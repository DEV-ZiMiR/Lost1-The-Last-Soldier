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
var weapon: Dictionary = {}
var projectile: Dictionary = {}
var ammo_item: ItemData = null
var mouse_pos: Vector2 = Vector2.ZERO
var last_shot_time: float = 0.0
var fire_cooldown: float = 0.0

var can_use_items: bool = true
var inventory_open: bool = false
  # сюди збиратимемо дані
const InventorySlotClass = preload("res://scenes/items/inventory/inventory_slot.gd")

signal inventory_ready

@onready var inventory_ui: Control
@onready var hotbar_ui: HBoxContainer
@onready var Player: CharacterBody2D
@onready var context_menu: ItemContextMenuClass
@onready var armor_context_menu: ArmorContextMenuClass
@onready var hotbar_context_menu: HotbarContextMenuClass
@onready var pet_inventory: Control
@onready var teleport_menu: Panel

func initialize(ui_inventory: Control, ui_hotbar: HBoxContainer, player_ref: CharacterBody2D,
				context: ItemContextMenuClass, armor_context: ArmorContextMenuClass, hotbar_context: HotbarContextMenuClass, inventory_pet: Control, menu_teleport: Panel):
	inventory_ui = ui_inventory
	hotbar_ui = ui_hotbar
	Player = player_ref
	context_menu = context
	armor_context_menu = armor_context
	hotbar_context_menu = hotbar_context
	pet_inventory = inventory_pet
	teleport_menu = menu_teleport
	if Player == null:
		print("Player вирішив піти нафіг! - InventoryManager")
	init_inventory_system()

func init_inventory_system():
	inventory_slots.clear()
	hotbar_slots.clear()

	var sort_bar = inventory_ui.get_node("Panel/VBoxContainer/SortBar")
	sort_bar.get_node("SortByPriceAsc").pressed.connect(func(): sort_inventory_by_price(true))
	sort_bar.get_node("SortByPriceDesc").pressed.connect(func(): sort_inventory_by_price(false))
	sort_bar.get_node("SortByType").pressed.connect(func(): sort_inventory_by_type())

	for i in range(5):
		var slot = hotbar_ui.get_node("HotbarContainer/HotbarSlot" + str(i))
		hotbar_slots.append(slot)

	var grid = inventory_ui.get_node("Panel/VBoxContainer/InventoryGrid")
	for i in range(INVENTORY_SIZE):
		var slot = grid.get_node("Slot" + str(i))
		inventory_slots.append(slot)
		
	await get_tree().create_timer(0.8).timeout
	
	var pet_data = preload("res://data/pet_data/pets/lilu.tres")
	var pet_data2 = preload("res://data/pet_data/pets/sweet.tres")
	pet_inventory.add_pet(pet_data)
	pet_inventory.add_pet(pet_data2)

func add_item(item_data: ItemData, item_amount: int) -> bool:
	# Додати до існуючого стака
	for slot in inventory_slots:
		if slot.item_data != null and slot.item_data.id == item_data.id and slot.amount < item_data.max_stack:
			slot.amount += item_amount
			slot.update_slot()
			return true

	# Додати до пустого слота
	for slot in inventory_slots:
		if slot.item_data == null:
			slot.set_item(item_data, item_amount)
			return true

	return false  # Інвентар заповнений

func _process(_delta):
	mouse_pos = get_viewport().get_mouse_position()
	if can_use_items == false:
		return
	# Перевірка натискань на хотбар клавіші (1–5):
	
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
	if equipped_item != null and equipped_item.weapon_type == ItemData.WeaponType.RANGED:
		if Player:
			Player.equip_ranged_weapon(equipped_item.icon)
		else:
			pass
			
	if equipped_item == null or equipped_item.weapon_type == ItemData.WeaponType.MELEE:
		if Player:
			Player.unequip_ranged_weapon()
			Player.set_can_attack(true)
		else:
			pass
 # скидаємо бонус
		

