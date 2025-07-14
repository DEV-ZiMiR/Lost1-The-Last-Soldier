extends Node
class_name InventoryManagerClass

const INVENTORY_SIZE := 25
var inventory_slots: Array[Control] = []
var hotbar_slots: Array[Control] = []
var active_slot_index: int = -1
var current_hotbar_index: int = 0
var equipped_item: ItemData = null
var active_equip_panel: Control = null
var helmet_equipped: ItemData = null
var vest_equipped: ItemData = null
var suit_equipped: ItemData = null

const InventorySlotClass = preload("res://scenes/items/inventory/inventory_slot.gd")


@onready var inventory_ui: Control = get_tree().root.get_node("Game/PlayerUI/InventoryUI")
@onready var hotbar_ui: Control = get_tree().root.get_node("Game/PlayerUI/HotbarUI")
@onready var Player: CharacterBody2D = get_tree().root.get_node("Game/Player")
@onready var context_menu: ItemContextMenuClass = get_tree().root.get_node("Game/PlayerUI/InventoryUI/ItemContextMenu")
@onready var armor_context_menu: ArmorContextMenuClass = get_tree().root.get_node("Game/PlayerUI/InventoryUI/ArmorContextMenu")

func _ready():
	var sort_bar = inventory_ui.get_node("Panel/VBoxContainer/SortBar")
	sort_bar.get_node("SortByPriceAsc").pressed.connect(func(): sort_inventory_by_price(true))
	sort_bar.get_node("SortByPriceDesc").pressed.connect(func(): sort_inventory_by_price(false))
	sort_bar.get_node("SortByType").pressed.connect(func(): sort_inventory_by_type())
	# Ініціалізуємо слоти хотбару
	for i in range(5):
		var slot = hotbar_ui.get_node("HotbarContainer/HotbarSlot" + str(i))
		hotbar_slots.append(slot)

	# Ініціалізуємо інвентарні слоти
	var grid = inventory_ui.get_node("Panel/VBoxContainer/InventoryGrid")
	for i in range(INVENTORY_SIZE):
		var slot = grid.get_node("Slot" + str(i))
		inventory_slots.append(slot)
		

func add_item(item_data: ItemData) -> bool:
	# Додати до існуючого стака
	for slot in inventory_slots:
		if slot.item_data != null and slot.item_data.id == item_data.id and slot.amount < item_data.max_stack:
			slot.amount += 1
			slot.update_slot()
			return true

	# Додати до пустого слота
	for slot in inventory_slots:
		if slot.item_data == null:
			slot.set_item(item_data, 1)
			return true

	return false  # Інвентар заповнений

func _process(_delta):
	# Перевірка натискань на хотбар клавіші (1–5)
	for i in range(5):
		if Input.is_action_just_pressed("hotbar_" + str(i + 1)):
			active_slot_index = i
			highlight_active_slot(i)
			return

	# При натисканні X — деактивуємо активний слот
	if Input.is_action_just_pressed("unequip_item"):  # ← це дія для кнопки X
		deselect_hotbar_slot()

func highlight_active_slot(index: int):
	for i in range(hotbar_slots.size()):
		var slot = hotbar_slots[i]
		var highlight = slot.get_node("Highlight")
		highlight.visible = (i == active_slot_index and active_slot_index != -1)
		
	if index < hotbar_slots.size():
		current_hotbar_index = index
		var slot = hotbar_slots[index]
		equipped_item = slot.item_data
		
		if equipped_item != null and equipped_item.damage_bonus > 0:
			Player.add_damage(equipped_item.damage_bonus)
		else:
			Player.add_damage(0)  # скидаємо бонус
		

func deselect_hotbar_slot():
	active_slot_index = -1
	highlight_active_slot(active_slot_index)
	# Якщо потрібно — очистити ефекти зброї/броні
	
func _input(event):
	if event.is_action_pressed("use_item"):
		use_equipped_item()
		
func show_item_context_menu(slot: InventorySlotClass, position: Vector2):
	# Якщо вже відкрито — і це той самий слот, закриваємо
	if context_menu.visible == true:
		context_menu.hide_menu()
		active_equip_panel = null
	else:
		# Інакше — оновлюємо
		context_menu.show_menu(slot, position)
		active_equip_panel = context_menu

func show_armor_context_menu(slot: ArmorSlotClass, position: Vector2):
	if armor_context_menu.visible == true:
		armor_context_menu.hide_menu()
		active_equip_panel = null
	else:
		# Інакше — оновлюємо
		armor_context_menu.show_menu(slot, position)
		active_equip_panel = armor_context_menu
		
		

func use_equipped_item():
	if equipped_item == null:
		return

	var slot = hotbar_slots[current_hotbar_index]

	if slot.amount <= 0:
		print("❌ Предмет закінчився")
		return

	if equipped_item.is_usable:
		if equipped_item.hp_bonus != 0:
			Player.add_hp(equipped_item.hp_bonus)
		elif equipped_item.armor_bonus != 0:
			Player.add_armor_hp(equipped_item.armor_bonus)
		else:
			return  # предмет не дав ефекту

		# зменшуємо кількість
		slot.amount -= 1
		if slot.amount <= 0:
			slot.set_item(null, 0)
		else:
			slot.set_item(equipped_item, slot.amount)
		

