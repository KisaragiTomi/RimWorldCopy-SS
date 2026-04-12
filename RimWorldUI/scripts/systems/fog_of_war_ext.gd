extends Node

var _visibility_map: Dictionary = {}
var _sight_range: int = 12

const SIGHT_RANGES: Dictionary = {
	"Normal": 12,
	"NightOwl": 10,
	"KeenEyed": 16,
	"Bionic": 20,
	"Blind": 0,
}


func set_sight_range(pawn_id: int, sight_trait: String) -> void:
	_sight_range = int(SIGHT_RANGES.get(sight_trait, 12))


func reveal_area(center: Vector2i, radius: int) -> int:
	var revealed: int = 0
	for dx: int in range(-radius, radius + 1):
		for dy: int in range(-radius, radius + 1):
			if dx * dx + dy * dy <= radius * radius:
				var pos: Vector2i = center + Vector2i(dx, dy)
				if not _visibility_map.has(pos):
					_visibility_map[pos] = true
					revealed += 1
	return revealed


func is_visible(pos: Vector2i) -> bool:
	return _visibility_map.has(pos)


func get_revealed_percent(map_width: int, map_height: int) -> float:
	var total: int = map_width * map_height
	if total <= 0:
		return 0.0
	return float(_visibility_map.size()) / float(total) * 100.0


func get_best_sight_trait() -> String:
	var best: String = ""
	var best_range: int = 0
	for t_name: String in SIGHT_RANGES:
		if SIGHT_RANGES[t_name] > best_range:
			best_range = SIGHT_RANGES[t_name]
			best = t_name
	return best


func get_unrevealed_count(map_width: int, map_height: int) -> int:
	return maxi(0, map_width * map_height - _visibility_map.size())


func reset_visibility() -> void:
	_visibility_map.clear()


func get_worst_sight_trait() -> String:
	var worst: String = ""
	var worst_range: int = 999
	for trait_name: String in SIGHT_RANGES:
		if SIGHT_RANGES[trait_name] < worst_range:
			worst_range = SIGHT_RANGES[trait_name]
			worst = trait_name
	return worst


func get_avg_sight_range() -> float:
	if SIGHT_RANGES.is_empty():
		return 12.0
	var total: int = 0
	for t: String in SIGHT_RANGES:
		total += SIGHT_RANGES[t]
	return snappedf(float(total) / float(SIGHT_RANGES.size()), 0.1)


func get_visibility_coverage_pct() -> float:
	return snappedf(float(_visibility_map.size()) / 10000.0 * 100.0, 0.1)


func get_sight_range_spread() -> int:
	var lo: int = 999
	var hi: int = 0
	for t: String in SIGHT_RANGES:
		var r: int = int(SIGHT_RANGES[t])
		if r < lo:
			lo = r
		if r > hi:
			hi = r
	return hi - lo


func get_above_average_trait_count() -> int:
	var avg: float = get_avg_sight_range()
	var count: int = 0
	for t: String in SIGHT_RANGES:
		if float(SIGHT_RANGES[t]) > avg:
			count += 1
	return count


func get_blind_trait_exists() -> bool:
	for t: String in SIGHT_RANGES:
		if int(SIGHT_RANGES[t]) == 0:
			return true
	return false


func get_awareness_level() -> String:
	var coverage: float = get_visibility_coverage_pct()
	if coverage >= 80.0:
		return "Full Awareness"
	elif coverage >= 50.0:
		return "Moderate"
	elif coverage >= 20.0:
		return "Limited"
	return "Blind"

func get_scouting_quality() -> String:
	var avg: float = get_avg_sight_range()
	if avg >= 15.0:
		return "Excellent"
	elif avg >= 12.0:
		return "Good"
	elif avg >= 8.0:
		return "Fair"
	return "Poor"

func get_vulnerability_pct() -> float:
	if SIGHT_RANGES.is_empty():
		return 0.0
	var weak: int = 0
	for sr_name: String in SIGHT_RANGES:
		if SIGHT_RANGES[sr_name] < 10:
			weak += 1
	return snappedf(float(weak) / float(SIGHT_RANGES.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"revealed_tiles": _visibility_map.size(),
		"sight_range_types": SIGHT_RANGES.size(),
		"default_range": 12,
		"best_trait": get_best_sight_trait(),
		"worst_trait": get_worst_sight_trait(),
		"avg_range": get_avg_sight_range(),
		"coverage_pct": get_visibility_coverage_pct(),
		"range_spread": get_sight_range_spread(),
		"above_avg_traits": get_above_average_trait_count(),
		"has_blind": get_blind_trait_exists(),
		"awareness_level": get_awareness_level(),
		"scouting_quality": get_scouting_quality(),
		"vulnerability_pct": get_vulnerability_pct(),
		"situational_awareness": get_situational_awareness(),
		"intel_reliability": get_intel_reliability(),
		"blind_spot_risk": get_blind_spot_risk(),
		"reconnaissance_ecosystem_health": get_reconnaissance_ecosystem_health(),
		"intelligence_governance": get_intelligence_governance(),
		"perceptual_maturity_index": get_perceptual_maturity_index(),
	}

func get_situational_awareness() -> String:
	var awareness := get_awareness_level()
	var coverage := get_visibility_coverage_pct()
	if awareness in ["Alert", "Vigilant"] and coverage >= 60.0:
		return "Comprehensive"
	elif coverage >= 30.0:
		return "Partial"
	return "Blind"

func get_intel_reliability() -> float:
	var quality := get_scouting_quality()
	match quality:
		"Excellent":
			return 95.0
		"Good":
			return 75.0
		"Average":
			return 50.0
		_:
			return 25.0

func get_blind_spot_risk() -> String:
	var vuln := get_vulnerability_pct()
	if vuln >= 60.0:
		return "Critical"
	elif vuln >= 30.0:
		return "Moderate"
	return "Low"

func get_reconnaissance_ecosystem_health() -> float:
	var reliability := get_intel_reliability()
	var awareness := get_situational_awareness()
	var a_val: float = 90.0 if awareness == "Comprehensive" else (60.0 if awareness == "Partial" else 30.0)
	var coverage := get_visibility_coverage_pct()
	return snapped((reliability + a_val + coverage) / 3.0, 0.1)

func get_intelligence_governance() -> String:
	var health := get_reconnaissance_ecosystem_health()
	var blind_risk := get_blind_spot_risk()
	if health >= 65.0 and blind_risk == "Low":
		return "Vigilant"
	elif health >= 35.0:
		return "Watchful"
	return "Blind"

func get_perceptual_maturity_index() -> float:
	var scouting := get_scouting_quality()
	var s_val: float = 90.0 if scouting == "Excellent" else (70.0 if scouting == "Good" else (50.0 if scouting == "Average" else 25.0))
	var vuln := get_vulnerability_pct()
	return snapped((s_val + maxf(100.0 - vuln, 0.0)) / 2.0, 0.1)
