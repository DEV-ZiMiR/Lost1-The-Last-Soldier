extends Button

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	var inventory_ui = get_node("../../")  # або "../.." якщо ти всередині Panel
	inventory_ui.visible = false
	$"../../ItemContextMenu".visible = false
	InventoryManager.Player.set_can_attack(true)
