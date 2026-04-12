extends Node

const SYNERGIES: Dictionary = {
	"Tough+Brawler": {"melee_damage": 0.15, "description": "Natural fighter"},
	"Industrious+FastLearner": {"global_work_speed": 0.20, "description": "Prodigy worker"},
	"Kind+Beautiful": {"social_impact": 0.25, "description": "Beloved by all"},
	"Psychopath+Bloodlust": {"mental_break_threshold": -0.10, "description": "Cold killer"},
	"Neurotic+Industrious": {"work_speed": 0.25, "mental_break_threshold": 0.05, "description": "Perfectionist"},
	"Jogger+Nimble": {"move_speed": 0.20, "dodge_chance": 0.10, "description": "Untouchable"},
	"GreenThumb+PlantLover": {"plant_speed": 0.25, "description": "Master gardener"},
	"Ascetic+Tough": {"pain_threshold": 0.15, "description": "Stoic endurance"}
}

const CONFLICTS: Dictionary = {
	"Greedy+Ascetic": {"incompatible": true, "description": "Cannot coexist"},
	"Kind+Psychopath": {"incompatible": true, "description": "Cannot coexist"},
	"Industrious+Lazy": {"incompatible": true, "description": "Cannot coexist"},
	"Optimist+Pessimist": {"incompatible": true, "description": "Cannot coexist"},
	"Bloodlust+Kind": {"incompatible": true, "description": "Cannot coexist"},
	"NightOwl+EarlyRiser": {"incompatible": true, "description": "Cannot coexist"}
}

func get_synergy(trait_a: String, trait_b: String) -> Dictionary:
	var key1: String = trait_a + "+" + trait_b
	var key2: String = trait_b + "+" + trait_a
	if SYNERGIES.has(key1):
		return SYNERGIES[key1]
	if SYNERGIES.has(key2):
		return SYNERGIES[key2]
	return {}

func are_conflicting(trait_a: String, trait_b: String) -> bool:
	var key1: String = trait_a + "+" + trait_b
	var key2: String = trait_b + "+" + trait_a
	return CONFLICTS.has(key1) or CONFLICTS.has(key2)

func evaluate_trait_set(pawn_traits: Array) -> Dictionary:
	var bonuses: Dictionary = {}
	var conflicts: Array = []
	for i: int in range(pawn_traits.size()):
		for j: int in range(i + 1, pawn_traits.size()):
			var syn: Dictionary = get_synergy(pawn_traits[i], pawn_traits[j])
			if not syn.is_empty():
				for k: String in syn:
					if k != "description":
						bonuses[k] = bonuses.get(k, 0.0) + syn[k]
			if are_conflicting(pawn_traits[i], pawn_traits[j]):
				conflicts.append(pawn_traits[i] + "+" + pawn_traits[j])
	return {"bonuses": bonuses, "conflicts": conflicts}

func get_all_synergy_traits() -> Array[String]:
	var traits: Dictionary = {}
	for key: String in SYNERGIES:
		var parts: Array = key.split("+")
		for p in parts:
			traits[String(p)] = true
	var result: Array[String] = []
	for k: String in traits:
		result.append(k)
	return result


func get_strongest_synergy() -> Dictionary:
	var best_key: String = ""
	var best_total: float = 0.0
	for key: String in SYNERGIES:
		var s: Dictionary = SYNERGIES[key]
		var total: float = 0.0
		for k: String in s:
			if k != "description":
				total += absf(float(s[k]))
		if total > best_total:
			best_total = total
			best_key = key
	if best_key.is_empty():
		return {}
	return {"combo": best_key, "total_bonus": best_total}


func get_avg_synergy_bonus() -> float:
	if SYNERGIES.is_empty():
		return 0.0
	var total: float = 0.0
	for key: String in SYNERGIES:
		var s: Dictionary = SYNERGIES[key]
		for k: String in s:
			if k != "description":
				total += absf(float(s[k]))
	return total / SYNERGIES.size()


func get_total_unique_traits() -> int:
	var traits: Dictionary = {}
	for key: String in SYNERGIES:
		for p in key.split("+"):
			traits[String(p)] = true
	for key: String in CONFLICTS:
		for p in key.split("+"):
			traits[String(p)] = true
	return traits.size()


func get_weakest_synergy() -> Dictionary:
	var best_key: String = ""
	var best_total: float = 999.0
	for key: String in SYNERGIES:
		var s: Dictionary = SYNERGIES[key]
		var total: float = 0.0
		for k: String in s:
			if k != "description":
				total += absf(float(s[k]))
		if total < best_total:
			best_total = total
			best_key = key
	if best_key.is_empty():
		return {}
	return {"combo": best_key, "total_bonus": best_total}


