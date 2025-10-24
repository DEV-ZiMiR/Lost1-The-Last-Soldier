extends Control

const SETTINGS_PATH := "user://settings.cfg"

@onready var volume_slider : HSlider = $Panel/ScrollContainer/VBoxContainer/GameVolume/HSlider
@onready var volume_input : LineEdit = $Panel/ScrollContainer/VBoxContainer/GameVolume/LineEdit
@onready var display_mode : OptionButton = $Panel/ScrollContainer/VBoxContainer/DisplayMode/OptionButton
@onready var language_select : OptionButton = $Panel/ScrollContainer/VBoxContainer/Language/OptionButton
@onready var fps_spin : SpinBox = $Panel/ScrollContainer/VBoxContainer/FPS/SpinBox
@onready var show_fps_check : CheckBox = $Panel/ScrollContainer/VBoxContainer/FPS/CheckBox
@onready var back_button : TextureButton = $BackButton

var main_menu : bool = false
# Упорядкований список мов (name + код). Російську замінив на українську.
var SUPPORTED_LANGS := [
	{"name":"English",              "code":"en"},
	{"name":"Українська",           "code":"uk"},
	{"name":"Deutsch",              "code":"de"},
	{"name":"Français",             "code":"fr"},
	{"name":"Español",              "code":"es"},
	{"name":"Italiano",             "code":"it"},
	{"name":"Polski",               "code":"pl"},
	{"name":"Português (Brasil)",   "code":"pt"},
	{"name":"日本語",                "code":"ja"},
	{"name":"한국어",                "code":"ko"},
	{"name":"简体中文",              "code":"zh_Hans"},
	{"name":"繁體中文",              "code":"zh_Hant"}
]

func _ready() -> void:
	# Ініціалізуємо UI (мова в OptionButton з metadata)
	_setup_display_mode_options()
	_setup_languages()

	# Підключаємо сигнали
	volume_slider.connect("value_changed", Callable(self, "_on_volume_slider_changed"))
	volume_input.connect("text_changed", Callable(self, "_on_volume_input_changed"))
	display_mode.connect("item_selected", Callable(self, "_on_display_mode_changed"))
	language_select.connect("item_selected", Callable(self, "_on_language_changed"))
	fps_spin.connect("value_changed", Callable(self, "_on_fps_changed"))
	show_fps_check.connect("toggled", Callable(self, "_on_show_fps_changed"))
	back_button.pressed.connect(_on_BackButton_pressed)

	# Завантажуємо збереження і застосовуємо налаштування
	load_settings()

	# Гарантія збереження при закритті сцени/виході
	# _exit_tree виконає save_settings при видаленні ноди (закриття сцени/вихід)
	
func _on_BackButton_pressed():
	if main_menu == true:
		get_tree().change_scene_to_file("res://scenes/world/main_menu.tscn")
	elif main_menu == false:
		queue_free()
# ───────────────────────── ІНІЦІАЛІЗАЦІЯ UI ─────────────────────────
func _setup_languages() -> void:
	language_select.clear()
	for i in SUPPORTED_LANGS.size():
		var entry = SUPPORTED_LANGS[i]
		language_select.add_item(entry.name)
		language_select.set_item_metadata(i, entry.code)

# Якщо в майбутньому треба динамічно наповнювати режим вікна — тут place для цього.
func _setup_display_mode_options() -> void:
	if display_mode.get_item_count() == 0:
		display_mode.add_item("Fullscreen (Windowed fullscreen)") # 0
		display_mode.add_item("Fullscreen (Borderless)")          # 1
		display_mode.add_item("Windowed")                         # 2


# ───────────────────────── ЗВУК ─────────────────────────
func _on_volume_slider_changed(value: float) -> void:
	var v := int(clamp(value, 0, 100))
	volume_input.text = str(v)
	_apply_volume(v)
	save_settings_deferred()

func _on_volume_input_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		var v := int(clamp(int(new_text), 0, 100))
		# оновлюємо слайдер без повторного виклику (ті самі сигнали)
		if volume_slider.value != v:
			volume_slider.value = v
		_apply_volume(v)
		save_settings_deferred()

func _apply_volume(value_0_100: int) -> void:
	var bus := AudioServer.get_bus_index("Master")
	# linear [0..1] -> dB
	var linear := float(value_0_100) / 100.0
	AudioServer.set_bus_volume_db(bus, linear_to_db(clamp(linear, 0.0, 1.0)))


# ───────────────────────── РЕЖИМ ВІКНА ─────────────────────────
func _on_display_mode_changed(index: int) -> void:
	_apply_display_mode(index)
	save_settings_deferred()

func _apply_display_mode(index: int) -> void:
	# Спочатку скидати borderless, щоб уникнути "залишкових" прапорів
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


# ───────────────────────── МОВА ─────────────────────────
func _on_language_changed(index: int) -> void:
	var code = language_select.get_item_metadata(index)
	_apply_language(code)
	save_settings_deferred()

