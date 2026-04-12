extends Node

## Schedule system. Each pawn has a 24-hour schedule of Work/Sleep/Recreation/Anything.
## Registered as autoload "ScheduleManager".

enum Activity { ANYTHING, WORK, SLEEP, RECREATION }

const DEFAULT_SCHEDULE: Array[int] = [
	3, 3, 3, 3, 3, 3,  # 0-5: Sleep
	0, 0, 1, 1, 1, 1,  # 6-11: Anything, Work
	1, 1, 0, 0, 1, 1,  # 12-17: Work, break, Work
	0, 0, 2, 2, 0, 0,  # 18-23: Anything, Recreation, Anything
]

const NIGHT_OWL_SCHEDULE: Array[int] = [
	1, 1, 1, 1, 0, 0,  # 0-5: Work
	3, 3, 3, 3, 3, 3,  # 6-11: Sleep
	3, 3, 0, 0, 0, 0,  # 12-17: Sleep, Anything
	1, 1, 1, 1, 2, 2,  # 18-23: Work, Recreation
]

const EARLY_BIRD_SCHEDULE: Array[int] = [
	3, 3, 3, 3, 0, 1,  # 0-5: Sleep, Work
	1, 1, 1, 1, 1, 1,  # 6-11: Work
	0, 0, 2, 2, 0, 0,  # 12-17: break, Recreation, break
	0, 0, 3, 3, 3, 3,  # 18-23: Anything, Sleep
]

var pawn_schedules: Dictionary = {}


func get_schedule(pawn_id: int) -> Array[int]:
	if not pawn_schedules.has(pawn_id):
		pawn_schedules[pawn_id] = DEFAULT_SCHEDULE.duplicate()
	return pawn_schedules[pawn_id]


func set_hour_activity(pawn_id: int, hour: int, activity: int) -> void:
	if not pawn_schedules.has(pawn_id):
		pawn_schedules[pawn_id] = DEFAULT_SCHEDULE.duplicate()
	if hour >= 0 and hour < 24:
		pawn_schedules[pawn_id][hour] = activity


func apply_template(pawn_id: int, template_name: String) -> void:
	match template_name:
		"NightOwl":
			pawn_schedules[pawn_id] = NIGHT_OWL_SCHEDULE.duplicate()
		"EarlyBird":
			pawn_schedules[pawn_id] = EARLY_BIRD_SCHEDULE.duplicate()
		_:
			pawn_schedules[pawn_id] = DEFAULT_SCHEDULE.duplicate()


func set_range(pawn_id: int, from_hour: int, to_hour: int, activity: int) -> void:
	var sched := get_schedule(pawn_id)
	for h: int in range(from_hour, to_hour + 1):
		if h >= 0 and h < 24:
			sched[h] = activity


func get_current_activity(pawn_id: int) -> int:
	var hour: int = 12
	if GameState:
		hour = GameState.game_date.get("hour", 12)
	var sched: Array[int] = get_schedule(pawn_id)
	if hour >= 0 and hour < sched.size():
		return sched[hour]
	return Activity.ANYTHING


func is_work_time(pawn_id: int) -> bool:
	var act := get_current_activity(pawn_id)
	return act == Activity.WORK or act == Activity.ANYTHING


func is_sleep_time(pawn_id: int) -> bool:
	var act := get_current_activity(pawn_id)
	return act == Activity.SLEEP


func is_recreation_time(pawn_id: int) -> bool:
	var act := get_current_activity(pawn_id)
	return act == Activity.RECREATION or act == Activity.ANYTHING


func get_hours_of(pawn_id: int, activity: int) -> int:
	var sched := get_schedule(pawn_id)
	var count: int = 0
	for a: int in sched:
		if a == activity:
			count += 1
	return count


func get_activity_name(activity: int) -> String:
	match activity:
		Activity.ANYTHING:
			return "Anything"
		Activity.WORK:
			return "Work"
		Activity.SLEEP:
			return "Sleep"
		Activity.RECREATION:
			return "Recreation"
	return "Unknown"


func get_pawns_currently_working() -> Array[int]:
	var result: Array[int] = []
	for pid: int in pawn_schedules:
		if get_current_activity(pid) == Activity.WORK:
			result.append(pid)
	return result


