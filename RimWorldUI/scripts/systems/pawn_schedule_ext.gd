extends Node

const SCHEDULE_BLOCKS: Dictionary = {
	"Sleep": {"hours": [22, 23, 0, 1, 2, 3, 4, 5], "priority": 1},
	"Work": {"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17], "priority": 2},
	"Joy": {"hours": [18, 19, 20], "priority": 3},
	"Anything": {"hours": [21], "priority": 4},
	"Meditate": {"hours": [], "priority": 5},
	"Research": {"hours": [], "priority": 6}
}

const ACTIVITY_TYPES: Dictionary = {
	"Sleep": {"rest_gain": 0.12, "joy_gain": 0.0},
	"Work": {"rest_gain": -0.02, "joy_gain": -0.01},
	"Joy": {"rest_gain": -0.01, "joy_gain": 0.06},
	"Anything": {"rest_gain": 0.0, "joy_gain": 0.02},
	"Meditate": {"rest_gain": 0.02, "joy_gain": 0.03, "psyfocus_gain": 0.01},
	"Research": {"rest_gain": -0.03, "joy_gain": -0.02, "research_speed": 1.0}
}

var _pawn_schedules: Dictionary = {}

func set_schedule(pawn_id: String, hour: int, activity: String) -> Dictionary:
	if not ACTIVITY_TYPES.has(activity):
		return {"error": "unknown_activity"}
	if hour < 0 or hour > 23:
		return {"error": "invalid_hour"}
	if not _pawn_schedules.has(pawn_id):
		_pawn_schedules[pawn_id] = {}
		for h: int in range(24):
			_pawn_schedules[pawn_id][h] = "Anything"
	_pawn_schedules[pawn_id][hour] = activity
	return {"pawn": pawn_id, "hour": hour, "activity": activity}

func get_activity(pawn_id: String, hour: int) -> String:
	if _pawn_schedules.has(pawn_id):
		return _pawn_schedules[pawn_id].get(hour, "Anything")
	return SCHEDULE_BLOCKS.keys()[0] if hour in SCHEDULE_BLOCKS["Sleep"]["hours"] else "Work" if hour in SCHEDULE_BLOCKS["Work"]["hours"] else "Joy" if hour in SCHEDULE_BLOCKS["Joy"]["hours"] else "Anything"

func get_work_hours_count(pawn_id: String) -> int:
	if not _pawn_schedules.has(pawn_id):
		return SCHEDULE_BLOCKS["Work"]["hours"].size()
	var cnt: int = 0
	for h: int in range(24):
		if _pawn_schedules[pawn_id].get(h, "Anything") == "Work":
			cnt += 1
	return cnt

func get_sleep_deficit_pawns() -> Array[String]:
	var result: Array[String] = []
	for pid: String in _pawn_schedules:
		var sleep_h: int = 0
		for h: int in range(24):
			if _pawn_schedules[pid].get(h, "Anything") == "Sleep":
				sleep_h += 1
		if sleep_h < 6:
			result.append(pid)
	return result

func get_meditating_pawns() -> Array[String]:
	var result: Array[String] = []
	for pid: String in _pawn_schedules:
		for h: int in range(24):
			if _pawn_schedules[pid].get(h, "Anything") == "Meditate":
				result.append(pid)
				break
	return result

func get_avg_work_hours() -> float:
	if _pawn_schedules.is_empty():
		return 0.0
	var total: int = 0
	for pid: String in _pawn_schedules:
		total += get_work_hours_count(pid)
	return float(total) / _pawn_schedules.size()


func get_overworked_count() -> int:
	var count: int = 0
	for pid: String in _pawn_schedules:
		if get_work_hours_count(pid) >= 16:
			count += 1
	return count


func get_recreation_deficit_count() -> int:
	var count: int = 0
	for pid: String in _pawn_schedules:
		var sched: Variant = _pawn_schedules[pid]
		var joy_hours: int = 0
		if sched is Dictionary:
			for h: int in range(24):
				if sched.get(h, "") == "Joy":
					joy_hours += 1
		if joy_hours < 2:
			count += 1
	return count


func get_researcher_count() -> int:
	var count: int = 0
	for pid: String in _pawn_schedules:
		for h: int in range(24):
			if _pawn_schedules[pid].get(h, "Anything") == "Research":
				count += 1
				break
	return count


func get_unique_activities_used() -> int:
	var acts: Dictionary = {}
	for pid: String in _pawn_schedules:
		for h: int in range(24):
			acts[_pawn_schedules[pid].get(h, "Anything")] = true
	return acts.size()


func get_max_work_hours_pawn() -> String:
	var best: String = ""
	var best_h: int = 0
	for pid: String in _pawn_schedules:
		var wh: int = get_work_hours_count(pid)
		if wh > best_h:
			best_h = wh
			best = pid
	return best


func get_workforce_health() -> String:
	var overworked: int = get_overworked_count()
	var sleep_def: int = get_sleep_deficit_pawns().size()
	var total: int = _pawn_schedules.size()
	if total == 0:
		return "no_data"
	var stress: float = (overworked + sleep_def) * 1.0 / total
	if stress >= 0.5:
		return "strained"
	if stress >= 0.2:
		return "moderate"
	return "healthy"

func get_leisure_adequacy_pct() -> float:
	var joy_def: int = get_recreation_deficit_count()
	var total: int = _pawn_schedules.size()
	if total == 0:
		return 100.0
	return snapped((total - joy_def) * 100.0 / total, 0.1)

func get_schedule_diversity() -> String:
	var unique: int = get_unique_activities_used()
	var available: int = ACTIVITY_TYPES.size()
	if available == 0:
		return "none"
	var ratio: float = unique * 1.0 / available
	if ratio >= 0.8:
		return "rich"
	if ratio >= 0.5:
		return "moderate"
	return "rigid"

func get_summary() -> Dictionary:
	return {
		"schedule_blocks": SCHEDULE_BLOCKS.size(),
		"activity_types": ACTIVITY_TYPES.size(),
		"custom_schedules": _pawn_schedules.size(),
		"sleep_deficit_count": get_sleep_deficit_pawns().size(),
		"meditating_count": get_meditating_pawns().size(),
		"avg_work_hours": snapped(get_avg_work_hours(), 0.1),
		"overworked": get_overworked_count(),
		"joy_deficit": get_recreation_deficit_count(),
		"researchers": get_researcher_count(),
		"unique_activities": get_unique_activities_used(),
		"hardest_worker": get_max_work_hours_pawn(),
		"workforce_health": get_workforce_health(),
		"leisure_adequacy_pct": get_leisure_adequacy_pct(),
		"schedule_diversity": get_schedule_diversity(),
		"work_life_balance": get_work_life_balance(),
		"burnout_risk_index": get_burnout_risk_index(),
		"productivity_sustainability": get_productivity_sustainability(),
		"schedule_ecosystem_health": get_schedule_ecosystem_health(),
		"temporal_governance": get_temporal_governance(),
		"workforce_rhythm_index": get_workforce_rhythm_index(),
	}

func get_work_life_balance() -> String:
	var leisure := get_leisure_adequacy_pct()
	var overworked := get_overworked_count()
	if leisure >= 70.0 and overworked == 0:
		return "Excellent"
	elif leisure >= 40.0:
		return "Adequate"
	return "Poor"

func get_burnout_risk_index() -> float:
	var overworked := get_overworked_count()
	var sleep_deficit := get_sleep_deficit_pawns().size()
	var total := _pawn_schedules.size()
	if total <= 0:
		return 0.0
	return snapped(float(overworked + sleep_deficit) / float(total) * 100.0, 0.1)

func get_productivity_sustainability() -> String:
	var health := get_workforce_health()
	var joy := get_recreation_deficit_count()
	if health in ["Healthy", "Excellent"] and joy == 0:
		return "Self-Sustaining"
	elif health in ["Moderate", "Healthy"]:
		return "Manageable"
	return "Declining"

func get_schedule_ecosystem_health() -> float:
	var balance := get_work_life_balance()
	var b_val: float = 90.0 if balance == "Balanced" else (60.0 if balance == "Good" else 30.0)
	var burnout := get_burnout_risk_index()
	var leisure := get_leisure_adequacy_pct()
	return snapped((b_val + maxf(100.0 - burnout, 0.0) + leisure) / 3.0, 0.1)

func get_temporal_governance() -> String:
	var health := get_schedule_ecosystem_health()
	var sustainability := get_productivity_sustainability()
	if health >= 65.0 and sustainability == "Self-Sustaining":
		return "Optimized"
	elif health >= 35.0:
		return "Functional"
	return "Chaotic"

func get_workforce_rhythm_index() -> float:
	var diversity := get_schedule_diversity()
	var d_val: float = 90.0 if diversity == "Diverse" else (60.0 if diversity == "Moderate" else 30.0)
	var workforce := get_workforce_health()
	var w_val: float = 90.0 if workforce in ["Excellent", "Healthy"] else (60.0 if workforce == "Moderate" else 30.0)
	return snapped((d_val + w_val) / 2.0, 0.1)
