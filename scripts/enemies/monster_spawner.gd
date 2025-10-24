extends Node2D

@export var enemy_scene: PackedScene
@export var enemy_container_path: NodePath
@export var max_enemies: int = 8
@export var initial_spawn_count: int = 3
@export var min_spawn_interval: float = 5.0
@export var max_spawn_interval: float = 8.0
@export var spawn_delay: float = 5.0   # ⬅️ затримка перед дозволом на спавн

var _player_inside := false
var _spawn_points: Array[Marker2D] = []
var _active_spawns: Dictionary = {} # spawn_point_name: enemy_instance
var _spawn_timer := Timer.new()
var _delay_timer := Timer.new()   # ⬅️ додатковий таймер
var _rng := RandomNumberGenerator.new()

func _ready():
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)

	_delay_timer.one_shot = true
	_delay_timer.wait_time = spawn_delay
	_delay_timer.start()
	add_child(_delay_timer)

	_rng.randomize()
	
	# Збираємо всі Marker2D як точки спавну
	var spawn_parent = $SpawnPoints
	for child in spawn_parent.get_children():
		if child is Marker2D:
			_spawn_points.append(child)

	# Слухаємо зону виявлення
	$DetectionArea.body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	# ⬅️ якщо ще працює таймер затримки — нічого не робимо
	if _delay_timer.time_left > 0:
		return

	if body.name == "Player" and not _player_inside:
		_player_inside = true
		_initial_spawn()
		_schedule_next_spawn()


func _initial_spawn():
	var available_points = _get_available_spawn_points()
	var points_to_use = _get_random_unique_items(available_points, initial_spawn_count)
	
	for point in points_to_use:
		_spawn_enemy_at(point)


func _schedule_next_spawn():
	var wait_time = _rng.randf_range(min_spawn_interval, max_spawn_interval)
	_spawn_timer.start(wait_time)


func _on_spawn_timer_timeout():
	# ⬅️ перевірка таймера — без цього вороги можуть піти ще до закінчення затримки
	if _delay_timer.time_left > 0:
		return

	if _get_total_enemy_count() >= max_enemies:
		_schedule_next_spawn()
		return

	var spawn_count = 1
	if _rng.randf() < 0.33:
		spawn_count = 2

	spawn_count = min(spawn_count, max_enemies - _get_total_enemy_count())

	var available_points = _get_available_spawn_points()
	var points_to_use = _get_random_unique_items(available_points, spawn_count)

	for point in points_to_use:
		_spawn_enemy_at(point)

	_schedule_next_spawn()


func _get_available_spawn_points() -> Array[Marker2D]:
	return _spawn_points.filter(func(p): return not _active_spawns.has(p.name))


func _spawn_enemy_at(spawn_point: Marker2D):
	if enemy_scene == null:
		push_error("Enemy scene is not assigned!")
		return

	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_point.global_position

	var container = get_node_or_null(enemy_container_path)
	if container == null:
		push_error("Enemy container not found at path: %s" % str(enemy_container_path))
		return

	container.add_child(enemy)
	_active_spawns[spawn_point.name] = enemy

	# Підписка на сигнал "death" ворога, або створення вручну, якщо в нього немає сигналу
	if enemy.has_signal("death"):
		enemy.connect("death", Callable(self, "_on_enemy_died").bind(spawn_point.name))
	else:
		# Автоматично знищиться — ручне видалення точки
		enemy.tree_exited.connect(Callable(self, "_on_enemy_removed").bind(spawn_point.name))


func _on_enemy_died(spawn_point_name: String):
	_active_spawns.erase(spawn_point_name)


func _on_enemy_removed(spawn_point_name: String):
	_active_spawns.erase(spawn_point_name)


func _get_total_enemy_count() -> int:
	return _active_spawns.size()


func _get_random_unique_items(array: Array, count: int) -> Array:
	var copy = array.duplicate()
	var selected = []
	count = min(count, copy.size())

	while selected.size() < count:
		var index = _rng.randi_range(0, copy.size() - 1)
		selected.append(copy[index])
		copy.remove_at(index)

	return selected