func get_pawns_currently_sleeping() -> Array[int]:
	var result: Array[int] = []
	for pid: int in pawn_schedules:
		if get_current_activity(pid) == Activity.SLEEP:
			result.append(pid)
	return result


func get_next_activity_change(pawn_id: int) -> int:
	var hour: int = 12
	if GameState:
		hour = GameState.game_date.get("hour", 12)
	var sched := get_schedule(pawn_id)
	var current: int = sched[hour] if hour < sched.size() else 0
	for offset: int in range(1, 25):
		var h: int = (hour + offset) % 24
		if sched[h] != current:
			return offset
	return 24


func get_anything_hours(pawn_id: int) -> int:
	var sched := get_schedule(pawn_id)
	var cnt: int = 0
	for h: int in sched:
		if h == Activity.ANYTHING:
			cnt += 1
	return cnt


func get_total_pawns_scheduled() -> int:
	return pawn_schedules.size()


func get_avg_work_hours() -> float:
	if pawn_schedules.is_empty():
		return 0.0
	var total: int = 0
	for pid: int in pawn_schedules:
		total += get_hours_of(pid, Activity.WORK)
	return float(total) / float(pawn_schedules.size())


func get_recreation_pawn_count() -> int:
	var count: int = 0
	for pid: int in pawn_schedules:
		if get_current_activity(pid) == Activity.RECREATION:
			count += 1
	return count

func get_night_owl_count() -> int:
	var count: int = 0
	for pid: int in pawn_schedules:
		var sched: Array[int] = pawn_schedules[pid]
		if sched[0] == Activity.WORK and sched[8] == Activity.SLEEP:
			count += 1
	return count

func get_overworked_pawn_count() -> int:
	var count: int = 0
	for pid: int in pawn_schedules:
		if get_hours_of(pid, Activity.WORK) >= 14:
			count += 1
	return count

func get_work_ratio() -> float:
	var total: int = get_total_pawns_scheduled()
	if total <= 0:
		return 0.0
	return snappedf(float(get_pawns_currently_working().size()) / float(total) * 100.0, 0.1)


func get_idle_pawn_count() -> int:
	var hour: int = GameState.game_date.get("hour", 0) if GameState else 0
	var count: int = 0
	for pid: int in pawn_schedules:
		var sched: Array[int] = pawn_schedules[pid]
		if hour < sched.size() and sched[hour] == Activity.ANYTHING:
			count += 1
	return count


func get_sleep_ratio() -> float:
	var total: int = get_total_pawns_scheduled()
	if total <= 0:
		return 0.0
	return snappedf(float(get_pawns_currently_sleeping().size()) / float(total) * 100.0, 0.1)


func get_workforce_optimization() -> float:
	var total := get_total_pawns_scheduled()
	if total <= 0:
		return 0.0
	var working := float(get_pawns_currently_working().size())
	var sleeping := float(get_pawns_currently_sleeping().size())
	var idle := float(get_idle_pawn_count())
	var productive := working + sleeping
	return snapped(productive / float(total) * 100.0, 0.1)

func get_burnout_risk_pct() -> float:
	var total := get_total_pawns_scheduled()
	if total <= 0:
		return 0.0
	return snapped(float(get_overworked_pawn_count()) / float(total) * 100.0, 0.1)

func get_schedule_health() -> String:
	var burnout := get_burnout_risk_pct()
	var idle := get_idle_pawn_count()
	var total := get_total_pawns_scheduled()
	if total <= 0:
		return "Empty"
	if burnout > 30.0:
		return "Overworked"
	elif burnout > 10.0 and idle <= 0:
		return "Strained"
	elif idle > total / 2:
		return "Underutilized"
	return "Healthy"

