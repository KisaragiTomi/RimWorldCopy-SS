extends Node

var _pods: Array = []
var _launched: Array = []

const POD_TYPES: Dictionary = {
	"TransportPod": {"capacity_kg": 150.0, "fuel_cost": 75, "range_tiles": 66, "build_work": 1600},
	"DropPod": {"capacity_kg": 80.0, "fuel_cost": 50, "range_tiles": 40, "build_work": 800},
	"ShuttlePod": {"capacity_kg": 300.0, "fuel_cost": 150, "range_tiles": 100, "build_work": 3200}
}

const PAYLOAD_TYPES: Array = ["Colonist", "Prisoner", "Animal", "Item", "Silver", "Gift"]

func build_pod(pod_type: String, position: Vector2i) -> int:
	if not POD_TYPES.has(pod_type):
		return -1
	var pod: Dictionary = {
		"id": _pods.size(),
		"type": pod_type,
		"position": position,
		"payload": [],
		"total_weight": 0.0,
		"fueled": false
	}
	_pods.append(pod)
	return pod["id"]

func load_payload(pod_id: int, payload_type: String, item_id: int, weight: float) -> bool:
	if pod_id < 0 or pod_id >= _pods.size():
		return false
	var pod: Dictionary = _pods[pod_id]
	var cap: float = POD_TYPES[pod["type"]]["capacity_kg"]
	if pod["total_weight"] + weight > cap:
		return false
	pod["payload"].append({"type": payload_type, "item_id": item_id, "weight": weight})
	pod["total_weight"] += weight
	return true

func fuel_pod(pod_id: int) -> bool:
	if pod_id < 0 or pod_id >= _pods.size():
		return false
	_pods[pod_id]["fueled"] = true
	return true

func launch(pod_id: int, target: Vector2i) -> Dictionary:
	if pod_id < 0 or pod_id >= _pods.size():
		return {}
	var pod: Dictionary = _pods[pod_id]
	if not pod["fueled"]:
		return {"error": "not_fueled"}
	if pod["payload"].is_empty():
		return {"error": "empty_payload"}
	var result: Dictionary = {
		"pod_type": pod["type"],
		"target": target,
		"payload_count": pod["payload"].size(),
		"total_weight": pod["total_weight"]
	}
	_launched.append(result)
	return result

func get_fueled_count() -> int:
	var count: int = 0
	for pod: Dictionary in _pods:
		if bool(pod.get("fueled", false)):
			count += 1
	return count


func get_largest_pod_type() -> String:
	var best: String = ""
	var best_cap: float = 0.0
	for pt: String in POD_TYPES:
		if float(POD_TYPES[pt].get("capacity_kg", 0.0)) > best_cap:
			best_cap = float(POD_TYPES[pt].get("capacity_kg", 0.0))
			best = pt
	return best


func get_total_launched_weight() -> float:
	var total: float = 0.0
	for l: Dictionary in _launched:
		total += float(l.get("total_weight", 0.0))
	return total


func get_avg_payload_per_launch() -> float:
	if _launched.is_empty():
		return 0.0
	var total: int = 0
	for l: Dictionary in _launched:
		total += int(l.get("payload_count", 0))
	return float(total) / _launched.size()


func get_unfueled_count() -> int:
	var count: int = 0
	for pod: Dictionary in _pods:
		if not bool(pod.get("fueled", false)):
			count += 1
	return count


func get_avg_launched_weight() -> float:
	if _launched.is_empty():
		return 0.0
	return get_total_launched_weight() / _launched.size()


func get_total_fuel_cost() -> int:
	var total: int = 0
	for pod: Dictionary in _pods:
		total += int(POD_TYPES.get(String(pod.get("type", "")), {}).get("fuel_cost", 0))
	return total


func get_max_range_pod() -> String:
	var best: String = ""
	var best_r: int = 0
	for pt: String in POD_TYPES:
		var r: int = int(POD_TYPES[pt].get("range_tiles", 0))
		if r > best_r:
			best_r = r
			best = pt
	return best


