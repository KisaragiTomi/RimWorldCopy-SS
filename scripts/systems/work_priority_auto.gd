extends Node

const WORK_SKILL_MAP: Dictionary = {
	"Doctor": "Medical",
	"Cook": "Cooking",
	"Hunt": "Shooting",
	"Construct": "Construction",
	"Grow": "Plants",
	"Mine": "Mining",
	"Smith": "Crafting",
	"Tailor": "Crafting",
	"Art": "Artistic",
	"Research": "Intellectual",
	"Haul": "",
	"Clean": "",
	"Handle": "Animals",
	"Warden": "Social",
}


func auto_assign_priorities(pawn_skills: Dictionary) -> Dictionary:
	var priorities: Dictionary = {}
	var skill_ranks: Array = []
	for work: String in WORK_SKILL_MAP:
		var skill_name: String = WORK_SKILL_MAP[work]
		var level: int = 0
		if not skill_name.is_empty() and pawn_skills.has(skill_name):
			level = int(pawn_skills[skill_name])
		skill_ranks.append({"work": work, "level": level})
	skill_ranks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.level) > int(b.level))
	for i: int in range(skill_ranks.size()):
		var entry: Dictionary = skill_ranks[i]
		var prio: int = 4
		if i < 3:
			prio = 1
		elif i < 6:
			prio = 2
		elif i < 10:
			prio = 3
		priorities[entry.work] = prio
	return priorities


func get_skilled_works() -> Array[String]:
	var result: Array[String] = []
	for work: String in WORK_SKILL_MAP:
		if not String(WORK_SKILL_MAP[work]).is_empty():
			result.append(work)
	return result


func get_unskilled_works() -> Array[String]:
	var result: Array[String] = []
	for work: String in WORK_SKILL_MAP:
		if String(WORK_SKILL_MAP[work]).is_empty():
			result.append(work)
	return result


func get_work_for_skill(skill: String) -> Array[String]:
	var result: Array[String] = []
	for work: String in WORK_SKILL_MAP:
		if WORK_SKILL_MAP[work] == skill:
			result.append(work)
	return result


func get_unique_skills_used() -> int:
	var skills: Dictionary = {}
	for work: String in WORK_SKILL_MAP:
		var s: String = String(WORK_SKILL_MAP[work])
		if not s.is_empty():
			skills[s] = true
	return skills.size()


func get_most_skill_intensive() -> String:
	var skill_counts: Dictionary = {}
	for work: String in WORK_SKILL_MAP:
		var s: String = String(WORK_SKILL_MAP[work])
		if not s.is_empty():
			skill_counts[s] = skill_counts.get(s, 0) + 1
	var best: String = ""
	var best_n: int = 0
	for s: String in skill_counts:
		if skill_counts[s] > best_n:
			best_n = skill_counts[s]
			best = s
	return best


func get_skill_coverage_pct() -> float:
	if WORK_SKILL_MAP.is_empty():
		return 0.0
	return snappedf(float(get_skilled_works().size()) / float(WORK_SKILL_MAP.size()) * 100.0, 0.1)


func get_multi_work_skill_count() -> int:
	var skill_counts: Dictionary = {}
	for work: String in WORK_SKILL_MAP:
		var s: String = String(WORK_SKILL_MAP[work])
		if not s.is_empty():
			skill_counts[s] = skill_counts.get(s, 0) + 1
	var count: int = 0
	for s: String in skill_counts:
		if int(skill_counts[s]) > 1:
			count += 1
	return count


func get_skill_to_work_ratio() -> float:
	if WORK_SKILL_MAP.is_empty():
		return 0.0
	return snappedf(float(get_unique_skills_used()) / float(WORK_SKILL_MAP.size()), 0.01)


func get_unskilled_pct() -> float:
	if WORK_SKILL_MAP.is_empty():
		return 0.0
	return snappedf(float(get_unskilled_works().size()) / float(WORK_SKILL_MAP.size()) * 100.0, 0.1)