func deselect_hotbar_slot():
	active_slot_index = -1
	highlight_active_slot(active_slot_index)
	# Якщо потрібно — очистити ефекти зброї/броні
	
func set_inventory_open(open: bool):
	inventory_open = open

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
		
func show_hotbar_context_menu(slot: InventoryHotbarClass, position: Vector2):
	if hotbar_context_menu.visible == true:
		hotbar_context_menu.hide_menu()
		active_equip_panel = null
	else:
		hotbar_context_menu.show_menu(slot, position)
		active_equip_panel = hotbar_context_menu
		
		

func use_equipped_item(single_shot: bool = false):
	print("\n==============================")
	print("🔹 ВИКЛИК use_equipped_item()")
	print("📦 equipped_item:", equipped_item)
	print("📛 can_use_items:", can_use_items)
	print("🎯 single_shot:", single_shot)
	print("==============================")

	if can_use_items == false:
		print("🚫 ВИКОРИСТАННЯ ЗАБОРОНЕНО (can_use_items == false)")
		return

	if equipped_item == null:
		print("🚫 Немає вибраного предмета (equipped_item == null)")
		return

	var slot = hotbar_slots[current_hotbar_index]
	print("🎚️ Поточний слот:", current_hotbar_index, " | amount:", slot.amount)

	if slot.amount <= 0:
		print("❌ Предмет закінчився у слоті")
		return

	# Якщо це зброя
	if equipped_item.type == ItemData.ItemType.WEAPON:
		print("🗡️ Використовується зброя:", equipped_item.item_name, "| Тип:", equipped_item.weapon_type)

		match equipped_item.weapon_type:
			ItemData.WeaponType.MELEE:
				print("⚔️ Ближній бій. Бонус урону:", equipped_item.damage_bonus)
				if equipped_item.damage_bonus > 0:
					Player.add_damage(equipped_item.damage_bonus)
				else:
					Player.add_damage(0)

			ItemData.WeaponType.RANGED:
				print("🏹 Дальня зброя.")
				Player.set_can_attack(false)
				weapon = ItemDatabase.get_ranged_weapon(equipped_item.id)
				fire_cooldown = weapon.fire_rate
				projectile = ItemDatabase.get_projectile_by_id(weapon.projectile_id)
				ammo_item = ItemDatabase.get_item_by_id(projectile.to_inventory)
				Player.equip_ranged_weapon(equipped_item.icon)

				if ammo_item:
					print("🎯 Знайдено тип боєприпасів")
					try_shoot(equipped_item)
					if single_shot:
						print("🔫 single_shot — вихід з функції")
						return
				else:
					can_use_items = true
					print("❌ Немає потрібних стріл для пострілу!")
		return

	# Якщо це використовуваний предмет
	if equipped_item.is_usable:
		print("💊 Використовується предмет:", equipped_item.item_name)
		Player.set_can_attack(false)

		# 🔹 Якщо це телепорт — не витрачаємо і відкриваємо меню вибору
		if equipped_item.type == ItemData.ItemType.MISC and equipped_item.misc_type == ItemData.MiscType.TELEPORT:
			print("🌀 Використано телепорт — відкривається меню вибору локації")
			teleport_menu.open()
			print("✅ Меню телепорту викликано. Вихід з функції.")
			return

		# 🔹 Звичайне використання предметів
		if equipped_item.hp_bonus != 0:
			print("❤️ HP бонус:", equipped_item.hp_bonus)
			Player.add_hp(equipped_item.hp_bonus)
		elif equipped_item.armor_bonus != 0:
			print("🛡️ Armor бонус:", equipped_item.armor_bonus)
			Player.add_armor_hp(equipped_item.armor_bonus)
		else:
			print("⚪ Без ефектів (hp_bonus і armor_bonus == 0)")

		# Витрачаємо предмет (але не телепорт)
		slot.amount -= 1
		print("📉 Кількість предметів після використання:", slot.amount)

		if slot.amount <= 0:
			print("🗑️ Предмет закінчився, очищуємо слот")
			slot.set_item(null, 0)
			await get_tree().create_timer(0.15).timeout
			Player.set_can_attack(true)
		else:
			print("♻️ Оновлюємо слот із залишком:", slot.amount)
			slot.set_item(equipped_item, slot.amount)
			can_use_items = true

	print("✅ Використання предмета завершено успішно")
	print("==============================\n")



