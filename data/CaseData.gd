@icon("res://assets/Textures/Items/misc/iron-weapons.png")
extends Resource
class_name CaseData

# Інфа про сам кейс
@export var id: String = ""
@export var case_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var rarity: ItemData.RarityList = ItemData.RarityList.DULLY
@export var price: int = 0

# Всередині кейсу може бути список нагород
@export var rewards: Array[CaseReward] = []

# Відкриття кейсу — повертає або ItemData, або PetData
func open_case() -> Resource:
	if rewards.is_empty():
		push_warning("CaseData %s has no rewards!" % id)
		return null

	# вибираємо по шансах
	var roll = randf() * 100.0
	var cumulative := 0.0
	for r in rewards:
		cumulative += r.chance
		if roll <= cumulative:
			return r.get_reward()
	
	# fallback якщо не попали
	return rewards.back().get_reward()
