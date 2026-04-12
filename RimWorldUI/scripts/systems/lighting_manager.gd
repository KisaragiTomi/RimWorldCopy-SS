extends Node

## Tracks light sources on the map. Lights improve room beauty and prevent
## "InDarkness" mood penalty. Registered as autoload "LightingManager".

const LIGHT_DEFS: Dictionary = {
	"StandingLamp": {"radius": 10, "brightness": 1.0, "beauty": 0.5, "power_draw": 75.0},
	"Torch": {"radius": 8, "brightness": 0.8, "beauty": 0.3, "power_draw": 0.0},
	"Campfire": {"radius": 6, "brightness": 0.7, "beauty": 1.0, "power_draw": 0.0},
	"SunLamp": {"radius": 14, "brightness": 1.5, "beauty": 0.0, "power_draw": 2900.0},
	"WallLight": {"radius": 7, "brightness": 0.9, "beauty": 0.3, "power_draw": 35.0},
}

var _lights: Dictionary = {}  # building_id -> {pos, def_name, radius, brightness}
var total_power_draw: float = 0.0


func register_light(building_id: int, def_name: String, pos: Vector2i) -> void:
	if not LIGHT_DEFS.has(def_name):
		return
	var def: Dictionary = LIGHT_DEFS[def_name]
	_lights[building_id] = {
		"pos": pos,
		"def_name": def_name,
		"radius": def.radius,
		"brightness": def.brightness,
		"beauty": def.beauty,
	}


func unregister_light(building_id: int) -> void:
	_lights.erase(building_id)


func get_light_level(pos: Vector2i) -> float:
	var max_light: float = 0.0
	for lid: int in _lights:
		var light: Dictionary = _lights[lid]
		var dist: float = float(pos.distance_to(light.pos))
		if dist <= float(light.radius):
			var falloff: float = 1.0 - (dist / float(light.radius))
			var level: float = light.brightness * falloff
			max_light = maxf(max_light, level)
	return clampf(max_light, 0.0, 1.5)


func is_lit(pos: Vector2i) -> bool:
	return get_light_level(pos) > 0.2


func get_beauty_bonus(pos: Vector2i) -> float:
	var bonus: float = 0.0
	for lid: int in _lights:
		var light: Dictionary = _lights[lid]
		var dist: float = float(pos.distance_to(light.pos))
		if dist <= float(light.radius):
			bonus += light.beauty * (1.0 - dist / float(light.radius))
	return bonus


func get_light_count() -> int:
	return _lights.size()


func get_all_light_types() -> Array:
	return LIGHT_DEFS.keys()


func get_total_power_draw() -> float:
	var total: float = 0.0
	for lid: int in _lights:
		var def_name: String = _lights[lid].def_name
		total += LIGHT_DEFS.get(def_name, {}).get("power_draw", 0.0)
	return total


func get_dark_colonists() -> Array[Pawn]:
	var result: Array[Pawn] = []
	if not PawnManager:
		return result
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed:
			continue
		if not is_lit(p.grid_pos):
			result.append(p)
	return result


func get_total_beauty_bonus() -> float:
	var total: float = 0.0
	for lid: int in _lights:
		total += _lights[lid].get("beauty", 0.0)
	return total


func get_nearest_light(pos: Vector2i) -> Dictionary:
	var best_dist: float = 9999.0
	var best: Dictionary = {}
	for lid: int in _lights:
		var light: Dictionary = _lights[lid]
		var dist: float = float(pos.distance_to(light.pos))
		if dist < best_dist:
			best_dist = dist
			best = {"id": lid, "pos": light.pos, "def_name": light.def_name, "distance": dist}
	return best


func get_lit_area_coverage() -> float:
	if _lights.is_empty():
		return 0.0
	var total_radius_sq: float = 0.0
	for lid: int in _lights:
		var r: float = float(_lights[lid].radius)
		total_radius_sq += r * r * PI
	return snappedf(total_radius_sq, 1.0)


func get_most_common_light() -> String:
	var counts: Dictionary = {}
	for lid: int in _lights:
		var d: String = _lights[lid].def_name
		counts[d] = counts.get(d, 0) + 1
	var best: String = ""
	var best_n: int = 0
	for d: String in counts:
		if counts[d] > best_n:
			best_n = counts[d]
			best = d
	return best


