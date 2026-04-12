extends Node

const TRAINERS: Dictionary = {
	"ShootingTrainer": {"skill": "Shooting", "xp_gain": 4000, "market_value": 200},
	"MeleeTrainer": {"skill": "Melee", "xp_gain": 4000, "market_value": 200},
	"ConstructionTrainer": {"skill": "Construction", "xp_gain": 4000, "market_value": 200},
	"MiningTrainer": {"skill": "Mining", "xp_gain": 4000, "market_value": 200},
	"CookingTrainer": {"skill": "Cooking", "xp_gain": 4000, "market_value": 200},
	"PlantsTrainer": {"skill": "Plants", "xp_gain": 4000, "market_value": 200},
	"AnimalsTrainer": {"skill": "Animals", "xp_gain": 4000, "market_value": 200},
	"CraftingTrainer": {"skill": "Crafting", "xp_gain": 4000, "market_value": 200},
	"ArtisticTrainer": {"skill": "Artistic", "xp_gain": 4000, "market_value": 200},
	"MedicalTrainer": {"skill": "Medical", "xp_gain": 4000, "market_value": 200},
	"SocialTrainer": {"skill": "Social", "xp_gain": 4000, "market_value": 200},
	"IntellectualTrainer": {"skill": "Intellectual", "xp_gain": 4000, "market_value": 200},
}

var _usage_log: Array = []
var _usage_by_skill: Dictionary = {}
var _usage_by_pawn: Dictionary = {}


func use_trainer(pawn_id: int, trainer_id: String) -> Dictionary:
	if not TRAINERS.has(trainer_id):
		return {"success": false, "reason": "Unknown trainer"}
	var data: Dictionary = TRAINERS[trainer_id]
	_usage_log.append({
		"pawn_id": pawn_id,
		"trainer": trainer_id,
		"skill": data.skill,
		"xp": data.xp_gain,
		"tick": TickManager.current_tick if TickManager else 0,
	})
	_usage_by_skill[data.skill] = _usage_by_skill.get(data.skill, 0) + 1
	_usage_by_pawn[pawn_id] = _usage_by_pawn.get(pawn_id, 0) + 1
	if ColonyLog and ColonyLog.has_method("add_entry"):
		ColonyLog.add_entry("Training", "Pawn " + str(pawn_id) + " used " + trainer_id, "info")
	return {"success": true, "skill": data.skill, "xp_gained": data.xp_gain}


func get_most_trained_skill() -> String:
	var best: String = ""
	var best_count: int = 0
	for s: String in _usage_by_skill:
		if _usage_by_skill[s] > best_count:
			best_count = _usage_by_skill[s]
			best = s
	return best


func get_total_xp_granted() -> int:
	return _usage_log.size() * 4000


func get_most_active_pawn() -> int:
	var best_id: int = -1
	var best_count: int = 0
	for pid: int in _usage_by_pawn:
		if _usage_by_pawn[pid] > best_count:
			best_count = _usage_by_pawn[pid]
			best_id = pid
	return best_id


func get_avg_xp_per_use() -> float:
	if _usage_log.is_empty():
		return 0.0
	return snappedf(float(get_total_xp_granted()) / float(_usage_log.size()), 0.1)


func get_unique_pawns_trained() -> int:
	return _usage_by_pawn.size()


func get_training_coverage_pct() -> float:
	if not PawnManager:
		return 0.0
	var alive: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			alive += 1
	if alive == 0:
		return 0.0
	return snappedf(float(_usage_by_pawn.size()) / float(alive) * 100.0, 0.1)


func get_unique_skills_trained() -> int:
	return _usage_by_skill.size()


func get_avg_uses_per_pawn() -> float:
	if _usage_by_pawn.is_empty():
		return 0.0
	var total: int = 0
	for pid: int in _usage_by_pawn:
		total += int(_usage_by_pawn[pid])
	return snappedf(float(total) / float(_usage_by_pawn.size()), 0.1)


func get_training_intensity() -> String:
	var avg: float = get_avg_uses_per_pawn()
	if avg >= 5.0:
		return "Intensive"
	elif avg >= 2.0:
		return "Active"
	elif avg > 0.0:
		return "Light"
	return "None"

