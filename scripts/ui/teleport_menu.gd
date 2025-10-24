extends Control

var selected_location: int = -1

@onready var teleport_button: TextureButton = $Panel/VBoxContainer/HBoxContainer/TeleportButton
@onready var cancel_button: TextureButton = $Panel/VBoxContainer/HBoxContainer/CancelButton
@onready var teleport_places_container: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/VBoxContainer

func _ready():
	visible = false # меню спочатку приховане

	# Під’єднуємо всі кнопки локацій до однієї функції
	for i in range(teleport_places_container.get_child_count()):
		var place_button = teleport_places_container.get_child(i)
		if place_button is TextureButton:
			place_button.connect("pressed", Callable(self, "_on_teleport_place_pressed").bind(i + 1)) # +1 щоб нумерація починалась з 1

	# Підключаємо кнопки Teleport і Cancel
	teleport_button.connect("pressed", Callable(self, "_on_teleport_button_pressed"))
	cancel_button.connect("pressed", Callable(self, "_on_cancel_button_pressed"))

func open():
	visible = true
	print("📖 Меню телепорту відкрито")

func close():
	print("📕 Меню телепорту закрито")
	visible = false

func _on_teleport_place_pressed(place_id: int):
	selected_location = place_id
	print("📍 Обрано локацію для телепорту:", selected_location)

	# (необов’язково) Можеш тут додати підсвічування активної кнопки
	for i in range(teleport_places_container.get_child_count()):
		var place = teleport_places_container.get_child(i)
		if place is Button:
			place.modulate = Color.WHITE if i + 1 != selected_location else Color(0.6, 1.0, 0.6) # зелена підсвітка обраного

func _on_teleport_button_pressed():
	if selected_location == -1:
		print("⚠️ Не обрано місце телепорту!")
		return

	print("🌀 Телепортуємо гравця до локації №", selected_location)
	InventoryManager.TeleportPlayer(selected_location)
	InventoryManager.Player.set_can_attack(true)
	close() # закриваємо меню після використання

func _on_cancel_button_pressed():
	print("❌ Скасовано телепорт")
	InventoryManager.Player.set_can_attack(true)
	close()
