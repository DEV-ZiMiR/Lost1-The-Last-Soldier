extends CanvasLayer

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var spinner: TextureRect = $MarginContainer/Spinner
@onready var player_runner: AnimatedSprite2D = $MarginContainer/PlayerRunner
@onready var log: AnimatedSprite2D = $LogoSprites
@onready var cases: AnimatedSprite2D = $CaseSprites
@onready var items: Sprite2D = $ItemsPetsSprites

var is_loading: bool = false

func _ready():
	spinner.set_pivot_offset(spinner.size / 2)
	visible = true
	log.play("Godot")
	anim.play("waiting_to_be_ok")
	await anim.animation_finished
	anim.play("game_loading_godot")
	await anim.animation_finished
	log.play("Z&K Game Studio")
	anim.play("game_loading_studio")
	await anim.animation_finished
	anim.play("fade_out")
	await anim.animation_finished
	visible = false


func show_loading():
	visible = true
	is_loading = true
	anim.play("fade_in")
	await anim.animation_finished
	anim.play("start_loading")

func hide_loading():
	anim.play("end_loading")
	await anim.animation_finished
	anim.play("fade_out")
	await anim.animation_finished
	visible = false
	is_loading = false

func open_case(item: Texture2D, case: String):
	cases.play(case)
	items.texture = item
	visible = true
	anim.play("open_case")
	await anim.animation_finished
	visible = false
	
func _process(delta):
	if is_loading:
		spinner.rotation_degrees += delta * -180.0
