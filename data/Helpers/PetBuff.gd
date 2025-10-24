@icon("res://assets/Textures/Logo/studio_logo.png")
extends Resource
class_name PetBuff

## Один баф пета. Значення задаються у ВІДСОТКАХ (10 = +10%, -15 = -15%)

enum BuffType {
	HP,            # +% до максимального HP
	SPEED,         # +% до швидкості руху
	ATTACK,        # +% до урону/силі атаки
	JUMP,          # +% до висоти стрибка
	REGEN,         # +%/сек регену (або інтерпретуєш у своєму менеджері)
	CRIT_CHANCE,   # +% до шансу криту
	CRIT_DAMAGE,   # +% до множника криту
	DAMAGE_REDUCE, # -% вхідного урону (позитивне значення = зменшення)
	PROJECTILE_SIZE,   # +% до розміру снарядів
	PROJECTILE_SPEED,  # +% до швидкості снарядів
	GOLD_GAIN,     # +% до здобутого золота
	XP_GAIN        # +% до досвіду
}

@export var type: BuffType = BuffType.HP

# У відсотках. Дозволив негативні — раптом захочеш “мінуси за силу”.
@export_range(-1000.0, 1000.0, 0.1, "or_greater") var percent: float = 0.0
