extends CharacterBody2D
class_name ArmoredMonster

enum State { IDLE, RUN, ATTACK, HIT, DIE, DODGE }

var current_state: State = State.IDLE
var player: Node2D = null
var move_speed := 100
var max_health := 20
var hp := 20
var is_dead: bool = false
var can_attack: bool = true
var gravity = 900
const ATTACK_RANGE := 20.0
const DETECTION_RANGE := 200.0  # можеш змінити при потребі

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_scene = $EnemyAttack
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var dodge_label: Label = $HPBar/Label
@onready var hp_bar_left = $HPBar/hpbar_left
@onready var hp_bar_right = $HPBar/hpbar_right
@onready var enemy_attack: CollisionShape2D = $EnemyAttack/CollisionShapeSigma
@onready var enemy_attack_area: Area2D = $EnemyAttack
@export var drop_data: EnemyDropData
@onready var drop_spot: Marker2D = $DropSpot
@onready var pickup_item_scene: PackedScene = preload("res://scenes/items/pickup_item.tscn")

@onready var drop_data_easy: EnemyDropData = preload("res://data/item_data/drops/enemy1_drop_list.tres")
@onready var drop_data_medium: EnemyDropData = preload("res://data/item_data/drops/enemy2_drop_list.tres")
@onready var drop_data_rare: EnemyDropData = preload("res://data/item_data/drops/enemy3_drop_list.tres")


func _ready():
	enemy_attack.connect("body_entered", Callable(self, "_on_EnemyAttack_body_entered"))
	detection_area.connect("body_entered", Callable(self, "_on_player_detected"))
	attack_area.connect("body_entered", Callable(self, "_on_player_in_attack_range"))
	attack_area.connect("body_exited", Callable(self, "_on_player_out_of_range"))
	dodge_label.visible = false


func _physics_process(_delta):
	update_hpbar()
	if current_state in [State.HIT, State.DIE]:
		move_and_slide()
		return

	if player != null and is_instance_valid(player):
		apply_gravity(_delta)
		face_player()
		if player.has_method("get_current_state"):
			var p_state = player.get_current_state()
			if p_state in [State.HIT, State.DIE]:
				change_state(State.IDLE)
				velocity.x = 0
				move_and_slide()
				return

		var distance = global_position.distance_to(player.global_position)

		if distance <= ATTACK_RANGE and can_attack and current_state != State.ATTACK:
			change_state(State.ATTACK)
			velocity.x = 0
			move_and_slide()
			return

		elif distance <= DETECTION_RANGE and current_state != State.ATTACK:
			if current_state != State.RUN:
				change_state(State.RUN)
			var direction = sign(player.global_position.x - global_position.x)
			move_speed = clamp(75 + (distance / 10), 75, 100)
			velocity.x = direction * move_speed
			move_and_slide()
			return

		else:
			if current_state != State.ATTACK:
				change_state(State.IDLE)
			velocity.x = 0
			move_and_slide()
	else:
		player = null
		change_state(State.IDLE)
		velocity.x = 0
		move_and_slide()


func face_player():
	if is_dead:
		return

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
	if current_state == new_state:
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
			velocity = Vector2.ZERO
			anim_player.play("hit")
			sprite.play("hit")
		State.DIE:
			anim_player.play("die")
			sprite.play("hit")
			await get_tree().create_timer(0.6).timeout
			sprite.play("die")

			
		State.DODGE:
			anim_player.play("dodge")
			sprite.play("dodge")

# ─── Виявлення гравця ────────────────────────
func _on_player_detected(body):
	if is_dead:
		return
	if body.is_in_group("player"):
		player = body
		if current_state not in [State.ATTACK, State.HIT, State.DIE, State.DODGE]:
			change_state(State.RUN)

func _on_player_in_attack_range(body):
	$HPBar.visible = true
	if is_dead:
		return
	if current_state not in [State.ATTACK, State.HIT, State.DODGE]:
		if body.is_in_group("player") and current_state == State.RUN:
			change_state(State.ATTACK)

func _on_player_out_of_range(body):
	if body.is_in_group("player"):
		# ! НЕ скасовуємо гравця, просто запам’ятали його
		$HPBar.visible = false
		# не змінюємо player = null


# ─── Отримання урону ──────────────────────────
func take_damage(damage := 1):
	if current_state == State.DIE or current_state == State.DODGE:
		return

	if randi() % 3 == 0:
		# 33% шанс уникнути
		change_state(State.DODGE)
		show_dodge_label()
		return

	hp -= damage
	if hp <= 0:
		change_state(State.DIE)
	else:
		change_state(State.HIT)

func show_dodge_label():
	dodge_label.visible = true
	dodge_label.text = "Dodged!"
	await get_tree().create_timer(0.6).timeout
	dodge_label.visible = false
	change_state(State.RUN)

# ─── HP Bar ──────────────────────────────────
func update_hpbar():
	var percent = int((float(hp) / float(max_health)) * 100.0)
	hp_bar_left.value = percent
	hp_bar_right.value = percent
	flip_hpbar(sprite.flip_h)

# ─── Колбеки анімацій ────────────────────────
func _on_attack_animation_finished():
	if current_state == State.ATTACK:
		change_state(State.RUN)

func _on_hit_animation_finished():
	if current_state == State.HIT:
		change_state(State.RUN)

func _on_die_animation_finished():
	emit_signal("death")
	drop_item(drop_data_medium)
	queue_free()


func _on_timer_timeout():
	sprite.play("die")

# ─── Атака гравця ─────────────────────────────
func _on_EnemyAttack_body_entered(body):
	if body.is_in_group("player") and can_attack:
		body.take_damage(enemy_attack_area.damage)
		can_attack = false
		await get_tree().create_timer(2.0).timeout # Затримка 1 секунда
		can_attack = true

# ─── Дзеркалення ──────────────────────────────
func flip_hpbar(flip_h: bool):
	hp_bar_left.visible = flip_h
	hp_bar_right.visible = not flip_h

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
