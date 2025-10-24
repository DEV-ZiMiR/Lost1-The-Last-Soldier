extends Control

@onready var continue_button: TextureButton = $VBoxContainer/ContinueButton
@onready var new_game_button: TextureButton = $VBoxContainer/NewGameButton
@onready var load_game_button: TextureButton = $VBoxContainer/LoadGameButton
@onready var settings_button: TextureButton = $VBoxContainer/SettingsButton
@onready var quit_button: TextureButton = $VBoxContainer/QuitButton

func _ready():
	if LoadingScreen.is_loading == true:
		LoadingScreen.hide_loading()
	continue_button.pressed.connect(on_continue_pressed)
	new_game_button.pressed.connect(on_new_game_pressed)
	load_game_button.pressed.connect(on_load_game_pressed)
	settings_button.pressed.connect(on_settings_pressed)
	quit_button.pressed.connect(on_quit_pressed)

# 🟢 ПРОДОВЖИТИ ГРУ (остання)
func on_continue_pressed():
	LoadingScreen.show_loading()
	await get_tree().create_timer(2).timeout
	SaveManager.continue_game()

# 🟡 НОВА ГРА
func on_new_game_pressed():
	# відкриваємо сцену вибору світу для нової гри
	SaveManager.set_game_mode(true)
	get_tree().change_scene_to_file("res://scenes/world/world_select_ui.tscn")

# 🔵 ЗАВАНТАЖИТИ ГРУ
func on_load_game_pressed():
	# відкриваємо сцену вибору світу/збереження
	SaveManager.set_game_mode(false)
	get_tree().change_scene_to_file("res://scenes/world/world_select_ui.tscn")

# ⚙️ НАЛАШТУВАННЯ
func on_settings_pressed():
	# Завантажуємо сцену налаштувань
	var settings_scene = load("res://scenes/world/settings_ui.tscn")
	var settings_instance = settings_scene.instantiate()

	# Викликаємо функцію в сцені налаштувань (якщо є така функція)
	settings_instance.is_main_menu(true)

	# Замінюємо поточну сцену на налаштування
	get_tree().root.add_child(settings_instance)
	get_tree().current_scene = settings_instance


# 🔴 ВИХІД
func on_quit_pressed():
	get_tree().quit()
