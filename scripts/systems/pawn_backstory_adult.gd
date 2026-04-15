extends Node

var _pawn_adulthoods: Dictionary = {}

const ADULTHOODS: Dictionary = {
	"Soldier": {"skills": {"Shooting": 6, "Melee": 4}, "disabled_work": [], "traits": ["Tough"]},
	"Scientist": {"skills": {"Intellectual": 8, "Medicine": 3}, "disabled_work": ["Hauling"], "traits": ["Neurotic"]},
	"Farmer": {"skills": {"Plants": 7, "Animals": 4}, "disabled_work": [], "traits": ["GreenThumb"]},
	"Doctor": {"skills": {"Medicine": 8, "Social": 2}, "disabled_work": [], "traits": ["Careful"]},
	"Merchant": {"skills": {"Social": 7, "Crafting": 3}, "disabled_work": ["Mining"], "traits": ["Greedy"]},
	"Miner": {"skills": {"Mining": 8, "Construction": 4}, "disabled_work": [], "traits": ["Tough"]},
	"Artist": {"skills": {"Artistic": 8, "Crafting": 3}, "disabled_work": ["Mining", "Hauling"], "traits": ["Creative"]},
	"Cook": {"skills": {"Cooking": 7, "Plants": 3}, "disabled_work": [], "traits": ["Gourmand"]},
	"Criminal": {"skills": {"Melee": 5, "Social": 4, "Shooting": 3}, "disabled_work": ["Firefighting"], "traits": ["Psychopath"]},
	"Builder": {"skills": {"Construction": 8, "Crafting": 4}, "disabled_work": [], "traits": ["Industrious"]},
	"Nurse": {"skills": {"Medicine": 5, "Social": 4}, "disabled_work": ["Mining"], "traits": ["Kind"]},
	"Warden": {"skills": {"Social": 6, "Melee": 3, "Shooting": 2}, "disabled_work": [], "traits": ["Steadfast"]}
}

func assign_adulthood(pawn_id: int, backstory: String) -> bool:
	if not ADULTHOODS.has(backstory):
		return false
	_pawn_adulthoods[pawn_id] = backstory
	return true

func get_adulthood(pawn_id: int) -> String:
	return _pawn_adulthoods.get(pawn_id, "")

func get_skill_bonuses(pawn_id: int) -> Dictionary:
	var bs: String = _pawn_adulthoods.get(pawn_id, "")
	if bs == "":
		return {}
	return ADULTHOODS[bs].get("skills", {})

func get_disabled_work(pawn_id: int) -> Array:
	var bs: String = _pawn_adulthoods.get(pawn_id, "")
	if bs == "":
		return []
	return ADULTHOODS[bs].get("disabled_work", [])

func get_random_adulthood() -> String:
	var keys: Array = ADULTHOODS.keys()
	return keys[randi() % keys.size()]

func get_backstory_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pid: int in _pawn_adulthoods:
		var bs: String = String(_pawn_adulthoods[pid])
		dist[bs] = dist.get(bs, 0) + 1
	return dist


func get_backstories_with_skill(skill: String) -> Array[String]:
	var result: Array[String] = []
	for bs: String in ADULTHOODS:
		if ADULTHOODS[bs].get("skills", {}).has(skill):
			result.append(bs)
	return result


func get_no_restriction_backstories() -> Array[String]:
	var result: Array[String] = []
	for bs: String in ADULTHOODS:
		if ADULTHOODS[bs].get("disabled_work", []).is_empty():
			result.append(bs)
	return result


func get_most_common_adulthood() -> String:
	var dist: Dictionary = get_backstory_distribution()
	var best: String = ""
	var best_count: int = 0
	for bs: String in dist:
		if int(dist[bs]) > best_count:
			best_count = int(dist[bs])
			best = bs
	return best


func get_highest_skill_backstory() -> String:
	var best: String = ""
	var best_total: int = 0
	for bs: String in ADULTHOODS:
		var total: int = 0
		for skill: String in ADULTHOODS[bs].get("skills", {}):
			total += int(ADULTHOODS[bs]["skills"][skill])
		if total > best_total:
			best_total = total
			best = bs
	return best


func get_total_disabled_work_types() -> int:
	var count: int = 0
	for bs: String in ADULTHOODS:
		count += ADULTHOODS[bs].get("disabled_work", []).size()
	return count


