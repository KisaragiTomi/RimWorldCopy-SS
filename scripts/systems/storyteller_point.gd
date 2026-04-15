extends Node

const BASE_POINTS: float = 35.0
const WEALTH_FACTOR: float = 0.001
const COLONIST_FACTOR: float = 15.0
const DAY_FACTOR: float = 0.5

const POINT_BUDGET_TYPES: Dictionary = {
	"Raid": {"min_pct": 0.3, "max_pct": 1.0, "priority": 1},
	"MechCluster": {"min_pct": 0.5, "max_pct": 1.0, "priority": 2},
	"Infestation": {"min_pct": 0.2, "max_pct": 0.6, "priority": 3},
	"ManhunterPack": {"min_pct": 0.15, "max_pct": 0.5, "priority": 4},
	"SiegeEvent": {"min_pct": 0.6, "max_pct": 1.0, "priority": 2},
	"PsychicShip": {"min_pct": 0.4, "max_pct": 0.8, "priority": 3}
}

const DIFFICULTY_MULT: Dictionary = {
	"Peaceful": 0.0,
	"Community": 0.5,
	"Adventure": 0.8,
	"Strive": 1.0,
	"Merciless": 1.3,
	"Deathwill": 1.8
}

func calc_threat_points(colony_wealth: float, colonist_count: int, day: int, difficulty: String) -> float:
	var base: float = BASE_POINTS + colony_wealth * WEALTH_FACTOR + colonist_count * COLONIST_FACTOR + day * DAY_FACTOR
	var diff_mult: float = DIFFICULTY_MULT.get(difficulty, 1.0)
	return base * diff_mult

func allocate_points(total_points: float, event_type: String) -> Dictionary:
	if not POINT_BUDGET_TYPES.has(event_type):
		return {"error": "unknown_event"}
	var info: Dictionary = POINT_BUDGET_TYPES[event_type]
	var allocated: float = clampf(total_points, total_points * info["min_pct"], total_points * info["max_pct"])
	return {"event": event_type, "allocated": allocated, "total": total_points}

func get_hardest_difficulty() -> String:
	var best: String = ""
	var best_m: float = 0.0
	for d: String in DIFFICULTY_MULT:
		if float(DIFFICULTY_MULT[d]) > best_m:
			best_m = float(DIFFICULTY_MULT[d])
			best = d
	return best


func get_highest_priority_event() -> String:
	var best: String = ""
	var best_p: int = 999
	for e: String in POINT_BUDGET_TYPES:
		var p: int = int(POINT_BUDGET_TYPES[e].get("priority", 999))
		if p < best_p:
			best_p = p
			best = e
	return best


func get_max_budget_events() -> Array[String]:
	var result: Array[String] = []
	for e: String in POINT_BUDGET_TYPES:
		if float(POINT_BUDGET_TYPES[e].get("max_pct", 0.0)) >= 1.0:
			result.append(e)
	return result


func get_avg_budget_range() -> float:
	if POINT_BUDGET_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for evt: String in POINT_BUDGET_TYPES:
		var info: Dictionary = POINT_BUDGET_TYPES[evt]
		total += float(info.get("max_pct", 0.0)) - float(info.get("min_pct", 0.0))
	return total / POINT_BUDGET_TYPES.size()


func get_easiest_difficulty() -> String:
	var best: String = ""
	var best_mult: float = 999.0
	for d: String in DIFFICULTY_MULT:
		var m: float = float(DIFFICULTY_MULT[d])
		if m < best_mult:
			best_mult = m
			best = d
	return best


func get_full_budget_events() -> int:
	var count: int = 0
	for evt: String in POINT_BUDGET_TYPES:
		if float(POINT_BUDGET_TYPES[evt].get("max_pct", 0.0)) >= 1.0:
			count += 1
	return count


