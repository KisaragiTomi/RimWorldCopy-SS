class_name Caravan
extends RefCounted

## A caravan moving on the world map with food consumption and encounters.

signal arrived(destination: Vector2i)
signal returned_home()
signal food_ran_out()
signal encounter_triggered(encounter_type: String)

var id: int = 0
var members: Array[int] = []
var inventory: Dictionary = {}
var position: Vector2i = Vector2i.ZERO
var destination: Vector2i = Vector2i(-1, -1)
var path: Array[Vector2i] = []
var path_index: int = 0
var speed: float = 1.0
var move_progress: float = 0.0
var state: String = "Idle"
var days_traveling: int = 0
var food_supply: float = 10.0
var _tick_counter: int = 0
var _rng := RandomNumberGenerator.new()
var encounters: Array[String] = []

static var _next_id: int = 1

const ENCOUNTER_TYPES := ["Ambush", "Trader", "Ruins", "Refugee", "BrokenVehicle", "Wildlife"]
const FOOD_PER_MEMBER_PER_DAY := 1.5


func _init() -> void:
	id = _next_id
	_next_id += 1
	_rng.seed = randi()


func add_member(pawn_id: int) -> void:
	if pawn_id not in members:
		members.append(pawn_id)


func remove_member(pawn_id: int) -> void:
	members.erase(pawn_id)


func add_food(amount: float) -> void:
	food_supply += amount


func add_item(item_name: String, count: int) -> void:
	inventory[item_name] = inventory.get(item_name, 0) + count


func get_days_of_food() -> float:
	if members.is_empty():
		return food_supply
	return food_supply / (float(members.size()) * FOOD_PER_MEMBER_PER_DAY)


func set_destination(dest: Vector2i, world: WorldGrid) -> bool:
	if dest == position:
		return false
	destination = dest
	path = _find_world_path(world, position, dest)
	path_index = 0
	state = "Traveling"
	days_traveling = 0
	return path.size() > 0


func tick_movement() -> void:
	if state != "Traveling" or path.is_empty():
		return

	_tick_counter += 1
	move_progress += speed * 0.02
	if move_progress >= 1.0:
		move_progress = 0.0
		if path_index < path.size():
			position = path[path_index]
			path_index += 1
			_consume_food()
			_check_encounter()
			if path_index >= path.size():
				state = "Arrived"
				arrived.emit(destination)

	if _tick_counter % 2500 == 0:
		days_traveling += 1


func _consume_food() -> void:
	var consumption: float = float(members.size()) * FOOD_PER_MEMBER_PER_DAY * 0.1
	food_supply = maxf(0.0, food_supply - consumption)
	if food_supply <= 0.0:
		food_ran_out.emit()


func _check_encounter() -> void:
	if _rng.randf() > 0.08:
		return
	var enc: String = ENCOUNTER_TYPES[_rng.randi_range(0, ENCOUNTER_TYPES.size() - 1)]
	encounters.append(enc)
	encounter_triggered.emit(enc)


func return_home(home: Vector2i, world: WorldGrid) -> void:
	set_destination(home, world)
	state = "Returning"


func tick_return() -> void:
	if state != "Returning" or path.is_empty():
		return
	_tick_counter += 1
	move_progress += speed * 0.02
	if move_progress >= 1.0:
		move_progress = 0.0
		if path_index < path.size():
			position = path[path_index]
			path_index += 1
			_consume_food()
			if path_index >= path.size():
				state = "Home"
				returned_home.emit()


func _find_world_path(world: WorldGrid, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var open: Array[Dictionary] = [{"pos": from, "g": 0.0, "f": _heuristic(from, to), "parent": Vector2i(-1, -1)}]
	var closed: Dictionary = {}
	var parent_map: Dictionary = {}

	while open.size() > 0:
		open.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.f < b.f)
		var current: Dictionary = open.pop_front()
		var cpos: Vector2i = current.pos

		if cpos == to:
			return _reconstruct(parent_map, from, to)

		if closed.has(cpos):
			continue
		closed[cpos] = true

		for nb: Vector2i in world.get_hex_neighbors(cpos.x, cpos.y):
			if closed.has(nb):
				continue
			var tile := world.get_tile(nb.x, nb.y)
			if tile.is_empty() or tile.biome == "Ocean" or tile.biome == "SeaIce":
				continue
			var move_cost: float = 1.0
			if tile.hilliness == "Mountainous":
				move_cost = 3.0
			elif tile.hilliness == "LargeHills":
				move_cost = 2.0
			elif tile.hilliness == "SmallHills":
				move_cost = 1.5
			var new_g: float = current.g + move_cost
			var existing := open.filter(func(o: Dictionary) -> bool: return o.pos == nb)
			if existing.size() > 0 and existing[0].g <= new_g:
				continue
			parent_map[nb] = cpos
			open.append({"pos": nb, "g": new_g, "f": new_g + _heuristic(nb, to), "parent": cpos})

	return []


