class_name PowerManager
extends RefCounted

## Simple power net system. Generators produce, consumers draw, batteries store.

signal power_status_changed(net_id: int, surplus: float)

var nets: Array[Dictionary] = []


func rebuild_nets(map: MapData) -> void:
	nets.clear()
	if not ThingManager:
		return

	var conduit_cells: Dictionary = {}
	var power_buildings: Array[Thing] = []

	for t: Thing in ThingManager.things:
		if not (t is Building):
			continue
		var b := t as Building
		if b.def_name == "PowerConduit":
			conduit_cells[b.grid_pos] = true
		elif b.build_state == Building.BuildState.COMPLETE:
			if _is_power_device(b.def_name):
				power_buildings.append(t)

	var visited: Dictionary = {}
	for t: Thing in power_buildings:
		if visited.has(t.id):
			continue
		var net := _trace_net(t, conduit_cells, power_buildings, visited)
		if not net.is_empty():
			nets.append(net)


func _trace_net(start: Thing, conduits: Dictionary, all_buildings: Array[Thing], visited: Dictionary) -> Dictionary:
	var net_gen: float = 0.0
	var net_draw: float = 0.0
	var net_stored: float = 0.0
	var net_capacity: float = 0.0
	var members: Array[int] = []

	var queue: Array[Vector2i] = [start.grid_pos]
	var cell_visited: Dictionary = {}

	while queue.size() > 0:
		var pos: Vector2i = queue.pop_front() as Vector2i
		if cell_visited.has(pos):
			continue
		cell_visited[pos] = true

		for b: Thing in all_buildings:
			if b.grid_pos == pos and not visited.has(b.id):
				visited[b.id] = true
				members.append(b.id)
				var bld := b as Building
				var pw := _get_power(bld.def_name)
				net_gen += pw.get("gen", 0.0)
				net_draw += pw.get("draw", 0.0)
				net_capacity += pw.get("capacity", 0.0)

		for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nb: Vector2i = pos + dir
			if conduits.has(nb) or _has_building_at(nb, all_buildings):
				queue.append(nb)

	if members.is_empty():
		return {}

	return {
		"generation": net_gen,
		"consumption": net_draw,
		"surplus": net_gen - net_draw,
		"stored": net_stored,
		"capacity": net_capacity,
		"members": members,
	}


func _has_building_at(pos: Vector2i, buildings: Array[Thing]) -> bool:
	for b: Thing in buildings:
		if b.grid_pos == pos:
			return true
	return false


func _is_power_device(def_name: String) -> bool:
	return _get_power(def_name).size() > 0


func _get_power(def_name: String) -> Dictionary:
	if DefDB:
		var data: Dictionary = DefDB.get_def("ThingDef", def_name)
		if not data.is_empty():
			var result: Dictionary = {}
			var gen: float = float(data.get("powerGen", 0))
			var draw: float = float(data.get("powerDraw", 0))
			var cap: float = float(data.get("powerCapacity", 0))
			if gen > 0.0:
				result["gen"] = gen
			if draw > 0.0:
				result["draw"] = draw
			if cap > 0.0:
				result["capacity"] = cap
			if not result.is_empty():
				return result
	var power_data: Dictionary = {
		"WoodFiredGenerator": {"gen": 1000.0, "draw": 0.0},
		"SolarGenerator": {"gen": 1700.0, "draw": 0.0},
		"Battery": {"gen": 0.0, "draw": 0.0, "capacity": 600.0},
		"MiniTurret": {"gen": 0.0, "draw": 80.0},
		"CookingStove": {"gen": 0.0, "draw": 350.0},
		"MachiningTable": {"gen": 0.0, "draw": 350.0},
		"HiTechResearchBench": {"gen": 0.0, "draw": 250.0},
		"CommsConsole": {"gen": 0.0, "draw": 200.0},
		"SunLamp": {"gen": 0.0, "draw": 2900.0},
	}
	return power_data.get(def_name, {})


