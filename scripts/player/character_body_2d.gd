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
	AIM, # 🆕 новий стан
	HIT,
	DIE
}
var current_state: State = State.IDLE

# --- Рух ---
@export var move_speed := 120
@export var jump_force := -300
@export var gravity := 900
@export var gold: int = 150
var is_poisoned: bool = false
var poison_timer: Timer
var poison_duration: float = 0.0
var poison_damage: int = 0
var poison_time_passed: float = 0.0
var facing_dir : int = 1
var base_max_hp: int = 10  # 🆕 Додаємо базове HP
var max_hp: int = base_max_hp  # І використовуємо його
var hp: int = 10
var total_damage: int = 0
var base_damage: int = 1
var bonus_damage: int = 0
var is_invulnerable: bool = false
var is_dead: bool = false
var can_attack: bool = true

var hp_buff_percent: float = 0.0
var damage_buff_percent: float = 0.0
var speed_buff_percent: float = 0.0
var regen_buff_percent: float = 0.0
var crit_chance_buff_percent: float = 0.0
var crit_damage_buff_percent: float = 0.0
var damage_reduce_buff_percent: float = 0.0

var input_direction := 0

@onready var pet: Node2D = $"../PlayerPet"
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var sword_hitbox := $"hitbox(sword)/CollisionShape2D"
@onready var hp_bar: TextureProgressBar = $"../PlayerUI/PlayerHP/HBoxContainer/HPBar"
@onready var hp_label: Label = $"../PlayerUI/PlayerHP/HBoxContainer/HPBar/HPLabel"
@onready var restart_menu: Control = $"../PlayerUI/RestartMenu"
@onready var target: Marker2D = $Target

func _process(delta):
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - $WeaponHolder.global_position).angle()
# замість ставити rotation напряму на sprite — використай API:
	$WeaponHolder/ranged_weapon.set_aim_angle_rad(dir)


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
		State.AIM:
			velocity.x = 0.40 * (input_direction * move_speed)
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
			if can_attack == false:
				return
			change_state(State.ATTACK)
			
	if current_state == State.SLIDE and Input.is_action_just_pressed("jump"):
		velocity.y = jump_force
		change_state(State.JUMP)
		return


func update_facing():
	if current_state == State.ATTACK:
		return

	if current_state == State.AIM:
		face_to_mouse()
		return

	if input_direction > 0:
		facing_dir = 1
		sprite.flip_h = false
		sword_hitbox.position.x = abs(sword_hitbox.position.x)
	elif input_direction < 0:
		facing_dir = -1
		sprite.flip_h = true
		sword_hitbox.position.x = -abs(sword_hitbox.position.x)

func face_to_mouse():
	var mouse_pos = get_global_mouse_position()
	var diff = mouse_pos.x - global_position.x

	if diff > 0 and facing_dir != 1:
		facing_dir = 1
		sprite.flip_h = false

	elif diff < 0 and facing_dir != -1:
		facing_dir = -1
		sprite.flip_h = true

		
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
			
		State.AIM:
			anim_player.play("aim")
			sprite.play("aim")

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
	poison_timer = Timer.new()
	poison_timer.connect("timeout", Callable(self, "_on_poison_tick"))
	add_child(poison_timer)
	
func update_hp_ui(): 
	hp_bar.value = float(hp) / max_hp * 100
	hp_label.text = str(hp) + "/" + str(max_hp)
	
# --- Урон ---
func take_damage(amount: int) -> void:
	if is_invulnerable or is_dead:
		return

	# Зменшуємо шкоду враховуючи damage_reduce_buff_percent
	var final_damage = int(amount * (1.0 - damage_reduce_buff_percent / 100.0))
	hp -= final_damage
	update_hp_ui()

	if hp > 0:
		is_invulnerable = true
		change_state(State.HIT)
	else:
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
	 # Сховати гравця

func add_item_to_inventory(item_data: ItemData) -> bool:
	return InventoryManager.add_item(item_data, 1)

# --- Додати HP (лікування враховує бафи на HP)
func add_hp(amount: int):
	hp = min(hp + amount, max_hp)
	update_hp_ui()
