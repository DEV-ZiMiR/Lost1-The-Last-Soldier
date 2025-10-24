extends Area2D

@export var checkpoint_id: String = ""

func _ready():
	# якщо вже пройдений — відключаємось
	if Engine.has_singleton("SaveManager") and SaveManager.has_visited_checkpoint(checkpoint_id):
		monitoring = false
		visible = false # якщо потрібно
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	# перевірка на гравця — підлаштуй під свій кейс (ім'я, група тощо)
	if body.name != "Player":
		return

	# Якщо є глобальний AutosaveController — повідомляємо його
	AutosaveController.checkpoint_crossed(checkpoint_id)

	# один раз спрацьовує — відключаємо monitoring
	set_deferred("monitoring", false)
	set_deferred("visible", false)
