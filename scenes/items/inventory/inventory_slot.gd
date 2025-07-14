extends TextureButton
class_name InventorySlotClass

@export var item_data: ItemData
@export var amount: int = 0

@onready var icon: TextureRect = $Icon
@onready var count_label: Label = $AmountLabel


func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Якщо це був клік, а не drag
		if not get_viewport().gui_is_dragging() and item_data != null:
			InventoryManager.show_item_context_menu(self, get_global_mouse_position())
		elif get_viewport().gui_is_dragging() and item_data != null:
			print("→ GUI_INPUT works")
			var preview = TextureRect.new()
			preview.texture = icon.texture
			preview.expand_mode = TextureRect.EXPAND_KEEP_SIZE
			preview.size = Vector2(32, 32)
			set_drag_preview(preview)

func _ready():
	update_slot()
	
func try_add_item(item: ItemData) -> bool:
	if item_data == null:
		item_data = item
		amount = 1
		update_slot()
		return true
	elif item_data.id == item.id and amount < item.max_stack:
		amount += 1
		update_slot()
		return true
	return false

func set_item(item: ItemData, quantity: int):
	item_data = item
	amount = quantity
	update_slot()

func _get_drag_data(position):
	print("→ get_drag_data triggered!")
	var preview = TextureRect.new()
	preview.texture = icon.texture
	preview.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	preview.size = Vector2(32, 32)
	set_drag_preview(preview)

	return {
		"item_data": item_data,
		"amount": amount,
		"from_slot": self,
	}

func _can_drop_data(position, data):
	print("→ can_drop_data")
	return data.has("item_data") and data.from_slot != self

func _drop_data(position, data):
	print("→ drop_data")
	# Міняємо місцями
	var temp_data = item_data
	var temp_amount = amount

	item_data = data.item_data
	amount = data.amount

	data.from_slot.item_data = temp_data
	data.from_slot.amount = temp_amount

	update_slot()
	data.from_slot.update_slot()

func update_slot():
	if item_data != null:
		icon.texture = item_data.icon
		count_label.text = str(amount)
		icon.visible = true
		count_label.visible = amount > 1
	else:
		icon.texture = null
		count_label.text = ""
		icon.visible = false
		count_label.visible = false
		
func clear_item():
	item_data = null
	amount = 0
	update_slot()
