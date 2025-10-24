extends Panel

@onready var close_button: TextureButton = $CloseButton
@onready var type_filter: OptionButton = $Filters/TypeFilter
@onready var location_filter: OptionButton = $Filters/LocationFilter
@onready var entries_container: GridContainer = $Scroll/EntriesContainer

var all_entries: Array[BestiaryEntryData] = []

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	_setup_filters()
	_load_entries()

func _on_close_pressed():
	$"../../".visible = false # або queue_free()
	InventoryManager.Player.set_can_attack(true)

func _setup_filters():
	# Типи
	type_filter.add_item("All")
	for t in BestiaryEntryData.EntryType.keys():
		type_filter.add_item(t.capitalize())

	# Локації
	location_filter.add_item("All")
	for l in BestiaryEntryData.LocationType.keys():
		location_filter.add_item(l.capitalize())

	type_filter.item_selected.connect(_apply_filters)
	location_filter.item_selected.connect(_apply_filters)

func _load_entries():
	var folder_path := "res://data/item_data/bestiary/"  # зміни при потребі
	all_entries.clear()

	var dir := DirAccess.open(folder_path)
	if dir == null:
		push_error("❌ Не вдалося відкрити директорію: " + folder_path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		# Пропускаємо приховані файли і директорії
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var file_path := folder_path + file_name
		if dir.current_is_dir():
			print("📁 Пропускаю папку:", file_path)
		elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
			print("📄 Знайдено файл:", file_path)
			var entry = load(file_path)
			if entry and entry is BestiaryEntryData:
				all_entries.append(entry)
				print("✅ Додано в entries:", entry.name)
			else:
				print("⚠️ Пропущено (не BestiaryEntryData):", file_name)
		else:
			print("⚪ Пропущено (інший тип):", file_name)

		file_name = dir.get_next()

	dir.list_dir_end()
	print("🔹 Завантажено записів:", all_entries.size())

	_apply_filters()



func _apply_filters(_i: int = 0):
	for child in entries_container.get_children():
		child.queue_free()

	for entry in all_entries:
		var type_ok = type_filter.selected == 0 or entry.entry_type == type_filter.selected - 1
		var loc_ok = location_filter.selected == 0 or entry.location == location_filter.selected - 1

		if type_ok and loc_ok:
			var card = preload("res://scenes/player/ui/bestiary_entry.tscn").instantiate()
			card.set_entry(entry)
			entries_container.add_child(card)
