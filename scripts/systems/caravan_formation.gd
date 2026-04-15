extends Node

var _forming_caravans: Dictionary = {}
var _next_id: int = 1
var total_launched: int = 0

const MAX_CARRY_MASS: float = 35.0


func start_forming(leader_id: int) -> int:
	var cid: int = _next_id
	_next_id += 1
	_forming_caravans[cid] = {
		"leader": leader_id,
		"members": [leader_id],
		"items": [],
		"destination": Vector2i.ZERO,
		"ready": false,
	}
	return cid


func add_member(caravan_id: int, pawn_id: int) -> bool:
	if not _forming_caravans.has(caravan_id):
		return false
	var c: Dictionary = _forming_caravans[caravan_id]
	if not c.members.has(pawn_id):
		c.members.append(pawn_id)
	return true


func remove_member(caravan_id: int, pawn_id: int) -> bool:
	if not _forming_caravans.has(caravan_id):
		return false
	var c: Dictionary = _forming_caravans[caravan_id]
	c.members.erase(pawn_id)
	return true


func add_item(caravan_id: int, item_id: String, amount: int) -> bool:
	if not _forming_caravans.has(caravan_id):
		return false
	_forming_caravans[caravan_id].items.append({"item": item_id, "amount": amount})
	return true


func set_destination(caravan_id: int, dest: Vector2i) -> void:
	if _forming_caravans.has(caravan_id):
		_forming_caravans[caravan_id].destination = dest


func get_total_mass(caravan_id: int) -> float:
	if not _forming_caravans.has(caravan_id):
		return 0.0
	var total: float = 0.0
	for entry: Dictionary in _forming_caravans[caravan_id].items:
		total += float(entry.get("amount", 0)) * 0.5
	return total


func get_carry_capacity(caravan_id: int) -> float:
	if not _forming_caravans.has(caravan_id):
		return 0.0
	return _forming_caravans[caravan_id].members.size() * MAX_CARRY_MASS


func validate(caravan_id: int) -> Dictionary:
	if not _forming_caravans.has(caravan_id):
		return {"valid": false, "reason": "No such caravan"}
	var c: Dictionary = _forming_caravans[caravan_id]
	if c.members.size() < 1:
		return {"valid": false, "reason": "No members"}
	if c.destination == Vector2i.ZERO:
		return {"valid": false, "reason": "No destination"}
	var mass := get_total_mass(caravan_id)
	var cap := get_carry_capacity(caravan_id)
	if mass > cap:
		return {"valid": false, "reason": "Overloaded (%.1f/%.1f kg)" % [mass, cap]}
	return {"valid": true, "members": c.members.size(), "items": c.items.size(), "mass": mass, "capacity": cap}


func cancel(caravan_id: int) -> void:
	_forming_caravans.erase(caravan_id)


func launch(caravan_id: int) -> Dictionary:
	var v: Dictionary = validate(caravan_id)
	if not bool(v.get("valid", false)):
		return v
	var c: Dictionary = _forming_caravans[caravan_id]
	_forming_caravans.erase(caravan_id)
	total_launched += 1
	if ColonyLog and ColonyLog.has_method("add_entry"):
		ColonyLog.add_entry("Caravan", "Caravan launched with %d members and %d items." % [c.members.size(), c.items.size()], "info")
	return {"launched": true, "members": c.members.size(), "items": c.items.size()}


func get_forming_details(caravan_id: int) -> Dictionary:
	return _forming_caravans.get(caravan_id, {})


func get_largest_forming() -> Dictionary:
	var best_id: int = -1
	var best_size: int = 0
	for cid: int in _forming_caravans:
		var sz: int = _forming_caravans[cid].members.size()
		if sz > best_size:
			best_size = sz
			best_id = cid
	if best_id < 0:
		return {}
	return {"id": best_id, "members": best_size}


func get_overloaded_caravans() -> Array[int]:
	var result: Array[int] = []
	for cid: int in _forming_caravans:
		if get_total_mass(cid) > get_carry_capacity(cid):
			result.append(cid)
	return result


func get_all_forming_ids() -> Array[int]:
	var result: Array[int] = []
	for cid: int in _forming_caravans:
		result.append(cid)
	return result


func get_average_caravan_size() -> float:
	if _forming_caravans.is_empty():
		return 0.0
	var total: int = 0
	for cid: int in _forming_caravans:
		var c: Dictionary = _forming_caravans[cid]
		total += (c.get("members", []) as Array).size()
	return float(total) / float(_forming_caravans.size())


func get_largest_caravan() -> Dictionary:
	var best: Dictionary = {}
	var best_size: int = 0
	for cid: int in _forming_caravans:
		var c: Dictionary = _forming_caravans[cid]
		var s: int = (c.get("members", []) as Array).size()
		if s > best_size:
			best_size = s
			best = c
	return best


func is_any_forming() -> bool:
	return not _forming_caravans.is_empty()


