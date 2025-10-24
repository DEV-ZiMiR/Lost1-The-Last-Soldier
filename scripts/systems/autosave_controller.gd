extends Node

@export var autosave_interval: float = 10.0

var _visited_checkpoints: Array = []
var _visited_set: Dictionary = {} # для швидкої перевірки (id -> true)
var _timer: Timer

func _ready():
	# Таймер
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.wait_time = autosave_interval
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_timer.start()

	# Ініціалізація з SaveManager (якщо є збережені чекпоінти)
	_init_from_save_manager()

func _init_from_save_manager():
	# SaveManager скоріше за все у тебе Autoload, тому можна використовувати глобально:
	# Якщо SaveManager вже має save_data із завантаженням, візьмемо visited_checkpoints
	var visited = SaveManager.get_visited_checkpoints()
	if typeof(visited) == TYPE_ARRAY:
		_visited_checkpoints = visited.duplicate()
		_visited_set.clear()
		for id in _visited_checkpoints:
			_visited_set[id] = true

# Викликається, коли чекпоінт перетнули
func checkpoint_crossed(checkpoint_id: String) -> void:
	if checkpoint_id == "" or checkpoint_id == null:
		return
	if checkpoint_id in _visited_set:
		return

	# Позначаємо як пройдений
	_visited_set[checkpoint_id] = true
	_visited_checkpoints.append(checkpoint_id)

	# Оновлюємо SaveManager (щоб save_data отримав цей список)

	SaveManager.mark_checkpoint_visited(checkpoint_id)

	# Робимо миттєвий autosave

	SaveManager.autosave()

	# Перезапускаємо таймер автосейву
	_timer.start()

# Таймер автосейву
func _on_timer_timeout():
	if InventoryManager.Player != null:
		# робимо автовейв (навіть якщо ніякі чекпоінти не пройдені — можна зберегти)
		SaveManager.autosave()
	else:
		print("Skip autosave, reason: not in game rn!")

# Доступні утиліти
func has_checkpoint_been_visited(id: String) -> bool:
	return id in _visited_set

func get_visited_checkpoints() -> Array:
	return _visited_checkpoints.duplicate()
