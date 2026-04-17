extends Node

## Detects idle colonists (those without a job for extended periods) and
## alerts the player. Registered as autoload "IdleDetector".

const IDLE_THRESHOLD_TICKS: int = 600
const CHECK_INTERVAL: int = 10

var _idle_ticks: Dictionary = {}  # pawn_id -> ticks_idle
var _idle_alerts: Array[Dictionary] = []
var _check_counter: int = 0
var total_idle_alerts: int = 0
var _longest_idle: int = 0
var _longest_idle_pawn: String = ""


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func _on_rare_tick(_tick: int) -> void:
	_update_idle_status()


func _update_idle_status() -> void:
	if not PawnManager:
		return

	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed or p.drafted or p.is_in_mental_break():
			_idle_ticks.erase(p.id)
			continue

		var is_idle := p.current_job_name.is_empty() or p.current_job_name == "Wander"

		if is_idle:
			_idle_ticks[p.id] = _idle_ticks.get(p.id, 0) + CHECK_INTERVAL
		else:
			_idle_ticks.erase(p.id)

		if _idle_ticks.get(p.id, 0) >= IDLE_THRESHOLD_TICKS:
			_report_idle(p)


func _report_idle(pawn: Pawn) -> void:
	for alert: Dictionary in _idle_alerts:
		if alert.get("pawn_id", -1) == pawn.id:
			return

	total_idle_alerts += 1
	var idle_t: int = _idle_ticks.get(pawn.id, 0)
	if idle_t > _longest_idle:
		_longest_idle = idle_t
		_longest_idle_pawn = pawn.pawn_name

	_idle_alerts.append({
		"pawn_id": pawn.id,
		"pawn_name": pawn.pawn_name,
		"idle_ticks": idle_t,
	})

	if _idle_alerts.size() > 20:
		_idle_alerts = _idle_alerts.slice(-10)


func get_idle_pawns() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not PawnManager:
		return result

	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var ticks: int = _idle_ticks.get(p.id, 0)
		if ticks >= IDLE_THRESHOLD_TICKS:
			result.append({
				"pawn_id": p.id,
				"pawn_name": p.pawn_name,
				"idle_ticks": ticks,
				"current_job": p.current_job_name,
			})
	return result


func is_idle(pawn_id: int) -> bool:
	return _idle_ticks.get(pawn_id, 0) >= IDLE_THRESHOLD_TICKS


func get_idle_count() -> int:
	var count := 0
	for pid: int in _idle_ticks:
		if _idle_ticks[pid] >= IDLE_THRESHOLD_TICKS:
			count += 1
	return count


func get_avg_idle_time() -> float:
	if _idle_ticks.is_empty():
		return 0.0
	var total: int = 0
	for pid: int in _idle_ticks:
		total += _idle_ticks[pid]
	return float(total) / float(_idle_ticks.size())


func get_most_idle_pawn() -> Dictionary:
	var best_id: int = -1
	var best_ticks: int = 0
	for pid: int in _idle_ticks:
		if _idle_ticks[pid] > best_ticks:
			best_ticks = _idle_ticks[pid]
			best_id = pid
	if best_id < 0:
		return {}
	var name_str: String = ""
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.id == best_id:
				name_str = p.pawn_name
				break
	return {"pawn_id": best_id, "name": name_str, "idle_ticks": best_ticks}


func get_idle_percentage() -> float:
	if not PawnManager or PawnManager.pawns.is_empty():
		return 0.0
	var alive: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			alive += 1
	if alive == 0:
		return 0.0
	return snappedf(float(get_idle_count()) / float(alive) * 100.0, 0.1)


func get_never_idle_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if not _idle_ticks.has(p.id) or _idle_ticks[p.id] == 0:
			count += 1
	return count


func has_idle_problem() -> bool:
	return get_idle_count() >= 3 or get_idle_percentage() > 30.0


func get_workforce_efficiency() -> float:
	return snappedf(100.0 - get_idle_percentage(), 0.1)

func get_idle_severity() -> String:
	var pct: float = get_idle_percentage()
	if pct == 0.0:
		return "None"
	elif pct < 15.0:
		return "Mild"
	elif pct < 30.0:
		return "Moderate"
	return "Severe"

