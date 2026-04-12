extends Node

const ROOM_STATS: Dictionary = {
	"Impressiveness": {"weight": 1.0, "desc": "Overall room quality"},
	"Beauty": {"weight": 0.8, "desc": "Visual appeal"},
	"Wealth": {"weight": 0.6, "desc": "Total value of furnishings"},
	"Space": {"weight": 0.5, "desc": "Unobstructed floor area"},
	"Cleanliness": {"weight": 0.7, "desc": "Filth level"},
	"LightLevel": {"weight": 0.3, "desc": "Average lighting"}
}

const IMPRESSIVENESS_THRESHOLDS: Dictionary = {
	"Awful": 0.0,
	"Dull": 20.0,
	"Mediocre": 35.0,
	"Decent": 50.0,
	"Slightly_Impressive": 65.0,
	"Somewhat_Impressive": 80.0,
	"Very_Impressive": 100.0,
	"Extremely_Impressive": 130.0,
	"Unbelievably_Impressive": 170.0,
	"Wondrously_Impressive": 220.0
}

const ROOM_ROLES: Dictionary = {
	"Bedroom": {"required_stats": {"Space": 12, "Beauty": 20}, "mood_bonus": 3},
	"DiningRoom": {"required_stats": {"Impressiveness": 40}, "mood_bonus": 2},
	"RecRoom": {"required_stats": {"Space": 20, "Beauty": 15}, "mood_bonus": 2},
	"Hospital": {"required_stats": {"Cleanliness": 80, "LightLevel": 60}, "surgery_bonus": 0.05},
	"Prison": {"required_stats": {"Space": 8}, "recruit_bonus": 0.02},
	"Throne": {"required_stats": {"Impressiveness": 80, "Space": 30}, "mood_bonus": 5},
	"Lab": {"required_stats": {"Cleanliness": 60}, "research_bonus": 0.03},
	"Workshop": {"required_stats": {"Space": 15}, "work_speed_bonus": 0.02}
}

func calc_impressiveness(beauty: float, wealth: float, space: float, cleanliness: float) -> float:
	return beauty * 0.3 + wealth * 0.002 + space * 0.5 + cleanliness * 0.2

func get_impressiveness_label(score: float) -> String:
	var result: String = "Awful"
	for label: String in IMPRESSIVENESS_THRESHOLDS:
		if score >= IMPRESSIVENESS_THRESHOLDS[label]:
			result = label
	return result

func get_room_mood_bonus(role: String, impressiveness: float) -> float:
	if not ROOM_ROLES.has(role):
		return 0.0
	var base: float = ROOM_ROLES[role].get("mood_bonus", 0.0)
	var multiplier: float = 1.0 + (impressiveness - 50.0) / 100.0
	return base * maxf(multiplier, 0.5)

func get_roles_with_bonus(bonus_type: String) -> Array[String]:
	var result: Array[String] = []
	for role: String in ROOM_ROLES:
		if ROOM_ROLES[role].has(bonus_type):
			result.append(role)
	return result


func get_highest_mood_role() -> String:
	var best: String = ""
	var best_mood: float = 0.0
	for role: String in ROOM_ROLES:
		var m: float = float(ROOM_ROLES[role].get("mood_bonus", 0.0))
		if m > best_mood:
			best_mood = m
			best = role
	return best


func get_max_impressiveness_label() -> String:
	var best: String = ""
	var best_threshold: float = 0.0
	for label: String in IMPRESSIVENESS_THRESHOLDS:
		var t: float = float(IMPRESSIVENESS_THRESHOLDS[label])
		if t > best_threshold:
			best_threshold = t
			best = label
	return best


func get_avg_role_mood() -> float:
	if ROOM_ROLES.is_empty():
		return 0.0
	var total: float = 0.0
	for role: String in ROOM_ROLES:
		total += float(ROOM_ROLES[role].get("mood_bonus", 0.0))
	return total / ROOM_ROLES.size()


func get_roles_with_requirements() -> int:
	var count: int = 0
	for role: String in ROOM_ROLES:
		if not ROOM_ROLES[role].get("required_stats", {}).is_empty():
			count += 1
	return count


func get_total_stat_count() -> int:
	return ROOM_STATS.size()


func get_highest_weight_stat() -> String:
	var best: String = ""
	var best_w: float = 0.0
	for stat: String in ROOM_STATS:
		var w: float = float(ROOM_STATS[stat].get("weight", 0.0))
		if w > best_w:
			best_w = w
			best = stat
	return best


func get_avg_stat_weight() -> float:
	if ROOM_STATS.is_empty():
		return 0.0
	var total: float = 0.0
	for stat: String in ROOM_STATS:
		total += float(ROOM_STATS[stat].get("weight", 0.0))
	return snappedf(total / float(ROOM_STATS.size()), 0.01)


func get_total_role_bonuses() -> int:
	var count: int = 0
	for role: String in ROOM_ROLES:
		for key: String in ROOM_ROLES[role]:
			if key.ends_with("_bonus"):
				count += 1
	return count


