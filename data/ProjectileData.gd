@icon("res://assets/Textures/Items/weapons/ranged/arrows/arrow_01e.png")
extends Resource
class_name ProjectileData

@export var projectile_id: String = "" # Унікальний ID для пошуку
@export var name: String = "" # Назва снаряда
@export var description: String = ""
@export var texture: Texture2D

@export var flight_effect_scene: PackedScene

@export var speed: int = 500.0 # Пікселів за секунду

enum EffectType { NONE, FIRE, POISON, ICE, AUTOAIM}

@export var effect: EffectType = EffectType.NONE # Наприклад: "fire", "ice", "poison"

@export var scale_x: float = 1.0
@export var scale_y: float = 1.0
# Іконка/спрайт снаряда
