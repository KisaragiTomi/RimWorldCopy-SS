extends Node

const CHILDHOODS: Dictionary = {
	"Farmboy": {"skills": {"Plants": 4, "Animals": 2}, "traits": ["HardWorker"], "disabled": []},
	"UrbanChild": {"skills": {"Social": 3, "Intellectual": 2}, "traits": ["Neurotic"], "disabled": []},
	"Urchin": {"skills": {"Melee": 3, "Social": 1}, "traits": ["Tough"], "disabled": []},
	"Scholar": {"skills": {"Intellectual": 5}, "traits": ["TooSmart"], "disabled": ["Mining"]},
	"Soldier": {"skills": {"Shooting": 4, "Melee": 2}, "traits": ["Brave"], "disabled": []},
	"Noble": {"skills": {"Social": 4, "Artistic": 2}, "traits": ["Greedy"], "disabled": ["Mining", "Cleaning"]},
	"Slave": {"skills": {"Mining": 3, "Construction": 2, "Plants": 2}, "traits": ["Depressive"], "disabled": []},
	"Healer": {"skills": {"Medical": 4, "Intellectual": 1}, "traits": ["Kind"], "disabled": []},
	"Tinker": {"skills": {"Crafting": 4, "Construction": 2}, "traits": ["Industrious"], "disabled": []},
	"Wanderer": {"skills": {"Melee": 2, "Animals": 2, "Plants": 1}, "traits": ["Tough"], "disabled": []},
}


func get_childhood(childhood_id: String) -> Dictionary:
	return CHILDHOODS.get(childhood_id, {})


func apply_childhood(pawn_id: int, childhood_id: String) -> Dictionary:
	var data: Dictionary = get_childhood(childhood_id)
	if data.is_empty():
		return {"success": false}
	return {
		"success": true,
		"childhood": childhood_id,
		"skills": data.get("skills", {}),
		"traits": data.get("traits", []),
		"disabled": data.get("disabled", []),
	}


func get_random_childhood() -> String:
	var keys: Array = CHILDHOODS.keys()
	return String(keys[randi() % keys.size()])


func get_childhoods_with_skill(skill: String) -> Array[String]:
	var result: Array[String] = []
	for cid: String in CHILDHOODS:
		var skills: Dictionary = CHILDHOODS[cid].get("skills", {})
		if skills.has(skill):
			result.append(cid)
	return result


func get_childhoods_without_disabled() -> Array[String]:
	var result: Array[String] = []
	for cid: String in CHILDHOODS:
		var disabled: Array = CHILDHOODS[cid].get("disabled", [])
		if disabled.is_empty():
			result.append(cid)
	return result


func get_total_skill_bonus(childhood_id: String) -> int:
	var data: Dictionary = get_childhood(childhood_id)
	var total: int = 0
	for s: String in data.get("skills", {}):
		total += int(data.skills[s])
	return total


func get_best_childhood() -> String:
	var best: String = ""
	var best_bonus: int = -99
	for cid: String in CHILDHOODS:
		var total: int = get_total_skill_bonus(cid)
		if total > best_bonus:
			best_bonus = total
			best = cid
	return best


func get_avg_skill_bonus() -> float:
	if CHILDHOODS.is_empty():
		return 0.0
	var total: int = 0
	for cid: String in CHILDHOODS:
		total += get_total_skill_bonus(cid)
	return snappedf(float(total) / float(CHILDHOODS.size()), 0.1)


func get_restricted_count() -> int:
	return CHILDHOODS.size() - get_childhoods_without_disabled().size()


func get_total_disabled_work_types() -> int:
	var all_disabled: Dictionary = {}
	for cid: String in CHILDHOODS:
		for d in CHILDHOODS[cid].get("disabled", []):
			all_disabled[str(d)] = true
	return all_disabled.size()


func get_skill_coverage() -> Dictionary:
	var coverage: Dictionary = {}
	for cid: String in CHILDHOODS:
		for skill: String in CHILDHOODS[cid].get("skills", {}):
			coverage[skill] = coverage.get(skill, 0) + 1
	return coverage


