extends Node

## Manages caravan formation, loading items, and departure.
## Registered as autoload "CaravanManager".

signal caravan_formed(caravan_id: int)
signal caravan_departed(caravan_id: int)

var caravans: Array[Dictionary] = []
var _next_id: int = 1


func form_caravan(pawn_ids: Array, destination: Vector2i) -> int:
	var caravan := {
		"id": _next_id,
		"pawns": pawn_ids.duplicate(),
		"items": [],
		"state": "Loading",
		"destination": destination,
		"mass_capacity": _calc_capacity(pawn_ids),
		"current_mass": 0.0,
	}
	_next_id += 1
	caravans.append(caravan)
	caravan_formed.emit(caravan.id)

	if ColonyLog:
		ColonyLog.add_entry("Caravan", "Forming caravan #" + str(caravan.id) + " with " + str(pawn_ids.size()) + " colonists.", "info")

	return caravan.id


func load_item(caravan_id: int, item_def: String, count: int) -> bool:
	var caravan: Dictionary = _find_caravan(caravan_id)
	if caravan.is_empty():
		return false
	if caravan.get("state", "") != "Loading":
		return false

	var mass: float = _item_mass(item_def) * count
	if caravan.get("current_mass", 0.0) + mass > caravan.get("mass_capacity", 100.0):
		return false

	caravan["current_mass"] = caravan.get("current_mass", 0.0) + mass
	var items: Array = caravan.get("items", [])
	var found := false
	for entry: Dictionary in items:
		if entry.get("def", "") == item_def:
			entry["count"] = entry.get("count", 0) + count
			found = true
			break
	if not found:
		items.append({"def": item_def, "count": count})

	return true


func unload_item(caravan_id: int, item_def: String, count: int) -> bool:
	var caravan: Dictionary = _find_caravan(caravan_id)
	if caravan.is_empty():
		return false

	var items: Array = caravan.get("items", [])
	for entry: Dictionary in items:
		if entry.get("def", "") == item_def:
			var available: int = entry.get("count", 0)
			var to_remove: int = mini(count, available)
			entry["count"] = available - to_remove
			caravan["current_mass"] = maxf(0.0, caravan.get("current_mass", 0.0) - _item_mass(item_def) * to_remove)
			if entry["count"] <= 0:
				items.erase(entry)
			return true
	return false


func depart(caravan_id: int) -> bool:
	var caravan: Dictionary = _find_caravan(caravan_id)
	if caravan.is_empty():
		return false
	if caravan.get("state", "") != "Loading":
		return false

	caravan["state"] = "Traveling"
	caravan_departed.emit(caravan_id)

	if ColonyLog:
		ColonyLog.add_entry("Caravan", "Caravan #" + str(caravan_id) + " departed with " + str(caravan.get("items", []).size()) + " item types.", "info")

	return true


func arrive(caravan_id: int) -> bool:
	var caravan: Dictionary = _find_caravan(caravan_id)
	if caravan.is_empty():
		return false
	caravan["state"] = "Arrived"

	if ColonyLog:
		ColonyLog.add_entry("Caravan", "Caravan #" + str(caravan_id) + " arrived at destination.", "info")

	return true


func disband(caravan_id: int) -> bool:
	for i: int in range(caravans.size()):
		if caravans[i].get("id", -1) == caravan_id:
			caravans.remove_at(i)
			return true
	return false


func _find_caravan(caravan_id: int) -> Dictionary:
	for c: Dictionary in caravans:
		if c.get("id", -1) == caravan_id:
			return c
	return {}


func _calc_capacity(pawn_ids: Array) -> float:
	return pawn_ids.size() * 35.0


func _item_mass(item_def: String) -> float:
	var masses: Dictionary = {
		"Steel": 0.5, "Wood": 0.5, "Silver": 0.01,
		"Gold": 0.1, "Plasteel": 0.4, "Component": 0.6,
		"RawFood": 0.03, "Meal": 0.44, "SimpleMeal": 0.44,
		"Medicine": 0.5, "HerbalMed": 0.35,
		"Cloth": 0.03, "Beer": 0.3,
	}
	return masses.get(item_def, 0.5)


func get_logistics_readiness() -> String:
	var active := 0
	var total := caravans.size()
	for c: Dictionary in caravans:
		if c.get("state", "") != "":
			active += 1
	if total <= 0:
		return "No History"
	if active > 2:
		return "Overextended"
	elif active > 0:
		return "Active"
	return "Ready"

func get_caravan_success_rate() -> float:
	var completed := 0
	var total := caravans.size()
	for c: Dictionary in caravans:
		if c.get("state", "") == "completed":
			completed += 1
	if total <= 0:
		return 0.0
	return snapped(float(completed) / float(total) * 100.0, 0.1)

func get_expedition_capacity() -> int:
	var idle_pawns := 0
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if not p.dead and not p.downed and not p.drafted:
				idle_pawns += 1
	return maxi(idle_pawns / 3, 0)

func get_summary() -> Dictionary:
	var active: int = 0
	for c: Dictionary in caravans:
		if c.get("state", "") != "":
			active += 1
	return {
		"active_caravans": active,
		"total_formed": _next_id - 1,
		"logistics_readiness": get_logistics_readiness(),
		"success_rate_pct": get_caravan_success_rate(),
		"expedition_capacity": get_expedition_capacity(),
		"caravan_mastery": get_caravan_mastery(),
		"trade_route_viability": get_trade_route_viability(),
		"expeditionary_readiness": get_expeditionary_readiness(),
	}

func get_caravan_mastery() -> String:
	var total: int = _next_id - 1
	var success: float = get_caravan_success_rate()
	if total >= 10 and success >= 80.0:
		return "Expert"
	if total >= 5 and success >= 60.0:
		return "Competent"
	if total >= 2:
		return "Novice"
	return "Untested"

func get_trade_route_viability() -> float:
	var success: float = get_caravan_success_rate()
	var readiness: String = get_logistics_readiness()
	var bonus: float = 20.0 if readiness == "Ready" else (10.0 if readiness == "Partial" else 0.0)
	return snappedf(clampf(success * 0.8 + bonus, 0.0, 100.0), 0.1)

func get_expeditionary_readiness() -> String:
	var cap: int = get_expedition_capacity()
	var readiness: String = get_logistics_readiness()
	if cap >= 8 and readiness == "Ready":
		return "Full"
	if readiness == "Ready":
		return "Moderate"
	return "Limited"
