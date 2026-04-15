class_name JobDriverWander
extends JobDriver

## Walk to the target cell, then wait briefly.

func _make_toils() -> Array[Dictionary]:
	return [
		{
			"name": "goto",
			"complete_mode": "never",
		},
		{
			"name": "wait",
			"complete_mode": "delay",
			"delay_ticks": 500,
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"goto":
			_start_walk()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"goto":
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
	var dx: int = next.x - pawn.grid_pos.x
	var dy: int = next.y - pawn.grid_pos.y
	if dy < 0: pawn.facing = 0
	elif dx > 0: pawn.facing = 1
	elif dy > 0: pawn.facing = 2
	elif dx < 0: pawn.facing = 3
	pawn.set_grid_pos(next)


func _get_map() -> MapData:
	if GameState and GameState.has_method("get_map"):
		return GameState.get_map()
	return null
