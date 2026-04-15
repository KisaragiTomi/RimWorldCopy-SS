extends Node

var _victory_progress: Dictionary = {}

const VICTORY_CONDITIONS: Dictionary = {
	"ShipLaunch": {"desc": "Build and launch the ship", "requirements": ["ShipReactor", "ShipEngine", "ShipComputer", "ShipSensor", "ShipCryptosleep"], "survive_days": 15},
	"RoyalAscent": {"desc": "Reach Stellarch title and call shuttle", "requirements": ["Stellarch_title", "Empire_allied"], "survive_days": 0},
	"ArchonexusMap1": {"desc": "Sell colony to find first archonexus piece", "requirements": ["Colony_wealth_350000"], "survive_days": 0},
	"ArchonexusMap2": {"desc": "Find second archonexus piece", "requirements": ["Archonexus_piece_1"], "survive_days": 0},
	"ArchonexusMap3": {"desc": "Complete the archonexus", "requirements": ["Archonexus_piece_2"], "survive_days": 0},
	"DefeatAnomalyBoss": {"desc": "Seal the pit gate", "requirements": ["PitGateSealing_research", "Bioferrite_50"], "survive_days": 0}
}

func check_requirement(victory: String, requirement: String) -> Dictionary:
	if not VICTORY_CONDITIONS.has(victory):
		return {"error": "unknown_victory"}
	if not _victory_progress.has(victory):
		_victory_progress[victory] = {}
	_victory_progress[victory][requirement] = true
	var reqs: Array = VICTORY_CONDITIONS[victory]["requirements"]
	var met: int = 0
	for r: String in reqs:
		if _victory_progress[victory].get(r, false):
			met += 1
	return {"requirement": requirement, "met": met, "total": reqs.size(), "complete": met >= reqs.size()}

func get_victory_status(victory: String) -> Dictionary:
	if not VICTORY_CONDITIONS.has(victory):
		return {"error": "unknown_victory"}
	var reqs: Array = VICTORY_CONDITIONS[victory]["requirements"]
	var met: int = 0
	for r: String in reqs:
		if _victory_progress.get(victory, {}).get(r, false):
			met += 1
	return {"victory": victory, "met": met, "total": reqs.size(), "complete": met >= reqs.size()}

func get_closest_to_completion() -> String:
	var best: String = ""
	var best_pct: float = -1.0
	for v: String in VICTORY_CONDITIONS:
		var reqs: Array = VICTORY_CONDITIONS[v]["requirements"]
		var met: int = 0
		for r: String in reqs:
			if _victory_progress.get(v, {}).get(r, false):
				met += 1
		var pct: float = float(met) / maxf(1.0, float(reqs.size()))
		if pct > best_pct:
			best_pct = pct
			best = v
	return best

func get_easiest_victory() -> String:
	var best: String = ""
	var min_reqs: int = 999
	for v: String in VICTORY_CONDITIONS:
		var cnt: int = VICTORY_CONDITIONS[v]["requirements"].size()
		if cnt < min_reqs:
			min_reqs = cnt
			best = v
	return best

func get_all_statuses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for v: String in VICTORY_CONDITIONS:
		result.append(get_victory_status(v))
	return result

func get_total_requirements() -> int:
	var total: int = 0
	for v: String in VICTORY_CONDITIONS:
		total += VICTORY_CONDITIONS[v].get("requirements", []).size()
	return total


func get_most_complex_victory() -> String:
	var best: String = ""
	var best_reqs: int = 0
	for v: String in VICTORY_CONDITIONS:
		var r: int = VICTORY_CONDITIONS[v].get("requirements", []).size()
		if r > best_reqs:
			best_reqs = r
			best = v
	return best


func get_survival_victories_count() -> int:
	var count: int = 0
	for v: String in VICTORY_CONDITIONS:
		if int(VICTORY_CONDITIONS[v].get("survive_days", 0)) > 0:
			count += 1
	return count


func get_total_survive_days() -> int:
	var total: int = 0
	for v: String in VICTORY_CONDITIONS:
		total += int(VICTORY_CONDITIONS[v].get("survive_days", 0))
	return total


func get_no_survive_victory_count() -> int:
	var count: int = 0
	for v: String in VICTORY_CONDITIONS:
		if int(VICTORY_CONDITIONS[v].get("survive_days", 0)) == 0:
			count += 1
	return count


func get_avg_requirements() -> float:
	if VICTORY_CONDITIONS.is_empty():
		return 0.0
	var total: int = 0
	for v: String in VICTORY_CONDITIONS:
		total += VICTORY_CONDITIONS[v].get("requirements", []).size()
	return float(total) / VICTORY_CONDITIONS.size()


func get_summary() -> Dictionary:
	var closest: String = get_closest_to_completion()
	var easiest: String = get_easiest_victory()
	return {
		"victory_types": VICTORY_CONDITIONS.size(),
		"tracked_victories": _victory_progress.size(),
		"closest_to_completion": closest,
		"easiest_victory": easiest,
		"total_reqs": get_total_requirements(),
		"most_complex": get_most_complex_victory(),
		"survival_victories": get_survival_victories_count(),
		"total_survive_days": get_total_survive_days(),
		"instant_victories": get_no_survive_victory_count(),
		"avg_requirements": snapped(get_avg_requirements(), 0.01),
		"completion_depth": get_completion_depth(),
		"category_balance_pct": get_category_balance_pct(),
		"expansion_readiness": get_expansion_readiness(),
		"endgame_ecosystem_health": get_endgame_ecosystem_health(),
		"victory_governance": get_victory_governance(),
		"campaign_maturity_index": get_campaign_maturity_index(),
	}

func get_completion_depth() -> String:
	var tracked := _victory_progress.size()
	var total := VICTORY_CONDITIONS.size()
	if total <= 0:
		return "None"
	var ratio := float(tracked) / float(total)
	if ratio >= 0.8:
		return "Deep"
	elif ratio >= 0.4:
		return "Moderate"
	return "Shallow"

func get_category_balance_pct() -> float:
	var survival := get_survival_victories_count()
	var instant := get_no_survive_victory_count()
	var total := survival + instant
	if total <= 0:
		return 0.0
	return snapped(minf(float(survival), float(instant)) / float(total) * 200.0, 0.1)

func get_expansion_readiness() -> String:
	var closest := get_closest_to_completion()
	if closest != "":
		return "Near Victory"
	var tracked := _victory_progress.size()
	if tracked > 0:
		return "In Progress"
	return "Not Started"

func get_endgame_ecosystem_health() -> float:
	var depth := get_completion_depth()
	var d_val: float = 90.0 if depth in ["Complete", "Advanced"] else (60.0 if depth in ["Moderate", "Partial"] else 30.0)
	var balance := get_category_balance_pct()
	var readiness := get_expansion_readiness()
	var r_val: float = 90.0 if readiness == "Near Victory" else (60.0 if readiness == "In Progress" else 30.0)
	return snapped((d_val + balance + r_val) / 3.0, 0.1)

func get_campaign_maturity_index() -> float:
	var avg_reqs := get_avg_requirements()
	var complexity := float(get_total_requirements())
	var c_val: float = minf(complexity * 5.0, 100.0)
	var tracked := _victory_progress.size()
	var t_val: float = minf(float(tracked) * 25.0, 100.0)
	return snapped((avg_reqs * 10.0 + c_val + t_val) / 3.0, 0.1)

func get_victory_governance() -> String:
	var ecosystem := get_endgame_ecosystem_health()
	var maturity := get_campaign_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _victory_progress.size() > 0:
		return "Nascent"
	return "Dormant"
