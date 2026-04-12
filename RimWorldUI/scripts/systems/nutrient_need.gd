extends Node

const NUTRIENTS: Dictionary = {
	"Protein": {"daily_need": 0.4, "sources": ["Meat", "Eggs", "Milk", "Insect Meat"]},
	"Carbs": {"daily_need": 0.35, "sources": ["Rice", "Corn", "Potato", "Berries"]},
	"Vitamins": {"daily_need": 0.15, "sources": ["Berries", "Healroot", "Vegetables"]},
	"Fat": {"daily_need": 0.1, "sources": ["Meat", "Milk", "Cheese"]},
}

const FOOD_NUTRIENTS: Dictionary = {
	"SimpleMeal": {"Protein": 0.3, "Carbs": 0.4, "Vitamins": 0.2, "Fat": 0.1},
	"FineMeal": {"Protein": 0.35, "Carbs": 0.3, "Vitamins": 0.25, "Fat": 0.1},
	"LavishMeal": {"Protein": 0.3, "Carbs": 0.25, "Vitamins": 0.3, "Fat": 0.15},
	"NutrientPaste": {"Protein": 0.25, "Carbs": 0.5, "Vitamins": 0.15, "Fat": 0.1},
	"Pemmican": {"Protein": 0.4, "Carbs": 0.3, "Vitamins": 0.1, "Fat": 0.2},
	"RawMeat": {"Protein": 0.7, "Carbs": 0.0, "Vitamins": 0.1, "Fat": 0.2},
	"RawVegetable": {"Protein": 0.1, "Carbs": 0.5, "Vitamins": 0.35, "Fat": 0.05},
	"InsectJelly": {"Protein": 0.2, "Carbs": 0.6, "Vitamins": 0.1, "Fat": 0.1},
}

var _pawn_nutrition: Dictionary = {}


func record_meal(pawn_id: int, food_type: String) -> Dictionary:
	if not FOOD_NUTRIENTS.has(food_type):
		return {"success": false}
	var nutrients: Dictionary = FOOD_NUTRIENTS[food_type]
	if not _pawn_nutrition.has(pawn_id):
		_pawn_nutrition[pawn_id] = {"Protein": 0.0, "Carbs": 0.0, "Vitamins": 0.0, "Fat": 0.0}
	for n: String in nutrients:
		_pawn_nutrition[pawn_id][n] = float(_pawn_nutrition[pawn_id].get(n, 0.0)) + float(nutrients[n])
	return {"success": true, "nutrients": nutrients}


func get_deficiencies(pawn_id: int) -> Array:
	var status: Dictionary = _pawn_nutrition.get(pawn_id, {})
	var deficiencies: Array = []
	for n: String in NUTRIENTS:
		var need: float = float(NUTRIENTS[n].daily_need)
		var have: float = float(status.get(n, 0.0))
		if have < need * 0.5:
			deficiencies.append(n)
	return deficiencies


func get_best_food_for_nutrient(nutrient: String) -> String:
	var best: String = ""
	var best_val: float = 0.0
	for food: String in FOOD_NUTRIENTS:
		var val: float = float(FOOD_NUTRIENTS[food].get(nutrient, 0.0))
		if val > best_val:
			best_val = val
			best = food
	return best


func get_pawn_nutrition_pct(pawn_id: int) -> Dictionary:
	var status: Dictionary = _pawn_nutrition.get(pawn_id, {})
	var result: Dictionary = {}
	for n: String in NUTRIENTS:
		var need: float = float(NUTRIENTS[n].daily_need)
		var have: float = float(status.get(n, 0.0))
		result[n] = snappedf(have / need * 100.0, 0.1) if need > 0 else 0.0
	return result


func get_colony_deficiency_count() -> Dictionary:
	var counts: Dictionary = {}
	for pid: int in _pawn_nutrition:
		var defs: Array = get_deficiencies(pid)
		for d: String in defs:
			counts[d] = counts.get(d, 0) + 1
	return counts


func get_most_deficient_nutrient() -> String:
	var counts := get_colony_deficiency_count()
	var worst: String = ""
	var worst_n: int = 0
	for n: String in counts:
		if counts[n] > worst_n:
			worst_n = counts[n]
			worst = n
	return worst


func get_total_deficiencies() -> int:
	var total: int = 0
	for n: String in get_colony_deficiency_count():
		total += get_colony_deficiency_count()[n]
	return total


func has_any_deficiency() -> bool:
	return get_total_deficiencies() > 0


func get_avg_nutrient_level() -> Dictionary:
	if _pawn_nutrition.is_empty():
		return {}
	var sums: Dictionary = {}
	for pid: int in _pawn_nutrition:
		for n: String in _pawn_nutrition[pid]:
			sums[n] = sums.get(n, 0.0) + float(_pawn_nutrition[pid][n])
	var avgs: Dictionary = {}
	for n: String in sums:
		avgs[n] = snappedf(sums[n] / float(_pawn_nutrition.size()), 0.01)
	return avgs


