class_name PawnInventory
extends RefCounted

## A pawn's personal inventory. Can carry a limited number of items.

var items: Array[Dictionary] = []  # {def_name, count}
var max_slots: int = 5
var max_mass: float = 35.0

const ITEM_MASS: Dictionary = {
	"Steel": 0.5, "Wood": 0.3, "Stone": 0.8,
	"Silver": 0.01, "Gold": 0.05,
	"RawFood": 0.05, "Meal": 0.3, "MealSimple": 0.3,
	"HerbalMedicine": 0.35, "Medicine": 0.5,
	"Cloth": 0.05, "Leather": 0.08,
	"ComponentIndustrial": 0.6,
}


func add_item(def_name: String, count: int) -> int:
	var mass_per: float = ITEM_MASS.get(def_name, 0.1) as float
	var current_mass := get_total_mass()
	var max_add := floori((max_mass - current_mass) / maxf(mass_per, 0.01))
	var actual := mini(count, max_add)
	if actual <= 0:
		return 0

	for entry: Dictionary in items:
		if entry.get("def_name", "") == def_name:
			entry["count"] = entry.get("count", 0) + actual
			return actual

	if items.size() >= max_slots:
		return 0

	items.append({"def_name": def_name, "count": actual})
	return actual


func remove_item(def_name: String, count: int) -> int:
	for i: int in range(items.size() - 1, -1, -1):
		if items[i].get("def_name", "") == def_name:
			var have: int = items[i].get("count", 0)
			var take: int = mini(count, have)
			items[i]["count"] = have - take
			if items[i]["count"] <= 0:
				items.remove_at(i)
			return take
	return 0


func has_item(def_name: String, min_count: int = 1) -> bool:
	for entry: Dictionary in items:
		if entry.get("def_name", "") == def_name and entry.get("count", 0) >= min_count:
			return true
	return false


func get_count(def_name: String) -> int:
	for entry: Dictionary in items:
		if entry.get("def_name", "") == def_name:
			return entry.get("count", 0)
	return 0


func get_total_mass() -> float:
	var total: float = 0.0
	for entry: Dictionary in items:
		var mass_per: float = ITEM_MASS.get(entry.get("def_name", ""), 0.1) as float
		total += mass_per * entry.get("count", 0)
	return total


func get_item_mass(def_name: String) -> float:
	return ITEM_MASS.get(def_name, 0.1) as float


func get_free_mass() -> float:
	return max_mass - get_total_mass()


func get_free_slots() -> int:
	return max_slots - items.size()


func is_full() -> bool:
	return items.size() >= max_slots or get_total_mass() >= max_mass - 0.01


func clear() -> Array[Dictionary]:
	var dropped: Array[Dictionary] = items.duplicate()
	items.clear()
	return dropped


func get_most_stacked() -> Dictionary:
	var best: Dictionary = {}
	var best_count: int = 0
	for entry: Dictionary in items:
		var c: int = entry.get("count", 0)
		if c > best_count:
			best = entry
			best_count = c
	return best


func get_total_value() -> float:
	var total: float = 0.0
	const VALUE_MAP: Dictionary = {
		"Steel": 1.0, "Wood": 0.6, "Stone": 0.3, "Silver": 1.0, "Gold": 5.0,
		"RawFood": 0.25, "Meal": 1.0, "MealSimple": 1.0, "MealFine": 3.0,
		"MealLavish": 5.0, "Medicine": 9.0, "HerbalMedicine": 4.0,
		"Cloth": 1.5, "Leather": 2.0, "ComponentIndustrial": 12.0,
	}
	for entry: Dictionary in items:
		var val: float = VALUE_MAP.get(entry.get("def_name", ""), 1.0)
		total += val * float(entry.get("count", 0))
	return total


func get_heaviest_item() -> Dictionary:
	var best: Dictionary = {}
	var best_mass: float = 0.0
	for entry: Dictionary in items:
		var mass_per: float = ITEM_MASS.get(entry.get("def_name", ""), 0.1) as float
		var total_m: float = mass_per * entry.get("count", 0)
		if total_m > best_mass:
			best_mass = total_m
			best = entry
	return best


