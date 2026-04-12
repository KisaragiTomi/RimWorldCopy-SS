extends Node

## Sorts and filters pawn work assignments based on priority and schedule.
## Registered as autoload "WorkScheduler".

const WORK_TO_JOB_MAP: Dictionary = {
	"Firefighter": "Firefight",
	"Doctor": "TendPatient",
	"Construction": "Construct",
	"Growing": "Sow",
	"Mining": "Mine",
	"Cooking": "Cook",
	"Hunting": "Hunt",
	"Crafting": "Craft",
	"Hauling": "Haul",
	"Cleaning": "Clean",
	"Research": "Research",
	"Handling": "Tame",
	"Warden": "Warden",
	"PlantCutting": "Chop",
}

const EMERGENCY_WORK: PackedStringArray = ["Firefighter", "Doctor"]


func can_do_work(pawn: Pawn, work_type: String) -> bool:
	var priority: int = pawn.get_work_priority(work_type)
	if priority == 0:
		return false

	if ScheduleManager:
		var activity: int = ScheduleManager.get_current_activity(pawn.id)
		if activity == ScheduleManager.Activity.SLEEP:
			return work_type in EMERGENCY_WORK
		if activity == ScheduleManager.Activity.RECREATION:
			return work_type in EMERGENCY_WORK

	return true


func get_sorted_work_types(pawn: Pawn) -> Array[String]:
	var types: Array[Dictionary] = []
	for work_type: String in pawn.work_priorities:
		var p: int = pawn.work_priorities[work_type]
		if p > 0:
			types.append({"name": work_type, "priority": p})

	types.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("priority", 3) < b.get("priority", 3)
	)

	var result: Array[String] = []
	for entry: Dictionary in types:
		result.append(entry.get("name", ""))
	return result


func get_best_job_for_pawn(pawn: Pawn) -> String:
	var sorted := get_sorted_work_types(pawn)
	for work_type: String in sorted:
		if not can_do_work(pawn, work_type):
			continue
		var job_name: String = WORK_TO_JOB_MAP.get(work_type, "")
		if not job_name.is_empty():
			return job_name
	return ""


func get_idle_pawns() -> Array[Pawn]:
	var idle: Array[Pawn] = []
	if not PawnManager:
		return idle
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed or p.drafted:
			continue
		if p.current_job_name == "" or p.current_job_name == "Idle":
			idle.append(p)
	return idle


func get_pawns_doing(work_type: String) -> Array[Pawn]:
	var result: Array[Pawn] = []
	if not PawnManager:
		return result
	var job_name: String = WORK_TO_JOB_MAP.get(work_type, work_type)
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if p.current_job_name == job_name:
			result.append(p)
	return result


func get_work_coverage() -> Dictionary:
	var coverage: Dictionary = {}
	if not PawnManager:
		return coverage
	for work_type: String in WORK_TO_JOB_MAP:
		var count: int = 0
		for p: Pawn in PawnManager.pawns:
			if p.dead or p.downed:
				continue
			if pawn_can_do(p, work_type):
				count += 1
		coverage[work_type] = count
	return coverage


func pawn_can_do(pawn: Pawn, work_type: String) -> bool:
	return pawn.get_work_priority(work_type) > 0


func get_uncovered_work_types() -> Array[String]:
	var cov: Dictionary = get_work_coverage()
	var result: Array[String] = []
	for wt: String in cov:
		if cov[wt] == 0:
			result.append(wt)
	return result


func get_busiest_pawn() -> String:
	if not PawnManager:
		return ""
	var best: String = ""
	var best_c: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var cnt: int = 0
		for wt: String in WORK_TO_JOB_MAP:
			if p.get_work_priority(wt) > 0:
				cnt += 1
		if cnt > best_c:
			best_c = cnt
			best = p.pawn_name
	return best


func get_total_active_workers() -> int:
	if not PawnManager:
		return 0
	var cnt: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed or p.drafted:
			continue
		if not p.current_job_name.is_empty() and p.current_job_name != "Wander":
			cnt += 1
	return cnt


func get_avg_work_types_per_pawn() -> float:
	if not PawnManager:
		return 0.0
	var total: int = 0
	var cnt: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		cnt += 1
		total += get_sorted_work_types(p).size()
	if cnt == 0:
		return 0.0
	return float(total) / float(cnt)


func get_idle_percentage() -> float:
	if not PawnManager:
		return 0.0
	var alive: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			alive += 1
	if alive == 0:
		return 0.0
	return float(get_idle_pawns().size()) / float(alive) * 100.0


