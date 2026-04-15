extends Node

var _training_levels: Dictionary = {}

const TRAINING_SKILLS: Dictionary = {
	"Obedience": {"decay_per_day": 0.02, "min_level": 0.0, "max_level": 1.0},
	"Release": {"decay_per_day": 0.03, "min_level": 0.0, "max_level": 1.0},
	"Rescue": {"decay_per_day": 0.025, "min_level": 0.0, "max_level": 1.0},
	"Haul": {"decay_per_day": 0.02, "min_level": 0.0, "max_level": 1.0},
	"Guard": {"decay_per_day": 0.035, "min_level": 0.0, "max_level": 1.0}
}

const WILDNESS_DECAY_MULT: Dictionary = {
	"Low": 0.5,
	"Medium": 1.0,
	"High": 1.5,
	"Extreme": 2.5
}

func set_training(animal_id: int, skill: String, level: float) -> void:
	if not _training_levels.has(animal_id):
		_training_levels[animal_id] = {}
	_training_levels[animal_id][skill] = clampf(level, 0.0, 1.0)

func train(animal_id: int, skill: String, amount: float) -> Dictionary:
	if not TRAINING_SKILLS.has(skill):
		return {"error": "unknown_skill"}
	if not _training_levels.has(animal_id):
		_training_levels[animal_id] = {}
	var current: float = _training_levels[animal_id].get(skill, 0.0)
	var new_val: float = minf(current + amount, 1.0)
	_training_levels[animal_id][skill] = new_val
	return {"skill": skill, "old": current, "new_level": new_val}

func advance_day(wildness_category: String) -> Dictionary:
	var mult: float = WILDNESS_DECAY_MULT.get(wildness_category, 1.0)
	var decayed: int = 0
	for aid: int in _training_levels:
		for skill: String in _training_levels[aid]:
			var decay: float = TRAINING_SKILLS.get(skill, {}).get("decay_per_day", 0.02) * mult
			_training_levels[aid][skill] = maxf(0.0, _training_levels[aid][skill] - decay)
			decayed += 1
	return {"decayed_entries": decayed, "wildness_mult": mult}

func get_fastest_decaying_skill() -> String:
	var best: String = ""
	var best_rate: float = 0.0
	for s: String in TRAINING_SKILLS:
		var r: float = float(TRAINING_SKILLS[s].get("decay_per_day", 0.0))
		if r > best_rate:
			best_rate = r
			best = s
	return best


func get_fully_trained_count() -> int:
	var count: int = 0
	for aid: int in _training_levels:
		var all_max: bool = true
		for skill: String in TRAINING_SKILLS:
			if float(_training_levels[aid].get(skill, 0.0)) < 1.0:
				all_max = false
				break
		if all_max:
			count += 1
	return count


func get_untrained_count() -> int:
	var count: int = 0
	for aid: int in _training_levels:
		var has_any: bool = false
		for skill: String in _training_levels[aid]:
			if float(_training_levels[aid][skill]) > 0.0:
				has_any = true
				break
		if not has_any:
			count += 1
	return count


func get_avg_training_level() -> float:
	if _training_levels.is_empty():
		return 0.0
	var total: float = 0.0
	var count: int = 0
	for aid: int in _training_levels:
		for skill: String in _training_levels[aid]:
			total += float(_training_levels[aid][skill])
			count += 1
	if count == 0:
		return 0.0
	return total / count


func get_fully_untrained_count() -> int:
	var count: int = 0
	for aid: int in _training_levels:
		var any_trained: bool = false
		for skill: String in _training_levels[aid]:
			if float(_training_levels[aid][skill]) > 0.0:
				any_trained = true
				break
		if not any_trained:
			count += 1
	return count


func get_slowest_decaying_skill() -> String:
	var best: String = ""
	var best_rate: float = 999999.0
	for s: String in TRAINING_SKILLS:
		var rate: float = float(TRAINING_SKILLS[s].get("decay_per_day", 999999.0))
		if rate < best_rate:
			best_rate = rate
			best = s
	return best


