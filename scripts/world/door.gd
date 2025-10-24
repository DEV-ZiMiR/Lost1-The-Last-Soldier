extends StaticBody2D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var open_area: Area2D = $open_area
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_in_area: Node = null
var is_open: bool = false
var is_animating: bool = false

func _ready():
	open_area.connect("body_entered", Callable(self, "_on_body_entered"))
	open_area.connect("body_exited", Callable(self, "_on_body_exited"))

func _process(_delta):
	if is_animating or player_in_area == null:
		return

	if Input.is_action_just_pressed("active_with"):
		is_animating = true
		open_area.set_deferred("monitoring", false)

		if is_open:
			anim_player.play("close")
			sprite.play("close")
		else:
			anim_player.play("open")
			sprite.play("open")

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_area = body

func _on_body_exited(body):
	if body == player_in_area:
		player_in_area = null

# --- Ці функції викликаються з AnimationPlayer як Call Method Track ---
func _on_open_finished():
	is_open = true
	is_animating = false
	anim_player.play("opened")
	sprite.play("opened")
	open_area.set_deferred("monitoring", true)

func _on_close_finished():
	is_open = false
	is_animating = false
	anim_player.play("default")
	sprite.play("default")
	open_area.set_deferred("monitoring", true)
