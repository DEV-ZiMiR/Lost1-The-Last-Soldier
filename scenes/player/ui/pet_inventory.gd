extends VBoxContainer
class_name PetInventory

@export var slot_scene: PackedScene   # префаб PetSlot (рамка пета)
var pets: Array[PetData] = []         # список петов у гравця

@onready var grid := $GridContainer   # контейнер для слотів

func add_pet(pet: PetData):
	if pet == null:
		return
	pets.append(pet)
	_add_pet_slot(pet)

func _add_pet_slot(pet: PetData):
	var slot = slot_scene.instantiate()
	grid.add_child(slot)
	await get_tree().process_frame
	if slot.has_method("set_pet"):
		slot.set_pet(pet)

# -------- НОВЕ: повертає копію всіх петов ----------
func get_all_pets() -> Array[PetData]:
	return pets.duplicate(true)

# (опційно) зручно мати лічильник
func get_pets_count() -> int:
	return pets.size()

# -------- НОВЕ: видалення пета (для продажу) -------
func remove_pet(pet: PetData) -> bool:
	var idx := pets.find(pet)
	if idx == -1:
		return false
	pets.remove_at(idx)
	_rebuild_grid()
	return true

# (опційно) видалення по id
func remove_pet_by_id(pet_id: String) -> bool:
	for i in range(pets.size()):
		if pets[i] and pets[i].id == pet_id:
			pets.remove_at(i)
			_rebuild_grid()
			return true
	return false

# Перебудувати сітку слотів відповідно до масиву pets
func _rebuild_grid():
	for c in grid.get_children():
		c.queue_free()
	for p in pets:
		_add_pet_slot(p)

func clear_inventory():
	pets.clear()
	for c in grid.get_children():
		c.queue_free()

func load_pets(pet_list: Array[PetData]):
	clear_inventory()
	for p in pet_list:
		add_pet(p)
