extends Node
class_name GameTimeManagerClass

signal new_day_started(day: int)
signal phase_changed(phase: int)

enum Phase { DAWN, DAY, DUSK, NIGHT }

# -------- Налаштування циклу --------
@export var day_length: float = 120.0         # повна довжина доби, сек
@export var dawn_len: float = 12.0            # світанок
@export var day_len: float = 60.0            # день
@export var dusk_len: float = 12.0            # захід (ніч = решта)

# Базові кольори/яскравість для фаз (можеш міняти під свій стиль)
@export var night_tint: Color = Color(0.12, 0.12, 0.24)
@export var dawn_tint:  Color = Color(1.00, 0.85, 0.65)
@export var day_tint:   Color = Color(1, 1, 1)
@export var dusk_tint:  Color = Color(1.00, 0.90, 0.70)

@export var night_brightness: float = 0.30
@export var day_brightness:   float = 1.00

# -------- Список сцен, у яких годинник має призупинятись --------
# Додай сюди PackedScene через інспектор (або через preload у коді).
# Наприклад: paused_scene_resources = [ preload("res://scenes/menu.tscn") ]
@export var paused_scene_resources: Array[PackedScene] = []

# -------- Поточний стан --------
var current_time: float = 0.0
var current_day: int = 1
var _phase: Phase = Phase.NIGHT

# -------- Посилання на ноди/матеріал --------
@onready var fx_layer: CanvasLayer = $PostFX
@onready var fx_rect: ColorRect   = $PostFX/DayNightFX
@onready var fx_mat: ShaderMaterial = fx_rect.material as ShaderMaterial

# інтернал для швидкої перевірки шляхів сцен
var _paused_scene_paths: Array[String] = []

# стан паузи
var _is_paused_by_scene: bool = false

func _ready() -> void:
	# гарантуємо, що ColorRect покриває екран і не ловить мишу
	if fx_rect:
		fx_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# зберемо шляхи paused сцен (resource_path) для швидких порівнянь
	_paused_scene_paths.clear()
	for ps in paused_scene_resources:
		if ps != null:
			# PackedScene має властивість resource_path; якщо її немає в твоїй версії — заміни
			var p := ""
			if "resource_path" in ps: # безпечна перевірка
				p = ps.resource_path
			else:
				# запасний варіант: спробуємо отримати шлях через tostring або через опис
				p = str(ps)
			if p != "":
				_paused_scene_paths.append(p)

	_update_phase_and_fx() # початкове застосування ефектів

func _process(delta: float) -> void:
	# перевірка чи поточна сцена входить до списку паузних сцен
	var should_pause := _is_current_scene_in_paused_list()

	# стан змінився — вмикаємо/вимикаємо ефекти і друкуємо повідомлення
	if should_pause and not _is_paused_by_scene:
		# перейшли в паузну сцену
		_is_paused_by_scene = true
		_on_pause_start()
		return # не нарощуємо час у цей кадр

	elif not should_pause and _is_paused_by_scene:
		# вийшли з паузної сцени — відновлюємо
		_is_paused_by_scene = false
		_on_pause_end()
		# нехай далі виконається оновлення часу у цьому кадрі (за бажанням)

	# якщо зараз пауза — не крокаємо годинник
	if _is_paused_by_scene:
		return

	# звичайна робота годинника
	current_time += delta
	if current_time >= day_length:
		current_time = 0.0
		current_day += 1
		emit_signal("new_day_started", current_day)
	_update_phase_and_fx()

# повертає true якщо поточна сцена є в списку паузних
func _is_current_scene_in_paused_list() -> bool:
	var cur_scene := get_tree().current_scene
	if cur_scene == null:
		return false
	# в коді раніше ти використовував current_scene.scene_file_path
	var cur_path := ""
	if "scene_file_path" in cur_scene:
		cur_path = cur_scene.scene_file_path
	elif "get_filename" in cur_scene:
		cur_path = cur_scene.get_filename() # запасний
	else:
		# остання надія: to_string
		cur_path = str(cur_scene)

	# порівнюємо з підготовленими шляхами
	for p in _paused_scene_paths:
		if p == "":
			continue
		# пряме порівняння рядків (повний шлях)
		if cur_path == p:
			return true
		# інколи шляхи можуть різнитися в способі запису — перевіримо суфікс
		if cur_path.ends_with(p) or p.ends_with(cur_path):
			return true

	return false

