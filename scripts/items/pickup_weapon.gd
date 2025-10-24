extends Area2D
class_name PickupWeapon

@export var item_data: ItemData
var player_near := false
var player_node: Node = null

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_near = true
		player_node = body

func _on_body_exited(body):
	if body == player_node:
		player_near = false
		player_node = null

func _process(delta):
	if player_near and Input.is_action_just_pressed("active_with"):
		if InventoryManager.add_item(item_data):
			queue_free()  # ← без цього предмет не зникне
