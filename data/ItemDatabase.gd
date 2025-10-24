extends Node
class_name ItemDatabaseClass

var items: Dictionary = {
	"quest_enemy_drop1": preload("res://data/item_data/items/enemy_drop1.tres"),
	"quest_enemy_drop2": preload("res://data/item_data/items/enemy_drop2.tres"),
	"quest_enemy_drop3": preload("res://data/item_data/items/enemy_drop3.tres"),
	"heal_3hp": preload("res://data/item_data/items/heal_3hp.tres"),
	"heal_5hp": preload("res://data/item_data/items/heal_5hp.tres"),
	"heal_15hp": preload("res://data/item_data/items/heal_15hp.tres"),
	"armor_vest1": preload("res://data/item_data/items/armor_vest1.tres"),
	"armor_vest2": preload("res://data/item_data/items/armor_vest2.tres"),
	"armor_vest3": preload("res://data/item_data/items/armor_vest3.tres"),
	"armor_helmet1": preload("res://data/item_data/items/helmet1.tres"),
	"armor_helmet2": preload("res://data/item_data/items/helmet2.tres"),
	"armor_helmet3": preload("res://data/item_data/items/helmet3.tres"),
	"armor_suit1": preload("res://data/item_data/items/suit1.tres"),
	"armor_suit2": preload("res://data/item_data/items/suit2.tres"),
	"armor_suit3": preload("res://data/item_data/items/suit3.tres"),
	"weapon_wood_sword": preload("res://data/item_data/items/sword1.tres"),
	"weapon_iron_sword": preload("res://data/item_data/items/sword2.tres"),
	"weapon_crystal_sword": preload("res://data/item_data/items/sword3.tres"),
	"item_arrow1": preload("res://data/item_data/items/projectiles/arrow1.tres"),
	"weapon_bow1": preload("res://data/item_data/items/bow1.tres"),
	"item_pistol_bullet": preload("res://data/item_data/items/projectiles/pistol_bullet.tres"),
	"item_ar_bullet": preload("res://data/item_data/items/projectiles/ar_bullet.tres"),
	"item_sniper_bullet": preload("res://data/item_data/items/projectiles/sniper_bullet.tres"),
	"weapon_pistol1": preload("res://data/item_data/items/pistol1.tres"),
	"weapon_pistol2": preload("res://data/item_data/items/pistol2.tres"),
	"weapon_ar_ak47": preload("res://data/item_data/items/ar1.tres"),
	"weapon_ar_m15": preload("res://data/item_data/items/ar2.tres"),
	"weapon_sniper_m24": preload("res://data/item_data/items/sniper1.tres")
}

var projectiles: Dictionary = {
	"arrow1": {
		"to_shoot": preload("res://data/item_data/projectiles/arrow1.tres"),
		"to_inventory": "item_arrow1"
	},
	"pistol_bullet": {
		"to_shoot": preload("res://data/item_data/projectiles/pistol_bullet.tres"),
		"to_inventory": "item_pistol_bullet"
	},
	"ar_bullet": {
		"to_shoot": preload("res://data/item_data/projectiles/ar_bullet.tres"),
		"to_inventory": "item_ar_bullet"
	},
	"sniper_bullet": {
		"to_shoot": preload("res://data/item_data/projectiles/sniper_bullet.tres"),
		"to_inventory": "item_sniper_bullet"
	}
}

var ranged_weapons: Dictionary = {
	"weapon_bow1": {
		"projectile_id": "arrow1",
		"fire_rate": 0.6, # затримка між пострілами (сек)
		"range": 400,      # пікселі
		"spread": 6,      # відхилення пострілу (пікселі)
		"damage": 6
	},
	"weapon_pistol1": {
		"projectile_id": "pistol_bullet",
		"fire_rate": 0.5, # затримка між пострілами (сек)
		"range": 650,      # пікселі
		"spread": 9,      # відхилення пострілу (пікселі)
		"damage": 28
	},
	"weapon_pistol2": {
		"projectile_id": "pistol_bullet",
		"fire_rate": 0.4, # затримка між пострілами (сек)
		"range": 600,      # пікселі
		"spread": 4,      # відхилення пострілу (пікселі)
		"damage": 35
	},
	"weapon_ar_ak47": {
		"projectile_id": "ar_bullet",
		"fire_rate": 0.3, # затримка між пострілами (сек)
		"range": 800,      # пікселі
		"spread": 3,      # відхилення пострілу (пікселі)
		"damage": 60
	},
	"weapon_ar_m15": {
		"projectile_id": "ar_bullet",
		"fire_rate": 0.2, # затримка між пострілами (сек)
		"range": 780,      # пікселі
		"spread": 5,      # відхилення пострілу (пікселі)
		"damage": 75
	},
	"weapon_sniper_m24": {
		"projectile_id": "sniper_bullet",
		"fire_rate": 0.85, # затримка між пострілами (сек)
		"range": 800,      # пікселі
		"spread": 1,      # відхилення пострілу (пікселі)
		"damage": 400
	},
}

# Глобальний доступ до предмету за id
func get_item_by_id(id) -> ItemData:
	id = str(id)  # гарантуємо, що це рядок

	if id.strip_edges() == "":
		push_warning("⚠️ Item ID є порожнім рядком.")
		return null

	if not items.has(id):
		push_warning("❌ Item з ID '" + id + "' не знайдено в базі даних!")
		return null

	return items[id]

func get_projectile_by_id(id: String) -> Dictionary:
	id = str(id)

	if id.strip_edges() == "":
		push_warning("⚠️ Projectile ID є порожнім рядком.")
		return {}

	if not projectiles.has(id):
		push_warning("❌ Projectile з ID '" + id + "' не знайдено в базі даних!")
		return {}

	return projectiles[id]
	
func get_ranged_weapon(id: String) -> Dictionary:
	id = str(id)

	if id.strip_edges() == "":
		push_warning("⚠️ Weapon ID порожній.")
		return {}

	if not ranged_weapons.has(id):
		push_warning("❌ Зброя з ID '" + id + "' не знайдена в базі.")
		return {}

	return ranged_weapons[id]
