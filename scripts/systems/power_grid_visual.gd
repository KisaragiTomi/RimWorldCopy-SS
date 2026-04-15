extends Node

var _generators: Dictionary = {}
var _consumers: Dictionary = {}
var _batteries: Dictionary = {}


func register_generator(building_id: int, output_watts: float) -> void:
	_generators[building_id] = {"output": output_watts, "active": true}


func register_consumer(building_id: int, draw_watts: float) -> void:
	_consumers[building_id] = {"draw": draw_watts, "active": true}


func register_battery(building_id: int, capacity: float) -> void:
	_batteries[building_id] = {"capacity": capacity, "stored": 0.0, "active": true}


func charge_battery(building_id: int, amount: float) -> void:
	if _batteries.has(building_id):
		var b: Dictionary = _batteries[building_id]
		b.stored = minf(float(b.stored) + amount, float(b.capacity))


func discharge_battery(building_id: int, amount: float) -> float:
	if not _batteries.has(building_id):
		return 0.0
	var b: Dictionary = _batteries[building_id]
	var actual: float = minf(amount, float(b.stored))
	b.stored = float(b.stored) - actual
	return actual


func get_total_production() -> float:
	var total: float = 0.0
	for gid: int in _generators:
		var g: Dictionary = _generators[gid]
		if bool(g.get("active", false)):
			total += float(g.get("output", 0.0))
	return total


func get_total_consumption() -> float:
	var total: float = 0.0
	for cid: int in _consumers:
		var c: Dictionary = _consumers[cid]
		if bool(c.get("active", false)):
			total += float(c.get("draw", 0.0))
	return total


func get_total_stored() -> float:
	var total: float = 0.0
	for bid: int in _batteries:
		total += float(_batteries[bid].get("stored", 0.0))
	return total


func get_power_status() -> String:
	var prod: float = get_total_production()
	var cons: float = get_total_consumption()
	if prod >= cons:
		return "Surplus"
	elif get_total_stored() > 0:
		return "Draining"
	else:
		return "Blackout"


func get_surplus() -> float:
	return get_total_production() - get_total_consumption()


func get_battery_fill_pct() -> float:
	var total_cap: float = 0.0
	var total_stored: float = 0.0
	for bid: int in _batteries:
		total_cap += float(_batteries[bid].get("capacity", 0.0))
		total_stored += float(_batteries[bid].get("stored", 0.0))
	if total_cap <= 0:
		return 0.0
	return snappedf(total_stored / total_cap * 100.0, 0.1)


func get_largest_generator() -> Dictionary:
	var best_id: int = -1
	var best_output: float = 0.0
	for gid: int in _generators:
		var output: float = float(_generators[gid].get("output", 0.0))
		if output > best_output:
			best_output = output
			best_id = gid
	if best_id < 0:
		return {}
	return {"id": best_id, "output": best_output}


func get_efficiency() -> float:
	var prod: float = get_total_production()
	if prod <= 0.0:
		return 0.0
	return snappedf(get_total_consumption() / prod * 100.0, 0.1)


func get_biggest_generator() -> Dictionary:
	var best_id: int = -1
	var best_prod: float = 0.0
	for gid: int in _generators:
		var prod: float = float(_generators[gid].get("output", 0.0))
		if prod > best_prod:
			best_prod = prod
			best_id = gid
	if best_id < 0:
		return {}
	return {"id": best_id, "output": snapped(best_prod, 0.1)}


func is_power_critical() -> bool:
	return get_power_status() == "blackout" or get_battery_fill_pct() < 10.0


func get_active_generator_count() -> int:
	var count: int = 0
	for gid: int in _generators:
		if bool(_generators[gid].get("active", false)):
			count += 1
	return count

func get_total_battery_capacity() -> float:
	var total: float = 0.0
	for bid: int in _batteries:
		total += float(_batteries[bid].get("capacity", 0.0))
	return snappedf(total, 0.1)

func get_avg_consumer_draw() -> float:
	if _consumers.is_empty():
		return 0.0
	var total: float = 0.0
	for cid: int in _consumers:
		total += float(_consumers[cid].get("draw", 0.0))
	return snappedf(total / float(_consumers.size()), 0.1)

func get_grid_resilience() -> String:
	var fill: float = get_battery_fill_pct()
	var surplus: float = get_surplus()
	if fill >= 80.0 and surplus > 0:
		return "Robust"
	elif fill >= 40.0:
		return "Adequate"
	elif fill > 0.0:
		return "Fragile"
	return "Critical"

func get_renewable_ratio() -> float:
	if _generators.is_empty():
		return 0.0
	var renewable: int = 0
	for gid: int in _generators:
		var g: Dictionary = _generators[gid]
		var gtype: String = g.get("type", "")
		if gtype == "solar" or gtype == "wind" or gtype == "geothermal":
			renewable += 1
	return snappedf(float(renewable) / float(_generators.size()) * 100.0, 0.1)

func get_load_balance() -> String:
	var prod: float = get_total_production()
	var cons: float = get_total_consumption()
	if prod == 0.0:
		return "No Power"
	var ratio: float = cons / prod
	if ratio <= 0.5:
		return "Light Load"
	elif ratio <= 0.8:
		return "Balanced"
	elif ratio <= 1.0:
		return "Heavy"
	return "Overloaded"

func get_summary() -> Dictionary:
	return {
		"generators": _generators.size(),
		"consumers": _consumers.size(),
		"batteries": _batteries.size(),
		"production_w": snapped(get_total_production(), 0.1),
		"consumption_w": snapped(get_total_consumption(), 0.1),
		"stored_wd": snapped(get_total_stored(), 0.1),
		"surplus_w": snapped(get_surplus(), 0.1),
		"battery_fill_pct": get_battery_fill_pct(),
		"status": get_power_status(),
		"efficiency_pct": get_efficiency(),
		"biggest_generator": get_biggest_generator(),
		"critical": is_power_critical(),
		"active_generators": get_active_generator_count(),
		"total_battery_capacity": get_total_battery_capacity(),
		"avg_consumer_draw": get_avg_consumer_draw(),
		"grid_resilience": get_grid_resilience(),
		"renewable_ratio_pct": get_renewable_ratio(),
		"load_balance": get_load_balance(),
		"power_ecosystem_health": get_power_ecosystem_health(),
		"energy_sovereignty_index": get_energy_sovereignty_index(),
		"grid_governance": get_grid_governance(),
	}

func get_power_ecosystem_health() -> float:
	var efficiency := get_efficiency()
	var resilience := get_grid_resilience()
	var r_val: float = 90.0 if resilience == "Robust" else (60.0 if resilience == "Adequate" else 30.0)
	var renewable := get_renewable_ratio()
	return snapped((efficiency + r_val + renewable) / 3.0, 0.1)

func get_energy_sovereignty_index() -> float:
	var surplus := get_surplus()
	var production := get_total_production()
	if production <= 0.0:
		return 0.0
	var self_sufficiency := minf(surplus / production * 100.0, 100.0)
	var battery_fill := get_battery_fill_pct()
	return snapped((maxf(self_sufficiency, 0.0) + battery_fill) / 2.0, 0.1)

func get_grid_governance() -> String:
	var health := get_power_ecosystem_health()
	var sovereignty := get_energy_sovereignty_index()
	if health >= 65.0 and sovereignty >= 50.0:
		return "Well Managed"
	elif health >= 35.0 or sovereignty >= 25.0:
		return "Developing"
	return "Fragile"
