@icon("res://assets/Textures/Items/coin_01c.png")
extends Resource
class_name ItemData

# Базова інформація
@export var id: String = ""
@export var item_name: String = ""
@export var description: String = ""
@export var icon: Texture2D

# Стекування
@export var is_stackable: bool = true
@export var max_stack: int = 64

# Тип предмету
enum ItemType { MISC, CONSUMABLE, WEAPON, ARMOR, QUEST }
@export var type: ItemType = ItemType.MISC

# Бойові характеристики
@export var damage_bonus: int = 0
@export var armor_bonus: int = 0
@export var hp_bonus: int = 0
@export var is_equippable: bool = true
@export var is_usable: bool = true
@export var sort_priority: int = 0

# Інші
@export var price: int = 0

enum RarityList { DULLY, BRISKY, SHINY, GLOWY, BRIGHTY, PHAZEY  }
@export var rarity : RarityList = RarityList.DULLY

# Armor only
# Тип броні
enum ArmorType { NONE, HELMET, SUIT, VEST }
@export var armor_type: ArmorType = ArmorType.NONE
