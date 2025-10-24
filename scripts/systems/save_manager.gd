extends Node

const SAVE_PATH := "user://saves/"
const WORLD_NAMES := ["world_1", "world_2", "world_3"]

var current_world: String = "world_1"
var current_slot: int = 1
var save_data: Dictionary = {}

var is_new_game: bool = true

enum PlayerStates {
	IDLE,
	RUN,
	JUMP,
	LANDING,
	SLIDE,
	SITTING,
	SIT,
	ATTACK,
	HIT,
	DIE
}

# --- AUTOSAVE CONFIG ---
# масив слотів, в які буде писатися автосейв (можеш задати [2] або [1,2,3] тощо)
var autosave_slots: Array = [4]
var autosave_index: int = 0
var drops_parent: Node = null

var enemy_containers: Dictionary = {}
var enemies_data: Dictionary = {}

func _ready():
	DirAccess.make_dir_absolute(SAVE_PATH)

# ---------- ІСНУЮЧІ МЕТОДИ (твої) ----------
func set_game_mode(new_game: bool) -> void:
	is_new_game = new_game

func set_current_world(world_name: String) -> void:
	if world_name in WORLD_NAMES:
		current_world = world_name

func set_current_slot(slot: int) -> void:
	current_slot = clamp(slot, 1, 4)

func get_save_file_path(world := current_world, slot := current_slot) -> String:
	# Якщо слот в autosave_slots — завжди зберігаємо в autosave.save
	if slot in autosave_slots:
		return "%s%s/autosave.save" % [SAVE_PATH, world]
	else:
		return "%s%s/slot_%d.save" % [SAVE_PATH, world, slot]


func create_new_game(world: String, slot: int):
	get_tree().change_scene_to_file("res://scenes/world/game.tscn")
	set_current_world(world)
	set_current_slot(slot)
	await get_tree().create_timer(0.5).timeout
	gather_game_data()
	# Звичайний save у вказаний slot
	save_game(slot, world)
	await get_tree().create_timer(0.5).timeout
	LoadingScreen.hide_loading()

# ---------- ОНОВЛЕНИЙ save_game (підтримує slot/world) ----------
func save_game(slot = null, world = null) -> void:
	# Якщо передано null — використовуємо поточні
	var target_world = world if world != null else current_world
	var target_slot = slot if slot != null else current_slot

	# Збираємо дані (якщо потрібно) — якщо хочеш вручну викликати gather_game_data() перед save, можна
	gather_game_data()

	# Переконаємось що папка існує
	var dir_path = "%s%s/" % [SAVE_PATH, target_world]
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	var file_path = get_save_file_path(target_world, target_slot)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		# Додаємо час збереження
		save_data["save_date"] = Time.get_datetime_string_from_system(true)
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()
		print("Saved to: %s" % file_path)
	else:
		push_error("Не вдалося відкрити файл для збереження: %s" % file_path)

# ---------- gather_game_data (додаю visited_checkpoints, якщо є) ----------
func gather_game_data() -> void:
	save_data = {}
	var player = InventoryManager.Player

	if player == null:
		push_error("Player is null, cannot gather save data!")
		return

	save_data["player"] = {
		"position": {
			"x": player.global_position.x,
			"y": player.global_position.y
		},
		"hp": player.hp,
		"max_hp": player.max_hp,
		"gold": player.gold,
		"scene": get_tree().current_scene.scene_file_path,
	}

	save_data["inventory"] = InventoryManager.get_inventory_data()
	save_data["hotbar"] = InventoryManager.get_hotbar_data()
	save_data["equipped_armor"] = InventoryManager.get_equipped_armor_data()
	
	gather_enemies_data()
	save_data["enemies"] = enemies_data
	save_data["drops"] = get_drops_data()


	# збереження списку пройдених чекпоінтів (якщо є)
	if not save_data.has("visited_checkpoints"):
		save_data["visited_checkpoints"] = []
	# якщо AutosaveController передавав відомості у save_data раніше, вони тут вже будуть;
	# інакше залишиться пустий масив

