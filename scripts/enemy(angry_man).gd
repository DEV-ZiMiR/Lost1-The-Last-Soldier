extends CharacterBody2D

enum State { IDLE, RUN, ATTACK, HIT, DIE }

var current_state: State = State.IDLE
var player: Node2D = null
var move_speed := 50
var max_health := 4
var hp := 4
var can_attack: bool = true

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_scene = $EnemyAttack
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var hp_bar_sprite: AnimatedSprite2D = $HPBar/AnimatedSprite2D
@onready var enemy_attack: CollisionShape2D = $EnemyAttack/CollisionShapeSigma

func _ready():
	detection_area.connect("body_entered", Callable(self, "_on_player_detected"))
	attack_area.connect("body_entered", Callable(self, "_on_player_in_attack_range"))
	attack_area.connect("body_exited", Callable(self, "_on_player_out_of_range"))

func _physics_process(delta):
	if current_state == State.RUN and player:
		if attack_area.overlaps_body(player):
			change_state(State.ATTACK)
			return  # Щоб не продовжував рух

		var direction = sign(player.global_position.x - global_position.x)
		velocity.x = direction * move_speed
		move_and_slide()
	else:
		velocity.x = 0
		move_and_slide()

	face_player()
	update_hpbar()


		
		
func face_player():
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
	if body.is_in_group("player") and current_state == State.IDLE:
		player = body
		change_state(State.RUN)

# Гравець у зоні атаки
func _on_player_in_attack_range(body):
	$HPBar.visible = true  # Показуємо HPbar, поки гравець у зоні
	if body.is_in_group("player") and current_state == State.RUN:
		change_state(State.ATTACK)

func _on_player_out_of_range(body):
	$HPBar.visible = false
	if body == player and current_state == State.ATTACK:
		change_state(State.RUN)

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
	if current_state == State.ATTACK:
		change_state(State.RUN)

func _on_hit_animation_finished():
	if current_state == State.HIT:
		change_state(State.RUN)

func _on_die_animation_finished():
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
		body.take_damage(2)  # Або більше, залежно від атаки
		can_attack = false
		await get_tree().create_timer(2.0).timeout  # Затримка між ударами
		can_attack = true
		print("Enemy hit", body.name)
