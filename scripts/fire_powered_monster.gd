extends CharacterBody2D
class_name FirePoweredMonster

enum State { IDLE, RUN, ATTACK, HIT, DIE }

var current_state: State = State.IDLE
var player: Node2D = null
var move_speed := 30
var max_health := 20
var hp := 20
var gravity = 900
var can_attack: bool = true
var is_attacking: bool = false
const ATTACK_RANGE := 300.0
const DETECTION_RANGE := 400.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var dodge_label: Label = $HPBar/Label
@onready var hp_bar_left = $HPBar/hpbar_left
@onready var hp_bar_right = $HPBar/hpbar_right
@onready var fire_point: Marker2D = $Marker2D
@export var drop_data: EnemyDropData
@onready var drop_spot: Marker2D = $DropSpot
@onready var pickup_item_scene: PackedScene = preload("res://scenes/items/pickup_item.tscn")
@onready var drop_data_easy: EnemyDropData = preload("res://drops/enemy1_drop_list.tres")
@onready var drop_data_medium: EnemyDropData = preload("res://drops/enemy2_drop_list.tres")
@onready var drop_data_rare: EnemyDropData = preload("res://drops/enemy3_drop_list.tres")
@onready var fireball_scene = preload("res://scenes/fire_ball.tscn")

func _ready():
	detection_area.body_entered.connect(_on_player_detected)
	attack_area.body_entered.connect(_on_player_in_attack_range)
	attack_area.body_exited.connect(_on_player_out_of_range)
	dodge_label.visible = false

func _physics_process(_delta):
	update_hpbar()
	if player != null and current_state not in [State.DIE, State.HIT]:
		var distance = global_position.distance_to(player.global_position)
		face_player()   

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
	if player and player.global_position.x < global_position.x:
		sprite.flip_h = true
		flip_hpbar(true)
		flip_marker(true)
	elif player and player.global_position.x > global_position.x:
		sprite.flip_h = false
		flip_hpbar(false)
		flip_marker(false)

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
			if is_attacking: return  # блокуємо спам
			is_attacking = true
			anim_player.play("attack")
			sprite.play("attack")
			await shoot_fireballs()
			is_attacking = false
			change_state(State.IDLE)
			can_attack = false
			await get_tree().create_timer(3).timeout
			can_attack = true
		State.HIT:
			velocity = Vector2.ZERO
			anim_player.play("hit")
			sprite.play("hit")
			await get_tree().create_timer(0.3).timeout
			change_state(State.RUN)
		State.DIE:
			velocity = Vector2.ZERO
			anim_player.play("die")
			sprite.play("hit")
			await get_tree().create_timer(0.6).timeout
			sprite.play("die")

func shoot_fireballs():
	await get_tree().create_timer(0.5).timeout

	for i in range(3):
		if current_state != State.ATTACK:
			break  # зупинити стрільбу, якщо вже не атакує

		var fireball = fireball_scene.instantiate()
		fireball.global_position = fire_point.global_position

		var target_position: Vector2

		if player != null and player.has_node("Target"):
			var target_node = player.get_node("Target")
			target_position = target_node.global_position
		elif player != null:
			target_position = player.global_position
		else:
			target_position = fire_point.global_position  # стріляє просто вперед

		fireball.set_target(target_position)
		get_tree().current_scene.add_child(fireball)

		await get_tree().create_timer(0.5).timeout

	# тільки після всіх пострілів завершення атаки
	if current_state == State.ATTACK:
		change_state(State.IDLE)
		can_attack = false
		await get_tree().create_timer(3.0).timeout
		can_attack = true




# ─── Гравець виявлений ────────────────────────
func _on_player_detected(body):
	if body.is_in_group("player"):
		player = body
		if current_state not in [State.ATTACK, State.HIT, State.DIE]:
			change_state(State.RUN)

func _on_player_in_attack_range(body):
	$HPBar.visible = true
	if body.is_in_group("player") and current_state == State.RUN:
		if can_attack:
			change_state(State.ATTACK)

func _on_player_out_of_range(body):
	if body.is_in_group("player"):
		# ! НЕ скасовуємо гравця, просто запам’ятали його
		$HPBar.visible = false
		# не змінюємо player = null


# ─── Урон ─────────────────────────────────────
func take_damage(damage := 1):
	if current_state == State.DIE:
		return

	hp -= damage
	if hp <= 0:
		change_state(State.DIE)
	else:
		change_state(State.HIT)

# ─── HP Bar ───────────────────────────────────
func update_hpbar():
	var percent = int((float(hp) / float(max_health)) * 100.0)
	hp_bar_left.value = percent
	hp_bar_right.value = percent
	flip_hpbar(sprite.flip_h)

func flip_hpbar(flip_h: bool):
	hp_bar_left.visible = flip_h
	hp_bar_right.visible = not flip_h
	
func flip_marker(flip_h: bool):
	fire_point.position.x = -abs(fire_point.position.x) if flip_h else abs(fire_point.position.x)
	
func _on_die_animation_finished():
	drop_item(drop_data_rare)
	queue_free()
	
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
			get_tree().current_scene.add_child(item_instance)
			return
			
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
