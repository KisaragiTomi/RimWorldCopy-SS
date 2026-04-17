class_name JobDriverRepair
extends JobDriver

## Drives the Repair job: walk to building, repair it over time.


func _make_toils() -> Array[Dictionary]:
	return [
		{
			"name": "walk_to_building",
			"complete_mode": "never",
		},
		{
			"name": "repairing",
			"complete_mode": "delay",
			"delay_ticks": 200,
		},
		{
			"name": "done",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"walk_to_building":
			_start_walk()
		"done":
			_finish()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"walk_to_building":
			_tick_walk()
		"repairing":
			_tick_repair()


func _start_walk() -> void:
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		end_job(false)
		return
	var target := _adjacent_pos(job.target_pos, pf.map)
	pawn.path = pf.find_path(pawn.grid_pos, target)
	pawn.path_index = 0


func _tick_walk() -> void:
	if pawn.has_path():
		pawn.set_grid_pos(pawn.next_path_step())
	else:
		_advance_toil()


func _tick_repair() -> void:
	if not ThingManager:
		return
	for t: Thing in ThingManager.things:
		if t is Building and t.grid_pos == job.target_pos:
			var b := t as Building
			var skill_level: int = pawn.skills.get("Construction", {}).get("level", 0)
			var repair_amount: int = 2 + skill_level
			b.hit_points = mini(b.max_hit_points, b.hit_points + repair_amount)
			if b.hit_points >= b.max_hit_points:
				_advance_toil()
			return


func _finish() -> void:
	var skill: int = pawn.get_skill_level("Construction") if pawn else 0
	var xp: float = 25.0 + skill * 1.5
	pawn.gain_xp("Construction", xp)
	if ColonyLog:
		ColonyLog.add_entry("Work", "%s repaired building at (%d,%d)." % [pawn.pawn_name, job.target_pos.x, job.target_pos.y], "info")


func _adjacent_pos(pos: Vector2i, map: MapData) -> Vector2i:
	var dirs: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	for d: Vector2i in dirs:
		var p := pos + d
		if map.in_bounds(p.x, p.y):
			var cell := map.get_cell(p.x, p.y)
			if cell and cell.is_passable():
				return p
	return pos
