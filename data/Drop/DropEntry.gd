@icon("res://assets/Textures/Items/wood_01d.png")
extends Resource
class_name DropEntry # опціонально, іконка дропу

@export var item: ItemData
@export_range(0, 100) var drop_chance: int = 100
@export_range(1, 99) var amount: int = 1
