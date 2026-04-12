extends Node

const REST_MOOD_RECOVERY: float = 0.02
const JOY_GAIN_REST: float = 0.01
const SLEEP_MOOD_BONUS: float = 0.005

var _pawn_schedule_state: Dictionary = {}


func set_schedule_state(pawn_id: int, state: String) -> void:
	_pawn_schedule_state[pawn_id] = state


func get_schedule_state(pawn_id: int) -> String:
	return String(_pawn_schedule_state.get(pawn_id, "Work"))


func tick_rest(pawn_id: int) -> Dictionary:
	var state: String = get_schedule_state(pawn_id)
	var mood_gain: float = 0.0
	var joy_gain: float = 0.0
	var rest_gain: float = 0.0
	match state:
		"Rest":
			mood_gain = REST_MOOD_RECOVERY
			joy_gain = JOY_GAIN_REST
			rest_gain = 0.005
		"Sleep":
			mood_gain = SLEEP_MOOD_BONUS
			rest_gain = 0.015
		"Recreation":
			joy_gain = 0.02
			mood_gain = 0.01
		_:
			pass
	return {"mood": mood_gain, "joy": joy_gain, "rest": rest_gain}


func get_state_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pid: int in _pawn_schedule_state:
		var s: String = String(_pawn_schedule_state[pid])
		dist[s] = dist.get(s, 0) + 1
	return dist


func get_resting_count() -> int:
	var count: int = 0
	for pid: int in _pawn_schedule_state:
		var s: String = String(_pawn_schedule_state[pid])
		if s == "Rest" or s == "Sleep":
			count += 1
	return count


func get_working_count() -> int:
	var count: int = 0
	for pid: int in _pawn_schedule_state:
		if String(_pawn_schedule_state[pid]) == "Work":
			count += 1
	return count


func get_recreation_count() -> int:
	var count: int = 0
	for pid: int in _pawn_schedule_state:
		if str(_pawn_schedule_state[pid]) == "recreation":
			count += 1
	return count


func get_rest_percentage() -> float:
	if _pawn_schedule_state.is_empty():
		return 0.0
	return snappedf(float(get_resting_count()) / float(_pawn_schedule_state.size()) * 100.0, 0.1)


func get_work_pct() -> float:
	if _pawn_schedule_state.is_empty():
		return 0.0
	return snappedf(float(get_working_count()) / float(_pawn_schedule_state.size()) * 100.0, 0.1)


func get_most_common_state() -> String:
	var dist: Dictionary = get_state_distribution()
	var best: String = ""
	var best_n: int = 0
	for s: String in dist:
		if int(dist[s]) > best_n:
			best_n = int(dist[s])
			best = s
	return best


func get_unique_state_count() -> int:
	return get_state_distribution().size()


func get_work_life_balance() -> String:
	var work: float = get_work_pct()
	if work >= 70.0:
		return "Overworked"
	elif work >= 50.0:
		return "Busy"
	elif work >= 30.0:
		return "Balanced"
	return "Relaxed"

func get_burnout_risk() -> String:
	var rest: float = get_rest_percentage()
	if rest < 10.0:
		return "Critical"
	elif rest < 20.0:
		return "High"
	elif rest < 35.0:
		return "Moderate"
	return "Low"

func get_leisure_ratio() -> float:
	if _pawn_schedule_state.is_empty():
		return 0.0
	return snappedf(float(get_recreation_count()) / float(_pawn_schedule_state.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"tracked_pawns": _pawn_schedule_state.size(),
		"distribution": get_state_distribution(),
		"resting": get_resting_count(),
		"working": get_working_count(),
		"recreation": get_recreation_count(),
		"rest_pct": get_rest_percentage(),
		"work_pct": get_work_pct(),
		"most_common_state": get_most_common_state(),
		"unique_states": get_unique_state_count(),
		"work_life_balance": get_work_life_balance(),
		"burnout_risk": get_burnout_risk(),
		"leisure_ratio_pct": get_leisure_ratio(),
		"energy_management": get_energy_management(),
		"productivity_window": get_productivity_window(),
		"schedule_optimization": get_schedule_optimization(),
		"rest_ecosystem_health": get_rest_ecosystem_health(),
		"circadian_governance": get_circadian_governance(),
		"recovery_maturity_index": get_recovery_maturity_index(),
	}

func get_energy_management() -> String:
	var rest := get_rest_percentage()
	var burnout := get_burnout_risk()
	if rest >= 30.0 and burnout in ["None", "Low"]:
		return "Well Rested"
	elif rest >= 15.0:
		return "Adequate"
	return "Exhausted"

func get_productivity_window() -> float:
	var work := get_work_pct()
	var balance := get_work_life_balance()
	if balance in ["Balanced", "Good"]:
		return snapped(work, 0.1)
	return snapped(work * 0.7, 0.1)

func get_schedule_optimization() -> String:
	var balance := get_work_life_balance()
	var leisure := get_leisure_ratio()
	if balance in ["Good", "Balanced"] and leisure >= 15.0:
		return "Optimized"
	elif balance in ["Balanced"]:
		return "Adequate"
	return "Needs Tuning"

func get_rest_ecosystem_health() -> float:
	var energy := get_energy_management()
	var e_val: float = 90.0 if energy == "Well Rested" else (60.0 if energy == "Adequate" else 30.0)
	var optimization := get_schedule_optimization()
	var o_val: float = 90.0 if optimization == "Optimized" else (60.0 if optimization == "Adequate" else 30.0)
	var rest := get_rest_percentage()
	return snapped((e_val + o_val + rest) / 3.0, 0.1)

func get_circadian_governance() -> String:
	var health := get_rest_ecosystem_health()
	var burnout := get_burnout_risk()
	if health >= 65.0 and burnout in ["None", "Low"]:
		return "Well Regulated"
	elif health >= 35.0:
		return "Developing"
	return "Dysregulated"

func get_recovery_maturity_index() -> float:
	var productivity := get_productivity_window()
	var leisure := get_leisure_ratio()
	return snapped((productivity + leisure) / 2.0, 0.1)