func try_shoot(weapon_item: ItemData) -> void:
	# Перевірка кнопки — якщо вже відпущена, зупиняємось
	if not Input.is_action_pressed("use_item"):
		can_use_items = true
		return

	# Перевірка чи є патрони
	if ammo_item == null:
		can_use_items = true
		print("❌ Немає типу набоїв для цієї зброї")
		return
	if get_item_count(ammo_item) <= 0:
		can_use_items = true
		print("❌ Немає набоїв!")
		return

	# Робимо постріл
	if remove_item(ammo_item, 1):
		spawn_projectile(weapon_item)
		last_shot_time = Time.get_ticks_msec() / 1000.0

	# Чекаємо затримку між пострілами
	await get_tree().create_timer(fire_cooldown).timeout

	# І пробуємо ще раз (авто-вогонь)
	try_shoot(weapon_item)



func spawn_projectile(weapon_item: ItemData) -> void:
	# 1) Дістаємо дані зброї з БД і projectile_id
	var weapon_data := ItemDatabase.get_ranged_weapon(weapon_item.id)
	if weapon_data.is_empty():
		return
	var proj_id : String = weapon_data.get("projectile_id", "")
	if proj_id == "":
		return

	# 2) Інстансимо сцену снаряду
	var projectile_scene: PackedScene = preload("res://scenes/items/projectile_player.tscn")
	var projectile = projectile_scene.instantiate()

	# 3) Точка старту (краще зроби socket на луці, але поки — з гравця)
	var muzzle: Vector2 = Player.target.global_position
	projectile.global_position = muzzle

	# 4) БЕРЕМО СВІТОВУ позицію миші (а не екрана!)
	# варіант А (найпростіший, бо Player — Node2D):
	var mouse_world: Vector2 = Player.get_global_mouse_position()
	# варіант Б (через камеру, якщо треба):
	# var mouse_world: Vector2 = get_viewport().get_camera_2d().get_global_mouse_position()

	# 5) Рахуємо напрямок
	var dir := (mouse_world - muzzle)
	if dir.length_squared() < 0.0001:
		dir = Vector2.RIGHT  # фолбек, щоб не було NaN
	dir = dir.normalized()

	# 6) Передаємо у setup вже ВЕКТОР, а не позицію
	projectile.setup(weapon_item.id, proj_id, dir)

	# 7) Додаємо у світ
	get_tree().current_scene.add_child(projectile)


		

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

		
func unequip_from_armor_slot(slot: ArmorSlotClass, drop: bool):
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
	if drop != true:
		add_item(item, 1)
	
	# Очищуємо слот
	slot.set_item(null)
	
	# Оновлюємо HP
	update_player_max_hp()
	
func unequip_from_hotbar_slot(slot: InventoryHotbarClass):
	# Повертаємо до інвентаря
	add_item(slot.item_data, slot.amount)
	# Очищуємо слот
	slot.set_item(null, 0)

		
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
		add_item(old_item, 1)

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

func get_inventory_data() -> Array:
	var data := []
	for slot in inventory_slots:
		if slot.item_data != null:
			data.append({
				"id": slot.item_data.id,
				"amount": slot.amount
			})
	return data

func get_hotbar_data() -> Array:
	var data := []
	for slot in hotbar_slots:
		if slot.item_data != null:
			data.append({
				"id": slot.item_data.id,
				"amount": slot.amount
			})
		else:
			data.append(null)
	return data

