extends Panel

# --- Тип дії (анімація зліва)
enum ActionType { JUMP, ATTACK, MOVE, SIT, HOTBAR, UNEQUIP_ITEM, INTERACT, OPEN_INVENTORY, SLIDE, ESC }

var _action_type: ActionType = ActionType.JUMP
@export var action_type: ActionType:
	get: return _action_type
	set(value):
		_action_type = value
		call_deferred("_update_action")

# --- Кількість кнопок (1 або 2)
@export_range(1, 2, 1)
var _button_count: int = 1
@export var button_count: int:
	get: return _button_count
	set(value):
		_button_count = value
		call_deferred("_update_buttons_visibility")

# --- Кнопки (назви/іконки), список однаковий
enum ButtonType { SPACE, LMB, CTRL, TAB, W, A, S, D, E, X, ONE, FIVE, ESC }

var _button1: ButtonType = ButtonType.SPACE
@export var button1: ButtonType:
	get: return _button1
	set(value):
		_button1 = value
		call_deferred("_update_button1")

var _button2: ButtonType = ButtonType.LMB
@export var button2: ButtonType:
	get: return _button2
	set(value):
		_button2 = value
		call_deferred("_update_button2")


# --- посилання на ноди
@onready var action_anim: AnimatedSprite2D = $HBoxContainer/AnimatedSprite2D
@onready var button_anim1: AnimatedSprite2D = $HBoxContainer/VBoxContainer/AnimatedSprite2D
@onready var action_label: Label = $HBoxContainer/VBoxContainer/Label
@onready var button_anim2: AnimatedSprite2D = $HBoxContainer/VBoxContainer/AnimatedSprite2D2
@onready var plus_label: Label = $HBoxContainer/VBoxContainer/Label2


# --- словник для кнопки -> анімація
var BUTTON_ANIMATIONS := {
	ButtonType.SPACE: "space",
	ButtonType.LMB: "mouse_left",
	ButtonType.CTRL: "control",
	ButtonType.TAB: "tab",
	ButtonType.X: "x",
	ButtonType.ONE: "one",
	ButtonType.FIVE: "five",
	ButtonType.W: "key_w",
	ButtonType.A: "key_a",
	ButtonType.S: "key_s",
	ButtonType.D: "key_d",
	ButtonType.E: "key_e",
	ButtonType.ESC: "esc"
}

# --- словник для дій (анімація зліва)
var ACTION_ANIMATIONS := {
	ActionType.JUMP: "jump",
	ActionType.ATTACK: "attack",
	ActionType.MOVE: "move",
	ActionType.SIT: "sit",
	ActionType.HOTBAR: "hotbar",
	ActionType.UNEQUIP_ITEM: "unequip item",
	ActionType.OPEN_INVENTORY: "open inventory",
	ActionType.INTERACT: "interact",
	ActionType.SLIDE: "slide",
	ActionType.ESC: "esc"
}

# --- словник для текстових назв дій
var ACTION_NAMES := {
	ActionType.JUMP: "Jump",
	ActionType.ATTACK: "Attack",
	ActionType.MOVE: "Move",
	ActionType.SIT: "Sit",
	ActionType.HOTBAR: "Hotbar",
	ActionType.UNEQUIP_ITEM: "Unequip Item",
	ActionType.OPEN_INVENTORY: "Open Inventory",
	ActionType.INTERACT: "Interact",
	ActionType.SLIDE: "Slide",
	ActionType.ESC: "Open pause menu"
}


# --- оновлення (з захистом від null) ---
func _update_action() -> void:
	if action_anim == null and action_label == null:
		call_deferred("_update_action")
		return

	if is_instance_valid(action_anim):
		var anim_name = ACTION_ANIMATIONS.get(_action_type, "")
		if anim_name != "":
			action_anim.play(anim_name)
	if is_instance_valid(action_label):
		action_label.text = ACTION_NAMES.get(_action_type, "???")


func _update_button1() -> void:
	if button_anim1 == null:
		call_deferred("_update_button1")
		return
	if is_instance_valid(button_anim1):
		var anim = BUTTON_ANIMATIONS.get(_button1, "")
		if anim != "":
			button_anim1.play(anim)


func _update_button2() -> void:
	if button_anim2 == null:
		return
	if is_instance_valid(button_anim2):
		var anim = BUTTON_ANIMATIONS.get(_button2, "")
		if anim != "":
			button_anim2.play(anim)


func _update_buttons_visibility() -> void:
	if button_anim1 == null:
		call_deferred("_update_buttons_visibility")
		return

	var b2_valid := button_anim2 != null and is_instance_valid(button_anim2)
	var plus_valid := plus_label != null and is_instance_valid(plus_label)

	if _button_count == 1:
		if b2_valid:
			button_anim2.visible = false
		if plus_valid:
			plus_label.text = ""
		if is_instance_valid(button_anim1):
			button_anim1.position = Vector2(150, 71)
	else:
		if b2_valid:
			button_anim2.visible = true
		if plus_valid:
			plus_label.text = "+"
		if is_instance_valid(button_anim1):
			button_anim1.position = Vector2(106, 70)


# --- _ready ---
func _ready() -> void:
	await get_tree().process_frame
	_update_action()
	_update_button1()
	_update_button2()
	_update_buttons_visibility()
