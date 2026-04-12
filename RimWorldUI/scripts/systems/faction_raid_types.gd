extends Node

const RAID_STYLES: Dictionary = {
	"Pirate": {
		"tactics": ["FrontalAssault", "SapperAttack", "SiegeWithMortars"],
		"min_tech": "Industrial",
		"weapon_bias": "Ranged",
		"retreat_threshold": 0.5,
	},
	"Tribe": {
		"tactics": ["FrontalAssault", "HumanWave", "SurpriseAttack"],
		"min_tech": "Neolithic",
		"weapon_bias": "Melee",
		"retreat_threshold": 0.3,
	},
	"Mechanoid": {
		"tactics": ["DropPodAssault", "ClusterLanding", "SiegeWithInferno"],
		"min_tech": "Spacer",
		"weapon_bias": "Ranged",
		"retreat_threshold": 0.0,
	},
	"Insectoid": {
		"tactics": ["TunnelAttack", "InfestationSpawn"],
		"min_tech": "None",
		"weapon_bias": "Melee",
		"retreat_threshold": 0.0,
	},
	"Empire": {
		"tactics": ["DropPodAssault", "FrontalAssault", "Bombardment"],
		"min_tech": "Spacer",
		"weapon_bias": "Mixed",
		"retreat_threshold": 0.6,
	},
}


func get_raid_style(faction_type: String) -> Dictionary:
	return RAID_STYLES.get(faction_type, RAID_STYLES["Pirate"])


func pick_tactic(faction_type: String) -> String:
	var style: Dictionary = get_raid_style(faction_type)
	var tactics: Array = style.get("tactics", ["FrontalAssault"])
	if tactics.is_empty():
		return "FrontalAssault"
	return str(tactics[randi() % tactics.size()])


func should_retreat(faction_type: String, casualties_ratio: float) -> bool:
	var style: Dictionary = get_raid_style(faction_type)
	var threshold: float = float(style.get("retreat_threshold", 0.5))
	return casualties_ratio >= threshold and threshold > 0.0


func get_all_tactics() -> Array[String]:
	var tactics: Array[String] = []
	for faction: String in RAID_STYLES:
		for t in RAID_STYLES[faction].tactics:
			var ts: String = str(t)
			if not tactics.has(ts):
				tactics.append(ts)
	return tactics


func get_faction_danger_rank() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for faction: String in RAID_STYLES:
		var style: Dictionary = RAID_STYLES[faction]
		var danger: float = float(style.tactics.size()) * (1.0 - style.retreat_threshold)
		result.append({"faction": faction, "danger": snappedf(danger, 0.01)})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.danger > b.danger
	)
	return result


func get_factions_with_tactic(tactic: String) -> Array[String]:
	var result: Array[String] = []
	for faction: String in RAID_STYLES:
		for t in RAID_STYLES[faction].tactics:
			if str(t) == tactic:
				result.append(faction)
				break
	return result


func get_most_dangerous_faction() -> String:
	var rank := get_faction_danger_rank()
	if rank.is_empty():
		return ""
	return rank[0].faction


func get_avg_tactic_count() -> float:
	if RAID_STYLES.is_empty():
		return 0.0
	var total: int = 0
	for faction: String in RAID_STYLES:
		total += RAID_STYLES[faction].tactics.size()
	return snappedf(float(total) / float(RAID_STYLES.size()), 0.1)


func get_retreat_threshold_range() -> Dictionary:
	var low: float = 1.0
	var high: float = 0.0
	for faction: String in RAID_STYLES:
		var t: float = RAID_STYLES[faction].retreat_threshold
		if t < low:
			low = t
		if t > high:
			high = t
	return {"min": snappedf(low, 0.01), "max": snappedf(high, 0.01)}


func get_tactical_complexity() -> String:
	var avg: float = get_avg_tactic_count()
	if avg >= 4.0:
		return "Complex"
	elif avg >= 2.0:
		return "Moderate"
	elif avg > 0.0:
		return "Simple"
	return "None"

func get_most_aggressive_retreat() -> float:
	var r: Dictionary = get_retreat_threshold_range()
	return r.get("max", 0.0)

func get_danger_diversity() -> int:
	var rank: Array = get_faction_danger_rank()
	return rank.size()

func get_summary() -> Dictionary:
	return {
		"faction_types": RAID_STYLES.size(),
		"styles": RAID_STYLES.keys(),
		"total_tactics": get_all_tactics().size(),
		"danger_rank": get_faction_danger_rank(),
		"most_dangerous": get_most_dangerous_faction(),
		"avg_tactics": get_avg_tactic_count(),
		"retreat_range": get_retreat_threshold_range(),
		"faction_count": RAID_STYLES.size(),
		"tactics_per_faction": snappedf(float(get_all_tactics().size()) / maxf(float(RAID_STYLES.size()), 1.0), 0.1),
		"tactical_complexity": get_tactical_complexity(),
		"max_retreat_threshold": get_most_aggressive_retreat(),
		"danger_diversity": get_danger_diversity(),
		"tactical_adaptability": get_tactical_adaptability(),
		"defense_preparedness": get_defense_preparedness(),
		"threat_dimensionality": get_threat_dimensionality(),
		"adversarial_intelligence": get_adversarial_intelligence(),
		"counter_strategy_readiness": get_counter_strategy_readiness(),
		"combat_ecology_score": get_combat_ecology_score(),
	}

func get_adversarial_intelligence() -> float:
	var diversity := float(get_danger_diversity())
	var tactics := float(get_all_tactics().size())
	return snapped(diversity * tactics / maxf(float(RAID_STYLES.size()), 1.0) * 10.0, 0.1)

func get_counter_strategy_readiness() -> String:
	var preparedness := get_defense_preparedness()
	var adaptability := get_tactical_adaptability()
	if preparedness == "Well Prepared" and adaptability == "Highly Adaptive":
		return "Comprehensive"
	elif preparedness == "Unprepared":
		return "Deficient"
	return "Partial"

func get_combat_ecology_score() -> float:
	var factions := float(RAID_STYLES.size())
	var tactics := float(get_all_tactics().size())
	if factions <= 0.0:
		return 0.0
	return snapped(tactics / factions * 25.0, 0.1)

func get_tactical_adaptability() -> String:
	var complexity := get_tactical_complexity()
	var diversity := get_danger_diversity()
	if complexity == "Complex" and diversity >= 3:
		return "Highly Adaptive"
	elif diversity >= 2:
		return "Adaptive"
	return "Predictable"

func get_defense_preparedness() -> String:
	var danger := get_faction_danger_rank()
	if danger.is_empty():
		return "N/A"
	var top_threat := danger[0] if danger.size() > 0 else {}
	var score: float = top_threat.get("danger_score", 0.0)
	if score <= 5.0:
		return "Prepared"
	elif score <= 10.0:
		return "Alert"
	return "Vulnerable"

func get_threat_dimensionality() -> float:
	var tactics := get_all_tactics()
	var unique_types: Dictionary = {}
	for t: String in tactics:
		unique_types[t] = true
	return snapped(float(unique_types.size()) / maxf(float(tactics.size()), 1.0) * 100.0, 0.1)