func equip_from_slot(slot: InventorySlotClass):
	var amount = slot.amount
	var item = slot.item_data
	if item == null or not item.is_equippable:
		return

	# 🎯 Якщо це броня — екіпіруємо одразу в броньовий слот
	if item.type == ItemData.ItemType.ARMOR:
		equip_armor(item, slot)
		return

	# 🗡 Якщо це не броня — поводимось як завжди, додаємо в хотбар
	for i in range(hotbar_slots.size()):
		if hotbar_slots[i].item_data == null:
			hotbar_slots[i].set_item(item, amount)
			slot.set_item(null, 0)
			return

	# Якщо всі слоти зайняті — замінюємо активний
	if active_slot_index != -1:
		var active_slot = hotbar_slots[active_slot_index]
		var temp_item = active_slot.item_data
		var temp_amount = active_slot.amount

		active_slot.set_item(item, 1)
		slot.set_item(temp_item, temp_amount)

		
func unequip_from_slot(slot: ArmorSlotClass):
	var item = slot.equipped_item
	if item == null:
		return
	
	match slot.slot_type:
		ItemData.ArmorType.HELMET:
			if helmet_equipped == item:
				helmet_equipped = null
		ItemData.ArmorType.VEST:
			if vest_equipped == item:
				vest_equipped = null
		ItemData.ArmorType.SUIT:
			if suit_equipped == item:
				suit_equipped = null

	# Повертаємо до інвентаря
	add_item(item)
	
	# Очищуємо слот
	slot.set_item(null)
	
	# Оновлюємо HP
	update_player_max_hp()

		
func sort_inventory_by_price(ascending: bool = true):
	var items := []
	for slot in inventory_slots:
		if slot.item_data != null:
			items.append({
				"item_data": slot.item_data,
				"amount": slot.amount
			})
	
	items.sort_custom(func(a, b):
		return a["item_data"].price < b["item_data"].price if ascending else a["item_data"].price > b["item_data"].price
	)

	apply_sorted_items(items)


func sort_inventory_by_type():
	var items := []
	for slot in inventory_slots:
		if slot.item_data != null:
			items.append({
				"item_data": slot.item_data,
				"amount": slot.amount
			})
	
	items.sort_custom(func(a, b):
		return a["item_data"].sort_priority < b["item_data"].sort_priority
	)

	apply_sorted_items(items)

func apply_sorted_items(sorted_items: Array):
	for slot in inventory_slots:
		slot.set_item(null, 0)

	for i in range(sorted_items.size()):
		inventory_slots[i].set_item(sorted_items[i]["item_data"], sorted_items[i]["amount"])
		
func equip_armor(item: ItemData, from_slot: InventorySlotClass):
	if item.type != ItemData.ItemType.ARMOR:
		return

	var old_item: ItemData = null
	var slot_name := ""

	match item.armor_type:
		ItemData.ArmorType.HELMET:
			old_item = helmet_equipped
			helmet_equipped = item
			slot_name = "ArmorSlotHelmet"
		ItemData.ArmorType.VEST:
			old_item = vest_equipped
			vest_equipped = item
			slot_name = "ArmorSlotVest"
		ItemData.ArmorType.SUIT:
			old_item = suit_equipped
			suit_equipped = item
			slot_name = "ArmorSlotSuit"

	# Обновити UI
	update_armor_slot_ui(slot_name, item)

	# Повертаємо старий предмет назад у інвентар
	if old_item != null:
		add_item(old_item)

	# Очистити слот, з якого був перетяг предмет
	from_slot.set_item(null, 0)

	# Оновити HP
	update_player_max_hp()
	
	
func update_player_max_hp():
	var armor_bonus = 0

	if helmet_equipped != null:
		armor_bonus += helmet_equipped.armor_bonus
	if vest_equipped != null:
		armor_bonus += vest_equipped.armor_bonus
	if suit_equipped != null:
		armor_bonus += suit_equipped.armor_bonus

	Player.set_max_hp(Player.base_max_hp + armor_bonus)

	
func update_armor_slot_ui(slot_name: String, item: ItemData):
	var slot = inventory_ui.get_node("Panel/ArmorPanel/" + slot_name)
	slot.set_item(item)

func get_item_count(item: ItemData) -> int:
	var count := 0
	for i in inventory_slots:
		if i.item_data == item:
			count += i.amount
	return count
	
func get_rarity_color(rarity: int) -> Color:
	match rarity:
		ItemData.RarityList.DULLY: return Color("#aaaaaa")
		ItemData.RarityList.BRISKY: return Color("#55ff55")
		ItemData.RarityList.SHINY: return Color("#3399ff")
		ItemData.RarityList.GLOWY: return Color("#cc33ff")
		ItemData.RarityList.BRIGHTY: return Color("#ffaa00")
		ItemData.RarityList.PHAZEY: return Color("#ff4444")
		_: return Color.WHITE

func get_all_slots() -> Array[Control]:
	return inventory_slots

func remove_item(item_data: ItemData, amount: int = 1) -> bool:
	var total_removed := 0

	# Пройтись по всіх слотах і зменшити кількість
	for slot in inventory_slots:
		if slot.item_data == item_data:
			var to_remove = min(slot.amount, amount - total_removed)
			slot.amount -= to_remove
			total_removed += to_remove

			# Очистити слот, якщо кількість стала 0
			if slot.amount <= 0:
				slot.set_item(null, 0)
			else:
				slot.update_slot()

			if total_removed >= amount:
				return true  # успішно видалили потрібну кількість

	return false  # не було достатньої кількості