func get_deficient_pawn_count() -> int:
	var count: int = 0
	for pid: int in _pawn_nutrition:
		if not get_deficiencies(pid).is_empty():
			count += 1
	return count


func get_well_fed_pawn_count() -> int:
	return _pawn_nutrition.size() - get_deficient_pawn_count()


func get_nutrition_health() -> String:
	var deficient: int = get_deficient_pawn_count()
	var total: int = _pawn_nutrition.size()
	if total == 0:
		return "N/A"
	var pct: float = float(deficient) / float(total) * 100.0
	if pct == 0.0:
		return "Excellent"
	elif pct < 20.0:
		return "Good"
	elif pct < 50.0:
		return "Concerning"
	return "Critical"

func get_nutrient_coverage_pct() -> float:
	if NUTRIENTS.is_empty() or _pawn_nutrition.is_empty():
		return 0.0
	var adequate: int = 0
	var total_checks: int = 0
	for pid: int in _pawn_nutrition:
		var levels: Dictionary = _pawn_nutrition[pid]
		for n: String in NUTRIENTS:
			total_checks += 1
			if levels.get(n, 0.0) >= 0.5:
				adequate += 1
	if total_checks == 0:
		return 0.0
	return snappedf(float(adequate) / float(total_checks) * 100.0, 0.1)

func get_malnutrition_risk() -> String:
	var total_def: int = get_total_deficiencies()
	if total_def == 0:
		return "None"
	elif total_def <= 3:
		return "Low"
	elif total_def <= 8:
		return "Moderate"
	return "High"

func get_summary() -> Dictionary:
	return {
		"nutrient_types": NUTRIENTS.size(),
		"food_types": FOOD_NUTRIENTS.size(),
		"tracked_pawns": _pawn_nutrition.size(),
		"colony_deficiencies": get_colony_deficiency_count(),
		"most_deficient": get_most_deficient_nutrient(),
		"total_deficiencies": get_total_deficiencies(),
		"has_deficiency": has_any_deficiency(),
		"avg_nutrient_level": get_avg_nutrient_level(),
		"deficient_pawns": get_deficient_pawn_count(),
		"well_fed_pawns": get_well_fed_pawn_count(),
		"nutrition_health": get_nutrition_health(),
		"nutrient_coverage_pct": get_nutrient_coverage_pct(),
		"malnutrition_risk": get_malnutrition_risk(),
		"dietary_safety_net": get_dietary_safety_net(),
		"deficiency_forecast": get_deficiency_forecast(),
		"nutrition_fulfillment_efficiency": get_nutrition_fulfillment_efficiency(),
		"nutritional_governance": get_nutritional_governance(),
		"dietary_ecosystem_health": get_dietary_ecosystem_health(),
		"metabolic_resilience_index": get_metabolic_resilience_index(),
	}

func get_dietary_safety_net() -> String:
	var well_fed := get_well_fed_pawn_count()
	var total := _pawn_nutrition.size()
	if total <= 0:
		return "N/A"
	var ratio := float(well_fed) / float(total)
	if ratio >= 0.9:
		return "Strong"
	elif ratio >= 0.6:
		return "Adequate"
	return "Thin"

func get_deficiency_forecast() -> String:
	var risk := get_malnutrition_risk()
	var coverage := get_nutrient_coverage_pct()
	if risk == "None" and coverage >= 80.0:
		return "Secure"
	elif risk in ["None", "Low"]:
		return "Stable"
	return "At Risk"

func get_nutrition_fulfillment_efficiency() -> float:
	var avg_dict: Dictionary = get_avg_nutrient_level()
	if avg_dict.is_empty():
		return 0.0
	var total: float = 0.0
	for key: String in avg_dict:
		total += float(avg_dict[key])
	var avg_val: float = total / maxf(float(avg_dict.size()), 1.0)
	if avg_val <= 0.0:
		return 0.0
	return snapped(minf(avg_val / 0.8 * 100.0, 100.0), 0.1)

func get_nutritional_governance() -> float:
	var coverage := get_nutrient_coverage_pct()
	var efficiency := get_nutrition_fulfillment_efficiency()
	var safety := get_dietary_safety_net()
	var safety_val: float = 90.0 if safety == "Strong" else (60.0 if safety == "Adequate" else 30.0)
	return snapped((coverage + efficiency + safety_val) / 3.0, 0.1)

func get_dietary_ecosystem_health() -> String:
	var governance := get_nutritional_governance()
	var forecast := get_deficiency_forecast()
	if governance >= 70.0 and forecast == "Secure":
		return "Thriving"
	elif governance >= 40.0 or forecast == "Stable":
		return "Sustainable"
	return "Fragile"

func get_metabolic_resilience_index() -> float:
	var well_fed := get_well_fed_pawn_count()
	var deficient := get_deficient_pawn_count()
	var total := _pawn_nutrition.size()
	if total <= 0:
		return 0.0
	var health_ratio := float(well_fed) / float(total) * 100.0
	var risk_penalty := float(deficient) / float(total) * 50.0
	return snapped(maxf(health_ratio - risk_penalty, 0.0), 0.1)