#продовжувати функцію set_maxhp!!!
func set_max_hp(new_max_hp: int):
	max_hp = new_max_hp
	hp = clamp(hp, 0, max_hp)
	update_hp_ui()

func add_damage(amount: int):
	bonus_damage = amount
	print("Bonus damage:", bonus_damage)

func get_total_damage() -> int:
	var buffed_damage = int(base_damage * (1.0 + damage_buff_percent / 100.0))
	total_damage = buffed_damage + bonus_damage
	return total_damage

func get_current_state() -> State:
	return current_state

func equip_ranged_weapon(icon : Texture2D):
	var weapon_holder = $WeaponHolder
	var weapon : Sprite2D = $WeaponHolder/ranged_weapon/Sprite2D
	weapon_holder.visible = true
	weapon.texture = icon
	change_state(State.AIM)
	
func unequip_ranged_weapon():
	var weapon_holder = $WeaponHolder
	weapon_holder.visible = false
	if abs(input_direction) > 0:
		change_state(State.RUN)
	else:
		change_state(State.IDLE)
	
func set_can_attack(attack: bool):
	if attack == true:
		can_attack = true
		InventoryManager.can_use_items = true
	elif attack == false:
		can_attack = false
		InventoryManager.can_use_items = false
		
func apply_poison(duration: float, damage_per_second: int, wait_time: float):
	poison_timer.wait_time = wait_time  # шкода щосекунди
	poison_timer.one_shot = false
	poison_duration = duration
	poison_damage = damage_per_second
	poison_time_passed = 0.0
	is_poisoned = true
	if not poison_timer.is_stopped():
		poison_timer.stop()
	poison_timer.start()

func _on_poison_tick():
	if not is_poisoned:
		return
	
	poison_time_passed += 1.0
	take_damage(poison_damage)
	
	print("Отрута завдала ", poison_damage, " шкоди. HP: ", hp)

	if poison_time_passed >= poison_duration:
		is_poisoned = false
		poison_timer.stop()
		print("Отрута закінчилася")
	
func on_save_loaded():
	is_dead = false
	is_invulnerable = false

func apply_pet_buffs(buffs: Array[PetBuff]):
	for buff in buffs:
		match buff.type:
			PetBuff.BuffType.HP:
				hp_buff_percent = buff.percent
			PetBuff.BuffType.SPEED:
				speed_buff_percent += buff.percent
			PetBuff.BuffType.ATTACK:
				damage_buff_percent += buff.percent
			PetBuff.BuffType.REGEN:
				regen_buff_percent += buff.percent
			PetBuff.BuffType.CRIT_CHANCE:
				crit_chance_buff_percent += buff.percent
			PetBuff.BuffType.CRIT_DAMAGE:
				crit_damage_buff_percent += buff.percent
			PetBuff.BuffType.DAMAGE_REDUCE:
				damage_reduce_buff_percent += buff.percent
			_: pass

	_update_stats(false)

func drop_pet_buffs():
	damage_buff_percent = 0.0
	speed_buff_percent = 0.0
	regen_buff_percent = 0.0
	crit_chance_buff_percent = 0.0
	crit_damage_buff_percent = 0.0
	damage_reduce_buff_percent = 0.0

	_update_stats(true)

# 🟢 Перерахунок характеристик
func _update_stats(drop_stats: bool):
	# HP
	var buffed_hp: int
	if drop_stats != true:
		buffed_hp = int(max_hp * (1.0 + hp_buff_percent / 100.0))
	else:
		buffed_hp = int(max_hp / (1.0 + hp_buff_percent / 100.0))
	set_max_hp(buffed_hp)

	# Damage
	get_total_damage()

	# Швидкість руху
	move_speed = int(120 * (1.0 + speed_buff_percent / 100.0))

	# Якщо хп після зниження стало більше за max_hp — обмежуємо
	hp = clamp(hp, 0, max_hp)
	update_hp_ui()
	
func show_pet(pet_data: PetData):
	pet.set_player(self)
	pet.update_look(pet_data)
	await get_tree().process_frame
	pet.visible = true

func hide_pet():
	pet.visible = false
	
func get_dir() -> int:
	return facing_dir
