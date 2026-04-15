extends Node

var _pawn_states: Dictionary = {}

const STATES: Dictionary = {
	"Normal": {"can_work": true, "can_social": true, "violence": false},
	"Daze": {"can_work": false, "can_social": false, "violence": false, "duration_hours": 4, "min_mood": 0.0, "max_mood": 0.2},
	"SadWander": {"can_work": false, "can_social": false, "violence": false, "duration_hours": 6, "min_mood": 0.0, "max_mood": 0.15},
	"FoodBinge": {"can_work": false, "can_social": false, "violence": false, "duration_hours": 3, "min_mood": 0.0, "max_mood": 0.25},
	"HidingInRoom": {"can_work": false, "can_social": false, "violence": false, "duration_hours": 8, "min_mood": 0.0, "max_mood": 0.2},
	"Tantrum": {"can_work": false, "can_social": false, "violence": true, "duration_hours": 2, "min_mood": 0.0, "max_mood": 0.1},
	"Berserk": {"can_work": false, "can_social": false, "violence": true, "duration_hours": 1, "min_mood": 0.0, "max_mood": 0.05},
	"RunWild": {"can_work": false, "can_social": false, "violence": false, "duration_hours": 12, "min_mood": 0.0, "max_mood": 0.1},
	"InsultSpree": {"can_work": false, "can_social": true, "violence": false, "duration_hours": 4, "min_mood": 0.0, "max_mood": 0.15},
	"Catatonic": {"can_work": false, "can_social": false, "violence": false, "duration_hours": 24, "min_mood": 0.0, "max_mood": 0.05},
}


func trigger_break(pawn_id: int, mood_level: float) -> Dictionary:
	var candidates: Array = []
	for state: String in STATES:
		if state == "Normal":
			continue
		var data: Dictionary = STATES[state]
		if mood_level <= float(data.get("max_mood", 1.0)):
			candidates.append(state)
	if candidates.is_empty():
		return {"state": "Normal"}
	var chosen: String = candidates[randi() % candidates.size()]
	var data: Dictionary = STATES[chosen]
	var dur_ticks: int = int(data.get("duration_hours", 1)) * 2500
	_pawn_states[pawn_id] = {
		"state": chosen,
		"expires_tick": (TickManager.current_tick if TickManager else 0) + dur_ticks,
	}
	return {"state": chosen, "duration_hours": data.get("duration_hours", 1)}


func get_state(pawn_id: int) -> String:
	if not _pawn_states.has(pawn_id):
		return "Normal"
	var info: Dictionary = _pawn_states[pawn_id]
	var current: int = TickManager.current_tick if TickManager else 0
	if current > int(info.get("expires_tick", 0)):
		_pawn_states.erase(pawn_id)
		return "Normal"
	return String(info.get("state", "Normal"))


func can_work(pawn_id: int) -> bool:
	var s: String = get_state(pawn_id)
	return bool(STATES.get(s, {}).get("can_work", true))


func get_violent_states() -> Array[String]:
	var result: Array[String] = []
	for s: String in STATES:
		if bool(STATES[s].get("violence", false)):
			result.append(s)
	return result


func get_active_break_distribution() -> Dictionary:
	var dist: Dictionary = {}
	var current: int = TickManager.current_tick if TickManager else 0
	for pid: int in _pawn_states:
		var info: Dictionary = _pawn_states[pid]
		if current <= int(info.get("expires_tick", 0)):
			var s: String = String(info.get("state", ""))
			dist[s] = dist.get(s, 0) + 1
	return dist


func is_anyone_violent() -> bool:
	var current: int = TickManager.current_tick if TickManager else 0
	for pid: int in _pawn_states:
		var info: Dictionary = _pawn_states[pid]
		if current <= int(info.get("expires_tick", 0)):
			var s: String = String(info.get("state", ""))
			if bool(STATES.get(s, {}).get("violence", false)):
				return true
	return false


func get_most_common_break() -> String:
	var dist := get_active_break_distribution()
	var best: String = ""
	var best_n: int = 0
	for s: String in dist:
		if dist[s] > best_n:
			best_n = dist[s]
			best = s
	return best


func get_violent_count() -> int:
	var count: int = 0
	for pid: int in _pawn_states:
		var state_id: String = str(_pawn_states[pid].get("state", ""))
		var data: Dictionary = STATES.get(state_id, {})
		if data.get("violent", false):
			count += 1
	return count


func has_any_break() -> bool:
	return not _pawn_states.is_empty()