func get_difficulty_spread() -> float:
	var lo: float = 999.0
	var hi: float = 0.0
	for d: String in DIFFICULTY_MULT:
		var m: float = float(DIFFICULTY_MULT[d])
		if m < lo:
			lo = m
		if m > hi:
			hi = m
	return snappedf(hi - lo, 0.01)


func get_low_budget_event_count() -> int:
	var count: int = 0
	for evt: String in POINT_BUDGET_TYPES:
		if float(POINT_BUDGET_TYPES[evt].get("min_pct", 0.0)) <= 0.2:
			count += 1
	return count


func get_avg_priority() -> float:
	if POINT_BUDGET_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for evt: String in POINT_BUDGET_TYPES:
		total += float(POINT_BUDGET_TYPES[evt].get("priority", 0))
	return snappedf(total / float(POINT_BUDGET_TYPES.size()), 0.1)


func get_escalation_pressure() -> String:
	var spread: float = get_difficulty_spread()
	var full: int = get_full_budget_events()
	if spread >= 2.0 and full >= 3:
		return "Heavy"
	if spread >= 1.0:
		return "Moderate"
	return "Light"


func get_budget_saturation_pct() -> float:
	var full: int = get_full_budget_events()
	return snappedf(float(full) / maxf(float(POINT_BUDGET_TYPES.size()), 1.0) * 100.0, 0.1)


func get_threat_variety() -> String:
	var low: int = get_low_budget_event_count()
	var full: int = get_full_budget_events()
	var total: int = POINT_BUDGET_TYPES.size()
	var mid: int = total - low - full
	if low > 0 and mid > 0 and full > 0:
		return "Diverse"
	if full > low:
		return "TopHeavy"
	return "Mild"


func get_summary() -> Dictionary:
	return {
		"event_budgets": POINT_BUDGET_TYPES.size(),
		"difficulty_levels": DIFFICULTY_MULT.size(),
		"hardest": get_hardest_difficulty(),
		"highest_priority": get_highest_priority_event(),
		"avg_budget_range": snapped(get_avg_budget_range(), 0.01),
		"easiest": get_easiest_difficulty(),
		"full_budget_events": get_full_budget_events(),
		"difficulty_spread": get_difficulty_spread(),
		"low_budget_events": get_low_budget_event_count(),
		"avg_priority": get_avg_priority(),
		"escalation_pressure": get_escalation_pressure(),
		"budget_saturation_pct": get_budget_saturation_pct(),
		"threat_variety": get_threat_variety(),
		"narrative_ecosystem_health": get_narrative_ecosystem_health(),
		"threat_governance": get_threat_governance(),
		"difficulty_maturity_index": get_difficulty_maturity_index(),
	}

func get_narrative_ecosystem_health() -> float:
	var pressure := get_escalation_pressure()
	var p_val: float = 90.0 if pressure == "Extreme" else (60.0 if pressure == "Heavy" else 30.0)
	var saturation := get_budget_saturation_pct()
	var variety := get_threat_variety()
	var v_val: float = 90.0 if variety == "Diverse" else (60.0 if variety == "Moderate" else 30.0)
	return snapped((p_val + saturation + v_val) / 3.0, 0.1)

func get_threat_governance() -> String:
	var ecosystem := get_narrative_ecosystem_health()
	var pressure := get_escalation_pressure()
	var pr_val: float = 90.0 if pressure == "Extreme" else (60.0 if pressure == "Heavy" else 30.0)
	var combined := (ecosystem + pr_val) / 2.0
	if combined >= 70.0:
		return "Overwhelming"
	elif combined >= 40.0:
		return "Challenging"
	elif POINT_BUDGET_TYPES.size() > 0:
		return "Manageable"
	return "Peaceful"

func get_difficulty_maturity_index() -> float:
	var saturation := get_budget_saturation_pct()
	var spread := get_difficulty_spread()
	return snapped((saturation + minf(spread * 20.0, 100.0)) / 2.0, 0.1)
