class_name JobDriverEat
extends JobDriver

## Walk to food item, consume it, restore food need with quality-based nutrition.

var _food_item: Item

const NUTRITION_VALUES: Dictionary = {
	"MealLavish": 1.0,
	"MealFine": 0.9,
	"MealSimple": 0.7,
	"Pemmican": 0.6,
	"NutrientPaste": 0.5,
	"Berries": 0.35,
	"RawFood": 0.4,
	"Meat": 0.3,
	"Rice": 0.3,
	"Corn": 0.35,
}

const MOOD_THOUGHTS: Dictionary = {
	"MealLavish": "AteLavishMeal",
	"MealFine": "AteFineMeal",
	"MealSimple": "",
	"Pemmican": "",
	"NutrientPaste": "AteNutrientPaste",
	"Berries": "",
	"RawFood": "AteRawFood",
	"Meat": "AteRawFood",
	"Rice": "AteRawFood",
	"Corn": "AteRawFood",
}


func _make_toils() -> Array[Dictionary]:
	_find_food()
	if _food_item:
		return [
			{
				"name": "goto_food",
				"complete_mode": "never",
			},
			{
				"name": "eat",
				"complete_mode": "delay",
				"delay_ticks": 120,
			},
			{
				"name": "finish",
				"complete_mode": "instant",
			},
		]
	return [
		{
			"name": "eat_nothing",
			"complete_mode": "delay",
			"delay_ticks": 60,
		},
		{
			"name": "finish",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"goto_food":
			_start_walk()
		"finish":
			if _food_item:
				_finish_eat()
			else:
				_finish_eat_nothing()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"goto_food":
			_walk_tick()


func _find_food() -> void:
	if not ThingManager or job.target_thing_id < 0:
		return
	for thing: Thing in ThingManager.things:
		if thing.id == job.target_thing_id and thing is Item:
			_food_item = thing as Item
			_food_item.hauled_by = pawn.id
			return


func _start_walk() -> void:
	if _food_item == null:
		end_job(false)
		return
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		end_job(false)
		return
	pawn.path = pf.find_path(pawn.grid_pos, _food_item.grid_pos)
	pawn.path_index = 0
	if pawn.path.is_empty():
		_food_item.hauled_by = -1
		end_job(false)


func _walk_tick() -> void:
	if not pawn.has_path():
		_advance_toil()
		return
	var next := pawn.next_path_step()
	pawn.set_grid_pos(next)


func _start_eat() -> void:
	pass


func _finish_eat() -> void:
	var nutrition: float = 0.6
	var food_name: String = ""

	if _food_item and _food_item.state == Thing.ThingState.SPAWNED:
		food_name = _food_item.def_name
		nutrition = NUTRITION_VALUES.get(food_name, 0.5)
		_food_item.hauled_by = -1
		if _food_item.stack_count <= 1:
			ThingManager.remove_thing(_food_item)
		else:
			_food_item.stack_count -= 1

	pawn.set_need("Food", minf(1.0, pawn.get_need("Food") + nutrition))

	var thought: String = MOOD_THOUGHTS.get(food_name, "")
	if thought != "" and pawn.thought_tracker:
		pawn.thought_tracker.add_thought(thought)

	end_job(true)


func _finish_eat_nothing() -> void:
	pawn.set_need("Food", minf(1.0, pawn.get_need("Food") + 0.15))
	if pawn.thought_tracker:
		pawn.thought_tracker.add_thought("AteWithoutTable")
	end_job(true)


func _get_map() -> MapData:
	if GameState and GameState.has_method("get_map"):
		return GameState.get_map()
	return null
