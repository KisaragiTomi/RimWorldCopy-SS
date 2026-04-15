extends Node

const ROOM_TYPES: Dictionary = {
	"Bedroom": {"required": ["Bed"], "min_size": 9, "beauty_bonus": 0.0},
	"Barracks": {"required": ["Bed", "Bed"], "min_size": 25, "beauty_bonus": -5.0},
	"DiningRoom": {"required": ["Table", "Chair"], "min_size": 16, "beauty_bonus": 5.0},
	"Hospital": {"required": ["HospitalBed"], "min_size": 16, "beauty_bonus": 0.0},
	"Prison": {"required": ["PrisonBed"], "min_size": 9, "beauty_bonus": 0.0},
	"ResearchLab": {"required": ["ResearchBench"], "min_size": 16, "beauty_bonus": 0.0},
	"Workshop": {"required": ["CraftingBench"], "min_size": 16, "beauty_bonus": 0.0},
	"Kitchen": {"required": ["Stove"], "min_size": 12, "beauty_bonus": 0.0},
	"Storage": {"required": [], "min_size": 4, "beauty_bonus": -10.0},
	"Throne": {"required": ["Throne"], "min_size": 25, "beauty_bonus": 10.0},
}

var _room_cache: Dictionary = {}


func identify_room(room_id: int, furniture_list: Array, size: int) -> String:
	for type_name: String in ROOM_TYPES:
		var req: Array = ROOM_TYPES[type_name].get("required", [])
		var min_sz: int = int(ROOM_TYPES[type_name].get("min_size", 0))
		if size < min_sz:
			continue
		var all_met: bool = true
		var furn_copy: Array = furniture_list.duplicate()
		for r in req:
			var idx: int = furn_copy.find(r)
			if idx < 0:
				all_met = false
				break
			furn_copy.remove_at(idx)
		if all_met:
			_room_cache[room_id] = type_name
			return type_name
	_room_cache[room_id] = "Generic"
	return "Generic"


func get_room_type(room_id: int) -> String:
	return String(_room_cache.get(room_id, "Unknown"))


func get_beauty_bonus(room_id: int) -> float:
	var t: String = get_room_type(room_id)
	if ROOM_TYPES.has(t):
		return float(ROOM_TYPES[t].get("beauty_bonus", 0.0))
	return 0.0


func get_room_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for rid: int in _room_cache:
		var t: String = _room_cache[rid]
		dist[t] = dist.get(t, 0) + 1
	return dist


func count_rooms_of_type(type_name: String) -> int:
	var count: int = 0
	for rid: int in _room_cache:
		if _room_cache[rid] == type_name:
			count += 1
	return count


func get_rooms_of_type(type_name: String) -> Array[int]:
	var result: Array[int] = []
	for rid: int in _room_cache:
		if _room_cache[rid] == type_name:
			result.append(rid)
	return result


func get_most_common_room_type() -> String:
	var dist := get_room_distribution()
	var best: String = ""
	var best_n: int = 0
	for t: String in dist:
		if dist[t] > best_n:
			best_n = dist[t]
			best = t
	return best


func get_unique_room_type_count() -> int:
	return get_room_distribution().size()


func get_missing_room_types() -> Array[String]:
	var present := get_room_distribution()
	var missing: Array[String] = []
	for t: String in ROOM_TYPES:
		if not present.has(t):
			missing.append(t)
	return missing


func get_missing_type_pct() -> float:
	var missing: int = get_missing_room_types().size()
	if ROOM_TYPES.size() == 0:
		return 0.0
	return snappedf(float(missing) / float(ROOM_TYPES.size()) * 100.0, 0.1)


func get_avg_rooms_per_type() -> float:
	var dist := get_room_distribution()
	if dist.is_empty():
		return 0.0
	var total: int = 0
	for t: String in dist:
		total += int(dist[t])
	return snappedf(float(total) / float(dist.size()), 0.1)


