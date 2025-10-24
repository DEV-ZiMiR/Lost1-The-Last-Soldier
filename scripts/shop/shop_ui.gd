extends CanvasLayer
class_name ShopUI

enum Mode { BUY, SELL }

@export var buy_items: Array[ItemData] = []
@export var sell_items: Array[ItemData] = []

@onready var buy_button: TextureButton = $Panel/Panel/VBoxContainer/HBoxContainer/BuyButton
@onready var sell_button: TextureButton = $Panel/Panel/VBoxContainer/HBoxContainer/SellButton
@onready var items_grid: GridContainer = $Panel/Panel/VBoxContainer/ScrollContainer/ItemGrid
@onready var close_button: TextureButton = $Panel/Panel/CloseButton

var current_mode: Mode = Mode.BUY
var shop_item_slot_scene: PackedScene = preload("res://scenes/shops/shop_item_slot.tscn")

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	buy_button.pressed.connect(_on_buy_pressed)
	sell_button.pressed.connect(_on_sell_pressed)

	switch_mode(Mode.BUY)

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
			for item in buy_items:
				var slot = shop_item_slot_scene.instantiate()
				slot.set_item(item, Mode.BUY)
				items_grid.add_child(slot)

		Mode.SELL:
			# Оновлено: отримати предмети з InventoryManager
			for slot_data in InventoryManager.get_all_slots():
				if slot_data.item_data != null:
					var slot = shop_item_slot_scene.instantiate()
					slot.set_item(slot_data.item_data, Mode.SELL, slot_data.amount)
					items_grid.add_child(slot)
					
					
