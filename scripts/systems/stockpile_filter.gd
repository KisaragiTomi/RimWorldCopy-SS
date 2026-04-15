extends Node

## Manages item filters for stockpile zones.
## Registered as autoload "StockpileFilter".

var _filters: Dictionary = {}
var _priorities: Dictionary = {}  # zone_key -> int (1=Low, 2=Normal, 3=Preferred, 4=Critical)

const ALL_CATEGORIES: Array = [
	"Food", "RawFood", "Meal", "MealSimple", "MealFine", "MealLavish",
	"Pemmican", "Berries", "Meat", "Rice", "Corn",
	"Materials", "Steel", "Wood", "Gold", "Plasteel", "Stone", "Jade",
	"Medicine", "HerbalMedicine", "GlitterworldMedicine", "ComponentIndustrial",
	"Apparel", "Cloth", "Leather",
	"Weapons", "Silver",
	"Drugs", "Beer", "Smokeleaf", "GoJuice", "Yayo",
	"Corpse", "AnimalCorpse",
]

const PRESETS: Dictionary = {
	"AllowAll": [],
	"FoodOnly": ["Food", "RawFood", "Meal", "MealSimple", "MealFine", "MealLavish", "Pemmican", "Berries", "Meat", "Rice", "Corn"],
	"MaterialsOnly": ["Materials", "Steel", "Wood", "Gold", "Plasteel", "Stone", "Jade", "ComponentIndustrial"],
	"MedicalOnly": ["Medicine", "HerbalMedicine", "GlitterworldMedicine"],
	"WeaponsArmor": ["Weapons", "Apparel"],
}


func set_filter(zone_pos: Vector2i, allowed_items: Array) -> void:
	var key: String = _key(zone_pos)
	_filters[key] = {}
	for item: String in allowed_items:
		_filters[key][item] = true


func apply_preset(zone_pos: Vector2i, preset_name: String) -> void:
	var items: Array = PRESETS.get(preset_name, [])
	if items.is_empty():
		clear_filter(zone_pos)
	else:
		set_filter(zone_pos, items)


func set_priority(zone_pos: Vector2i, priority: int) -> void:
	_priorities[_key(zone_pos)] = clampi(priority, 1, 4)


func get_priority(zone_pos: Vector2i) -> int:
	return _priorities.get(_key(zone_pos), 2)


func clear_filter(zone_pos: Vector2i) -> void:
	_filters.erase(_key(zone_pos))


func toggle_item(zone_pos: Vector2i, item_def: String) -> void:
	var key: String = _key(zone_pos)
	if not _filters.has(key):
		_filters[key] = {}
		for cat: String in ALL_CATEGORIES:
			_filters[key][cat] = true
	if _filters[key].has(item_def):
		_filters[key].erase(item_def)
	else:
		_filters[key][item_def] = true


func is_allowed(zone_pos: Vector2i, item_def: String) -> bool:
	var key: String = _key(zone_pos)
	if not _filters.has(key):
		return true
	return _filters[key].has(item_def)


func get_filter(zone_pos: Vector2i) -> Array:
	var key: String = _key(zone_pos)
	if not _filters.has(key):
		return ALL_CATEGORIES.duplicate()
	return _filters[key].keys()


func find_best_stockpile(item_def: String) -> Vector2i:
	var best_pos := Vector2i(-1, -1)
	var best_priority: int = 0
	for key: String in _filters:
		if _filters[key].has(item_def):
			var p: int = _priorities.get(key, 2)
			if p > best_priority:
				best_priority = p
				best_pos = _pos_from_key(key)
	return best_pos


func get_zone_count() -> int:
	return _filters.size()


func get_highest_priority_zone() -> String:
	var best: String = ""
	var best_p: int = 0
	for key: String in _filters:
		var f: Dictionary = _filters[key]
		var p: int = f.get("priority", 1)
		if p > best_p:
			best_p = p
			best = key
	return best


func get_zones_accepting(item_def: String) -> int:
	var cnt: int = 0
	for key: String in _filters:
		var f: Dictionary = _filters[key]
		var items: Array = f.get("items", []) as Array
		if items.is_empty() or item_def in items:
			cnt += 1
	return cnt


