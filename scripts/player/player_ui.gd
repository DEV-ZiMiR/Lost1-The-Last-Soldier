extends CanvasLayer

@onready var inventory_ui := $InventoryUI  # або шлях до InventoryUI
@onready var gold_label: Label = $MoneyBar/Panel/Label
@onready var day_count: Label = $DayCount
@onready var player = get_tree().root.get_node("Game/Player")
var is_inventory_open := false

func update_gold_label():
	if player:
		gold_label.text = str(player.gold)
		
func update_day_count():
	day_count.text = "Day: " + str(GameTimeManager.current_day)
		
func _process(_delta):
	update_day_count()
	update_gold_label()
	if Input.is_action_just_pressed("toggle_inventory"):
		is_inventory_open = !is_inventory_open
		inventory_ui.visible = is_inventory_open
		player.set_can_attack(!is_inventory_open)
		print(InventoryManager.can_use_items)
		InventoryManager.set_inventory_open(is_inventory_open)
		