func _heuristic(a: Vector2i, b: Vector2i) -> float:
	return absf(a.x - b.x) + absf(a.y - b.y) as float


func _reconstruct(parent_map: Dictionary, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var cur := to
	while cur != from:
		result.push_front(cur)
		if not parent_map.has(cur):
			break
		cur = parent_map[cur]
	return result


func get_encounter_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for enc: String in encounters:
		dist[enc] = dist.get(enc, 0) + 1
	return dist


func get_total_inventory_count() -> int:
	var total: int = 0
	for item: String in inventory:
		total += inventory[item]
	return total


func is_starving() -> bool:
	return food_supply <= 0.0 and not members.is_empty()


func get_food_per_member() -> float:
	if members.is_empty():
		return food_supply
	return snappedf(food_supply / float(members.size()), 0.1)

func get_unique_encounter_count() -> int:
	var seen: Array[String] = []
	for enc: String in encounters:
		if not seen.has(enc):
			seen.append(enc)
	return seen.size()

func get_path_completion_pct() -> float:
	if path.is_empty():
		return 0.0
	return snappedf(float(path_index) / float(path.size()) * 100.0, 0.1)

func get_encounter_rate() -> float:
	if days_traveling <= 0:
		return 0.0
	return snappedf(float(encounters.size()) / float(days_traveling), 0.01)

func get_most_common_encounter() -> String:
	var dist := get_encounter_distribution()
	var best: String = ""
	var best_cnt: int = 0
	for enc: String in dist:
		if dist[enc] > best_cnt:
			best_cnt = dist[enc]
			best = enc
	return best

func get_inventory_variety() -> int:
	return inventory.size()

func get_food_urgency() -> String:
	var days: float = get_days_of_food()
	if days <= 0.0:
		return "Starving"
	elif days < 1.0:
		return "Critical"
	elif days < 3.0:
		return "Low"
	return "Sufficient"

func get_travel_efficiency() -> float:
	if days_traveling <= 0 or path.is_empty():
		return 0.0
	return snappedf(float(path_index) / float(days_traveling), 0.01)

func get_danger_encounter_pct() -> float:
	if encounters.is_empty():
		return 0.0
	var danger: int = 0
	for enc: String in encounters:
		if enc == "Ambush" or enc == "Wildlife":
			danger += 1
	return snappedf(float(danger) / float(encounters.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"id": id,
		"state": state,
		"position": [position.x, position.y],
		"destination": [destination.x, destination.y],
		"members": members.size(),
		"path_progress": str(path_index) + "/" + str(path.size()),
		"food_supply": snappedf(food_supply, 0.1),
		"days_of_food": snappedf(get_days_of_food(), 0.1),
		"days_traveling": days_traveling,
		"encounters": encounters.size(),
		"inventory_types": inventory.size(),
		"starving": is_starving(),
		"total_items": get_total_inventory_count(),
		"food_per_member": get_food_per_member(),
		"unique_encounters": get_unique_encounter_count(),
		"path_completion_pct": get_path_completion_pct(),
		"encounter_rate": get_encounter_rate(),
		"most_common_encounter": get_most_common_encounter(),
		"inventory_variety": get_inventory_variety(),
		"food_urgency": get_food_urgency(),
		"travel_efficiency": get_travel_efficiency(),
		"danger_encounter_pct": get_danger_encounter_pct(),
		"caravan_ecosystem_health": get_caravan_ecosystem_health(),
		"expedition_governance": get_expedition_governance(),
		"journey_maturity_index": get_journey_maturity_index(),
	}

func get_caravan_ecosystem_health() -> float:
	var urgency := get_food_urgency()
	var u_val: float = 90.0 if urgency == "Sufficient" else (60.0 if urgency == "Low" else (30.0 if urgency == "Critical" else 10.0))
	var eff := minf(get_travel_efficiency() * 50.0, 100.0)
	var danger_inv := maxf(100.0 - get_danger_encounter_pct(), 0.0)
	return snapped((u_val + eff + danger_inv) / 3.0, 0.1)

func get_expedition_governance() -> String:
	var eco := get_caravan_ecosystem_health()
	var mat := get_journey_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif members.size() > 0:
		return "Nascent"
	return "Dormant"

func get_journey_maturity_index() -> float:
	var completion := get_path_completion_pct()
	var variety := minf(float(get_unique_encounter_count()) * 20.0, 100.0)
	var inv_variety := minf(float(get_inventory_variety()) * 15.0, 100.0)
	return snapped((completion + variety + inv_variety) / 3.0, 0.1)
