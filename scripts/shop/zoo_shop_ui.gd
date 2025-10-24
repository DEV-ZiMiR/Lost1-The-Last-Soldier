extends CanvasLayer
class_name ZooShopUI

enum Mode { BUY, SELL }

@export var buy_cases: Array[CaseData] = []   # кейси, доступні для покупки
@export var buy_items: Array[ItemData] = []   # предмети, доступні для покупки
@export var stock_per_item: int = 1           # скільки одиниць кожного предмета на день
@export var stock_per_case: int = 1           # скільки одиниць кожного кейсу на день

@onready var buy_button: TextureButton = $Panel/Panel/VBoxContainer/HBoxContainer/BuyButton
@onready var sell_button: TextureButton = $Panel/Panel/VBoxContainer/HBoxContainer/SellButton
@onready var items_grid: GridContainer = $Panel/Panel/VBoxContainer/ScrollContainer/ItemGrid
@onready var close_button: TextureButton = $Panel/Panel/CloseButton

var current_mode: Mode = Mode.BUY
var shop_item_slot_scene: PackedScene = preload("res://scenes/shops/zoo_shop_item_slot.tscn")

# словник: {resource_path: залишок}
var remaining_stock: Dictionary = {}

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	buy_button.pressed.connect(_on_buy_pressed)
	sell_button.pressed.connect(_on_sell_pressed)

	GameTimeManager.new_day_started.connect(_on_new_day)

	# ініціалізація стоку
	_reset_stock()
	switch_mode(Mode.BUY)

func _reset_stock():
	remaining_stock.clear()

	for case_data in buy_cases:
		if case_data:
			remaining_stock[case_data.resource_path] = stock_per_case

	for item_data in buy_items:
		if item_data:
			remaining_stock[item_data.resource_path] = stock_per_item

func _on_new_day(day: int):
	print("ZooShop: Новий день %d, оновлюю асортимент" % day)
	_reset_stock()
	refresh_item_list()

func _on_close_pressed():
	visible = false
	InventoryManager.can_use_items = true
	InventoryManager.Player.set_can_attack(true)

func _on_buy_pressed():
	switch_mode(Mode.BUY)

func _on_sell_pressed():
	switch_mode(Mode.SELL)

func switch_mode(mode: Mode):
	current_mode = mode
	buy_button.disabled = (mode == Mode.BUY)
	sell_button.disabled = (mode == Mode.SELL)
	refresh_item_list()

func refresh_item_list():
	# Очистити старі слоти
	for child in items_grid.get_children():
		child.queue_free()

	match current_mode:
		Mode.BUY:
			# Кейси
			for case_data in buy_cases:
				var stock_left = remaining_stock.get(case_data.resource_path, 0)
				if stock_left > 0:
					var slot = shop_item_slot_scene.instantiate()
					slot.set_item(case_data, Mode.BUY, 1, stock_left)
					items_grid.add_child(slot)

			# Предмети
			for item_data in buy_items:
				var stock_left = remaining_stock.get(item_data.resource_path, 0)
				if stock_left > 0:
					var slot = shop_item_slot_scene.instantiate()
					slot.set_item(item_data, Mode.BUY, 1, stock_left)
					items_grid.add_child(slot)

		Mode.SELL:
			# Всі пети з інвентаря
			for pet in InventoryManager.pet_inventory.get_all_pets():
				if pet != null:
					var slot = shop_item_slot_scene.instantiate()
					slot.set_item(pet, Mode.SELL, 1, 0) # 1 пет = 1 слот
					items_grid.add_child(slot)

# --- Публічний метод: купівля ---
func try_buy_item(data: Resource) -> bool:
	var key = data.resource_path
	if remaining_stock.has(key) and remaining_stock[key] > 0:
		remaining_stock[key] -= 1
		refresh_item_list()
		return true
	else:
		print("Немає в наявності:", key)
		return false
