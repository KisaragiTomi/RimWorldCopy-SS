extends Node

const BODY_PARTS: Dictionary = {
	"Head": {"hp": 30, "groups": ["UpperHead", "FullHead"], "coverage": 0.1, "vital": true},
	"Neck": {"hp": 25, "groups": ["Neck"], "coverage": 0.05, "vital": true},
	"Torso": {"hp": 40, "groups": ["Torso", "UpperBody"], "coverage": 0.25, "vital": true},
	"LeftArm": {"hp": 25, "groups": ["LeftHand", "Arms"], "coverage": 0.08},
	"RightArm": {"hp": 25, "groups": ["RightHand", "Arms"], "coverage": 0.08},
	"LeftHand": {"hp": 20, "groups": ["LeftHand", "Hands"], "coverage": 0.04},
	"RightHand": {"hp": 20, "groups": ["RightHand", "Hands"], "coverage": 0.04},
	"LeftLeg": {"hp": 30, "groups": ["Legs", "LeftLeg"], "coverage": 0.1},
	"RightLeg": {"hp": 30, "groups": ["Legs", "RightLeg"], "coverage": 0.1},
	"LeftFoot": {"hp": 20, "groups": ["Feet"], "coverage": 0.04},
	"RightFoot": {"hp": 20, "groups": ["Feet"], "coverage": 0.04},
	"LeftEye": {"hp": 10, "groups": ["Eyes", "FullHead"], "coverage": 0.02},
	"RightEye": {"hp": 10, "groups": ["Eyes", "FullHead"], "coverage": 0.02},
	"LeftEar": {"hp": 10, "groups": ["Ears"], "coverage": 0.02},
	"RightEar": {"hp": 10, "groups": ["Ears"], "coverage": 0.02}
}

const ARMOR_COVERAGE: Dictionary = {
	"Flak": {"groups": ["Torso", "UpperBody", "Neck"], "sharp": 0.4, "blunt": 0.15},
	"Marine": {"groups": ["Torso", "UpperBody", "Arms", "Legs", "Neck"], "sharp": 0.7, "blunt": 0.4},
	"Cataphract": {"groups": ["Torso", "UpperBody", "Arms", "Legs", "Neck", "FullHead"], "sharp": 0.85, "blunt": 0.5},
	"AdvancedHelmet": {"groups": ["FullHead", "UpperHead", "Neck"], "sharp": 0.6, "blunt": 0.3},
	"SimpleHelmet": {"groups": ["UpperHead"], "sharp": 0.3, "blunt": 0.15}
}

func get_hit_part(coverage_weights: Dictionary) -> String:
	var total: float = 0.0
	for part: String in coverage_weights:
		total += coverage_weights[part]
	var roll: float = randf() * total
	var cumulative: float = 0.0
	for part: String in coverage_weights:
		cumulative += coverage_weights[part]
		if roll <= cumulative:
			return part
	return "Torso"

func is_armor_covering(armor: String, body_part: String) -> bool:
	if not ARMOR_COVERAGE.has(armor) or not BODY_PARTS.has(body_part):
		return false
	var armor_groups: Array = ARMOR_COVERAGE[armor]["groups"]
	var part_groups: Array = BODY_PARTS[body_part]["groups"]
	for ag: String in armor_groups:
		if ag in part_groups:
			return true
	return false

func get_vital_parts() -> Array[String]:
	var result: Array[String] = []
	for p: String in BODY_PARTS:
		if BODY_PARTS[p].get("vital", false):
			result.append(p)
	return result

func get_most_exposed_part() -> String:
	var best: String = ""
	var best_cov: float = 999.0
	for p: String in BODY_PARTS:
		if BODY_PARTS[p]["coverage"] < best_cov:
			best_cov = BODY_PARTS[p]["coverage"]
			best = p
	return best

func get_best_armor_coverage() -> String:
	var best: String = ""
	var best_cnt: int = 0
	for a: String in ARMOR_COVERAGE:
		var cnt: int = ARMOR_COVERAGE[a]["groups"].size()
		if cnt > best_cnt:
			best_cnt = cnt
			best = a
	return best

func get_avg_hp() -> float:
	if BODY_PARTS.is_empty():
		return 0.0
	var total: float = 0.0
	for bp: String in BODY_PARTS:
		total += float(BODY_PARTS[bp].get("hp", 0))
	return total / BODY_PARTS.size()

func get_non_vital_count() -> int:
	return BODY_PARTS.size() - get_vital_parts().size()

func get_most_protected_part() -> String:
	var best: String = ""
	var best_count: int = 0
	for bp: String in BODY_PARTS:
		var cover: int = 0
		for armor: String in ARMOR_COVERAGE:
			var parts: Array = ARMOR_COVERAGE[armor].get("parts", [])
			if bp in parts:
				cover += 1
		if cover > best_count:
			best_count = cover
			best = bp
	return best

