extends Node2D


# Called when the node enters the scene tree for the first time.
func _process(delta):
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).angle()
	$WeaponHolder.rotation = dir