func get_skill_focus_pct() -> float:
	if _usage_by_skill.is_empty():
		return 0.0
	var max_uses: int = 0
	var total: int = 0
	for skill: String in _usage_by_skill:
		var c: int = _usage_by_skill[skill]
		total += c
		if c > max_uses:
			max_uses = c
	if total == 0:
		return 0.0
	return snappedf(float(max_uses) / float(total) * 100.0, 0.1)

func get_xp_efficiency() -> String:
	var avg: float = get_avg_xp_per_use()
	if avg >= 200.0:
		return "Excellent"
	elif avg >= 100.0:
		return "Good"
	elif avg > 0.0:
		return "Low"
	return "None"

func get_summary() -> Dictionary:
	return {
		"trainer_types": TRAINERS.size(),
		"total_uses": _usage_log.size(),
		"total_xp": get_total_xp_granted(),
		"by_skill": _usage_by_skill.duplicate(),
		"most_trained": get_most_trained_skill(),
		"most_active_pawn": get_most_active_pawn(),
		"avg_xp_per_use": get_avg_xp_per_use(),
		"unique_pawns": get_unique_pawns_trained(),
		"training_coverage_pct": get_training_coverage_pct(),
		"unique_skills_trained": get_unique_skills_trained(),
		"avg_uses_per_pawn": get_avg_uses_per_pawn(),
		"training_intensity": get_training_intensity(),
		"skill_focus_pct": get_skill_focus_pct(),
		"xp_efficiency": get_xp_efficiency(),
		"training_roi": get_training_roi(),
		"skill_breadth": get_skill_breadth(),
		"mastery_trajectory": get_mastery_trajectory(),
		"training_ecosystem_health": get_training_ecosystem_health(),
		"skill_cultivation_index": get_skill_cultivation_index(),
		"workforce_development_maturity": get_workforce_development_maturity(),
	}

func get_training_roi() -> String:
	var efficiency := get_xp_efficiency()
	var coverage := get_training_coverage_pct()
	if efficiency in ["Excellent"] and coverage >= 50.0:
		return "High"
	elif efficiency in ["Good", "Excellent"]:
		return "Moderate"
	return "Low"

func get_skill_breadth() -> float:
	var unique_skills := get_unique_skills_trained()
	var total_available := TRAINERS.size()
	if total_available <= 0:
		return 0.0
	return snapped(float(unique_skills) / float(total_available) * 100.0, 0.1)

func get_mastery_trajectory() -> String:
	var intensity := get_training_intensity()
	var focus := get_skill_focus_pct()
	if intensity in ["Intense", "Heavy"] and focus >= 50.0:
		return "Specializing"
	elif intensity in ["Moderate", "Heavy"]:
		return "Broadening"
	elif _usage_log.size() > 0:
		return "Dabbling"
	return "Inactive"

func get_training_ecosystem_health() -> float:
	var breadth := get_skill_breadth()
	var coverage := get_training_coverage_pct()
	var roi := get_training_roi()
	var roi_val: float = 90.0 if roi == "High" else (60.0 if roi == "Moderate" else 30.0)
	return snapped((breadth + coverage + roi_val) / 3.0, 0.1)

func get_skill_cultivation_index() -> float:
	var avg_xp := get_avg_xp_per_use()
	var unique := get_unique_skills_trained()
	var intensity := get_training_intensity()
	var intensity_val: float = 80.0 if intensity in ["Intense", "Heavy"] else (50.0 if intensity == "Moderate" else 20.0)
	return snapped((avg_xp * 0.5 + float(unique) * 10.0 + intensity_val) / 3.0, 0.1)

func get_workforce_development_maturity() -> String:
	var ecosystem := get_training_ecosystem_health()
	var cultivation := get_skill_cultivation_index()
	if ecosystem >= 70.0 and cultivation >= 60.0:
		return "Mature"
	elif ecosystem >= 40.0 or cultivation >= 30.0:
		return "Developing"
	elif _usage_log.size() > 0:
		return "Nascent"
	return "Dormant"
