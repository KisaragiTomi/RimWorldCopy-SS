class_name JobDriverCraft
extends JobDriver

## Walk to bench, consume materials, craft item with quality.

var _recipe_name: String = ""


func setup(p: Pawn, j: Job) -> void:
	_recipe_name = j.meta_data.get("recipe", "") as String
	super.setup(p, j)


func _make_toils() -> Array[Dictionary]:
	var recipe: Dictionary = CraftingManager.RECIPES.get(_recipe_name, {}) if CraftingManager else {}
	var work_ticks: int = recipe.get("work_ticks", 300) as int
	return [
		{
			"name": "goto_bench",
			"complete_mode": "never",
		},
		{
			"name": "consume_materials",
			"complete_mode": "instant",
		},
		{
			"name": "crafting",
			"complete_mode": "delay",
			"delay_ticks": work_ticks,
		},
		{
			"name": "finish_craft",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"goto_bench":
			_start_walk()
		"consume_materials":
			_consume_materials()
		"finish_craft":
			_finish_craft()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"goto_bench":
			_walk_tick()


func _start_walk() -> void:
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		_unassign_queue_entry()
		end_job(false)
		return
	pawn.path = pf.find_path(pawn.grid_pos, job.target_pos)
	pawn.path_index = 0
	if pawn.path.is_empty():
		_unassign_queue_entry()
		end_job(false)


func _walk_tick() -> void:
	if not pawn.has_path():
		_advance_toil()
		return
	var next := pawn.next_path_step()
	pawn.set_grid_pos(next)


func _consume_materials() -> void:
	if not CraftingManager or not CraftingManager.consume_ingredients(_recipe_name):
		_unassign_queue_entry()
		end_job(false)
		return
	_advance_toil()


func _finish_craft() -> void:
	if not CraftingManager:
		_unassign_queue_entry()
		end_job(false)
		return
	var result: Dictionary = CraftingManager.complete_craft(_recipe_name, pawn)
	if result.is_empty():
		_unassign_queue_entry()
		end_job(false)
		return

	if ThingManager:
		ThingManager.spawn_item_stacks(result.get("item", "Unknown"), result.get("count", 1), pawn.grid_pos)

	end_job(true)


func end_job(success: bool) -> void:
	if not success:
		_unassign_queue_entry()
	super.end_job(success)


func _unassign_queue_entry() -> void:
	if not CraftingManager:
		return
	for entry: Dictionary in CraftingManager.craft_queue:
		if entry.get("recipe", "") == _recipe_name and entry.get("assigned", false):
			entry["assigned"] = false
			break


func _get_map() -> MapData:
	if GameState and GameState.has_method("get_map"):
		return GameState.get_map()
	return null
