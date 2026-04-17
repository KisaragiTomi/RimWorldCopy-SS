extends Node

## Round-robin logger: every 10 frames, record one colonist + their cell.
## Auto-saves to res://logs/game_raw_data.json when buffer is full.

var _frame_counter: int = 0
var _pawn_index: int = 0
var _last_save_size: int = 0

func _process(_delta: float) -> void:
	_frame_counter += 1
	if _frame_counter % 10 != 0:
		return
	var alive: Array = []
	for p: Variant in PawnManager.pawns:
		if not p.dead:
			alive.append(p)
	if alive.is_empty():
		return
	_pawn_index = _pawn_index % alive.size()
	var p: Variant = alive[_pawn_index]
	_pawn_index += 1

	var pi: Dictionary = {
		"name": p.pawn_name,
		"pos": [p.grid_pos.x, p.grid_pos.y],
		"job": p.current_job_name,
		"food": p.get_need("Food"),
		"rest": p.get_need("Rest"),
		"mood": p.get_need("Mood"),
		"drafted": p.drafted,
		"downed": p.downed,
		"gear": p.equipment.slots if p.equipment else {},
	}
	if GameState.active_map:
		var cell: Variant = GameState.active_map.get_cell_v(p.grid_pos)
		if cell:
			pi["cell"] = {
				"terrain": cell.terrain_def,
				"roof": cell.roof,
				"building": cell.building,
				"zone": str(cell.zone) if cell.zone else null,
			}

	var entry: Dictionary = {
		"tick": TickManager.current_tick,
		"frame": _frame_counter,
		"pawn": pi,
	}
	var log: Array = get_meta("log")
	var max_entries: int = get_meta("max_entries")
	if log.size() >= max_entries:
		log.pop_front()
	log.append(entry)

	if log.size() >= max_entries and _last_save_size < max_entries:
		_save_to_disk(log)
	_last_save_size = log.size()


func _save_to_disk(log: Array) -> void:
	var save_name: String = get_meta("save_name", "game_raw_data")
	var dir: String = ProjectSettings.globalize_path("res://logs")
	DirAccess.make_dir_absolute(dir)
	var path: String = dir + "/" + save_name + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(log))
		file.close()
		print("DataLogger: saved %d entries to %s" % [log.size(), path])
