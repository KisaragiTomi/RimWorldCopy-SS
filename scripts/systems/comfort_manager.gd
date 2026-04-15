extends Node

## Tracks furniture comfort levels. Higher comfort improves rest quality
## and grants mood bonuses. Registered as autoload "ComfortManager".

const COMFORT_DEFS: Dictionary = {
	"Bed": {"comfort": 0.7, "beauty": 0.5},
	"RoyalBed": {"comfort": 0.95, "beauty": 3.0},
	"HospitalBed": {"comfort": 0.8, "beauty": 0.3},
	"SleepingSpot": {"comfort": 0.3, "beauty": -1.0},
	"Chair": {"comfort": 0.6, "beauty": 0.2},
	"Armchair": {"comfort": 0.85, "beauty": 1.0},
	"DiningChair": {"comfort": 0.65, "beauty": 0.3},
	"Throne": {"comfort": 0.95, "beauty": 5.0},
}

const COMFORT_MOOD_THRESHOLDS: Dictionary = {
	0.9: {"thought": "VeryComfortable", "mood": 0.06},
	0.7: {"thought": "Comfortable", "mood": 0.03},
	0.4: {"thought": "Uncomfortable", "mood": -0.02},
}

var _furniture_comfort: Dictionary = {}  # building_id -> {pos, def_name, comfort}


func register_furniture(building_id: int, def_name: String, pos: Vector2i) -> void:
	if not COMFORT_DEFS.has(def_name):
		return
	var def: Dictionary = COMFORT_DEFS[def_name]
	_furniture_comfort[building_id] = {
		"pos": pos,
		"def_name": def_name,
		"comfort": def.comfort,
		"beauty": def.beauty,
	}


func unregister_furniture(building_id: int) -> void:
	_furniture_comfort.erase(building_id)


func get_comfort_at(pos: Vector2i) -> float:
	var best: float = 0.0
	for fid: int in _furniture_comfort:
		var f: Dictionary = _furniture_comfort[fid]
		if f.pos == pos:
			best = maxf(best, f.comfort)
	return best


func get_comfort_in_radius(pos: Vector2i, radius: int) -> float:
	var best: float = 0.0
	for fid: int in _furniture_comfort:
		var f: Dictionary = _furniture_comfort[fid]
		if pos.distance_to(f.pos) <= float(radius):
			best = maxf(best, f.comfort)
	return best


func get_rest_quality_bonus(comfort: float) -> float:
	return clampf(comfort * 0.3, 0.0, 0.3)


func apply_comfort_thought(pawn: Pawn, comfort: float) -> void:
	if not pawn.thought_tracker:
		return
	var thresholds: Array = [0.9, 0.7, 0.4]
	for threshold: float in thresholds:
		if comfort >= threshold:
			var entry: Dictionary = COMFORT_MOOD_THRESHOLDS[threshold]
			pawn.thought_tracker.add_thought(entry.thought)
			return


func get_avg_comfort() -> float:
	if _furniture_comfort.is_empty():
		return 0.0
	var total: float = 0.0
	for fid: int in _furniture_comfort:
		total += _furniture_comfort[fid].comfort
	return snappedf(total / float(_furniture_comfort.size()), 0.01)


func get_best_comfort_furniture() -> Dictionary:
	var best_id: int = -1
	var best_val: float = 0.0
	for fid: int in _furniture_comfort:
		if _furniture_comfort[fid].comfort > best_val:
			best_val = _furniture_comfort[fid].comfort
			best_id = fid
	if best_id < 0:
		return {}
	return {"id": best_id, "def_name": _furniture_comfort[best_id].def_name, "comfort": best_val}


func get_total_beauty() -> float:
	var total: float = 0.0
	for fid: int in _furniture_comfort:
		total += _furniture_comfort[fid].beauty
	return snappedf(total, 0.1)


func get_furniture_near(pos: Vector2i, radius: int = 5) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for fid: int in _furniture_comfort:
		var f: Dictionary = _furniture_comfort[fid]
		if pos.distance_to(f.pos) <= float(radius):
			result.append({"id": fid, "def_name": f.def_name, "comfort": f.comfort})
	return result


