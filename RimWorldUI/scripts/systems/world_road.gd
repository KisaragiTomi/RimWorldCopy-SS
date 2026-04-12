extends Node

var _roads: Dictionary = {}

const ROAD_TYPES: Dictionary = {
	"DirtPath": {"move_mult": 1.2, "build_cost": 0, "description": "Slightly faster"},
	"StoneRoad": {"move_mult": 1.5, "build_cost": 50, "description": "Good road"},
	"AncientAsphaltRoad": {"move_mult": 1.8, "build_cost": 0, "description": "Pre-war highway"},
	"AncientAsphaltHighway": {"move_mult": 2.0, "build_cost": 0, "description": "Major highway"},
	"Railroad": {"move_mult": 2.5, "build_cost": 200, "description": "Fast rail connection"}
}

const BIOME_BASE_SPEED: Dictionary = {
	"TemperateForest": 1.0, "BorealForest": 0.85, "TropicalRainforest": 0.70,
	"Desert": 0.80, "IceSheet": 0.50, "Tundra": 0.65,
	"AridShrubland": 0.90, "SeaIce": 0.40, "Mountain": 0.60
}

func add_road(from_tile: Vector2i, to_tile: Vector2i, road_type: String) -> bool:
	if not ROAD_TYPES.has(road_type):
		return false
	var key: String = str(from_tile) + "_" + str(to_tile)
	_roads[key] = {"type": road_type, "from": from_tile, "to": to_tile}
	return true

func get_road_between(from_tile: Vector2i, to_tile: Vector2i) -> String:
	var key1: String = str(from_tile) + "_" + str(to_tile)
	var key2: String = str(to_tile) + "_" + str(from_tile)
	if _roads.has(key1):
		return _roads[key1]["type"]
	if _roads.has(key2):
		return _roads[key2]["type"]
	return ""

func get_travel_speed(from_tile: Vector2i, to_tile: Vector2i, biome: String) -> float:
	var base: float = BIOME_BASE_SPEED.get(biome, 1.0)
	var road: String = get_road_between(from_tile, to_tile)
	if road != "":
		base *= ROAD_TYPES[road]["move_mult"]
	return base

func get_fastest_road() -> String:
	var best: String = ""
	var best_mult: float = 0.0
	for r: String in ROAD_TYPES:
		var m: float = float(ROAD_TYPES[r].get("move_mult", 0.0))
		if m > best_mult:
			best_mult = m
			best = r
	return best


func get_slowest_biome() -> String:
	var worst: String = ""
	var worst_speed: float = 999.0
	for b: String in BIOME_BASE_SPEED:
		var s: float = float(BIOME_BASE_SPEED[b])
		if s < worst_speed:
			worst_speed = s
			worst = b
	return worst


func get_road_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for key: String in _roads:
		var rtype: String = String(_roads[key].get("type", ""))
		dist[rtype] = int(dist.get(rtype, 0)) + 1
	return dist


func get_avg_road_speed() -> float:
	var total: float = 0.0
	for r: String in ROAD_TYPES:
		total += float(ROAD_TYPES[r].get("move_mult", 1.0))
	return total / maxf(ROAD_TYPES.size(), 1)


func get_free_road_count() -> int:
	var count: int = 0
	for r: String in ROAD_TYPES:
		if int(ROAD_TYPES[r].get("build_cost", 0)) == 0:
			count += 1
	return count


func get_fastest_biome() -> String:
	var best: String = ""
	var best_speed: float = 0.0
	for b: String in BIOME_BASE_SPEED:
		if float(BIOME_BASE_SPEED[b]) > best_speed:
			best_speed = float(BIOME_BASE_SPEED[b])
			best = b
	return best


func get_avg_biome_speed() -> float:
	if BIOME_BASE_SPEED.is_empty():
		return 0.0
	var total: float = 0.0
	for b: String in BIOME_BASE_SPEED:
		total += float(BIOME_BASE_SPEED[b])
	return snappedf(total / float(BIOME_BASE_SPEED.size()), 0.01)


func get_most_common_road_type() -> String:
	var dist: Dictionary = get_road_distribution()
	var best: String = ""
	var best_n: int = 0
	for r: String in dist:
		if int(dist[r]) > best_n:
			best_n = int(dist[r])
			best = r
	return best


