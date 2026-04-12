class_name JobDriverFirefight
extends JobDriver

## Drives the Firefight job: run to fire, put it out, chain to adjacent fires.

var _fires_put_out: int = 0
const MAX_CHAIN := 3


func _make_toils() -> Array[Dictionary]:
	return [
		{
			"name": "run_to_fire",
			"complete_mode": "never",
		},
		{
			"name": "extinguish",
			"complete_mode": "delay",
			"delay_ticks": 80,
		},
		{
			"name": "done",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"run_to_fire":
			_start_run()
		"done":
			_finish_extinguish()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"run_to_fire":
			_tick_run()


func _start_run() -> void:
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		end_job(false)
		return
	var adjacent := _find_adjacent(pf.map, job.target_pos)
	if adjacent.x < 0:
		end_job(false)
		return
	pawn.path = pf.find_path(pawn.grid_pos, adjacent)
	pawn.path_index = 0


func _tick_run() -> void:
	if pawn.has_path():
		var next: Vector2i = pawn.next_path_step()
		pawn.set_grid_pos(next)
	else:
		_advance_toil()


func _finish_extinguish() -> void:
	if FireManager:
		FireManager.extinguish(job.target_pos)
	_fires_put_out += 1
	pawn.gain_xp("Firefighting", 30.0)

	var chain_target := _find_adjacent_fire()
	if chain_target.x >= 0 and _fires_put_out < MAX_CHAIN:
		job.target_pos = chain_target
		_toil_index = -1
		_toil_ticks = 0
		_advance_toil()
		return

	if ColonyLog:
		if _fires_put_out > 1:
			ColonyLog.add_entry("Work", "%s extinguished %d fires." % [pawn.pawn_name, _fires_put_out], "positive")
		else:
			ColonyLog.add_entry("Work", pawn.pawn_name + " extinguished a fire.", "positive")
	end_job(true)


func _find_adjacent_fire() -> Vector2i:
	if not FireManager:
		return Vector2i(-1, -1)
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
	for d: Vector2i in dirs:
		var check := job.target_pos + d
		if FireManager.fires.has(check):
			return check
	return Vector2i(-1, -1)


func _find_adjacent(map: MapData, pos: Vector2i) -> Vector2i:
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for d: Vector2i in dirs:
		var check := pos + d
		if map.in_bounds(check.x, check.y):
			var c := map.get_cell(check.x, check.y)
			if c and c.is_passable():
				return check
	return Vector2i(-1, -1)