# виклик при вході в паузну сцену
func _on_pause_start() -> void:
	# Вимикаємо FX (прибираємо шейдерний вплив)
	if fx_layer:
		fx_layer.visible = false
	# додатково: якщо хочеш повністю скинути параметри шейдера, можна:
	# if fx_mat: fx_mat.set_shader_parameter("u_brightness", 1.0)  # приклад

	print("Годинник призупинено")
	# МІСЦЕ ДЛЯ ДОП. ЛОГІКИ: ТУТ МОЖЕШ ДОДАТИ ДІЇ ПРИ ПАУЗІ (наприклад виклик SaveManager або інші)
	# --- <ТУТ ВСТАВ ТВОЇ СЦЕНИ/ЛОГІКУ> ---

# виклик при виході з паузної сцени
func _on_pause_end() -> void:
	# Вмикаємо FX назад
	if fx_layer:
		fx_layer.visible = true
	# можеш відновити параметри шейдера, якщо зберігав раніше
	print("Годинник відновлено")

# -------- Публічні методи --------
func get_phase() -> Phase:
	return _phase

func set_time(seconds: float) -> void:
	current_time = clampf(seconds, 0.0, day_length)
	_update_phase_and_fx()

func set_time_normalized01(v: float) -> void:
	current_time = clampf(v, 0.0, 1.0) * day_length
	_update_phase_and_fx()

# -------- Внутрішня логіка (без змін) --------
func _update_phase_and_fx() -> void:
	var p := current_time / maxf(day_length, 0.001)

	var dawn_end := dawn_len / day_length
	var day_end  := (dawn_len + day_len) / day_length
	var dusk_end := (dawn_len + day_len + dusk_len) / day_length

	var brightness := day_brightness
	var tint := day_tint

	# 🔹 Безперервна плавна зміна між усіма фазами:
	if p < dawn_end:
		# ніч → світанок
		var t := _smooth_step(_safe_div(p, dawn_end))
		_set_phase(Phase.DAWN)
		brightness = lerp(night_brightness, day_brightness, t)
		tint = night_tint.lerp(dawn_tint, t)

	elif p < day_end:
		# світанок → день (плавний перехід)
		var t := _smooth_step(_safe_div(p - dawn_end, day_end - dawn_end))
		_set_phase(Phase.DAY)
		brightness = lerp(day_brightness * 0.9, day_brightness, t)
		tint = dawn_tint.lerp(day_tint, t)

	elif p < dusk_end:
		# день → захід
		var t := _smooth_step(_safe_div(p - day_end, dusk_end - day_end))
		_set_phase(Phase.DUSK)
		brightness = lerp(day_brightness, night_brightness, t)
		tint = day_tint.lerp(dusk_tint, t)

	else:
		# захід → ніч (плавно в ніч)
		var t := _smooth_step(_safe_div(p - dusk_end, 1.0 - dusk_end))
		_set_phase(Phase.NIGHT)
		brightness = lerp(night_brightness * 0.8, night_brightness, t)
		tint = dusk_tint.lerp(night_tint, t)

	_apply_fx(brightness, tint)

func _smooth_step(x: float) -> float:
	# Робить перехід дуже плавним на початку й в кінці
	return clampf(x * x * (3.0 - 2.0 * x), 0.0, 1.0)

func _apply_fx(brightness: float, tint: Color) -> void:
	# якщо годинник зараз паузиться зовні — не застосовуємо FX
	if _is_paused_by_scene:
		return

	if fx_mat:
		fx_mat.set_shader_parameter("u_brightness", brightness)
		fx_mat.set_shader_parameter("u_contrast", 1.0)
		fx_mat.set_shader_parameter("u_saturation", 1.0)
		fx_mat.set_shader_parameter("u_tint", Color(tint.r, tint.g, tint.b, 1.0))
	else:
		# запасний варіант: просто затемнення альфою, якщо раптом шейдера немає
		if fx_rect:
			fx_rect.modulate = Color(0, 0, 0, 1.0 - brightness)

func _set_phase(p: Phase) -> void:
	if p != _phase:
		_phase = p
		emit_signal("phase_changed", _phase)

func _safe_div(a: float, b: float) -> float:
	return (a / b) if b != 0.0 else 0.0
