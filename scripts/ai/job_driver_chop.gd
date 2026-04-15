class_name JobDriverChop
extends JobDriver

## Drives the Chop job: walk to plant, cut it down, yield wood.
## Skill speeds up chopping; chains up to 2 nearby designated plants.

var _plants_chopped: int = 0
var _total_wood: int = 0
const MAX_CHAIN: int = 2
const BASE_TICKS: int = 120
const CHOP_XP: float = 25.0


func _make_toils() -> Array[Dictionary]:
	var ticks := _calc_chop_ticks()
	return [
		{
			"name": "walk_to_plant",
			"complete_mode": "never",
		},
		{
			"name": "chopping",
			"complete_mode": "delay",
			"delay_ticks": ticks,
		},
		{
			"name": "done",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"walk_to_plant":
			_start_walk()
		"done":
			_finish_chop()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"walk_to_plant":
			_tick_walk()


func _calc_chop_ticks() -> int:
	var skill: int = pawn.get_skill("Plants") if pawn else 0
	var factor: float = clampf(1.0 - skill * 0.04, 0.4, 1.0)
	return roundi(BASE_TICKS * factor)


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


func _finish_chop() -> void:
	if not ThingManager:
		return
	for t: Thing in ThingManager.things:
		if t is Plant and t.grid_pos == job.target_pos:
			var plant := t as Plant
			var skill: int = pawn.get_skill("Plants") if pawn else 0
			var bonus: float = 1.0 + skill * 0.03
			var yield_wood: int = roundi(plant.growth * 25.0 * bonus)
			if yield_wood > 0:
				var wood := Item.new("Wood")
				wood.grid_pos = job.target_pos
				wood.stack_count = yield_wood
				ThingManager.add_thing(wood)
			ThingManager.destroy_thing(t)
			pawn.gain_xp("Plants", CHOP_XP)
			_plants_chopped += 1
			_total_wood += yield_wood
			break

	if _plants_chopped < MAX_CHAIN:
		var next := _find_nearby_designated(8)
		if next != Vector2i(-1, -1):
			job.target_pos = next
			_toil_index = -1
			_toil_ticks = 0
			_advance_toil()
			return

	if ColonyLog:
		ColonyLog.add_entry("Work", "%s chopped %d plants (+%d wood)." % [pawn.pawn_name, _plants_chopped, _total_wood], "info")


func _find_nearby_designated(max_dist: int) -> Vector2i:
	if not ThingManager:
		return Vector2i(-1, -1)
	var best := Vector2i(-1, -1)
	var best_dist: int = 999
	for t: Thing in ThingManager.things:
		if not (t is Plant):
			continue
		if not (t as Plant).designated_cut:
			continue
		var dist: int = absi(t.grid_pos.x - pawn.grid_pos.x) + absi(t.grid_pos.y - pawn.grid_pos.y)
		if dist <= max_dist and dist < best_dist:
			best_dist = dist
			best = t.grid_pos
	return best
