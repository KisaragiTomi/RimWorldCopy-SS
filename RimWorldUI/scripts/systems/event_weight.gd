extends Node

const EVENT_WEIGHTS: Dictionary = {
	"RaidSmall": {"base_weight": 100, "min_days": 5, "cooldown_days": 3},
	"RaidLarge": {"base_weight": 40, "min_days": 20, "cooldown_days": 10},
	"WandererJoin": {"base_weight": 80, "min_days": 3, "cooldown_days": 5},
	"ResourceDrop": {"base_weight": 60, "min_days": 1, "cooldown_days": 2},
	"TraderVisit": {"base_weight": 70, "min_days": 5, "cooldown_days": 4},
	"Disease": {"base_weight": 50, "min_days": 10, "cooldown_days": 15},
	"ManhunterPack": {"base_weight": 30, "min_days": 15, "cooldown_days": 10},
	"SolarFlare": {"base_weight": 20, "min_days": 30, "cooldown_days": 20},
	"Eclipse": {"base_weight": 25, "min_days": 20, "cooldown_days": 15},
	"ToxicFallout": {"base_weight": 15, "min_days": 25, "cooldown_days": 20},
	"ColdSnap": {"base_weight": 35, "min_days": 10, "cooldown_days": 10},
	"HeatWave": {"base_weight": 35, "min_days": 10, "cooldown_days": 10},
	"Infestation": {"base_weight": 20, "min_days": 30, "cooldown_days": 15},
	"PsychicDrone": {"base_weight": 15, "min_days": 20, "cooldown_days": 25},
	"TransportPodCrash": {"base_weight": 40, "min_days": 10, "cooldown_days": 8},
}

var _last_fired: Dictionary = {}


func select_event(current_day: int, difficulty: float) -> String:
	var candidates: Array = []
	var total_weight: float = 0.0
	for eid: String in EVENT_WEIGHTS:
		var data: Dictionary = EVENT_WEIGHTS[eid]
		if current_day < int(data.get("min_days", 0)):
			continue
		var last: int = int(_last_fired.get(eid, -999))
		if current_day - last < int(data.get("cooldown_days", 0)):
			continue
		var w: float = float(data.get("base_weight", 0)) * difficulty
		candidates.append({"id": eid, "weight": w})
		total_weight += w
	if candidates.is_empty():
		return ""
	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for c: Dictionary in candidates:
		cumulative += float(c.weight)
		if roll <= cumulative:
			_last_fired[String(c.id)] = current_day
			return String(c.id)
	return String(candidates[-1].id)


func get_available_events(current_day: int) -> Array[String]:
	var result: Array[String] = []
	for eid: String in EVENT_WEIGHTS:
		var data: Dictionary = EVENT_WEIGHTS[eid]
		if current_day < int(data.get("min_days", 0)):
			continue
		var last: int = int(_last_fired.get(eid, -999))
		if current_day - last < int(data.get("cooldown_days", 0)):
			continue
		result.append(eid)
	return result


func get_highest_weight_event() -> String:
	var best: String = ""
	var best_w: float = 0.0
	for eid: String in EVENT_WEIGHTS:
		var w: float = float(EVENT_WEIGHTS[eid].get("base_weight", 0))
		if w > best_w:
			best_w = w
			best = eid
	return best


func get_on_cooldown(current_day: int) -> Array[String]:
	var result: Array[String] = []
	for eid: String in _last_fired:
		var data: Dictionary = EVENT_WEIGHTS.get(eid, {})
		var last: int = int(_last_fired[eid])
		if current_day - last < int(data.get("cooldown_days", 0)):
			result.append(eid)
	return result


func get_cooldown_count() -> int:
	var count: int = 0
	var now: int = TickManager.current_tick if TickManager else 0
	for eid: String in _last_fired:
		var cd: int = int(EVENT_WEIGHTS.get(eid, {}).get("cooldown", 0))
		if now < _last_fired[eid] + cd:
			count += 1
	return count


func get_avg_weight() -> float:
	if EVENT_WEIGHTS.is_empty():
		return 0.0
	var total: float = 0.0
	for eid: String in EVENT_WEIGHTS:
		total += float(EVENT_WEIGHTS[eid].get("weight", 0.0))
	return snappedf(total / float(EVENT_WEIGHTS.size()), 0.1)


func get_never_fired_count() -> int:
	return EVENT_WEIGHTS.size() - _last_fired.size()


func get_weight_range() -> Dictionary:
	var lo: float = 99999.0
	var hi: float = 0.0
	for eid: String in EVENT_WEIGHTS:
		var w: float = float(EVENT_WEIGHTS[eid].get("base_weight", 0))
		if w < lo:
			lo = w
		if w > hi:
			hi = w
	if EVENT_WEIGHTS.is_empty():
		return {"min": 0, "max": 0}
	return {"min": int(lo), "max": int(hi)}


