extends Node

var _active_conditions: Dictionary = {}
var _history: Array[Dictionary] = []
var _activation_counts: Dictionary = {}

const CONDITIONS: Dictionary = {
	"ToxicFallout": {"outdoor_penalty": -0.5, "crop_growth": 0.0, "mood": -10, "duration_days": 3, "desc": "Toxic dust blankets the area"},
	"VolcanicWinter": {"outdoor_penalty": 0.0, "crop_growth": 0.3, "mood": -5, "duration_days": 15, "temp_offset": -10.0, "desc": "Volcanic ash blocks sunlight"},
	"ColdSnap": {"outdoor_penalty": 0.0, "crop_growth": 0.0, "mood": -3, "duration_days": 5, "temp_offset": -20.0, "desc": "Extreme cold wave"},
	"HeatWave": {"outdoor_penalty": 0.0, "crop_growth": 0.8, "mood": -5, "duration_days": 5, "temp_offset": 15.0, "desc": "Scorching heat"},
	"Eclipse": {"outdoor_penalty": 0.0, "crop_growth": 0.5, "mood": -3, "duration_days": 1, "desc": "Solar eclipse"},
	"Aurora": {"outdoor_penalty": 0.0, "crop_growth": 1.0, "mood": 5, "duration_days": 1, "desc": "Beautiful aurora"},
	"Flashstorm": {"outdoor_penalty": -0.3, "crop_growth": 0.8, "mood": -5, "duration_days": 1, "desc": "Lightning strikes everywhere"},
	"PsychicDrone": {"outdoor_penalty": 0.0, "crop_growth": 1.0, "mood": -15, "duration_days": 2, "desc": "Psychic drone attacks minds"},
	"PsychicSoothe": {"outdoor_penalty": 0.0, "crop_growth": 1.0, "mood": 10, "duration_days": 2, "desc": "Calming psychic wave"},
}


func activate_condition(cond_id: String) -> Dictionary:
	if not CONDITIONS.has(cond_id):
		return {"success": false}
	var data: Dictionary = CONDITIONS[cond_id]
	var dur: int = int(data.get("duration_days", 1)) * 60000
	_active_conditions[cond_id] = {
		"expires_tick": (TickManager.current_tick if TickManager else 0) + dur,
		"data": data,
	}
	_activation_counts[cond_id] = _activation_counts.get(cond_id, 0) + 1
	_history.append({"id": cond_id, "tick": TickManager.current_tick if TickManager else 0})
	if _history.size() > 30:
		_history.pop_front()
	if EventLetter and EventLetter.has_method("send_letter"):
		EventLetter.send_letter(cond_id, String(data.get("desc", "")), 1 if float(data.get("mood", 0)) < 0 else 0)
	return {"success": true, "condition": cond_id, "duration_days": data.get("duration_days", 1)}


func get_active_conditions() -> Array:
	var current: int = TickManager.current_tick if TickManager else 0
	var expired: Array = []
	for cid: String in _active_conditions:
		if current > int(_active_conditions[cid].get("expires_tick", 0)):
			expired.append(cid)
	for e: String in expired:
		_active_conditions.erase(e)
	return _active_conditions.keys()


func get_mood_offset() -> float:
	var total: float = 0.0
	for cid: String in get_active_conditions():
		var info: Dictionary = _active_conditions.get(cid, {})
		var data: Dictionary = info.get("data", {})
		total += float(data.get("mood", 0))
	return total


func get_temperature_offset() -> float:
	var total: float = 0.0
	for cid: String in get_active_conditions():
		var info: Dictionary = _active_conditions.get(cid, {})
		var data: Dictionary = info.get("data", {})
		total += float(data.get("temp_offset", 0.0))
	return total


func get_crop_growth_modifier() -> float:
	var factor: float = 1.0
	for cid: String in get_active_conditions():
		var info: Dictionary = _active_conditions.get(cid, {})
		var data: Dictionary = info.get("data", {})
		factor *= float(data.get("crop_growth", 1.0))
	return factor


func get_most_frequent_condition() -> String:
	var best: String = ""
	var best_count: int = 0
	for cid: String in _activation_counts:
		if _activation_counts[cid] > best_count:
			best_count = _activation_counts[cid]
			best = cid
	return best


func get_negative_conditions() -> Array[String]:
	var result: Array[String] = []
	for cid: String in get_active_conditions():
		var info: Dictionary = _active_conditions.get(cid, {})
		var data: Dictionary = info.get("data", {})
		if float(data.get("mood", 0)) < 0:
			result.append(cid)
	return result


func get_active_count() -> int:
	return get_active_conditions().size()