func get_design_complexity() -> String:
	var total_reqs: int = 0
	for role: String in ROOM_ROLES:
		total_reqs += ROOM_ROLES[role].get("required_stats", {}).size()
	var avg_reqs: float = float(total_reqs) / maxf(float(ROOM_ROLES.size()), 1.0)
	if avg_reqs >= 2.0:
		return "High"
	if avg_reqs >= 1.5:
		return "Moderate"
	return "Simple"


func get_stat_coverage_pct() -> float:
	var used_stats: Dictionary = {}
	for role: String in ROOM_ROLES:
		for stat: String in ROOM_ROLES[role].get("required_stats", {}):
			used_stats[stat] = true
	return snappedf(float(used_stats.size()) / maxf(float(ROOM_STATS.size()), 1.0) * 100.0, 0.1)


func get_luxury_index() -> float:
	var threshold_values: Array = IMPRESSIVENESS_THRESHOLDS.values()
	if threshold_values.is_empty():
		return 0.0
	var max_thresh: float = 0.0
	for v: Variant in threshold_values:
		if float(v) > max_thresh:
			max_thresh = float(v)
	var top_roles: int = 0
	for role: String in ROOM_ROLES:
		var reqs: Dictionary = ROOM_ROLES[role].get("required_stats", {})
		if reqs.has("Impressiveness") and float(reqs["Impressiveness"]) >= 60.0:
			top_roles += 1
	return snappedf(float(top_roles) / maxf(float(ROOM_ROLES.size()), 1.0) * 100.0, 0.1)


func get_summary() -> Dictionary:
	return {
		"room_stats": ROOM_STATS.size(),
		"impressiveness_levels": IMPRESSIVENESS_THRESHOLDS.size(),
		"room_roles": ROOM_ROLES.size(),
		"highest_mood_role": get_highest_mood_role(),
		"avg_role_mood": snapped(get_avg_role_mood(), 0.1),
		"roles_with_reqs": get_roles_with_requirements(),
		"highest_weight_stat": get_highest_weight_stat(),
		"avg_stat_weight": get_avg_stat_weight(),
		"total_role_bonuses": get_total_role_bonuses(),
		"design_complexity": get_design_complexity(),
		"stat_coverage_pct": get_stat_coverage_pct(),
		"luxury_index": get_luxury_index(),
		"room_optimization_score": get_room_optimization_score(),
		"comfort_consistency": get_comfort_consistency(),
		"architectural_ambition": get_architectural_ambition(),
		"interior_ecosystem_health": get_interior_ecosystem_health(),
		"design_governance": get_design_governance(),
		"habitat_maturity_index": get_habitat_maturity_index(),
	}

func get_room_optimization_score() -> float:
	var coverage := get_stat_coverage_pct()
	var avg_mood := get_avg_role_mood()
	return snapped(coverage * (avg_mood / 10.0 + 0.5), 0.1)

func get_comfort_consistency() -> String:
	var roles := get_roles_with_requirements()
	var total := ROOM_ROLES.size()
	if total <= 0:
		return "None"
	var ratio := float(roles) / float(total)
	if ratio >= 0.8:
		return "Uniform"
	elif ratio >= 0.5:
		return "Mixed"
	return "Inconsistent"

func get_architectural_ambition() -> String:
	var luxury := get_luxury_index()
	var complexity := get_design_complexity()
	if luxury in ["Lavish", "Opulent"] and complexity in ["Complex", "Advanced"]:
		return "Grand"
	elif luxury in ["Comfortable", "Lavish"]:
		return "Ambitious"
	return "Modest"

func get_interior_ecosystem_health() -> float:
	var opt := get_room_optimization_score()
	var consistency := get_comfort_consistency()
	var c_val: float = 90.0 if consistency == "Uniform" else (60.0 if consistency == "Mixed" else 25.0)
	var coverage := get_stat_coverage_pct()
	return snapped((opt + c_val + coverage) / 3.0, 0.1)

func get_design_governance() -> String:
	var ecosystem := get_interior_ecosystem_health()
	var ambition := get_architectural_ambition()
	var a_val: float = 90.0 if ambition == "Grand" else (60.0 if ambition == "Ambitious" else 25.0)
	var combined := (ecosystem + a_val) / 2.0
	if combined >= 70.0:
		return "Masterful"
	elif combined >= 40.0:
		return "Competent"
	elif ROOM_ROLES.size() > 0:
		return "Basic"
	return "None"

func get_habitat_maturity_index() -> float:
	var luxury := get_luxury_index()
	var l_val: float = minf(luxury, 100.0)
	var complexity := get_design_complexity()
	var cx_val: float = 90.0 if complexity in ["High", "Advanced"] else (60.0 if complexity == "Moderate" else 25.0)
	return snapped((l_val + cx_val) / 2.0, 0.1)
