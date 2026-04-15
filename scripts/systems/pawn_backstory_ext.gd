extends Node

const CHILDHOOD_BACKSTORIES: Dictionary = {
	"Vatgrown": {"skills": {"Intellectual": 3, "Social": -2}, "work_disabled": [], "desc": "Raised in a vat"},
	"Farmhand": {"skills": {"Plants": 4, "Animals": 2}, "work_disabled": [], "desc": "Grew up on a farm"},
	"StreetUrch": {"skills": {"Melee": 3, "Social": 2}, "work_disabled": ["Intellectual"], "desc": "Survived on the streets"},
	"Noble": {"skills": {"Social": 4, "Intellectual": 2}, "work_disabled": ["Mining", "Cleaning"], "desc": "Born into nobility"},
	"Midworld": {"skills": {"Shooting": 2, "Construction": 2}, "work_disabled": [], "desc": "Middle-class upbringing"},
	"Tribal": {"skills": {"Animals": 3, "Plants": 2, "Melee": 1}, "work_disabled": ["Intellectual"], "desc": "Raised by a tribe"},
	"Slave": {"skills": {"Mining": 3, "Construction": 2}, "work_disabled": [], "desc": "Born into slavery"},
	"Spacer": {"skills": {"Intellectual": 4, "Crafting": 2}, "work_disabled": ["Plants"], "desc": "Grew up on a spaceship"},
	"Cave": {"skills": {"Mining": 4, "Crafting": 1}, "work_disabled": ["Social"], "desc": "Raised underground"},
	"Mechanitor": {"skills": {"Intellectual": 3, "Crafting": 3}, "work_disabled": [], "desc": "Tinkered with machines"}
}

const ADULTHOOD_BACKSTORIES: Dictionary = {
	"Marine": {"skills": {"Shooting": 5, "Melee": 3}, "work_disabled": ["Artistic"], "desc": "Served in the marines"},
	"Doctor": {"skills": {"Medicine": 5, "Intellectual": 3}, "work_disabled": ["Hauling"], "desc": "Practiced medicine"},
	"Engineer": {"skills": {"Construction": 5, "Crafting": 3}, "work_disabled": [], "desc": "Built structures"},
	"Artist": {"skills": {"Artistic": 5, "Crafting": 2}, "work_disabled": ["Hauling", "Cleaning"], "desc": "Created art"},
	"Researcher": {"skills": {"Intellectual": 6}, "work_disabled": ["Plants", "Mining"], "desc": "Conducted research"},
	"Hunter": {"skills": {"Shooting": 4, "Animals": 3}, "work_disabled": [], "desc": "Hunted for a living"},
	"Cook": {"skills": {"Cooking": 5, "Plants": 2}, "work_disabled": [], "desc": "Professional chef"},
	"Trader": {"skills": {"Social": 5, "Crafting": 1}, "work_disabled": ["Mining"], "desc": "Ran trade caravans"},
	"Warden": {"skills": {"Social": 3, "Melee": 3, "Shooting": 2}, "work_disabled": [], "desc": "Managed prisoners"},
	"Farmer": {"skills": {"Plants": 5, "Animals": 3, "Cooking": 1}, "work_disabled": [], "desc": "Worked the land"},
	"Assassin": {"skills": {"Melee": 5, "Shooting": 3}, "work_disabled": ["Social", "Caring"], "desc": "Killed for hire"},
	"Preacher": {"skills": {"Social": 5, "Intellectual": 2}, "work_disabled": ["Violence"], "desc": "Spread the word"}
}

func get_combined_skills(childhood: String, adulthood: String) -> Dictionary:
	var skills: Dictionary = {}
	if CHILDHOOD_BACKSTORIES.has(childhood):
		for sk: String in CHILDHOOD_BACKSTORIES[childhood]["skills"]:
			skills[sk] = skills.get(sk, 0) + CHILDHOOD_BACKSTORIES[childhood]["skills"][sk]
	if ADULTHOOD_BACKSTORIES.has(adulthood):
		for sk: String in ADULTHOOD_BACKSTORIES[adulthood]["skills"]:
			skills[sk] = skills.get(sk, 0) + ADULTHOOD_BACKSTORIES[adulthood]["skills"][sk]
	return skills

