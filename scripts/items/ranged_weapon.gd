extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

# зберігаємо базові значення масштабу
var base_scale_x: float = 1.0
var base_scale_y: float = 1.0
var base_scale_sign_x: float = 1.0

# логічний кут в градусах
var logical_angle_deg: float = 0.0

# опціональний дебаг
var DEBUG := false

func _ready() -> void:
	if sprite:
		base_scale_x = abs(sprite.scale.x)
		base_scale_y = abs(sprite.scale.y)
		base_scale_sign_x = sign(sprite.scale.x) if sprite.scale.x != 0 else 1.0

# --- API: викликай один з них з гравця ---
func set_aim_angle_rad(angle_rad: float) -> void:
	set_aim_angle_deg(rad_to_deg(angle_rad))

func set_aim_angle_deg(angle_deg: float) -> void:
	logical_angle_deg = _normalize_deg(angle_deg)
	_apply_transform_from_logical()

func set_aim_direction(dir: Vector2) -> void:
	if dir.length_squared() == 0:
		return
	set_aim_angle_rad(dir.angle())

# --- Внутрішня логіка застосування трансформації ---
func _apply_transform_from_logical() -> void:
	if sprite == null:
		return

	var ang := _normalize_deg(logical_angle_deg)  # логічний кут (-180,180]

	# чи потрібно дзеркалити? (поза межами -90..90)
	var need_mirror := (ang > 90.0) or (ang < -90.0)

	# якщо дзеркалимо — зрушуємо кут на +/-180, щоб візуально напрямок залишився очікуваним
	var display_angle := ang
	if need_mirror:
		display_angle = ang - 180.0 * sign(ang)

	# нормалізуємо кінцевий відображуваний кут
	display_angle = _normalize_deg(display_angle)

	# застосовуємо scale.x з урахуванням початкового знаку
	var final_scale_sign := (-1.0 if need_mirror else 1.0)
	sprite.scale = Vector2(base_scale_x * base_scale_sign_x * final_scale_sign, base_scale_y)

	# застосовуємо обертання на спрайт (у градусах)
	sprite.rotation_degrees = display_angle

	if DEBUG:
		print("logical:", ang, "need_mirror:", need_mirror, "display:", display_angle, "sprite.scale.x:", sprite.scale.x)

# допоміжна: нормалізація градусів до (-180, 180]
func _normalize_deg(a: float) -> float:
	var res = fmod(a + 180.0, 360.0)
	if res < 0.0:
		res += 360.0
	return res - 180.0
