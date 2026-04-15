extends Node

const DYE_COLORS: Dictionary = {
	"Red": Color(0.8, 0.15, 0.15),
	"Blue": Color(0.15, 0.3, 0.8),
	"Green": Color(0.2, 0.7, 0.2),
	"Yellow": Color(0.85, 0.8, 0.15),
	"Purple": Color(0.6, 0.15, 0.7),
	"White": Color(0.95, 0.95, 0.95),
	"Black": Color(0.1, 0.1, 0.1),
	"Brown": Color(0.5, 0.3, 0.15),
	"Pink": Color(0.9, 0.5, 0.6),
	"Orange": Color(0.9, 0.5, 0.1),
}

const DYE_COST: Dictionary = {
	"base_cloth": 5,
	"base_dye": 10,
}

var _dyed_items: Dictionary = {}
var _total_dyed: int = 0
var _dye_by_color: Dictionary = {}


func dye_apparel(item_id: int, color_name: String) -> Dictionary:
	if not DYE_COLORS.has(color_name):
		return {"success": false, "reason": "Unknown color: " + color_name}
	_dyed_items[item_id] = {
		"color_name": color_name,
		"color": DYE_COLORS[color_name],
	}
	_total_dyed += 1
	_dye_by_color[color_name] = _dye_by_color.get(color_name, 0) + 1
	return {"success": true, "color": color_name}


func get_item_color(item_id: int) -> Dictionary:
	return _dyed_items.get(item_id, {})


func get_available_colors() -> Array:
	return DYE_COLORS.keys()


func remove_dye(item_id: int) -> bool:
	if _dyed_items.has(item_id):
		_dyed_items.erase(item_id)
		return true
	return false


func get_most_popular_color() -> String:
	var best: String = ""
	var best_count: int = 0
	for c: String in _dye_by_color:
		if _dye_by_color[c] > best_count:
			best_count = _dye_by_color[c]
			best = c
	return best


func get_least_popular_color() -> String:
	var worst: String = ""
	var worst_count: int = 99999
	for c: String in _dye_by_color:
		if _dye_by_color[c] < worst_count:
			worst_count = _dye_by_color[c]
			worst = c
	return worst


func get_unused_color_count() -> int:
	var used: int = _dye_by_color.size()
	return maxi(DYE_COLORS.size() - used, 0)


func get_dye_rate() -> float:
	if _total_dyed == 0:
		return 0.0
	return snappedf(float(_dyed_items.size()) / float(_total_dyed) * 100.0, 0.1)


func get_color_diversity_pct() -> float:
	var used: int = DYE_COLORS.size() - get_unused_color_count()
	if DYE_COLORS.is_empty():
		return 0.0
	return snappedf(float(used) / float(DYE_COLORS.size()) * 100.0, 0.1)

func get_fashion_rating() -> String:
	var rate: float = get_dye_rate()
	if rate >= 60.0:
		return "Fashionable"
	elif rate >= 30.0:
		return "Moderate"
	elif rate > 0.0:
		return "Basic"
	return "None"

func get_avg_dyes_per_item() -> float:
	if _dyed_items.is_empty():
		return 0.0
	return snappedf(float(_total_dyed) / float(_dyed_items.size()), 0.1)

func get_aesthetic_cohesion() -> String:
	if _dye_by_color.is_empty():
		return "none"
	var max_c: int = 0
	var total_c: int = 0
	for col: String in _dye_by_color:
		total_c += _dye_by_color[col]
		if _dye_by_color[col] > max_c:
			max_c = _dye_by_color[col]
	if total_c == 0:
		return "none"
	var dominance: float = max_c * 1.0 / total_c
	if dominance >= 0.6:
		return "uniform"
	if dominance >= 0.3:
		return "mixed"
	return "eclectic"

func get_material_waste_pct() -> float:
	var redyed: int = maxf(_total_dyed - _dyed_items.size(), 0)
	if _total_dyed == 0:
		return 0.0
	return snapped(redyed * 100.0 / _total_dyed, 0.1)

func get_trend_direction() -> String:
	var used: int = DYE_COLORS.size() - get_unused_color_count()
	var total: int = DYE_COLORS.size()
	if total == 0:
		return "none"
	var usage: float = used * 1.0 / total
	if usage >= 0.8:
		return "diversifying"
	if usage >= 0.4:
		return "expanding"
	return "narrow"

func get_summary() -> Dictionary:
	return {
		"available_colors": DYE_COLORS.size(),
		"dyed_items": _dyed_items.size(),
		"total_dyed": _total_dyed,
		"most_popular": get_most_popular_color(),
		"least_popular": get_least_popular_color(),
		"by_color": _dye_by_color.duplicate(),
		"unused_colors": get_unused_color_count(),
		"active_dye_pct": get_dye_rate(),
		"dyes_per_color": snappedf(float(_total_dyed) / maxf(float(DYE_COLORS.size()), 1.0), 0.1),
		"used_color_count": DYE_COLORS.size() - get_unused_color_count(),
		"color_diversity_pct": get_color_diversity_pct(),
		"fashion_rating": get_fashion_rating(),
		"avg_dyes_per_item": get_avg_dyes_per_item(),
		"aesthetic_cohesion": get_aesthetic_cohesion(),
		"material_waste_pct": get_material_waste_pct(),
		"trend_direction": get_trend_direction(),
		"dye_ecosystem_health": get_dye_ecosystem_health(),
		"aesthetic_governance": get_aesthetic_governance(),
		"fashion_maturity_index": get_fashion_maturity_index(),
	}

func get_dye_ecosystem_health() -> float:
	var cohesion := get_aesthetic_cohesion()
	var c_val: float = 90.0 if cohesion in ["unified", "harmonious"] else (60.0 if cohesion in ["diverse", "mixed"] else 30.0)
	var waste := get_material_waste_pct()
	var w_val: float = maxf(100.0 - waste, 0.0)
	var rating := get_fashion_rating()
	var r_val: float = 90.0 if rating == "Fashionable" else (60.0 if rating == "Moderate" else 30.0)
	return snapped((c_val + w_val + r_val) / 3.0, 0.1)

func get_fashion_maturity_index() -> float:
	var diversity := get_color_diversity_pct()
	var trend := get_trend_direction()
	var t_val: float = 90.0 if trend == "diversifying" else (60.0 if trend == "expanding" else 30.0)
	var dye_rate := get_dye_rate()
	return snapped((diversity + t_val + dye_rate) / 3.0, 0.1)

func get_aesthetic_governance() -> String:
	var ecosystem := get_dye_ecosystem_health()
	var maturity := get_fashion_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _dyed_items.size() > 0:
		return "Nascent"
	return "Dormant"