func get_most_offered_skill() -> String:
	var cov := get_skill_coverage()
	var best: String = ""
	var best_n: int = 0
	for s: String in cov:
		if cov[s] > best_n:
			best_n = cov[s]
			best = s
	return best


func get_talent_pool_rating() -> String:
	var avg: float = get_avg_skill_bonus()
	if avg >= 4.0:
		return "Exceptional"
	elif avg >= 2.0:
		return "Good"
	elif avg > 0.0:
		return "Average"
	return "Poor"

func get_restriction_severity() -> float:
	if CHILDHOODS.is_empty():
		return 0.0
	return snappedf(float(get_restricted_count()) / float(CHILDHOODS.size()) * 100.0, 0.1)

func get_versatility_score() -> String:
	var disabled: int = get_total_disabled_work_types()
	if disabled == 0:
		return "Fully Versatile"
	elif disabled <= 3:
		return "Mostly Versatile"
	elif disabled <= 6:
		return "Partially Restricted"
	return "Heavily Restricted"

func get_summary() -> Dictionary:
	return {
		"childhood_count": CHILDHOODS.size(),
		"no_restrictions": get_childhoods_without_disabled().size(),
		"restricted_count": get_restricted_count(),
		"best_childhood": get_best_childhood(),
		"avg_skill_bonus": get_avg_skill_bonus(),
		"total_disabled_work_types": get_total_disabled_work_types(),
		"skill_coverage": get_skill_coverage(),
		"most_offered_skill": get_most_offered_skill(),
		"talent_pool_rating": get_talent_pool_rating(),
		"restriction_severity_pct": get_restriction_severity(),
		"versatility_score": get_versatility_score(),
		"upbringing_quality": get_upbringing_quality(),
		"workforce_readiness": get_workforce_readiness(),
		"skill_foundation": get_skill_foundation(),
		"childhood_ecosystem_health": get_childhood_ecosystem_health(),
		"talent_pipeline_index": get_talent_pipeline_index(),
		"developmental_governance": get_developmental_governance(),
	}

func get_upbringing_quality() -> String:
	var avg := get_avg_skill_bonus()
	var restricted := get_restricted_count()
	if avg >= 4.0 and restricted <= 2:
		return "Excellent"
	elif avg >= 2.0:
		return "Good"
	return "Limited"

func get_workforce_readiness() -> float:
	var disabled := get_total_disabled_work_types()
	var total_childhoods := CHILDHOODS.size()
	if total_childhoods <= 0:
		return 100.0
	return snapped(maxf(100.0 - float(disabled) / float(total_childhoods) * 10.0, 0.0), 0.1)

func get_skill_foundation() -> String:
	var coverage := get_skill_coverage()
	var most := get_most_offered_skill()
	if coverage.size() >= 5 and most != "":
		return "Broad"
	elif coverage.size() >= 3:
		return "Moderate"
	return "Narrow"

func get_childhood_ecosystem_health() -> float:
	var readiness := get_workforce_readiness()
	var quality := get_upbringing_quality()
	var q_val: float = 90.0 if quality == "Excellent" else (60.0 if quality == "Good" else 30.0)
	var severity := get_restriction_severity()
	return snapped((readiness + q_val + maxf(100.0 - severity, 0.0)) / 3.0, 0.1)

func get_talent_pipeline_index() -> float:
	var avg_bonus := get_avg_skill_bonus()
	var coverage := get_skill_coverage()
	var versatility := get_versatility_score()
	var v_val: float = 90.0 if versatility == "Fully Versatile" else (60.0 if versatility == "Mostly Versatile" else 30.0)
	return snapped((avg_bonus * 15.0 + float(coverage.size()) * 10.0 + v_val) / 3.0, 0.1)

func get_developmental_governance() -> String:
	var health := get_childhood_ecosystem_health()
	var pipeline := get_talent_pipeline_index()
	if health >= 70.0 and pipeline >= 50.0:
		return "Structured"
	elif health >= 40.0 or pipeline >= 25.0:
		return "Emerging"
	return "Unstructured"
