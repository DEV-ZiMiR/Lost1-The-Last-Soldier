extends Control
class_name PetSlot

@onready var icon = $Panel/Icon
@onready var name_label = $Panel/Name
@onready var rarity_label = $Panel/Rarity
@onready var buffs_container = $Panel/Scroll/V/Buffs   # VBoxContainer з Label'ами
@onready var equip_button = $Panel/EquipUnequipButton
@onready var state_label = $Panel/EquipUnequipButton/Label   # Наприклад, "Equipped" / "Unequipped"

var pet: PetData
var is_equipped: bool = false   # чи цей PetSlot зараз активний

func set_pet(p: PetData):
	pet = p
	_update_visuals()

# ─────────────────────────────────────────────
func _ready():
	equip_button.pressed.connect(_on_equip_pressed)

func _on_equip_pressed():
	if pet == null:
		return
	
	if is_equipped:
		# Unequip логіка
		PetManager.unequip_pet(pet)
		is_equipped = false
		state_label.text = "Equip"
	else:
		# Equip логіка
		if PetManager.current_pet != null:
			print("PetSlot вже зайнятий!")
			return
		
		PetManager.equip_pet(pet)
		is_equipped = true
		state_label.text = "Unequip"

# ─────────────────────────────────────────────
func _update_visuals():
	if pet == null:
		return

	icon.texture = pet.icon
	name_label.text = pet.pet_name
	rarity_label.text = get_rarity_text(pet.rarity)
	rarity_label.modulate = get_color_by_rarity(pet.rarity)

	# очистити попередні бафи
	for c in buffs_container.get_children():
		c.queue_free()

	# додати кожен баф як Label
	for b in pet.buffs:
		var lbl = Label.new()
		lbl.text = get_full_buff_text(b)

		var font: FontFile = load("res://assets/Fonts/Ubuntu-Medium.ttf")
		var font_size = 11
		lbl.add_theme_font_override("font", font)
		lbl.add_theme_font_size_override("font_size", font_size)

		buffs_container.add_child(lbl)

# ─────────────────────────────────────────────
func get_color_by_rarity(rarity: int) -> Color:
	match rarity:
		PetData.PetRarity.DULLY: return Color("#bdbdbd")
		PetData.PetRarity.BRISKY: return Color("#79c17e")
		PetData.PetRarity.SHINY: return Color("#4c9ce0")
		PetData.PetRarity.GLOWY: return Color("#ad6bef")
		PetData.PetRarity.BRIGHTY: return Color("#fcd74d")
		PetData.PetRarity.PHAZEY: return Color("#f55b5b")
		_: return Color.WHITE

func get_buff_text(buff_type: PetBuff.BuffType) -> String:
	match buff_type:
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

func get_rarity_text(rarity: int) -> String:
	match rarity:
		PetData.PetRarity.DULLY: return "Dully"
		PetData.PetRarity.BRISKY: return "Brisky"
		PetData.PetRarity.SHINY: return "Shiny"
		PetData.PetRarity.GLOWY: return "Glowy"
		PetData.PetRarity.BRIGHTY: return "Brighty"
		PetData.PetRarity.PHAZEY: return "Phazey"
		_: return "Невідома"

func get_full_buff_text(buff: PetBuff) -> String:
	var name = get_buff_text(buff.type)
	var sign := ""
	if buff.percent >= 0:
		sign = "+"
	return "%s%s%% %s" % [sign, str(buff.percent), name]
