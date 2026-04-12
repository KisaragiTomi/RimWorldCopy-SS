extends Node

## Unified power grid system. Discovers connected power nets via BFS
## through conduits and power buildings, reads power values from Building's
## DefDB-driven properties, handles battery charge/discharge each tick.

signal power_changed(net_index: int, surplus: float)

var nets: Array[Dictionary] = []
var _dirty: bool = true


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)
	if ThingManager:
		ThingManager.thing_spawned.connect(_on_thing_changed)
		ThingManager.thing_destroyed.connect(_on_thing_changed)


func _on_thing_changed(_thing: Thing) -> void:
	_dirty = true


func _on_rare_tick(_tick: int) -> void:
	if _dirty:
		rebuild_nets()
		_dirty = false
	tick_power()


func rebuild_nets() -> void:
	nets.clear()
	if not ThingManager:
		return

	var conduit_cells: Dictionary = {}
	var power_buildings: Array[Building] = []

	for t: Thing in ThingManager.things:
		if not (t is Building):
			continue
		var b: Building = t as Building
		if b.build_state != Building.BuildState.COMPLETE:
			continue
		if b.def_name == "PowerConduit":
			conduit_cells[b.grid_pos] = true
		elif b.power_draw > 0.0 or b.power_gen > 0.0:
			power_buildings.append(b)

	var visited_ids: Dictionary = {}
	for b: Building in power_buildings:
		if visited_ids.has(b.id):
			continue
		var net := _trace_net(b, conduit_cells, power_buildings, visited_ids)
		if not net.is_empty():
			nets.append(net)


func _trace_net(start: Building, conduits: Dictionary, all_buildings: Array[Building], visited: Dictionary) -> Dictionary:
	var net_gen: float = 0.0
	var net_draw: float = 0.0
	var net_stored: float = 0.0
	var net_capacity: float = 0.0
	var members: Array[int] = []
	var member_buildings: Array[Building] = []

	var queue: Array[Vector2i] = [start.grid_pos]
	var cell_visited: Dictionary = {}

	while queue.size() > 0:
		var pos: Vector2i = queue.pop_front() as Vector2i
		if cell_visited.has(pos):
			continue
		cell_visited[pos] = true

		for b: Building in all_buildings:
			if b.grid_pos == pos and not visited.has(b.id):
				visited[b.id] = true
				members.append(b.id)
				member_buildings.append(b)
				net_gen += b.power_gen
				net_draw += b.power_draw
				var def_data: Dictionary = DefDB.get_def("ThingDef", b.def_name) if DefDB else {}
				net_capacity += float(def_data.get("powerCapacity", 0))

		for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nb: Vector2i = pos + dir
			if conduits.has(nb) or _has_building_at(nb, all_buildings):
				queue.append(nb)

	if members.is_empty():
		return {}

	var surplus: float = net_gen - net_draw
	var status: String = "powered"
	if net_gen <= 0.0 and net_draw > 0.0:
		status = "unpowered"
	elif surplus < 0.0 and net_stored <= 0.0:
		status = "brownout"

	return {
		"generation": net_gen,
		"consumption": net_draw,
		"surplus": surplus,
		"stored": net_stored,
		"capacity": net_capacity,
		"members": members,
		"status": status,
	}


func _has_building_at(pos: Vector2i, buildings: Array[Building]) -> bool:
	for b: Building in buildings:
		if b.grid_pos == pos:
			return true
	return false


func tick_power() -> void:
	for i: int in range(nets.size()):
		var net: Dictionary = nets[i]
		var surplus: float = net.generation - net.consumption
		if surplus > 0.0 and net.capacity > 0.0:
			net["stored"] = minf(net.capacity, net.stored + surplus * 0.01)
			net["status"] = "powered"
		elif surplus < 0.0 and net.stored > 0.0:
			var deficit: float = absf(surplus) * 0.01
			net["stored"] = maxf(0.0, net.stored - deficit)
			net["status"] = "powered" if net.stored > 0.0 else "brownout"
		elif surplus < 0.0:
			net["status"] = "brownout"
		else:
			net["status"] = "powered"
		net["surplus"] = surplus
		_sync_building_power_state(net)
		power_changed.emit(i, surplus)


func _sync_building_power_state(net: Dictionary) -> void:
	if not ThingManager:
		return
	var powered: bool = net.get("status", "") == "powered"
	for member_id: int in net.get("members", []):
		for t: Thing in ThingManager.things:
			if t.id == member_id and t is Building:
				(t as Building).is_powered = powered


func is_powered(building_id: int) -> bool:
	for net: Dictionary in nets:
		if net.members.has(building_id):
			return net.status == "powered"
	return false


func get_net_for_building(building_id: int) -> Dictionary:
	for net: Dictionary in nets:
		if net.members.has(building_id):
			return net
	return {}


func get_total_generation() -> float:
	var total: float = 0.0
	for net: Dictionary in nets:
		total += net.generation
	return total


func get_total_consumption() -> float:
	var total: float = 0.0
	for net: Dictionary in nets:
		total += net.consumption
	return total


func get_total_stored() -> float:
	var total: float = 0.0
	for net: Dictionary in nets:
		total += net.stored
	return total


func get_grid_count() -> int:
	return nets.size()


func get_grid_for_pos(pos: Vector2i) -> int:
	if not ThingManager:
		return -1
	for i: int in range(nets.size()):
		for member_id: int in nets[i].members:
			for t: Thing in ThingManager.things:
				if t.id == member_id and t.grid_pos == pos:
					return i
	return -1


