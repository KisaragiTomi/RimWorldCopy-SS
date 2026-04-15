extends Node

var _active_events: Array = []
var _event_counts: Dictionary = {}
var _event_history: Array[Dictionary] = []

const EVENTS: Dictionary = {
	"GlobalWarming": {"temp_offset": 5.0, "crop_mod": 0.8, "duration_days": 30, "desc": "Temperatures rise globally"},
	"IceAge": {"temp_offset": -10.0, "crop_mod": 0.3, "duration_days": 60, "desc": "A new ice age begins"},
	"Plague": {"mood_mod": -10, "duration_days": 15, "desc": "Global plague spreads between settlements"},
	"GoldenAge": {"mood_mod": 10, "trade_mod": 1.5, "duration_days": 30, "desc": "An era of prosperity"},
	"MechanoidSwarm": {"threat_mod": 2.0, "duration_days": 20, "desc": "Mechanoids attack everywhere"},
	"SolarFlare": {"power_disabled": true, "duration_days": 2, "desc": "Massive solar flare disables electronics"},
	"Meteor": {"resource_bonus": 500, "duration_days": 1, "desc": "Meteors rain down with resources"},
	"PsychicStorm": {"mood_mod": -20, "duration_days": 3, "desc": "Worldwide psychic disturbance"},
}


func trigger_event(event_id: String) -> Dictionary:
	if not EVENTS.has(event_id):
		return {"success": false}
	var data: Dictionary = EVENTS[event_id]
	var dur: int = int(data.get("duration_days", 1)) * 60000
	var entry: Dictionary = {
		"id": event_id,
		"expires_tick": (TickManager.current_tick if TickManager else 0) + dur,
		"data": data,
	}
	_active_events.append(entry)
	_event_counts[event_id] = _event_counts.get(event_id, 0) + 1
	_event_history.append({"id": event_id, "tick": TickManager.current_tick if TickManager else 0})
	if _event_history.size() > 30:
		_event_history.pop_front()
	if EventLetter and EventLetter.has_method("send_letter"):
		EventLetter.send_letter("World Event: " + event_id, String(data.get("desc", "")), 2)
	return {"success": true, "event": event_id}


func get_active_events() -> Array:
	var current: int = TickManager.current_tick if TickManager else 0
	_active_events = _active_events.filter(func(e: Dictionary) -> bool: return current <= int(e.get("expires_tick", 0)))
	var ids: Array = []
	for e: Dictionary in _active_events:
		ids.append(String(e.get("id", "")))
	return ids


func get_dangerous_events() -> Array[String]:
	var result: Array[String] = []
	for eid: String in EVENTS:
		var d: Dictionary = EVENTS[eid]
		if float(d.get("threat_mod", 0)) > 1.0 or float(d.get("mood_mod", 0)) < -10 or bool(d.get("power_disabled", false)):
			result.append(eid)
	return result


func get_most_frequent_event() -> String:
	var best: String = ""
	var best_count: int = 0
	for eid: String in _event_counts:
		if _event_counts[eid] > best_count:
			best_count = _event_counts[eid]
			best = eid
	return best


func get_total_mood_impact() -> float:
	var total: float = 0.0
	for eid: String in get_active_events():
		for e: Dictionary in _active_events:
			if String(e.get("id", "")) == eid:
				total += float(e.get("data", {}).get("mood_mod", 0))
				break
	return total


func get_total_events_triggered() -> int:
	var total: int = 0
	for eid: String in _event_counts:
		total += _event_counts[eid]
	return total


func get_dangerous_active_count() -> int:
	var count: int = 0
	for e: Dictionary in _active_events:
		var data: Dictionary = EVENTS.get(str(e.get("id", "")), {})
		if data.get("dangerous", false):
			count += 1
	return count


func is_any_active() -> bool:
	return not _active_events.is_empty()


func get_unique_triggered_count() -> int:
	return _event_counts.size()


func get_never_triggered() -> Array[String]:
	var result: Array[String] = []
	for eid: String in EVENTS:
		if not _event_counts.has(eid):
			result.append(eid)
	return result


