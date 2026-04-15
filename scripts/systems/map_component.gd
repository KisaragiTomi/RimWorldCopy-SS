extends Node

var _components: Dictionary = {}

const MAP_COMPONENT_TYPES: Dictionary = {
	"River": {"movement_cost": 3.0, "fertility_bonus": 0.2, "beauty": 2, "blocks_building": true},
	"Road": {"movement_cost": 0.5, "fertility_bonus": 0.0, "beauty": 0, "blocks_building": false},
	"Bridge": {"movement_cost": 0.8, "fertility_bonus": 0.0, "beauty": 1, "blocks_building": false},
	"Cliff": {"movement_cost": 999.0, "fertility_bonus": 0.0, "beauty": 1, "blocks_building": true},
	"Marsh": {"movement_cost": 2.5, "fertility_bonus": 0.3, "beauty": -1, "blocks_building": false},
	"SteamGeyser": {"movement_cost": 1.0, "fertility_bonus": 0.0, "beauty": -1, "blocks_building": false},
	"AncientRuin": {"movement_cost": 1.5, "fertility_bonus": 0.0, "beauty": 2, "blocks_building": true},
	"Cave": {"movement_cost": 1.2, "fertility_bonus": 0.0, "beauty": 0, "blocks_building": false},
	"Lake": {"movement_cost": 999.0, "fertility_bonus": 0.0, "beauty": 3, "blocks_building": true},
	"Ravine": {"movement_cost": 4.0, "fertility_bonus": 0.0, "beauty": 1, "blocks_building": true}
}

func add_component(pos: Vector2i, comp_type: String) -> Dictionary:
	if not MAP_COMPONENT_TYPES.has(comp_type):
		return {"error": "unknown_type"}
	_components[pos] = comp_type
	return {"placed": true, "type": comp_type}

func get_component_at(pos: Vector2i) -> String:
	return _components.get(pos, "")

func get_movement_cost(pos: Vector2i) -> float:
	var comp: String = _components.get(pos, "")
	if comp == "":
		return 1.0
	return MAP_COMPONENT_TYPES.get(comp, {}).get("movement_cost", 1.0)

func can_build_at(pos: Vector2i) -> bool:
	var comp: String = _components.get(pos, "")
	if comp == "":
		return true
	return not MAP_COMPONENT_TYPES.get(comp, {}).get("blocks_building", false)

func get_impassable_types() -> Array[String]:
	var result: Array[String] = []
	for c: String in MAP_COMPONENT_TYPES:
		if float(MAP_COMPONENT_TYPES[c].get("movement_cost", 1.0)) >= 999.0:
			result.append(c)
	return result


func get_component_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pos: Vector2i in _components:
		var t: String = _components[pos]
		dist[t] = int(dist.get(t, 0)) + 1
	return dist


func get_most_beautiful_component() -> String:
	var best: String = ""
	var best_b: int = -999
	for c: String in MAP_COMPONENT_TYPES:
		var b: int = int(MAP_COMPONENT_TYPES[c].get("beauty", 0))
		if b > best_b:
			best_b = b
			best = c
	return best


func get_avg_movement_cost() -> float:
	if MAP_COMPONENT_TYPES.is_empty():
		return 1.0
	var total: float = 0.0
	for ct: String in MAP_COMPONENT_TYPES:
		total += float(MAP_COMPONENT_TYPES[ct].get("movement_cost", 1.0))
	return total / MAP_COMPONENT_TYPES.size()


func get_fertile_component_count() -> int:
	var count: int = 0
	for ct: String in MAP_COMPONENT_TYPES:
		if float(MAP_COMPONENT_TYPES[ct].get("fertility_bonus", 0.0)) > 0.0:
			count += 1
	return count


func get_buildable_count() -> int:
	var count: int = 0
	for ct: String in MAP_COMPONENT_TYPES:
		if not bool(MAP_COMPONENT_TYPES[ct].get("blocks_building", false)):
			count += 1
	return count


func get_ugliest_component() -> String:
	var worst: String = ""
	var worst_b: int = 999
	for c: String in MAP_COMPONENT_TYPES:
		var b: int = int(MAP_COMPONENT_TYPES[c].get("beauty", 0))
		if b < worst_b:
			worst_b = b
			worst = c
	return worst


func get_blocking_type_count() -> int:
	var count: int = 0
	for c: String in MAP_COMPONENT_TYPES:
		if bool(MAP_COMPONENT_TYPES[c].get("blocks_building", false)):
			count += 1
	return count


