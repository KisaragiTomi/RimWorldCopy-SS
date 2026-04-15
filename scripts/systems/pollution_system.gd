extends Node

var _polluted_tiles: Dictionary = {}

const POLLUTION_SOURCES: Dictionary = {
	"ToxicWaste": {"spread_rate": 0.05, "severity": 0.8, "radius": 8},
	"MechClusterDebris": {"spread_rate": 0.03, "severity": 0.6, "radius": 5},
	"ToxicFalloutResidue": {"spread_rate": 0.02, "severity": 0.4, "radius": 12},
	"IndustrialRunoff": {"spread_rate": 0.04, "severity": 0.5, "radius": 6},
	"NuclearFallout": {"spread_rate": 0.06, "severity": 1.0, "radius": 15}
}

const POLLUTION_EFFECTS: Dictionary = {
	"fertility_penalty": -0.5,
	"beauty_penalty": -3,
	"move_speed_penalty": -0.1,
	"toxic_buildup_rate": 0.01,
	"plant_death_chance": 0.1
}

func add_pollution(pos: Vector2i, source: String) -> Dictionary:
	if not POLLUTION_SOURCES.has(source):
		return {"error": "unknown_source"}
	_polluted_tiles[pos] = {"source": source, "severity": POLLUTION_SOURCES[source]["severity"]}
	return {"polluted": true, "pos": [pos.x, pos.y], "severity": POLLUTION_SOURCES[source]["severity"]}

func get_pollution_at(pos: Vector2i) -> float:
	return _polluted_tiles.get(pos, {}).get("severity", 0.0)

func clean_tile(pos: Vector2i, amount: float) -> Dictionary:
	if not _polluted_tiles.has(pos):
		return {"error": "not_polluted"}
	_polluted_tiles[pos]["severity"] -= amount
	if _polluted_tiles[pos]["severity"] <= 0:
		_polluted_tiles.erase(pos)
		return {"cleaned": true}
	return {"remaining": _polluted_tiles[pos]["severity"]}

func get_most_severe_source() -> String:
	var best: String = ""
	var best_s: float = 0.0
	for s: String in POLLUTION_SOURCES:
		var sv: float = float(POLLUTION_SOURCES[s].get("severity", 0.0))
		if sv > best_s:
			best_s = sv
			best = s
	return best


func get_average_severity() -> float:
	if _polluted_tiles.is_empty():
		return 0.0
	var total: float = 0.0
	for pos: Vector2i in _polluted_tiles:
		total += float(_polluted_tiles[pos].get("severity", 0.0))
	return total / float(_polluted_tiles.size())


func get_source_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pos: Vector2i in _polluted_tiles:
		var s: String = String(_polluted_tiles[pos].get("source", ""))
		dist[s] = int(dist.get(s, 0)) + 1
	return dist


func get_clean_tiles_needed() -> int:
	var count: int = 0
	for pos: Vector2i in _polluted_tiles:
		if float(_polluted_tiles[pos].get("severity", 0.0)) > 0.0:
			count += 1
	return count


func get_widest_spread_source() -> String:
	var best: String = ""
	var best_radius: int = 0
	for src: String in POLLUTION_SOURCES:
		var r: int = int(POLLUTION_SOURCES[src].get("radius", 0))
		if r > best_radius:
			best_radius = r
			best = src
	return best


func get_total_pollution_severity() -> float:
	var total: float = 0.0
	for pos: Vector2i in _polluted_tiles:
		total += float(_polluted_tiles[pos].get("severity", 0.0))
	return total


func get_avg_source_radius() -> float:
	if POLLUTION_SOURCES.is_empty():
		return 0.0
	var total: float = 0.0
	for s: String in POLLUTION_SOURCES:
		total += float(POLLUTION_SOURCES[s].get("radius", 0))
	return snappedf(total / float(POLLUTION_SOURCES.size()), 0.1)


func get_fastest_spreading_source() -> String:
	var best: String = ""
	var best_r: float = 0.0
	for s: String in POLLUTION_SOURCES:
		var r: float = float(POLLUTION_SOURCES[s].get("spread_rate", 0.0))
		if r > best_r:
			best_r = r
			best = s
	return best


func get_high_severity_tile_count() -> int:
	var count: int = 0
	for pos: Vector2i in _polluted_tiles:
		if float(_polluted_tiles[pos].get("severity", 0.0)) >= 0.7:
			count += 1
	return count


