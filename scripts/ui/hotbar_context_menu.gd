extends Panel
class_name HotbarContextMenuClass

var current_slot: InventoryHotbarClass

@export var slot_ref: InventoryHotbarClass

@onready var item_name_label = $VBoxContainer/ItemNameLabel
@onready var item_description_label = $VBoxContainer/ItemDescriptionLabel
@onready var unequip_button = $VBoxContainer/UnequipButton
@onready var item_rare_label = $VBoxContainer/ItemRareLabel
@onready var item_type_label = $VBoxContainer/ItemPriceLabel
@onready var drop_button = $VBoxContainer/DropButton

func _ready():
	visible = false
	unequip_button.pressed.connect(_on_unequip_pressed)
	drop_button.pressed.connect(_on_drop_pressed)

# 🟢 Показати меню для конкретного слота
func show_menu(slot: InventoryHotbarClass, position: Vector2):
	current_slot = slot
	var item = slot.item_data
	if item == null:
		return
	item_name_label.text = item.item_name
	item_description_label.text = item.description
	
	item_rare_label.text = get_rarity_text(item.rarity)
	item_rare_label.modulate = get_color_by_rarity(item.rarity)

	item_type_label.text = "Type: " + get_type_text(item.type)
	position += Vector2(4, -175)
	global_position = position
	visible = true

func hide_menu():
	visible = false
	current_slot = null

# 🟣 Зняти предмет із хотбару (unequip)
func _on_unequip_pressed():
	if current_slot != null:
		InventoryManager.unequip_from_hotbar_slot(current_slot)
	hide_menu()

# 🔵 Викинути предмет із хотбару
func _on_drop_pressed():
	if current_slot != null and current_slot.item_data != null:
		var item_data = current_slot.item_data
		var amount = current_slot.amount

		var pickup_item_scene = preload("res://scenes/items/pickup_item.tscn")
		var pickup = pickup_item_scene.instantiate()
		pickup.set_item_data(item_data, amount)

		pickup.global_position = InventoryManager.Player.global_position + Vector2(0, -8)
		get_tree().current_scene.add_child(pickup)

		current_slot.set_item(null, 0)

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

func get_type_text(rarity: int) -> String:
	match rarity:
		ItemData.ItemType.MISC: return "Teleport"
		ItemData.ItemType.WEAPON: return "Weapon"
		ItemData.ItemType.CONSUMABLE: return "Heal"
		ItemData.ItemType.ARMOR: return "Armor"
		ItemData.ItemType.QUEST: return "Drop"
		_: return "Невідома"