func get_avg_duration_hours() -> float:
	var total: float = 0.0
	var count: int = 0
	for s: String in STATES:
		if s == "Normal":
			continue
		total += float(STATES[s].get("duration_hours", 0))
		count += 1
	if count == 0:
		return 0.0
	return snappedf(total / float(count), 0.1)


func get_non_violent_break_count() -> int:
	var count: int = 0
	for s: String in STATES:
		if s == "Normal":
			continue
		if not bool(STATES[s].get("violence", false)):
			count += 1
	return count


func get_break_pct() -> float:
	if _pawn_states.is_empty():
		return 0.0
	var current: int = TickManager.current_tick if TickManager else 0
	var active: int = 0
	for pid: int in _pawn_states:
		if current <= int(_pawn_states[pid].get("expires_tick", 0)):
			active += 1
	return snappedf(float(active) / float(_pawn_states.size()) * 100.0, 0.1)


func get_stability_rating() -> String:
	var pct: float = get_break_pct()
	if pct == 0.0:
		return "Stable"
	elif pct < 10.0:
		return "Mostly Stable"
	elif pct < 30.0:
		return "Volatile"
	return "Crisis"

func get_violence_threat() -> String:
	var violent: int = get_violent_count()
	if violent == 0:
		return "None"
	elif violent <= 1:
		return "Low"
	elif violent <= 3:
		return "Moderate"
	return "High"

func get_recovery_outlook() -> String:
	var avg: float = get_avg_duration_hours()
	if avg <= 2.0:
		return "Quick"
	elif avg <= 6.0:
		return "Moderate"
	elif avg <= 12.0:
		return "Slow"
	return "Extended"

func get_summary() -> Dictionary:
	return {
		"state_types": STATES.size(),
		"active_breaks": _pawn_states.size(),
		"violent_active": is_anyone_violent(),
		"violent_count": get_violent_count(),
		"distribution": get_active_break_distribution(),
		"most_common": get_most_common_break(),
		"any_break": has_any_break(),
		"avg_duration_hours": get_avg_duration_hours(),
		"non_violent_breaks": get_non_violent_break_count(),
		"break_pct": get_break_pct(),
		"stability_rating": get_stability_rating(),
		"violence_threat": get_violence_threat(),
		"recovery_outlook": get_recovery_outlook(),
		"psychological_resilience": get_psychological_resilience(),
		"crisis_frequency_index": get_crisis_frequency_index(),
		"intervention_urgency": get_intervention_urgency(),
		"mental_ecosystem_health": get_mental_ecosystem_health(),
		"stability_governance": get_stability_governance(),
		"psychiatric_maturity_index": get_psychiatric_maturity_index(),
	}

func get_psychological_resilience() -> String:
	var stability := get_stability_rating()
	var recovery := get_recovery_outlook()
	if stability in ["Stable", "Strong"] and recovery in ["Good", "Excellent"]:
		return "Resilient"
	elif stability in ["Fragile"] or recovery in ["Poor"]:
		return "Fragile"
	return "Average"

func get_crisis_frequency_index() -> float:
	var breaks := _pawn_states.size()
	var total := STATES.size()
	if total <= 0:
		return 0.0
	return snapped(float(breaks) / float(total) * 100.0, 0.1)

func get_intervention_urgency() -> String:
	var violent := get_violent_count()
	var any := has_any_break()
	if violent >= 2:
		return "Critical"
	elif violent > 0 or any:
		return "Urgent"
	return "None"

func get_mental_ecosystem_health() -> float:
	var resilience := get_psychological_resilience()
	var r_val: float = 90.0 if resilience == "Resilient" else (50.0 if resilience == "Average" else 20.0)
	var crisis := get_crisis_frequency_index()
	var stability := get_stability_rating()
	var s_val: float = 90.0 if stability in ["Stable", "Strong"] else (50.0 if stability == "Fragile" else 20.0)
	return snapped((r_val + maxf(100.0 - crisis, 0.0) + s_val) / 3.0, 0.1)

func get_stability_governance() -> String:
	var health := get_mental_ecosystem_health()
	var urgency := get_intervention_urgency()
	if health >= 65.0 and urgency == "None":
		return "Proactive"
	elif health >= 35.0:
		return "Reactive"
	return "Overwhelmed"

func get_psychiatric_maturity_index() -> float:
	var recovery := get_recovery_outlook()
	var rc_val: float = 90.0 if recovery in ["Good", "Excellent"] else (50.0 if recovery == "Fair" else 20.0)
	var violence := get_violence_threat()
	var v_val: float = 90.0 if violence == "None" else (50.0 if violence == "Low" else 20.0)
	return snapped((rc_val + v_val) / 2.0, 0.1)
