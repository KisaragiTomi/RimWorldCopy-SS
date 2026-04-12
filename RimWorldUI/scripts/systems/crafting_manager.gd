extends Node

## Crafting system with recipes, material validation, and quality output.
## Registered as autoload "CraftingManager".

signal item_crafted(recipe_name: String, pawn_name: String)

const RECIPES: Dictionary = {
	"SimpleClothes": {
		"label": "Simple Clothes",
		"ingredients": {"Cloth": 30},
		"output": "SimpleClothes",
		"output_count": 1,
		"work_ticks": 400,
		"skill": "Crafting",
		"min_skill": 3,
		"xp": 80.0,
	},
	"ComponentIndustrial": {
		"label": "Component (Industrial)",
		"ingredients": {"Steel": 12},
		"output": "ComponentIndustrial",
		"output_count": 1,
		"work_ticks": 500,
		"skill": "Crafting",
		"min_skill": 5,
		"xp": 100.0,
	},
	"HerbalMedicine_Craft": {
		"label": "Herbal Medicine",
		"ingredients": {"Healroot_Leaf": 1},
		"output": "HerbalMedicine",
		"output_count": 1,
		"work_ticks": 200,
		"skill": "Medicine",
		"min_skill": 2,
		"xp": 60.0,
	},
	"StoneBlock": {
		"label": "Stone Blocks",
		"ingredients": {"Stone": 20},
		"output": "StoneBlock",
		"output_count": 20,
		"work_ticks": 300,
		"skill": "Crafting",
		"min_skill": 0,
		"xp": 40.0,
	},
	"SteelSword": {
		"label": "Steel Sword",
		"ingredients": {"Steel": 25},
		"output": "SteelSword",
		"output_count": 1,
		"work_ticks": 600,
		"skill": "Crafting",
		"min_skill": 6,
		"xp": 120.0,
	},
	"Medicine_Craft": {
		"label": "Medicine",
		"ingredients": {"HerbalMedicine": 1, "Cloth": 3, "Healroot_Leaf": 1},
		"output": "Medicine",
		"output_count": 1,
		"work_ticks": 350,
		"skill": "Medicine",
		"min_skill": 6,
		"xp": 90.0,
	},
	"Flak_Vest": {
		"label": "Flak Vest",
		"ingredients": {"Steel": 30, "Cloth": 20},
		"output": "FlakVest",
		"output_count": 1,
		"work_ticks": 700,
		"skill": "Crafting",
		"min_skill": 7,
		"xp": 150.0,
	},
}

var craft_queue: Array[Dictionary] = []
var total_crafted: int = 0


func add_to_queue(recipe_name: String, count: int = 1) -> bool:
	if not RECIPES.has(recipe_name):
		return false
	for i: int in count:
		craft_queue.append({"recipe": recipe_name, "assigned": false})
	return true


func remove_from_queue(recipe_name: String) -> bool:
	var i := craft_queue.size() - 1
	while i >= 0:
		if craft_queue[i].get("recipe", "") == recipe_name:
			craft_queue.remove_at(i)
			return true
		i -= 1
	return false


func get_next_unassigned() -> Dictionary:
	for entry: Dictionary in craft_queue:
		if not entry.get("assigned", false):
			return entry
	return {}


func has_ingredients(recipe_name: String) -> bool:
	var recipe: Dictionary = RECIPES.get(recipe_name, {})
	if recipe.is_empty():
		return false
	var ingredients: Dictionary = recipe.get("ingredients", {})
	if not ThingManager:
		return false
	for mat_name: String in ingredients:
		var needed: int = ingredients[mat_name]
		var available: int = _count_material(mat_name)
		if available < needed:
			return false
	return true


func consume_ingredients(recipe_name: String) -> bool:
	var recipe: Dictionary = RECIPES.get(recipe_name, {})
	if recipe.is_empty():
		return false
	var ingredients: Dictionary = recipe.get("ingredients", {})
	if not ThingManager:
		return false
	for mat_name: String in ingredients:
		var needed: int = ingredients[mat_name]
		if not _consume_material(mat_name, needed):
			return false
	return true


func complete_craft(recipe_name: String, crafter: Pawn) -> Dictionary:
	var recipe: Dictionary = RECIPES.get(recipe_name, {})
	if recipe.is_empty():
		return {}

	var output_name: String = recipe.get("output", "") as String
	var output_count: int = recipe.get("output_count", 1) as int
	var xp_amount: float = recipe.get("xp", 50.0) as float
	var skill_name: String = recipe.get("skill", "Crafting") as String

	crafter.gain_xp(skill_name, xp_amount)
	total_crafted += 1

	var i := craft_queue.size() - 1
	while i >= 0:
		if craft_queue[i].get("recipe", "") == recipe_name:
			craft_queue.remove_at(i)
			break
		i -= 1

	var quality: String = _roll_quality(crafter.get_skill_level(skill_name))
	_quality_counts[quality] = _quality_counts.get(quality, 0) + 1

	item_crafted.emit(recipe_name, crafter.pawn_name)
	if ColonyLog:
		ColonyLog.add_entry("Work", "%s crafted %s (%s)." % [
			crafter.pawn_name, recipe.get("label", output_name), quality
		], "info")

	return {"item": output_name, "count": output_count, "quality": quality}