# ---------- CONTINUE / GET LATEST / LOAD (твої існуючі методи) ----------
func continue_game():
	var result = get_latest_save()
	var world = result[0]
	var slot = result[1]
	if world != "" and slot > 0:
		set_current_world(world)
		set_current_slot(slot)
		await get_tree().process_frame
		await get_tree().create_timer(0.5).timeout
		load_save()
	else:
		print("Немає доступних збережень для продовження гри.")

func get_latest_save() -> Array:
	var latest_time := 0
	var latest_world := ""
	var latest_slot := -1

	for world in WORLD_NAMES:
		for slot in range(1, 5):
			var path = get_save_file_path(world, slot)
			if FileAccess.file_exists(path):
				var mod_time = FileAccess.get_modified_time(path)
				if mod_time > latest_time:
					latest_time = mod_time
					latest_world = world
					latest_slot = slot
	print(latest_world, latest_slot)
	return [latest_world, latest_slot]


func load_save():
	if LoadingScreen.is_loading != true:
		LoadingScreen.show_loading()

	var file_path = get_save_file_path()
	if not FileAccess.file_exists(file_path):
		push_warning("Файл збереження не знайдено: %s" % file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Не вдалося відкрити файл збереження!")
		return

	var json_string = file.get_as_text()
	file.close()

	var result = JSON.parse_string(json_string)
	if result == null:
		push_error("Помилка при розборі JSON!")
		return

	# Присвоюємо save_data — тепер інші скрипти (AutosaveController) зможуть дістати список пройдених чекпоінтів
	save_data = result

	# Завантаження сцени
	var scene_path = save_data.get("player", {}).get("scene", "")
	if scene_path != "" and get_tree().current_scene.scene_file_path != scene_path:
		var scene = load(scene_path)
		if scene:
			get_tree().change_scene_to_packed(scene)
			await get_tree().process_frame

	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout

	var player = InventoryManager.Player
	if player == null:
		push_error("Player is null після завантаження сцени!")
		return

	var player_data = save_data.get("player", {})
	var pos_data = player_data.get("position", null)
	if typeof(pos_data) == TYPE_DICTIONARY and pos_data.has("x") and pos_data.has("y"):
		player.global_position = Vector2(pos_data["x"], pos_data["y"])
	else:
		player.global_position = Vector2.ZERO

	player.hp = player_data.get("hp", 10000)
	player.max_hp = player_data.get("max_hp", 10000)
	player.gold = player_data.get("gold", 0)

	if save_data.has("inventory"):
		InventoryManager.load_inventory_data(save_data["inventory"])

	if save_data.has("hotbar"):
		InventoryManager.load_hotbar_data(save_data["hotbar"])

	if save_data.has("equipped_armor"):
		InventoryManager.load_equipped_armor_data(save_data["equipped_armor"])
	
	load_drops_data(save_data["drops"])

	enemies_data = save_data["enemies"]
	spawn_enemies_from_data()
	player.change_state(PlayerStates.IDLE)
	player.on_save_loaded()

	LoadingScreen.hide_loading()
	print("Гру успішно завантажено з", file_path)

# ---------- НОВІ МЕТОДИ ДЛЯ AUTOSAVE / ЧЕКПОІНТІВ ----------

# set_autosave_slots([1]) або set_autosave_slot(2)
func set_autosave_slots(slots: Array) -> void:
	# нормалізація: тільки валідні номера
	var cleaned := []
	for s in slots:
		var si = int(s)
		if si >= 1 and si <= 99: # обмеження довільне
			cleaned.append(si)
	if cleaned.size() == 0:
		cleaned = [current_slot]
	autosave_slots = cleaned
	autosave_index = 0

func set_autosave_slot(slot: int) -> void:
	set_autosave_slots([slot])

# поверне масив поточних збережених чекпоінтів (з поточного save_data)
func get_visited_checkpoints() -> Array:
	if save_data.has("visited_checkpoints"):
		return save_data["visited_checkpoints"]
	return []

# додає чекпоінт до save_data (і можна робити save одразу з AutosaveController)
func mark_checkpoint_visited(checkpoint_id: String) -> void:
	if not save_data.has("visited_checkpoints"):
		save_data["visited_checkpoints"] = []
	var arr = save_data["visited_checkpoints"]
	if checkpoint_id in arr:
		return
	arr.append(checkpoint_id)
	save_data["visited_checkpoints"] = arr

func has_visited_checkpoint(checkpoint_id: String) -> bool:
	if not save_data.has("visited_checkpoints"):
		return false
	return checkpoint_id in save_data["visited_checkpoints"]

# Функція автосейву — вибирає слот із autosave_slots і робить save
func autosave() -> void:
	if autosave_slots.size() == 0:
		push_warning("Autosave slots not set — skipping autosave")
		return

	var idx = autosave_index % autosave_slots.size()
	var slot = int(autosave_slots[idx])
	autosave_index = (autosave_index + 1) % autosave_slots.size()

	# зберігаємо у вказаний слот (не міняючи current_slot постійно)
	save_game(slot, current_world)
	print("Autosaved to slot %d in world %s" % [slot, current_world])

func set_enemy_containers(containers: Dictionary) -> void:
	enemy_containers = containers
	
func set_drops_parent(node: Node) -> void:
	drops_parent = node
	
func gather_enemies_data() -> void:
	enemies_data.clear()

	for enemy_type in enemy_containers.keys():
		var container = enemy_containers[enemy_type]
		if container == null:
			print("Hello")
			continue

		enemies_data[enemy_type] = []

		for enemy in container.get_children():
			if enemy == null:
				print("u are stupid...")
				continue
			var data = {
				"position": {
				"x": enemy.global_position.x,
				"y": enemy.global_position.y
			},
				"hp": enemy.hp if enemy else 0
			}
			enemies_data[enemy_type].append(data)

	print("Зібрані дані про ворогів: ", enemies_data)


# ---- відновлення ворогів після load ----
func spawn_enemies_from_data():
	for enemy_type in enemies_data.keys():
		var container = enemy_containers.get(enemy_type, null)
		if container == null:
			print("GET OUT!")
			continue

		# ⬅️ Спочатку очищаємо контейнер
		for child in container.get_children():
			child.queue_free()

		# preload для кожного типу
		var enemy_scene: PackedScene = null
		match enemy_type:
			"skeleton": enemy_scene = preload("res://scenes/enemies/enemy(angry_man).tscn")
			"armored": enemy_scene = preload("res://scenes/enemies/armored_monster.tscn")
			"fire_powered": enemy_scene = preload("res://scenes/enemies/fire_powered_monster.tscn")
			"trash": enemy_scene = preload("res://scenes/enemies/trash_monster.tscn")
			"cobra": enemy_scene = preload("res://scenes/enemies/angry_cobra_monster.tscn")

		if enemy_scene == null:
			print("What?")
			continue

		# Тепер спавнимо оновлених ворогів
		for enemy_data in enemies_data[enemy_type]:
			var enemy = enemy_scene.instantiate()
			container.add_child(enemy)

			enemy.global_position = Vector2(
				enemy_data["position"]["x"],
				enemy_data["position"]["y"]
			)

			enemy.hp = enemy_data["hp"]

	print("Вороги заспавнені з даних")


func get_drops_data() -> Array:
	var drops_data: Array = []
	if drops_parent == null:
		return drops_data

	for drop in drops_parent.get_children():
		var item_data = drop.item_data
		var count = drop.amount if drop.amount != null else 1

		drops_data.append({
			"item_id": item_data.id,
			"count": count,
			"position": {
				"x": drop.global_position.x,
				"y": drop.global_position.y
			}, # збережемо і позицію, щоб відновлювати
		})
	return drops_data



func load_drops_data(drops_array: Array) -> void:
	if drops_parent == null:
		push_error("Drops parent не заданий у InventoryManager!")
		return

	# очистимо старі дропи
	for child in drops_parent.get_children():
		child.queue_free()

	for drop_dict in drops_array:
		var scene = preload("res://scenes/items/pickup_item.tscn") # заміни на свій шлях
		var drop_instance = scene.instantiate()

		var item_data = ItemDatabase.get_item_by_id(drop_dict["item_id"])
		drop_instance.set_item_data(item_data, drop_dict["count"])
		drop_instance.global_position = Vector2(
			drop_dict["position"]["x"],
			drop_dict["position"]["y"]
		)

		drops_parent.add_child(drop_instance)
