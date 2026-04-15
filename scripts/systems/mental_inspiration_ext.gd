extends Node

const INSPIRATIONS: Dictionary = {
	"ShootFrenzy": {"skill": "Shooting", "multiplier": 2.0, "duration_hours": 8, "desc": "Incredible shooting focus"},
	"GoFrenzy": {"skill": "Melee", "multiplier": 2.0, "duration_hours": 8, "desc": "Devastating melee power"},
	"Inspired_Trade": {"skill": "Social", "multiplier": 1.5, "duration_hours": 12, "desc": "Silver tongue activated"},
	"Inspired_Art": {"skill": "Artistic", "multiplier": 3.0, "duration_hours": 8, "desc": "Artistic masterpiece incoming"},
	"Inspired_Med": {"skill": "Medical", "multiplier": 2.0, "duration_hours": 6, "desc": "Surgical precision"},
	"Inspired_Cook": {"skill": "Cooking", "multiplier": 2.0, "duration_hours": 8, "desc": "Culinary genius"},
	"Inspired_Craft": {"skill": "Crafting", "multiplier": 2.0, "duration_hours": 8, "desc": "Crafting perfection"},
	"Inspired_Research": {"skill": "Intellectual", "multiplier": 2.5, "duration_hours": 10, "desc": "Eureka moment"},
	"Inspired_Tame": {"skill": "Animals", "multiplier": 5.0, "duration_hours": 6, "desc": "Animal whisperer"},
	"Inspired_Recruit": {"skill": "Social", "multiplier": 4.0, "duration_hours": 6, "desc": "Persuasion mastery"},
}

var _active: Dictionary = {}


func trigger_inspiration(pawn_id: int, insp_id: String) -> Dictionary:
	if not INSPIRATIONS.has(insp_id):
		return {"success": false, "reason": "Unknown inspiration"}
	var data: Dictionary = INSPIRATIONS[insp_id]
	var dur_ticks: int = int(data.duration_hours) * 2500
	_active[pawn_id] = {
		"id": insp_id,
		"skill": data.skill,
		"multiplier": data.multiplier,
		"expires_tick": (TickManager.current_tick if TickManager else 0) + dur_ticks,
	}
	if EventLetter and EventLetter.has_method("send_letter"):
		EventLetter.send_letter("Inspiration!", data.desc, 0)
	return {"success": true, "inspiration": insp_id, "duration_hours": data.duration_hours}


func get_active_inspiration(pawn_id: int) -> Dictionary:
	if not _active.has(pawn_id):
		return {}
	var current_tick: int = TickManager.current_tick if TickManager else 0
	var info: Dictionary = _active[pawn_id]
	if current_tick > int(info.get("expires_tick", 0)):
		_active.erase(pawn_id)
		return {}
	return info


func get_skill_multiplier(pawn_id: int, skill: String) -> float:
	var info: Dictionary = get_active_inspiration(pawn_id)
	if info.is_empty():
		return 1.0
	if String(info.get("skill", "")) == skill:
		return float(info.get("multiplier", 1.0))
	return 1.0


func get_active_list() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var current_tick: int = TickManager.current_tick if TickManager else 0
	for pid: int in _active:
		var info: Dictionary = _active[pid]
		if current_tick <= int(info.get("expires_tick", 0)):
			result.append({"pawn_id": pid, "id": info.id, "skill": info.skill, "multiplier": info.multiplier})
	return result


func get_strongest_active() -> Dictionary:
	var best: Dictionary = {}
	var best_mult: float = 0.0
	var current_tick: int = TickManager.current_tick if TickManager else 0
	for pid: int in _active:
		var info: Dictionary = _active[pid]
		if current_tick <= int(info.get("expires_tick", 0)):
			if info.multiplier > best_mult:
				best_mult = info.multiplier
				best = {"pawn_id": pid, "id": info.id, "multiplier": info.multiplier}
	return best


func get_inspirations_for_skill(skill: String) -> Array[String]:
	var result: Array[String] = []
	for insp_id: String in INSPIRATIONS:
		if INSPIRATIONS[insp_id].skill == skill:
			result.append(insp_id)
	return result


