extends Node

const AGE_THRESHOLDS: Dictionary = {
	"young": {"min": 18, "max": 30, "consciousness": 1.0, "moving": 1.0, "immunity": 1.0},
	"adult": {"min": 31, "max": 50, "consciousness": 1.0, "moving": 0.95, "immunity": 0.95},
	"middle": {"min": 51, "max": 65, "consciousness": 0.95, "moving": 0.85, "immunity": 0.85},
	"elderly": {"min": 66, "max": 80, "consciousness": 0.85, "moving": 0.7, "immunity": 0.7},
	"very_old": {"min": 81, "max": 120, "consciousness": 0.7, "moving": 0.5, "immunity": 0.5},
}

const CHRONIC_CONDITIONS: Array = [
	{"name": "BadBack", "min_age": 45, "chance_per_year": 0.02, "moving_penalty": -0.1},
	{"name": "Frail", "min_age": 60, "chance_per_year": 0.03, "moving_penalty": -0.15},
	{"name": "Cataracts", "min_age": 55, "chance_per_year": 0.02, "sight_penalty": -0.2},
	{"name": "Dementia", "min_age": 70, "chance_per_year": 0.01, "consciousness_penalty": -0.2},
	{"name": "Alzheimers", "min_age": 75, "chance_per_year": 0.005, "consciousness_penalty": -0.3},
]


func get_age_category(age: int) -> String:
	for cat: String in AGE_THRESHOLDS:
		var data: Dictionary = AGE_THRESHOLDS[cat]
		if age >= int(data.min) and age <= int(data.max):
			return cat
	return "very_old"


func get_stat_modifier(age: int, stat: String) -> float:
	var cat: String = get_age_category(age)
	var data: Dictionary = AGE_THRESHOLDS.get(cat, {})
	return float(data.get(stat, 1.0))


func check_chronic_conditions(age: int) -> Array:
	var possible: Array = []
	for cond in CHRONIC_CONDITIONS:
		var cd: Dictionary = cond if cond is Dictionary else {}
		if age >= int(cd.get("min_age", 999)):
			possible.append(cd)
	return possible


func get_all_modifiers(age: int) -> Dictionary:
	var cat: String = get_age_category(age)
	var data: Dictionary = AGE_THRESHOLDS.get(cat, {})
	var mods: Dictionary = {}
	for key: String in ["consciousness", "moving", "immunity"]:
		mods[key] = float(data.get(key, 1.0))
	return mods