func get_most_valuable_item() -> Dictionary:
	const VALUE_MAP: Dictionary = {
		"Steel": 1.0, "Wood": 0.6, "Stone": 0.3, "Silver": 1.0, "Gold": 5.0,
		"RawFood": 0.25, "Meal": 1.0, "MealSimple": 1.0, "MealFine": 3.0,
		"MealLavish": 5.0, "Medicine": 9.0, "HerbalMedicine": 4.0,
		"Cloth": 1.5, "Leather": 2.0, "ComponentIndustrial": 12.0,
	}
	var best: Dictionary = {}
	var best_val: float = 0.0
	for entry: Dictionary in items:
		var val: float = VALUE_MAP.get(entry.get("def_name", ""), 1.0)
		var total_v: float = val * float(entry.get("count", 0))
		if total_v > best_val:
			best_val = total_v
			best = entry
	return best


func get_fill_percent() -> float:
	return get_total_mass() / maxf(max_mass, 0.01) * 100.0


func get_unique_item_count() -> int:
	var types: Dictionary = {}
	for entry: Dictionary in items:
		types[entry.get("def_name", "")] = true
	return types.size()


func get_avg_stack_size() -> float:
	if items.is_empty():
		return 0.0
	var total: int = 0
	for entry: Dictionary in items:
		total += entry.get("count", 0) as int
	return float(total) / float(items.size())


func is_overloaded() -> bool:
	return get_total_mass() > max_mass


func get_value_per_mass() -> float:
	var mass: float = get_total_mass()
	if mass <= 0.0:
		return 0.0
	return snappedf(get_total_value() / mass, 0.01)


func get_slot_utilization_pct() -> float:
	if max_slots <= 0:
		return 0.0
	return snappedf(float(items.size()) / float(max_slots) * 100.0, 0.1)


func is_empty() -> bool:
	return items.is_empty()


func get_carry_efficiency() -> float:
	if max_mass <= 0.0:
		return 0.0
	var used := get_total_mass()
	var value := get_total_value()
	if used <= 0.0:
		return 0.0
	return snapped(value / used, 0.01)

func get_loadout_diversity() -> float:
	var unique := get_unique_item_count()
	var total := items.size()
	if total <= 0:
		return 0.0
	return snapped(float(unique) / float(total) * 100.0, 0.1)

func get_capacity_forecast() -> String:
	var fill := get_fill_percent()
	if fill >= 90.0:
		return "Full"
	elif fill >= 70.0:
		return "Near Capacity"
	elif fill >= 30.0:
		return "Adequate"
	elif fill > 0.0:
		return "Light"
	return "Empty"

func get_summary() -> Dictionary:
	return {
		"items": items.duplicate(),
		"slots_used": items.size(),
		"max_slots": max_slots,
		"mass": snappedf(get_total_mass(), 0.1),
		"max_mass": max_mass,
		"free_mass": snappedf(get_free_mass(), 0.1),
		"free_slots": get_free_slots(),
		"total_value": snappedf(get_total_value(), 0.1),
		"fill_pct": snappedf(get_fill_percent(), 0.1),
		"unique_items": get_unique_item_count(),
		"avg_stack": snappedf(get_avg_stack_size(), 0.1),
		"overloaded": is_overloaded(),
		"value_per_mass": get_value_per_mass(),
		"slot_util_pct": get_slot_utilization_pct(),
		"is_empty": is_empty(),
		"carry_efficiency": get_carry_efficiency(),
		"loadout_diversity": get_loadout_diversity(),
		"capacity_forecast": get_capacity_forecast(),
		"logistics_ecosystem_health": get_logistics_ecosystem_health(),
		"cargo_governance": get_cargo_governance(),
		"supply_maturity_index": get_supply_maturity_index(),
	}

func get_logistics_ecosystem_health() -> float:
	var efficiency := get_carry_efficiency()
	var slot_util := get_slot_utilization_pct()
	var value_mass := get_value_per_mass()
	return snapped((minf(efficiency, 100.0) + slot_util + minf(value_mass * 10.0, 100.0)) / 3.0, 0.1)

func get_cargo_governance() -> String:
	var health := get_logistics_ecosystem_health()
	var forecast := get_capacity_forecast()
	if health >= 60.0 and forecast in ["Ample", "Comfortable"]:
		return "Managed"
	elif health >= 30.0:
		return "Reactive"
	return "Chaotic"

func get_supply_maturity_index() -> float:
	var diversity := get_loadout_diversity()
	var fill := get_fill_percent()
	return snapped((diversity + fill) / 2.0, 0.1)
