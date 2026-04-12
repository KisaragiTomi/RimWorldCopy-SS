extends Node

var _nodes: Dictionary = {}
var _next_id: int = 0

const NODE_TYPES: Dictionary = {
	"BasicBandNode": {"bandwidth": 1, "range": 8, "power": 50},
	"StandardBandNode": {"bandwidth": 2, "range": 12, "power": 100},
	"HighBandNode": {"bandwidth": 4, "range": 15, "power": 200},
	"LargeBandNode": {"bandwidth": 6, "range": 20, "power": 350},
	"SubcoreEncoder": {"bandwidth": 0, "special": "encode_subcore", "power": 400},
	"SubcoreScanner": {"bandwidth": 0, "special": "scan_subcore", "power": 300}
}

const MECH_BANDWIDTH_COST: Dictionary = {
	"Militor": 1, "Lifter": 1, "Constructoid": 1, "Agrihand": 1,
	"Cleansweeper": 1, "Fabricor": 2, "Centurion": 3, "Tesseron": 2
}

func place_node(node_type: String, pos: Vector2i) -> Dictionary:
	if not NODE_TYPES.has(node_type):
		return {"error": "unknown_type"}
	var nid: int = _next_id
	_next_id += 1
	_nodes[nid] = {"type": node_type, "pos": pos, "active": true}
	return {"node_id": nid, "bandwidth": NODE_TYPES[node_type]["bandwidth"]}

func get_total_bandwidth() -> int:
	var total: int = 0
	for nid: int in _nodes:
		if _nodes[nid]["active"]:
			total += NODE_TYPES.get(_nodes[nid]["type"], {}).get("bandwidth", 0)
	return total

func can_control_mech(mech_type: String, current_used: int) -> bool:
	var cost: int = MECH_BANDWIDTH_COST.get(mech_type, 1)
	return current_used + cost <= get_total_bandwidth()

func get_highest_bandwidth_node() -> String:
	var best: String = ""
	var best_bw: int = 0
	for n: String in NODE_TYPES:
		var bw: int = int(NODE_TYPES[n].get("bandwidth", 0))
		if bw > best_bw:
			best_bw = bw
			best = n
	return best


func get_total_power_draw() -> int:
	var total: int = 0
	for nid: int in _nodes:
		if bool(_nodes[nid].get("active", false)):
			total += int(NODE_TYPES.get(String(_nodes[nid].get("type", "")), {}).get("power", 0))
	return total


func get_most_expensive_mech() -> String:
	var best: String = ""
	var best_cost: int = 0
	for m: String in MECH_BANDWIDTH_COST:
		if int(MECH_BANDWIDTH_COST[m]) > best_cost:
			best_cost = int(MECH_BANDWIDTH_COST[m])
			best = m
	return best


func get_avg_bandwidth_per_node() -> float:
	if NODE_TYPES.is_empty():
		return 0.0
	var total: int = 0
	for nt: String in NODE_TYPES:
		total += int(NODE_TYPES[nt].get("bandwidth", 0))
	return float(total) / NODE_TYPES.size()


func get_special_node_count() -> int:
	var count: int = 0
	for nt: String in NODE_TYPES:
		if NODE_TYPES[nt].has("special"):
			count += 1
	return count


func get_active_node_count() -> int:
	var count: int = 0
	for nid: int in _nodes:
		if bool(_nodes[nid].get("active", false)):
			count += 1
	return count


func get_total_possible_bandwidth() -> int:
	var total: int = 0
	for nt: String in NODE_TYPES:
		total += int(NODE_TYPES[nt].get("bandwidth", 0))
	return total


func get_avg_power_per_node() -> float:
	if NODE_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for nt: String in NODE_TYPES:
		total += float(NODE_TYPES[nt].get("power", 0))
	return snappedf(total / float(NODE_TYPES.size()), 0.1)


func get_inactive_node_count() -> int:
	var count: int = 0
	for nid: int in _nodes:
		if not bool(_nodes[nid].get("active", false)):
			count += 1
	return count


