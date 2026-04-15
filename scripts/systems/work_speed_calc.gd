extends Node

const BASE_SPEED: float = 1.0

const SKILL_SPEED_FACTOR: Dictionary = {
	"Construction": {"skill": "Construction", "per_level": 0.06},
	"Mining": {"skill": "Mining", "per_level": 0.05},
	"Cooking": {"skill": "Cooking", "per_level": 0.04},
	"Crafting": {"skill": "Crafting", "per_level": 0.05},
	"Plants": {"skill": "Plants", "per_level": 0.04},
	"Medicine": {"skill": "Medicine", "per_level": 0.06},
	"Research": {"skill": "Intellectual", "per_level": 0.08},
	"Artistic": {"skill": "Artistic", "per_level": 0.05},
}

const HEALTH_PENALTY: Dictionary = {
	"consciousness": {"weight": 0.5, "threshold": 0.5},
	"manipulation": {"weight": 0.3, "threshold": 0.3},
	"sight": {"weight": 0.2, "threshold": 0.5},
}

const TRAIT_SPEED_BONUS: Dictionary = {
	"Industrious": 1.35,
	"HardWorker": 1.15,
	"Lazy": 0.8,
	"Slothful": 0.6,
}


func calc_work_speed(pawn: Pawn, work_type: String) -> float:
	var speed: float = BASE_SPEED

	var skill_def: Dictionary = SKILL_SPEED_FACTOR.get(work_type, {})
	if not skill_def.is_empty():
		var skill_name: String = skill_def.get("skill", "")
		var per_level: float = skill_def.get("per_level", 0.0)
		if pawn.skills.has(skill_name):
			var level: int = int(pawn.skills[skill_name].get("level", 0))
			speed += float(level) * per_level

	if pawn.traits:
		for t in Array(pawn.traits):
			var t_str: String = str(t)
			if TRAIT_SPEED_BONUS.has(t_str):
				speed *= TRAIT_SPEED_BONUS[t_str]

	if InspirationManager and InspirationManager.has_method("is_inspired"):
		if InspirationManager.is_inspired(pawn.id):
			speed *= 1.5

	return snappedf(clampf(speed, 0.1, 5.0), 0.01)


func get_pawn_all_speeds(pawn: Pawn) -> Dictionary:
	var result: Dictionary = {}
	for work_type: String in SKILL_SPEED_FACTOR:
		result[work_type] = calc_work_speed(pawn, work_type)
	return result


func get_colony_best_for_work(work_type: String) -> Dictionary:
	if not PawnManager:
		return {}
	var best_name: String = ""
	var best_speed: float = 0.0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var speed: float = calc_work_speed(p, work_type)
		if speed > best_speed:
			best_speed = speed
			best_name = p.pawn_name
	if best_name.is_empty():
		return {}
	return {"name": best_name, "speed": best_speed}


func get_colony_avg_speed(work_type: String) -> float:
	if not PawnManager:
		return 0.0
	var total: float = 0.0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		total += calc_work_speed(p, work_type)
		count += 1
	if count == 0:
		return 0.0
	return snappedf(total / float(count), 0.01)


func get_fastest_work_type() -> String:
	if not PawnManager:
		return ""
	var best_type: String = ""
	var best_avg: float = 0.0
	for wt: String in SKILL_SPEED_FACTOR:
		var total: float = 0.0
		var count: int = 0
		for p: Pawn in PawnManager.pawns:
			if p.dead:
				continue
			total += calc_work_speed(p, wt)
			count += 1
		if count > 0:
			var avg: float = total / float(count)
			if avg > best_avg:
				best_avg = avg
				best_type = wt
	return best_type


func get_slowest_work_type() -> String:
	if not PawnManager:
		return ""
	var worst_type: String = ""
	var worst_avg: float = 999.0
	for wt: String in SKILL_SPEED_FACTOR:
		var total: float = 0.0
		var count: int = 0
		for p: Pawn in PawnManager.pawns:
			if p.dead:
				continue
			total += calc_work_speed(p, wt)
			count += 1
		if count > 0:
			var avg: float = total / float(count)
			if avg < worst_avg:
				worst_avg = avg
				worst_type = wt
	return worst_type


func get_total_penalty_types() -> int:
	return HEALTH_PENALTY.size()


func get_modifier_complexity() -> String:
	var total: int = TRAIT_SPEED_BONUS.size() + HEALTH_PENALTY.size()
	if total >= 10:
		return "Complex"
	elif total >= 5:
		return "Moderate"
	elif total > 0:
		return "Simple"
	return "None"

func get_health_impact_ratio() -> float:
	var total: int = TRAIT_SPEED_BONUS.size() + HEALTH_PENALTY.size()
	if total <= 0:
		return 0.0
	return snappedf(float(HEALTH_PENALTY.size()) / float(total) * 100.0, 0.1)

func get_work_type_diversity() -> int:
	return SKILL_SPEED_FACTOR.size()

func get_summary() -> Dictionary:
	return {
		"work_types_with_skill": SKILL_SPEED_FACTOR.size(),
		"trait_modifiers": TRAIT_SPEED_BONUS.size(),
		"health_factors": HEALTH_PENALTY.size(),
		"fastest_work_type": get_fastest_work_type(),
		"slowest_work_type": get_slowest_work_type(),
		"total_modifiers": TRAIT_SPEED_BONUS.size() + HEALTH_PENALTY.size(),
		"speed_range": SKILL_SPEED_FACTOR.size(),
		"modifier_complexity": get_modifier_complexity(),
		"health_impact_ratio_pct": get_health_impact_ratio(),
		"work_type_diversity": get_work_type_diversity(),
		"productivity_potential": get_productivity_potential(),
		"speed_optimization": get_speed_optimization(),
		"efficiency_balance": get_efficiency_balance(),
		"labor_throughput_index": get_labor_throughput_index(),
		"performance_ceiling": get_performance_ceiling(),
		"workflow_maturity": get_workflow_maturity(),
	}

func get_labor_throughput_index() -> float:
	var diversity := float(get_work_type_diversity())
	var total := float(SKILL_SPEED_FACTOR.size())
	if total <= 0.0:
		return 0.0
	return snapped(diversity / total * 100.0, 0.1)

func get_performance_ceiling() -> float:
	var health_impact := get_health_impact_ratio()
	return snapped(100.0 - health_impact, 0.1)

func get_workflow_maturity() -> String:
	var potential := get_productivity_potential()
	var optimization := get_speed_optimization()
	if potential == "High" and optimization == "Well Tuned":
		return "Optimized"
	elif potential == "Limited":
		return "Primitive"
	return "Developing"

func get_productivity_potential() -> String:
	var diversity := get_work_type_diversity()
	if diversity >= 8:
		return "High"
	elif diversity >= 4:
		return "Moderate"
	return "Limited"

func get_speed_optimization() -> String:
	var health_impact := get_health_impact_ratio()
	if health_impact < 10.0:
		return "Optimized"
	elif health_impact < 30.0:
		return "Adequate"
	return "Penalized"

func get_efficiency_balance() -> float:
	var traits := TRAIT_SPEED_BONUS.size()
	var penalties := HEALTH_PENALTY.size()
	if traits + penalties <= 0:
		return 50.0
	return snapped(float(traits) / float(traits + penalties) * 100.0, 0.1)
