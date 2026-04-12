extends Node

const TECH_LEVELS: Dictionary = {
	"Animal": {"level": 0, "research_speed_mult": 0.0, "label": "Animal"},
	"Neolithic": {"level": 1, "research_speed_mult": 0.5, "label": "Neolithic"},
	"Medieval": {"level": 2, "research_speed_mult": 0.7, "label": "Medieval"},
	"Industrial": {"level": 3, "research_speed_mult": 1.0, "label": "Industrial"},
	"Spacer": {"level": 4, "research_speed_mult": 1.3, "label": "Spacer"},
	"Ultra": {"level": 5, "research_speed_mult": 1.5, "label": "Ultra"},
	"Archotech": {"level": 6, "research_speed_mult": 2.0, "label": "Archotech"}
}

const RESEARCH_COST_MULT: Dictionary = {
	"same_level": 1.0,
	"one_above": 1.5,
	"two_above": 2.5,
	"three_above": 4.0
}

const FACTION_TECH_DEFAULTS: Dictionary = {
	"Colony": "Industrial",
	"Tribal": "Neolithic",
	"Outlander": "Industrial",
	"Empire": "Spacer",
	"Mechanoid": "Ultra",
	"Pirate": "Industrial",
	"Insectoid": "Animal",
	"Ancients": "Archotech"
}

func get_research_cost(faction_tech: String, target_tech: String, base_cost: float) -> float:
	if not TECH_LEVELS.has(faction_tech) or not TECH_LEVELS.has(target_tech):
		return base_cost
	var diff: int = TECH_LEVELS[target_tech]["level"] - TECH_LEVELS[faction_tech]["level"]
	if diff <= 0:
		return base_cost * RESEARCH_COST_MULT["same_level"]
	elif diff == 1:
		return base_cost * RESEARCH_COST_MULT["one_above"]
	elif diff == 2:
		return base_cost * RESEARCH_COST_MULT["two_above"]
	else:
		return base_cost * RESEARCH_COST_MULT["three_above"]

func get_highest_tech_faction() -> String:
	var best: String = ""
	var best_lvl: int = -1
	for f: String in FACTION_TECH_DEFAULTS:
		var tech: String = FACTION_TECH_DEFAULTS[f]
		var lvl: int = TECH_LEVELS.get(tech, {}).get("level", 0)
		if lvl > best_lvl:
			best_lvl = lvl
			best = f
	return best

func get_factions_at_level(tech: String) -> Array[String]:
	var result: Array[String] = []
	for f: String in FACTION_TECH_DEFAULTS:
		if FACTION_TECH_DEFAULTS[f] == tech:
			result.append(f)
	return result

func get_research_speed(tech: String) -> float:
	return TECH_LEVELS.get(tech, {}).get("research_speed_mult", 0.0)

func get_avg_research_speed() -> float:
	var total: float = 0.0
	for t: String in TECH_LEVELS:
		total += TECH_LEVELS[t].get("research_speed_mult", 0.0)
	if TECH_LEVELS.is_empty():
		return 0.0
	return snappedf(total / float(TECH_LEVELS.size()), 0.01)

func get_faction_count_above_level(min_level: int) -> int:
	var count: int = 0
	for f: String in FACTION_TECH_DEFAULTS:
		var tech: String = FACTION_TECH_DEFAULTS[f]
		if TECH_LEVELS.get(tech, {}).get("level", 0) >= min_level:
			count += 1
	return count

func get_max_cost_multiplier() -> float:
	var mx: float = 0.0
	for k: String in RESEARCH_COST_MULT:
		if RESEARCH_COST_MULT[k] > mx:
			mx = RESEARCH_COST_MULT[k]
	return mx

func get_lowest_tech_faction() -> String:
	var worst: String = ""
	var worst_lvl: int = 999
	for f: String in FACTION_TECH_DEFAULTS:
		var tech: String = FACTION_TECH_DEFAULTS[f]
		var lvl: int = int(TECH_LEVELS.get(tech, {}).get("level", 999))
		if lvl < worst_lvl:
			worst_lvl = lvl
			worst = f
	return worst


func get_industrial_faction_count() -> int:
	var count: int = 0
	for f: String in FACTION_TECH_DEFAULTS:
		if FACTION_TECH_DEFAULTS[f] == "Industrial":
			count += 1
	return count


func get_research_speed_spread() -> float:
	var lo: float = 999.0
	var hi: float = 0.0
	for t: String in TECH_LEVELS:
		var s: float = float(TECH_LEVELS[t].get("research_speed_mult", 0.0))
		if s < lo:
			lo = s
		if s > hi:
			hi = s
	if lo > hi:
		return 0.0
	return hi - lo


