class_name JobDriverCook
extends JobDriver

## Walk to stove, consume raw ingredients, produce a meal. Skill affects quality.

const RAW_FOOD_DEFS: PackedStringArray = ["RawFood", "Rice", "Corn", "Meat"]
const INGREDIENTS_NEEDED := 3


func _make_toils() -> Array[Dictionary]:
	return [
		{
			"name": "goto_stove",
			"complete_mode": "never",
		},
		{
			"name": "cook",
			"complete_mode": "delay",
			"delay_ticks": 240,
		},
		{
			"name": "finish_cook",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"goto_stove":
			_start_walk()
		"finish_cook":
			_do_cook()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"goto_stove":
			_walk_tick()


func _start_walk() -> void:
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		end_job(false)
		return
	pawn.path = pf.find_path(pawn.grid_pos, job.target_pos)
	pawn.path_index = 0
	if pawn.path.is_empty():
		end_job(false)


func _walk_tick() -> void:
	if not pawn.has_path():
		_advance_toil()
		return
	var next := pawn.next_path_step()
	pawn.set_grid_pos(next)


func _do_cook() -> void:
	if not ThingManager:
		end_job(false)
		return
	var consumed := _consume_raw_food(INGREDIENTS_NEEDED)
	if consumed < INGREDIENTS_NEEDED:
		end_job(false)
		return

	var skill: int = pawn.get_skill_level("Cooking")
	var meal_type := _determine_meal(skill)

	var meal := Item.new(meal_type, 1)
	var drop_pos := pawn.grid_pos
	meal.spawn_at(drop_pos)
	ThingManager.spawn_thing(meal, drop_pos)

	pawn.gain_xp("Cooking", 60.0)

	if _is_food_poisoning(skill):
		if ColonyLog:
			ColonyLog.add_entry("Cook", "%s botched a meal (food poisoning risk)." % pawn.pawn_name, "warning")
	else:
		if ColonyLog:
			ColonyLog.add_entry("Cook", "%s cooked a %s." % [pawn.pawn_name, meal_type], "info")

	end_job(true)


func _determine_meal(skill: int) -> String:
	if skill >= 12:
		return "MealLavish" if randf() < 0.3 else "MealFine"
	elif skill >= 8:
		return "MealFine"
	elif skill >= 4:
		return "MealSimple"
	else:
		return "MealSimple" if randf() > 0.1 else "NutrientPaste"


func _is_food_poisoning(skill: int) -> bool:
	var chance: float = maxf(0.0, 0.15 - float(skill) * 0.012)
	return randf() < chance


func _consume_raw_food(amount: int) -> int:
	var consumed: int = 0
	var to_remove: Array[Thing] = []
	for t: Thing in ThingManager.things:
		if consumed >= amount:
			break
		if t is Item:
			var item := t as Item
			if item.state != Thing.ThingState.SPAWNED:
				continue
			if not (item.def_name in RAW_FOOD_DEFS):
				continue
			var take := mini(amount - consumed, item.stack_count)
			item.stack_count -= take
			consumed += take
			if item.stack_count <= 0:
				to_remove.append(t)
	for t: Thing in to_remove:
		ThingManager.remove_thing(t)
	return consumed


func get_food_poisoning_chance() -> float:
	var skill: int = pawn.get_skill_level("Cooking")
	return maxf(0.0, 0.15 - float(skill) * 0.012)


func get_expected_meal_type() -> String:
	return _determine_meal(pawn.get_skill_level("Cooking"))


func count_available_ingredients() -> int:
	if not ThingManager:
		return 0
	var total: int = 0
	for t: Thing in ThingManager.things:
		if t is Item:
			var item := t as Item
			if item.state == Thing.ThingState.SPAWNED and item.def_name in RAW_FOOD_DEFS:
				total += item.stack_count
	return total


func _get_map() -> MapData:
	if GameState and GameState.has_method("get_map"):
		return GameState.get_map()
	return null
