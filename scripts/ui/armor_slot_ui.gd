class_name ArmorSlotClass extends TextureButton  # якщо твій слот — TextureButton, це нормально

@export var slot_type: ItemData.ArmorType = ItemData.ArmorType.NONE

var equipped_item: ItemData = null
@onready var icon = $TextureRect

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if equipped_item != null:
			print("I'm here")
			InventoryManager.show_armor_context_menu(self, get_global_mouse_position())

func set_item(item: ItemData):
	equipped_item = item
	icon.texture = item.icon if item else null

func get_item():
	return equipped_item

func _can_drop_data(_pos, data):
	if typeof(data) == TYPE_DICTIONARY and data.has("item_data"):
		var item = data["item_data"]
		return item.type == ItemData.ItemType.ARMOR and item.armor_type == slot_type
	return false

func _drop_data(_pos, data):
	if _can_drop_data(_pos, data):
		var item = data["item_data"]
		var from_slot = data["from_slot"]
		InventoryManager.equip_armor(item, from_slot)  # Крок 3 — реалізуємо далі