func get_avg_decay_rate() -> float:
	if TRAINING_SKILLS.is_empty():
		return 0.0
	var total: float = 0.0
	for s: String in TRAINING_SKILLS:
		total += float(TRAINING_SKILLS[s].get("decay_per_day", 0.0))
	return snappedf(total / float(TRAINING_SKILLS.size()), 0.001)


func get_partially_trained_count() -> int:
	var count: int = 0
	for aid: int in _training_levels:
		var has_any: bool = false
		var all_max: bool = true
		for skill: String in TRAINING_SKILLS:
			var lvl: float = float(_training_levels[aid].get(skill, 0.0))
			if lvl > 0.0:
				has_any = true
			if lvl < 1.0:
				all_max = false
		if has_any and not all_max:
			count += 1
	return count


func get_extreme_wildness_mult() -> float:
	return WILDNESS_DECAY_MULT.get("Extreme", 0.0)


func get_decay_spread() -> float:
	var mn: float = 999.0
	var mx: float = 0.0
	for s: String in TRAINING_SKILLS:
		var r: float = float(TRAINING_SKILLS[s].get("decay_per_day", 0.0))
		mn = minf(mn, r)
		mx = maxf(mx, r)
	return snappedf(mx - mn, 0.001)

func get_combat_skill_count() -> int:
	var combat_skills: Array[String] = ["Release", "Guard"]
	var count: int = 0
	for s: String in TRAINING_SKILLS:
		if s in combat_skills:
			count += 1
	return count

func get_low_wildness_mult() -> float:
	return WILDNESS_DECAY_MULT.get("Low", 0.0)

func get_training_coverage() -> float:
	if _training_levels.is_empty() or TRAINING_SKILLS.is_empty():
		return 0.0
	var total_slots: int = _training_levels.size() * TRAINING_SKILLS.size()
	var trained_slots: int = 0
	for aid: int in _training_levels:
		for skill: String in TRAINING_SKILLS:
			if float(_training_levels[aid].get(skill, 0.0)) > 0.0:
				trained_slots += 1
	return snappedf(float(trained_slots) / float(total_slots) * 100.0, 0.1)

func get_at_risk_count() -> int:
	var count: int = 0
	for aid: int in _training_levels:
		for skill: String in _training_levels[aid]:
			if float(_training_levels[aid][skill]) > 0.0 and float(_training_levels[aid][skill]) < 0.15:
				count += 1
				break
	return count

func get_best_trained_animal_level() -> float:
	var best: float = 0.0
	for aid: int in _training_levels:
		var total: float = 0.0
		for skill: String in _training_levels[aid]:
			total += float(_training_levels[aid][skill])
		if total > best:
			best = total
	return snappedf(best, 0.01)

func get_training_maturity() -> String:
	var fully: int = get_fully_trained_count()
	var total: int = _training_levels.size()
	if total == 0:
		return "NoData"
	var ratio: float = float(fully) / float(total)
	if ratio >= 0.7:
		return "Mature"
	if ratio >= 0.3:
		return "Developing"
	return "Early"


func get_decay_resilience_pct() -> float:
	var safe: int = 0
	for aid: int in _training_levels:
		var levels: Dictionary = _training_levels[aid]
		var avg: float = 0.0
		for skill: String in levels:
			avg += float(levels[skill])
		avg /= maxf(float(levels.size()), 1.0)
		if avg >= 0.6:
			safe += 1
	return snappedf(float(safe) / maxf(float(_training_levels.size()), 1.0) * 100.0, 0.1)


func get_skill_balance() -> String:
	if TRAINING_SKILLS.is_empty():
		return "NoData"
	var combat: int = get_combat_skill_count()
	var utility: int = TRAINING_SKILLS.size() - combat
	if combat == 0 and utility == 0:
		return "Empty"
	var diff: float = absf(float(combat) - float(utility)) / float(TRAINING_SKILLS.size())
	if diff <= 0.2:
		return "Balanced"
	if combat > utility:
		return "CombatHeavy"
	return "UtilityHeavy"