func get_type_beauty_ranking() -> Array[Dictionary]:
	var ranking: Array[Dictionary] = []
	for t: String in ROOM_TYPES:
		ranking.append({"type": t, "beauty_bonus": float(ROOM_TYPES[t].get("beauty_bonus", 0.0))})
	ranking.sort_custom(func(a, b): return a.beauty_bonus > b.beauty_bonus)
	return ranking


func get_colony_comfort() -> String:
	var missing: float = get_missing_type_pct()
	if missing == 0.0:
		return "Luxurious"
	elif missing <= 20.0:
		return "Comfortable"
	elif missing <= 50.0:
		return "Basic"
	return "Lacking"

func get_specialization_ratio() -> float:
	if _room_cache.is_empty():
		return 0.0
	var unique: int = get_unique_room_type_count()
	return snappedf(float(unique) / float(_room_cache.size()) * 100.0, 0.1)

func get_redundancy_pct() -> float:
	var dist: Dictionary = get_room_distribution()
	if dist.is_empty():
		return 0.0
	var duplicated: int = 0
	var total: int = 0
	for t: String in dist:
		total += dist[t]
		if dist[t] > 1:
			duplicated += dist[t] - 1
	if total == 0:
		return 0.0
	return snappedf(float(duplicated) / float(total) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"room_type_count": ROOM_TYPES.size(),
		"cached_rooms": _room_cache.size(),
		"distribution": get_room_distribution(),
		"most_common": get_most_common_room_type(),
		"unique_types": get_unique_room_type_count(),
		"missing_types": get_missing_room_types(),
		"missing_type_pct": get_missing_type_pct(),
		"avg_rooms_per_type": get_avg_rooms_per_type(),
		"beauty_ranking": get_type_beauty_ranking(),
		"colony_comfort": get_colony_comfort(),
		"specialization_ratio": get_specialization_ratio(),
		"redundancy_pct": get_redundancy_pct(),
		"infrastructure_completeness": get_infrastructure_completeness(),
		"spatial_efficiency": get_spatial_efficiency(),
		"colony_livability": get_colony_livability(),
		"spatial_governance": get_spatial_governance(),
		"habitat_maturity_index": get_habitat_maturity_index(),
		"architectural_ecosystem_health": get_architectural_ecosystem_health(),
	}

func get_infrastructure_completeness() -> String:
	var missing_pct := get_missing_type_pct()
	if missing_pct <= 5.0:
		return "Complete"
	elif missing_pct <= 20.0:
		return "Near Complete"
	elif missing_pct <= 50.0:
		return "Partial"
	return "Minimal"

func get_spatial_efficiency() -> float:
	var avg := get_avg_rooms_per_type()
	var redundancy := get_redundancy_pct()
	if avg <= 0.0:
		return 0.0
	return snapped(maxf(100.0 - redundancy, 0.0), 0.1)

func get_colony_livability() -> String:
	var comfort := get_colony_comfort()
	var missing := get_missing_type_pct()
	if comfort in ["Luxurious", "Comfortable"] and missing <= 10.0:
		return "Excellent"
	elif comfort in ["Comfortable", "Adequate"]:
		return "Good"
	elif comfort in ["Adequate"]:
		return "Acceptable"
	return "Poor"

func get_spatial_governance() -> float:
	var efficiency := get_spatial_efficiency()
	var specialization := get_specialization_ratio()
	var redundancy := get_redundancy_pct()
	return snapped((efficiency + specialization * 100.0 + maxf(100.0 - redundancy, 0.0)) / 3.0, 0.1)

func get_habitat_maturity_index() -> float:
	var missing := get_missing_type_pct()
	var avg := get_avg_rooms_per_type()
	var completeness_val: float = maxf(100.0 - missing, 0.0)
	return snapped((completeness_val + minf(avg * 20.0, 100.0)) / 2.0, 0.1)

func get_architectural_ecosystem_health() -> String:
	var governance := get_spatial_governance()
	var maturity := get_habitat_maturity_index()
	if governance >= 70.0 and maturity >= 70.0:
		return "Thriving"
	elif governance >= 40.0 or maturity >= 40.0:
		return "Growing"
	return "Undeveloped"