func get_best_for_skill(skill: String) -> Dictionary:
	var best_child: String = ""
	var best_adult: String = ""
	var best_cv: int = 0
	var best_av: int = 0
	for c: String in CHILDHOOD_BACKSTORIES:
		var v: int = CHILDHOOD_BACKSTORIES[c]["skills"].get(skill, 0)
		if v > best_cv:
			best_cv = v
			best_child = c
	for a: String in ADULTHOOD_BACKSTORIES:
		var v: int = ADULTHOOD_BACKSTORIES[a]["skills"].get(skill, 0)
		if v > best_av:
			best_av = v
			best_adult = a
	return {"childhood": best_child, "adulthood": best_adult}

func get_no_disability_stories() -> Array[String]:
	var result: Array[String] = []
	for c: String in CHILDHOOD_BACKSTORIES:
		if CHILDHOOD_BACKSTORIES[c]["work_disabled"].is_empty():
			result.append(c)
	return result

func get_all_disabled_work_types() -> Array[String]:
	var types: Array[String] = []
	for c: String in CHILDHOOD_BACKSTORIES:
		for w: String in CHILDHOOD_BACKSTORIES[c]["work_disabled"]:
			if not types.has(w):
				types.append(w)
	for a: String in ADULTHOOD_BACKSTORIES:
		for w: String in ADULTHOOD_BACKSTORIES[a]["work_disabled"]:
			if not types.has(w):
				types.append(w)
	return types

func get_avg_skill_bonus_childhood() -> float:
	var total: float = 0.0
	var count: int = 0
	for c: String in CHILDHOOD_BACKSTORIES:
		for sk: String in CHILDHOOD_BACKSTORIES[c]["skills"]:
			total += CHILDHOOD_BACKSTORIES[c]["skills"][sk]
			count += 1
	if count == 0:
		return 0.0
	return snappedf(total / float(count), 0.01)

func get_most_restricted_adulthood() -> String:
	var worst: String = ""
	var worst_count: int = 0
	for a: String in ADULTHOOD_BACKSTORIES:
		var n: int = ADULTHOOD_BACKSTORIES[a]["work_disabled"].size()
		if n > worst_count:
			worst_count = n
			worst = a
	return worst

func get_total_unique_skills() -> int:
	var skills: Array[String] = []
	for c: String in CHILDHOOD_BACKSTORIES:
		for sk: String in CHILDHOOD_BACKSTORIES[c]["skills"]:
			if not skills.has(sk):
				skills.append(sk)
	for a: String in ADULTHOOD_BACKSTORIES:
		for sk: String in ADULTHOOD_BACKSTORIES[a]["skills"]:
			if not skills.has(sk):
				skills.append(sk)
	return skills.size()

func get_no_disability_adulthood_count() -> int:
	var count: int = 0
	for a: String in ADULTHOOD_BACKSTORIES:
		if ADULTHOOD_BACKSTORIES[a]["work_disabled"].is_empty():
			count += 1
	return count


func get_highest_single_skill_bonus() -> int:
	var best: int = 0
	for c: String in CHILDHOOD_BACKSTORIES:
		for sk: String in CHILDHOOD_BACKSTORIES[c]["skills"]:
			var v: int = int(CHILDHOOD_BACKSTORIES[c]["skills"][sk])
			if v > best:
				best = v
	for a: String in ADULTHOOD_BACKSTORIES:
		for sk: String in ADULTHOOD_BACKSTORIES[a]["skills"]:
			var v: int = int(ADULTHOOD_BACKSTORIES[a]["skills"][sk])
			if v > best:
				best = v
	return best


func get_avg_adulthood_skill_count() -> float:
	if ADULTHOOD_BACKSTORIES.is_empty():
		return 0.0
	var total: int = 0
	for a: String in ADULTHOOD_BACKSTORIES:
		total += ADULTHOOD_BACKSTORIES[a]["skills"].size()
	return float(total) / ADULTHOOD_BACKSTORIES.size()


func get_workforce_versatility() -> float:
	var free_c := 0
	for b in CHILDHOOD_BACKSTORIES.values():
		if b["work_disabled"].size() == 0:
			free_c += 1
	var free_a := 0
	for b in ADULTHOOD_BACKSTORIES.values():
		if b["work_disabled"].size() == 0:
			free_a += 1
	var total := CHILDHOOD_BACKSTORIES.size() + ADULTHOOD_BACKSTORIES.size()
	return snapped(float(free_c + free_a) / maxf(total, 1.0) * 100.0, 0.1)

