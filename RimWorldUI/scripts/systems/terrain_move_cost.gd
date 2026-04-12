extends Node

const TERRAIN_MOVE_COST: Dictionary = {
	"Soil": 1.0,
	"RichSoil": 1.0,
	"GravelSoil": 1.2,
	"Sand": 1.5,
	"SoftSand": 2.0,
	"Marsh": 2.5,
	"Mud": 2.0,
	"ShallowWater": 3.0,
	"DeepWater": 999.0,
	"Ice": 1.3,
	"Snow": 1.8,
	"SmoothStone": 0.9,
	"RoughStone": 1.1,
	"Concrete": 0.8,
	"WoodFloor": 0.85,
	"TileFloor": 0.8,
	"CarpetFloor": 0.85,
	"SterileTile": 0.8,
}

const WEATHER_MODIFIERS: Dictionary = {
	"Rain": 1.2,
	"Snow": 1.5,
	"FoggyRain": 1.3,
	"Clear": 1.0,
	"DryThunderstorm": 1.1,
}


func get_move_cost(terrain_id: String) -> float:
	return float(TERRAIN_MOVE_COST.get(terrain_id, 1.0))


func get_weather_modifier(weather_id: String) -> float:
	return float(WEATHER_MODIFIERS.get(weather_id, 1.0))


func get_effective_cost(terrain_id: String, weather_id: String) -> float:
	return get_move_cost(terrain_id) * get_weather_modifier(weather_id)


func is_passable(terrain_id: String) -> bool:
	return get_move_cost(terrain_id) < 100.0


func get_fastest_terrains(count: int = 5) -> Array[String]:
	var sorted: Array[Dictionary] = []
	for tid: String in TERRAIN_MOVE_COST:
		if TERRAIN_MOVE_COST[tid] < 100.0:
			sorted.append({"id": tid, "cost": TERRAIN_MOVE_COST[tid]})
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.cost < b.cost)
	var result: Array[String] = []
	for i in range(mini(count, sorted.size())):
		result.append(String(sorted[i].id))
	return result


func get_impassable_terrains() -> Array[String]:
	var result: Array[String] = []
	for tid: String in TERRAIN_MOVE_COST:
		if TERRAIN_MOVE_COST[tid] >= 100.0:
			result.append(tid)
	return result


func get_worst_weather() -> String:
	var worst: String = ""
	var worst_mod: float = 0.0
	for wid: String in WEATHER_MODIFIERS:
		if WEATHER_MODIFIERS[wid] > worst_mod:
			worst_mod = WEATHER_MODIFIERS[wid]
			worst = wid
	return worst


func get_avg_move_cost() -> float:
	if TERRAIN_MOVE_COST.is_empty():
		return 0.0
	var total: float = 0.0
	var count: int = 0
	for tid: String in TERRAIN_MOVE_COST:
		if TERRAIN_MOVE_COST[tid] < 100.0:
			total += TERRAIN_MOVE_COST[tid]
			count += 1
	if count == 0:
		return 0.0
	return snappedf(total / float(count), 0.01)


func get_slowest_passable() -> String:
	var worst: String = ""
	var worst_cost: float = 0.0
	for tid: String in TERRAIN_MOVE_COST:
		if TERRAIN_MOVE_COST[tid] < 100.0 and TERRAIN_MOVE_COST[tid] > worst_cost:
			worst_cost = TERRAIN_MOVE_COST[tid]
			worst = tid
	return worst


func get_passable_count() -> int:
	return TERRAIN_MOVE_COST.size() - get_impassable_terrains().size()


func get_cost_range() -> Dictionary:
	var lo: float = 999.0
	var hi: float = 0.0
	for tid: String in TERRAIN_MOVE_COST:
		var c: float = TERRAIN_MOVE_COST[tid]
		if c < 100.0:
			if c < lo:
				lo = c
			if c > hi:
				hi = c
	return {"min": snappedf(lo, 0.01), "max": snappedf(hi, 0.01)}


func get_passable_pct() -> float:
	if TERRAIN_MOVE_COST.is_empty():
		return 0.0
	return snappedf(float(get_passable_count()) / float(TERRAIN_MOVE_COST.size()) * 100.0, 0.1)


