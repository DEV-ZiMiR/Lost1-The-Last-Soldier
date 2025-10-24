extends Resource
class_name CaseReward

enum RewardType { ITEM, PET }

@export var type: RewardType = RewardType.ITEM
@export var item: ItemData
@export var pet: PetData
@export var chance: float = 0.0   # у відсотках (%)

func get_reward() -> Resource:
	match type:
		RewardType.ITEM: return item
		RewardType.PET: return pet
	return null
