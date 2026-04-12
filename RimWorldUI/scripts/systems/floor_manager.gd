extends Node

## Manages constructed floors. Floors overlay terrain to boost room beauty
## and reduce move cost. Registered as autoload "FloorManager".

const FLOOR_DEFS: Dictionary = {
	"WoodPlank": {"beauty": 1.0, "move_cost": 1, "work": 85, "cost_def": "Wood", "cost_amount": 3, "color": [0.55, 0.42, 0.28], "flammable": true, "cleanliness": 0.0},
	"Concrete": {"beauty": 0.0, "move_cost": 1, "work": 65, "cost_def": "Steel", "cost_amount": 2, "color": [0.62, 0.62, 0.60], "flammable": false, "cleanliness": 0.0},
	"StoneTile": {"beauty": 2.0, "move_cost": 1, "work": 120, "cost_def": "StoneBrick", "cost_amount": 4, "color": [0.70, 0.68, 0.63], "flammable": false, "cleanliness": 0.0},
	"Carpet": {"beauty": 3.0, "move_cost": 1, "work": 100, "cost_def": "Cloth", "cost_amount": 5, "color": [0.75, 0.25, 0.25], "flammable": true, "cleanliness": -0.1},
	"SterileTile": {"beauty": 1.5, "move_cost": 1, "work": 140, "cost_def": "Steel", "cost_amount": 3, "color": [0.88, 0.90, 0.88], "flammable": false, "cleanliness": 0.6},
	"FlagstoneGranite": {"beauty": 2.5, "move_cost": 1, "work": 130, "cost_def": "StoneBrick", "cost_amount": 4, "color": [0.60, 0.55, 0.52], "flammable": false, "cleanliness": 0.0},
	"FlagstoneMarble": {"beauty": 3.5, "move_cost": 1, "work": 150, "cost_def": "StoneBrick", "cost_amount": 5, "color": [0.85, 0.82, 0.78], "flammable": false, "cleanliness": 0.0},
}

var total_placed: int = 0
var total_removed: int = 0

var _floors: Dictionary = {}  # Vector2i -> floor_def_name


func set_floor(pos: Vector2i, floor_def: String) -> bool:
	if not FLOOR_DEFS.has(floor_def):
		return false
	_floors[pos] = floor_def
	total_placed += 1
	return true


func remove_floor(pos: Vector2i) -> void:
	if _floors.has(pos):
		total_removed += 1
	_floors.erase(pos)


func get_floor(pos: Vector2i) -> String:
	return _floors.get(pos, "")


func has_floor(pos: Vector2i) -> bool:
	return _floors.has(pos)


func get_beauty(pos: Vector2i) -> float:
	var f := get_floor(pos)
	if f.is_empty():
		return 0.0
	return FLOOR_DEFS[f].get("beauty", 0.0)


func get_move_cost(pos: Vector2i) -> int:
	var f := get_floor(pos)
	if f.is_empty():
		return -1
	return int(FLOOR_DEFS[f].get("move_cost", 1))


func get_floor_color(pos: Vector2i) -> Color:
	var f := get_floor(pos)
	if f.is_empty():
		return Color.TRANSPARENT
	var c: Array = FLOOR_DEFS[f].get("color", [0.5, 0.5, 0.5])
	return Color(c[0], c[1], c[2])


func get_all_floor_types() -> Array:
	return FLOOR_DEFS.keys()


func get_floor_count() -> int:
	return _floors.size()


func get_cleanliness(pos: Vector2i) -> float:
	var f := get_floor(pos)
	if f.is_empty():
		return 0.0
	return FLOOR_DEFS[f].get("cleanliness", 0.0)


func is_flammable(pos: Vector2i) -> bool:
	var f := get_floor(pos)
	if f.is_empty():
		return false
	return FLOOR_DEFS[f].get("flammable", false)


func get_total_beauty() -> float:
	var total: float = 0.0
	for pos: Vector2i in _floors:
		var f: String = _floors[pos]
		total += FLOOR_DEFS[f].get("beauty", 0.0)
	return total


func get_floors_in_area(center: Vector2i, radius: int) -> Dictionary:
	var result: Dictionary = {}
	for dx: int in range(-radius, radius + 1):
		for dy: int in range(-radius, radius + 1):
			var pos := center + Vector2i(dx, dy)
			if _floors.has(pos):
				var f: String = _floors[pos]
				result[f] = result.get(f, 0) + 1
	return result


func get_cost_to_build(floor_def: String) -> Dictionary:
	var fd: Dictionary = FLOOR_DEFS.get(floor_def, {})
	if fd.is_empty():
		return {}
	return {"material": fd.get("cost_def", ""), "amount": fd.get("cost_amount", 0), "work": fd.get("work", 0)}


func get_most_common_floor() -> String:
	var counts: Dictionary = {}
	for pos: Vector2i in _floors:
		var f: String = _floors[pos]
		counts[f] = counts.get(f, 0) + 1
	var best: String = ""
	var best_n: int = 0
	for f: String in counts:
		if counts[f] > best_n:
			best_n = counts[f]
			best = f
	return best


