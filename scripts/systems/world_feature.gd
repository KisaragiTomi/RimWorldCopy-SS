extends Node

var _features: Dictionary = {}

const FEATURE_TYPES: Dictionary = {
	"Mountain": {"size_range": [3, 15], "movement_penalty": 0.5, "beauty": 2},
	"Ocean": {"size_range": [10, 50], "movement_penalty": 999.0, "beauty": 3},
	"Lake": {"size_range": [2, 8], "movement_penalty": 999.0, "beauty": 3},
	"Desert": {"size_range": [5, 20], "movement_penalty": 0.3, "beauty": 0},
	"Forest": {"size_range": [4, 12], "movement_penalty": 0.1, "beauty": 2},
	"Volcano": {"size_range": [1, 3], "movement_penalty": 0.6, "beauty": 1, "danger": true},
	"Canyon": {"size_range": [2, 10], "movement_penalty": 0.4, "beauty": 2},
	"Glacier": {"size_range": [3, 12], "movement_penalty": 0.5, "beauty": 1},
	"Swamp": {"size_range": [3, 8], "movement_penalty": 0.4, "beauty": -1},
	"Plains": {"size_range": [5, 25], "movement_penalty": 0.0, "beauty": 1},
	"Archipelago": {"size_range": [5, 15], "movement_penalty": 0.3, "beauty": 3},
	"Crater": {"size_range": [1, 5], "movement_penalty": 0.2, "beauty": 1}
}

func generate_feature(feat_type: String, center_tile: Vector2i, given_name: String) -> Dictionary:
	if not FEATURE_TYPES.has(feat_type):
		return {"error": "unknown_feature"}
	var size_r: Array = FEATURE_TYPES[feat_type]["size_range"]
	var feat_size: int = randi_range(size_r[0], size_r[1])
	_features[given_name] = {"type": feat_type, "center": center_tile, "size": feat_size}
	return {"generated": given_name, "type": feat_type, "size": feat_size}

func get_feature_at(tile: Vector2i) -> String:
	for fname: String in _features:
		var center: Vector2i = _features[fname]["center"]
		var feat_size: int = _features[fname]["size"]
		if Vector2(tile - center).length() <= feat_size:
			return fname
	return ""

func get_dangerous_features() -> Array[String]:
	var result: Array[String] = []
	for ft: String in FEATURE_TYPES:
		if FEATURE_TYPES[ft].get("danger", false):
			result.append(ft)
	return result

func get_most_beautiful() -> String:
	var best: String = ""
	var best_b: int = -999
	for ft: String in FEATURE_TYPES:
		if FEATURE_TYPES[ft]["beauty"] > best_b:
			best_b = FEATURE_TYPES[ft]["beauty"]
			best = ft
	return best

func get_impassable_features() -> Array[String]:
	var result: Array[String] = []
	for ft: String in FEATURE_TYPES:
		if FEATURE_TYPES[ft]["movement_penalty"] >= 999.0:
			result.append(ft)
	return result

func get_impassable_feature_count() -> int:
	var count: int = 0
	for ft: String in FEATURE_TYPES:
		if float(FEATURE_TYPES[ft].get("movement_penalty", 0.0)) >= 999.0:
			count += 1
	return count


func get_avg_beauty() -> float:
	if FEATURE_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for ft: String in FEATURE_TYPES:
		total += float(FEATURE_TYPES[ft].get("beauty", 0))
	return total / FEATURE_TYPES.size()


func get_largest_feature_type() -> String:
	var best: String = ""
	var best_max: int = 0
	for ft: String in FEATURE_TYPES:
		var r: Array = FEATURE_TYPES[ft].get("size_range", [0, 0])
		if r.size() >= 2 and int(r[1]) > best_max:
			best_max = int(r[1])
			best = ft
	return best


func get_ugliest_feature() -> String:
	var worst: String = ""
	var worst_b: int = 999
	for ft: String in FEATURE_TYPES:
		var b: int = int(FEATURE_TYPES[ft].get("beauty", 999))
		if b < worst_b:
			worst_b = b
			worst = ft
	return worst


func get_avg_movement_penalty() -> float:
	if FEATURE_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	var count: int = 0
	for ft: String in FEATURE_TYPES:
		var pen: float = float(FEATURE_TYPES[ft].get("movement_penalty", 0.0))
		if pen < 999.0:
			total += pen
			count += 1
	if count == 0:
		return 0.0
	return total / count


func get_small_feature_count() -> int:
	var count: int = 0
	for ft: String in FEATURE_TYPES:
		var r: Array = FEATURE_TYPES[ft].get("size_range", [0, 0])
		if r.size() >= 2 and int(r[1]) <= 5:
			count += 1
	return count


