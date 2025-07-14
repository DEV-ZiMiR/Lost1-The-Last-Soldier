extends Area2D

var speed := 200
var damage := 5
var target_direction: Vector2
var distance_traveled := 0.0
var max_distance := 300

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $DistanceTimer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	timer.start()

func _physics_process(delta):
	var move_vector = target_direction.normalized() * speed * delta
	position += move_vector
	distance_traveled += move_vector.length()

	if distance_traveled >= max_distance:
		explode()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage)
		explode()

func explode():
	speed = 0
	$CollisionShape2D.disabled = true
	sprite.play("exploding")
	anim.play("explode")
	await anim.animation_finished
	queue_free()

func set_target(target_position: Vector2):
	target_direction = target_position - global_position
	look_at(target_position)