func get_avg_brightness() -> float:
	if _lights.is_empty():
		return 0.0
	var total: float = 0.0
	for lid: int in _lights:
		total += _lights[lid].brightness
	return snappedf(total / float(_lights.size()), 0.01)


func get_unpowered_light_count() -> int:
	var count: int = 0
	for lid: int in _lights:
		var def_name: String = _lights[lid].def_name
		var draw: float = LIGHT_DEFS.get(def_name, {}).get("power_draw", 0.0)
		if draw > 0.0 and PowerConsumption and not PowerConsumption.has_power(lid):
			count += 1
	return count


func get_coverage_rating() -> String:
	var dark: int = get_dark_colonists().size()
	if dark == 0:
		return "FullCoverage"
	elif dark <= 2:
		return "MostlyCovered"
	return "Inadequate"

func get_dark_risk_pct() -> float:
	if not PawnManager:
		return 0.0
	var alive: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			alive += 1
	if alive <= 0:
		return 0.0
	return snappedf(float(get_dark_colonists().size()) / float(alive) * 100.0, 0.1)

func get_efficiency_score() -> float:
	if _lights.is_empty():
		return 0.0
	return snappedf(get_avg_brightness() / maxf(get_total_power_draw() / maxf(float(_lights.size()), 1.0), 0.01) * 100.0, 0.1)

func get_illumination_quality() -> String:
	var avg := get_avg_brightness()
	var coverage := get_coverage_rating()
	if avg >= 0.8 and coverage == "WellLit":
		return "Excellent"
	elif avg >= 0.5:
		return "Adequate"
	return "Dim"

func get_energy_waste_pct() -> float:
	var total_draw := get_total_power_draw()
	if total_draw <= 0.0:
		return 0.0
	var dark := get_dark_colonists().size()
	if dark <= 0:
		return 0.0
	return snapped(float(dark) / maxf(float(_lights.size()), 1.0) * 100.0, 0.1)

func get_safety_index() -> String:
	var dark_risk := get_dark_risk_pct()
	if dark_risk <= 0.0:
		return "Safe"
	elif dark_risk < 20.0:
		return "Acceptable"
	return "Hazardous"

func get_summary() -> Dictionary:
	var by_type: Dictionary = {}
	for lid: int in _lights:
		var def_name: String = _lights[lid].def_name
		by_type[def_name] = by_type.get(def_name, 0) + 1
	return {
		"total_lights": _lights.size(),
		"by_type": by_type,
		"total_power_draw": snappedf(get_total_power_draw(), 0.1),
		"total_beauty": snappedf(get_total_beauty_bonus(), 0.1),
		"dark_colonists": get_dark_colonists().size(),
		"lit_area": get_lit_area_coverage(),
		"most_common": get_most_common_light(),
		"avg_brightness": get_avg_brightness(),
		"unique_types": by_type.size(),
		"power_per_light": snappedf(get_total_power_draw() / maxf(float(_lights.size()), 1.0), 0.01),
		"coverage_rating": get_coverage_rating(),
		"dark_risk_pct": get_dark_risk_pct(),
		"efficiency_score": get_efficiency_score(),
		"illumination_quality": get_illumination_quality(),
		"energy_waste_pct": get_energy_waste_pct(),
		"safety_index": get_safety_index(),
		"lighting_ecosystem_health": get_lighting_ecosystem_health(),
		"luminous_efficiency_index": get_luminous_efficiency_index(),
		"ambient_comfort_score": get_ambient_comfort_score(),
	}

func get_lighting_ecosystem_health() -> String:
	var coverage: String = get_coverage_rating()
	var dark_risk: float = get_dark_risk_pct()
	if coverage in ["Full", "High"] and dark_risk <= 5.0:
		return "Excellent"
	if dark_risk <= 20.0:
		return "Good"
	return "Poor"

func get_luminous_efficiency_index() -> float:
	var efficiency: float = get_efficiency_score()
	var waste: float = get_energy_waste_pct()
	return snappedf(clampf(efficiency - waste * 0.5, 0.0, 100.0), 0.1)

func get_ambient_comfort_score() -> float:
	var brightness: float = get_avg_brightness()
	var beauty: float = get_total_beauty_bonus()
	var score: float = brightness * 50.0 + beauty * 5.0
	return snappedf(clampf(score, 0.0, 100.0), 0.1)