func get_workforce_readiness() -> String:
	var coverage: float = get_skill_coverage_pct()
	if coverage >= 90.0:
		return "Ready"
	elif coverage >= 70.0:
		return "Adequate"
	elif coverage >= 40.0:
		return "Gaps"
	return "Critical Shortage"

func get_automation_potential() -> float:
	if WORK_SKILL_MAP.is_empty():
		return 0.0
	return snappedf(float(get_multi_work_skill_count()) / float(WORK_SKILL_MAP.size()) * 100.0, 0.1)

func get_specialization_level() -> String:
	var ratio: float = get_skill_to_work_ratio()
	if ratio >= 2.0:
		return "Highly Specialized"
	elif ratio >= 1.0:
		return "Balanced"
	elif ratio > 0.0:
		return "Generalist"
	return "None"

func get_summary() -> Dictionary:
	return {
		"work_types": WORK_SKILL_MAP.size(),
		"skilled_works": get_skilled_works().size(),
		"unskilled_works": get_unskilled_works().size(),
		"unique_skills": get_unique_skills_used(),
		"most_demanded_skill": get_most_skill_intensive(),
		"skill_coverage_pct": get_skill_coverage_pct(),
		"multi_work_skills": get_multi_work_skill_count(),
		"skill_to_work_ratio": get_skill_to_work_ratio(),
		"unskilled_pct": get_unskilled_pct(),
		"workforce_readiness": get_workforce_readiness(),
		"automation_potential_pct": get_automation_potential(),
		"specialization_level": get_specialization_level(),
		"labor_allocation_efficiency": get_labor_allocation_efficiency(),
		"skill_utilization_index": get_skill_utilization_index(),
		"workforce_flexibility": get_workforce_flexibility(),
		"labor_ecosystem_health": get_labor_ecosystem_health(),
		"human_resource_governance": get_human_resource_governance(),
		"productivity_maturity_index": get_productivity_maturity_index(),
	}

func get_labor_allocation_efficiency() -> float:
	var coverage := get_skill_coverage_pct()
	var unskilled := get_unskilled_pct()
	return snapped(maxf(coverage - unskilled, 0.0), 0.1)

func get_skill_utilization_index() -> String:
	var unique := get_unique_skills_used()
	var total := WORK_SKILL_MAP.size()
	if total <= 0:
		return "N/A"
	var pct := float(unique) / float(total) * 100.0
	if pct >= 80.0:
		return "Full Utilization"
	elif pct >= 50.0:
		return "Partial"
	return "Underutilized"

func get_workforce_flexibility() -> String:
	var multi := get_multi_work_skill_count()
	var total := WORK_SKILL_MAP.size()
	if total <= 0:
		return "N/A"
	if float(multi) / float(total) >= 0.5:
		return "Highly Flexible"
	elif multi > 0:
		return "Moderate"
	return "Rigid"

func get_labor_ecosystem_health() -> float:
	var allocation := get_labor_allocation_efficiency()
	var utilization := get_skill_utilization_index()
	var u_val: float = 90.0 if utilization == "Full" else (70.0 if utilization == "Partial" else 30.0)
	var flexibility := get_workforce_flexibility()
	var f_val: float = 90.0 if flexibility == "Highly Flexible" else (60.0 if flexibility == "Moderate" else 30.0)
	return snapped((allocation + u_val + f_val) / 3.0, 0.1)

func get_human_resource_governance() -> String:
	var health := get_labor_ecosystem_health()
	var readiness := get_workforce_readiness()
	if health >= 65.0 and readiness in ["Ready", "Strong"]:
		return "Optimized"
	elif health >= 35.0:
		return "Developing"
	return "Disorganized"

func get_productivity_maturity_index() -> float:
	var coverage := get_skill_coverage_pct()
	var specialization := get_specialization_level()
	var s_val: float = 90.0 if specialization == "Specialized" else (60.0 if specialization == "Partial" else 30.0)
	return snapped((coverage + s_val) / 2.0, 0.1)