func get_coverage_percentage() -> float:
	var cov: Dictionary = get_work_coverage()
	if cov.is_empty():
		return 0.0
	var covered: int = 0
	for wt: String in cov:
		if cov[wt] > 0:
			covered += 1
	return float(covered) / float(cov.size()) * 100.0


func get_overloaded_pawn_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var assigned: int = 0
		for wt: String in p.work_priorities:
			if p.work_priorities[wt] > 0:
				assigned += 1
		if assigned >= 8:
			count += 1
	return count


func get_specialist_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var assigned: int = 0
		for wt: String in p.work_priorities:
			if p.work_priorities[wt] > 0:
				assigned += 1
		if assigned <= 2 and assigned > 0:
			count += 1
	return count


func get_efficiency_rating() -> String:
	var coverage: float = get_coverage_percentage()
	if coverage >= 90.0:
		return "Excellent"
	elif coverage >= 70.0:
		return "Good"
	elif coverage >= 50.0:
		return "Fair"
	return "Poor"


func get_labor_balance() -> String:
	var overloaded := get_overloaded_pawn_count()
	var idle_pct := get_idle_percentage()
	if overloaded > 3 and idle_pct > 20.0:
		return "Polarized"
	elif overloaded > 2:
		return "Top Heavy"
	elif idle_pct > 30.0:
		return "Underemployed"
	return "Balanced"

func get_critical_gap_count() -> int:
	var uncovered: Array = get_uncovered_work_types()
	var critical := 0
	for wt: String in uncovered:
		if wt in ["Doctor", "Firefighter", "Cook", "Haul"]:
			critical += 1
	return critical

func get_workforce_flexibility() -> float:
	var avg := get_avg_work_types_per_pawn()
	var specialists := get_specialist_count()
	var total := get_total_active_workers()
	if total <= 0:
		return 0.0
	var flex := (avg / 5.0) * 60.0 + (1.0 - float(specialists) / float(total)) * 40.0
	return snapped(clampf(flex, 0.0, 100.0), 0.1)

func get_summary() -> Dictionary:
	var result: Dictionary = {}
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.dead:
				continue
			result[p.pawn_name] = get_sorted_work_types(p)
	return {
		"assignments": result,
		"idle_count": get_idle_pawns().size(),
		"coverage": get_work_coverage(),
		"uncovered": get_uncovered_work_types(),
		"busiest_pawn": get_busiest_pawn(),
		"active_workers": get_total_active_workers(),
		"avg_work_types": snappedf(get_avg_work_types_per_pawn(), 0.1),
		"idle_pct": snappedf(get_idle_percentage(), 0.1),
		"coverage_pct": snappedf(get_coverage_percentage(), 0.1),
		"overloaded": get_overloaded_pawn_count(),
		"specialists": get_specialist_count(),
		"efficiency": get_efficiency_rating(),
		"labor_balance": get_labor_balance(),
		"critical_gaps": get_critical_gap_count(),
		"workforce_flexibility": get_workforce_flexibility(),
		"labor_ecosystem_health": get_labor_ecosystem_health(),
		"productivity_potential": get_productivity_potential(),
		"workforce_resilience": get_workforce_resilience(),
	}

func get_labor_ecosystem_health() -> String:
	var gaps: int = get_critical_gap_count()
	var idle_pct: float = get_idle_percentage()
	var coverage: float = get_coverage_percentage()
	if gaps == 0 and idle_pct < 10.0 and coverage >= 90.0:
		return "Optimal"
	if gaps <= 1 and coverage >= 70.0:
		return "Healthy"
	if gaps <= 3:
		return "Strained"
	return "Dysfunctional"

func get_productivity_potential() -> float:
	var idle_pct: float = get_idle_percentage()
	var overloaded: int = get_overloaded_pawn_count()
	var active: int = get_total_active_workers()
	var overload_penalty: float = float(overloaded) / float(maxi(active, 1)) * 30.0
	var score: float = 100.0 - idle_pct - overload_penalty
	return snappedf(clampf(score, 0.0, 100.0), 0.1)

func get_workforce_resilience() -> String:
	var specialists: int = get_specialist_count()
	var active: int = get_total_active_workers()
	var flexibility: float = get_workforce_flexibility()
	if active >= 8 and flexibility >= 70.0:
		return "Resilient"
	if active >= 5:
		return "Moderate"
	if active >= 3:
		return "Fragile"
	return "Critical"