func get_empty_pod_count() -> int:
	var count: int = 0
	for pod: Dictionary in _pods:
		if pod.get("payload", []).is_empty():
			count += 1
	return count


func get_launch_readiness() -> String:
	if _pods.is_empty():
		return "N/A"
	var ready_pct: float = float(get_fueled_count()) / float(_pods.size()) * 100.0
	if ready_pct >= 80.0:
		return "Combat-Ready"
	elif ready_pct >= 50.0:
		return "Operational"
	elif ready_pct >= 20.0:
		return "Limited"
	return "Grounded"

func get_logistics_efficiency() -> String:
	var avg: float = get_avg_payload_per_launch()
	if avg >= 200.0:
		return "Excellent"
	elif avg >= 100.0:
		return "Good"
	elif avg >= 50.0:
		return "Fair"
	return "Poor"

func get_fleet_utilization_pct() -> float:
	if _pods.is_empty():
		return 0.0
	var active: int = _pods.size() - get_empty_pod_count()
	return snappedf(float(active) / float(_pods.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"pod_types": POD_TYPES.size(),
		"built_pods": _pods.size(),
		"launched_count": _launched.size(),
		"fueled_ready": get_fueled_count(),
		"largest_type": get_largest_pod_type(),
		"avg_payload": snapped(get_avg_payload_per_launch(), 0.1),
		"unfueled": get_unfueled_count(),
		"avg_weight": snapped(get_avg_launched_weight(), 0.1),
		"total_fuel_cost": get_total_fuel_cost(),
		"max_range_type": get_max_range_pod(),
		"empty_pods": get_empty_pod_count(),
		"launch_readiness": get_launch_readiness(),
		"logistics_efficiency": get_logistics_efficiency(),
		"fleet_utilization_pct": get_fleet_utilization_pct(),
		"orbital_capability": get_orbital_capability(),
		"deployment_speed": get_deployment_speed(),
		"strategic_mobility": get_strategic_mobility(),
		"pod_ecosystem_health": get_pod_ecosystem_health(),
		"deployment_governance": get_deployment_governance(),
		"transport_maturity_index": get_transport_maturity_index(),
	}

func get_orbital_capability() -> String:
	var fueled := get_fueled_count()
	var total := _pods.size()
	if fueled >= 3:
		return "Full Capability"
	elif fueled > 0:
		return "Limited"
	return "None"

func get_deployment_speed() -> String:
	var readiness := get_launch_readiness()
	if readiness in ["Ready", "Primed"]:
		return "Rapid"
	elif readiness in ["Partial"]:
		return "Delayed"
	return "Unavailable"

func get_strategic_mobility() -> float:
	var launched := _launched.size()
	var total := _pods.size() + launched
	if total <= 0:
		return 0.0
	return snapped(float(launched) / float(total) * 100.0, 0.1)

func get_pod_ecosystem_health() -> float:
	var capability := get_orbital_capability()
	var cap_val: float = 90.0 if capability in ["Full", "Advanced"] else (60.0 if capability in ["Partial", "Basic"] else 30.0)
	var speed := get_deployment_speed()
	var sp_val: float = 90.0 if speed == "Rapid" else (60.0 if speed == "Delayed" else 30.0)
	var mobility := get_strategic_mobility()
	return snapped((cap_val + sp_val + mobility) / 3.0, 0.1)

func get_transport_maturity_index() -> float:
	var readiness := get_launch_readiness()
	var r_val: float = 90.0 if readiness in ["Ready", "Primed"] else (60.0 if readiness in ["Partial", "Standby"] else 30.0)
	var efficiency := get_logistics_efficiency()
	var e_val: float = 90.0 if efficiency in ["Optimal", "Efficient"] else (60.0 if efficiency in ["Adequate", "Moderate"] else 30.0)
	var utilization := get_fleet_utilization_pct()
	return snapped((r_val + e_val + utilization) / 3.0, 0.1)

func get_deployment_governance() -> String:
	var ecosystem := get_pod_ecosystem_health()
	var maturity := get_transport_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _pods.size() > 0:
		return "Nascent"
	return "Dormant"
