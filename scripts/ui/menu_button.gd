extends TextureButton

@onready var pause_menu = get_tree().root.get_node("Game/PlayerUI/PauseMenu")

func _ready():
	pressed.connect(_on_menu_button_pressed)

func _on_menu_button_pressed():
	pause_menu.visible = !pause_menu.visible
	get_tree().paused = pause_menu.visible
