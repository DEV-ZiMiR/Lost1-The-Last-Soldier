extends TextureButton

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	# Знаходимо PlayerUI (предок)
	var player_ui = get_node("../../..")  # з HBoxContainer → UIButtons → PlayerUI
	# Шукаємо InventoryUI всередині PlayerUI
	var inventory_ui = player_ui.get_node("InventoryUI")
	
	if inventory_ui:
		inventory_ui.visible = true
	else:
		push_error("InventoryUI не знайдено!")
