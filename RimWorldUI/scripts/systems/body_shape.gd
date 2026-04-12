extends Node

const SHAPE_THIN: int = 0
const SHAPE_AVERAGE: int = 1
const SHAPE_HULK: int = 2
const SHAPE_FAT: int = 3

const SHAPE_DATA: Dictionary = {
	0: {"name": "Thin", "move_speed": 1.05, "melee_damage": 0.85, "carry_capacity": 0.8, "food_rate": 0.85},
	1: {"name": "Average", "move_speed": 1.0, "melee_damage": 1.0, "carry_capacity": 1.0, "food_rate": 1.0},
	2: {"name": "Hulk", "move_speed": 0.9, "melee_damage": 1.3, "carry_capacity": 1.3, "food_rate": 1.2},
	3: {"name": "Fat", "move_speed": 0.85, "melee_damage": 0.95, "carry_capacity": 1.1, "food_rate": 1.3},
}

var _pawn_shapes: Dictionary = {}


func assign_shape(pawn_id: int, shape: int) -> void:
	_pawn_shapes[pawn_id] = shape


func get_shape(pawn_id: int) -> int:
	return int(_pawn_shapes.get(pawn_id, SHAPE_AVERAGE))


func get_shape_name(pawn_id: int) -> String:
	var s: int = get_shape(pawn_id)
	return String(SHAPE_DATA.get(s, {}).get("name", "Average"))


func get_modifier(pawn_id: int, stat: String) -> float:
	var s: int = get_shape(pawn_id)
	var data: Dictionary = SHAPE_DATA.get(s, {})
	return float(data.get(stat, 1.0))


func randomize_shape(pawn_id: int) -> void:
	var r: float = randf()
	var shape: int = SHAPE_AVERAGE
	if r < 0.15:
		shape = SHAPE_THIN
	elif r < 0.75:
		shape = SHAPE_AVERAGE
	elif r < 0.9:
		shape = SHAPE_HULK
	else:
		shape = SHAPE_FAT
	assign_shape(pawn_id, shape)


func get_shape_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pid: int in _pawn_shapes:
		var s: int = _pawn_shapes[pid]
		var name: String = String(SHAPE_DATA.get(s, {}).get("name", "Unknown"))
		dist[name] = dist.get(name, 0) + 1
	return dist


func get_pawns_by_shape(shape: int) -> Array[int]:
	var result: Array[int] = []
	for pid: int in _pawn_shapes:
		if _pawn_shapes[pid] == shape:
			result.append(pid)
	return result


func get_all_modifiers(pawn_id: int) -> Dictionary:
	var s: int = get_shape(pawn_id)
	var data: Dictionary = SHAPE_DATA.get(s, {})
	return {
		"shape": data.get("name", "Average"),
		"move_speed": data.get("move_speed", 1.0),
		"melee_damage": data.get("melee_damage", 1.0),
		"carry_capacity": data.get("carry_capacity", 1.0),
		"food_rate": data.get("food_rate", 1.0),
	}


func get_most_common_shape() -> String:
	var dist := get_shape_distribution()
	var best: String = ""
	var best_n: int = 0
	for s: String in dist:
		if dist[s] > best_n:
			best_n = dist[s]
			best = s
	return best


func get_fastest_shape() -> String:
	var best: String = ""
	var best_speed: float = 0.0
	for sid: int in SHAPE_DATA:
		var spd: float = float(SHAPE_DATA[sid].get("move_speed", 1.0))
		if spd > best_speed:
			best_speed = spd
			best = String(SHAPE_DATA[sid].get("name", ""))
	return best


func get_strongest_shape() -> String:
	var best: String = ""
	var best_dmg: float = 0.0
	for sid: int in SHAPE_DATA:
		var dmg: float = float(SHAPE_DATA[sid].get("melee_damage", 1.0))
		if dmg > best_dmg:
			best_dmg = dmg
			best = String(SHAPE_DATA[sid].get("name", ""))
	return best


func get_unique_assigned_shape_count() -> int:
	var seen: Dictionary = {}
	for pid: int in _pawn_shapes:
		seen[_pawn_shapes[pid]] = true
	return seen.size()


