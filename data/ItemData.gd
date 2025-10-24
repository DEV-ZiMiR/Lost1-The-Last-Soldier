@icon("res://assets/Textures/Items/misc/coin_01c.png")
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

# Додатковий підтип для Misc-предметів
enum MiscType {
	NONE,       # За замовчуванням — нічого
	TELEPORT,   # Телепорт (наприклад, сувій або пристрій)
	BAG,        # Мішок, скринька тощо
	GRENADE     # Граната або вибухівка
}
@export var misc_type: MiscType = MiscType.NONE

# Бойові характеристики
@export var damage_bonus: int = 0
@export var armor_bonus: int = 0
@export var hp_bonus: int = 0
@export var is_equippable: bool = true
@export var is_usable: bool = true
@export var sort_priority: int = 0

# Інші
@export var price: int = 0

# Рідкість
enum RarityList { DULLY, BRISKY, SHINY, GLOWY, BRIGHTY, PHAZEY }
@export var rarity: RarityList = RarityList.DULLY

# Armor only
# Тип броні
enum ArmorType { NONE, HELMET, SUIT, VEST }
@export var armor_type: ArmorType = ArmorType.NONE

# Weapon only
enum WeaponType { NONE, MELEE, RANGED }
@export var weapon_type: WeaponType = WeaponType.NONE
