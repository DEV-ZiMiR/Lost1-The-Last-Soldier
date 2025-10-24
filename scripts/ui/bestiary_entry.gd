extends Panel
@onready var icon: TextureRect = $Icon
@onready var name_label: Label = $Name
@onready var rarity_label: Label = $Rarity
@onready var location_label: Label = $Location
@onready var description_label: RichTextLabel = $Description

func set_entry(data: BestiaryEntryData) -> void:
	await ready
	icon.texture = data.icon
	name_label.text = data.name
	rarity_label.text = get_rarity_text(data.rarity)
	rarity_label.modulate = get_color_by_rarity(data.rarity)
	description_label.text = "Description: \n%s" % str(data.description)
	location_label.text = "Location: %s" % str(get_location_text(data.location))
	
func get_color_by_rarity(rarity: int) -> Color:
	match rarity:
		BestiaryEntryData.RarityList.DULLY: return Color("#bdbdbd")
		BestiaryEntryData.RarityList.BRISKY: return Color("#79c17e")
		BestiaryEntryData.RarityList.SHINY: return Color("#4c9ce0")
		BestiaryEntryData.RarityList.GLOWY: return Color("#ad6bef")
		BestiaryEntryData.RarityList.BRIGHTY: return Color("#fcd74d")
		BestiaryEntryData.RarityList.PHAZEY: return Color("#f55b5b")
		_: return Color.WHITE

func get_rarity_text(rarity: int) -> String:
	match rarity:
		BestiaryEntryData.RarityList.DULLY: return "Dully"
		BestiaryEntryData.RarityList.BRISKY: return "Brisky"
		BestiaryEntryData.RarityList.SHINY: return "Shiny"
		BestiaryEntryData.RarityList.GLOWY: return "Glowy"
		BestiaryEntryData.RarityList.BRIGHTY: return "Brighty"
		BestiaryEntryData.RarityList.PHAZEY: return "Phazey"
		_: return "Невідома"
		
func get_location_text(location: int) -> String:
	match location:
		BestiaryEntryData.LocationType.FOREST: return "Forest"
		BestiaryEntryData.LocationType.DARKFOREST: return "Dark Forest"
		BestiaryEntryData.LocationType.FLAMELANDS: return "Flame Lands"
		BestiaryEntryData.LocationType.SNOWYCLIFFS: return "Snowy Cliffs"
		BestiaryEntryData.LocationType.JUNGLE: return "Jungle"
		BestiaryEntryData.LocationType.FALLENKINGDOM: return "Fallen Kingdom"
		BestiaryEntryData.LocationType.RUINEDCIVILIZATION: return "Ruined Civilization"
		_: return "Невідома"
