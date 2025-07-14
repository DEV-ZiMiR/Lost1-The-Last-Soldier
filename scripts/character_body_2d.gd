extends CharacterBody2D

# --- Стан ---
enum State {
	IDLE,
	RUN,
	JUMP,
	LANDING,
	SLIDE,
	SITTING,
	SIT,
	ATTACK,
	HIT,
	DIE
}
var current_state: State = State.IDLE

# --- Рух ---
@export var move_speed := 120
@export var jump_force := -300
@export var gravity := 900
@export var gold: int = 150
var facing_dir := 1
var base_max_hp: int = 10  # 🆕 Додаємо базове HP
var max_hp: int = base_max_hp  # І використовуємо його
var hp: int = 10
var total_damage: int = 0
var base_damage: int = 1
var bonus_damage: int = 0
var is_invulnerable: bool = false
var is_dead: bool = false

var input_direction := 0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var sword_hitbox := $"hitbox(sword)/CollisionShape2D"
@onready var hp_bar: TextureProgressBar = $"../PlayerUI/PlayerHP/HBoxContainer/HPBar"
@onready var hp_label: Label = $"../PlayerUI/PlayerHP/HBoxContainer/HPBar/HPLabel"
@onready var restart_menu: Control = $"../PlayerUI/RestartMenu"

# --- Керування ---
func _physics_process(delta):	
	apply_gravity(delta)
	get_input()         # 🟢 Спочатку зчитуємо ввід
	update_facing()     # 🟢 Потім визначаємо напрямок

	match current_state:
		State.DIE:
			velocity.x = 0
			
		State.HIT:
			velocity.x = 0
			# рух заборонено
		State.ATTACK:
			# рух/керування заблоковані
			velocity.x = 0

		State.JUMP:
			# рух в повітрі
			velocity.x = input_direction * move_speed
			if velocity.y > 0:
				change_state(State.LANDING)

		State.LANDING:
			# Переходить автоматично після анімації
			velocity.x = input_direction * move_speed

		State.SLIDE:
			velocity.x = input_direction * move_speed * 1.3

			# Якщо врізався у стіну — завершити слайд
			if is_on_wall():
				if abs(input_direction) > 0:
					change_state(State.RUN)
				else:
					change_state(State.IDLE)


		State.SITTING:
			velocity.x = 0

		State.SIT:
			velocity.x = 0
			if not Input.is_action_pressed("sit"):
				change_state(State.IDLE)

		State.RUN:
			velocity.x = input_direction * move_speed
			if abs(input_direction) == 0:
				change_state(State.IDLE)

		State.IDLE:
			velocity.x = 0
			if abs(input_direction) > 0:
				change_state(State.RUN)

	move_and_slide()

# --- Отримання керування ---
func get_input():
	if current_state != State.SLIDE:
		input_direction = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))

	if current_state in [State.IDLE, State.RUN]:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_force
			change_state(State.JUMP)
		elif Input.is_action_just_pressed("slide") and input_direction != 0:
			change_state(State.SLIDE)
		elif Input.is_action_just_pressed("sit"):
			change_state(State.SITTING)
		elif Input.is_action_just_pressed("attack"):
			change_state(State.ATTACK)
			
	if current_state == State.SLIDE and Input.is_action_just_pressed("jump"):
		velocity.y = jump_force
		change_state(State.JUMP)
		return


func update_facing():
	if current_state == State.ATTACK:
		return
		
	if input_direction > 0:
		sprite.flip_h = false
		sword_hitbox.position.x = abs(sword_hitbox.position.x)
	elif input_direction < 0:
		sprite.flip_h = true
		sword_hitbox.position.x = -abs(sword_hitbox.position.x)  # вліво

		
# --- Гравітація ---
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

# --- Зміна стану ---
func change_state(new_state: State):
	if current_state == new_state:
		return

	current_state = new_state

	match new_state:
		State.IDLE:
			anim_player.play("idle")
			sprite.play("idle")

		State.RUN:
			anim_player.play("run")
			sprite.play("run")

		State.JUMP:
			anim_player.play("jump")
			sprite.play("jump")

		State.LANDING:
			anim_player.play("landing")
			sprite.play("landing")

		State.SLIDE:
			anim_player.play("slide")
			sprite.play("slide")

		State.SITTING:
			anim_player.play("sitting")
			sprite.play("sitting")

		State.SIT:
			anim_player.play("sit")
			sprite.play("sit")

		State.ATTACK:
			$"hitbox(sword)".activate(self)
			anim_player.play("attack")
			sprite.play("attack")
			
		State.HIT:
			anim_player.play("hit")
			sprite.play("hit")
		
		State.DIE:
			anim_player.play("die")
			sprite.play("die")

func _on_landing_finished():
	if is_on_floor():
		if abs(input_direction) > 0:
			change_state(State.RUN)
		else:
			change_state(State.IDLE)

func _on_sitting_finished():
	change_state(State.SIT)

func _on_slide_finished():
	if abs(input_direction) > 0:
		change_state(State.RUN)
	else:
		change_state(State.IDLE)

func _on_hit_finished():
	change_state(State.IDLE)

func _ready():
	update_hp_ui()
	add_to_group("player")
	
func update_hp_ui(): 
	hp_bar.value = float(hp) / max_hp * 100
	hp_label.text = str(hp) + "/" + str(max_hp)
	
# === Отримання урону ===
func take_damage(amount: int) -> void:
	if is_invulnerable or is_dead:
		return
	
	hp -= amount
	update_hp_ui()

	if hp > 0:
		# Гравець ще живий — анімація урону
		is_invulnerable = true
		change_state(State.HIT)
	else:
		# Смерть
		hp = 0
		is_dead = true
		change_state(State.HIT)
		await get_tree().create_timer(0.4).timeout
		change_state(State.DIE)

# === Викликається з анімації hit через AnimationPlayer ===
func end_hit_state():
	is_invulnerable = false
	
	if abs(input_direction) > 0:
		change_state(State.RUN)
	else:
		change_state(State.IDLE)

# === Викликається в кінці анімації die ===
func on_death_animation_end():
	Engine.time_scale = 0.1
	restart_menu.visible = true
	hide() # Сховати гравця

func add_item_to_inventory(item_data: ItemData) -> bool:
	return InventoryManager.add_item(item_data)

func add_hp(amount: int):
	hp = min(hp + amount, max_hp)
	print("HP after heal:", hp, "/", max_hp)
	update_hp_ui()

#продовжувати функцію set_maxhp!!!
func set_max_hp(new_max_hp: int):
	max_hp = new_max_hp
	hp = clamp(hp, 0, max_hp)
	update_hp_ui()

func add_damage(amount: int):
	bonus_damage = amount
	print("Bonus damage:", bonus_damage)

func get_total_damage():
	total_damage = base_damage + bonus_damage

func get_current_state() -> State:
	return current_state
