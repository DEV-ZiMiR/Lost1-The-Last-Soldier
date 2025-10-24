extends CanvasLayer

@onready var continue_button: TextureButton = $Panel/Panel/VBoxContainer/ResumeButton
@onready var settings_button: TextureButton = $Panel/Panel/VBoxContainer/SettingsButton
@onready var quit_button: TextureButton = $Panel/Panel/VBoxContainer/ExitButton
@onready var save_button: TextureButton = $Panel/Panel/VBoxContainer/HBoxContainer/SaveButton
@onready var load_button: TextureButton = $Panel/Panel/VBoxContainer/HBoxContainer/LoadButton
@onready var info_ui_button: TextureButton = $Panel/Panel/VBoxContainer/HBoxContainer/InfoButton

# --- SAVE панель ---
@onready var save_panel: Panel = $Panel/Panel2
@onready var save_slot1: TextureButton = $Panel/Panel2/VBoxContainer/Slot1
@onready var save_slot2: TextureButton = $Panel/Panel2/VBoxContainer/Slot2
@onready var save_slot3: TextureButton = $Panel/Panel2/VBoxContainer/Slot3
@onready var save_cancel: TextureButton = $Panel/Panel2/VBoxContainer/HBoxContainer/CancelButton
@onready var save_in_slot_button: TextureButton = $Panel/Panel2/VBoxContainer/HBoxContainer/SaveInSlotButton

# --- LOAD панель ---
@onready var load_panel: Panel = $Panel/Panel3
@onready var load_slot1: TextureButton = $Panel/Panel3/ScrollContainer/VBoxContainer/Slot1
@onready var load_slot2: TextureButton = $Panel/Panel3/ScrollContainer/VBoxContainer/Slot2
@onready var load_slot3: TextureButton = $Panel/Panel3/ScrollContainer/VBoxContainer/Slot3
@onready var load_slot4: TextureButton = $Panel/Panel3/ScrollContainer/VBoxContainer/Slot4
@onready var load_cancel: TextureButton = $Panel/Panel3/HBoxContainer/CancelButton
@onready var load_from_slot_button: TextureButton = $Panel/Panel3/HBoxContainer/LoadFromSlotButton

@export var settings_scene: PackedScene
var settings_instance: Node = null

@export var info_ui: PackedScene
var info_ui_scene: Node = null
# --- вибрані слоти ---
var save_slot: int = 0
var load_slot: int = 0

func _ready():
	hide()
	# основні кнопки
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	info_ui_button.pressed.connect(_on_info_ui_pressed)

	# save popup
	save_slot1.pressed.connect(func(): save_slot = 1)
	save_slot2.pressed.connect(func(): save_slot = 2)
	save_slot3.pressed.connect(func(): save_slot = 3)
	save_cancel.pressed.connect(_on_save_cancel_pressed)
	save_in_slot_button.pressed.connect(_on_save_in_slot_pressed)

	# load popup
	load_slot1.pressed.connect(func(): load_slot = 1)
	load_slot2.pressed.connect(func(): load_slot = 2)
	load_slot3.pressed.connect(func(): load_slot = 3)
	load_slot4.pressed.connect(func(): load_slot = 4)
	load_cancel.pressed.connect(_on_load_cancel_pressed)
	load_from_slot_button.pressed.connect(_on_load_from_slot_pressed)

	# спочатку ховаємо popup-и
	save_panel.visible = false
	load_panel.visible = false

# ========== PAUSE ==========

func show_pause_menu():
	visible = true
	get_tree().paused = true

func hide_pause_menu():
	var inventory_ui = get_tree().root.get_node("Game/PlayerUI/InventoryUI")
	inventory_ui.visible = false
	visible = false
	get_tree().paused = false

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if visible:
			hide_pause_menu()
		else:
			show_pause_menu()

func _on_continue_pressed():
	hide_pause_menu()

# ========== SETTINGS ==========

func _on_settings_pressed():
	if settings_instance and is_instance_valid(settings_instance):
		return
	settings_instance = settings_scene.instantiate()
	add_child(settings_instance)
	if settings_instance.has_method("is_main_menu"):
		settings_instance.is_main_menu(false)

# ========== QUIT ==========

func _on_quit_pressed():
	Engine.time_scale = 1.0
	get_tree().paused = false
	LoadingScreen.show_loading()
	SaveManager.autosave()
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/world/main_menu.tscn")

func _on_info_ui_pressed():
	if info_ui_scene and is_instance_valid(settings_instance):
		return
	info_ui_scene = info_ui.instantiate()
	add_child(info_ui_scene)
# ========== SAVE POPUP ==========

func _on_save_pressed():
	save_panel.visible = true
	save_slot = 0 # скидаємо

func _on_save_cancel_pressed():
	save_panel.visible = false
	save_slot = 0

func _on_save_in_slot_pressed():
	if save_slot == 0:
		print("⚠️ Слот не вибрано!")
		return
	print("💾 Зберігаю у слот ", save_slot)
	# тут твоя логіка збереження
	SaveManager.set_current_slot(save_slot)
	SaveManager.save_game()
	save_panel.visible = false
	save_slot = 0

# ========== LOAD POPUP ==========

func _on_load_pressed():
	load_panel.visible = true
	load_slot = 0 # скидаємо

func _on_load_cancel_pressed():
	load_panel.visible = false
	load_slot = 0

func _on_load_from_slot_pressed():
	if load_slot == 0:
		print("⚠️ Слот не вибрано!")
		return
	print("📂 Завантажую зі слоту ", load_slot)
	LoadingScreen.show_loading()
	Engine.time_scale = 1.0
	get_tree().paused = false
	await get_tree().create_timer(2.0).timeout
	SaveManager.set_current_slot(load_slot)
	SaveManager.load_save()
	
	# тут твоя логіка завантаження
	load_panel.visible = false
	load_slot = 0