func get_best_weather() -> String:
	var best: String = ""
	var best_mod: float = 999.0
	for wid: String in WEATHER_MODIFIERS:
		if WEATHER_MODIFIERS[wid] < best_mod:
			best_mod = WEATHER_MODIFIERS[wid]
			best = wid
	return best


func get_traversal_difficulty() -> String:
	var avg: float = get_avg_move_cost()
	if avg <= 1.5:
		return "Easy"
	elif avg <= 3.0:
		return "Moderate"
	elif avg <= 5.0:
		return "Difficult"
	return "Treacherous"

func get_terrain_variety() -> float:
	if TERRAIN_MOVE_COST.is_empty():
		return 0.0
	var r: Dictionary = get_cost_range()
	var rng: float = r.get("max", 0.0) - r.get("min", 0.0)
	if r.get("max", 1.0) == 0.0:
		return 0.0
	return snappedf(rng / r.get("max", 1.0) * 100.0, 0.1)

func get_mobility_outlook() -> String:
	var best: String = get_best_weather()
	var worst: String = get_worst_weather()
	if best == worst:
		return "Stable"
	var passable_pct: float = get_passable_pct()
	if passable_pct >= 80.0:
		return "Favorable"
	elif passable_pct >= 50.0:
		return "Mixed"
	return "Hostile"

func get_summary() -> Dictionary:
	return {
		"terrain_types": TERRAIN_MOVE_COST.size(),
		"weather_types": WEATHER_MODIFIERS.size(),
		"impassable": get_impassable_terrains().size(),
		"fastest": get_fastest_terrains(3),
		"worst_weather": get_worst_weather(),
		"avg_cost": get_avg_move_cost(),
		"slowest_passable": get_slowest_passable(),
		"passable_count": get_passable_count(),
		"cost_range": get_cost_range(),
		"passable_pct": get_passable_pct(),
		"best_weather": get_best_weather(),
		"traversal_difficulty": get_traversal_difficulty(),
		"terrain_variety_pct": get_terrain_variety(),
		"mobility_outlook": get_mobility_outlook(),
		"pathfinding_complexity": get_pathfinding_complexity(),
		"terrain_accessibility": get_terrain_accessibility(),
		"movement_efficiency_index": get_movement_efficiency_index(),
		"terrain_ecosystem_health": get_terrain_ecosystem_health(),
		"mobility_governance": get_mobility_governance(),
		"geographic_mastery_index": get_geographic_mastery_index(),
	}

func get_pathfinding_complexity() -> String:
	var variety := get_terrain_variety()
	var impassable := get_impassable_terrains().size()
	if variety >= 70.0 and impassable >= 3:
		return "Complex"
	elif variety >= 40.0:
		return "Moderate"
	return "Simple"

func get_terrain_accessibility() -> float:
	var passable := get_passable_count()
	var total := TERRAIN_MOVE_COST.size()
	if total <= 0:
		return 0.0
	return snapped(float(passable) / float(total) * 100.0, 0.1)

func get_movement_efficiency_index() -> float:
	var avg := get_avg_move_cost()
	if avg <= 0.0:
		return 0.0
	return snapped(1.0 / avg * 100.0, 0.1)

func get_terrain_ecosystem_health() -> float:
	var accessibility := get_terrain_accessibility()
	var efficiency := get_movement_efficiency_index()
	var variety := get_terrain_variety()
	return snapped((accessibility + efficiency + variety) / 3.0, 0.1)

func get_mobility_governance() -> String:
	var health := get_terrain_ecosystem_health()
	var complexity := get_pathfinding_complexity()
	if health >= 60.0 and complexity in ["Simple", "Moderate"]:
		return "Optimized"
	elif health >= 35.0:
		return "Manageable"
	return "Hindered"

func get_geographic_mastery_index() -> float:
	var passable_pct := get_passable_pct()
	var difficulty := get_traversal_difficulty()
	var d_val: float = 90.0 if difficulty == "Easy" else (60.0 if difficulty == "Moderate" else 30.0)
	return snapped((passable_pct + d_val) / 2.0, 0.1)
