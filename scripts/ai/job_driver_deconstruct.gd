class_name JobDriverDeconstruct
extends JobDriver

## Drives the Deconstruct job: walk to building, tear it down, yield resources.

const DECONSTRUCT_YIELDS: Dictionary = {
	"Wall": {"Steel": 3, "Wood": 5},
	"Door": {"Wood": 5},
	"Bed": {"Wood": 8},
	"DoubleBed": {"Wood": 12},
	"Table": {"Wood": 6},
	"DiningChair": {"Wood": 3},
	"Campfire": {"Wood": 3},
	"WoodFiredGenerator": {"Steel": 8, "ComponentIndustrial": 1},
	"SolarGenerator": {"Steel": 12, "ComponentIndustrial": 2},
	"Battery": {"Steel": 6, "ComponentIndustrial": 1},
	"MiniTurret": {"Steel": 15, "ComponentIndustrial": 2},
	"Shelf": {"Wood": 5},
	"StandingLamp": {"Steel": 2},
}


func _make_toils() -> Array[Dictionary]:
	return [
		{
			"name": "walk_to_building",
			"complete_mode": "never",
		},
		{
			"name": "deconstructing",
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
			_finish_deconstruct()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"walk_to_building":
			_tick_walk()


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


func _finish_deconstruct() -> void:
	if not ThingManager:
		return

	for t: Thing in ThingManager.things:
		if t is Building and t.grid_pos == job.target_pos:
			var b := t as Building
			var yields: Dictionary = DECONSTRUCT_YIELDS.get(b.def_name, {"Wood": 3})

			ThingManager.destroy_thing(t)

			var offset: int = 0
			for item_def: String in yields:
				var count: int = yields[item_def]
				ThingManager.spawn_item_stacks(item_def, count, job.target_pos + Vector2i(offset, 0))
				offset += 1

			var skill: int = pawn.get_skill_level("Construction") if pawn else 0
			pawn.gain_xp("Construction", 20.0 + skill * 1.0)

			var yield_str: String = ", ".join(yields.keys().map(func(k: String) -> String: return str(yields[k]) + " " + k))
			if ColonyLog:
				ColonyLog.add_entry("Work", "%s deconstructed %s → %s." % [pawn.pawn_name, b.def_name, yield_str], "info")
			break


func _adjacent_pos(pos: Vector2i, map: MapData) -> Vector2i:
	var dirs: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	for d: Vector2i in dirs:
		var p := pos + d
		if map.in_bounds(p.x, p.y):
			var cell := map.get_cell(p.x, p.y)
			if cell and cell.is_passable():
				return p
	return pos
