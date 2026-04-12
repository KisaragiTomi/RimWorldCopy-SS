extends Node

var _switches: Dictionary = {}
var _connections: Dictionary = {}

const SWITCH_TYPES: Dictionary = {
	"PowerSwitch": {"resistance": 0.0, "max_throughput": 9999},
	"Fuse": {"resistance": 0.01, "max_throughput": 2000, "blows_at": 2000},
	"Breaker": {"resistance": 0.0, "max_throughput": 5000, "auto_reset": true},
	"Transformer": {"resistance": 0.02, "max_throughput": 10000, "voltage_change": true}
}

func place_switch(switch_id: int, switch_type: String, position: Vector2i) -> bool:
	if not SWITCH_TYPES.has(switch_type):
		return false
	_switches[switch_id] = {
		"type": switch_type,
		"position": position,
		"on": true,
		"blown": false
	}
	return true

func toggle_switch(switch_id: int) -> bool:
	if not _switches.has(switch_id):
		return false
	if _switches[switch_id]["blown"]:
		return false
	_switches[switch_id]["on"] = not _switches[switch_id]["on"]
	return _switches[switch_id]["on"]

func is_on(switch_id: int) -> bool:
	if not _switches.has(switch_id):
		return false
	return _switches[switch_id]["on"] and not _switches[switch_id]["blown"]

func check_overload(switch_id: int, current_load: float) -> bool:
	if not _switches.has(switch_id):
		return false
	var info: Dictionary = SWITCH_TYPES[_switches[switch_id]["type"]]
	if current_load > info["max_throughput"]:
		if info.has("blows_at"):
			_switches[switch_id]["blown"] = true
			_switches[switch_id]["on"] = false
		return true
	return false

func repair_switch(switch_id: int) -> bool:
	if not _switches.has(switch_id):
		return false
	_switches[switch_id]["blown"] = false
	_switches[switch_id]["on"] = true
	return true

func get_blown_count() -> int:
	var count: int = 0
	for sid: int in _switches:
		if bool(_switches[sid].get("blown", false)):
			count += 1
	return count


func get_active_count() -> int:
	var count: int = 0
	for sid: int in _switches:
		if is_on(sid):
			count += 1
	return count


func get_switches_by_type(switch_type: String) -> Array:
	var result: Array = []
	for sid: int in _switches:
		if String(_switches[sid].get("type", "")) == switch_type:
			result.append(sid)
	return result


func get_inactive_count() -> int:
	return _switches.size() - get_active_count()


func get_most_common_type() -> String:
	var counts: Dictionary = {}
	for sid: int in _switches:
		var t: String = String(_switches[sid].get("type", ""))
		counts[t] = counts.get(t, 0) + 1
	var best: String = ""
	var best_count: int = 0
	for t: String in counts:
		if int(counts[t]) > best_count:
			best_count = int(counts[t])
			best = t
	return best


func get_health_rate() -> float:
	if _switches.is_empty():
		return 1.0
	return 1.0 - (float(get_blown_count()) / _switches.size())


func get_fuse_count() -> int:
	return get_switches_by_type("Fuse").size()


func get_active_pct() -> float:
	if _switches.is_empty():
		return 0.0
	return snappedf(float(get_active_count()) / float(_switches.size()) * 100.0, 0.1)


func get_unique_placed_types() -> int:
	var types: Dictionary = {}
	for sid: int in _switches:
		types[String(_switches[sid].get("type", ""))] = true
	return types.size()


func get_grid_reliability() -> String:
	var health: float = get_health_rate()
	if health >= 0.9:
		return "Reliable"
	elif health >= 0.7:
		return "Stable"
	elif health >= 0.4:
		return "Degraded"
	return "Failing"

func get_maintenance_urgency() -> String:
	var blown: int = get_blown_count()
	if _switches.is_empty():
		return "N/A"
	var blown_pct: float = float(blown) / float(_switches.size())
	if blown_pct >= 0.3:
		return "Critical"
	elif blown_pct >= 0.15:
		return "Needed"
	elif blown_pct >= 0.05:
		return "Minor"
	return "Clear"

func get_automation_coverage_pct() -> float:
	if SWITCH_TYPES.is_empty():
		return 0.0
	return snappedf(float(get_unique_placed_types()) / float(SWITCH_TYPES.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"switch_types": SWITCH_TYPES.size(),
		"placed_switches": _switches.size(),
		"active": get_active_count(),
		"blown": get_blown_count(),
		"inactive": get_inactive_count(),
		"most_common_type": get_most_common_type(),
		"health_rate": snapped(get_health_rate(), 0.01),
		"fuse_count": get_fuse_count(),
		"active_pct": get_active_pct(),
		"unique_placed_types": get_unique_placed_types(),
		"grid_reliability": get_grid_reliability(),
		"maintenance_urgency": get_maintenance_urgency(),
		"automation_coverage_pct": get_automation_coverage_pct(),
		"power_control_maturity": get_power_control_maturity(),
		"circuit_safety_rating": get_circuit_safety_rating(),
		"switch_utilization_pct": get_switch_utilization_pct(),
		"electrical_ecosystem_health": get_electrical_ecosystem_health(),
		"circuit_governance": get_circuit_governance(),
		"power_infrastructure_maturity": get_power_infrastructure_maturity(),
	}

func get_power_control_maturity() -> String:
	var types := get_unique_placed_types()
	var auto := get_automation_coverage_pct()
	if types >= 3 and auto >= 50.0:
		return "Advanced"
	elif types >= 2:
		return "Developing"
	return "Basic"

func get_circuit_safety_rating() -> String:
	var blown := get_blown_count()
	var total := _switches.size()
	if total <= 0:
		return "No Grid"
	var fail_rate := float(blown) / float(total)
	if fail_rate <= 0.05:
		return "Excellent"
	elif fail_rate <= 0.2:
		return "Acceptable"
	return "Critical"

func get_switch_utilization_pct() -> float:
	var active := get_active_count()
	var total := _switches.size()
	if total <= 0:
		return 0.0
	return snapped(float(active) / float(total) * 100.0, 0.1)

func get_electrical_ecosystem_health() -> float:
	var reliability := get_grid_reliability()
	var r_val: float = 90.0 if reliability == "Rock Solid" else (60.0 if reliability == "Reliable" else 30.0)
	var safety := get_circuit_safety_rating()
	var s_val: float = 90.0 if safety == "Excellent" else (60.0 if safety == "Acceptable" else 20.0)
	var utilization := get_switch_utilization_pct()
	return snapped((r_val + s_val + utilization) / 3.0, 0.1)

func get_circuit_governance() -> String:
	var ecosystem := get_electrical_ecosystem_health()
	var maturity := get_power_control_maturity()
	var m_val: float = 90.0 if maturity == "Advanced" else (60.0 if maturity == "Standard" else 20.0)
	var combined := (ecosystem + m_val) / 2.0
	if combined >= 70.0:
		return "Robust"
	elif combined >= 40.0:
		return "Functional"
	elif _switches.size() > 0:
		return "Fragile"
	return "Offline"

func get_power_infrastructure_maturity() -> float:
	var automation := get_automation_coverage_pct()
	var health := get_health_rate()
	return snapped((automation + health * 100.0) / 2.0, 0.1)
