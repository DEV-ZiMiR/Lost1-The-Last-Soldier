extends CharacterBody2D

signal death

enum State { IDLE, RUN, ATTACK, HIT, DIE }

var current_state: State = State.IDLE
var player: Node2D = null
var move_speed := 80
var max_health := 75
var hp := 75
var gravity = 900
var can_attack: bool = true
const ATTACK_RANGE := 36.0
const DETECTION_RANGE := 300.0

# attack_type: 1 або 2 (в залежності від hp%)
var attack_type: int = 1

# Тайминги (можеш підлаштувати під анімації)


@onready var hp_bar_left = $HPBar/hpbar_left
@onready var hp_bar_right = $HPBar/hpbar_right
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_scene = $EnemyAttack
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var hp_bar_sprite: AnimatedSprite2D = $HPBar/AnimatedSprite2D
@onready var enemy_attack_shape: CollisionShape2D = $EnemyAttack/CollisionShapeSigma
@onready var enemy_attack_area: Area2D = $EnemyAttack
@export var drop_data: EnemyDropData
@onready var drop_spot: Marker2D = $DropSpot
@onready var pickup_item_scene: PackedScene = preload("res://scenes/items/pickup_item.tscn")

@onready var drop_data_easy: EnemyDropData = preload("res://data/item_data/drops/enemy5_drop_list.tres")
@onready var drop_data_medium: EnemyDropData = preload("res://data/item_data/drops/enemy6_drop_list.tres")
@onready var drop_data_rare: EnemyDropData = preload("res://data/item_data/drops/enemy7_drop_list.tres")

func _ready():
	# сигнали зон
	detection_area.body_entered.connect(Callable(self, "_on_player_detected"))
	attack_area.body_entered.connect(Callable(self, "_on_player_in_attack_range"))
	attack_area.body_exited.connect(Callable(self, "_on_player_out_of_range"))

	# зона нанесення урону (Area колайдер)
	enemy_attack_area.body_entered.connect(Callable(self, "_on_EnemyAttack_body_entered"))

	# підписка на завершення анімацій
	anim_player.animation_finished.connect(Callable(self, "_on_animation_finished"))

	# вимкнемо колайдер атаки поки не треба
	if enemy_attack_shape:
		enemy_attack_shape.disabled = true

	# хпбар спочатку вимкнений
	$HPBar.visible = false

func _physics_process(_delta):
	update_hpbar()

	# перевірка валідності гравця
	if player != null and not is_instance_valid(player):
		player = null
		change_state(State.IDLE)
		return

	if player != null and current_state not in [State.DIE, State.HIT, State.ATTACK]:
		var distance = global_position.distance_to(player.global_position)
		face_player()
		apply_gravity(_delta)

		# якщо гравець в діапазоні атаки і ворог може атакувати — вибираємо тип атаки та атакуємо
		if distance <= ATTACK_RANGE and can_attack and current_state != State.ATTACK:
			# вибір атаки по відсотку здоров'я
			if max_health > 0 and float(hp) / float(max_health) <= 0.3:
				attack_type = 2
			else:
				attack_type = 1
			change_state(State.ATTACK)
			return

		# якщо бачив гравця в зоні виявлення, рухатись до нього
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


func face_player():
	# не перевертати у середині атаки автоматично — щоб анімація не ривала напрям
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
			sprite.play("idle")
			velocity = Vector2.ZERO
		State.RUN:
			anim_player.play("run")
			sprite.play("run")
		State.ATTACK:
			# почати атаку асинхронно
			if attack_type == 1:
				anim_player.play("attack_1")
				sprite.play("attack_1")
			else:
				anim_player.play("attack_2")
				sprite.play("attack_2")
			# запустимо процес активації зони атаки під час анімації
		State.HIT:
			anim_player.play("hit")
			sprite.play("hit")
		State.DIE:
			anim_player.play("die")
			timer.start()
			sprite.play("hit")
			await get_tree().create_timer(0.3).timeout
			sprite.play("die")


# --- Сигнали зон/детекції ---
func _on_player_detected(body):
	if body.is_in_group("player"):
		player = body
		if current_state not in [State.ATTACK, State.HIT, State.DIE]:
			change_state(State.RUN)

func _on_player_in_attack_range(body):
	if body.is_in_group("player"):
		player = body
		$HPBar.visible = true
		# якщо був у бігу — перейти в атаку
		if current_state == State.RUN and can_attack:
			# тип атаки визначається в _physics_process або тут теж можна додати
			if max_health > 0 and float(hp) / float(max_health) <= 0.3:
				attack_type = 2
			else:
				attack_type = 1
			change_state(State.ATTACK)

func _on_player_out_of_range(body):
	if body.is_in_group("player"):
		# коли гравець вийшов з attack_area — хпбар сховати та припинити мішень
		$HPBar.visible = false
		player = null
		if current_state not in [State.DIE, State.HIT, State.ATTACK]:
			change_state(State.IDLE)


# Функція, яка вмикає зону нанесення урону в потрібний момент анімації

# Обробка входу гравця в зону нанесення урону
func _on_EnemyAttack_body_entered(body):
	# body.take_damage(...) - викликаємо метод гравця, якщо він є
	if body.is_in_group("player") and can_attack:
		var dmg : int
		# зчитуємо damage з Area (якщо він заданий на Area2D через поле 'damage'), або задаємо дефолт
		if attack_type == 1:
			dmg = 35
		elif attack_type == 2:
			dmg = 45

		if enemy_attack_area.has_method("get_damage"):
			dmg = enemy_attack_area.get_damage()
		elif enemy_attack_area.has_meta("damage"):
			dmg = enemy_attack_area.get_meta("damage")
		# виклик методу гравця
		if body.has_method("take_damage"):
			body.take_damage(dmg)

		# заблокуємо повторні влучання, почнемо кулдаун

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
	var value := 0
	# Якщо хочеш, можна перерахувати від max_health для гнучкості
	if max_health > 0:
		value = int(clamp(float(hp) / float(max_health) * 100.0, 0, 100))
	else:
		value = 0

	$HPBar/hpbar_left.value = value
	$HPBar/hpbar_right.value = value

	flip_hpbar(sprite.flip_h)


# Обробник завершення анімацій (всі анімації приходять сюди)
func _on_animation_finished(anim_name: String):
	if anim_name == "hit":
		# після хіта повертаємось у RUN (якщо гравець є)
		if player != null and current_state == State.HIT:
			change_state(State.RUN)
		else:
			change_state(State.IDLE)

	elif anim_name == "die":
		_on_die_animation_finished()

func _on_attack_animation_finished():
	change_state(State.IDLE)
	can_attack = false
	if attack_type == 1:
		await get_tree().create_timer(0.5).timeout
	if attack_type == 2:
		await get_tree().create_timer(0.2).timeout
	can_attack = true
	
func _on_die_animation_finished():
	emit_signal("death")
	# викликаємо дроп із рідкістю (можеш змінити на іншу логіку)
	drop_item(drop_data_medium)
	queue_free()


func _on_timer_timeout() -> void:
	# таймер контролює завершення діє-анімації, тут просто включає відповідну спрайт-анімацію
	sprite.play("die")


func flip_hpbar(flip_h: bool):
	$HPBar/hpbar_left.visible = flip_h
	$HPBar/hpbar_right.visible = not flip_h


func flip_attack_area(flip_h: bool):
	# зміщуємо позицію колайду атаки по X в залежності від напрямку
	enemy_attack_shape.position.x = -abs(enemy_attack_shape.position.x) if flip_h else abs(enemy_attack_shape.position.x)


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
