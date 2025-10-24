extends CharacterBody2D

enum State { IDLE, RUN, ATTACK, HIT, DIE }

var current_state: State = State.IDLE
var player: Node2D = null
var move_speed := 40
var max_health := 80
var hp := 80
var gravity = 900
var can_attack: bool = true
const ATTACK_RANGE := 40.0
const DETECTION_RANGE := 300.0

# Унікальні параметри mtha_monster
var attack_damage := 1
const MAX_ATTACK_DAMAGE := 64
const DAMAGE_REDUCTION := 0.8  # 80% урону проходить, 20% ігнорується

@onready var hp_bar_left = $HPBar/hpbar_left
@onready var hp_bar_right = $HPBar/hpbar_right
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

@onready var drop_data_rare: EnemyDropData = preload("res://data/item_data/drops/enemy7_drop_list.tres")

func _ready():
	detection_area.connect("body_entered", Callable(self, "_on_player_detected"))
	attack_area.connect("body_entered", Callable(self, "_on_player_in_attack_range"))
	attack_area.connect("body_exited", Callable(self, "_on_player_out_of_range"))

func _physics_process(delta):
	update_hpbar()
	if player != null and current_state not in [State.DIE, State.HIT]:
		var distance = global_position.distance_to(player.global_position)
		face_player()   
		apply_gravity(delta)

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


func change_state(new_state: State):
	if current_state == new_state or current_state == State.DIE:
		return
	current_state = new_state
	match new_state:
		State.IDLE:
			anim_player.play("idle")
			sprite.play("idle")
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
			sprite.play("hit")
			await get_tree().create_timer(0.1).timeout
			sprite.play("die")


func _on_player_detected(body):
	if body.is_in_group("player"):
		player = body
		if current_state not in [State.ATTACK, State.HIT, State.DIE]:
			change_state(State.RUN)


func _on_player_in_attack_range(body):
	$HPBar.visible = true
	if body.is_in_group("player") and current_state == State.RUN:
		change_state(State.ATTACK)


func _on_player_out_of_range(body):
	if body.is_in_group("player") and current_state != State.ATTACK:
		$HPBar.visible = false
		change_state(State.RUN)
		player = null


# --- Унікальна механіка ---
func take_damage(damage := 1):
	if current_state == State.DIE:
		return
	# Вбирає 20% урону
	var reduced_damage = int(ceil(damage * DAMAGE_REDUCTION))
	hp -= reduced_damage
	if hp <= 0:
		change_state(State.DIE)
	else:
		change_state(State.HIT)


func _on_EnemyAttack_body_entered(body):
	if body.is_in_group("player") and can_attack:
		# Наносимо урон, який масштабується
		body.take_damage(attack_damage)
		
		# Після атаки подвоюємо урон (до 64)
		attack_damage = min(attack_damage * 2, MAX_ATTACK_DAMAGE)

		can_attack = false
		await get_tree().create_timer(2.0).timeout
		can_attack = true


func update_hpbar():
	var percent = int((float(hp) / float(max_health)) * 100.0)
	hp_bar_left.value = percent
	hp_bar_right.value = percent
	flip_hpbar(sprite.flip_h)


func _on_attack_animation_finished():
	can_attack = false
	if player and player.has_method("get_current_state"):
		var p_state = player.get_current_state()
		if p_state == State.HIT or State.DIE:
			change_state(State.IDLE)
		else:
			change_state(State.RUN)
	await get_tree().create_timer(1).timeout
	can_attack = true

func _on_hit_animation_finished():
	if current_state == State.HIT:
		change_state(State.RUN)

func _on_die_animation_finished():
	emit_signal("death")
	drop_item(drop_data_rare)
	queue_free()

func flip_hpbar(flip_h: bool):
	$HPBar/hpbar_left.visible = flip_h
	$HPBar/hpbar_right.visible = not flip_h

func flip_attack_area(flip_h: bool):
	enemy_attack.position.x = -abs(enemy_attack.position.x) if flip_h else abs(enemy_attack.position.x)

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
			if SaveManager.drops_parent != null:
				SaveManager.drops_parent.add_child(item_instance)
			else:
				get_tree().current_scene.add_child(item_instance)
			return

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
