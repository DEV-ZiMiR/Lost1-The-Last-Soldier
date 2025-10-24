@icon("res://assets/Textures/Logo/studio_logo.png")
extends Resource
class_name PetData

# ── Identity ───────────────────────────────────────────────────────────────────
@export_group("Identity")
@export var id: String = ""                 # унікальний ключ (наприклад, "pet_blue_wolf")
@export var pet_name: String = ""           # відображувана назва
@export_multiline var description: String = ""
@export var icon: Texture2D                 # іконка/портрет пета

# ── Meta ───────────────────────────────────────────────────────────────────────
@export_group("Meta")

# Рідкість з випадаючого списку
enum PetRarity { DULLY, BRISKY, SHINY, GLOWY, BRIGHTY, PHAZEY }
@export var rarity: PetRarity = PetRarity.DULLY

# Спеціальна здатність (якщо не треба — NONE)
enum SpecialAbility {
	NONE,
	VAMPIRIC,            # частина завданого урону лікує гравця
	REGEN_OVER_TIME,     # пасивний реген hp з часом
	THORNS,              # відбиває % вхідного урону
	SHIELD_ON_HIT,       # періодичний щит/бар’єр
	AUTO_LOOT,           # підбір дропу поблизу
	EXTRA_LOOT,          # підвищений шанс/кількість дропу
	DASH_COOLDOWN_CUT,   # зменшення кд ривка/дашів
	INVIS_ON_IDLE        # тимчасова непомітність/зменшення агро
}
@export var ability: SpecialAbility = SpecialAbility.NONE

# ── Buffs (percent list) ───────────────────────────────────────────────────────
@export_group("Buffs")
# Масив PetBuff елементів (кожен = тип + %). 10 означає +10%, -15 = -15%.
@export var buffs: Array[PetBuff] = []

# ── Economy (необов’язково) ────────────────────────────────────────────────────
@export_group("Economy")
@export var price: int = 0          # базова ціна в зоомагазині
@export var sell_price: int = 0     # ціна викупу, якщо дозволиш продавати
@export var tradable: bool = true   # чи можна продавати/міняти

# ── Helpers (зручно для підрахунку) ────────────────────────────────────────────
func get_total_percent(buff_type: PetBuff.BuffType) -> float:
	var total := 0.0
	for b in buffs:
		if b.type == buff_type:
			total += b.percent
	return total

# Якщо хочеш працювати множниками: 10% -> 1.10, -25% -> 0.75
func get_multiplier(buff_type: PetBuff.BuffType) -> float:
	return 1.0 + get_total_percent(buff_type) / 100.0