func get_avg_priority() -> float:
	if _filters.is_empty():
		return 0.0
	var total: int = 0
	for key: String in _filters:
		total += _filters[key].get("priority", 1) as int
	return float(total) / float(_filters.size())


func get_empty_filter_count() -> int:
	var cnt: int = 0
	for key: String in _filters:
		var items: Array = _filters[key].get("items", []) as Array
		if items.is_empty():
			cnt += 1
	return cnt


func get_total_allowed_items() -> int:
	var all_items: Dictionary = {}
	for key: String in _filters:
		var items: Array = _filters[key].get("items", []) as Array
		for item: String in items:
			all_items[item] = true
	return all_items.size()


func get_critical_zone_count() -> int:
	var cnt: int = 0
	for key: String in _priorities:
		if _priorities[key] >= 4:
			cnt += 1
	return cnt

func get_filter_diversity() -> float:
	if _filters.is_empty():
		return 0.0
	var total: int = 0
	for key: String in _filters:
		total += _filters[key].size()
	return snappedf(float(total) / float(_filters.size()), 0.1)

func get_storage_health() -> String:
	if _filters.is_empty():
		return "NoZones"
	var empty: int = get_empty_filter_count()
	if empty == 0:
		return "Organized"
	elif empty <= 2:
		return "MostlyOrganized"
	return "Disorganized"

func get_storage_optimization() -> float:
	if _filters.is_empty():
		return 0.0
	var empty := float(get_empty_filter_count())
	var total := float(_filters.size())
	var diversity := get_filter_diversity()
	var utilized := (total - empty) / total * 60.0
	var div_score := minf(diversity / float(ALL_CATEGORIES.size()), 1.0) * 40.0
	return snapped(utilized + div_score, 0.1)

func get_logistics_complexity() -> String:
	var zones := _filters.size()
	if zones >= 10:
		return "Complex"
	elif zones >= 5:
		return "Moderate"
	elif zones >= 1:
		return "Simple"
	return "None"

func get_category_coverage_pct() -> float:
	var used_cats: Dictionary = {}
	for key: String in _filters:
		for item: String in _filters[key]:
			used_cats[item] = true
	if ALL_CATEGORIES.is_empty():
		return 0.0
	return snapped(float(used_cats.size()) / float(ALL_CATEGORIES.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"filtered_zones": _filters.size(),
		"categories": ALL_CATEGORIES.size(),
		"presets_available": PRESETS.keys(),
		"highest_priority": get_highest_priority_zone(),
		"avg_priority": snappedf(get_avg_priority(), 0.1),
		"empty_filters": get_empty_filter_count(),
		"total_allowed_items": get_total_allowed_items(),
		"critical_zones": get_critical_zone_count(),
		"filter_diversity": get_filter_diversity(),
		"storage_health": get_storage_health(),
		"storage_optimization": get_storage_optimization(),
		"logistics_complexity": get_logistics_complexity(),
		"category_coverage_pct": get_category_coverage_pct(),
		"warehouse_maturity": get_warehouse_maturity(),
		"inventory_governance": get_inventory_governance(),
		"supply_chain_integration": get_supply_chain_integration(),
	}

func get_warehouse_maturity() -> String:
	var zones: int = _filters.size()
	var coverage: float = get_category_coverage_pct()
	if zones >= 8 and coverage >= 80.0:
		return "Mature"
	if zones >= 4 and coverage >= 50.0:
		return "Developing"
	if zones >= 1:
		return "Basic"
	return "None"

func get_inventory_governance() -> float:
	var empty: int = get_empty_filter_count()
	var total: int = _filters.size()
	var critical: int = get_critical_zone_count()
	if total == 0:
		return 0.0
	var penalty: float = float(empty + critical) / float(total) * 50.0
	return snappedf(clampf(100.0 - penalty, 0.0, 100.0), 0.1)

func get_supply_chain_integration() -> String:
	var optimization: float = get_storage_optimization()
	var health: String = get_storage_health()
	if optimization >= 80.0 and health == "Organized":
		return "Integrated"
	if health in ["Organized", "Functional"]:
		return "Partial"
	return "Fragmented"


func _key(pos: Vector2i) -> String:
	return str(pos.x) + "," + str(pos.y)


func _pos_from_key(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() == 2:
		return Vector2i(parts[0].to_int(), parts[1].to_int())
	return Vector2i(-1, -1)
