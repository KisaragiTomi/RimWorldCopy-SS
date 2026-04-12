class_name JobDriverClean
extends JobDriver

## Drives the Clean job: walk to filth, clean it. Chains up to 3 nearby spots.

var _spots_cleaned: int = 0
const MAX_CHAIN: int = 3
const CLEAN_XP: float = 15.0


func _make_toils() -> Array[Dictionary]:
	return [
		{
			"name": "walk_to_filth",
			"complete_mode": "never",
		},
		{
			"name": "cleaning",
			"complete_mode": "delay",
			"delay_ticks": 60,
		},
		{
			"name": "done",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"walk_to_filth":
			_start_walk()
		"done":
			_finish_clean()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"walk_to_filth":
			_tick_walk()


func _start_walk() -> void:
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		end_job(false)
		return
	pawn.path = pf.find_path(pawn.grid_pos, job.target_pos)
	pawn.path_index = 0


func _tick_walk() -> void:
	if pawn.has_path():
		pawn.set_grid_pos(pawn.next_path_step())
	else:
		_advance_toil()


func _finish_clean() -> void:
	if FilthManager:
		FilthManager.clean(job.target_pos)
	_spots_cleaned += 1
	pawn.gain_xp("Cleaning", CLEAN_XP)

	if _spots_cleaned < MAX_CHAIN and FilthManager:
		var next := FilthManager.get_nearest_filth(pawn.grid_pos, 8)
		if next.x >= 0:
			job.target_pos = next
			_toil_index = -1
			_toil_ticks = 0
			_advance_toil()
			return

	if ColonyLog and _spots_cleaned > 1:
		ColonyLog.add_entry("Cleaning", "%s cleaned %d spots." % [pawn.pawn_name, _spots_cleaned], "info")
