extends Node

var _pawn_passions: Dictionary = {}

const PASSION_NONE: int = 0
const PASSION_MINOR: int = 1
const PASSION_MAJOR: int = 2

const PASSION_XP_MULT: Dictionary = {
	0: 0.35,
	1: 1.0,
	2: 1.5
}

const PASSION_JOY_RATE: Dictionary = {
	0: 0.0,
	1: 0.001,
	2: 0.002
}

const ALL_SKILLS: Array = [
	"Shooting", "Melee", "Construction", "Mining", "Cooking",
	"Plants", "Animals", "Crafting", "Artistic", "Medicine",
	"Social", "Intellectual"
]

func set_passion(pawn_id: int, skill: String, passion_level: int) -> bool:
	if skill not in ALL_SKILLS:
		return false
	if passion_level < 0 or passion_level > 2:
		return false
	if not _pawn_passions.has(pawn_id):
		_pawn_passions[pawn_id] = {}
	_pawn_passions[pawn_id][skill] = passion_level
	return true

func get_passion(pawn_id: int, skill: String) -> int:
	return _pawn_passions.get(pawn_id, {}).get(skill, PASSION_NONE)

func get_xp_multiplier(pawn_id: int, skill: String) -> float:
	var passion: int = get_passion(pawn_id, skill)
	return PASSION_XP_MULT.get(passion, 0.35)

func get_joy_from_work(pawn_id: int, skill: String) -> float:
	var passion: int = get_passion(pawn_id, skill)
	return PASSION_JOY_RATE.get(passion, 0.0)

func randomize_passions(pawn_id: int) -> Dictionary:
	var result: Dictionary = {}
	for skill: String in ALL_SKILLS:
		var roll: float = randf()
		var passion: int = PASSION_NONE
		if roll < 0.10:
			passion = PASSION_MAJOR
		elif roll < 0.30:
			passion = PASSION_MINOR
		set_passion(pawn_id, skill, passion)
		result[skill] = passion
	return result

func get_major_passion_count(pawn_id: int) -> int:
	var count: int = 0
	var passions: Dictionary = _pawn_passions.get(pawn_id, {})
	for skill: String in passions:
		if int(passions[skill]) == PASSION_MAJOR:
			count += 1
	return count


func get_most_passionate_pawn() -> Dictionary:
	var best_id: int = -1
	var best_total: int = 0
	for pid: int in _pawn_passions:
		var total: int = 0
		for skill: String in _pawn_passions[pid]:
			total += int(_pawn_passions[pid][skill])
		if total > best_total:
			best_total = total
			best_id = pid
	if best_id < 0:
		return {}
	return {"pawn_id": best_id, "passion_total": best_total}


func get_passion_distribution() -> Dictionary:
	var dist: Dictionary = {0: 0, 1: 0, 2: 0}
	for pid: int in _pawn_passions:
		for skill: String in _pawn_passions[pid]:
			var lvl: int = int(_pawn_passions[pid][skill])
			dist[lvl] = int(dist.get(lvl, 0)) + 1
	return dist


func get_colony_major_passion_count() -> int:
	var count: int = 0
	for pid: int in _pawn_passions:
		for skill: String in _pawn_passions[pid]:
			if int(_pawn_passions[pid][skill]) == PASSION_MAJOR:
				count += 1
	return count


func get_no_passion_count() -> int:
	var count: int = 0
	for pid: int in _pawn_passions:
		for skill: String in _pawn_passions[pid]:
			if int(_pawn_passions[pid][skill]) == PASSION_NONE:
				count += 1
	return count


func get_passion_coverage() -> float:
	var total_skills: int = 0
	var passionate: int = 0
	for pid: int in _pawn_passions:
		for skill: String in _pawn_passions[pid]:
			total_skills += 1
			if int(_pawn_passions[pid][skill]) > PASSION_NONE:
				passionate += 1
	if total_skills == 0:
		return 0.0
	return snappedf(float(passionate) / float(total_skills) * 100.0, 0.1)


func get_talent_rating() -> String:
	var coverage: float = get_passion_coverage()
	if coverage >= 60.0:
		return "Talented"
	elif coverage >= 30.0:
		return "Average"
	elif coverage > 0.0:
		return "Limited"
	return "None"

func get_specialist_ratio() -> float:
	if _pawn_passions.is_empty():
		return 0.0
	var specialists: int = 0
	for pid: int in _pawn_passions:
		var major: int = 0
		for skill: String in _pawn_passions[pid]:
			if _pawn_passions[pid][skill] == 2:
				major += 1
		if major >= 2:
			specialists += 1
	return snappedf(float(specialists) / float(_pawn_passions.size()) * 100.0, 0.1)

