extends Node

var _pawn_preferences: Dictionary = {}

const FOOD_TYPES: Dictionary = {
	"Lavish": {"nutrition": 1.0, "mood": 12, "tier": 4, "ingredients": 2},
	"Fine": {"nutrition": 0.9, "mood": 5, "tier": 3, "ingredients": 1},
	"Simple": {"nutrition": 0.9, "mood": 0, "tier": 2, "ingredients": 1},
	"Pemmican": {"nutrition": 0.05, "mood": -3, "tier": 2, "shelf_life": 70},
	"Packaged": {"nutrition": 0.9, "mood": -3, "tier": 2, "shelf_life": -1},
	"NutrientPaste": {"nutrition": 0.9, "mood": -4, "tier": 1},
	"RawVeggie": {"nutrition": 0.05, "mood": -7, "tier": 0},
	"RawMeat": {"nutrition": 0.05, "mood": -15, "tier": 0},
	"Kibble": {"nutrition": 0.05, "mood": -12, "tier": 0},
	"InsectJelly": {"nutrition": 0.05, "mood": 5, "tier": 3},
	"Berries": {"nutrition": 0.05, "mood": 0, "tier": 1},
	"HumanMeat": {"nutrition": 0.05, "mood": -20, "tier": -1}
}

const TRAIT_PREFERENCES: Dictionary = {
	"Gourmand": {"preferred": ["Lavish", "Fine"], "avoid": ["NutrientPaste", "RawMeat"]},
	"Ascetic": {"preferred": ["Simple", "RawVeggie"], "avoid": ["Lavish"]},
	"Cannibal": {"preferred": ["HumanMeat"], "avoid": []},
	"Bloodlust": {"preferred": [], "avoid": []},
	"Kind": {"preferred": [], "avoid": ["HumanMeat"]}
}

func set_preference(pawn_id: int, pawn_trait: String) -> void:
	_pawn_preferences[pawn_id] = pawn_trait

func get_best_food(pawn_id: int, available_foods: Array) -> String:
	var pawn_trait: String = _pawn_preferences.get(pawn_id, "")
	var prefs: Dictionary = TRAIT_PREFERENCES.get(pawn_trait, {})
	var preferred: Array = prefs.get("preferred", [])
	var avoid: Array = prefs.get("avoid", [])
	for p: String in preferred:
		if available_foods.has(p):
			return p
	var best: String = ""
	var best_tier: int = -99
	for food: String in available_foods:
		if avoid.has(food):
			continue
		var tier: int = FOOD_TYPES.get(food, {}).get("tier", 0)
		if tier > best_tier:
			best_tier = tier
			best = food
	return best

func get_mood_from_food(food: String) -> int:
	return FOOD_TYPES.get(food, {}).get("mood", 0)

func get_best_mood_food() -> String:
	var best: String = ""
	var best_mood: int = -999
	for food: String in FOOD_TYPES:
		var m: int = int(FOOD_TYPES[food].get("mood", 0))
		if m > best_mood:
			best_mood = m
			best = food
	return best


func get_foods_by_tier(tier: int) -> Array[String]:
	var result: Array[String] = []
	for food: String in FOOD_TYPES:
		if int(FOOD_TYPES[food].get("tier", 0)) == tier:
			result.append(food)
	return result


func get_pawn_trait_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pid: int in _pawn_preferences:
		var t: String = String(_pawn_preferences[pid])
		dist[t] = dist.get(t, 0) + 1
	return dist


func get_negative_mood_food_count() -> int:
	var count: int = 0
	for food: String in FOOD_TYPES:
		if int(FOOD_TYPES[food].get("mood", 0)) < 0:
			count += 1
	return count


func get_avg_food_mood() -> float:
	var total: int = 0
	for food: String in FOOD_TYPES:
		total += int(FOOD_TYPES[food].get("mood", 0))
	return float(total) / maxf(FOOD_TYPES.size(), 1)


func get_highest_tier_food() -> String:
	var best: String = ""
	var best_tier: int = -999
	for food: String in FOOD_TYPES:
		var t: int = int(FOOD_TYPES[food].get("tier", 0))
		if t > best_tier:
			best_tier = t
			best = food
	return best


func get_tier_count() -> int:
	var tiers: Dictionary = {}
	for food: String in FOOD_TYPES:
		tiers[int(FOOD_TYPES[food].get("tier", 0))] = true
	return tiers.size()


func get_shelf_stable_count() -> int:
	var count: int = 0
	for food: String in FOOD_TYPES:
		if FOOD_TYPES[food].has("shelf_life"):
			count += 1
	return count


func get_worst_mood_food() -> String:
	var worst: String = ""
	var worst_m: int = 999
	for food: String in FOOD_TYPES:
		var m: int = int(FOOD_TYPES[food].get("mood", 0))
		if m < worst_m:
			worst_m = m
			worst = food
	return worst