func get_brownout_nets() -> int:
	var count: int = 0
	for net: Dictionary in nets:
		if net.status == "brownout":
			count += 1
	return count


func get_largest_net() -> Dictionary:
	var best: Dictionary = {}
	var best_size: int = 0
	for net: Dictionary in nets:
		var mlist: Array = net.get("members", [])
		if mlist.size() > best_size:
			best_size = mlist.size()
			best = net
	return best


func get_total_surplus() -> float:
	var total: float = 0.0
	for net: Dictionary in nets:
		total += net.surplus
	return snappedf(total, 0.1)


func get_most_efficient_net() -> int:
	var best_idx: int = -1
	var best_surplus: float = -999.0
	for i: int in range(nets.size()):
		if nets[i].surplus > best_surplus:
			best_surplus = nets[i].surplus
			best_idx = i
	return best_idx


func get_total_capacity() -> float:
	var total: float = 0.0
	for net: Dictionary in nets:
		total += net.capacity
	return total


func get_battery_fill_percent() -> float:
	var cap: float = get_total_capacity()
	if cap <= 0.0:
		return 0.0
	return (get_total_stored() / cap) * 100.0


func get_grid_stability() -> String:
	var brownout: int = get_brownout_nets()
	if brownout == 0:
		return "Stable"
	elif brownout <= 1:
		return "Stressed"
	return "Unstable"

func get_brownout_risk_pct() -> float:
	if nets.is_empty():
		return 0.0
	return snappedf(float(get_brownout_nets()) / float(nets.size()) * 100.0, 0.1)

func get_reserve_rating() -> String:
	var stored: float = get_total_stored()
	var consumption: float = get_total_consumption()
	if consumption <= 0.0:
		return "N/A"
	var ratio: float = stored / consumption
	if ratio >= 2.0:
		return "Ample"
	elif ratio >= 1.0:
		return "Adequate"
	elif ratio > 0.0:
		return "Low"
	return "Empty"

func get_summary() -> Dictionary:
	return {
		"grid_count": nets.size(),
		"total_generation": snappedf(get_total_generation(), 0.1),
		"total_consumption": snappedf(get_total_consumption(), 0.1),
		"total_stored": snappedf(get_total_stored(), 0.1),
		"total_surplus": get_total_surplus(),
		"brownout_nets": get_brownout_nets(),
		"nets": nets.map(func(n: Dictionary) -> Dictionary: return {
			"gen": snappedf(n.generation, 0.1),
			"draw": snappedf(n.consumption, 0.1),
			"surplus": snappedf(n.surplus, 0.1),
			"stored": snappedf(n.stored, 0.1),
			"status": n.status,
			"members": n.get("members", []).size(),
		}),
		"efficiency_pct": snappedf(get_total_consumption() / maxf(get_total_generation(), 0.01) * 100.0, 0.1),
		"avg_members_per_net": snappedf(float(nets.reduce(func(acc: int, n: Dictionary) -> int: return acc + n.get("members", []).size(), 0)) / maxf(float(nets.size()), 1.0), 0.1),
		"grid_stability": get_grid_stability(),
		"brownout_risk_pct": get_brownout_risk_pct(),
		"reserve_rating": get_reserve_rating(),
		"power_infrastructure_maturity": get_power_infrastructure_maturity(),
		"load_balance_score": get_load_balance_score(),
		"energy_independence": get_energy_independence(),
		"grid_scalability": get_grid_scalability(),
		"peak_demand_buffer_pct": get_peak_demand_buffer(),
		"power_autonomy_hours": get_power_autonomy_hours(),
	}

func get_power_infrastructure_maturity() -> String:
	var grid_count := nets.size()
	var stability := get_grid_stability()
	if grid_count >= 3 and stability in ["Stable", "Robust"]:
		return "Mature"
	elif grid_count >= 1:
		return "Developing"
	return "None"

func get_load_balance_score() -> float:
	if nets.is_empty():
		return 0.0
	var total_surplus := get_total_surplus()
	var total_gen := get_total_generation()
	if total_gen <= 0.0:
		return 0.0
	return snapped(minf(absf(total_surplus) / total_gen * 100.0, 100.0), 0.1)

func get_energy_independence() -> String:
	var surplus := get_total_surplus()
	var stored := get_total_stored()
	if surplus > 0.0 and stored > 100.0:
		return "Self-Sufficient"
	elif surplus > 0.0:
		return "Surplus"
	elif stored > 0.0:
		return "Drawing Reserves"
	return "Deficit"

func get_grid_scalability() -> String:
	var total_gen := get_total_generation()
	var total_con := get_total_consumption()
	if total_gen <= 0.0:
		return "N/A"
	var headroom: float = (total_gen - total_con) / total_gen
	if headroom >= 0.4:
		return "Highly Scalable"
	elif headroom >= 0.2:
		return "Scalable"
	elif headroom >= 0.0:
		return "Tight"
	return "Over Capacity"

func get_peak_demand_buffer() -> float:
	var gen := get_total_generation()
	var con := get_total_consumption()
	if con <= 0.0:
		return 100.0
	return snappedf((gen - con) / con * 100.0, 0.1)

func get_power_autonomy_hours() -> float:
	var stored := get_total_stored()
	var con := get_total_consumption()
	if con <= 0.0:
		return 999.0
	return snappedf(stored / con * 2.5, 0.1)