func get_avg_pawns_per_shape() -> float:
	var unique: int = get_unique_assigned_shape_count()
	if unique == 0:
		return 0.0
	return snappedf(float(_pawn_shapes.size()) / float(unique), 0.1)


func get_shape_pct_distribution() -> Dictionary:
	var dist := get_shape_distribution()
	var total: int = _pawn_shapes.size()
	if total == 0:
		return {}
	var pct: Dictionary = {}
	for s: String in dist:
		pct[s] = snappedf(float(dist[s]) / float(total) * 100.0, 0.1)
	return pct


func get_physical_diversity() -> float:
	if SHAPE_DATA.is_empty():
		return 0.0
	return snappedf(float(get_unique_assigned_shape_count()) / float(SHAPE_DATA.size()) * 100.0, 0.1)

func get_combat_fitness() -> String:
	var strongest: String = get_strongest_shape()
	var dist: Dictionary = get_shape_distribution()
	var strong_count: int = dist.get(strongest, 0)
	if strong_count >= _pawn_shapes.size() / 2:
		return "Combat Ready"
	elif strong_count > 0:
		return "Mixed"
	return "Non-Combat"

func get_mobility_rating() -> String:
	var fastest: String = get_fastest_shape()
	var dist: Dictionary = get_shape_distribution()
	var fast_count: int = dist.get(fastest, 0)
	if fast_count >= _pawn_shapes.size() / 2:
		return "Agile"
	elif fast_count > 0:
		return "Average"
	return "Slow"

func get_summary() -> Dictionary:
	return {
		"shape_types": SHAPE_DATA.size(),
		"assigned_pawns": _pawn_shapes.size(),
		"distribution": get_shape_distribution(),
		"most_common": get_most_common_shape(),
		"fastest": get_fastest_shape(),
		"strongest": get_strongest_shape(),
		"unique_assigned_shapes": get_unique_assigned_shape_count(),
		"avg_pawns_per_shape": get_avg_pawns_per_shape(),
		"pct_distribution": get_shape_pct_distribution(),
		"physical_diversity_pct": get_physical_diversity(),
		"combat_fitness": get_combat_fitness(),
		"mobility_rating": get_mobility_rating(),
		"body_composition_balance": get_body_composition_balance(),
		"physical_potential": get_physical_potential(),
		"ergonomic_index": get_ergonomic_index(),
		"biomechanical_balance": get_biomechanical_balance(),
		"physical_capital_index": get_physical_capital_index(),
		"morphological_governance": get_morphological_governance(),
	}

func get_biomechanical_balance() -> float:
	var diversity := get_physical_diversity()
	var ergonomic := get_ergonomic_index()
	return snapped((diversity + ergonomic) / 2.0, 0.1)

func get_physical_capital_index() -> float:
	var potential := get_physical_potential()
	var fitness := get_combat_fitness()
	var p_val: float = 80.0 if potential == "High" else (50.0 if potential == "Moderate" else 20.0)
	var f_val: float = 80.0 if fitness == "Fit" else (50.0 if fitness == "Average" else 20.0)
	return snapped((p_val + f_val) / 2.0, 0.1)

func get_morphological_governance() -> String:
	var balance := get_body_composition_balance()
	var mobility := get_mobility_rating()
	if balance == "Balanced" and mobility in ["Agile", "Swift"]:
		return "Harmonized"
	elif balance == "Skewed":
		return "Unbalanced"
	return "Mixed"

func get_body_composition_balance() -> String:
	var diversity := get_physical_diversity()
	if diversity >= 70.0:
		return "Balanced"
	elif diversity >= 40.0:
		return "Moderate"
	return "Skewed"

func get_physical_potential() -> String:
	var fitness := get_combat_fitness()
	var mobility := get_mobility_rating()
	if fitness == "Combat Ready" and mobility == "Agile":
		return "Peak"
	elif fitness in ["Combat Ready", "Mixed"] and mobility in ["Agile", "Average"]:
		return "Capable"
	return "Limited"

func get_ergonomic_index() -> float:
	var diversity := get_physical_diversity()
	var fitness_score := 0.0
	match get_combat_fitness():
		"Combat Ready":
			fitness_score = 90.0
		"Mixed":
			fitness_score = 55.0
		_:
			fitness_score = 20.0
	return snapped((diversity + fitness_score) / 2.0, 0.1)
