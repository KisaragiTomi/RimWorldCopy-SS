extends Node

var _raid_log: Array = []

const STRATEGIES: Dictionary = {
	"FrontAssault": {"weight": 0.30, "description": "Direct attack", "approach": "edge", "breach": false},
	"Siege": {"weight": 0.10, "description": "Build and bombard", "approach": "edge", "breach": false, "mortar": true},
	"Sappers": {"weight": 0.15, "description": "Mine through walls", "approach": "weakpoint", "breach": true},
	"DropPod": {"weight": 0.08, "description": "Drop in center", "approach": "center", "breach": false, "min_tech": "Industrial"},
	"SapperWithMortars": {"weight": 0.05, "description": "Sapper + mortar cover", "approach": "weakpoint", "breach": true, "mortar": true},
	"ZergRush": {"weight": 0.12, "description": "Many weak enemies", "approach": "edge", "breach": false, "count_mult": 2.0},
	"MechCluster": {"weight": 0.05, "description": "Mechanoid cluster drop", "approach": "random", "breach": false, "mech_only": true},
	"SneakAttack": {"weight": 0.08, "description": "Night attack", "approach": "edge", "breach": false, "night_only": true},
	"TribalWave": {"weight": 0.07, "description": "Tribal mass attack", "approach": "edge", "breach": false, "count_mult": 3.0, "max_tech": "Neolithic"}
}

func select_strategy(colony_wealth: float, colony_tech: String) -> Dictionary:
	var valid: Dictionary = {}
	var total_weight: float = 0.0
	for name: String in STRATEGIES:
		var strat: Dictionary = STRATEGIES[name]
		if strat.has("min_tech") and colony_tech == "Neolithic":
			continue
		valid[name] = strat["weight"]
		total_weight += strat["weight"]
	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for name: String in valid:
		cumulative += valid[name]
		if roll <= cumulative:
			var result: Dictionary = STRATEGIES[name].duplicate()
			result["name"] = name
			_raid_log.append(result)
			return result
	return STRATEGIES["FrontAssault"]

func get_breach_strategies() -> Array[String]:
	var result: Array[String] = []
	for s: String in STRATEGIES:
		if bool(STRATEGIES[s].get("breach", false)):
			result.append(s)
	return result


func get_most_used_strategy() -> String:
	var counts: Dictionary = {}
	for entry: Dictionary in _raid_log:
		var n: String = String(entry.get("name", ""))
		counts[n] = int(counts.get(n, 0)) + 1
	var best: String = ""
	var best_c: int = 0
	for n: String in counts:
		if int(counts[n]) > best_c:
			best_c = int(counts[n])
			best = n
	return best


func get_mortar_strategies() -> Array[String]:
	var result: Array[String] = []
	for s: String in STRATEGIES:
		if bool(STRATEGIES[s].get("mortar", false)):
			result.append(s)
	return result


func get_avg_weight() -> float:
	var total: float = 0.0
	for s: String in STRATEGIES:
		total += float(STRATEGIES[s].get("weight", 0.0))
	return total / maxf(STRATEGIES.size(), 1)


func get_unique_strategies_used() -> int:
	var types: Dictionary = {}
	for entry: Dictionary in _raid_log:
		types[String(entry.get("name", ""))] = true
	return types.size()


func get_night_strategy_count() -> int:
	var count: int = 0
	for s: String in STRATEGIES:
		if bool(STRATEGIES[s].get("night_only", false)):
			count += 1
	return count


func get_mortar_strategy_count() -> int:
	return get_mortar_strategies().size()


func get_edge_approach_count() -> int:
	var count: int = 0
	for s: String in STRATEGIES:
		if String(STRATEGIES[s].get("approach", "")) == "edge":
			count += 1
	return count


func get_weight_range() -> Dictionary:
	var lo: float = 999.0
	var hi: float = 0.0
	for s: String in STRATEGIES:
		var w: float = float(STRATEGIES[s].get("weight", 0.0))
		if w < lo:
			lo = w
		if w > hi:
			hi = w
	return {"min": snapped(lo, 0.01), "max": snapped(hi, 0.01)}