func get_tech_disparity() -> int:
	var hi := 0
	var lo := 99
	for tech_key in FACTION_TECH_DEFAULTS.values():
		if TECH_LEVELS.has(tech_key):
			var lv: int = TECH_LEVELS[tech_key]["level"]
			hi = maxi(hi, lv)
			lo = mini(lo, lv)
	return hi - lo

func get_advancement_pressure_pct() -> float:
	var below := 0
	for tech_key in FACTION_TECH_DEFAULTS.values():
		if TECH_LEVELS.has(tech_key) and TECH_LEVELS[tech_key]["level"] <= 3:
			below += 1
	return snapped(float(below) / maxf(FACTION_TECH_DEFAULTS.size(), 1.0) * 100.0, 0.1)

func get_innovation_index() -> float:
	var unique_levels := {}
	var speed_sum := 0.0
	for tech_key in FACTION_TECH_DEFAULTS.values():
		if TECH_LEVELS.has(tech_key):
			unique_levels[TECH_LEVELS[tech_key]["level"]] = true
			speed_sum += TECH_LEVELS[tech_key]["research_speed_mult"]
	var diversity := float(unique_levels.size()) / maxf(TECH_LEVELS.size(), 1.0)
	var avg_speed := speed_sum / maxf(FACTION_TECH_DEFAULTS.size(), 1.0)
	return snapped(diversity * avg_speed * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"tech_levels": TECH_LEVELS.size(),
		"faction_defaults": FACTION_TECH_DEFAULTS.size(),
		"cost_tiers": RESEARCH_COST_MULT.size(),
		"highest_tech_faction": get_highest_tech_faction(),
		"avg_research_speed": get_avg_research_speed(),
		"spacer_plus_factions": get_faction_count_above_level(4),
		"max_cost_mult": get_max_cost_multiplier(),
		"lowest_tech_faction": get_lowest_tech_faction(),
		"industrial_factions": get_industrial_faction_count(),
		"speed_spread": snapped(get_research_speed_spread(), 0.01),
		"tech_disparity": get_tech_disparity(),
		"advancement_pressure_pct": get_advancement_pressure_pct(),
		"innovation_index": get_innovation_index(),
		"technological_supremacy": get_technological_supremacy(),
		"research_infrastructure_quality": get_research_infrastructure_quality(),
		"civilization_tier": get_civilization_tier(),
		"tech_ecosystem_health": get_tech_ecosystem_health(),
		"progress_governance": get_progress_governance(),
		"civilization_maturity_index": get_civilization_maturity_index(),
	}

func get_technological_supremacy() -> String:
	var highest := get_highest_tech_faction()
	var spacer := get_faction_count_above_level(4)
	if spacer >= 2:
		return "Dominant"
	elif spacer >= 1:
		return "Advanced"
	return "Developing"

func get_research_infrastructure_quality() -> float:
	var avg_speed := get_avg_research_speed()
	var spread := get_research_speed_spread()
	if spread <= 0.0:
		return avg_speed * 100.0
	return snapped(avg_speed / spread * 100.0, 0.1)

func get_civilization_tier() -> String:
	var industrial := get_industrial_faction_count()
	var spacer := get_faction_count_above_level(4)
	if spacer >= 2:
		return "Interstellar"
	elif industrial >= 3:
		return "Industrial"
	return "Pre-Industrial"

func get_tech_ecosystem_health() -> float:
	var supremacy := get_technological_supremacy()
	var s_val: float = 90.0 if supremacy == "Dominant" else (60.0 if supremacy == "Advanced" else 30.0)
	var infrastructure := get_research_infrastructure_quality()
	var tier := get_civilization_tier()
	var t_val: float = 90.0 if tier == "Interstellar" else (60.0 if tier == "Industrial" else 30.0)
	return snapped((s_val + minf(infrastructure, 100.0) + t_val) / 3.0, 0.1)

func get_civilization_maturity_index() -> float:
	var innovation := get_innovation_index()
	var pressure := get_advancement_pressure_pct()
	var disparity := get_tech_disparity()
	var d_val: float = maxf(100.0 - float(disparity) * 10.0, 0.0)
	return snapped((minf(innovation * 10.0, 100.0) + pressure + d_val) / 3.0, 0.1)

func get_progress_governance() -> String:
	var ecosystem := get_tech_ecosystem_health()
	var maturity := get_civilization_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif TECH_LEVELS.size() > 0:
		return "Nascent"
	return "Dormant"
