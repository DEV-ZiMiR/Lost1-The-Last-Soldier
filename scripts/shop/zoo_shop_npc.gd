extends Area2D

@onready var interaction_label = $InteractionLabel
@onready var shop_ui: ZooShopUI = $ZooShopUI
@onready var player = null
var is_player_inside = false

func _ready():
	interaction_label.visible = false
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _process(_delta):
	if is_player_inside and Input.is_action_just_pressed("active_with"):
		shop_ui.visible = true
		InventoryManager.can_use_items = false
		InventoryManager.Player.set_can_attack(false)

func _on_body_entered(body):
	if body.is_in_group("player"):
		is_player_inside = true
		interaction_label.visible = true
		player = body

func _on_body_exited(body):
	if body == player:
		is_player_inside = false
		interaction_label.visible = false