func _apply_language(lang_code: String) -> void:
	if lang_code == null or lang_code == "":
		return
	# Перекладач чекає код локалі
	TranslationServer.set_locale(str(lang_code))


# ───────────────────────── FPS ─────────────────────────
func _on_fps_changed(value: float) -> void:
	_apply_fps_limit(int(value))
	save_settings_deferred()

func _apply_fps_limit(value: int) -> void:
	Engine.set_max_fps(value if value > 0 else 0)

func _on_show_fps_changed(pressed: bool) -> void:
	_apply_show_fps(pressed)
	save_settings_deferred()

func _apply_show_fps(pressed: bool) -> void:
	# Ми зберігаємо стан у своєму конфі — і тут застосовуємо до ProjectSettings/runtime,
	# щоб відобразити FPS-оверлей під час гри (залежать від рушія).
	ProjectSettings.set_setting("debug/settings/fps/visible", pressed)
	# Не викликаємо ProjectSettings.save() тут, бо ми зберігаємо у user://settings.cfg


# ───────────────────────── ЗБЕРЕЖЕННЯ / ЗАВАНТАЖЕННЯ ─────────────────────────
func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", int(volume_slider.value))
	cfg.set_value("video", "display_mode_index", int(display_mode.get_selected()))
	# Зберігаємо код мови (надійніше за індекс)
	var lang_code = language_select.get_item_metadata(language_select.get_selected())
	cfg.set_value("gameplay", "language_code", lang_code)
	cfg.set_value("video", "fps_limit", int(fps_spin.value))
	cfg.set_value("video", "show_fps", show_fps_check.button_pressed)
	var err := cfg.save(SETTINGS_PATH)
	if err != OK:
		push_error("Не вдалося зберегти налаштування: %s" % str(err))

# Викликаємо трохи відкладено, щоб не робити часті записи на диск при швидкому зміненні слайдера
var _save_debounce_timer := Timer.new()
func save_settings_deferred(wait_time: float = 0.25) -> void:
	if not is_inside_tree():
		return
	if not _save_debounce_timer.is_processing():
		_save_debounce_timer.one_shot = true
		_save_debounce_timer.wait_time = wait_time
		_save_debounce_timer.connect("timeout", Callable(self, "_on_save_debounce_timeout"), Object.CONNECT_ONE_SHOT)
		add_child(_save_debounce_timer)
		_save_debounce_timer.start()
	else:
		# оновлюємо таймер (перезапуск)
		_save_debounce_timer.start()


func _on_save_debounce_timeout() -> void:
	save_settings()
	# Очистити таймер
	if is_instance_valid(_save_debounce_timer):
		_save_debounce_timer.queue_free()
		_save_debounce_timer = Timer.new()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		# Застосувати значення або значення за замовчуванням
		var vol := int(cfg.get_value("audio", "volume", 100))
		volume_slider.value = clamp(vol, 0, 100)
		volume_input.text = str(int(volume_slider.value))
		_apply_volume(int(volume_slider.value))

		var dm_idx := int(cfg.get_value("video", "display_mode_index", 0))
		if dm_idx < 0 or dm_idx >= display_mode.get_item_count():
			dm_idx = 0
		display_mode.select(dm_idx)
		_apply_display_mode(dm_idx)

		var lang_code := str(cfg.get_value("gameplay", "language_code", SUPPORTED_LANGS[0].code))
		var lang_idx := _find_language_index_by_code(lang_code)
		if lang_idx >= 0:
			language_select.select(lang_idx)
			_apply_language(lang_code)
		else:
			# fallback: обираємо першу мову
			language_select.select(0)
			_apply_language(language_select.get_item_metadata(0))

		var fps := int(cfg.get_value("video", "fps_limit", 0))
		fps_spin.value = fps
		_apply_fps_limit(fps)

		var show = bool(cfg.get_value("video", "show_fps", false))
		show_fps_check.button_pressed = show
		_apply_show_fps(show)
	else:
		# Якщо файлу немає — ініціалізація дефолтних значень
		volume_slider.value = 100
		volume_input.text = "100"
		_apply_volume(100)
		display_mode.select(0)
		_apply_display_mode(0)
		language_select.select(0)
		_apply_language(language_select.get_item_metadata(0))
		fps_spin.value = 0
		_apply_fps_limit(0)
		show_fps_check.button_pressed = false
		_apply_show_fps(false)

func _find_language_index_by_code(code: String) -> int:
	for i in range(language_select.get_item_count()):
		if language_select.get_item_metadata(i) == code:
			return i
	return -1

func is_main_menu(it_is : bool):
	if it_is == true:
		main_menu = true
	else:
		main_menu = false
		
# Гарантовано зберігаємо налаштування при виході/видаленні ноди
func _exit_tree() -> void:
	save_settings()
