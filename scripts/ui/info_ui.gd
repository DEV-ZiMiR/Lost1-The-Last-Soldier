extends Control

@onready var back_button : TextureButton = $Panel/BackButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	back_button.pressed.connect(_on_BackButton_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_BackButton_pressed(): self.hide()
