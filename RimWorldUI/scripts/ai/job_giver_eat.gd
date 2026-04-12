class_name JobGiverEat
extends ThinkNode

## Finds food items on the map and issues eat jobs when hungry.
## Prefers meals > paste > raw, avoids spoiled food unless desperate.

const HUNGER_THRESHOLD := 0.25
const DESPERATE_THRESHOLD := 0.08
const FOOD_DEFS: PackedStringArray = [
	"MealFine", "MealSimple", "MealLavish", "NutrientPaste",
	"RawFood", "Meat", "Rice", "Corn", "Berries", "Pemmican",
]

func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.get_need("Food") > HUNGER_THRESHOLD:
		return {}
	if not ThingManager:
		return {}

	var desperate: bool = pawn.get_need("Food") < DESPERATE_THRESHOLD

	var best_food: Item = null
	var best_score: float = -999.0

	for thing: Thing in ThingManager.things:
		if not (thing is Item):
			continue
		var item: Item = thing as Item
		if item.state != Thing.ThingState.SPAWNED:
			continue
		if item.forbidden or item.hauled_by >= 0:
			continue
		var priority: int = _food_priority(item.def_name)
		if priority >= 999:
			continue

		var freshness: String = item.get_freshness_label() if item.has_method("get_freshness_label") else "Fresh"
		if freshness == "Rotten" and not desperate:
			continue
		if freshness == "Spoiling" and not desperate:
			priority += 2

		var dist: int = absi(item.grid_pos.x - pawn.grid_pos.x) + absi(item.grid_pos.y - pawn.grid_pos.y)
		var score: float = 100.0 - float(priority) * 20.0 - float(dist) * 0.5
		if freshness == "Stale":
			score -= 10.0
		if score > best_score:
			best_score = score
			best_food = item

	if best_food:
		var j := Job.new("Eat", best_food.grid_pos)
		j.target_thing_id = best_food.id
		return {"job": j, "source": self}

	var j := Job.new("Eat", pawn.grid_pos)
	return {"job": j, "source": self}


func _food_priority(def_name: String) -> int:
	match def_name:
		"MealLavish": return 0
		"MealFine": return 1
		"MealSimple": return 2
		"Pemmican": return 3
		"NutrientPaste": return 4
		"Berries": return 5
		"RawFood", "Rice", "Corn": return 6
		"Meat": return 7
	return 999

func get_food_type_count() -> int:
	return FOOD_DEFS.size()

func get_highest_priority_food() -> String:
	if FOOD_DEFS.is_empty():
		return ""
	var best: String = FOOD_DEFS[0]
	var best_p: int = _food_priority(best)
	for i: int in range(1, FOOD_DEFS.size()):
		var p: int = _food_priority(FOOD_DEFS[i])
		if p < best_p:
			best_p = p
			best = FOOD_DEFS[i]
	return best

func get_meal_type_count() -> int:
	var count: int = 0
	for fd: String in FOOD_DEFS:
		if fd.begins_with("Meal") or fd == "NutrientPaste":
			count += 1
	return count

func get_nutrition_coverage() -> float:
	var good := 0
	for fd: String in FOOD_DEFS:
		if _food_priority(fd) <= 4:
			good += 1
	return snapped(float(good) / maxf(FOOD_DEFS.size(), 1.0) * 100.0, 0.1)

func get_desperation_gap() -> float:
	return snapped(HUNGER_THRESHOLD / maxf(DESPERATE_THRESHOLD, 0.001), 0.01)

func get_diet_variety_score() -> int:
	var raw := 0
	var meals := 0
	var produce := 0
	for fd: String in FOOD_DEFS:
		if fd.begins_with("Meal") or fd == "NutrientPaste":
			meals += 1
		elif fd in ["Berries", "Rice", "Corn"]:
			produce += 1
		else:
			raw += 1
	return mini(raw, 1) + mini(meals, 1) + mini(produce, 1)

func get_food_summary() -> Dictionary:
	return {
		"food_types": get_food_type_count(),
		"best_food": get_highest_priority_food(),
		"meal_types": get_meal_type_count(),
		"hunger_threshold": HUNGER_THRESHOLD,
		"desperate_threshold": DESPERATE_THRESHOLD,
		"nutrition_coverage": get_nutrition_coverage(),
		"desperation_gap": get_desperation_gap(),
		"diet_variety_score": get_diet_variety_score(),
		"food_ecosystem_health": get_food_ecosystem_health(),
		"dietary_governance": get_dietary_governance(),
		"sustenance_maturity_index": get_sustenance_maturity_index(),
	}

func get_food_ecosystem_health() -> float:
	var coverage := get_nutrition_coverage()
	var variety := minf(float(get_diet_variety_score()) * 15.0, 100.0)
	var types := minf(float(get_food_type_count()) * 10.0, 100.0)
	return snapped((coverage + variety + types) / 3.0, 0.1)

func get_dietary_governance() -> String:
	var eco := get_food_ecosystem_health()
	var mat := get_sustenance_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_food_type_count() > 0:
		return "Nascent"
	return "Dormant"

func get_sustenance_maturity_index() -> float:
	var coverage := get_nutrition_coverage()
	var meals := minf(float(get_meal_type_count()) * 20.0, 100.0)
	var gap_inv := maxf(100.0 - get_desperation_gap() * 10.0, 0.0)
	return snapped((coverage + meals + gap_inv) / 3.0, 0.1)
