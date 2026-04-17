class_name JobGiverCook
extends ThinkNode

## Issues cooking jobs when raw food is available and meals are needed.

const RAW_FOOD_DEFS: PackedStringArray = ["RawFood", "Rice", "Corn", "Meat"]
const MIN_RAW_FOOD := 3
const STOVE_DEFS: PackedStringArray = ["CookingStove", "Campfire", "ElectricStove"]

const MEALS_PER_COLONIST := 10
const MEAL_DEFS: PackedStringArray = ["MealSimple", "MealFine", "MealSurvival", "NutrientPaste", "Pemmican"]

func try_issue_job(pawn: Pawn) -> Dictionary:
	if not pawn.is_capable_of("Cooking"):
		return {}
	if pawn.drafted:
		return {}
	if not ThingManager:
		return {}

	var meal_count := _count_meals()
	var colonist_count := _count_colonists()
	if colonist_count > 0 and meal_count >= colonist_count * MEALS_PER_COLONIST:
		return {}

	var stove: Building = _find_best_stove(pawn)
	if stove == null:
		return {}
	if _count_raw_food() < MIN_RAW_FOOD:
		return {}

	var j := Job.new("Cook", stove.grid_pos)
	j.target_thing_id = stove.id
	return {"job": j, "source": self}


func _count_meals() -> int:
	var total: int = 0
	for t: Thing in ThingManager.things:
		if t is Item:
			var item := t as Item
			if item.state == Thing.ThingState.SPAWNED and item.def_name in MEAL_DEFS:
				total += item.stack_count
	return total


func _count_colonists() -> int:
	if not PawnManager:
		return 1
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead and (not p.has_meta("faction") or p.get_meta("faction") != "enemy"):
			count += 1
	return maxi(count, 1)


func _find_best_stove(cook: Pawn) -> Building:
	var best: Building = null
	var best_dist: int = 999
	for t: Thing in ThingManager.things:
		if not (t is Building):
			continue
		var b := t as Building
		if not (b.def_name in STOVE_DEFS):
			continue
		if b.build_state != Building.BuildState.COMPLETE:
			continue
		var dist: int = absi(b.grid_pos.x - cook.grid_pos.x) + absi(b.grid_pos.y - cook.grid_pos.y)
		if dist < best_dist:
			best_dist = dist
			best = b
	return best


func _count_raw_food() -> int:
	var total: int = 0
	for t: Thing in ThingManager.things:
		if t is Item:
			var item := t as Item
			if item.state == Thing.ThingState.SPAWNED and item.def_name in RAW_FOOD_DEFS:
				total += item.stack_count
	return total

func get_raw_food_type_count() -> int:
	return RAW_FOOD_DEFS.size()

func get_stove_type_count() -> int:
	return STOVE_DEFS.size()

func get_min_food_threshold() -> int:
	return MIN_RAW_FOOD

func get_available_stove_count() -> int:
	if not ThingManager:
		return 0
	var count: int = 0
	for t: Thing in ThingManager.things:
		if not (t is Building):
			continue
		var b := t as Building
		if b.def_name in STOVE_DEFS and b.build_state == Building.BuildState.COMPLETE:
			count += 1
	return count


func get_food_stock_ratio() -> float:
	var raw: int = _count_raw_food()
	if raw <= 0:
		return 0.0
	return snappedf(float(raw) / float(MIN_RAW_FOOD), 0.01)


func can_cook_now() -> bool:
	return _count_raw_food() >= MIN_RAW_FOOD and get_available_stove_count() > 0


func get_meal_production_rate() -> float:
	var stoves := get_available_stove_count()
	if stoves <= 0 or not can_cook_now():
		return 0.0
	var raw := _count_raw_food()
	var meals_possible := float(raw) / 10.0
	return snapped(minf(meals_possible, float(stoves) * 4.0), 0.1)

func get_food_security_score() -> float:
	var ratio := get_food_stock_ratio()
	var stoves := get_available_stove_count()
	var stove_factor := minf(float(stoves) / 2.0, 1.0)
	return snapped(clampf(ratio * 50.0 + stove_factor * 50.0, 0.0, 100.0), 0.1)

func get_nutrition_pipeline_health() -> String:
	var score := get_food_security_score()
	if score >= 80.0:
		return "Thriving"
	elif score >= 50.0:
		return "Stable"
	elif score >= 20.0:
		return "At Risk"
	return "Critical"

func get_cooking_summary() -> Dictionary:
	return {
		"raw_food_types": get_raw_food_type_count(),
		"stove_types": get_stove_type_count(),
		"min_food_threshold": MIN_RAW_FOOD,
		"available_stoves": get_available_stove_count(),
		"food_stock_ratio": get_food_stock_ratio(),
		"can_cook": can_cook_now(),
		"meal_production_rate": get_meal_production_rate(),
		"food_security_score": get_food_security_score(),
		"nutrition_pipeline": get_nutrition_pipeline_health(),
		"cooking_ecosystem_health": get_cooking_ecosystem_health(),
		"nutrition_governance": get_nutrition_governance(),
		"culinary_maturity_index": get_culinary_maturity_index(),
	}

func get_cooking_ecosystem_health() -> float:
	var rate := get_meal_production_rate()
	var security := get_food_security_score()
	var pipeline := get_nutrition_pipeline_health()
	var p_val: float = 90.0 if pipeline == "Thriving" else (65.0 if pipeline == "Adequate" else (35.0 if pipeline == "Struggling" else 15.0))
	return snapped((minf(rate * 10.0, 100.0) + security + p_val) / 3.0, 0.1)

func get_nutrition_governance() -> String:
	var eco := get_cooking_ecosystem_health()
	var mat := get_culinary_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif can_cook_now():
		return "Nascent"
	return "Dormant"

func get_culinary_maturity_index() -> float:
	var stoves := minf(float(get_available_stove_count()) * 20.0, 100.0)
	var ratio := minf(get_food_stock_ratio() * 50.0, 100.0)
	var security := get_food_security_score()
	return snapped((stoves + ratio + security) / 3.0, 0.1)
