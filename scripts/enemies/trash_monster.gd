extends CharacterBody2D
class_name TrashMonster

enum State { IDLE, RUN, ATTACK, HIT, DIE }

var current_state: State = State.IDLE
var player: Node2D = null
var move_speed := 40
var max_health := 50
var hp := 50
var gravity = 900
var can_attack: bool = true
const ATTACK_RANGE := 30.0
const DETECTION_RANGE := 200.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_scene = $EnemyAttack
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var hp_bar_left = $HPBar/hpbar_left
@onready var hp_bar_right = $HPBar/hpbar_right
@onready var enemy_attack: CollisionShape2D = $EnemyAttack/CollisionShapeSigma
@onready var enemy_attack_area: Area2D = $EnemyAttack
@export var drop_data: EnemyDropData
@onready var drop_spot: Marker2D = $DropSpot
@onready var pickup_item_scene: PackedScene = preload("res://scenes/items/pickup_item.tscn")

@onready var drop_data_easy: EnemyDropData = preload("res://data/item_data/drops/enemy3_drop_list.tres")
@onready var drop_data_medium: EnemyDropData = preload("res://data/item_data/drops/enemy4_drop_list.tres")
@onready var drop_data_rare: EnemyDropData = preload("res://data/item_data/drops/enemy5_drop_list.tres")

func _ready():
	enemy_attack_area.connect("body_entered", Callable(self, "_on_EnemyAttack_body_entered"))
	detection_area.connect("body_entered", Callable(self, "_on_player_detected"))
	attack_area.connect("body_entered", Callable(self, "_on_player_in_attack_range"))
	attack_area.connect("body_exited", Callable(self, "_on_player_out_of_range"))


func _physics_process(delta):
	update_hpbar()

	if current_state in [State.HIT, State.DIE]:
		move_and_slide()
		return

	if player != null and is_instance_valid(player):
		apply_gravity(delta)
		face_player()

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


# ─── Напрямок ────────────────────────────────
func face_player():
	if current_state == State.ATTACK:
		return 
	if player and player.global_position.x < global_position.x:
		sprite.flip_h = false
		flip_hpbar(false)
		flip_attack_area(false)
	elif player and player.global_position.x > global_position.x:
		sprite.flip_h = true
		flip_hpbar(true)
		flip_attack_area(true)


# ─── Стан ────────────────────────────────────
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


# ─── Виявлення ──────────────────────────────
func _on_player_detected(body):
	if body.is_in_group("player"):
		player = body
		if current_state not in [State.ATTACK, State.HIT, State.DIE]:
			change_state(State.RUN)

func _on_player_in_attack_range(body):
	$HPBar.visible = true
	if current_state not in [State.ATTACK, State.HIT]:
		if body.is_in_group("player") and current_state == State.RUN:
			change_state(State.ATTACK)

func _on_player_out_of_range(body):
	if body.is_in_group("player"):
		$HPBar.visible = false
		# не очищаємо player = null


# ─── Отримання урону ─────────────────────────
func take_damage(damage := 1):
	if current_state == State.DIE:
		return

	# 80% шанс поглинати 40–60% урону
	if randi() % 100 < 80:
		var absorb_percent = randf_range(0.4, 0.6)
		var absorbed = int(damage * absorb_percent)
		damage -= absorbed
		print("Поглинено ", absorbed, " урону")

	hp -= damage
	if hp <= 0:
		change_state(State.DIE)
	else:
		change_state(State.HIT)


# ─── HP Bar ──────────────────────────────────
func update_hpbar():
	var percent = int((float(hp) / float(max_health)) * 100.0)
	hp_bar_left.value = percent
	hp_bar_right.value = percent
	flip_hpbar(sprite.flip_h)


# ─── Атака ───────────────────────────────────
func _on_EnemyAttack_body_entered(body):
	if body.is_in_group("player") and can_attack:
		var base_damage = enemy_attack_area.damage
		# множник залежить від HP: менше HP → більше шкоди
		var multiplier = 1.0 + (1.0 - float(hp) / float(max_health))
		var final_damage = int(base_damage * multiplier)
		body.take_damage(final_damage)
		print("Ворог наніс ", final_damage, " урону (x", multiplier, ")")
		can_attack = false
		await get_tree().create_timer(2.0).timeout
		can_attack = true


# ─── Дзеркалення ─────────────────────────────
func flip_hpbar(flip_h: bool):
	hp_bar_left.visible = flip_h
	hp_bar_right.visible = not flip_h

func flip_attack_area(flip_h: bool):
	enemy_attack.position.x = -abs(enemy_attack.position.x) if flip_h else abs(enemy_attack.position.x)

func _on_attack_animation_finished():
	if current_state == State.ATTACK:
		change_state(State.RUN)

func _on_hit_animation_finished():
	if current_state == State.HIT:
		change_state(State.RUN)

# ─── Дроп ───────────────────────────────────
func _on_die_animation_finished():
	emit_signal("death")
	drop_item(drop_data_medium)
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

			# перевіряємо чи є контейнер Drops
			if SaveManager.drops_parent != null:
				SaveManager.drops_parent.add_child(item_instance)
			else:
				push_warning("Drops parent не заданий, дроп додається в current_scene")
				get_tree().current_scene.add_child(item_instance)

			return

# ─── Гравітація ──────────────────────────────
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
