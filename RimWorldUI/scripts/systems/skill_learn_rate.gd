extends Node

const AGE_FACTOR: Dictionary = {
	"young": {"min": 18, "max": 25, "factor": 1.2},
	"adult": {"min": 26, "max": 40, "factor": 1.0},
	"middle": {"min": 41, "max": 55, "factor": 0.8},
	"old": {"min": 56, "max": 80, "factor": 0.5},
	"elderly": {"min": 81, "max": 999, "factor": 0.3},
}

const TRAIT_LEARNING_BONUS: Dictionary = {
	"FastLearner": 1.5,
	"SlowLearner": 0.5,
	"Neurotic": 1.2,
	"VeryNeurotic": 1.4,
	"TooSmart": 1.3,
}

const PASSION_FACTOR: Dictionary = {
	0: 0.35,
	1: 1.0,
	2: 1.5,
}


func get_age_factor(age: int) -> float:
	for bracket: String in AGE_FACTOR:
		var data: Dictionary = AGE_FACTOR[bracket]
		if age >= data.min and age <= data.max:
			return data.factor
	return 0.5


func get_trait_factor(traits: Array) -> float:
	var factor: float = 1.0
	for t in traits:
		var t_str: String = str(t)
		if TRAIT_LEARNING_BONUS.has(t_str):
			factor *= TRAIT_LEARNING_BONUS[t_str]
	return factor


func get_passion_factor(passion_level: int) -> float:
	return PASSION_FACTOR.get(passion_level, 0.35)


func calc_learn_rate(pawn: Pawn, skill_name: String) -> float:
	var age: int = pawn.age if "age" in pawn else 30
	var age_f: float = get_age_factor(age)

	var trait_f: float = 1.0
	if pawn.traits:
		var trait_arr: Array = Array(pawn.traits)
		trait_f = get_trait_factor(trait_arr)

	var passion: int = 0
	if pawn.skills.has(skill_name):
		var sdata: Dictionary = pawn.skills[skill_name]
		passion = int(sdata.get("passion", 0))
	var passion_f: float = get_passion_factor(passion)

	return snappedf(age_f * trait_f * passion_f, 0.01)


func get_pawn_learn_rates(pawn: Pawn) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not pawn.skills:
		return result
	for skill_name: String in pawn.skills:
		var rate: float = calc_learn_rate(pawn, skill_name)
		result.append({
			"skill": skill_name,
			"learn_rate": rate,
		})
	return result


func get_fastest_learner() -> Dictionary:
	if not PawnManager:
		return {}
	var best_name: String = ""
	var best_avg: float = 0.0
	for p: Pawn in PawnManager.pawns:
		if p.dead or not p.skills:
			continue
		var rates := get_pawn_learn_rates(p)
		if rates.is_empty():
			continue
		var total: float = 0.0
		for r: Dictionary in rates:
			total += r.learn_rate
		var avg: float = total / float(rates.size())
		if avg > best_avg:
			best_avg = avg
			best_name = p.pawn_name
	if best_name.is_empty():
		return {}
	return {"name": best_name, "avg_rate": snappedf(best_avg, 0.01)}


func get_colony_avg_learn_rate() -> float:
	if not PawnManager:
		return 0.0
	var total: float = 0.0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead or not p.skills:
			continue
		var rates := get_pawn_learn_rates(p)
		for r: Dictionary in rates:
			total += r.learn_rate
			count += 1
	if count == 0:
		return 0.0
	return snappedf(total / float(count), 0.01)


func get_age_bracket(age: int) -> String:
	for bracket: String in AGE_FACTOR:
		var data: Dictionary = AGE_FACTOR[bracket]
		if age >= data.min and age <= data.max:
			return bracket
	return "elderly"


func get_slowest_learner() -> Dictionary:
	if not PawnManager:
		return {}
	var worst_name: String = ""
	var worst_rate: float = 999.0
	for p: Pawn in PawnManager.pawns:
		if p.dead or not p.skills:
			continue
		var rates := get_pawn_learn_rates(p)
		var total: float = 0.0
		for r: Dictionary in rates:
			total += r.learn_rate
		var avg: float = total / maxf(float(rates.size()), 1.0)
		if avg < worst_rate:
			worst_rate = avg
			worst_name = p.pawn_name
	if worst_name.is_empty():
		return {}
	return {"name": worst_name, "avg_rate": snappedf(worst_rate, 0.01)}