func get_launch_success_rate() -> float:
	if total_launched == 0 and _forming_caravans.is_empty():
		return 0.0
	var total_attempts: int = total_launched
	if total_attempts == 0:
		return 0.0
	return snappedf(float(total_launched) / float(total_attempts) * 100.0, 0.1)


func get_largest_caravan_size() -> int:
	var largest: int = 0
	for cid: int in _forming_caravans:
		var c: Dictionary = _forming_caravans[cid]
		var sz: int = c.get("pawns", []).size()
		if sz > largest:
			largest = sz
	return largest


func get_overload_percentage() -> float:
	if _forming_caravans.is_empty():
		return 0.0
	var overloaded: int = get_overloaded_caravans().size()
	return snappedf(float(overloaded) / float(_forming_caravans.size()) * 100.0, 0.1)


func get_total_forming_pawns() -> int:
	var total: int = 0
	for cid: int in _forming_caravans:
		total += _forming_caravans[cid].get("pawns", []).size()
	return total


func get_avg_items_per_caravan() -> float:
	if _forming_caravans.is_empty():
		return 0.0
	var total: int = 0
	for cid: int in _forming_caravans:
		total += _forming_caravans[cid].get("items", []).size()
	return float(total) / float(_forming_caravans.size())


func get_launch_rate() -> float:
	var total_attempted: int = total_launched + _forming_caravans.size()
	if total_attempted == 0:
		return 0.0
	return float(total_launched) / float(total_attempted) * 100.0


func get_total_forming_items() -> int:
	var total: int = 0
	for cid: int in _forming_caravans:
		total += _forming_caravans[cid].get("items", []).size()
	return total


func get_avg_mass_per_caravan() -> float:
	if _forming_caravans.is_empty():
		return 0.0
	var total: float = 0.0
	for cid: int in _forming_caravans:
		total += get_total_mass(cid)
	return snappedf(total / float(_forming_caravans.size()), 0.1)


func get_ready_caravan_count() -> int:
	var count: int = 0
	for cid: int in _forming_caravans:
		var v: Dictionary = validate(cid)
		if bool(v.get("valid", false)):
			count += 1
	return count


func get_logistics_rating() -> String:
	var overload: float = get_overload_percentage()
	if overload == 0.0:
		return "Optimal"
	elif overload < 20.0:
		return "Good"
	elif overload < 50.0:
		return "Strained"
	return "Overloaded"

func get_throughput_score() -> float:
	if total_launched == 0:
		return 0.0
	return snappedf(get_launch_rate() * get_average_caravan_size(), 0.1)

func get_readiness_pct() -> float:
	if _forming_caravans.is_empty():
		return 0.0
	return snappedf(float(get_ready_caravan_count()) / float(_forming_caravans.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"forming_count": _forming_caravans.size(),
		"total_launched": total_launched,
		"overloaded": get_overloaded_caravans().size(),
		"avg_size": snappedf(get_average_caravan_size(), 0.1),
		"any_forming": is_any_forming(),
		"largest_size": get_largest_caravan_size(),
		"overload_pct": get_overload_percentage(),
		"total_forming_pawns": get_total_forming_pawns(),
		"avg_items": snappedf(get_avg_items_per_caravan(), 0.1),
		"launch_rate": snappedf(get_launch_rate(), 0.1),
		"total_forming_items": get_total_forming_items(),
		"avg_mass": get_avg_mass_per_caravan(),
		"ready_count": get_ready_caravan_count(),
		"logistics_rating": get_logistics_rating(),
		"throughput_score": get_throughput_score(),
		"readiness_pct": get_readiness_pct(),
		"expedition_ecosystem_health": get_expedition_ecosystem_health(),
		"logistical_sophistication": get_logistical_sophistication(),
		"caravan_governance": get_caravan_governance(),
	}

func get_expedition_ecosystem_health() -> float:
	var readiness := get_readiness_pct()
	var logistics := get_logistics_rating()
	var l_val: float = 90.0 if logistics == "Excellent" else (60.0 if logistics in ["Good", "Adequate"] else 30.0)
	var overload := get_overload_percentage()
	return snapped((readiness + l_val + maxf(100.0 - overload, 0.0)) / 3.0, 0.1)

func get_logistical_sophistication() -> float:
	var throughput := get_throughput_score()
	var avg_items := get_avg_items_per_caravan()
	var launch_rate := get_launch_rate()
	return snapped((throughput + minf(avg_items * 5.0, 100.0) + minf(launch_rate * 10.0, 100.0)) / 3.0, 0.1)

func get_caravan_governance() -> String:
	var health := get_expedition_ecosystem_health()
	var sophistication := get_logistical_sophistication()
	if health >= 65.0 and sophistication >= 50.0:
		return "Professional"
	elif health >= 35.0 or sophistication >= 25.0:
		return "Developing"
	return "Improvised"
