extends Node

const ITEM_WEIGHTS: Dictionary = {
	"Steel": 0.5, "Wood": 0.3, "Silver": 0.3, "Gold": 0.5,
	"Plasteel": 0.4, "Components": 0.6, "Uranium": 1.0,
	"SimpleMeal": 0.3, "FineMeal": 0.3, "Pemmican": 0.2,
	"Medicine": 0.2, "HerbalMedicine": 0.15, "Beer": 0.4,
	"Cloth": 0.1, "Leather": 0.15, "Weapon": 2.0,
}

var _pawn_carry: Dictionary = {}
const BASE_CAPACITY: float = 35.0


func add_item(pawn_id: int, item_id: String, amount: int) -> Dictionary:
	if not _pawn_carry.has(pawn_id):
		_pawn_carry[pawn_id] = {}
	var weight: float = float(ITEM_WEIGHTS.get(item_id, 0.5)) * float(amount)
	var current: float = get_total_weight(pawn_id)
	if current + weight > BASE_CAPACITY:
		return {"success": false, "reason": "Too heavy", "current": snapped(current, 0.1)}
	_pawn_carry[pawn_id][item_id] = int(_pawn_carry[pawn_id].get(item_id, 0)) + amount
	return {"success": true, "total_weight": snapped(current + weight, 0.1)}


func get_total_weight(pawn_id: int) -> float:
	var items: Dictionary = _pawn_carry.get(pawn_id, {})
	var total: float = 0.0
	for item: String in items:
		total += float(ITEM_WEIGHTS.get(item, 0.5)) * float(items[item])
	return total


func get_speed_modifier(pawn_id: int) -> float:
	var w: float = get_total_weight(pawn_id)
	var ratio: float = w / BASE_CAPACITY
	return clampf(1.0 - ratio * 0.4, 0.3, 1.0)


func get_heaviest_item() -> String:
	var best: String = ""
	var best_w: float = 0.0
	for item: String in ITEM_WEIGHTS:
		if ITEM_WEIGHTS[item] > best_w:
			best_w = ITEM_WEIGHTS[item]
			best = item
	return best


func get_overloaded_pawns() -> Array[int]:
	var result: Array[int] = []
	for pid: int in _pawn_carry:
		if get_total_weight(pid) > BASE_CAPACITY:
			result.append(pid)
	return result


func get_fill_percent(pawn_id: int) -> float:
	return snappedf(get_total_weight(pawn_id) / BASE_CAPACITY * 100.0, 0.1)


func get_avg_fill_pct() -> float:
	if _pawn_carry.is_empty():
		return 0.0
	var total: float = 0.0
	for pid: int in _pawn_carry:
		var current: float = float(_pawn_carry[pid].get("current_weight", 0.0))
		var cap: float = float(_pawn_carry[pid].get("capacity", BASE_CAPACITY))
		if cap > 0.0:
			total += current / cap * 100.0
	return snappedf(total / float(_pawn_carry.size()), 0.1)


func get_lightest_item() -> String:
	var best: String = ""
	var best_w: float = 999.0
	for iid: String in ITEM_WEIGHTS:
		if ITEM_WEIGHTS[iid] < best_w:
			best_w = ITEM_WEIGHTS[iid]
			best = iid
	return best


func get_burden_level() -> String:
	var avg: float = get_avg_fill_pct()
	if avg >= 90.0:
		return "Overburdened"
	elif avg >= 60.0:
		return "Heavy"
	elif avg >= 30.0:
		return "Moderate"
	return "Light"

func get_overload_risk_pct() -> float:
	if _pawn_carry.is_empty():
		return 0.0
	return snappedf(float(get_overloaded_pawns().size()) / float(_pawn_carry.size()) * 100.0, 0.1)

func get_mobility_impact() -> String:
	var overloaded: int = get_overloaded_pawns().size()
	if overloaded == 0:
		return "None"
	elif overloaded <= 2:
		return "Minor"
	elif overloaded <= 5:
		return "Significant"
	return "Severe"

func get_summary() -> Dictionary:
	return {
		"item_weight_types": ITEM_WEIGHTS.size(),
		"carrying_pawns": _pawn_carry.size(),
		"base_capacity": BASE_CAPACITY,
		"overloaded": get_overloaded_pawns().size(),
		"avg_fill_pct": get_avg_fill_pct(),
		"heaviest_item": get_heaviest_item(),
		"lightest_item": get_lightest_item(),
		"burden_level": get_burden_level(),
		"overload_risk_pct": get_overload_risk_pct(),
		"mobility_impact": get_mobility_impact(),
		"load_management": get_load_management(),
		"capacity_headroom": get_capacity_headroom(),
		"logistics_strain": get_logistics_strain(),
	}

func get_load_management() -> String:
	var burden := get_burden_level()
	var overload := get_overload_risk_pct()
	if burden in ["Light"] and overload < 10.0:
		return "Well Managed"
	elif burden in ["Moderate", "Light"]:
		return "Adequate"
	return "Struggling"

func get_capacity_headroom() -> float:
	var avg_fill := get_avg_fill_pct()
	return snapped(maxf(100.0 - avg_fill, 0.0), 0.1)

func get_logistics_strain() -> String:
	var overloaded := get_overloaded_pawns().size()
	if overloaded == 0:
		return "None"
	elif overloaded <= 2:
		return "Minor"
	return "Heavy"