func get_threat_sophistication() -> String:
	var unique: int = get_unique_strategies_used()
	if unique >= 6:
		return "Masterful"
	elif unique >= 4:
		return "Tactical"
	elif unique >= 2:
		return "Basic"
	return "Predictable"

func get_siege_pressure() -> String:
	var mortar: int = get_mortar_strategy_count()
	var breach: int = get_breach_strategies().size()
	if mortar + breach >= 4:
		return "Overwhelming"
	elif mortar + breach >= 2:
		return "Heavy"
	elif mortar + breach >= 1:
		return "Moderate"
	return "Light"

func get_tactical_diversity_pct() -> float:
	if STRATEGIES.is_empty():
		return 0.0
	return snappedf(float(get_unique_strategies_used()) / float(STRATEGIES.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"strategy_types": STRATEGIES.size(),
		"raids_logged": _raid_log.size(),
		"breach_count": get_breach_strategies().size(),
		"most_used": get_most_used_strategy(),
		"avg_weight": snapped(get_avg_weight(), 0.01),
		"unique_used": get_unique_strategies_used(),
		"night_strategies": get_night_strategy_count(),
		"mortar_strategies": get_mortar_strategy_count(),
		"edge_approaches": get_edge_approach_count(),
		"weight_range": get_weight_range(),
		"threat_sophistication": get_threat_sophistication(),
		"siege_pressure": get_siege_pressure(),
		"tactical_diversity_pct": get_tactical_diversity_pct(),
		"defense_challenge_tier": get_defense_challenge_tier(),
		"raid_escalation_rate": get_raid_escalation_rate(),
		"strategic_unpredictability": get_strategic_unpredictability(),
		"threat_ecosystem_health": get_threat_ecosystem_health(),
		"defense_governance": get_defense_governance(),
		"military_readiness_index": get_military_readiness_index(),
	}

func get_defense_challenge_tier() -> String:
	var sophistication := get_threat_sophistication()
	var mortar := get_mortar_strategy_count()
	if sophistication in ["Advanced", "Elite"] and mortar >= 2:
		return "Extreme"
	elif sophistication in ["Moderate", "Advanced"]:
		return "Hard"
	return "Normal"

func get_raid_escalation_rate() -> float:
	var logs := _raid_log.size()
	var unique := get_unique_strategies_used()
	if logs <= 0:
		return 0.0
	return snapped(float(unique) / float(logs) * 100.0, 0.1)

func get_strategic_unpredictability() -> String:
	var diversity := get_tactical_diversity_pct()
	if diversity >= 70.0:
		return "Chaotic"
	elif diversity >= 40.0:
		return "Variable"
	return "Predictable"

func get_threat_ecosystem_health() -> float:
	var sophistication := get_threat_sophistication()
	var s_val: float = 90.0 if sophistication in ["Advanced", "Elite"] else (60.0 if sophistication == "Moderate" else 30.0)
	var pressure := get_siege_pressure()
	var p_val: float = 90.0 if pressure == "Extreme" else (60.0 if pressure == "Heavy" else 30.0)
	var escalation := get_raid_escalation_rate()
	return snapped((s_val + p_val + escalation) / 3.0, 0.1)

func get_defense_governance() -> String:
	var ecosystem := get_threat_ecosystem_health()
	var challenge := get_defense_challenge_tier()
	var c_val: float = 90.0 if challenge == "Extreme" else (60.0 if challenge == "Hard" else 30.0)
	var combined := (ecosystem + c_val) / 2.0
	if combined >= 70.0:
		return "Fortified"
	elif combined >= 40.0:
		return "Defended"
	elif _raid_log.size() > 0:
		return "Exposed"
	return "Peaceful"

func get_military_readiness_index() -> float:
	var diversity := get_tactical_diversity_pct()
	var unpredictability := get_strategic_unpredictability()
	var u_val: float = 90.0 if unpredictability == "Chaotic" else (60.0 if unpredictability == "Variable" else 30.0)
	return snapped((diversity + u_val) / 2.0, 0.1)
