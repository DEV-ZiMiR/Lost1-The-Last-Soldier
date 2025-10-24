extends Panel
class_name ShopItemSlot

@onready var icon: TextureRect = $HBoxContainer/Icon
@onready var name_label: Label = $HBoxContainer/VBoxContainer/NameLabel
@onready var price_label: Label = $HBoxContainer/VBoxContainer/PriceLabel
@onready var action_button: TextureButton = $HBoxContainer/VBoxContainer2/ActionButton
@onready var action_button_label: Label = $HBoxContainer/VBoxContainer2/ActionButton/ActionButtonLabel
@onready var Player: CharacterBody2D = get_tree().root.get_node("Game/Player")

var item_data: ItemData
var mode: ShopUI.Mode
var amount: int = 1

func set_item(data: ItemData, new_mode: ShopUI.Mode, amount := 1):
	await self.ready
	item_data = data
	mode = new_mode
	self.amount = amount
	icon.texture = item_data.icon
	name_label.text = item_data.item_name
	name_label.modulate = InventoryManager.get_rarity_color(item_data.rarity)
	price_label.text = "Price: " + str(item_data.price) + " gold"
	
	if mode == ShopUI.Mode.BUY:
		action_button_label.text = "Buy"
	else:
		action_button_label.text = "Sell"
		if amount > 1:
			$HBoxContainer/VBoxContainer2/AmountLabel.text = "x" + str(amount)
		else:
			$HBoxContainer/VBoxContainer2/AmountLabel.text = " "


	action_button.pressed.connect(on_action_button_pressed)

func on_action_button_pressed():
	if mode == ShopUI.Mode.BUY:
		if Player.gold >= item_data.price:
			Player.gold -= item_data.price
			var success = InventoryManager.add_item(item_data, 1)
			if success:
				print("✅ Куплено: ", item_data.item_name)
			else:
				print("❌ Немає місця в інвентарі!")
		else:
			print("❌ Недостатньо золота!")

	elif mode == ShopUI.Mode.SELL:
		var amount = InventoryManager.get_item_count(item_data)
		if amount > 0:
			Player.gold += item_data.price
			InventoryManager.remove_item(item_data, 1)
			print("✅ Продано: ", item_data.item_name)
			# Оновити магазин після продажу:
			var shop_ui = find_parent_shop_ui()
			if shop_ui != null:
				shop_ui.refresh_item_list()


func find_parent_shop_ui() -> Node:
	var current = get_parent()
	while current != null:
		if current is ShopUI:
			return current
		current = current.get_parent()
	return null
