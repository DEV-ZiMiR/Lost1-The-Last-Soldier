extends CharacterBody2D

enum State { IDLE, RUN, ATTACK, HIT, DIE }

var current_state: State = State.IDLE
var player: Node2D = null
var move_speed := 50
var max_health := 4
var hp := 4
var gravity = 900
var can_attack: bool = true
const ATTACK_RANGE := 40.0
const DETECTION_RANGE := 300.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_scene = $EnemyAttack
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var hp_bar_sprite: AnimatedSprite2D = $HPBar/AnimatedSprite2D
@onready var enemy_attack: CollisionShape2D = $EnemyAttack/CollisionShapeSigma
@onready var enemy_attack_area: Area2D = $EnemyAttack
@export var drop_data: EnemyDropData
@onready var drop_spot: Marker2D = $DropSpot
@onready var pickup_item_scene: PackedScene = preload("res://scenes/items/pickup_item.tscn")

@onready var drop_data_easy: EnemyDropData = preload("res://data/item_data/drops/enemy1_drop_list.tres")
@onready var drop_data_medium: EnemyDropData = preload("res://data/item_data/drops/enemy2_drop_list.tres")
@onready var drop_data_rare: EnemyDropData = preload("res://data/item_data/drops/enemy3_drop_list.tres")

func _ready():
	detection_area.connect("body_entered", Callable(self, "_on_player_detected"))
	attack_area.connect("body_entered", Callable(self, "_on_player_in_attack_range"))
	attack_area.connect("body_exited", Callable(self, "_on_player_out_of_range"))

func _physics_process(_delta):
	update_hpbar()
	if player != null and current_state not in [State.DIE, State.HIT]:
		var distance = global_position.distance_to(player.global_position)
	
		face_player()   
		apply_gravity(_delta)

		if distance <= ATTACK_RANGE and can_attack and current_state != State.ATTACK:
			change_state(State.ATTACK)
			return

		elif distance <= DETECTION_RANGE and current_state != State.ATTACK:
			change_state(State.RUN)
			var direction = sign(player.global_position.x - global_position.x)
			velocity.x = direction * move_speed
			move_and_slide()
			return

		else:
			if current_state != State.ATTACK:
				change_state(State.IDLE)
			velocity.x = 0
			move_and_slide()
	else:
		velocity.x = 0
		move_and_slide()
	
	if player != null and not is_instance_valid(player):
		player = null
		change_state(State.IDLE)
		return




		
		
func face_player():
	if current_state == State.ATTACK:
		return 
		
	if player and player.global_position.x < global_position.x:
		sprite.flip_h = true
		flip_hpbar(true)
		flip_attack_area(true)
	elif player and player.global_position.x > global_position.x:
		sprite.flip_h = false
		flip_hpbar(false)
		flip_attack_area(false)


# Зміна стану
func change_state(new_state: State):
	if current_state == new_state:
		return
	current_state = new_state
	match new_state:
		State.IDLE:
			anim_player.play("idle")
			sprite.play("default")
			velocity = Vector2.ZERO
		State.RUN:
			anim_player.play("run")
			sprite.play("run")
		State.ATTACK:
			anim_player.play("attack")
			sprite.play("attack")
		State.HIT:
			anim_player.play("hit")
			sprite.play("hit")
		State.DIE:
			anim_player.play("die")
			timer.start()
			sprite.play("hit")

# Виявлення гравця
func _on_player_detected(body):
	if body.is_in_group("player"):
		player = body
		if current_state not in [State.ATTACK, State.HIT, State.DIE]:
			change_state(State.RUN)


# Гравець у зоні атаки
func _on_player_in_attack_range(body):
	$HPBar.visible = true  # Показуємо HPbar, поки гравець у зоні
	if body.is_in_group("player") and current_state == State.RUN:
		change_state(State.ATTACK)

	# НЕ скасовуємо атаку, якщо гравець у грі, просто рухається
	# Тільки якщо реально вийшов
	if not attack_area.overlaps_body(body):
		$HPBar.visible = false
		change_state(State.RUN)
		player = null

# Отримання урону
func take_damage(damage := 1):
	if current_state == State.DIE:
		return
	hp -= damage
	if hp <= 0:
		change_state(State.DIE)
	else:
		change_state(State.HIT)
	
func update_hpbar():
	var value
	match hp:
		4:
			value = 100
		3:
			value = 75
		2:
			value = 50
		1:
			value = 25
		_:
			value = 0

	$HPBar/hpbar_left.value = value
	$HPBar/hpbar_right.value = value

	flip_hpbar(sprite.flip_h)


# Колбек завершення анімацій
func _on_attack_animation_finished():
	if player and player.has_method("get_current_state"):
		var p_state = player.get_current_state()

		if p_state == State.HIT or State.DIE:
			change_state(State.IDLE)
		else:
			change_state(State.RUN)

func _on_hit_animation_finished():
	if current_state == State.HIT:
		change_state(State.RUN)

func _on_die_animation_finished():
	emit_signal("death")
	drop_item(drop_data_easy)
	queue_free()

func _on_timer_timeout() -> void:
	sprite.play("die")

func flip_hpbar(flip_h: bool):
	$HPBar/hpbar_left.visible = flip_h
	$HPBar/hpbar_right.visible = not flip_h

func flip_attack_area(flip_h: bool):
	enemy_attack.position.x = -abs(enemy_attack.position.x) if flip_h else abs(enemy_attack.position.x)

func _on_EnemyAttack_body_entered(body):
	if body.is_in_group("player") and can_attack:
		body.take_damage(enemy_attack_area.damage)
		can_attack = false
		await get_tree().create_timer(2.0).timeout # Затримка 1 секунда
		can_attack = true
		
func drop_item(data: EnemyDropData):
	if data == null or data.drop_entries.is_empty():
		return

	var rng = randi() % 100 + 1
	var cumulative_chance = 0

	for entry in data.drop_entries:
		cumulative_chance += entry.drop_chance
		if rng <= cumulative_chance:
			var item_instance = pickup_item_scene.instantiate()
			item_instance.set_item_data(entry.item, entry.amount)
			item_instance.global_position = drop_spot.global_position

			# перевіряємо чи є контейнер Drops
			if SaveManager.drops_parent != null:
				SaveManager.drops_parent.add_child(item_instance)
			else:
				push_warning("Drops parent не заданий, дроп додається в current_scene")
				get_tree().current_scene.add_child(item_instance)

			return

			
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
