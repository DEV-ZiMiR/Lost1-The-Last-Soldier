extends Control

@onready var slot_button_1: TextureButton = $Panel/VBoxContainer/SlotButton1
@onready var slot_button_2: TextureButton = $Panel/VBoxContainer/SlotButton2
@onready var slot_button_3: TextureButton = $Panel/VBoxContainer/SlotButton3
@onready var autosave_slot: TextureButton = $Panel/VBoxContainer/SlotButton4
@onready var back_button : TextureButton = $Panel/BackButton

var slot_num: int = 0
var current_world: String = ""
var slot_path : String = ""
	
func _ready():
	slot_button_1.pressed.connect(_on_SlotButton1_pressed)
	slot_button_2.pressed.connect(_on_SlotButton2_pressed)
	slot_button_3.pressed.connect(_on_SlotButton3_pressed)
	autosave_slot.pressed.connect(_on_SlotButton4_pressed)
	back_button.pressed.connect(_on_BackButton_pressed)

	current_world = SaveManager.current_world
	update_slot_buttons()

func update_slot_buttons():
	if current_world == "":
		return # Світ ще не переданий
		print("nope")

	for child in $Panel/VBoxContainer.get_children():
		if child.name.begins_with("SlotButton"):
			var btn_slot_num = int(child.name.trim_prefix("SlotButton"))
			var label = child.get_node("Label")
			if btn_slot_num < 4:
				slot_path = "user://saves/%s/slot_%d.save" % [current_world, btn_slot_num]
			elif btn_slot_num == 4:
				slot_path = "user://saves/%s/autosave.save" % [current_world]

			if FileAccess.file_exists(slot_path):
				var file = FileAccess.open(slot_path, FileAccess.READ)
				var data = JSON.parse_string(file.get_as_text())
				file.close()

				var date = "[No date]"
				if typeof(data) == TYPE_DICTIONARY and data.has("save_date"):
					date = data["save_date"]
				if btn_slot_num < 4:
					label.text = "Slot %d\n%s" % [btn_slot_num, date]
				else:
					label.text = "Autosave\n%s" % [date]
			else:
				if btn_slot_num < 4:
					label.text = "Slot %d\n[Empty]" % btn_slot_num
				else:
					label.text = "Autosave\n[Empty]"

func _on_SlotButton1_pressed(): _select_slot(1)
func _on_SlotButton2_pressed(): _select_slot(2)
func _on_SlotButton3_pressed(): _select_slot(3)
func _on_SlotButton4_pressed(): _select_slot(4)
func _on_BackButton_pressed(): get_tree().change_scene_to_file("res://scenes/world/world_select_ui.tscn")

func _select_slot(num: int):
	slot_num = num
	if num < 4:
		slot_path = "user://saves/%s/slot_%d.save" % [current_world, slot_num]
	elif num == 4:
		slot_path = "user://saves/%s/autosave.save" % [current_world]
	if FileAccess.file_exists(slot_path):
		LoadingScreen.show_loading()
		await get_tree().create_timer(2.0).timeout
		SaveManager.set_current_slot(num)
		SaveManager.set_current_world(current_world)
		SaveManager.load_save()
		# ⬅ Тут твоя логіка при виборі слоту
		print("Вибрано слот №%d" % slot_num)
	else:
		push_error("Empty slot")