func get_summary() -> Dictionary:
	return {
		"training_skills": TRAINING_SKILLS.size(),
		"wildness_categories": WILDNESS_DECAY_MULT.size(),
		"tracked_animals": _training_levels.size(),
		"fully_trained": get_fully_trained_count(),
		"fastest_decay": get_fastest_decaying_skill(),
		"avg_level": snapped(get_avg_training_level(), 0.01),
		"untrained": get_fully_untrained_count(),
		"slowest_decay": get_slowest_decaying_skill(),
		"avg_decay_rate": get_avg_decay_rate(),
		"partially_trained": get_partially_trained_count(),
		"extreme_wildness_mult": get_extreme_wildness_mult(),
		"decay_spread": get_decay_spread(),
		"combat_skills": get_combat_skill_count(),
		"low_wildness_mult": get_low_wildness_mult(),
		"training_coverage_pct": get_training_coverage(),
		"at_risk_count": get_at_risk_count(),
		"best_animal_level": get_best_trained_animal_level(),
		"training_maturity": get_training_maturity(),
		"decay_resilience_pct": get_decay_resilience_pct(),
		"skill_balance": get_skill_balance(),
		"training_roi": get_training_roi(),
		"skill_retention_outlook": get_skill_retention_outlook(),
		"domestication_index": get_domestication_index(),
		"animal_ecosystem_health": get_animal_ecosystem_health(),
		"husbandry_governance": get_husbandry_governance(),
		"domestication_maturity_index": get_domestication_maturity_index(),
	}

func get_training_roi() -> float:
	var fully: int = get_fully_trained_count()
	var total: int = _training_levels.size()
	if total == 0:
		return 0.0
	var avg_level: float = get_avg_training_level()
	var resilience: float = get_decay_resilience_pct()
	return snappedf(avg_level * 30.0 + resilience * 0.5 + float(fully) / float(total) * 20.0, 0.1)

func get_skill_retention_outlook() -> String:
	var resilience: float = get_decay_resilience_pct()
	var at_risk: int = get_at_risk_count()
	if resilience >= 70.0 and at_risk <= 1:
		return "Excellent"
	if resilience >= 40.0:
		return "Stable"
	return "Declining"

func get_domestication_index() -> float:
	var fully: int = get_fully_trained_count()
	var partial: int = get_partially_trained_count()
	var total: int = _training_levels.size()
	if total == 0:
		return 0.0
	var score: float = (float(fully) * 2.0 + float(partial)) / float(total) * 50.0
	return snappedf(clampf(score, 0.0, 100.0), 0.1)

func get_animal_ecosystem_health() -> float:
	var resilience := get_decay_resilience_pct()
	var maturity := get_training_maturity()
	var m_val: float = 90.0 if maturity == "Excellent" else (60.0 if maturity == "Stable" else 25.0)
	var domestication := get_domestication_index()
	return snapped((resilience + m_val + domestication) / 3.0, 0.1)

func get_husbandry_governance() -> String:
	var ecosystem := get_animal_ecosystem_health()
	var retention := get_skill_retention_outlook()
	var r_val: float = 90.0 if retention == "Excellent" else (60.0 if retention == "Stable" else 25.0)
	var combined := (ecosystem + r_val) / 2.0
	if combined >= 70.0:
		return "Masterful"
	elif combined >= 40.0:
		return "Competent"
	elif _training_levels.size() > 0:
		return "Struggling"
	return "None"

func get_domestication_maturity_index() -> float:
	var roi := get_training_roi()
	var roi_val: float = minf(roi, 100.0)
	var balance := get_skill_balance()
	var b_val: float = 90.0 if balance == "Balanced" else (60.0 if balance == "Moderate" else 25.0)
	return snapped((roi_val + b_val) / 2.0, 0.1)
