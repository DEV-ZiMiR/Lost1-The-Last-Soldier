extends Button

@onready var parent : Control = $"../../../../RestartMenu"
func _on_pressed() -> void:
	parent.visible = false
	Engine.time_scale = 1.0
	SaveManager.load_save()
	