func tick_power() -> void:
	for net: Dictionary in nets:
		var surplus: float = net.generation - net.consumption
		if surplus > 0.0 and net.capacity > 0.0:
			net["stored"] = minf(net.capacity, net.stored + surplus * 0.01)
		elif surplus < 0.0 and net.stored > 0.0:
			net["stored"] = maxf(0.0, net.stored + surplus * 0.01)


func get_total_generation() -> float:
	var total: float = 0.0
	for n: Dictionary in nets:
		total += n.get("generation", 0.0)
	return snappedf(total, 0.1)

func get_total_consumption() -> float:
	var total: float = 0.0
	for n: Dictionary in nets:
		total += n.get("consumption", 0.0)
	return snappedf(total, 0.1)

func get_total_stored_energy() -> float:
	var total: float = 0.0
	for n: Dictionary in nets:
		total += n.get("stored", 0.0)
	return snappedf(total, 0.1)

func get_net_count() -> int:
	return nets.size()

func get_power_efficiency() -> float:
	var gen: float = get_total_generation()
	var cons: float = get_total_consumption()
	if gen <= 0.0:
		return 0.0
	return snappedf(minf(cons / gen, 1.0) * 100.0, 0.1)


func get_weakest_net_index() -> int:
	if nets.is_empty():
		return -1
	var worst_idx: int = 0
	var worst_surplus: float = nets[0].get("surplus", 0.0)
	for i: int in range(1, nets.size()):
		var s: float = nets[i].get("surplus", 0.0)
		if s < worst_surplus:
			worst_surplus = s
			worst_idx = i
	return worst_idx


func is_any_net_deficit() -> bool:
	for n: Dictionary in nets:
		if n.get("surplus", 0.0) < 0.0:
			return true
	return false


func get_grid_resilience() -> float:
	if nets.is_empty():
		return 0.0
	var total_score := 0.0
	for n: Dictionary in nets:
		var gen: float = n.get("generation", 0.0)
		var cons: float = n.get("consumption", 0.0)
		var stored: float = n.get("stored", 0.0)
		var cap: float = n.get("capacity", 0.0)
		var surplus_ratio := (gen - cons) / maxf(cons, 1.0)
		var storage_ratio := stored / maxf(cap, 1.0)
		total_score += clampf(surplus_ratio + storage_ratio, 0.0, 2.0)
	return snapped(total_score / float(nets.size()) * 50.0, 0.1)

func get_load_balance_score() -> float:
	if nets.size() < 2:
		return 100.0
	var loads: Array[float] = []
	for n: Dictionary in nets:
		var gen: float = n.get("generation", 0.0)
		var cons: float = n.get("consumption", 0.0)
		loads.append(cons / maxf(gen, 1.0))
	var avg := 0.0
	for l: float in loads:
		avg += l
	avg /= float(loads.size())
	var variance := 0.0
	for l: float in loads:
		variance += (l - avg) * (l - avg)
	variance /= float(loads.size())
	return snapped(maxf(0.0, 100.0 - variance * 100.0), 0.1)

func get_outage_risk_pct() -> float:
	if nets.is_empty():
		return 0.0
	var at_risk := 0
	for n: Dictionary in nets:
		var surplus: float = n.get("surplus", 0.0)
		var stored: float = n.get("stored", 0.0)
		if surplus <= 0.0 and stored <= 0.0:
			at_risk += 1
		elif surplus < 0.0:
			at_risk += 1
	return snapped(float(at_risk) / float(nets.size()) * 100.0, 0.1)

func get_summary() -> Array[Dictionary]:
	return nets.map(func(n: Dictionary) -> Dictionary:
		return {
			"generation": snappedf(n.generation, 0.1),
			"consumption": snappedf(n.consumption, 0.1),
			"surplus": snappedf(n.surplus, 0.1),
			"stored": snappedf(n.stored, 0.1),
			"members": n.members.size(),
			"grid_resilience": get_grid_resilience(),
			"load_balance": get_load_balance_score(),
			"outage_risk_pct": get_outage_risk_pct(),
		})