func can_craft(recipe_name: String, crafter: Pawn) -> bool:
	var recipe: Dictionary = RECIPES.get(recipe_name, {})
	if recipe.is_empty():
		return false
	var min_skill: int = recipe.get("min_skill", 0) as int
	var skill_name: String = recipe.get("skill", "Crafting") as String
	return crafter.get_skill_level(skill_name) >= min_skill


func _count_material(mat_name: String) -> int:
	var total: int = 0
	for t: Thing in ThingManager.things:
		if t is Item:
			var item := t as Item
			if item.state == Thing.ThingState.SPAWNED and item.def_name == mat_name:
				total += item.stack_count
	return total


func _consume_material(mat_name: String, amount: int) -> bool:
	var remaining: int = amount
	var to_remove: Array[Thing] = []
	for t: Thing in ThingManager.things:
		if remaining <= 0:
			break
		if t is Item:
			var item := t as Item
			if item.state == Thing.ThingState.SPAWNED and item.def_name == mat_name:
				var take: int = mini(remaining, item.stack_count)
				item.stack_count -= take
				remaining -= take
				if item.stack_count <= 0:
					to_remove.append(t)
	for t: Thing in to_remove:
		ThingManager.remove_thing(t)
	return remaining <= 0


func _roll_quality(skill_level: int) -> String:
	var roll: float = randf()
	var bonus: float = skill_level * 0.03
	roll += bonus
	if roll > 1.1:
		return "Masterwork"
	elif roll > 0.95:
		return "Excellent"
	elif roll > 0.75:
		return "Good"
	elif roll > 0.45:
		return "Normal"
	elif roll > 0.2:
		return "Poor"
	return "Awful"


var _quality_counts: Dictionary = {}


func get_craftable_recipes(crafter: Pawn) -> Array[String]:
	var result: Array[String] = []
	for recipe_name: String in RECIPES:
		if can_craft(recipe_name, crafter) and has_ingredients(recipe_name):
			result.append(recipe_name)
	return result


func get_missing_ingredients(recipe_name: String) -> Dictionary:
	var recipe: Dictionary = RECIPES.get(recipe_name, {})
	if recipe.is_empty():
		return {}
	var ingredients: Dictionary = recipe.get("ingredients", {})
	var missing: Dictionary = {}
	for mat_name: String in ingredients:
		var needed: int = ingredients[mat_name]
		var available: int = _count_material(mat_name)
		if available < needed:
			missing[mat_name] = needed - available
	return missing


func get_queue_by_recipe() -> Dictionary:
	var counts: Dictionary = {}
	for entry: Dictionary in craft_queue:
		var r: String = entry.get("recipe", "")
		counts[r] = counts.get(r, 0) + 1
	return counts


func get_most_crafted_quality() -> String:
	var best: String = "Normal"
	var best_c: int = 0
	for q: String in _quality_counts:
		if _quality_counts[q] > best_c:
			best_c = _quality_counts[q]
			best = q
	return best


func get_total_work_ticks_queued() -> int:
	var total: int = 0
	for entry: Dictionary in craft_queue:
		var r: String = entry.get("recipe", "")
		var recipe: Dictionary = RECIPES.get(r, {})
		total += recipe.get("work_ticks", 0) as int
	return total


func get_unassigned_count() -> int:
	var cnt: int = 0
	for entry: Dictionary in craft_queue:
		if not entry.get("assigned", false):
			cnt += 1
	return cnt


func get_recipe_diversity() -> int:
	var used: Dictionary = {}
	for entry: Dictionary in craft_queue:
		used[entry.get("recipe", "")] = true
	return used.size()


func get_avg_craft_per_recipe() -> float:
	if RECIPES.is_empty():
		return 0.0
	return float(total_crafted) / float(RECIPES.size())


func get_assigned_percentage() -> float:
	if craft_queue.is_empty():
		return 0.0
	var assigned: int = 0
	for entry: Dictionary in craft_queue:
		if entry.get("assigned", false):
			assigned += 1
	return float(assigned) / float(craft_queue.size()) * 100.0


func get_completion_rate() -> float:
	var total_attempts: int = total_crafted + craft_queue.size()
	if total_attempts <= 0:
		return 0.0
	return snappedf(float(total_crafted) / float(total_attempts) * 100.0, 0.1)


