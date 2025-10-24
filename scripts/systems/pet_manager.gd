extends Node
class_name PetManagerClass

var current_pet: PetData = null

func equip_pet(pet: PetData):
	if current_pet != null:
		print("Уже є активний пет!")
		return
	
	current_pet = pet
	_apply_buffs(pet)
	print("Equipped pet:", pet.pet_name)

func unequip_pet(pet: PetData):
	if current_pet != pet:
		print("Цей пет не активний!")
		return
	
	_remove_buffs(pet)
	current_pet = null
	print("Unequipped pet:", pet.pet_name)

# тут ти додаєш логіку підключення до гравця
func _apply_buffs(pet: PetData):
	InventoryManager.Player.apply_pet_buffs(pet.buffs)
	InventoryManager.Player.show_pet(pet)
	for b in pet.buffs:
		print("Додано баф:", get_buff_name(b))

func _remove_buffs(pet: PetData):
	InventoryManager.Player.drop_pet_buffs()
	InventoryManager.Player.hide_pet()
	for b in pet.buffs:
		print("Знято баф:", get_buff_name(b))

func get_buff_name(buff: PetBuff) -> String:
	match buff.type:
		PetBuff.BuffType.HP: return "Max HP"
		PetBuff.BuffType.SPEED: return "Movement Speed"
		PetBuff.BuffType.ATTACK: return "Attack Damage"
		PetBuff.BuffType.JUMP: return "Jump Height"
		PetBuff.BuffType.REGEN: return "HP Regen"
		PetBuff.BuffType.CRIT_CHANCE: return "Crit Chance"
		PetBuff.BuffType.CRIT_DAMAGE: return "Crit Damage"
		PetBuff.BuffType.DAMAGE_REDUCE: return "Damage Reduction"
		PetBuff.BuffType.PROJECTILE_SIZE: return "Projectile Size"
		PetBuff.BuffType.PROJECTILE_SPEED: return "Projectile Speed"
		PetBuff.BuffType.GOLD_GAIN: return "Gold Gain"
		PetBuff.BuffType.XP_GAIN: return "XP Gain"
		_: return "Unknown Buff"