func get_avg_skill_total() -> float:
	if ADULTHOODS.is_empty():
		return 0.0
	var total: float = 0.0
	for bs: String in ADULTHOODS:
		var skills: Dictionary = ADULTHOODS[bs].get("skills", {})
		for s: String in skills:
			total += float(skills[s])
	return snappedf(total / float(ADULTHOODS.size()), 0.1)


func get_no_restriction_count() -> int:
	return get_no_restriction_backstories().size()


func get_unique_trait_count() -> int:
	var traits: Dictionary = {}
	for bs: String in ADULTHOODS:
		for t in ADULTHOODS[bs].get("traits", []):
			traits[String(t)] = true
	return traits.size()


func get_workforce_flexibility() -> String:
	if ADULTHOODS.is_empty():
		return "N/A"
	var pct: float = float(get_no_restriction_count()) / float(ADULTHOODS.size()) * 100.0
	if pct >= 70.0:
		return "Flexible"
	elif pct >= 40.0:
		return "Moderate"
	elif pct >= 10.0:
		return "Restricted"
	return "Rigid"

func get_skill_richness() -> String:
	var avg: float = get_avg_skill_total()
	if avg >= 15.0:
		return "Exceptional"
	elif avg >= 10.0:
		return "Skilled"
	elif avg >= 5.0:
		return "Average"
	return "Low"

func get_backstory_diversity_pct() -> float:
	var dist: Dictionary = get_backstory_distribution()
	if _pawn_adulthoods.is_empty() or ADULTHOODS.is_empty():
		return 0.0
	return snappedf(float(dist.size()) / float(ADULTHOODS.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"adulthood_types": ADULTHOODS.size(),
		"assigned_pawns": _pawn_adulthoods.size(),
		"distribution": get_backstory_distribution(),
		"most_common": get_most_common_adulthood(),
		"highest_skill": get_highest_skill_backstory(),
		"total_disabled": get_total_disabled_work_types(),
		"avg_skill_total": get_avg_skill_total(),
		"no_restriction_count": get_no_restriction_count(),
		"unique_traits": get_unique_trait_count(),
		"workforce_flexibility": get_workforce_flexibility(),
		"skill_richness": get_skill_richness(),
		"backstory_diversity_pct": get_backstory_diversity_pct(),
		"career_depth": get_career_depth(),
		"professional_balance": get_professional_balance(),
		"talent_density": get_talent_density(),
		"background_ecosystem_health": get_background_ecosystem_health(),
		"workforce_governance": get_workforce_governance(),
		"career_maturity_index": get_career_maturity_index(),
	}

func get_career_depth() -> String:
	var unique := get_unique_trait_count()
	var avg := get_avg_skill_total()
	if unique >= 5 and avg >= 8.0:
		return "Deep"
	elif unique >= 3:
		return "Moderate"
	return "Shallow"

func get_professional_balance() -> float:
	var no_restrict := get_no_restriction_count()
	var total := ADULTHOODS.size()
	if total <= 0:
		return 0.0
	return snapped(float(no_restrict) / float(total) * 100.0, 0.1)

func get_talent_density() -> String:
	var richness := get_skill_richness()
	var flexibility := get_workforce_flexibility()
	if richness in ["Rich", "Exceptional"] and flexibility in ["Flexible", "Very Flexible"]:
		return "Dense"
	elif richness in ["Moderate", "Rich"]:
		return "Moderate"
	return "Sparse"

func get_background_ecosystem_health() -> float:
	var depth := get_career_depth()
	var d_val: float = 90.0 if depth in ["Deep", "Extensive"] else (60.0 if depth == "Moderate" else 30.0)
	var balance := get_professional_balance()
	var density := get_talent_density()
	var t_val: float = 90.0 if density == "Dense" else (60.0 if density == "Moderate" else 30.0)
	return snapped((d_val + balance + t_val) / 3.0, 0.1)

func get_career_maturity_index() -> float:
	var richness := get_skill_richness()
	var r_val: float = 90.0 if richness in ["Rich", "Exceptional"] else (60.0 if richness == "Moderate" else 30.0)
	var flexibility := get_workforce_flexibility()
	var f_val: float = 90.0 if flexibility in ["Flexible", "Very Flexible"] else (60.0 if flexibility == "Moderate" else 30.0)
	var diversity := get_backstory_diversity_pct()
	return snapped((r_val + f_val + diversity) / 3.0, 0.1)

func get_workforce_governance() -> String:
	var ecosystem := get_background_ecosystem_health()
	var maturity := get_career_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _pawn_adulthoods.size() > 0:
		return "Nascent"
	return "Dormant"