func get_global_summary() -> Dictionary:
	return {
		"total_scheduled": get_total_pawns_scheduled(),
		"currently_working": get_pawns_currently_working().size(),
		"currently_sleeping": get_pawns_currently_sleeping().size(),
		"avg_work_hours": snappedf(get_avg_work_hours(), 0.1),
		"recreation_now": get_recreation_pawn_count(),
		"night_owls": get_night_owl_count(),
		"overworked": get_overworked_pawn_count(),
		"work_ratio_pct": get_work_ratio(),
		"idle_pawns": get_idle_pawn_count(),
		"sleep_ratio_pct": get_sleep_ratio(),
		"workforce_optimization": get_workforce_optimization(),
		"burnout_risk_pct": get_burnout_risk_pct(),
		"schedule_health": get_schedule_health(),
		"schedule_ecosystem_health": get_schedule_ecosystem_health(),
		"labor_governance": get_labor_governance(),
		"workforce_maturity_index": get_workforce_maturity_index(),
	}

func get_schedule_ecosystem_health() -> float:
	var opt := get_workforce_optimization()
	var burnout := get_burnout_risk_pct()
	var burn_inv := maxf(100.0 - burnout, 0.0)
	var health := get_schedule_health()
	var h_val: float = 90.0 if health == "Healthy" else (60.0 if health == "Strained" else (35.0 if health == "Underutilized" else 15.0))
	return snapped((opt + burn_inv + h_val) / 3.0, 0.1)

func get_labor_governance() -> String:
	var eco := get_schedule_ecosystem_health()
	var mat := get_workforce_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_total_pawns_scheduled() > 0:
		return "Nascent"
	return "Dormant"

func get_workforce_maturity_index() -> float:
	var work_r := get_work_ratio()
	var idle := float(get_idle_pawn_count())
	var total := float(get_total_pawns_scheduled())
	var idle_inv: float = 100.0 if total <= 0.0 else maxf(100.0 - idle / total * 100.0, 0.0)
	var burnout_inv := maxf(100.0 - get_burnout_risk_pct(), 0.0)
	return snapped((work_r + idle_inv + burnout_inv) / 3.0, 0.1)

func get_schedule_coherence() -> float:
	var ids: Array = pawn_schedules.keys()
	if ids.size() < 2:
		return 100.0
	var work_hours_list: Array[float] = []
	for pid in ids:
		work_hours_list.append(float(get_hours_of(pid, Activity.WORK)))
	var avg := 0.0
	for h in work_hours_list:
		avg += h
	avg /= float(work_hours_list.size())
	var variance := 0.0
	for h in work_hours_list:
		variance += (h - avg) * (h - avg)
	variance /= float(work_hours_list.size())
	return snapped(maxf(100.0 - variance * 5.0, 0.0), 0.1)

func get_rest_adequacy_score() -> float:
	var ids: Array = pawn_schedules.keys()
	if ids.is_empty():
		return 0.0
	var adequate := 0
	for pid in ids:
		if get_hours_of(pid, Activity.SLEEP) >= 6:
			adequate += 1
	return snapped(float(adequate) / float(ids.size()) * 100.0, 0.1)

func get_productivity_window() -> int:
	var hour_scores: Array[int] = []
	hour_scores.resize(24)
	for h in range(24):
		hour_scores[h] = 0
	for pid in pawn_schedules.keys():
		var sched: Array = pawn_schedules[pid]
		for h in range(mini(sched.size(), 24)):
			if sched[h] == Activity.WORK:
				hour_scores[h] += 1
	var best_hour := 0
	var best_score := 0
	for h in range(24):
		if hour_scores[h] > best_score:
			best_score = hour_scores[h]
			best_hour = h
	return best_hour

func get_summary(pawn_id: int) -> Dictionary:
	var sched := get_schedule(pawn_id)
	var current := get_current_activity(pawn_id)
	return {
		"schedule": sched,
		"current_activity": get_activity_name(current),
		"hour": GameState.game_date.get("hour", 0) if GameState else 0,
		"work_hours": get_hours_of(pawn_id, Activity.WORK),
		"sleep_hours": get_hours_of(pawn_id, Activity.SLEEP),
		"recreation_hours": get_hours_of(pawn_id, Activity.RECREATION),
		"anything_hours": get_anything_hours(pawn_id),
		"total_scheduled": get_total_pawns_scheduled(),
		"avg_work_hours": snappedf(get_avg_work_hours(), 0.1),
		"schedule_coherence": get_schedule_coherence(),
		"rest_adequacy_score": get_rest_adequacy_score(),
		"peak_productivity_hour": get_productivity_window(),
	}