func get_avg_multiplier() -> float:
	var active_list := get_active_list()
	if active_list.is_empty():
		return 0.0
	var total: float = 0.0
	for a: Dictionary in active_list:
		total += a.get("multiplier", 1.0)
	return snappedf(total / float(active_list.size()), 0.01)


func get_most_common_inspiration() -> String:
	var counts: Dictionary = {}
	for pid: int in _active:
		var insp_id: String = str(_active[pid].get("id", ""))
		counts[insp_id] = counts.get(insp_id, 0) + 1
	var best: String = ""
	var best_n: int = 0
	for i: String in counts:
		if counts[i] > best_n:
			best_n = counts[i]
			best = i
	return best


func get_skills_covered() -> int:
	var skills: Dictionary = {}
	for insp_id: String in INSPIRATIONS:
		skills[INSPIRATIONS[insp_id].skill] = true
	return skills.size()


func get_active_type_count() -> int:
	var types: Dictionary = {}
	var active_list := get_active_list()
	for a: Dictionary in active_list:
		types[a.get("id", "")] = true
	return types.size()


func get_pawn_coverage_pct() -> float:
	if not PawnManager:
		return 0.0
	var alive: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			alive += 1
	if alive == 0:
		return 0.0
	return snappedf(float(get_active_list().size()) / float(alive) * 100.0, 0.1)


func get_inspirations_per_skill_dist() -> Dictionary:
	var dist: Dictionary = {}
	for insp_id: String in INSPIRATIONS:
		var skill: String = INSPIRATIONS[insp_id].skill
		dist[skill] = dist.get(skill, 0) + 1
	return dist


func get_inspiration_potency() -> String:
	var avg: float = get_avg_multiplier()
	if avg >= 2.0:
		return "Powerful"
	elif avg >= 1.5:
		return "Moderate"
	elif avg > 1.0:
		return "Mild"
	return "None"

func get_type_saturation_pct() -> float:
	if INSPIRATIONS.is_empty():
		return 0.0
	return snappedf(float(get_active_type_count()) / float(INSPIRATIONS.size()) * 100.0, 0.1)

func get_burst_potential() -> String:
	var coverage: float = get_pawn_coverage_pct()
	if coverage >= 50.0:
		return "High"
	elif coverage >= 20.0:
		return "Moderate"
	elif coverage > 0.0:
		return "Low"
	return "None"

func get_summary() -> Dictionary:
	return {
		"inspiration_types": INSPIRATIONS.size(),
		"active_count": _active.size(),
		"active_list": get_active_list(),
		"strongest": get_strongest_active(),
		"avg_multiplier": get_avg_multiplier(),
		"most_common": get_most_common_inspiration(),
		"skills_covered": get_skills_covered(),
		"active_unique_types": get_active_type_count(),
		"pawn_coverage_pct": get_pawn_coverage_pct(),
		"per_skill_dist": get_inspirations_per_skill_dist(),
		"inspiration_potency": get_inspiration_potency(),
		"type_saturation_pct": get_type_saturation_pct(),
		"burst_potential": get_burst_potential(),
		"inspiration_ecosystem_health": get_inspiration_ecosystem_health(),
		"creative_momentum_index": get_creative_momentum_index(),
		"talent_catalysis_score": get_talent_catalysis_score(),
	}

func get_inspiration_ecosystem_health() -> float:
	var saturation := get_type_saturation_pct()
	var coverage := get_pawn_coverage_pct()
	var potency := get_inspiration_potency()
	var potency_val: float = 90.0 if potency == "Powerful" else (60.0 if potency == "Moderate" else 30.0)
	return snapped((saturation + coverage + potency_val) / 3.0, 0.1)

func get_creative_momentum_index() -> float:
	var active := _active.size()
	var types := get_active_type_count()
	var avg_mult := get_avg_multiplier()
	return snapped((float(active) * 15.0 + float(types) * 20.0 + avg_mult * 30.0) / 3.0, 0.1)

func get_talent_catalysis_score() -> String:
	var health := get_inspiration_ecosystem_health()
	var momentum := get_creative_momentum_index()
	if health >= 60.0 and momentum >= 50.0:
		return "Catalytic"
	elif health >= 30.0 or momentum >= 25.0:
		return "Emerging"
	elif _active.size() > 0:
		return "Latent"
	return "Dormant"