func get_chronic_risk_summary(age: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for cond in CHRONIC_CONDITIONS:
		var cd: Dictionary = cond if cond is Dictionary else {}
		if age >= int(cd.get("min_age", 999)):
			result.append({"name": cd.get("name", ""), "chance": cd.get("chance_per_year", 0.0)})
	return result


func get_worst_stat(age: int) -> String:
	var mods: Dictionary = get_all_modifiers(age)
	var worst: String = ""
	var worst_val: float = 2.0
	for stat: String in mods:
		if mods[stat] < worst_val:
			worst_val = mods[stat]
			worst = stat
	return worst


func get_most_penalized_category() -> String:
	var worst: String = ""
	var worst_sum: float = 99.0
	for cat: String in AGE_THRESHOLDS:
		var data: Dictionary = AGE_THRESHOLDS[cat]
		var s: float = float(data.get("consciousness", 1.0)) + float(data.get("moving", 1.0)) + float(data.get("immunity", 1.0))
		if s < worst_sum:
			worst_sum = s
			worst = cat
	return worst


func get_high_risk_condition_count(age: int) -> int:
	var count: int = 0
	for cond in CHRONIC_CONDITIONS:
		var cd: Dictionary = cond if cond is Dictionary else {}
		if age >= int(cd.get("min_age", 999)) and cd.get("chance_per_year", 0.0) > 0.05:
			count += 1
	return count


func get_avg_chronic_risk() -> float:
	if CHRONIC_CONDITIONS.is_empty():
		return 0.0
	var total: float = 0.0
	for cond in CHRONIC_CONDITIONS:
		var cd: Dictionary = cond if cond is Dictionary else {}
		total += float(cd.get("chance_per_year", 0.0))
	return snappedf(total / float(CHRONIC_CONDITIONS.size()), 0.001)


func get_colony_age_distribution() -> Dictionary:
	var dist: Dictionary = {}
	if not PawnManager:
		return dist
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var age: int = int(p.get("bio_age")) if "bio_age" in p else 30
		var cat: String = get_age_category(age)
		dist[cat] = dist.get(cat, 0) + 1
	return dist


func get_avg_colony_age() -> float:
	if not PawnManager:
		return 0.0
	var total: int = 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var age: int = int(p.get("bio_age")) if "bio_age" in p else 30
		total += age
		count += 1
	if count == 0:
		return 0.0
	return snappedf(float(total) / float(count), 0.1)


func get_elderly_risk_count() -> int:
	var count: int = 0
	if not PawnManager:
		return 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var age: int = int(p.get("bio_age")) if "bio_age" in p else 30
		var cat: String = get_age_category(age)
		if cat == "elderly" or cat == "very_old":
			count += 1
	return count


func get_earliest_condition_age() -> int:
	var earliest: int = 999
	for cond in CHRONIC_CONDITIONS:
		var cd: Dictionary = cond if cond is Dictionary else {}
		var age: int = int(cd.get("min_age", 999))
		if age < earliest:
			earliest = age
	return earliest


func get_latest_condition_age() -> int:
	var latest: int = 0
	for cond in CHRONIC_CONDITIONS:
		var cd: Dictionary = cond if cond is Dictionary else {}
		var age: int = int(cd.get("min_age", 0))
		if age > latest:
			latest = age
	return latest


func get_total_conditions_possible() -> int:
	return CHRONIC_CONDITIONS.size()


func get_vitality_rating() -> String:
	var avg_age: float = get_avg_colony_age()
	if avg_age < 25.0:
		return "Youthful"
	elif avg_age < 40.0:
		return "Prime"
	elif avg_age < 55.0:
		return "Mature"
	return "Aging"

func get_health_risk_pct() -> float:
	var dist: Dictionary = get_colony_age_distribution()
	var total: int = 0
	var at_risk: int = 0
	for cat: String in dist:
		total += dist[cat]
		if cat == "elderly" or cat == "old":
			at_risk += dist[cat]
	if total == 0:
		return 0.0
	return snappedf(float(at_risk) / float(total) * 100.0, 0.1)

func get_workforce_longevity() -> String:
	var risk: int = get_elderly_risk_count()
	var dist: Dictionary = get_colony_age_distribution()
	var total: int = 0
	for cat: String in dist:
		total += dist[cat]
	if total == 0:
		return "N/A"
	var pct: float = float(risk) / float(total) * 100.0
	if pct < 10.0:
		return "Sustainable"
	elif pct < 30.0:
		return "Transitioning"
	return "At Risk"

func get_summary() -> Dictionary:
	return {
		"age_categories": AGE_THRESHOLDS.size(),
		"chronic_conditions": CHRONIC_CONDITIONS.size(),
		"categories": AGE_THRESHOLDS.keys(),
		"most_penalized": get_most_penalized_category(),
		"avg_chronic_risk": get_avg_chronic_risk(),
		"colony_age_dist": get_colony_age_distribution(),
		"avg_colony_age": get_avg_colony_age(),
		"elderly_risk_count": get_elderly_risk_count(),
		"earliest_condition_age": get_earliest_condition_age(),
		"latest_condition_age": get_latest_condition_age(),
		"total_conditions": get_total_conditions_possible(),
		"vitality_rating": get_vitality_rating(),
		"health_risk_pct": get_health_risk_pct(),
		"workforce_longevity": get_workforce_longevity(),
		"geriatric_care_index": get_geriatric_care_index(),
		"demographic_sustainability": get_demographic_sustainability(),
		"lifespan_governance": get_lifespan_governance(),
	}

func get_geriatric_care_index() -> float:
	var risk_pct := get_health_risk_pct()
	var elderly := get_elderly_risk_count()
	var dist: Dictionary = get_colony_age_distribution()
	var total: int = 0
	for cat: String in dist:
		total += dist[cat]
	if total <= 0:
		return 100.0
	var elderly_ratio := float(elderly) / float(total) * 100.0
	return snapped(maxf(100.0 - risk_pct - elderly_ratio * 0.5, 0.0), 0.1)

func get_demographic_sustainability() -> String:
	var longevity := get_workforce_longevity()
	var vitality := get_vitality_rating()
	if longevity in ["Sustainable"] and vitality in ["Vigorous", "Good"]:
		return "Sustainable"
	elif longevity in ["Sustainable", "Transitioning"]:
		return "Transitioning"
	return "Declining"

func get_lifespan_governance() -> float:
	var care := get_geriatric_care_index()
	var avg_age := get_avg_colony_age()
	var risk := get_health_risk_pct()
	return snapped((care + maxf(100.0 - risk, 0.0) + minf(avg_age * 2.0, 100.0)) / 3.0, 0.1)
