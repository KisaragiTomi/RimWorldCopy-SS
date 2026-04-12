extends Node

## Counts all resources in stockpiles, items on map, and pawn inventories.
## Registered as autoload "ResourceCounter".

var _cached: Dictionary = {}
var _cache_tick: int = -1

const CATEGORY_MAP: Dictionary = {
	"Steel": "Materials", "Wood": "Materials", "Stone": "Materials",
	"Plasteel": "Materials", "Gold": "Materials", "Jade": "Materials",
	"ComponentIndustrial": "Materials", "ComponentSpacer": "Materials",
	"Silver": "Currency",
	"RawFood": "Food", "Meal": "Food", "MealSimple": "Food",
	"MealFine": "Food", "MealLavish": "Food", "Pemmican": "Food",
	"NutrientPaste": "Food", "Berries": "Food", "Meat": "Food", "Rice": "Food", "Corn": "Food",
	"Medicine": "Medical", "HerbalMedicine": "Medical", "GlitterworldMedicine": "Medical",
	"Cloth": "Textiles", "Leather": "Textiles",
	"Beer": "Drugs", "Smokeleaf": "Drugs", "GoJuice": "Drugs", "Yayo": "Drugs",
}

const CRITICAL_RESOURCES: Array = ["Steel", "Wood", "Silver", "Medicine", "MealSimple"]
const LOW_THRESHOLDS: Dictionary = {
	"Steel": 50, "Wood": 100, "Silver": 100, "Medicine": 5, "MealSimple": 10,
}


func get_resource_count(resource_name: String) -> int:
	_refresh_cache()
	return _cached.get(resource_name, 0)


func get_all_resources() -> Dictionary:
	_refresh_cache()
	return _cached.duplicate()


func get_by_category(category: String) -> Dictionary:
	_refresh_cache()
	var result: Dictionary = {}
	for res: String in _cached:
		if CATEGORY_MAP.get(res, "Other") == category:
			result[res] = _cached[res]
	return result


func get_low_resources() -> Array[String]:
	_refresh_cache()
	var low: Array[String] = []
	for res: String in CRITICAL_RESOURCES:
		var threshold: int = LOW_THRESHOLDS.get(res, 10)
		if _cached.get(res, 0) < threshold:
			low.append(res)
	return low


func get_total_food() -> int:
	_refresh_cache()
	var total: int = 0
	for res: String in _cached:
		if CATEGORY_MAP.get(res, "") == "Food":
			total += _cached[res]
	return total


func get_total_value() -> float:
	_refresh_cache()
	var total: float = 0.0
	const VALUE_MAP: Dictionary = {
		"Steel": 1.0, "Wood": 0.6, "Silver": 1.0, "Gold": 5.0,
		"Plasteel": 4.0, "Jade": 3.0, "ComponentIndustrial": 12.0,
		"Medicine": 9.0, "HerbalMedicine": 4.0,
		"MealSimple": 1.0, "MealFine": 3.0, "MealLavish": 5.0,
		"Cloth": 1.5, "Leather": 2.0,
	}
	for res: String in _cached:
		total += float(_cached[res]) * VALUE_MAP.get(res, 1.0)
	return total


func _refresh_cache() -> void:
	var current_tick: int = TickManager.current_tick if TickManager else 0
	if current_tick == _cache_tick:
		return
	_cache_tick = current_tick
	_cached.clear()

	if ThingManager:
		for t: Thing in ThingManager.things:
			if t is Item and t.state == Thing.ThingState.SPAWNED:
				var item := t as Item
				_cached[item.def_name] = _cached.get(item.def_name, 0) + item.stack_count

	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.dead or p.inventory == null:
				continue
			for entry: Dictionary in p.inventory.items:
				var rname: String = entry.get("def_name", "")
				var count: int = entry.get("count", 0)
				_cached[rname] = _cached.get(rname, 0) + count

	if GameState:
		for r: Dictionary in GameState.resources:
			var rname: String = r.get("name", "")
			var count: int = r.get("count", 0)
			_cached[rname] = _cached.get(rname, 0) + count

	if TradeManager:
		_cached["Silver"] = _cached.get("Silver", 0) + roundi(TradeManager.colony_silver)


func get_most_abundant() -> String:
	_refresh_cache()
	var best: String = ""
	var best_c: int = 0
	for r: String in _cached:
		if _cached[r] > best_c:
			best_c = _cached[r]
			best = r
	return best


func get_resource_categories() -> Dictionary:
	_refresh_cache()
	var cats: Dictionary = {"food": 0, "material": 0, "medicine": 0, "other": 0}
	for r: String in _cached:
		if r in ["RawFood", "Rice", "Corn", "Meat", "MealSimple", "MealFine", "MealLavish"]:
			cats["food"] += _cached[r]
		elif r in ["Steel", "Wood", "Stone", "Plasteel", "ComponentIndustrial"]:
			cats["material"] += _cached[r]
		elif r in ["Medicine", "HerbalMedicine"]:
			cats["medicine"] += _cached[r]
		else:
			cats["other"] += _cached[r]
	return cats