func get_specialization_depth_pct() -> float:
	var deep := 0
	var total := 0
	for b in CHILDHOOD_BACKSTORIES.values():
		total += 1
		for v in b["skills"].values():
			if v >= 4:
				deep += 1
				break
	for b in ADULTHOOD_BACKSTORIES.values():
		total += 1
		for v in b["skills"].values():
			if v >= 4:
				deep += 1
				break
	return snapped(float(deep) / maxf(total, 1.0) * 100.0, 0.1)

func get_combination_potential() -> int:
	var valid := 0
	for ck in CHILDHOOD_BACKSTORIES.keys():
		var c_dis: Array = CHILDHOOD_BACKSTORIES[ck]["work_disabled"]
		for ak in ADULTHOOD_BACKSTORIES.keys():
			var a_dis: Array = ADULTHOOD_BACKSTORIES[ak]["work_disabled"]
			var conflict := false
			for sk in CHILDHOOD_BACKSTORIES[ck]["skills"].keys():
				if a_dis.has(sk):
					conflict = true
					break
			if not conflict:
				for sk in ADULTHOOD_BACKSTORIES[ak]["skills"].keys():
					if c_dis.has(sk):
						conflict = true
						break
			if not conflict:
				valid += 1
	return valid

func get_summary() -> Dictionary:
	return {
		"childhood_stories": CHILDHOOD_BACKSTORIES.size(),
		"adulthood_stories": ADULTHOOD_BACKSTORIES.size(),
		"no_disability_childhood": get_no_disability_stories().size(),
		"disabled_work_types": get_all_disabled_work_types().size(),
		"avg_skill_bonus_childhood": get_avg_skill_bonus_childhood(),
		"most_restricted_adulthood": get_most_restricted_adulthood(),
		"total_unique_skills": get_total_unique_skills(),
		"no_disability_adulthood": get_no_disability_adulthood_count(),
		"max_single_skill_bonus": get_highest_single_skill_bonus(),
		"avg_adult_skill_count": snapped(get_avg_adulthood_skill_count(), 0.01),
		"workforce_versatility": get_workforce_versatility(),
		"specialization_depth_pct": get_specialization_depth_pct(),
		"combination_potential": get_combination_potential(),
		"talent_pool_quality": get_talent_pool_quality(),
		"career_path_diversity": get_career_path_diversity(),
		"skill_foundation_score": get_skill_foundation_score(),
		"backstory_ecosystem_health": get_backstory_ecosystem_health(),
		"workforce_governance": get_workforce_governance(),
		"recruitment_maturity_index": get_recruitment_maturity_index(),
	}

func get_talent_pool_quality() -> String:
	var versatility := get_workforce_versatility()
	var spec := get_specialization_depth_pct()
	if versatility in ["High", "Exceptional"] and spec >= 50.0:
		return "Elite"
	elif versatility in ["Moderate", "High"]:
		return "Competent"
	return "Limited"

func get_career_path_diversity() -> float:
	var childhood := CHILDHOOD_BACKSTORIES.size()
	var adulthood := ADULTHOOD_BACKSTORIES.size()
	var total := childhood + adulthood
	if total <= 0:
		return 0.0
	var unique_skills := get_total_unique_skills()
	return snapped(float(unique_skills) / float(total) * 100.0, 0.1)

func get_skill_foundation_score() -> float:
	var avg_child := get_avg_skill_bonus_childhood()
	var avg_adult := get_avg_adulthood_skill_count()
	return snapped(avg_child + avg_adult, 0.1)

func get_backstory_ecosystem_health() -> float:
	var quality := get_talent_pool_quality()
	var q_val: float = 90.0 if quality == "Elite" else (60.0 if quality == "Competent" else 30.0)
	var diversity := get_career_path_diversity()
	var foundation := get_skill_foundation_score()
	return snapped((q_val + diversity + minf(foundation * 10.0, 100.0)) / 3.0, 0.1)

func get_recruitment_maturity_index() -> float:
	var versatility := get_workforce_versatility()
	var v_val: float = 90.0 if versatility in ["High", "Exceptional"] else (60.0 if versatility in ["Moderate", "Decent"] else 30.0)
	var spec := get_specialization_depth_pct()
	var potential := get_combination_potential()
	var p_val: float = 90.0 if potential in ["High", "Vast"] else (60.0 if potential in ["Moderate", "Some"] else 30.0)
	return snapped((v_val + spec + p_val) / 3.0, 0.1)

func get_workforce_governance() -> String:
	var ecosystem := get_backstory_ecosystem_health()
	var maturity := get_recruitment_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif ADULTHOOD_BACKSTORIES.size() > 0:
		return "Nascent"
	return "Dormant"
