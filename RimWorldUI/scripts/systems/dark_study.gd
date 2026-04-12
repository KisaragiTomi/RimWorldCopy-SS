extends Node

var _study_progress: Dictionary = {}

const STUDY_BENCHES: Dictionary = {
	"AnomalyResearchBench": {"speed": 1.0, "power": 200, "skill_req": 6},
	"AdvancedAnomalyBench": {"speed": 1.5, "power": 400, "skill_req": 10}
}

const KNOWLEDGE_TYPES: Dictionary = {
	"VoidProvocation": {"points_needed": 100, "danger_level": 1},
	"EntityBehavior": {"points_needed": 150, "danger_level": 2},
	"FleshShaping": {"points_needed": 200, "danger_level": 3},
	"DarkPsychics": {"points_needed": 250, "danger_level": 4},
	"BioferriteWeapons": {"points_needed": 120, "danger_level": 2},
	"ContainmentProtocol": {"points_needed": 80, "danger_level": 1},
	"RevenantAnatomy": {"points_needed": 180, "danger_level": 3},
	"PitGateSealing": {"points_needed": 300, "danger_level": 5}
}

func study_entity(entity_type: String, bench: String, skill_level: int) -> Dictionary:
	if not STUDY_BENCHES.has(bench):
		return {"error": "unknown_bench"}
	var bench_info: Dictionary = STUDY_BENCHES[bench]
	if skill_level < bench_info["skill_req"]:
		return {"error": "skill_too_low"}
	var points: float = bench_info["speed"] * (1.0 + skill_level * 0.05)
	if not _study_progress.has(entity_type):
		_study_progress[entity_type] = 0.0
	_study_progress[entity_type] += points
	return {"entity": entity_type, "points_gained": points, "total": _study_progress[entity_type]}

func is_knowledge_unlocked(knowledge: String) -> bool:
	if not KNOWLEDGE_TYPES.has(knowledge):
		return false
	var needed: float = KNOWLEDGE_TYPES[knowledge]["points_needed"]
	var total: float = 0.0
	for entity: String in _study_progress:
		total += _study_progress[entity]
	return total >= needed

func get_unlocked_knowledge() -> Array[String]:
	var result: Array[String] = []
	for k: String in KNOWLEDGE_TYPES:
		if is_knowledge_unlocked(k):
			result.append(k)
	return result


func get_most_dangerous_knowledge() -> String:
	var best: String = ""
	var best_d: int = 0
	for k: String in KNOWLEDGE_TYPES:
		var d: int = int(KNOWLEDGE_TYPES[k].get("danger_level", 0))
		if d > best_d:
			best_d = d
			best = k
	return best


func get_total_study_points() -> float:
	var total: float = 0.0
	for entity: String in _study_progress:
		total += float(_study_progress[entity])
	return total


func get_avg_danger_level() -> float:
	if KNOWLEDGE_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for k: String in KNOWLEDGE_TYPES:
		total += float(KNOWLEDGE_TYPES[k].get("danger_level", 0))
	return total / KNOWLEDGE_TYPES.size()


func get_locked_knowledge_count() -> int:
	return KNOWLEDGE_TYPES.size() - get_unlocked_knowledge().size()


func get_highest_danger_knowledge() -> String:
	var worst: String = ""
	var worst_danger: int = 0
	for k: String in KNOWLEDGE_TYPES:
		var d: int = int(KNOWLEDGE_TYPES[k].get("danger_level", 0))
		if d > worst_danger:
			worst_danger = d
			worst = k
	return worst


func get_total_points_needed() -> float:
	var total: float = 0.0
	for k: String in KNOWLEDGE_TYPES:
		total += float(KNOWLEDGE_TYPES[k].get("points_needed", 0))
	return total


func get_safest_knowledge() -> String:
	var best: String = ""
	var best_d: int = 999
	for k: String in KNOWLEDGE_TYPES:
		var d: int = int(KNOWLEDGE_TYPES[k].get("danger_level", 999))
		if d < best_d:
			best_d = d
			best = k
	return best


func get_bench_speed_spread() -> float:
	var lo: float = 999.0
	var hi: float = 0.0
	for b: String in STUDY_BENCHES:
		var s: float = float(STUDY_BENCHES[b].get("speed", 0.0))
		if s < lo:
			lo = s
		if s > hi:
			hi = s
	if lo > hi:
		return 0.0
	return hi - lo


func get_research_momentum() -> String:
	var total: float = get_total_study_points()
	var needed: float = get_total_points_needed()
	if needed <= 0.0:
		return "idle"
	var ratio: float = total / needed
	if ratio >= 0.8:
		return "near_breakthrough"
	if ratio >= 0.4:
		return "steady"
	return "early_phase"

