class_name JobDriverConstruct
extends JobDriver

## Walk to frame building, then do build work until complete. Awards Construction XP.

var _target_building: Building


func _make_toils() -> Array[Dictionary]:
	_find_target()
	if _target_building == null:
		return []
	if _target_building.needs_materials():
		return []
	return [
		{
			"name": "goto",
			"complete_mode": "never",
		},
		{
			"name": "construct",
			"complete_mode": "never",
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
		"construct":
			_construct_tick()


func _find_target() -> void:
	if not ThingManager:
		return
	for thing: Thing in ThingManager.things:
		if thing.id == job.target_thing_id and thing is Building:
			_target_building = thing as Building
			return


func _start_walk() -> void:
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		end_job(false)
		return
	var target := _find_adjacent_passable(job.target_pos, pf.map)
	pawn.path = pf.find_path(pawn.grid_pos, target)
	pawn.path_index = 0
	if pawn.path.is_empty():
		end_job(false)


func _find_adjacent_passable(pos: Vector2i, map: MapData) -> Vector2i:
	for offset: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		var adj := pos + offset
		if map.in_bounds(adj.x, adj.y):
			var cell := map.get_cell_v(adj)
			if cell and cell.is_passable():
				return adj
	return pos


func _walk_tick() -> void:
	if not pawn.has_path():
		_advance_toil()
		return
	var next := pawn.next_path_step()
	pawn.set_grid_pos(next)


func _construct_tick() -> void:
	if _target_building == null or _target_building.state == Thing.ThingState.DESTROYED:
		end_job(false)
		return
	if _target_building.build_state == Building.BuildState.COMPLETE:
		_award_xp()
		end_job(true)
		return
	if _target_building.needs_materials():
		end_job(false)
		return
	var skill_level: int = pawn.get_skill_level("Construction")
	var work_amount: float = 1.0 + skill_level * 0.15
	var done: bool = _target_building.do_build_work(work_amount)
	if done:
		_award_xp()
		if ColonyLog:
			ColonyLog.add_entry("Build", "%s built %s." % [pawn.pawn_name, _target_building.label], "info")
		end_job(true)


func _award_xp() -> void:
	var base_xp: float = _target_building.build_work_total * 0.5
	pawn.gain_xp("Construction", base_xp)


func _get_map() -> MapData:
	if GameState and GameState.has_method("get_map"):
		return GameState.get_map()
	return null
