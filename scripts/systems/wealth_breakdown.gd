extends Node

## Provides detailed colony wealth breakdown by category.
## Registered as autoload "WealthBreakdown".

var _last_update_tick: int = -1
var _cached: Dictionary = {}
var _history: Array[Dictionary] = []
var _peak_wealth: float = 0.0
var _peak_tick: int = 0
const MAX_HISTORY: int = 60


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func _on_rare_tick(_tick: int) -> void:
	_update_breakdown()


func _update_breakdown() -> void:
	var building_wealth: float = 0.0
	var item_wealth: float = 0.0
	var apparel_wealth: float = 0.0
	var weapon_wealth: float = 0.0
	var silver_wealth: float = 0.0
	var floor_wealth: float = 0.0

	if ThingManager:
		for t: Thing in ThingManager.things:
			if t is Building:
				building_wealth += _building_value(t as Building)
			elif t is Item:
				var iv := _item_value(t as Item)
				if t.def_name == "Silver":
					silver_wealth += iv
				else:
					item_wealth += iv

	if TradeManager:
		silver_wealth += float(TradeManager.colony_silver)

	if FloorManager:
		floor_wealth += float(FloorManager.get_floor_count()) * 3.0

	var total: float = building_wealth + item_wealth + apparel_wealth + weapon_wealth + silver_wealth + floor_wealth
	_cached = {
		"building": snappedf(building_wealth, 0.1),
		"items": snappedf(item_wealth, 0.1),
		"apparel": snappedf(apparel_wealth, 0.1),
		"weapons": snappedf(weapon_wealth, 0.1),
		"silver": snappedf(silver_wealth, 0.1),
		"floors": snappedf(floor_wealth, 0.1),
		"total": snappedf(total, 0.1),
	}
	_last_update_tick = TickManager.current_tick if TickManager else 0
	if total > _peak_wealth:
		_peak_wealth = total
		_peak_tick = _last_update_tick
	_history.append({"tick": _last_update_tick, "total": snappedf(total, 0.1)})
	if _history.size() > MAX_HISTORY:
		_history.pop_front()


func _building_value(b: Building) -> float:
	if b.build_state != Building.BuildState.COMPLETE:
		return 0.0
	var values: Dictionary = {
		"Wall": 10.0,
		"Door": 15.0,
		"Bed": 50.0,
		"Table": 30.0,
		"Campfire": 10.0,
		"WoodFiredGenerator": 200.0,
		"SolarGenerator": 350.0,
		"Battery": 150.0,
		"MiniTurret": 250.0,
		"CookingStove": 180.0,
		"HiTechResearchBench": 300.0,
	}
	return values.get(b.def_name, 20.0)


func _item_value(item: Item) -> float:
	if TradePrice:
		return TradePrice.get_sell_price(item.def_name, 0, 0.0) * float(item.stack_count)
	var base_values: Dictionary = {
		"Steel": 1.0, "Wood": 0.6, "Silver": 1.0, "Gold": 5.0,
		"RawFood": 0.25, "Meal": 1.0, "Medicine": 9.0,
	}
	return base_values.get(item.def_name, 1.0) * float(item.stack_count)


func get_breakdown() -> Dictionary:
	return _cached.duplicate()


func get_largest_category() -> String:
	var best_cat: String = "items"
	var best_val: float = 0.0
	for cat: String in ["building", "items", "apparel", "weapons", "silver", "floors"]:
		var v: float = _cached.get(cat, 0.0)
		if v > best_val:
			best_val = v
			best_cat = cat
	return best_cat


func get_wealth_change() -> float:
	if _history.size() < 2:
		return 0.0
	return _history[-1].total - _history[0].total


func get_category_pct() -> Dictionary:
	var total: float = _cached.get("total", 0.0)
	if total <= 0.0:
		return {}
	var result: Dictionary = {}
	for cat: String in ["building", "items", "apparel", "weapons", "silver", "floors"]:
		result[cat] = snappedf(_cached.get(cat, 0.0) / total * 100.0, 0.1)
	return result


func get_wealth_growth_rate() -> float:
	if _history.size() < 2:
		return 0.0
	var first: float = _history[0].total
	var last: float = _history[-1].total
	if first <= 0.0:
		return 0.0
	return snappedf((last - first) / first * 100.0, 0.1)


