class_name DefData

static func get_main_tabs() -> Array[Dictionary]:
	return [
		{"name": "Architect", "key": "architect", "icon": "architect"},
		{"name": "Work", "key": "work", "icon": "work"},
		{"name": "Restrict", "key": "restrict", "icon": "restrict"},
		{"name": "Assign", "key": "assign", "icon": "assign"},
		{"name": "Animals", "key": "animals", "icon": "animals"},
		{"name": "Wildlife", "key": "wildlife", "icon": "wildlife"},
		{"name": "Research", "key": "research", "icon": "research"},
		{"name": "World", "key": "world", "icon": "world"},
		{"name": "Factions", "key": "factions", "icon": "factions"},
		{"name": "Prisoners", "key": "prisoners", "icon": "prisoners"},
		{"name": "Overview", "key": "overview", "icon": "overview"},
		{"name": "Alerts", "key": "alerts", "icon": "alerts"},
		{"name": "History", "key": "history", "icon": "history"},
		{"name": "Menu", "key": "menu", "icon": "menu"},
	]


static func get_inspect_tabs() -> Array[Dictionary]:
	return [
		{"name": "Needs", "key": "needs"},
		{"name": "Health", "key": "health"},
		{"name": "Skills", "key": "skills"},
		{"name": "Social", "key": "social"},
		{"name": "Gear", "key": "gear"},
		{"name": "Bio", "key": "bio"},
		{"name": "Log", "key": "log"},
	]


static var _designator_textures: Dictionary = {
	"Wall": "res://assets/textures/ui/anomaly/GreyWall_MenuIcon.png",
	"Door": "res://assets/textures/ui/OrnateDoor_MenuIcon_south.png",
	"Fence": "res://assets/textures/ui/Fence_MenuIcon.png",
	"Barricade": "res://assets/textures/ui/Barricade_MenuIcon.png",
	"Sandbags": "res://assets/textures/ui/Sandbags_MenuIcon.png",
	"Mini-turret": "res://assets/textures/ui/TurretMini_MenuIcon.png",
	"Spike Trap": "res://assets/textures/ui/ideology/Archist_Spikes.png",
	"Campfire": "res://assets/textures/ui/Campfire_MenuIcon.png",
	"Torch Lamp": "res://assets/textures/ui/TorchLamp_MenuIcon.png",
	"Standing Lamp": "res://assets/textures/ui/WallLamp_MenuIcon.png",
	"Power Conduit": "res://assets/textures/ui/PowerConduit_MenuIcon.png",
	"Wind Turbine": "res://assets/textures/ui/WindTurbine_MenuIcon.png",
	"Research Bench": "res://assets/textures/ui/ResearchBenchSimple_south.png",
	"Butcher Table": "res://assets/textures/ui/TableButcher_south.png",
	"Stove": "res://assets/textures/ui/TableStoveFueled_south.png",
	"Tailoring Bench": "res://assets/textures/ui/TableTailorHand_south.png",
	"Machining Table": "res://assets/textures/ui/TableMachining_south.png",
	"Bridge": "res://assets/textures/ui/Bridge_MenuIcon.png",
}

static func get_designator_texture(item_name: String) -> Texture2D:
	if item_name in _designator_textures:
		var path: String = _designator_textures[item_name]
		if ResourceLoader.exists(path):
			return load(path)
	return null