func get_scarcest_material() -> String:
	_refresh_cache()
	var critical := ["Steel", "Wood", "Medicine"]
	var worst: String = ""
	var worst_c: int = 999999
	for r: String in critical:
		var c: int = _cached.get(r, 0)
		if c < worst_c:
			worst_c = c
			worst = r
	return worst


func get_total_item_count() -> int:
	_refresh_cache()
	var total: int = 0
	for r: String in _cached:
		total += _cached[r]
	return total


func get_avg_stock_per_type() -> float:
	_refresh_cache()
	if _cached.is_empty():
		return 0.0
	return float(get_total_item_count()) / float(_cached.size())


func get_zero_stock_count() -> int:
	_refresh_cache()
	var cnt: int = 0
	for r: String in _cached:
		if _cached[r] == 0:
			cnt += 1
	return cnt


func get_surplus_type_count() -> int:
	_refresh_cache()
	var count: int = 0
	for r: String in _cached:
		if _cached[r] > 100:
			count += 1
	return count


func get_stock_health() -> String:
	var zero: int = get_zero_stock_count()
	if zero == 0:
		return "Healthy"
	elif zero <= 2:
		return "Moderate"
	return "Critical"


func get_value_per_type() -> float:
	_refresh_cache()
	if _cached.is_empty():
		return 0.0
	return snappedf(get_total_value() / float(_cached.size()), 0.1)


func get_supply_chain_risk() -> String:
	var zero := get_zero_stock_count()
	var low := get_low_resources().size()
	if zero >= 3:
		return "Critical"
	elif zero >= 1 or low >= 3:
		return "Vulnerable"
	elif low >= 1:
		return "Watchful"
	return "Secure"

func get_resource_diversity_pct() -> float:
	_refresh_cache()
	if _cached.is_empty():
		return 0.0
	var nonzero := 0
	for key: String in _cached:
		if _cached[key].get("count", 0) > 0:
			nonzero += 1
	return snapped(float(nonzero) / float(_cached.size()) * 100.0, 0.1)

func get_economic_concentration() -> float:
	_refresh_cache()
	var total_val := get_total_value()
	if total_val <= 0.0 or _cached.is_empty():
		return 0.0
	var max_val := 0.0
	for key: String in _cached:
		var v: float = _cached[key].get("value", 0.0)
		if v > max_val:
			max_val = v
	return snapped(max_val / total_val * 100.0, 0.1)

func get_summary() -> Dictionary:
	_refresh_cache()
	return {
		"total_types": _cached.size(),
		"resources": _cached.duplicate(),
		"total_value": snappedf(get_total_value(), 0.1),
		"total_food": get_total_food(),
		"low_resources": get_low_resources(),
		"most_abundant": get_most_abundant(),
		"scarcest": get_scarcest_material(),
		"total_items": get_total_item_count(),
		"avg_stock": snappedf(get_avg_stock_per_type(), 0.1),
		"zero_stock": get_zero_stock_count(),
		"surplus_types": get_surplus_type_count(),
		"stock_health": get_stock_health(),
		"value_per_type": get_value_per_type(),
		"supply_chain_risk": get_supply_chain_risk(),
		"resource_diversity_pct": get_resource_diversity_pct(),
		"economic_concentration_pct": get_economic_concentration(),
		"economic_resilience": get_economic_resilience(),
		"resource_self_sufficiency": get_resource_self_sufficiency(),
		"strategic_reserve_health": get_strategic_reserve_health(),
	}

func get_economic_resilience() -> String:
	var zeros: int = get_zero_stock_count()
	var diversity: float = get_resource_diversity_pct()
	if zeros == 0 and diversity >= 80.0:
		return "Resilient"
	if zeros <= 2 and diversity >= 50.0:
		return "Moderate"
	if zeros <= 5:
		return "Fragile"
	return "Critical"

func get_resource_self_sufficiency() -> float:
	_refresh_cache()
	var total_types: int = _cached.size()
	if total_types == 0:
		return 0.0
	var sufficient: int = 0
	for key: String in _cached:
		if int(_cached[key]) >= 20:
			sufficient += 1
	return snappedf(float(sufficient) / float(total_types) * 100.0, 0.1)

func get_strategic_reserve_health() -> String:
	var food: int = get_total_food()
	var health: String = get_stock_health()
	if food >= 100 and health == "Healthy":
		return "Excellent"
	if food >= 50:
		return "Adequate"
	if food >= 20:
		return "Low"
	return "Critical"
