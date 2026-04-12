extends Node

const AGING_HEDIFFS: Dictionary = {
	"BadBack": {"onset_age": 40, "chance_per_year": 0.04, "severity_rate": 0.01},
	"Frailty": {"onset_age": 50, "chance_per_year": 0.05, "severity_rate": 0.015},
	"Cataract": {"onset_age": 45, "chance_per_year": 0.03, "severity_rate": 0.008},
	"Dementia": {"onset_age": 60, "chance_per_year": 0.03, "severity_rate": 0.02},
	"Alzheimers": {"onset_age": 65, "chance_per_year": 0.02, "severity_rate": 0.025},
	"HeartArtery": {"onset_age": 50, "chance_per_year": 0.04, "severity_rate": 0.012},
	"HearingLoss": {"onset_age": 45, "chance_per_year": 0.035, "severity_rate": 0.01},
	"Arthritis": {"onset_age": 40, "chance_per_year": 0.05, "severity_rate": 0.008}
}

const BODY_FUNCTION_DECAY: Dictionary = {
	"Moving": {"decay_start": 50, "rate_per_year": 0.005},
	"Manipulation": {"decay_start": 55, "rate_per_year": 0.004},
	"Sight": {"decay_start": 45, "rate_per_year": 0.003},
	"Hearing": {"decay_start": 45, "rate_per_year": 0.003},
	"Consciousness": {"decay_start": 60, "rate_per_year": 0.006},
	"BloodPumping": {"decay_start": 50, "rate_per_year": 0.004}
}

var _pawn_ages: Dictionary = {}

func set_age(pawn_id: int, age: int) -> void:
	_pawn_ages[pawn_id] = age

func check_aging_events(pawn_id: int) -> Array:
	var age: int = _pawn_ages.get(pawn_id, 20)
	var events: Array = []
	for hediff: String in AGING_HEDIFFS:
		var info: Dictionary = AGING_HEDIFFS[hediff]
		if age >= info["onset_age"] and randf() < info["chance_per_year"]:
			events.append({"hediff": hediff, "severity": info["severity_rate"]})
	return events

func get_function_factor(pawn_id: int, function_name: String) -> float:
	var age: int = _pawn_ages.get(pawn_id, 20)
	if not BODY_FUNCTION_DECAY.has(function_name):
		return 1.0
	var info: Dictionary = BODY_FUNCTION_DECAY[function_name]
	if age < info["decay_start"]:
		return 1.0
	var years_past: int = age - info["decay_start"]
	return maxf(0.3, 1.0 - years_past * info["rate_per_year"])

func get_earliest_onset_hediff() -> String:
	var best: String = ""
	var best_age: int = 999
	for h: String in AGING_HEDIFFS:
		var a: int = int(AGING_HEDIFFS[h].get("onset_age", 999))
		if a < best_age:
			best_age = a
			best = h
	return best


func get_elderly_count(threshold: int = 50) -> int:
	var count: int = 0
	for pid: int in _pawn_ages:
		if int(_pawn_ages[pid]) >= threshold:
			count += 1
	return count


func get_most_vulnerable_function() -> String:
	var worst: String = ""
	var worst_rate: float = 0.0
	for f: String in BODY_FUNCTION_DECAY:
		var r: float = float(BODY_FUNCTION_DECAY[f].get("rate_per_year", 0.0))
		if r > worst_rate:
			worst_rate = r
			worst = f
	return worst


func get_avg_pawn_age() -> float:
	if _pawn_ages.is_empty():
		return 0.0
	var total: float = 0.0
	for pid: int in _pawn_ages:
		total += float(_pawn_ages[pid])
	return total / _pawn_ages.size()


func get_latest_onset_hediff() -> String:
	var best: String = ""
	var best_age: int = 0
	for h: String in AGING_HEDIFFS:
		var onset: int = int(AGING_HEDIFFS[h].get("onset_age", 0))
		if onset > best_age:
			best_age = onset
			best = h
	return best


func get_most_common_hediff_risk() -> String:
	var best: String = ""
	var best_rate: float = 0.0
	for h: String in AGING_HEDIFFS:
		var rate: float = float(AGING_HEDIFFS[h].get("chance_per_year", 0.0))
		if rate > best_rate:
			best_rate = rate
			best = h
	return best


func get_avg_onset_age() -> float:
	if AGING_HEDIFFS.is_empty():
		return 0.0
	var total: float = 0.0
	for h: String in AGING_HEDIFFS:
		total += float(AGING_HEDIFFS[h].get("onset_age", 0))
	return snappedf(total / float(AGING_HEDIFFS.size()), 0.1)

func get_highest_severity_hediff() -> String:
	var best: String = ""
	var best_rate: float = 0.0
	for h: String in AGING_HEDIFFS:
		var r: float = float(AGING_HEDIFFS[h].get("severity_rate", 0.0))
		if r > best_rate:
			best_rate = r
			best = h
	return best

func get_early_decay_function_count() -> int:
	var count: int = 0
	for f: String in BODY_FUNCTION_DECAY:
		if int(BODY_FUNCTION_DECAY[f].get("decay_start", 999)) < 50:
			count += 1
	return count

func get_youth_ratio() -> float:
	if _pawn_ages.is_empty():
		return 0.0
	var young: int = 0
	for pid: int in _pawn_ages:
		if int(_pawn_ages[pid]) < 35:
			young += 1
	return snappedf(float(young) / float(_pawn_ages.size()) * 100.0, 0.1)

