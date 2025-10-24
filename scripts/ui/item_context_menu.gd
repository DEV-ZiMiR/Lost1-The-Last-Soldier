extends Panel
class_name ItemContextMenuClass

var current_slot: InventorySlotClass

@export var slot_ref: InventorySlotClass

@onready var item_name_label = $VBoxContainer/ItemNameLabel
@onready var item_description_label = $VBoxContainer/ItemDescriptionLabel
@onready var item_rare_label = $VBoxContainer/ItemRareLabel
@onready var item_price_label = $VBoxContainer/ItemPriceLabel
@onready var equip_button = $VBoxContainer/EquipButton
@onready var drop_button = $VBoxContainer/DropButton

func _ready():
	visible = false
	equip_button.pressed.connect(_on_equip_pressed)
	drop_button.pressed.connect(_on_drop_pressed)

func show_menu(slot: InventorySlotClass, position: Vector2):
	current_slot = slot
	var item = slot.item_data
	if item == null:
		return
	
	item_name_label.text = item.item_name

	item_description_label.text = item.description

	item_rare_label.text = get_rarity_text(item.rarity)
	item_rare_label.modulate = get_color_by_rarity(item.rarity)

	item_price_label.text = "Price: " + str(item.price) + " gold"

	position += Vector2(4, 4)
	global_position = position
	visible = true

func hide_menu():
	visible = false
	current_slot = null

func _on_equip_pressed():
	if current_slot != null:
		InventoryManager.equip_from_slot(current_slot)
	hide_menu()

func _on_drop_pressed():
	if current_slot != null and current_slot.item_data != null:
		var item_data = current_slot.item_data
		var amount = current_slot.amount

		if InventoryManager.remove_item(item_data, amount):
			# Створити предмет на землі (дроп)
			var pickup_item_scene = preload("res://scenes/items/pickup_item.tscn")
			var pickup = pickup_item_scene.instantiate()
			pickup.set_item_data(item_data, amount)

			# Поставити на позицію гравця або біля
			pickup.global_position = InventoryManager.Player.global_position + Vector2(0, -8)
			get_tree().current_scene.add_child(pickup)

	hide_menu()


func get_color_by_rarity(rarity: int) -> Color:
	match rarity:
		ItemData.RarityList.DULLY: return Color("#bdbdbd")
		ItemData.RarityList.BRISKY: return Color("#79c17e")
		ItemData.RarityList.SHINY: return Color("#4c9ce0")
		ItemData.RarityList.GLOWY: return Color("#ad6bef")
		ItemData.RarityList.BRIGHTY: return Color("#fcd74d")
		ItemData.RarityList.PHAZEY: return Color("#f55b5b")
		_: return Color.WHITE

func get_rarity_text(rarity: int) -> String:
	match rarity:
		ItemData.RarityList.DULLY: return "Dully"
		ItemData.RarityList.BRISKY: return "Brisky"
		ItemData.RarityList.SHINY: return "Shiny"
		ItemData.RarityList.GLOWY: return "Glowy"
		ItemData.RarityList.BRIGHTY: return "Brighty"
		ItemData.RarityList.PHAZEY: return "Phazey"
		_: return "Невідома"
