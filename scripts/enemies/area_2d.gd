extends Area2D

@export var damage : int = 1

@onready var Armored_monster = ArmoredMonster 

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))  # <-- ОЦЕ ВАЖЛИВО
	monitoring = false
	visible = false

func start_attack():
	monitoring = true
	visible = true

func end_attack():
	monitoring = false
	visible = false
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		var monster = self.get_parent()  # отримуємо ArmoredMonster
		monster._on_EnemyAttack_body_entered(body)
