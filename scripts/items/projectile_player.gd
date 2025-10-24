extends Area2D

@onready var icon: Sprite2D = $Icon
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var Player: CharacterBody2D = InventoryManager.Player

var direction: Vector2 = Vector2.ZERO
var damage: int = 5
var speed: float = 500
var proj_res: ProjectileData = null
var max_range: float = 1000
var traveled_distance: float = 0.0
var flight_effect: Node = null

func _ready() -> void:
	if proj_res:
		icon.texture = proj_res.texture
		icon.scale = Vector2(proj_res.scale_x, proj_res.scale_y)

		# Міняємо хітбокс
		if collision.shape is RectangleShape2D:
			collision.shape.extents = Vector2(4, 4) * Vector2(proj_res.scale_x, proj_res.scale_y)
		elif collision.shape is CircleShape2D:
			collision.shape.radius *= max(proj_res.scale_x, proj_res.scale_y)

		# Якщо є візуальний ефект польоту — додаємо
		if proj_res.flight_effect_scene:
			flight_effect = proj_res.flight_effect_scene.instantiate()
			add_child(flight_effect)
			flight_effect.position = Vector2.ZERO

	self.body_entered.connect(_on_body_entered)

func setup(weapon_id: String, projectile_id: String, dir: Vector2):
	var weapon_data = ItemDatabase.get_ranged_weapon(weapon_id)
	var projectile_data = ItemDatabase.get_projectile_by_id(projectile_id)

	if weapon_data.size() > 0:
		damage = weapon_data.get("damage", damage)
		if weapon_data.has("range"):
			max_range = weapon_data.range
		if weapon_data.has("spread") and weapon_data.spread != 0:
			var spread_angle = deg_to_rad(randf_range(-weapon_data.spread, weapon_data.spread))
			dir = dir.rotated(spread_angle)

	if projectile_data:
		if projectile_data.has("to_shoot"):
			proj_res = projectile_data["to_shoot"]
			speed = proj_res.speed

	direction = dir

func _process(delta):
	var move_vector = direction.normalized() * speed * delta
	position += move_vector

	# Крутимо кулю + ефект
	var angle = direction.angle()
	icon.rotation = angle
	if flight_effect:
		flight_effect.rotation = angle

	traveled_distance += move_vector.length()
	if traveled_distance >= max_range:
		queue_free()

func _on_body_entered(body):
	if body.has_method("take_damage") and body != Player:
		body.take_damage(damage)
		if body.has_method("apply_status_effect"):
			body.apply_status_effect(proj_res.effect, proj_res)
		queue_free()