func get_avg_events_per_type() -> float:
	if _event_counts.is_empty():
		return 0.0
	var total: int = get_total_events_triggered()
	return snappedf(float(total) / float(_event_counts.size()), 0.1)


func get_chaos_level() -> String:
	var dangerous: int = get_dangerous_active_count()
	if dangerous >= 3:
		return "Catastrophic"
	elif dangerous >= 2:
		return "Severe"
	elif dangerous >= 1:
		return "Elevated"
	return "Stable"

func get_event_coverage_pct() -> float:
	if EVENTS.is_empty():
		return 0.0
	return snappedf(float(get_unique_triggered_count()) / float(EVENTS.size()) * 100.0, 0.1)

func get_danger_trend() -> String:
	var total: int = get_total_events_triggered()
	var dangerous: int = get_dangerous_active_count()
	if total == 0:
		return "Quiet"
	var ratio: float = float(dangerous) / float(_active_events.size()) if _active_events.size() > 0 else 0.0
	if ratio >= 0.5:
		return "Escalating"
	elif ratio > 0.0:
		return "Mixed"
	return "Calm"

func get_summary() -> Dictionary:
	return {
		"event_types": EVENTS.size(),
		"active_events": get_active_events(),
		"active_count": _active_events.size(),
		"total_triggered": _event_counts.duplicate(),
		"mood_impact": get_total_mood_impact(),
		"total_events": get_total_events_triggered(),
		"dangerous_active": get_dangerous_active_count(),
		"most_frequent": get_most_frequent_event(),
		"unique_triggered": get_unique_triggered_count(),
		"never_triggered": get_never_triggered(),
		"avg_per_type": get_avg_events_per_type(),
		"chaos_level": get_chaos_level(),
		"event_coverage_pct": get_event_coverage_pct(),
		"danger_trend": get_danger_trend(),
		"event_saturation": get_event_saturation(),
		"crisis_readiness": get_crisis_readiness(),
		"world_stability": get_world_stability(),
		"event_ecosystem_health": get_event_ecosystem_health(),
		"geopolitical_awareness": get_geopolitical_awareness(),
		"global_resilience_index": get_global_resilience_index(),
	}

func get_event_saturation() -> float:
	var triggered := get_unique_triggered_count()
	var total := EVENTS.size()
	if total <= 0:
		return 0.0
	return snapped(float(triggered) / float(total) * 100.0, 0.1)

func get_crisis_readiness() -> String:
	var dangerous := get_dangerous_active_count()
	var coverage := get_event_coverage_pct()
	if dangerous == 0 and coverage >= 50.0:
		return "Prepared"
	elif dangerous <= 2:
		return "Alert"
	return "Overwhelmed"

func get_world_stability() -> String:
	var chaos := get_chaos_level()
	var trend := get_danger_trend()
	if chaos in ["Stable"] and trend in ["Calm", "Quiet"]:
		return "Peaceful"
	elif chaos in ["Elevated"]:
		return "Tense"
	return "Unstable"

func get_event_ecosystem_health() -> float:
	var saturation := get_event_saturation()
	var coverage := get_event_coverage_pct()
	var stability := get_world_stability()
	var stability_val: float = 90.0 if stability == "Peaceful" else (50.0 if stability == "Tense" else 20.0)
	return snapped((saturation + coverage + stability_val) / 3.0, 0.1)

func get_geopolitical_awareness() -> float:
	var unique := get_unique_triggered_count()
	var total := EVENTS.size()
	var dangerous := get_dangerous_active_count()
	if total <= 0:
		return 0.0
	var experience_pct := float(unique) / float(total) * 100.0
	var danger_awareness := minf(float(dangerous) * 20.0, 100.0)
	return snapped((experience_pct + danger_awareness) / 2.0, 0.1)

func get_global_resilience_index() -> String:
	var health := get_event_ecosystem_health()
	var readiness := get_crisis_readiness()
	if health >= 60.0 and readiness == "Prepared":
		return "Resilient"
	elif health >= 30.0 or readiness == "Alert":
		return "Adaptive"
	return "Vulnerable"
