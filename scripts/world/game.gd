extends Node2D

@onready var enemies_skeleton = $Enemy_1
@onready var enemies_armored = $Enemy_2
@onready var enemies_fire_powered = $Enemy_3
@onready var enemies_trash = $Enemy_4
@onready var enemies_cobra = $Enemy_5
# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().process_frame
	InventoryManager.initialize(
		$PlayerUI/InventoryUI,
		$PlayerUI/HotbarUI,
		$Player,
		$PlayerUI/InventoryUI/ItemContextMenu,
		$PlayerUI/InventoryUI/ArmorContextMenu,
		$PlayerUI/InventoryUI/HotbarContextMenu,
		$PlayerUI/InventoryUI/Panel/PetPanel/ScrollContainer/VBoxContainer,
		$PlayerUI/TeleportMenu
	)
	
	SaveManager.set_enemy_containers({
		"skeleton": enemies_skeleton,
		"armored": enemies_armored,
		"fire_powered": enemies_fire_powered,
		"trash": enemies_trash,
		"cobra": enemies_cobra
	})
	SaveManager.set_drops_parent($Drops)