func get_environmental_risk() -> String:
	var high: int = get_high_severity_tile_count()
	var total: int = _polluted_tiles.size()
	if total == 0:
		return "Clean"
	var ratio: float = float(high) / float(total)
	if ratio >= 0.5:
		return "Critical"
	if ratio >= 0.2:
		return "Concerning"
	return "Manageable"


func get_cleanup_feasibility_pct() -> float:
	var to_clean: int = get_clean_tiles_needed()
	var total: int = _polluted_tiles.size()
	if total == 0:
		return 100.0
	var cleaned: int = total - to_clean
	return snappedf(float(cleaned) / float(total) * 100.0, 0.1)


func get_spread_velocity() -> String:
	var avg_radius: float = get_avg_source_radius()
	if avg_radius >= 8.0:
		return "Rapid"
	if avg_radius >= 4.0:
		return "Moderate"
	return "Contained"


func get_summary() -> Dictionary:
	return {
		"pollution_sources": POLLUTION_SOURCES.size(),
		"effect_types": POLLUTION_EFFECTS.size(),
		"polluted_tiles": _polluted_tiles.size(),
		"avg_severity": get_average_severity(),
		"most_severe": get_most_severe_source(),
		"tiles_to_clean": get_clean_tiles_needed(),
		"widest_spread": get_widest_spread_source(),
		"total_severity": snapped(get_total_pollution_severity(), 0.1),
		"avg_source_radius": get_avg_source_radius(),
		"fastest_spreading": get_fastest_spreading_source(),
		"high_severity_tiles": get_high_severity_tile_count(),
		"environmental_risk": get_environmental_risk(),
		"cleanup_feasibility_pct": get_cleanup_feasibility_pct(),
		"spread_velocity": get_spread_velocity(),
		"contamination_containment": get_contamination_containment(),
		"ecosystem_health_index": get_ecosystem_health_index(),
		"remediation_urgency": get_remediation_urgency(),
		"pollution_ecosystem_health": get_pollution_ecosystem_health(),
		"environmental_governance": get_environmental_governance(),
		"remediation_maturity_index": get_remediation_maturity_index(),
	}

func get_contamination_containment() -> String:
	var velocity := get_spread_velocity()
	var feasibility := get_cleanup_feasibility_pct()
	if velocity in ["Slow", "Static"] and feasibility >= 70.0:
		return "Contained"
	elif feasibility >= 40.0:
		return "Partially Contained"
	return "Spreading"

func get_ecosystem_health_index() -> float:
	var severity := get_total_pollution_severity()
	var tiles := _polluted_tiles.size()
	if tiles <= 0:
		return 100.0
	return snapped(maxf(0.0, 100.0 - severity / float(tiles) * 10.0), 0.1)

func get_remediation_urgency() -> String:
	var high := get_high_severity_tile_count()
	var total := _polluted_tiles.size()
	if total <= 0:
		return "None"
	var ratio := float(high) / float(total)
	if ratio >= 0.5:
		return "Critical"
	elif ratio >= 0.2:
		return "Elevated"
	return "Routine"

func get_pollution_ecosystem_health() -> float:
	var containment := get_contamination_containment()
	var c_val: float = 90.0 if containment == "Contained" else (60.0 if containment == "Partial" else 20.0)
	var eco_index := get_ecosystem_health_index()
	var feasibility := get_cleanup_feasibility_pct()
	return snapped((c_val + eco_index + feasibility) / 3.0, 0.1)

func get_environmental_governance() -> String:
	var ecosystem := get_pollution_ecosystem_health()
	var urgency := get_remediation_urgency()
	var u_val: float = 90.0 if urgency in ["None", "Routine"] else (50.0 if urgency == "Elevated" else 15.0)
	var combined := (ecosystem + u_val) / 2.0
	if combined >= 70.0:
		return "Pristine"
	elif combined >= 40.0:
		return "Managed"
	elif _polluted_tiles.size() > 0:
		return "Degraded"
	return "Clean"

func get_remediation_maturity_index() -> float:
	var risk := get_environmental_risk()
	var r_val: float = 90.0 if risk == "Low" else (60.0 if risk == "Moderate" else 20.0)
	var velocity := get_spread_velocity()
	var v_val: float = 90.0 if velocity in ["Static", "Slow"] else (50.0 if velocity == "Moderate" else 15.0)
	return snapped((r_val + v_val) / 2.0, 0.1)