func get_avg_cooldown_days() -> float:
	if EVENT_WEIGHTS.is_empty():
		return 0.0
	var total: float = 0.0
	for eid: String in EVENT_WEIGHTS:
		total += float(EVENT_WEIGHTS[eid].get("cooldown_days", 0))
	return snappedf(total / float(EVENT_WEIGHTS.size()), 0.1)


func get_most_frequent_event() -> String:
	var best: String = ""
	var best_cd: int = 99999
	for eid: String in EVENT_WEIGHTS:
		var cd: int = int(EVENT_WEIGHTS[eid].get("cooldown_days", 99999))
		if cd < best_cd:
			best_cd = cd
			best = eid
	return best


func get_event_pressure() -> String:
	var avg: float = get_avg_weight()
	if avg >= 80.0:
		return "Intense"
	elif avg >= 50.0:
		return "Active"
	elif avg >= 20.0:
		return "Moderate"
	return "Calm"

func get_pool_freshness_pct() -> float:
	if EVENT_WEIGHTS.is_empty():
		return 0.0
	var never: int = get_never_fired_count()
	return snappedf(float(never) / float(EVENT_WEIGHTS.size()) * 100.0, 0.1)

func get_cooldown_saturation() -> String:
	if EVENT_WEIGHTS.is_empty():
		return "Empty"
	var cd: int = get_cooldown_count()
	var pct: float = float(cd) / float(EVENT_WEIGHTS.size()) * 100.0
	if pct >= 60.0:
		return "Saturated"
	elif pct >= 30.0:
		return "Moderate"
	elif pct > 0.0:
		return "Light"
	return "Open"

func get_summary() -> Dictionary:
	return {
		"event_types": EVENT_WEIGHTS.size(),
		"fired_events": _last_fired.size(),
		"most_common": get_highest_weight_event(),
		"on_cooldown": get_cooldown_count(),
		"avg_weight": get_avg_weight(),
		"never_fired": get_never_fired_count(),
		"weight_range": get_weight_range(),
		"avg_cooldown_days": get_avg_cooldown_days(),
		"most_frequent": get_most_frequent_event(),
		"event_pressure": get_event_pressure(),
		"pool_freshness_pct": get_pool_freshness_pct(),
		"cooldown_saturation": get_cooldown_saturation(),
		"event_variety_potential": get_event_variety_potential(),
		"threat_pipeline_health": get_threat_pipeline_health(),
		"narrative_freshness": get_narrative_freshness(),
		"event_ecosystem_governance": get_event_ecosystem_governance(),
		"storytelling_pipeline_index": get_storytelling_pipeline_index(),
		"dramatic_maturity": get_dramatic_maturity(),
	}

func get_event_variety_potential() -> float:
	var never := get_never_fired_count()
	var total := EVENT_WEIGHTS.size()
	if total <= 0:
		return 0.0
	return snapped(float(never) / float(total) * 100.0, 0.1)

func get_threat_pipeline_health() -> String:
	var saturation := get_cooldown_saturation()
	var pressure := get_event_pressure()
	if saturation in ["Open", "Light"] and pressure in ["Calm", "Low"]:
		return "Healthy"
	elif saturation in ["Moderate"]:
		return "Active"
	return "Strained"

func get_narrative_freshness() -> String:
	var freshness := get_pool_freshness_pct()
	if freshness >= 50.0:
		return "Fresh"
	elif freshness >= 20.0:
		return "Maturing"
	return "Stale"

func get_event_ecosystem_governance() -> float:
	var variety := get_event_variety_potential()
	var pipeline := get_threat_pipeline_health()
	var p_val: float = 90.0 if pipeline == "Healthy" else (60.0 if pipeline == "Active" else 30.0)
	var freshness_pct := get_pool_freshness_pct()
	return snapped((variety + p_val + freshness_pct) / 3.0, 0.1)

func get_storytelling_pipeline_index() -> float:
	var freshness := get_narrative_freshness()
	var f_val: float = 90.0 if freshness == "Fresh" else (60.0 if freshness == "Maturing" else 30.0)
	var cooldown := get_cooldown_saturation()
	var c_val: float = 90.0 if cooldown in ["Open", "Light"] else (50.0 if cooldown == "Moderate" else 20.0)
	return snapped((f_val + c_val) / 2.0, 0.1)

func get_dramatic_maturity() -> String:
	var governance := get_event_ecosystem_governance()
	var pipeline := get_storytelling_pipeline_index()
	if governance >= 65.0 and pipeline >= 60.0:
		return "Mature"
	elif governance >= 35.0 or pipeline >= 30.0:
		return "Developing"
	return "Nascent"
