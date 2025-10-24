extends TextureButton
class_name InventoryHotbarClass

@export var item_data: ItemData
@export var amount: int = 0

@onready var icon = $Icon
@onready var count_label = $AmountLabel

func _ready():
	update_slot()
	connect("pressed", Callable(self, "_on_slot_pressed"))

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


# 🟢 Обробка кліку
func _on_slot_pressed():
	if item_data == null:
		return

	if InventoryManager.inventory_open:
		_open_hotbar_menu()
	else:
		_select_slot()


# 🟣 Виклик меню Drop / Unequip
func _open_hotbar_menu():
	InventoryManager.show_hotbar_context_menu(self, get_global_mouse_position())


# 🔵 Використання предмету, коли інвентар закритий
func _select_slot():
	if item_data == null:
		return
	InventoryManager.use_item(item_data)