func get_danger_exposure_pct() -> float:
	var high_danger: int = 0
	for k: String in KNOWLEDGE_TYPES:
		if KNOWLEDGE_TYPES[k]["danger_level"] >= 3 and is_knowledge_unlocked(k):
			high_danger += 1
	var unlocked: int = get_unlocked_knowledge().size()
	if unlocked == 0:
		return 0.0
	return snapped(high_danger * 100.0 / unlocked, 0.1)

func get_study_efficiency() -> String:
	var total: float = get_total_study_points()
	var entities: int = _study_progress.size()
	if entities == 0:
		return "no_data"
	var per_entity: float = total / entities
	if per_entity >= 100.0:
		return "highly_focused"
	if per_entity >= 40.0:
		return "balanced"
	return "scattered"

func get_summary() -> Dictionary:
	return {
		"bench_types": STUDY_BENCHES.size(),
		"knowledge_types": KNOWLEDGE_TYPES.size(),
		"entities_studied": _study_progress.size(),
		"unlocked": get_unlocked_knowledge().size(),
		"total_points": get_total_study_points(),
		"avg_danger": snapped(get_avg_danger_level(), 0.1),
		"locked": get_locked_knowledge_count(),
		"most_dangerous": get_highest_danger_knowledge(),
		"total_points_needed": get_total_points_needed(),
		"safest_knowledge": get_safest_knowledge(),
		"bench_speed_spread": snapped(get_bench_speed_spread(), 0.01),
		"research_momentum": get_research_momentum(),
		"danger_exposure_pct": get_danger_exposure_pct(),
		"study_efficiency": get_study_efficiency(),
		"forbidden_knowledge_depth": get_forbidden_knowledge_depth(),
		"researcher_risk_profile": get_researcher_risk_profile(),
		"discovery_pace": get_discovery_pace(),
		"dark_knowledge_ecosystem_health": get_dark_knowledge_ecosystem_health(),
		"occult_governance": get_occult_governance(),
		"eldritch_study_maturity_index": get_eldritch_study_maturity_index(),
	}

func get_forbidden_knowledge_depth() -> float:
	var unlocked := get_unlocked_knowledge().size()
	var total := KNOWLEDGE_TYPES.size()
	if total <= 0:
		return 0.0
	return snapped(float(unlocked) / float(total) * 100.0, 0.1)

func get_researcher_risk_profile() -> String:
	var danger := get_danger_exposure_pct()
	if danger >= 60.0:
		return "Reckless"
	elif danger >= 30.0:
		return "Calculated"
	return "Cautious"

func get_discovery_pace() -> String:
	var momentum := get_research_momentum()
	var efficiency := get_study_efficiency()
	if momentum in ["Accelerating", "Rapid"] and efficiency in ["High", "Optimal"]:
		return "Breakthrough"
	elif momentum in ["Steady", "Accelerating"]:
		return "Progressing"
	return "Stalled"

func get_dark_knowledge_ecosystem_health() -> float:
	var depth := get_forbidden_knowledge_depth()
	var d_val: float = 90.0 if depth in ["Abyssal", "Deep"] else (60.0 if depth in ["Moderate", "Shallow"] else 30.0)
	var profile := get_researcher_risk_profile()
	var p_val: float = 90.0 if profile == "Cautious" else (60.0 if profile == "Calculated" else 30.0)
	var pace := get_discovery_pace()
	var pc_val: float = 90.0 if pace == "Breakthrough" else (60.0 if pace == "Progressing" else 30.0)
	return snapped((d_val + p_val + pc_val) / 3.0, 0.1)

func get_eldritch_study_maturity_index() -> float:
	var momentum := get_research_momentum()
	var m_val: float = 90.0 if momentum in ["Accelerating", "Rapid"] else (60.0 if momentum in ["Steady", "Building"] else 30.0)
	var danger := get_danger_exposure_pct()
	var d_val: float = maxf(100.0 - danger, 0.0)
	var efficiency := get_study_efficiency()
	var e_val: float = 90.0 if efficiency in ["High", "Optimal"] else (60.0 if efficiency in ["Moderate", "Adequate"] else 30.0)
	return snapped((m_val + d_val + e_val) / 3.0, 0.1)

func get_occult_governance() -> String:
	var ecosystem := get_dark_knowledge_ecosystem_health()
	var maturity := get_eldritch_study_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _study_progress.size() > 0:
		return "Nascent"
	return "Dormant"