func get_worst_comfort_furniture() -> Dictionary:
	var worst_id: int = -1
	var worst_val: float = 2.0
	for fid: int in _furniture_comfort:
		if _furniture_comfort[fid].comfort < worst_val:
			worst_val = _furniture_comfort[fid].comfort
			worst_id = fid
	if worst_id < 0:
		return {}
	return {"id": worst_id, "def_name": _furniture_comfort[worst_id].def_name, "comfort": worst_val}


func get_high_comfort_count() -> int:
	var count: int = 0
	for fid: int in _furniture_comfort:
		if _furniture_comfort[fid].comfort >= 0.8:
			count += 1
	return count


func get_comfort_rating() -> String:
	var avg := get_avg_comfort()
	if avg >= 0.85:
		return "Luxurious"
	elif avg >= 0.7:
		return "Comfortable"
	elif avg >= 0.5:
		return "Adequate"
	elif avg >= 0.3:
		return "Spartan"
	return "Miserable"


func get_comfort_coverage() -> float:
	if _furniture_comfort.is_empty():
		return 0.0
	var high: int = get_high_comfort_count()
	return snappedf(float(high) / float(_furniture_comfort.size()) * 100.0, 0.1)

func get_luxury_ratio() -> String:
	var coverage: float = get_comfort_coverage()
	if coverage >= 60.0:
		return "Luxurious"
	elif coverage >= 30.0:
		return "Comfortable"
	elif coverage > 0.0:
		return "Basic"
	return "Spartan"

func get_beauty_efficiency() -> float:
	if _furniture_comfort.is_empty():
		return 0.0
	return snappedf(get_total_beauty() / maxf(get_avg_comfort() * float(_furniture_comfort.size()), 0.01) * 100.0, 0.1)

func get_living_standard() -> String:
	var rating := get_comfort_rating()
	var luxury := get_luxury_ratio()
	if luxury == "Luxurious" and rating == "Excellent":
		return "Premium"
	elif luxury == "Comfortable":
		return "Standard"
	return "Basic"

func get_mood_contribution() -> float:
	var avg := get_avg_comfort()
	return snapped(avg * 10.0, 0.1)

func get_upgrade_potential() -> String:
	var high := get_high_comfort_count()
	var total := _furniture_comfort.size()
	if total <= 0:
		return "N/A"
	var ratio := float(high) / float(total)
	if ratio >= 0.8:
		return "Maxed"
	elif ratio >= 0.4:
		return "Moderate"
	return "High"

func get_summary() -> Dictionary:
	var by_type: Dictionary = {}
	for fid: int in _furniture_comfort:
		var d: String = _furniture_comfort[fid].def_name
		by_type[d] = by_type.get(d, 0) + 1
	return {
		"total_furniture": _furniture_comfort.size(),
		"by_type": by_type,
		"avg_comfort": get_avg_comfort(),
		"total_beauty": get_total_beauty(),
		"high_comfort": get_high_comfort_count(),
		"rating": get_comfort_rating(),
		"unique_types": by_type.size(),
		"beauty_per_furniture": snappedf(get_total_beauty() / maxf(float(_furniture_comfort.size()), 1.0), 0.01),
		"comfort_coverage_pct": get_comfort_coverage(),
		"luxury_ratio": get_luxury_ratio(),
		"beauty_efficiency": get_beauty_efficiency(),
		"living_standard": get_living_standard(),
		"mood_contribution": get_mood_contribution(),
		"upgrade_potential": get_upgrade_potential(),
		"comfort_ecosystem_health": get_comfort_ecosystem_health(),
		"furnishing_maturity": get_furnishing_maturity(),
		"quality_of_life_index": get_quality_of_life_index(),
	}

func get_comfort_ecosystem_health() -> String:
	var standard: String = get_living_standard()
	var coverage: float = get_comfort_coverage()
	if standard in ["Luxurious", "Comfortable"] and coverage >= 80.0:
		return "Thriving"
	if coverage >= 50.0:
		return "Adequate"
	return "Deficient"

func get_furnishing_maturity() -> float:
	var types: int = _furniture_comfort.size()
	var high: int = get_high_comfort_count()
	if types == 0:
		return 0.0
	return snappedf(float(high) / float(types) * 100.0, 0.1)

func get_quality_of_life_index() -> float:
	var comfort: float = get_avg_comfort()
	var beauty: float = get_total_beauty()
	var mood: float = get_mood_contribution()
	return snappedf(clampf(comfort * 30.0 + beauty * 2.0 + mood * 5.0, 0.0, 100.0), 0.1)