func get_exploration_value() -> String:
	var total: int = _features.size()
	if total == 0:
		return "unexplored"
	var unique_types: Dictionary = {}
	for fname: String in _features:
		unique_types[_features[fname]["type"]] = true
	var diversity: float = unique_types.size() * 1.0 / FEATURE_TYPES.size()
	if diversity >= 0.7:
		return "highly_diverse"
	if diversity >= 0.4:
		return "moderate"
	return "limited"

func get_settlement_viability_pct() -> float:
	var viable: int = 0
	for ft: String in FEATURE_TYPES:
		var info: Dictionary = FEATURE_TYPES[ft]
		if info["movement_penalty"] < 999.0 and info["beauty"] >= 0:
			viable += 1
	if FEATURE_TYPES.is_empty():
		return 0.0
	return snapped(viable * 100.0 / FEATURE_TYPES.size(), 0.1)

func get_terrain_threat_rating() -> String:
	var dangerous: int = get_dangerous_features().size()
	var impassable: int = get_impassable_feature_count()
	var total: int = _features.size()
	if total == 0:
		return "unknown"
	var threat_ratio: float = (dangerous + impassable) * 1.0 / total
	if threat_ratio >= 0.5:
		return "hostile"
	if threat_ratio >= 0.2:
		return "moderate"
	return "safe"

func get_summary() -> Dictionary:
	return {
		"feature_types": FEATURE_TYPES.size(),
		"generated_features": _features.size(),
		"dangerous_count": get_dangerous_features().size(),
		"most_beautiful": get_most_beautiful(),
		"impassable": get_impassable_feature_count(),
		"avg_beauty": snapped(get_avg_beauty(), 0.1),
		"largest_type": get_largest_feature_type(),
		"ugliest": get_ugliest_feature(),
		"avg_move_penalty": snapped(get_avg_movement_penalty(), 0.01),
		"small_features": get_small_feature_count(),
		"exploration_value": get_exploration_value(),
		"settlement_viability_pct": get_settlement_viability_pct(),
		"terrain_threat_rating": get_terrain_threat_rating(),
		"landscape_appeal": get_landscape_appeal(),
		"navigation_difficulty": get_navigation_difficulty(),
		"strategic_geography": get_strategic_geography(),
		"geographic_ecosystem_health": get_geographic_ecosystem_health(),
		"terrain_governance": get_terrain_governance(),
		"exploration_maturity_index": get_exploration_maturity_index(),
	}

func get_landscape_appeal() -> float:
	var avg_beauty := get_avg_beauty()
	var beautiful_count := 0
	for f: Dictionary in FEATURE_TYPES:
		if f.get("beauty", 0) > 0:
			beautiful_count += 1
	return snapped(avg_beauty * float(beautiful_count + 1), 0.1)

func get_navigation_difficulty() -> String:
	var impassable := get_impassable_feature_count()
	var penalty := get_avg_movement_penalty()
	if impassable >= 3 or penalty >= 2.0:
		return "Treacherous"
	elif impassable >= 1 or penalty >= 1.0:
		return "Challenging"
	return "Easy"

func get_strategic_geography() -> String:
	var dangerous := get_dangerous_features().size()
	var viability := get_settlement_viability_pct()
	if viability >= 60.0 and dangerous <= 1:
		return "Favorable"
	elif viability >= 30.0:
		return "Mixed"
	return "Hostile"

func get_geographic_ecosystem_health() -> float:
	var appeal := get_landscape_appeal()
	var navigation := get_navigation_difficulty()
	var n_val: float = 90.0 if navigation == "Easy" else (50.0 if navigation == "Challenging" else 20.0)
	var threat := get_terrain_threat_rating()
	var t_val: float = 90.0 if threat in ["safe", "low"] else (50.0 if threat in ["moderate", "unknown"] else 20.0)
	return snapped((minf(appeal, 100.0) + n_val + t_val) / 3.0, 0.1)

func get_exploration_maturity_index() -> float:
	var viability := get_settlement_viability_pct()
	var geography := get_strategic_geography()
	var g_val: float = 90.0 if geography == "Favorable" else (60.0 if geography == "Mixed" else 30.0)
	var exploration := get_exploration_value()
	var e_val: float = 90.0 if exploration in ["rich", "abundant"] else (60.0 if exploration in ["moderate", "promising"] else 30.0)
	return snapped((viability + g_val + e_val) / 3.0, 0.1)

func get_terrain_governance() -> String:
	var ecosystem := get_geographic_ecosystem_health()
	var maturity := get_exploration_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _features.size() > 0:
		return "Nascent"
	return "Dormant"
