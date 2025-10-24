extends Node2D
class_name PetFollower

# ----- configurable -----
@export var follow_distance: float = 20.0   # відстань по X від гравця (позаду/попереду)
@export var follow_speed: float = 5.0       # швидкість "підтягування" (більше -> швидше, використовуємо для lerp t)
@export var global_y: float = -18.0         # Глобальна Y-позиція пета (жорстко)
@export var start_delay: float = 0.5        # затримка перед початком слідування
# ------------------------

@onready var sprite: Sprite2D = $Sprite2D
@onready var delay_timer: Timer = $delay_timer

var player: CharacterBody2D = null
var target_x: float = 0.0
var is_following: bool = false

func _ready() -> void:
	# Налаштовуємо таймер (one-shot)
	if delay_timer:
		delay_timer.wait_time = start_delay
		delay_timer.one_shot = true
		if not delay_timer.is_connected("timeout", Callable(self, "_on_delay_timer_timeout")):
			delay_timer.timeout.connect(Callable(self, "_on_delay_timer_timeout"))

	# Гарантуємо, що Y завжди глобально встановлено, якщо нікого немає
	global_position.y = global_y

# Викликати одразу після створення / інстансування пета
# p має бути посиланням на Player (CharacterBody2D)
func set_player(p: CharacterBody2D) -> void:
	if p == null:
		push_error("PetFollower.set_player: player is null")
		return

	player = p

	# прочитаємо facing_dir без аварії (якщо його нема — беремо 1)
	var dir := 1
	var maybe_fd = player.get_dir()
	if typeof(maybe_fd) == TYPE_INT:
		dir = int(maybe_fd)

	# стартова позиція: одразу ставимо поряд з гравцем там, де пет буде зупинятись
	var spawn_x = player.global_position.x + follow_distance * -dir
	global_position.x = spawn_x
	global_position.y = global_y  # жорстко встановлено як ти просив

	# скидаємо стан слідування й запускаємо таймер
	is_following = false
	if delay_timer:
		delay_timer.start()

	# одразу синхронізуємо вигляд (щоб не було спалаху з іншим спрайтом)
	_update_sprite_direction(dir)

func _process(delta: float) -> void:
	if player == null:
		return

	# Отримуємо facing_dir без помилок
	var dir := 1
	var maybe_fd = player.get("facing_dir")
	if typeof(maybe_fd) == TYPE_INT:
		dir = int(maybe_fd)

	# Пет має "виглядати" в той самий бік через scale.x
	_update_sprite_direction(dir)

	# Для слідування тільки коли таймер спрацював
	if is_following:
		# цільова X-позиція — позаду або попереду гравця залежно від facing_dir
		target_x = player.global_position.x + follow_distance * -dir

		# плавний рух тільки по X (lerp)
		var t = clamp(follow_speed * delta, 0.0, 1.0)
		global_position.x = lerp(global_position.x, target_x, t)

		# Y — ЖОРСТКО ГЛОБАЛЬНА (не відносна до гравця)
		global_position.y = global_y

		# Якщо дуже близько до цілі — "припаркувати" пет точно
		if abs(global_position.x - target_x) < 0.5:
			global_position.x = target_x

# таймер timeout -> вмикаємо слідування
func _on_delay_timer_timeout() -> void:
	is_following = true

# Оновлює спрайт у залежності від напрямку; використовуємо scale.x для "фліпу"
func _update_sprite_direction(dir: int) -> void:
	if sprite == null:
		return

	var base_x = abs(sprite.scale.x) if typeof(sprite.scale.x) in [TYPE_FLOAT, TYPE_INT] else 1.0
	# якщо dir < 0 => дивиться вліво => scale.x negative
	if dir < 0:
		sprite.scale.x = -abs(base_x)
	else:
		sprite.scale.x = abs(base_x)

# оновити зовнішній вигляд пета (icon/texture, можна додати scale/anim)
func update_look(pet_data: PetData) -> void:
	if pet_data == null:
		return
	if pet_data.icon:
		sprite.texture = pet_data.icon