func get_expensive_road_count() -> int:
	var count: int = 0
	for r: String in ROAD_TYPES:
		if int(ROAD_TYPES[r].get("build_cost", 0)) > 0:
			count += 1
	return count


func get_infrastructure_grade() -> String:
	if _roads.is_empty():
		return "Wilderness"
	var avg: float = get_avg_road_speed()
	if avg >= 1.5:
		return "Highway"
	elif avg >= 1.0:
		return "Paved"
	elif avg >= 0.5:
		return "Trail"
	return "Rough"

func get_accessibility_pct() -> float:
	if ROAD_TYPES.is_empty():
		return 0.0
	var placed_types: int = 0
	for road in _roads:
		if road.get("type", "") != "":
			placed_types += 1
	return snappedf(float(_roads.size()) / maxf(float(ROAD_TYPES.size()), 1.0) * 100.0, 0.1)

func get_travel_economy() -> String:
	var free: int = get_free_road_count()
	if _roads.is_empty():
		return "N/A"
	var pct: float = float(free) / float(_roads.size())
	if pct >= 0.7:
		return "Free"
	elif pct >= 0.4:
		return "Affordable"
	elif pct >= 0.15:
		return "Costly"
	return "Prohibitive"

func get_summary() -> Dictionary:
	return {
		"road_types": ROAD_TYPES.size(),
		"placed_roads": _roads.size(),
		"biome_speeds": BIOME_BASE_SPEED.size(),
		"fastest_road": get_fastest_road(),
		"slowest_biome": get_slowest_biome(),
		"avg_road_speed": snapped(get_avg_road_speed(), 0.01),
		"free_roads": get_free_road_count(),
		"fastest_biome": get_fastest_biome(),
		"avg_biome_speed": get_avg_biome_speed(),
		"most_common_road": get_most_common_road_type(),
		"expensive_roads": get_expensive_road_count(),
		"infrastructure_grade": get_infrastructure_grade(),
		"accessibility_pct": get_accessibility_pct(),
		"travel_economy": get_travel_economy(),
		"route_network_quality": get_route_network_quality(),
		"logistics_efficiency": get_logistics_efficiency(),
		"connectivity_score": get_connectivity_score(),
		"transport_ecosystem_health": get_transport_ecosystem_health(),
		"road_governance": get_road_governance(),
		"mobility_maturity_index": get_mobility_maturity_index(),
	}

func get_route_network_quality() -> String:
	var grade := get_infrastructure_grade()
	var access := get_accessibility_pct()
	if grade in ["Advanced", "Superior"] and access >= 70.0:
		return "Excellent"
	elif grade in ["Standard", "Advanced"]:
		return "Adequate"
	return "Poor"

func get_logistics_efficiency() -> float:
	var avg_speed := get_avg_road_speed()
	var free := get_free_road_count()
	var total := _roads.size()
	if total <= 0:
		return 0.0
	return snapped(avg_speed * (float(free) / float(total) + 0.5), 0.01)

func get_connectivity_score() -> float:
	var placed := _roads.size()
	var types := ROAD_TYPES.size()
	if types <= 0:
		return 0.0
	return snapped(float(placed) / float(types) * 100.0, 0.1)

func get_transport_ecosystem_health() -> float:
	var quality := get_route_network_quality()
	var q_val: float = 90.0 if quality == "Excellent" else (60.0 if quality == "Adequate" else 25.0)
	var efficiency := get_logistics_efficiency()
	var connectivity := get_connectivity_score()
	return snapped((q_val + minf(efficiency, 100.0) + connectivity) / 3.0, 0.1)

func get_road_governance() -> String:
	var ecosystem := get_transport_ecosystem_health()
	var grade := get_infrastructure_grade()
	var g_val: float = 90.0 if grade in ["Advanced", "Superior"] else (60.0 if grade == "Standard" else 25.0)
	var combined := (ecosystem + g_val) / 2.0
	if combined >= 70.0:
		return "Well-Maintained"
	elif combined >= 40.0:
		return "Functional"
	elif _roads.size() > 0:
		return "Neglected"
	return "Wilderness"

func get_mobility_maturity_index() -> float:
	var access := get_accessibility_pct()
	var economy := get_travel_economy()
	var e_val: float = 90.0 if economy == "Efficient" else (60.0 if economy == "Moderate" else 25.0)
	return snapped((access + e_val) / 2.0, 0.1)
