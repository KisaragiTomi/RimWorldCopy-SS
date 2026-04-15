class_name Cell
extends RefCounted

## A single map cell. Stores terrain, occupants, roof state, etc.

var x: int
var y: int

var terrain_def: String = "Soil"
var roof: bool = false
var is_mountain: bool = false

var elevation: float = 0.0
var fertility: float = 0.0

var building: bool = false
var things: Array = []      # ThingIDs occupying this cell
var feature: String = ""    # cave, steam geyser, ancient danger, etc.
var ore: String = ""        # steel, gold, uranium, etc.
var zone: String = ""       # stockpile, growing, home, etc.


func _init(cx: int = 0, cy: int = 0) -> void:
	x = cx
	y = cy


func is_passable() -> bool:
	if is_mountain:
		return false
	var tdef := DefDB.get_def("TerrainDef", terrain_def) if DefDB else {}
	if not tdef.is_empty():
		return tdef.get("passable", true)
	return true


func get_move_cost() -> int:
	var tdef := DefDB.get_def("TerrainDef", terrain_def) if DefDB else {}
	if not tdef.is_empty():
		return int(tdef.get("moveCost", 2))
	return 2


func get_color() -> Color:
	var tdef := DefDB.get_def("TerrainDef", terrain_def) if DefDB else {}
	if not tdef.is_empty() and tdef.has("color"):
		var c: Array = tdef["color"]
		return Color(c[0], c[1], c[2])
	return Color(0.45, 0.35, 0.2)


func to_dict() -> Dictionary:
	return {
		"x": x, "y": y,
		"terrain": terrain_def,
		"roof": roof,
		"is_mountain": is_mountain,
		"elevation": elevation,
		"fertility": fertility,
		"feature": feature,
		"ore": ore,
		"zone": zone,
	}


static func from_dict(d: Dictionary) -> Cell:
	var c := Cell.new(d.get("x", 0), d.get("y", 0))
	c.terrain_def = d.get("terrain", "Soil")
	c.roof = d.get("roof", false)
	c.is_mountain = d.get("is_mountain", false)
	c.elevation = d.get("elevation", 0.0)
	c.fertility = d.get("fertility", 0.0)
	c.feature = d.get("feature", "")
	c.ore = d.get("ore", "")
	c.zone = d.get("zone", "")
	return c