func get_smallest_category() -> String:
	var worst_cat: String = "items"
	var worst_val: float = 99999999.0
	for cat: String in ["building", "items", "apparel", "weapons", "silver", "floors"]:
		var v: float = _cached.get(cat, 0.0)
		if v < worst_val:
			worst_val = v
			worst_cat = cat
	return worst_cat


func is_wealth_declining() -> bool:
	if _history.size() < 5:
		return false
	var recent := _history.slice(-5)
	var declines: int = 0
	for i: int in range(1, recent.size()):
		if recent[i].total < recent[i - 1].total:
			declines += 1
	return declines >= 3


func get_wealth_tier() -> String:
	if _peak_wealth >= 100000.0:
		return "Wealthy"
	elif _peak_wealth >= 50000.0:
		return "Prosperous"
	elif _peak_wealth >= 20000.0:
		return "Moderate"
	elif _peak_wealth > 0.0:
		return "Struggling"
	return "None"

func get_balance_score() -> float:
	var pcts: Dictionary = get_category_pct()
	if pcts.is_empty():
		return 0.0
	var ideal: float = 100.0 / float(pcts.size())
	var deviation: float = 0.0
	for cat: String in pcts:
		deviation += absf(pcts[cat] - ideal)
	return snappedf(maxf(0.0, 100.0 - deviation), 0.1)

func get_growth_health() -> String:
	var rate: float = get_wealth_growth_rate()
	if rate >= 5.0:
		return "Booming"
	elif rate >= 1.0:
		return "Growing"
	elif rate >= -1.0:
		return "Stable"
	return "Declining"

func get_economic_diversification() -> String:
	var balance := get_balance_score()
	var cats := get_category_pct().size()
	if balance >= 70.0 and cats >= 4:
		return "Well Diversified"
	elif balance >= 40.0:
		return "Moderate"
	return "Concentrated"

func get_wealth_resilience() -> float:
	var declining := is_wealth_declining()
	var balance := get_balance_score()
	if declining:
		return snapped(balance * 0.5, 0.1)
	return snapped(balance, 0.1)

func get_prosperity_index() -> String:
	var tier := get_wealth_tier()
	var growth := get_growth_health()
	if tier == "Wealthy" and growth == "Booming":
		return "Flourishing"
	elif tier != "Poor" and growth != "Declining":
		return "Stable"
	return "Struggling"

func get_summary() -> Dictionary:
	var base: Dictionary = _cached.duplicate()
	base["peak_wealth"] = snappedf(_peak_wealth, 0.1)
	base["peak_tick"] = _peak_tick
	base["largest_category"] = get_largest_category()
	base["wealth_change"] = snappedf(get_wealth_change(), 0.1)
	base["category_pct"] = get_category_pct()
	base["growth_rate_pct"] = get_wealth_growth_rate()
	base["smallest_category"] = get_smallest_category()
	base["declining"] = is_wealth_declining()
	base["category_count"] = get_category_pct().size()
	base["wealth_per_category"] = snappedf(float(_peak_wealth) / maxf(float(get_category_pct().size()), 1.0), 0.1)
	base["wealth_tier"] = get_wealth_tier()
	base["balance_score"] = get_balance_score()
	base["growth_health"] = get_growth_health()
	base["economic_diversification"] = get_economic_diversification()
	base["wealth_resilience"] = get_wealth_resilience()
	base["prosperity_index"] = get_prosperity_index()
	base["wealth_velocity"] = get_wealth_velocity()
	base["financial_stability_index"] = get_financial_stability_index()
	base["investment_potential"] = get_investment_potential()
	return base

func get_wealth_velocity() -> float:
	var rate := get_wealth_growth_rate()
	var change := get_wealth_change()
	return snapped(absf(change) * maxf(rate / 100.0, 0.01), 0.1)

func get_financial_stability_index() -> float:
	var declining := is_wealth_declining()
	var balance := get_balance_score()
	var base_score: float = 100.0 if not declining else 40.0
	return snapped(base_score * balance / 100.0, 0.1)

func get_investment_potential() -> String:
	var tier := get_wealth_tier()
	var growth := get_growth_health()
	var resilience := get_wealth_resilience()
	if tier == "Wealthy" and growth == "Booming" and resilience in ["Strong", "Robust"]:
		return "Prime"
	elif growth != "Declining":
		return "Viable"
	return "Risky"