func get_growth_potential() -> String:
	var majors: int = get_colony_major_passion_count()
	if majors >= _pawn_passions.size() * 2:
		return "High"
	elif majors >= _pawn_passions.size():
		return "Moderate"
	elif majors > 0:
		return "Low"
	return "None"

func get_summary() -> Dictionary:
	return {
		"tracked_pawns": _pawn_passions.size(),
		"skill_count": ALL_SKILLS.size(),
		"passion_levels": PASSION_XP_MULT.size(),
		"most_passionate": get_most_passionate_pawn(),
		"distribution": get_passion_distribution(),
		"major_passions": get_colony_major_passion_count(),
		"passion_coverage_pct": get_passion_coverage(),
		"no_passion_count": get_no_passion_count(),
		"avg_passions_per_pawn": snappedf(float(get_colony_major_passion_count() + get_no_passion_count()) / maxf(float(_pawn_passions.size()), 1.0), 0.1),
		"talent_rating": get_talent_rating(),
		"specialist_ratio_pct": get_specialist_ratio(),
		"growth_potential": get_growth_potential(),
		"talent_density": get_talent_density(),
		"skill_synergy": get_skill_synergy(),
		"specialization_index": get_specialization_index(),
		"workforce_readiness": get_workforce_readiness(),
		"passion_momentum": get_passion_momentum(),
		"colony_expertise_depth": get_colony_expertise_depth(),
		"talent_ecosystem_health": get_talent_ecosystem_health(),
		"skill_governance": get_skill_governance(),
		"human_potential_index": get_human_potential_index(),
	}

func get_workforce_readiness() -> String:
	var coverage := get_passion_coverage()
	var talent := get_talent_rating()
	if coverage >= 80.0 and talent in ["Exceptional", "Outstanding"]:
		return "Elite"
	elif coverage >= 50.0:
		return "Capable"
	return "Developing"

func get_passion_momentum() -> float:
	var majors := get_colony_major_passion_count()
	var total := _pawn_passions.size() * ALL_SKILLS.size()
	if total <= 0:
		return 0.0
	return snapped(float(majors) / float(total) * 100.0, 0.1)

func get_colony_expertise_depth() -> String:
	var specialist := get_specialist_ratio()
	if specialist >= 30.0:
		return "Deep"
	elif specialist >= 15.0:
		return "Moderate"
	return "Shallow"

func get_talent_density() -> float:
	if _pawn_passions.is_empty():
		return 0.0
	var total_major: int = get_colony_major_passion_count()
	return snapped(float(total_major) / float(_pawn_passions.size()), 0.1)

func get_skill_synergy() -> String:
	var coverage := get_passion_coverage()
	var specialist := get_specialist_ratio()
	if coverage >= 70.0 and specialist >= 30.0:
		return "Synergistic"
	elif coverage >= 40.0:
		return "Functional"
	return "Fragmented"

func get_specialization_index() -> String:
	var talent := get_talent_rating()
	var growth := get_growth_potential()
	if talent in ["Gifted", "Excellent"] and growth in ["High", "Excellent"]:
		return "Elite"
	elif talent in ["Gifted", "Excellent"]:
		return "Specialized"
	elif growth in ["High", "Excellent"]:
		return "Developing"
	return "Generalist"

func get_talent_ecosystem_health() -> float:
	var density := get_talent_density()
	var d_val: float = minf(density * 50.0, 100.0)
	var synergy := get_skill_synergy()
	var s_val: float = 90.0 if synergy == "Synergistic" else (60.0 if synergy == "Functional" else 25.0)
	var coverage := get_passion_coverage()
	return snapped((d_val + s_val + coverage) / 3.0, 0.1)

func get_skill_governance() -> String:
	var ecosystem := get_talent_ecosystem_health()
	var readiness := get_workforce_readiness()
	var r_val: float = 90.0 if readiness == "Battle Ready" else (60.0 if readiness == "Capable" else 25.0)
	var combined := (ecosystem + r_val) / 2.0
	if combined >= 70.0:
		return "Masterful"
	elif combined >= 40.0:
		return "Competent"
	elif _pawn_passions.size() > 0:
		return "Developing"
	return "Untrained"

func get_human_potential_index() -> float:
	var spec := get_specialization_index()
	var sp_val: float = 90.0 if spec == "Elite" else (70.0 if spec == "Specialized" else (50.0 if spec == "Developing" else 25.0))
	var momentum := get_passion_momentum()
	var m_val: float = minf(momentum * 2.0, 100.0)
	return snapped((sp_val + m_val) / 2.0, 0.1)