func get_good_quality_ratio() -> float:
	var good: int = _quality_counts.get("Good", 0) + _quality_counts.get("Excellent", 0) + _quality_counts.get("Legendary", 0)
	if total_crafted <= 0:
		return 0.0
	return snappedf(float(good) / float(total_crafted) * 100.0, 0.1)


func get_avg_work_per_item() -> float:
	if craft_queue.is_empty():
		return 0.0
	return snappedf(float(get_total_work_ticks_queued()) / float(craft_queue.size()), 0.1)


func get_production_throughput() -> float:
	if total_crafted <= 0:
		return 0.0
	var assigned := get_assigned_percentage()
	return snapped(float(total_crafted) * assigned / 100.0, 0.1)

func get_quality_consistency() -> float:
	if total_crafted <= 0:
		return 0.0
	var counts: Array[int] = []
	for q: String in _quality_counts:
		counts.append(_quality_counts[q])
	if counts.is_empty():
		return 100.0
	var avg := float(total_crafted) / float(counts.size())
	var variance := 0.0
	for c: int in counts:
		variance += (float(c) - avg) * (float(c) - avg)
	variance /= float(counts.size())
	return snapped(maxf(0.0, 100.0 - variance * 0.1), 0.1)

func get_manufacturing_health() -> String:
	var completion := get_completion_rate()
	var good_ratio := get_good_quality_ratio()
	var assigned := get_assigned_percentage()
	if completion >= 80.0 and good_ratio >= 50.0 and assigned >= 70.0:
		return "Optimal"
	elif completion >= 50.0 and assigned >= 40.0:
		return "Productive"
	elif assigned >= 20.0:
		return "Underperforming"
	return "Stalled"

func get_summary() -> Dictionary:
	return {
		"queue_size": craft_queue.size(),
		"total_crafted": total_crafted,
		"recipes_available": RECIPES.keys(),
		"queue_breakdown": get_queue_by_recipe(),
		"quality_stats": _quality_counts.duplicate(),
		"most_crafted_quality": get_most_crafted_quality(),
		"queued_work_ticks": get_total_work_ticks_queued(),
		"unassigned": get_unassigned_count(),
		"recipe_diversity": get_recipe_diversity(),
		"avg_craft_per_recipe": snappedf(get_avg_craft_per_recipe(), 0.01),
		"assigned_pct": snappedf(get_assigned_percentage(), 0.1),
		"completion_rate_pct": get_completion_rate(),
		"good_quality_ratio_pct": get_good_quality_ratio(),
		"avg_work_per_item": get_avg_work_per_item(),
		"production_throughput": get_production_throughput(),
		"quality_consistency": get_quality_consistency(),
		"manufacturing_health": get_manufacturing_health(),
		"industrial_capacity_index": get_industrial_capacity_index(),
		"artisan_skill_rating": get_artisan_skill_rating(),
		"supply_chain_maturity": get_supply_chain_maturity(),
		"manufacturing_ecosystem_health": get_manufacturing_ecosystem_health(),
		"production_governance": get_production_governance(),
		"industrial_maturity_index": get_industrial_maturity_index(),
	}

func get_industrial_capacity_index() -> float:
	var throughput := get_production_throughput()
	var diversity := get_recipe_diversity()
	if throughput in ["High", "Excellent"]:
		return snapped(float(diversity) * 10.0, 0.1)
	return snapped(float(diversity) * 5.0, 0.1)

func get_artisan_skill_rating() -> String:
	var good_ratio := get_good_quality_ratio()
	if good_ratio >= 80.0:
		return "Master"
	elif good_ratio >= 50.0:
		return "Skilled"
	elif good_ratio >= 20.0:
		return "Apprentice"
	return "Novice"

func get_supply_chain_maturity() -> String:
	var health := get_manufacturing_health()
	var completion := get_completion_rate()
	if health in ["Excellent", "Strong"] and completion >= 80.0:
		return "Mature"
	elif health not in ["Poor", "Failing"]:
		return "Developing"
	return "Immature"

func get_manufacturing_ecosystem_health() -> float:
	var capacity := get_industrial_capacity_index()
	var consistency := get_quality_consistency()
	var completion := get_completion_rate()
	return snapped((minf(capacity, 100.0) + consistency + completion) / 3.0, 0.1)

func get_production_governance() -> String:
	var health := get_manufacturing_ecosystem_health()
	var maturity := get_supply_chain_maturity()
	if health >= 65.0 and maturity == "Mature":
		return "Industrial"
	elif health >= 35.0:
		return "Artisanal"
	return "Primitive"

func get_industrial_maturity_index() -> float:
	var skill := get_artisan_skill_rating()
	var s_val: float = 90.0 if skill == "Master" else (70.0 if skill == "Skilled" else (40.0 if skill == "Apprentice" else 20.0))
	var assigned := get_assigned_percentage()
	return snapped((s_val + assigned) / 2.0, 0.1)
