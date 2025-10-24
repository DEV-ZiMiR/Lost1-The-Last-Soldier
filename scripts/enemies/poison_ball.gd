extends Area2D

var speed := 150
var target_direction: Vector2
var distance_traveled := 0.0
var max_distance := 150

# --- Налаштування отрути ---
var poison_initial_damage := 11
var poison_tick_damage := 3
var poison_ticks := 3
var poison_interval := 1.5 # секунди між ударами

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
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		# миттєва шкода
		if body.has_method("take_damage"):
			body.take_damage(poison_initial_damage)
			if body.has_method("apply_poison"):
				body.apply_poison(poison_ticks, poison_tick_damage, poison_interval)
			else:
				apply_poison_fallback(body)

		queue_free()

func apply_poison_fallback(body):
	var tick := 0
	var poison_timer := Timer.new()
	poison_timer.wait_time = poison_interval
	poison_timer.one_shot = false
	add_child(poison_timer)
	poison_timer.start()

	poison_timer.timeout.connect(func():
		if not is_instance_valid(body):
			poison_timer.queue_free()
			return
		if body.has_method("take_damage"):
			body.take_damage(poison_tick_damage)
		tick += 1
		if tick >= poison_ticks:
			poison_timer.queue_free()
	)

func set_target(target_position: Vector2):
	target_direction = target_position - global_position
	look_at(target_position)