func get_risk_score() -> float:
	if _pawn_ages.is_empty():
		return 0.0
	var score: float = 0.0
	for pid: int in _pawn_ages:
		var age: int = int(_pawn_ages[pid])
		for h: String in AGING_HEDIFFS:
			if age >= int(AGING_HEDIFFS[h].get("onset_age", 999)):
				score += float(AGING_HEDIFFS[h].get("chance_per_year", 0.0))
	return snappedf(score, 0.01)

func get_age_bracket() -> String:
	var avg: float = get_avg_pawn_age()
	if avg < 25.0:
		return "Young"
	elif avg < 40.0:
		return "PrimeAge"
	elif avg < 55.0:
		return "MiddleAged"
	return "Elderly"

func get_longevity_outlook() -> String:
	var youth: float = get_youth_ratio()
	var risk: float = get_risk_score()
	if youth >= 60.0 and risk < 3.0:
		return "Promising"
	if youth >= 30.0:
		return "Stable"
	return "Declining"


func get_medical_burden_pct() -> float:
	var elderly: int = get_elderly_count()
	var total: int = _pawn_ages.size()
	if total == 0:
		return 0.0
	return snappedf(float(elderly) / float(total) * 100.0, 0.1)


func get_workforce_vitality() -> String:
	var avg: float = get_avg_pawn_age()
	if avg < 30.0:
		return "Youthful"
	if avg < 45.0:
		return "Prime"
	if avg < 60.0:
		return "Mature"
	return "Aging"


func get_generational_balance() -> String:
	var youth := get_youth_ratio()
	var elderly := float(get_elderly_count())
	var total := float(_pawn_ages.size())
	if total <= 0.0:
		return "Empty"
	var elder_ratio := elderly / total * 100.0
	if youth > 60.0:
		return "Youthful"
	elif elder_ratio > 40.0:
		return "Aging Population"
	return "Balanced"

func get_succession_risk() -> float:
	var elderly := float(get_elderly_count())
	var total := float(_pawn_ages.size())
	if total <= 0.0:
		return 0.0
	return snapped(elderly / total * 100.0, 0.1)

func get_health_longevity_index() -> float:
	var risk := get_risk_score()
	var burden := get_medical_burden_pct()
	return snapped(maxf(100.0 - risk * 10.0 - burden * 0.5, 0.0), 0.1)

func get_summary() -> Dictionary:
	return {
		"aging_hediffs": AGING_HEDIFFS.size(),
		"body_functions": BODY_FUNCTION_DECAY.size(),
		"tracked_pawns": _pawn_ages.size(),
		"elderly": get_elderly_count(),
		"earliest_onset": get_earliest_onset_hediff(),
		"avg_age": snapped(get_avg_pawn_age(), 0.1),
		"latest_onset": get_latest_onset_hediff(),
		"most_common_risk": get_most_common_hediff_risk(),
		"avg_onset_age": get_avg_onset_age(),
		"highest_severity_hediff": get_highest_severity_hediff(),
		"early_decay_functions": get_early_decay_function_count(),
		"youth_ratio_pct": get_youth_ratio(),
		"risk_score": get_risk_score(),
		"age_bracket": get_age_bracket(),
		"longevity_outlook": get_longevity_outlook(),
		"medical_burden_pct": get_medical_burden_pct(),
		"workforce_vitality": get_workforce_vitality(),
		"generational_balance": get_generational_balance(),
		"succession_risk_pct": get_succession_risk(),
		"health_longevity_index": get_health_longevity_index(),
		"demographic_sustainability": get_demographic_sustainability(),
		"aging_preparedness": get_aging_preparedness(),
		"vitality_forecast": get_vitality_forecast(),
		"demographic_ecosystem_health": get_demographic_ecosystem_health(),
		"aging_governance": get_aging_governance(),
		"longevity_maturity_index": get_longevity_maturity_index(),
	}

func get_demographic_sustainability() -> String:
	var youth_pct: float = get_youth_ratio()
	var balance: String = get_generational_balance()
	if youth_pct >= 40.0 and balance == "Balanced":
		return "Sustainable"
	if youth_pct >= 25.0:
		return "Manageable"
	return "At Risk"

func get_aging_preparedness() -> float:
	var medical: float = get_medical_burden_pct()
	var longevity: float = get_health_longevity_index()
	var score: float = longevity * 0.6 + (100.0 - medical) * 0.4
	return snappedf(clampf(score, 0.0, 100.0), 0.1)

func get_vitality_forecast() -> String:
	var vitality: String = get_workforce_vitality()
	var succession: float = get_succession_risk()
	if vitality == "Vigorous" and succession <= 20.0:
		return "Bright"
	if vitality in ["Vigorous", "Steady"]:
		return "Stable"
	return "Concerning"

func get_demographic_ecosystem_health() -> float:
	var preparedness := get_aging_preparedness()
	var sustainability := get_demographic_sustainability()
	var s_val: float = 90.0 if sustainability == "Sustainable" else (60.0 if sustainability == "Stable" else 25.0)
	var longevity := get_health_longevity_index()
	return snapped((preparedness + s_val + longevity) / 3.0, 0.1)

func get_aging_governance() -> String:
	var ecosystem := get_demographic_ecosystem_health()
	var forecast := get_vitality_forecast()
	var f_val: float = 90.0 if forecast == "Bright" else (60.0 if forecast == "Stable" else 25.0)
	var combined := (ecosystem + f_val) / 2.0
	if combined >= 70.0:
		return "Thriving"
	elif combined >= 40.0:
		return "Managed"
	elif _pawn_ages.size() > 0:
		return "Declining"
	return "Unknown"

func get_longevity_maturity_index() -> float:
	var burden := get_medical_burden_pct()
	var succession := get_succession_risk()
	return snapped(((100.0 - burden) + (100.0 - succession)) / 2.0, 0.1)