func get_multi_ingredient_food_count() -> int:
	var count: int = 0
	for food: String in FOOD_TYPES:
		if int(FOOD_TYPES[food].get("ingredients", 0)) >= 2:
			count += 1
	return count


func get_avg_nutrition() -> float:
	if FOOD_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for food: String in FOOD_TYPES:
		total += float(FOOD_TYPES[food].get("nutrition", 0.0))
	return total / FOOD_TYPES.size()


func get_trait_count_with_avoidance() -> int:
	var count: int = 0
	for t: String in TRAIT_PREFERENCES:
		if not TRAIT_PREFERENCES[t].get("avoid", []).is_empty():
			count += 1
	return count


func get_dietary_health() -> String:
	var neg: int = get_negative_mood_food_count()
	var total: int = FOOD_TYPES.size()
	if total == 0:
		return "N/A"
	var neg_ratio: float = float(neg) / float(total)
	if neg_ratio <= 0.1:
		return "Excellent"
	elif neg_ratio <= 0.25:
		return "Good"
	elif neg_ratio <= 0.5:
		return "Fair"
	return "Poor"

func get_variety_score() -> String:
	var tiers: int = get_tier_count()
	if tiers >= 5:
		return "Diverse"
	elif tiers >= 3:
		return "Moderate"
	elif tiers >= 2:
		return "Limited"
	return "Monotone"

func get_food_safety_pct() -> float:
	if FOOD_TYPES.is_empty():
		return 0.0
	return snappedf(float(get_shelf_stable_count()) / float(FOOD_TYPES.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"food_types": FOOD_TYPES.size(),
		"trait_preferences": TRAIT_PREFERENCES.size(),
		"tracked_pawns": _pawn_preferences.size(),
		"best_mood_food": get_best_mood_food(),
		"negative_mood_foods": get_negative_mood_food_count(),
		"avg_mood": snapped(get_avg_food_mood(), 0.1),
		"highest_tier": get_highest_tier_food(),
		"tier_count": get_tier_count(),
		"shelf_stable": get_shelf_stable_count(),
		"worst_mood_food": get_worst_mood_food(),
		"multi_ingredient_foods": get_multi_ingredient_food_count(),
		"avg_nutrition": snapped(get_avg_nutrition(), 0.01),
		"traits_with_avoidance": get_trait_count_with_avoidance(),
		"dietary_health": get_dietary_health(),
		"variety_score": get_variety_score(),
		"food_safety_pct": get_food_safety_pct(),
		"culinary_sophistication": get_culinary_sophistication(),
		"nutritional_coverage": get_nutritional_coverage(),
		"morale_food_impact": get_morale_food_impact(),
		"dietary_ecosystem_health": get_dietary_ecosystem_health(),
		"nutrition_governance": get_nutrition_governance(),
		"culinary_maturity_index": get_culinary_maturity_index(),
	}

func get_culinary_sophistication() -> String:
	var tiers := get_tier_count()
	var variety := get_variety_score()
	if tiers >= 4 and variety in ["Excellent", "Good"]:
		return "Gourmet"
	elif tiers >= 2:
		return "Standard"
	return "Basic"

func get_nutritional_coverage() -> float:
	var stable := get_shelf_stable_count()
	var total := FOOD_TYPES.size()
	if total <= 0:
		return 0.0
	return snapped(float(stable) / float(total) * 100.0, 0.1)

func get_morale_food_impact() -> String:
	var avg := get_avg_food_mood()
	if avg >= 5.0:
		return "Uplifting"
	elif avg >= 0.0:
		return "Neutral"
	return "Depressing"

func get_dietary_ecosystem_health() -> float:
	var morale := get_morale_food_impact()
	var m_val: float = 90.0 if morale == "Uplifting" else (60.0 if morale == "Neutral" else 30.0)
	var coverage := get_nutritional_coverage()
	var safety := get_food_safety_pct()
	return snapped((m_val + coverage + safety) / 3.0, 0.1)

func get_culinary_maturity_index() -> float:
	var health := get_dietary_health()
	var h_val: float = 90.0 if health in ["Excellent", "Healthy"] else (60.0 if health in ["Adequate", "Moderate"] else 30.0)
	var variety := get_variety_score()
	var v_val: float = 90.0 if variety in ["Diverse", "Rich"] else (60.0 if variety in ["Moderate", "Decent"] else 30.0)
	var sophistication := get_culinary_sophistication()
	var s_val: float = 90.0 if sophistication in ["Gourmet", "Fine"] else (60.0 if sophistication in ["Average", "Moderate"] else 30.0)
	return snapped((h_val + v_val + s_val) / 3.0, 0.1)

func get_nutrition_governance() -> String:
	var ecosystem := get_dietary_ecosystem_health()
	var maturity := get_culinary_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _pawn_preferences.size() > 0:
		return "Nascent"
	return "Dormant"
