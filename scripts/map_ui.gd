# MiniMap.gd

extends Control

@export var world_rect: Rect2  # межі світу
@onready var player := get_tree().root.get_node("Game/Player")
@onready var map_texture := $MapContainer/MapTexture

func _process(_delta):
	if player == null:
		return

	var player_pos : Vector2 = player.global_position

	# Нормалізована позиція гравця (від 0.0 до 1.0)
	var normalized_x = clamp((player_pos.x - world_rect.position.x) / world_rect.size.x, 0.0, 1.0)
	var normalized_y = clamp((player_pos.y - world_rect.position.y) / world_rect.size.y, 0.0, 1.0)

	# Зміщення карти навколо маркера
	var map_size = map_texture.size
	var mini_map_size = self.size

	var offset_x = -normalized_x * (map_size.x - mini_map_size.x)
	var offset_y = -normalized_y * (map_size.y - mini_map_size.y)

	map_texture.position = Vector2(offset_x, offset_y)
