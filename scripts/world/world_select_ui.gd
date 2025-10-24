extends Control

@onready var world_slot_1: TextureButton = $Panel/VBoxContainer/SlotButton1
@onready var world_slot_2: TextureButton = $Panel/VBoxContainer/SlotButton2
@onready var world_slot_3: TextureButton = $Panel/VBoxContainer/SlotButton3
@onready var back_button : TextureButton = $Panel/BackButton

var slot_num : int = 0

func _ready():
	world_slot_1.pressed.connect(_on_SlotButton1_pressed)
	world_slot_2.pressed.connect(_on_SlotButton2_pressed)
	world_slot_3.pressed.connect(_on_SlotButton3_pressed)
	back_button.pressed.connect(_on_BackButton_pressed)
	update_slot_buttons()

func update_slot_buttons():
	for child in $Panel/VBoxContainer.get_children():
		if child.name.begins_with("SlotButton"):
			var slot_num = int(child.name.trim_prefix("SlotButton"))
			var label = child.get_node("Label")
			var world_path = "user://saves/world_%d" % slot_num

			var has_files = false
			if DirAccess.dir_exists_absolute(world_path):
				var dir = DirAccess.open(world_path)
				if dir:
					dir.list_dir_begin()
					var file_name = dir.get_next()
					while file_name != "":
						if not dir.current_is_dir(): # Це файл
							has_files = true
							break
						file_name = dir.get_next()
					dir.list_dir_end()

			if has_files:
				label.text = "World %d" % slot_num
			else:
				label.text = "World %d\n[Empty]" % slot_num



func _on_SlotButton1_pressed(): _select_world(1)
func _on_SlotButton2_pressed(): _select_world(2)
func _on_SlotButton3_pressed(): _select_world(3)
func _on_BackButton_pressed(): get_tree().change_scene_to_file("res://scenes/world/main_menu.tscn")

func _select_world(world_num: int):
	var world_name = "world_%d" % world_num
	SaveManager.set_current_world(world_name)

	if SaveManager.is_new_game:
		_handle_new_game_selection(world_name)
		print("lol")
	else:
		# Якщо це завантаження — йдемо в Slot Select
		SaveManager.set_current_world(world_name)
		get_tree().change_scene_to_file("res://scenes/world/select_slot_ui.tscn")

func _handle_new_game_selection(world_name: String):
	var save_path = "user://saves/%s/savegame.save" % world_name
	
	if FileAccess.file_exists(save_path):
		# ⚠ Показуємо підтвердження перезапису
		_show_overwrite_confirmation(world_name)
	else:
		# Знаходимо перший вільний слот і створюємо нову гру
		_create_in_first_empty_slot(world_name)

func _show_overwrite_confirmation(world_name: String):
	print("⚠ Світ вже існує: %s. Підтвердити перезапис?" % world_name)
	# Тут можна відкрити Popup з кнопками "Так" / "Ні"

func _create_in_first_empty_slot(world_name: String):
	for slot in range(1, 4):
		var slot_path = "user://saves/%s/slot_%d.save" % [world_name, slot]
		if not FileAccess.file_exists(slot_path):
			LoadingScreen.show_loading()
			await get_tree().create_timer(2).timeout
			SaveManager.create_new_game(world_name, slot)
			print("yo")
# тут можна одразу викликати сцену старту гри

			return
	
	print("❌ Немає вільних слотів у цьому світі!")
