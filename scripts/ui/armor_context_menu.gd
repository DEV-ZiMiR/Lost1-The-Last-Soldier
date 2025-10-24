extends Panel
class_name ArmorContextMenuClass

var current_slot: ArmorSlotClass

@export var slot_ref: ArmorSlotClass # або InventorySlotClass, якщо визначено


@onready var item_name_label = $VBoxContainer/ArmorNameLabel
@onready var item_armorbonus_label = $VBoxContainer/ItemArmorBonusLabel
@onready var unequip_button = $VBoxContainer/UnequipButton
@onready var drop_button = $VBoxContainer/DropButton

func _ready():
	visible = false
	unequip_button.pressed.connect(_on_unequip_pressed)
	drop_button.pressed.connect(_on_drop_pressed)

func show_menu(slot: ArmorSlotClass, position: Vector2):
	current_slot = slot
	var item = slot.equipped_item
	if item == null:
		return
	item_name_label.text = item.item_name
	item_armorbonus_label.text = "Armor bonus: " + str(item.armor_bonus)
	position += Vector2(4, 4)  # невеликий відступ
	global_position = position
	visible = true

func hide_menu():
	visible = false
	current_slot = null

func _on_unequip_pressed():
	if current_slot != null:
		InventoryManager.unequip_from_armor_slot(current_slot, false)
	hide_menu()

func _on_drop_pressed():
	if current_slot != null and current_slot.equipped_item != null:
		var item_data = current_slot.equipped_item

		# Створити предмет на землі (дроп)
		var pickup_item_scene = preload("res://scenes/items/pickup_item.tscn")
		var pickup = pickup_item_scene.instantiate()
		pickup.set_item_data(item_data, 1)
		
		InventoryManager.unequip_from_armor_slot(current_slot, true)

		# Поставити на позицію гравця або біля
		pickup.global_position = InventoryManager.Player.global_position + Vector2(0, -8)
		get_tree().current_scene.add_child(pickup)

	hide_menu()