func get_rate_spread() -> float:
	var fastest := get_fastest_learner()
	var slowest := get_slowest_learner()
	if fastest.is_empty() or slowest.is_empty():
		return 0.0
	return snappedf(fastest.get("avg_rate", 0.0) - slowest.get("avg_rate", 0.0), 0.01)


func get_high_learner_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead or not p.skills:
			continue
		var rates := get_pawn_learn_rates(p)
		var total: float = 0.0
		for r: Dictionary in rates:
			total += r.learn_rate
		if rates.size() > 0 and (total / float(rates.size())) > 1.2:
			count += 1
	return count


func get_learning_health() -> String:
	var avg: float = get_colony_avg_learn_rate()
	if avg >= 1.5:
		return "Exceptional"
	elif avg >= 1.0:
		return "Good"
	elif avg >= 0.7:
		return "Average"
	return "Slow"

func get_talent_gap() -> String:
	var spread: float = get_rate_spread()
	if spread < 0.3:
		return "Uniform"
	elif spread < 0.8:
		return "Moderate"
	return "Wide"

func get_prodigy_ratio() -> float:
	var high: int = get_high_learner_count()
	if AGE_FACTOR.is_empty():
		return 0.0
	return snappedf(float(high) / float(AGE_FACTOR.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"age_brackets": AGE_FACTOR.size(),
		"trait_modifiers": TRAIT_LEARNING_BONUS.size(),
		"passion_levels": PASSION_FACTOR.size(),
		"fastest_learner": get_fastest_learner(),
		"slowest_learner": get_slowest_learner(),
		"colony_avg_rate": get_colony_avg_learn_rate(),
		"rate_spread": get_rate_spread(),
		"high_learners": get_high_learner_count(),
		"high_learner_pct": snappedf(float(get_high_learner_count()) / maxf(float(AGE_FACTOR.size()), 1.0) * 100.0, 0.1),
		"rate_gap": get_rate_spread(),
		"learning_health": get_learning_health(),
		"talent_gap": get_talent_gap(),
		"prodigy_ratio_pct": get_prodigy_ratio(),
		"learning_efficiency": get_learning_efficiency(),
		"education_investment": get_education_investment(),
		"capability_ceiling": get_capability_ceiling(),
		"knowledge_pipeline_health": get_knowledge_pipeline_health(),
		"talent_cultivation_index": get_talent_cultivation_index(),
		"intellectual_capital": get_intellectual_capital(),
	}

func get_knowledge_pipeline_health() -> float:
	var efficiency := get_learning_efficiency()
	var high := float(get_high_learner_count())
	var total := float(AGE_FACTOR.size())
	if total <= 0.0:
		return 0.0
	return snapped((efficiency * 0.6 + high / total * 100.0 * 0.4), 0.1)

func get_talent_cultivation_index() -> float:
	var avg := get_colony_avg_learn_rate()
	var spread := get_rate_spread()
	return snapped(avg * 100.0 - spread * 10.0, 0.1)

func get_intellectual_capital() -> String:
	var ceiling := get_capability_ceiling()
	var investment := get_education_investment()
	if ceiling == "Exceptional" and investment == "Well Invested":
		return "Elite"
	elif ceiling in ["Exceptional", "High"]:
		return "Strong"
	return "Developing"

func get_learning_efficiency() -> float:
	var avg := get_colony_avg_learn_rate()
	return snapped(minf(avg * 100.0, 100.0), 0.1)

func get_education_investment() -> String:
	var high := get_high_learner_count()
	var health := get_learning_health()
	if health in ["Excellent", "Good"] and high >= 3:
		return "Well Invested"
	elif health in ["Excellent", "Good"]:
		return "Adequate"
	return "Under-invested"

func get_capability_ceiling() -> String:
	var prodigy := get_prodigy_ratio()
	var avg := get_colony_avg_learn_rate()
	if prodigy >= 20.0 and avg >= 0.8:
		return "High"
	elif avg >= 0.5:
		return "Moderate"
	return "Limited"