func is_any_harmful() -> bool:
	for c: Dictionary in get_active_conditions():
		var cdata: Dictionary = CONDITIONS.get(c.get("id", ""), {})
		if cdata.get("harmful", false):
			return true
	return false


func get_harmful_condition_count() -> int:
	var count: int = 0
	for cid: String in get_active_conditions():
		var info: Dictionary = _active_conditions.get(cid, {})
		var data: Dictionary = info.get("data", {})
		if float(data.get("mood", 0)) < 0:
			count += 1
	return count


func get_total_mood_modifier() -> float:
	return get_mood_offset()


func get_per_type_frequency() -> Dictionary:
	var total: int = 0
	for cid: String in _activation_counts:
		total += int(_activation_counts[cid])
	if total == 0:
		return {}
	var freq: Dictionary = {}
	for cid: String in _activation_counts:
		freq[cid] = snappedf(float(_activation_counts[cid]) / float(total) * 100.0, 0.1)
	return freq


func get_environmental_stress() -> String:
	var harmful: int = get_harmful_condition_count()
	if harmful == 0:
		return "Calm"
	elif harmful <= 2:
		return "Mild"
	elif harmful <= 4:
		return "Harsh"
	return "Extreme"

func get_condition_diversity() -> float:
	if CONDITIONS.is_empty():
		return 0.0
	var activated: int = 0
	for cid: String in _activation_counts:
		if _activation_counts[cid] > 0:
			activated += 1
	return snappedf(float(activated) / float(CONDITIONS.size()) * 100.0, 0.1)

func get_farming_impact() -> String:
	var mod: float = get_crop_growth_modifier()
	if mod >= 1.2:
		return "Boosted"
	elif mod >= 0.9:
		return "Normal"
	elif mod >= 0.5:
		return "Hindered"
	return "Devastated"

func get_summary() -> Dictionary:
	return {
		"condition_types": CONDITIONS.size(),
		"active": get_active_conditions(),
		"active_count": get_active_count(),
		"total_activations": _activation_counts.duplicate(),
		"crop_growth_mod": get_crop_growth_modifier(),
		"most_frequent": get_most_frequent_condition(),
		"any_harmful": is_any_harmful(),
		"harmful_count": get_harmful_condition_count(),
		"total_mood_mod": get_total_mood_modifier(),
		"per_type_freq": get_per_type_frequency(),
		"environmental_stress": get_environmental_stress(),
		"condition_diversity_pct": get_condition_diversity(),
		"farming_impact": get_farming_impact(),
		"environmental_resilience": get_environmental_resilience(),
		"condition_severity_index": get_condition_severity_index(),
		"habitability_rating": get_habitability_rating(),
		"environmental_governance": get_environmental_governance(),
		"climate_resilience_index": get_climate_resilience_index(),
		"ecological_stability_score": get_ecological_stability_score(),
	}

func get_environmental_resilience() -> String:
	var harmful := get_harmful_condition_count()
	var active := get_active_count()
	if active == 0:
		return "Pristine"
	if harmful == 0:
		return "Resilient"
	elif harmful <= active / 2:
		return "Coping"
	return "Strained"

func get_condition_severity_index() -> float:
	var mood := get_total_mood_modifier()
	var harmful := get_harmful_condition_count()
	return snapped(absf(mood) + float(harmful) * 5.0, 0.1)

func get_habitability_rating() -> String:
	var farming := get_farming_impact()
	var stress := get_environmental_stress()
	if farming in ["Boosted", "Normal"] and stress in ["None", "Low"]:
		return "Hospitable"
	elif farming in ["Normal", "Hindered"]:
		return "Tolerable"
	return "Hostile"

func get_environmental_governance() -> float:
	var severity := get_condition_severity_index()
	var diversity := get_condition_diversity()
	var resilience := get_environmental_resilience()
	var res_val: float = 90.0 if resilience in ["Pristine", "Resilient"] else (50.0 if resilience == "Coping" else 20.0)
	return snapped((maxf(100.0 - severity * 2.0, 0.0) + diversity + res_val) / 3.0, 0.1)

func get_climate_resilience_index() -> float:
	var harmful := get_harmful_condition_count()
	var active := get_active_count()
	if active <= 0:
		return 100.0
	var safe_ratio := float(active - harmful) / float(active) * 100.0
	var crop_mod := get_crop_growth_modifier()
	return snapped((safe_ratio + minf(crop_mod * 100.0, 100.0)) / 2.0, 0.1)

func get_ecological_stability_score() -> String:
	var governance := get_environmental_governance()
	var climate := get_climate_resilience_index()
	if governance >= 70.0 and climate >= 70.0:
		return "Stable"
	elif governance >= 40.0 or climate >= 40.0:
		return "Dynamic"
	return "Volatile"