func get_total_body_hp() -> int:
	var total: int = 0
	for bp: String in BODY_PARTS:
		total += int(BODY_PARTS[bp].get("hp", 0))
	return total


func get_highest_coverage_part() -> String:
	var best: String = ""
	var best_c: float = 0.0
	for bp: String in BODY_PARTS:
		var c: float = float(BODY_PARTS[bp].get("coverage", 0.0))
		if c > best_c:
			best_c = c
			best = bp
	return best


func get_unique_groups() -> int:
	var groups: Dictionary = {}
	for bp: String in BODY_PARTS:
		for g: String in BODY_PARTS[bp].get("groups", []):
			groups[g] = true
	return groups.size()


func get_anatomical_resilience() -> String:
	var vital: int = get_vital_parts().size()
	var total: int = BODY_PARTS.size()
	if total == 0:
		return "unknown"
	var ratio: float = vital * 1.0 / total
	if ratio <= 0.2:
		return "robust"
	if ratio <= 0.4:
		return "moderate"
	return "fragile"

func get_protection_coverage_pct() -> float:
	var protected: int = 0
	for p: String in BODY_PARTS:
		if BODY_PARTS[p].get("armor_group", "") != "":
			protected += 1
	if BODY_PARTS.is_empty():
		return 0.0
	return snapped(protected * 100.0 / BODY_PARTS.size(), 0.1)

func get_vulnerability_profile() -> String:
	var avg: float = get_avg_hp()
	var total: float = get_total_body_hp()
	if total <= 0.0:
		return "unknown"
	var vitals: int = get_vital_parts().size()
	if vitals >= 4 and avg < 30.0:
		return "high_risk"
	if vitals >= 2:
		return "moderate_risk"
	return "low_risk"

func get_summary() -> Dictionary:
	return {
		"body_parts": BODY_PARTS.size(),
		"armor_sets": ARMOR_COVERAGE.size(),
		"vital_parts": get_vital_parts().size(),
		"best_coverage_armor": get_best_armor_coverage(),
		"avg_hp": snapped(get_avg_hp(), 0.1),
		"non_vital": get_non_vital_count(),
		"most_protected": get_most_protected_part(),
		"total_hp": get_total_body_hp(),
		"highest_coverage": get_highest_coverage_part(),
		"unique_groups": get_unique_groups(),
		"anatomical_resilience": get_anatomical_resilience(),
		"protection_coverage_pct": get_protection_coverage_pct(),
		"vulnerability_profile": get_vulnerability_profile(),
		"combat_survivability": get_combat_survivability(),
		"critical_organ_exposure": get_critical_organ_exposure(),
		"body_integrity_score": get_body_integrity_score(),
		"anatomical_ecosystem_health": get_anatomical_ecosystem_health(),
		"body_governance": get_body_governance(),
		"physiological_maturity_index": get_physiological_maturity_index(),
	}

func get_combat_survivability() -> String:
	var resilience := get_anatomical_resilience()
	var coverage := get_protection_coverage_pct()
	if resilience in ["High", "Exceptional"] and coverage >= 70.0:
		return "Hardened"
	elif coverage >= 40.0:
		return "Moderate"
	return "Fragile"

func get_critical_organ_exposure() -> float:
	var vital := get_vital_parts().size()
	var total := BODY_PARTS.size()
	if total <= 0:
		return 0.0
	return snapped(float(vital) / float(total) * 100.0, 0.1)

func get_body_integrity_score() -> float:
	var total_hp := get_total_body_hp()
	var parts := BODY_PARTS.size()
	if parts <= 0:
		return 0.0
	return snapped(float(total_hp) / float(parts), 0.1)

func get_anatomical_ecosystem_health() -> float:
	var survivability := get_combat_survivability()
	var s_val: float = 90.0 if survivability == "Hardened" else (60.0 if survivability == "Moderate" else 30.0)
	var coverage := get_protection_coverage_pct()
	var integrity := get_body_integrity_score()
	return snapped((s_val + coverage + minf(integrity * 2.0, 100.0)) / 3.0, 0.1)

func get_physiological_maturity_index() -> float:
	var resilience := get_anatomical_resilience()
	var r_val: float = 90.0 if resilience in ["High", "Exceptional"] else (60.0 if resilience in ["Moderate", "Average"] else 30.0)
	var exposure := get_critical_organ_exposure()
	var e_val: float = maxf(100.0 - exposure, 0.0)
	var profile := get_vulnerability_profile()
	var p_val: float = 90.0 if profile in ["armored", "resilient"] else (60.0 if profile in ["moderate", "average"] else 30.0)
	return snapped((r_val + e_val + p_val) / 3.0, 0.1)

func get_body_governance() -> String:
	var ecosystem := get_anatomical_ecosystem_health()
	var maturity := get_physiological_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif BODY_PARTS.size() > 0:
		return "Nascent"
	return "Dormant"
