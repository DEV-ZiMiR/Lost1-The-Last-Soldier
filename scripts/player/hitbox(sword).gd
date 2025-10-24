extends Area2D 

@export var hit_once: bool = true

@onready var Player: CharacterBody2D = get_tree().root.get_node("Game/Player")

var already_hit: Array[Node] = []
var attacker: Node = null  # 👈 Додано

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	visible = false
	set_process(false)

func _on_body_entered(body: Node):
	if body == attacker:  # ⛔ Не бити себе
		return

	if hit_once and body in already_hit:
		return

	if body.has_method("take_damage"):
		Player.get_total_damage()
		body.take_damage(Player.total_damage)
		already_hit.append(body)

func activate(attacker_node: Node):  # 👈 Передаємо, хто атакує
	attacker = attacker_node
	visible = true
	$CollisionShape2D.disabled = false
	already_hit.clear()
	set_process(true)

func deactivate():
	attacker = null
	visible = false
	$CollisionShape2D.disabled = true
	set_process(false)
