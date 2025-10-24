extends Resource
class_name BestiaryEntryData

enum EntryType { MONSTER, ITEM, PET }
enum LocationType { FOREST, DARKFOREST, FLAMELANDS, SNOWYCLIFFS, JUNGLE, FALLENKINGDOM, RUINEDCIVILIZATION, UNKNOWN }
enum RarityList { DULLY, BRISKY, SHINY, GLOWY, BRIGHTY, PHAZEY  } 

@export var entry_type: EntryType = EntryType.MONSTER
@export var location: LocationType = LocationType.UNKNOWN
@export var name: String = "Unknown"
@export var description: String = ""
@export var rarity: RarityList = RarityList.DULLY
@export var icon: CompressedTexture2D