func get_network_health() -> String:
	var active: int = get_active_node_count()
	var total: int = _nodes.size()
	if total == 0:
		return "Offline"
	var ratio: float = float(active) / float(total)
	if ratio >= 0.9:
		return "Optimal"
	if ratio >= 0.6:
		return "Degraded"
	return "Critical"


func get_bandwidth_utilization_pct() -> float:
	var used: float = float(get_total_bandwidth())
	var possible: float = float(get_total_possible_bandwidth())
	if possible <= 0.0:
		return 0.0
	return snappedf(used / possible * 100.0, 0.1)


func get_power_efficiency() -> String:
	var avg_power: float = get_avg_power_per_node()
	if avg_power <= 100.0:
		return "Efficient"
	if avg_power <= 300.0:
		return "Moderate"
	return "PowerHungry"


func get_summary() -> Dictionary:
	return {
		"node_types": NODE_TYPES.size(),
		"mech_types_tracked": MECH_BANDWIDTH_COST.size(),
		"placed_nodes": _nodes.size(),
		"total_bandwidth": get_total_bandwidth(),
		"total_power": get_total_power_draw(),
		"most_expensive_mech": get_most_expensive_mech(),
		"avg_bandwidth": snapped(get_avg_bandwidth_per_node(), 0.1),
		"special_nodes": get_special_node_count(),
		"active_nodes": get_active_node_count(),
		"total_possible_bw": get_total_possible_bandwidth(),
		"avg_power_per_node": get_avg_power_per_node(),
		"inactive_nodes": get_inactive_node_count(),
		"network_health": get_network_health(),
		"bandwidth_utilization_pct": get_bandwidth_utilization_pct(),
		"power_efficiency": get_power_efficiency(),
		"network_scalability": get_network_scalability(),
		"signal_strength": get_signal_strength(),
		"mech_capacity_headroom": get_mech_capacity_headroom(),
		"network_ecosystem_health": get_network_ecosystem_health(),
		"node_governance": get_node_governance(),
		"mesh_maturity_index": get_mesh_maturity_index(),
	}

func get_network_scalability() -> String:
	var utilization := get_bandwidth_utilization_pct()
	if utilization <= 50.0:
		return "Highly Scalable"
	elif utilization <= 80.0:
		return "Room to Grow"
	return "At Capacity"

func get_signal_strength() -> float:
	var active := get_active_node_count()
	var total := _nodes.size()
	if total <= 0:
		return 0.0
	return snapped(float(active) / float(total) * 100.0, 0.1)

func get_mech_capacity_headroom() -> float:
	var total_bw := get_total_bandwidth()
	var possible := get_total_possible_bandwidth()
	if possible <= 0:
		return 0.0
	return snapped((1.0 - float(total_bw) / float(possible)) * 100.0, 0.1)

func get_network_ecosystem_health() -> float:
	var health := get_network_health()
	var h_val: float = 90.0 if health in ["Excellent", "Optimal"] else (60.0 if health in ["Good", "Stable"] else 30.0)
	var utilization := get_bandwidth_utilization_pct()
	var signal_val := get_signal_strength()
	return snapped((h_val + minf(utilization, 100.0) + signal_val) / 3.0, 0.1)

func get_mesh_maturity_index() -> float:
	var scalability := get_network_scalability()
	var s_val: float = 90.0 if scalability == "Highly Scalable" else (60.0 if scalability == "Room to Grow" else 30.0)
	var efficiency := get_power_efficiency()
	var e_val: float = 90.0 if efficiency == "Efficient" else (60.0 if efficiency == "Moderate" else 30.0)
	var headroom := get_mech_capacity_headroom()
	return snapped((s_val + e_val + headroom) / 3.0, 0.1)

func get_node_governance() -> String:
	var ecosystem := get_network_ecosystem_health()
	var maturity := get_mesh_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _nodes.size() > 0:
		return "Nascent"
	return "Dormant"