func get_flammable_floor_count() -> int:
	var count: int = 0
	for pos: Vector2i in _floors:
		var f: String = _floors[pos]
		if FLOOR_DEFS.get(f, {}).get("flammable", false):
			count += 1
	return count


func get_avg_beauty_per_tile() -> float:
	if _floors.is_empty():
		return 0.0
	return snappedf(get_total_beauty() / float(_floors.size()), 0.01)


func get_unique_floor_type_count() -> int:
	var types: Dictionary = {}
	for pos: Vector2i in _floors:
		types[_floors[pos]] = true
	return types.size()


func get_replacement_rate() -> float:
	if total_placed == 0:
		return 0.0
	return float(total_removed) / float(total_placed)


func get_floor_density() -> float:
	if _floors.is_empty():
		return 0.0
	return float(total_placed) / float(_floors.size())


func get_sterile_ratio() -> float:
	if _floors.is_empty():
		return 0.0
	var sterile: int = 0
	for pos: Vector2i in _floors:
		if _floors[pos] == "SterileTile":
			sterile += 1
	return snappedf(float(sterile) / float(_floors.size()) * 100.0, 0.1)

func get_fire_risk() -> String:
	var flam: int = get_flammable_floor_count()
	if flam == 0:
		return "None"
	elif flam < _floors.size() * 0.2:
		return "Low"
	elif flam < _floors.size() * 0.5:
		return "Moderate"
	return "High"

func get_beauty_rating() -> String:
	var avg: float = get_avg_beauty_per_tile()
	if avg >= 3.0:
		return "Gorgeous"
	elif avg >= 2.0:
		return "Beautiful"
	elif avg >= 1.0:
		return "Decent"
	return "Plain"

func get_material_quality() -> String:
	var sterile := get_sterile_ratio()
	var beauty := get_avg_beauty_per_tile()
	if sterile > 30.0 and beauty >= 2.0:
		return "Premium"
	elif sterile > 10.0 or beauty >= 1.0:
		return "Standard"
	return "Basic"

func get_coverage_adequacy() -> float:
	return snapped(get_floor_density() * 100.0, 0.1)

func get_aesthetic_investment() -> float:
	var beauty := get_total_beauty()
	var tiles := float(_floors.size())
	if tiles <= 0.0:
		return 0.0
	return snapped(beauty / tiles * 10.0, 0.1)

func get_summary() -> Dictionary:
	var counts: Dictionary = {}
	for pos: Vector2i in _floors:
		var f: String = _floors[pos]
		counts[f] = counts.get(f, 0) + 1
	return {
		"total_floors": _floors.size(),
		"by_type": counts,
		"total_beauty": snappedf(get_total_beauty(), 0.1),
		"total_placed": total_placed,
		"total_removed": total_removed,
		"most_common": get_most_common_floor(),
		"flammable_count": get_flammable_floor_count(),
		"avg_beauty": get_avg_beauty_per_tile(),
		"unique_types": get_unique_floor_type_count(),
		"replacement_rate": snappedf(get_replacement_rate(), 0.01),
		"floor_density": snappedf(get_floor_density(), 0.01),
		"sterile_ratio_pct": get_sterile_ratio(),
		"fire_risk": get_fire_risk(),
		"beauty_rating": get_beauty_rating(),
		"material_quality": get_material_quality(),
		"coverage_adequacy": get_coverage_adequacy(),
		"aesthetic_investment": get_aesthetic_investment(),
		"flooring_completeness": get_flooring_completeness(),
		"environmental_harmony": get_environmental_harmony(),
		"floor_lifecycle_health": get_floor_lifecycle_health(),
	}

func get_flooring_completeness() -> float:
	var density: float = get_floor_density()
	var sterile: float = get_sterile_ratio()
	return snappedf(clampf(density * 70.0 + sterile * 0.3, 0.0, 100.0), 0.1)

func get_environmental_harmony() -> String:
	var beauty: float = get_avg_beauty_per_tile()
	var fire_risk: String = get_fire_risk()
	if beauty >= 2.0 and fire_risk in ["None", "Low"]:
		return "Harmonious"
	if beauty >= 0.0:
		return "Neutral"
	return "Discordant"

func get_floor_lifecycle_health() -> String:
	var quality: String = get_material_quality()
	var adequacy: float = get_coverage_adequacy()
	if quality in ["Excellent", "Good"] and adequacy >= 70.0:
		return "Excellent"
	if quality != "Poor":
		return "Fair"
	return "Deteriorating"


func to_dict() -> Dictionary:
	var data: Dictionary = {}
	for pos: Vector2i in _floors:
		data["%d,%d" % [pos.x, pos.y]] = _floors[pos]
	return data


func from_dict(data: Dictionary) -> void:
	_floors.clear()
	for key: String in data:
		var parts := key.split(",")
		if parts.size() == 2:
			var pos := Vector2i(int(parts[0]), int(parts[1]))
			_floors[pos] = data[key]
