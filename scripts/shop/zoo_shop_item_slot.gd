extends Panel
class_name ZooShopItemSlot

@onready var icon: TextureRect = $HBoxContainer/Icon
@onready var name_label: Label = $HBoxContainer/VBoxContainer/NameLabel
@onready var price_label: Label = $HBoxContainer/VBoxContainer/PriceLabel
@onready var action_button: TextureButton = $HBoxContainer/VBoxContainer2/ActionButton
@onready var action_button_label: Label = $HBoxContainer/VBoxContainer2/ActionButton/ActionButtonLabel
@onready var amount_label: Label = $HBoxContainer/VBoxContainer2/AmountLabel
@onready var Player: CharacterBody2D = get_tree().root.get_node("Game/Player")

var shop_data: Resource   # ItemData або CaseData
var mode: ShopUI.Mode
var amount: int = 1       # кількість предметів у SELL
var stock: int = 0        # кількість доступних у BUY

func set_item(data: Resource, new_mode: ShopUI.Mode, amount := 1, stock := 0):
	await self.ready
	shop_data = data
	mode = new_mode
	self.amount = amount
	self.stock = stock

	# базові дані
	if shop_data is ItemData:
		icon.texture = shop_data.icon
		name_label.text = shop_data.item_name
		name_label.modulate = InventoryManager.get_rarity_color(shop_data.rarity)
		price_label.text = "Price: " + str(shop_data.price) + " gold"

	elif shop_data is CaseData:
		icon.texture = shop_data.icon
		name_label.text = shop_data.case_name
		name_label.modulate = InventoryManager.get_rarity_color(shop_data.rarity)
		price_label.text = "Price: " + str(shop_data.price) + " gold"
		
	elif shop_data is PetData:
		icon.texture = shop_data.icon
		name_label.text = shop_data.pet_name
		name_label.modulate = InventoryManager.get_rarity_color(shop_data.rarity)
		price_label.text = "Price: " + str(shop_data.price) + " gold"


	# кнопка Buy/Sell + кількість
	if mode == ShopUI.Mode.BUY:
		action_button_label.text = "Buy"
		amount_label.text = "Stock: " + str(stock)   # 🔹 завжди показуємо
	else:
		action_button_label.text = "Sell"
		if amount > 1:
			amount_label.text = "x" + str(amount)
		else:
			amount_label.text = " "       # 🔹 завжди показуємо

	action_button.pressed.connect(on_action_button_pressed)

func on_action_button_pressed():
	if mode == ZooShopUI.Mode.BUY:
		var price = shop_data.price if shop_data else 0
		if Player.gold >= price and stock > 0:
			Player.gold -= price

			if shop_data is ItemData:
				var success = InventoryManager.add_item(shop_data, 1)
				if success:
					stock -= 1
					amount_label.text = "Stock: " + str(stock)
					print("✅ Куплено: ", shop_data.item_name)
				else:
					print("❌ Немає місця в інвентарі!")

			elif shop_data is CaseData:
				var reward: Resource = shop_data.open_case()
				LoadingScreen.open_case(reward.icon, "case_pet_shiny")
				if reward is ItemData:
					InventoryManager.add_item(reward, 1)
					print("🎁 Випав предмет: ", reward.item_name)
				elif reward is PetData:
					InventoryManager.pet_inventory.add_pet(reward)
					print("🎁 Випав пет: ", reward.pet_name)
				else:
					print("❌ Кейс відкрито, але нагорода не визначена")
				stock -= 1
				amount_label.text = "Stock: " + str(stock)

		else:
			if stock <= 0:
				print("❌ Цей товар закінчився!")
			else:
				print("❌ Недостатньо золота!")

	elif mode == ZooShopUI.Mode.SELL:
		if shop_data is ItemData:
			var amount = InventoryManager.get_item_count(shop_data)
			if amount > 0:
				Player.gold += shop_data.price
				InventoryManager.remove_item(shop_data, 1)
				print("✅ Продано: ", shop_data.item_name)
				# Оновити магазин після продажу
				var shop_ui = find_parent_shop_ui()
				if shop_ui != null:
					shop_ui.refresh_item_list()
		else:
			print("❌ Кейс не можна продати!")
		
		if shop_data is PetData:
			var price = shop_data.sell_price if shop_data.sell_price > 0 else shop_data.price
			if InventoryManager.pet_inventory.remove_pet(shop_data):
				Player.gold += price
				print("✅ Продано пета: ", shop_data.pet_name)
				var shop_ui = find_parent_shop_ui()
				if shop_ui != null:
					shop_ui.refresh_item_list()
		else:
			print("❌ Продавати тут можна лише петов")


func find_parent_shop_ui() -> Node:
	var current = get_parent()
	while current != null:
		if current is ZooShopUI:
			return current
		current = current.get_parent()
	return null