func get_equipped_armor_data() -> Dictionary:
	return {
		"helmet": helmet_equipped.id if helmet_equipped != null else null,
		"vest": vest_equipped.id if vest_equipped != null else null,
		"suit": suit_equipped.id if suit_equipped != null else null,
	}

	
func load_inventory_data(data: Array) -> void:
	for i in range(inventory_slots.size()):
		var item_data : ItemData = null
		var amount := 0

		if i < data.size() and data[i] != null:
			var item_info = data[i]
			item_data = ItemDatabase.get_item_by_id(item_info["id"])
			amount = item_info["amount"]
			print("Inventory slot", i, "—", item_data, amount)

			if item_data == null:
				push_warning("❌ Невідомий предмет у інвентарі: " + str(item_info["id"]))

		inventory_slots[i].set_item(item_data, amount)
		print("✅ Встановлено в слот", i, item_data, amount)

func load_hotbar_data(data: Array) -> void:
	for i in range(hotbar_slots.size()):
		var item_data : ItemData = null
		var amount := 0

		if i < data.size() and data[i] != null:
			var item_info = data[i]
			item_data = ItemDatabase.get_item_by_id(item_info["id"])
			amount = item_info["amount"]
			print("Inventory slot", i, "—", item_data, amount)

			if item_data == null:
				push_warning("❌ Невідомий предмет у хотбарі: " + str(item_info["id"]))

		hotbar_slots[i].set_item(item_data, amount)
		print("✅ Встановлено в слот", i, item_data, amount)

			
func load_equipped_armor_data(data: Dictionary) -> void:
	var armor_slots = {
		"helmet": "ArmorSlotHelmet",
		"vest": "ArmorSlotVest",
		"suit": "ArmorSlotSuit"
	}

	for armor_key in armor_slots.keys():
		var item_id = data.get(armor_key, null)
		var item_data = null
		if item_id != "":
			item_data = ItemDatabase.get_item_by_id(item_id)


		match armor_key:
			"helmet":
				helmet_equipped = item_data
			"vest":
				vest_equipped = item_data
			"suit":
				suit_equipped = item_data

		update_armor_slot_ui(armor_slots[armor_key], item_data)

		if item_id != null and item_data == null:
			push_warning("❌ Невідомий предмет броні (%s): %s" % [armor_key, str(item_id)])

	update_player_max_hp()
	
func TeleportPlayer(location_id: int) -> void:
	if Player == null:
		print("⚠️ Не знайдено Player! Телепорт скасовано.")
		return
		
	match location_id:
		1:
			print("🌀 Телепорт у локацію 8 (секретна або інша зона)")
			Player.global_position = Vector2(0, -12) # 🔹 Введи координати
		2:
			print("🌀 Телепорт у локацію 1 (ліс)")
			Player.global_position = Vector2(2100, -12) # 🔹 Введи координати
			
		3:
			print("🌀 Телепорт у локацію 2 (темний ліс)")
			Player.global_position = Vector2(4500, -12) # 🔹 Введи координати

		4:
			print("🌀 Телепорт у локацію 3 (вогняні землі)")
			Player.global_position = Vector2(6840, -12) # 🔹 Введи координати

		5:
			print("🌀 Телепорт у локацію 4 (засніжені скелі)")
			Player.global_position = Vector2(9800, -12) # 🔹 Введи координати

		6:
			print("🌀 Телепорт у локацію 5 (джунглі)")
			Player.global_position = Vector2(13260, -12) # 🔹 Введи координати

		7:
			print("🌀 Телепорт у локацію 6 (павше королівство)")
			Player.global_position = Vector2(17320, -12) # 🔹 Введи координати

		8:
			print("🌀 Телепорт у локацію 7 (зруйнована цивілізація)")
			Player.global_position = Vector2(20850, -12) # 🔹 Введи координати

		_:
			print("⚠️ Локація з номером", location_id, "не визначена")
			