func get_productivity_rating() -> String:
	var eff: float = get_workforce_efficiency()
	if eff >= 90.0:
		return "Excellent"
	elif eff >= 70.0:
		return "Good"
	elif eff >= 50.0:
		return "Fair"
	return "Poor"

func get_task_allocation_health() -> String:
	var idle := get_idle_percentage()
	var problem := has_idle_problem()
	if not problem and idle < 5.0:
		return "Optimal"
	elif idle < 15.0:
		return "Good"
	elif problem:
		return "Poor"
	return "Fair"

func get_economic_loss_index() -> float:
	var idle_pct := get_idle_percentage()
	return snapped(idle_pct * 0.5, 0.1)

func get_automation_opportunity() -> String:
	var idle := get_idle_count()
	if idle >= 5:
		return "High"
	elif idle >= 2:
		return "Moderate"
	return "Low"

func get_summary() -> Dictionary:
	return {
		"idle_count": get_idle_count(),
		"tracked_pawns": _idle_ticks.size(),
		"total_idle_alerts": total_idle_alerts,
		"longest_idle": _longest_idle,
		"longest_idle_pawn": _longest_idle_pawn,
		"idle_pawns": get_idle_pawns(),
		"idle_pct": get_idle_percentage(),
		"never_idle": get_never_idle_count(),
		"has_problem": has_idle_problem(),
		"avg_idle_ticks": snappedf(float(_longest_idle) / maxf(float(_idle_ticks.size()), 1.0), 0.1),
		"alert_per_pawn": snappedf(float(total_idle_alerts) / maxf(float(_idle_ticks.size()), 1.0), 0.01),
		"workforce_efficiency": get_workforce_efficiency(),
		"idle_severity": get_idle_severity(),
		"productivity_rating": get_productivity_rating(),
		"task_allocation_health": get_task_allocation_health(),
		"economic_loss_index": get_economic_loss_index(),
		"automation_opportunity": get_automation_opportunity(),
		"labor_utilization_pct": get_labor_utilization_pct(),
		"workforce_optimization_score": get_workforce_optimization_score(),
		"operational_tempo": get_operational_tempo(),
		"idle_ecosystem_health": get_idle_ecosystem_health(),
		"task_governance": get_task_governance(),
		"operational_maturity_index": get_operational_maturity_index(),
	}

func get_labor_utilization_pct() -> float:
	var idle := get_idle_count()
	var total := _idle_ticks.size()
	if total <= 0:
		return 100.0
	return snappedf((1.0 - float(idle) / float(total)) * 100.0, 0.1)

func get_workforce_optimization_score() -> float:
	var efficiency := get_workforce_efficiency()
	var e_val: float = 1.0 if efficiency in ["Optimal", "High"] else (0.6 if efficiency in ["Good", "Adequate"] else 0.3)
	var never_idle := get_never_idle_count()
	return snapped(e_val * float(never_idle) / maxf(float(_idle_ticks.size()), 1.0) * 100.0, 0.1)

func get_operational_tempo() -> String:
	var idle_pct := get_idle_percentage()
	if idle_pct <= 5.0:
		return "High Tempo"
	elif idle_pct <= 20.0:
		return "Active"
	elif idle_pct <= 40.0:
		return "Moderate"
	return "Sluggish"

func get_idle_ecosystem_health() -> float:
	var utilization := get_labor_utilization_pct()
	var optimization := get_workforce_optimization_score()
	var tempo := get_operational_tempo()
	var t_val: float = 90.0 if tempo == "High Tempo" else (70.0 if tempo == "Active" else (40.0 if tempo == "Moderate" else 20.0))
	return snapped((utilization + optimization + t_val) / 3.0, 0.1)

func get_task_governance() -> String:
	var health := get_idle_ecosystem_health()
	var allocation := get_task_allocation_health()
	if health >= 65.0 and allocation in ["Healthy", "Excellent"]:
		return "Optimized"
	elif health >= 35.0:
		return "Functional"
	return "Wasteful"

func get_operational_maturity_index() -> float:
	var productivity := get_productivity_rating()
	var p_val: float = 90.0 if productivity in ["Excellent", "High"] else (60.0 if productivity in ["Good", "Adequate"] else 30.0)
	var automation := get_automation_opportunity()
	var a_val: float = 90.0 if automation in ["Low", "None"] else (50.0 if automation == "Moderate" else 20.0)
	return snapped((p_val + a_val) / 2.0, 0.1)