func get_avg_beauty() -> float:
	if MAP_COMPONENT_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for c: String in MAP_COMPONENT_TYPES:
		total += float(MAP_COMPONENT_TYPES[c].get("beauty", 0))
	return snappedf(total / float(MAP_COMPONENT_TYPES.size()), 0.1)


func get_terrain_diversity() -> String:
	var types_used: Dictionary = {}
	for pos: Vector2i in _components:
		types_used[_components[pos]] = true
	var ratio: float = float(types_used.size()) / maxf(float(MAP_COMPONENT_TYPES.size()), 1.0)
	if ratio >= 0.7:
		return "Rich"
	if ratio >= 0.4:
		return "Moderate"
	return "Sparse"


func get_traversability_pct() -> float:
	var passable: int = MAP_COMPONENT_TYPES.size() - get_impassable_types().size()
	return snappedf(float(passable) / maxf(float(MAP_COMPONENT_TYPES.size()), 1.0) * 100.0, 0.1)


func get_development_potential() -> String:
	var buildable: int = get_buildable_count()
	var total: int = MAP_COMPONENT_TYPES.size()
	if total == 0:
		return "None"
	var ratio: float = float(buildable) / float(total)
	if ratio >= 0.6:
		return "High"
	if ratio >= 0.3:
		return "Medium"
	return "Low"


func get_summary() -> Dictionary:
	return {
		"component_types": MAP_COMPONENT_TYPES.size(),
		"placed_components": _components.size(),
		"impassable": get_impassable_types().size(),
		"most_beautiful": get_most_beautiful_component(),
		"avg_move_cost": snapped(get_avg_movement_cost(), 0.1),
		"fertile_types": get_fertile_component_count(),
		"buildable_types": get_buildable_count(),
		"blocking_types": get_blocking_type_count(),
		"avg_beauty": get_avg_beauty(),
		"terrain_diversity": get_terrain_diversity(),
		"traversability_pct": get_traversability_pct(),
		"development_potential": get_development_potential(),
		"settlement_suitability": get_settlement_suitability(),
		"resource_accessibility": get_resource_accessibility(),
		"terrain_complexity_index": get_terrain_complexity_index(),
		"land_ecosystem_health": get_land_ecosystem_health(),
		"terrain_governance": get_terrain_governance(),
		"geographic_maturity_index": get_geographic_maturity_index(),
	}

func get_settlement_suitability() -> String:
	var buildable := get_buildable_count()
	var fertile := get_fertile_component_count()
	if buildable >= 5 and fertile >= 3:
		return "Ideal"
	elif buildable >= 3:
		return "Suitable"
	return "Challenging"

func get_resource_accessibility() -> float:
	var fertile := get_fertile_component_count()
	var total := MAP_COMPONENT_TYPES.size()
	if total <= 0:
		return 0.0
	return snapped(float(fertile) / float(total) * 100.0, 0.1)

func get_terrain_complexity_index() -> float:
	var blocking := get_blocking_type_count()
	var impassable := get_impassable_types().size()
	var total := MAP_COMPONENT_TYPES.size()
	if total <= 0:
		return 0.0
	return snapped(float(blocking + impassable) / float(total) * 100.0, 0.1)

func get_land_ecosystem_health() -> float:
	var suitability := get_settlement_suitability()
	var s_val: float = 90.0 if suitability == "Ideal" else (60.0 if suitability == "Suitable" else 25.0)
	var accessibility := get_resource_accessibility()
	var traversability := get_traversability_pct()
	return snapped((s_val + accessibility + traversability) / 3.0, 0.1)

func get_terrain_governance() -> String:
	var ecosystem := get_land_ecosystem_health()
	var potential := get_development_potential()
	var p_val: float = 90.0 if potential == "High" else (60.0 if potential == "Moderate" else 25.0)
	var combined := (ecosystem + p_val) / 2.0
	if combined >= 70.0:
		return "Optimized"
	elif combined >= 40.0:
		return "Developed"
	elif _components.size() > 0:
		return "Undeveloped"
	return "Barren"

func get_geographic_maturity_index() -> float:
	var complexity := get_terrain_complexity_index()
	var diversity := get_terrain_diversity()
	var d_val: float = 90.0 if diversity == "Rich" else (60.0 if diversity == "Moderate" else 25.0)
	return snapped(((100.0 - complexity) + d_val) / 2.0, 0.1)
