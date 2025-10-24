extends Area2D
class_name PickupItem

@onready var hint_label: Label = $HintLabel
@onready var name_label: Label = $NameLabel
@onready var amount_label: Label = $AmountLabel

@export var item_data: ItemData
var player_near := false
var player_node: Node = null
var amount : int = 1

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_near = true
		player_node = body
		show_hint()

func _on_body_exited(body):
	if body == player_node:
		player_near = false
		player_node = null
		hide_hint()

func _process(delta):
	if player_near and Input.is_action_just_pressed("active_with"):
		if InventoryManager.add_item(item_data, amount):
			queue_free()  # ← без цього предмет не зникне

func set_item_data(item_data: ItemData, amount: int = 1) -> void:
	self.item_data = item_data
	self.amount = amount

	# Оновлюємо іконку
	if item_data.icon:
		$Sprite2D.texture = item_data.icon
		$Sprite2D.scale.x = 0.5
		$Sprite2D.scale.y = 0.5
		$Sprite2D.set_position(Vector2(-8, -8))

func show_hint():
	hint_label.visible = true
	name_label.visible = true
	name_label.text = item_data.item_name
	name_label.modulate = get_color_by_rarity(item_data.rarity)
	amount_label.visible = true
	if amount > 1: 
		amount_label.text = "x" + str(amount)
	else:
		amount_label.text = ""

func hide_hint():
	hint_label.visible = false
	name_label.visible = false
	amount_label.visible = false

func get_color_by_rarity(rarity: int) -> Color:
	return InventoryManager.get_rarity_color(rarity)
