extends Button

func _on_pressed() -> void:
	get_tree().reload_current_scene()
	Engine.time_scale = 1.0