func get_conflict_trait_count() -> int:
	var traits: Dictionary = {}
	for key: String in CONFLICTS:
		for p in key.split("+"):
			traits[String(p)] = true
	return traits.size()


func get_synergy_to_conflict_ratio() -> float:
	if CONFLICTS.is_empty():
		return 0.0
	return snappedf(float(SYNERGIES.size()) / float(CONFLICTS.size()), 0.01)


func get_multi_synergy_traits() -> int:
	var trait_counts: Dictionary = {}
	for key: String in SYNERGIES:
		for p in key.split("+"):
			var t: String = String(p)
			trait_counts[t] = trait_counts.get(t, 0) + 1
	var count: int = 0
	for t: String in trait_counts:
		if int(trait_counts[t]) > 1:
			count += 1
	return count


func get_harmony_level() -> String:
	var ratio: float = get_synergy_to_conflict_ratio()
	if ratio >= 3.0:
		return "Harmonious"
	elif ratio >= 1.5:
		return "Cooperative"
	elif ratio >= 0.8:
		return "Neutral"
	return "Contentious"

func get_trait_complexity() -> String:
	var multi: int = get_multi_synergy_traits()
	var unique: int = get_total_unique_traits()
	if unique == 0:
		return "N/A"
	var pct: float = float(multi) / float(unique)
	if pct >= 0.6:
		return "Complex"
	elif pct >= 0.3:
		return "Moderate"
	return "Simple"

func get_conflict_pressure_pct() -> float:
	var total: int = SYNERGIES.size() + CONFLICTS.size()
	if total == 0:
		return 0.0
	return snappedf(float(CONFLICTS.size()) / float(total) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"synergy_count": SYNERGIES.size(),
		"conflict_count": CONFLICTS.size(),
		"strongest": get_strongest_synergy(),
		"avg_bonus": snapped(get_avg_synergy_bonus(), 0.01),
		"unique_traits": get_total_unique_traits(),
		"weakest": get_weakest_synergy(),
		"conflict_traits": get_conflict_trait_count(),
		"synergy_conflict_ratio": get_synergy_to_conflict_ratio(),
		"multi_synergy_traits": get_multi_synergy_traits(),
		"harmony_level": get_harmony_level(),
		"trait_complexity": get_trait_complexity(),
		"conflict_pressure_pct": get_conflict_pressure_pct(),
		"personality_synergy_index": get_personality_synergy_index(),
		"social_friction_risk": get_social_friction_risk(),
		"character_chemistry": get_character_chemistry(),
		"personality_ecosystem_health": get_personality_ecosystem_health(),
		"social_governance": get_social_governance(),
		"interpersonal_maturity_index": get_interpersonal_maturity_index(),
	}

func get_personality_synergy_index() -> float:
	var bonus := get_avg_synergy_bonus()
	var multi := get_multi_synergy_traits()
	return snapped(bonus * float(multi + 1), 0.1)

func get_social_friction_risk() -> String:
	var pressure := get_conflict_pressure_pct()
	if pressure >= 50.0:
		return "High"
	elif pressure >= 20.0:
		return "Moderate"
	return "Low"

func get_character_chemistry() -> String:
	var harmony := get_harmony_level()
	var ratio := get_synergy_to_conflict_ratio()
	if harmony in ["Harmonious"] and ratio >= 2.0:
		return "Excellent"
	elif harmony in ["Balanced", "Harmonious"]:
		return "Good"
	return "Strained"

func get_personality_ecosystem_health() -> float:
	var chemistry := get_character_chemistry()
	var ch_val: float = 90.0 if chemistry == "Excellent" else (60.0 if chemistry == "Good" else 30.0)
	var synergy := get_personality_synergy_index()
	var pressure := get_conflict_pressure_pct()
	var p_val: float = maxf(100.0 - pressure, 0.0)
	return snapped((ch_val + minf(synergy, 100.0) + p_val) / 3.0, 0.1)

func get_interpersonal_maturity_index() -> float:
	var harmony := get_harmony_level()
	var h_val: float = 90.0 if harmony == "Harmonious" else (60.0 if harmony in ["Balanced", "Neutral"] else 30.0)
	var complexity := get_trait_complexity()
	var c_val: float = 90.0 if complexity in ["Rich", "Complex"] else (60.0 if complexity in ["Moderate", "Simple"] else 30.0)
	var ratio := get_synergy_to_conflict_ratio()
	var r_val: float = minf(ratio * 30.0, 100.0)
	return snapped((h_val + c_val + r_val) / 3.0, 0.1)

func get_social_governance() -> String:
	var ecosystem := get_personality_ecosystem_health()
	var maturity := get_interpersonal_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif SYNERGIES.size() > 0:
		return "Nascent"
	return "Dormant"
