class_name JobDriverMine
extends JobDriver

## Drives the Mine job: walk adjacent to mountain, mine it.

const ORE_YIELDS: Dictionary = {
	"Steel": {"item": "Steel", "count_min": 20, "count_max": 40},
	"Gold": {"item": "Gold", "count_min": 8, "count_max": 18},
	"Uranium": {"item": "Uranium", "count_min": 6, "count_max": 14},
	"Jade": {"item": "Jade", "count_min": 5, "count_max": 12},
	"Plasteel": {"item": "Plasteel", "count_min": 10, "count_max": 22},
	"Compacted": {"item": "Steel", "count_min": 15, "count_max": 30},
	"": {"item": "Stone", "count_min": 15, "count_max": 30},
}

var _rng := RandomNumberGenerator.new()


func setup(p: Pawn, j: Job) -> void:
	_rng.seed = randi()
	super.setup(p, j)


func _make_toils() -> Array[Dictionary]:
	var mine_speed: int = _calc_mine_ticks()
	return [
		{
			"name": "walk_adjacent",
			"complete_mode": "never",
		},
		{
			"name": "mining",
			"complete_mode": "delay",
			"delay_ticks": mine_speed,
		},
		{
			"name": "finish_mine",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"walk_adjacent":
			_start_walk()
		"finish_mine":
			_finish_mine()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"walk_adjacent":
			_tick_walk()


func _calc_mine_ticks() -> int:
	var skill: int = pawn.get_skill_level("Mining")
	var speed_mult: float = maxf(0.4, 1.0 - skill * 0.04)
	return roundi(300.0 * speed_mult)


func _start_walk() -> void:
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		end_job(false)
		return
	var adjacent := _find_adjacent_passable(pf.map, job.target_pos)
	if adjacent.x < 0:
		end_job(false)
		return
	pawn.path = pf.find_path(pawn.grid_pos, adjacent)
	pawn.path_index = 0


func _tick_walk() -> void:
	if pawn.has_path():
		var next: Vector2i = pawn.next_path_step()
		pawn.set_grid_pos(next)
	else:
		_advance_toil()


func _finish_mine() -> void:
	var map: MapData = GameState.get_map() if GameState else null
	if map == null:
		return
	var cell := map.get_cell(job.target_pos.x, job.target_pos.y)
	if cell == null:
		return

	var ore_type: String = cell.ore
	var yield_data: Dictionary = ORE_YIELDS.get(ore_type, ORE_YIELDS[""])
	var item_name: String = yield_data.get("item", "Stone") as String
	var count: int = _rng.randi_range(
		yield_data.get("count_min", 10) as int,
		yield_data.get("count_max", 20) as int)

	cell.is_mountain = false
	cell.ore = ""
	cell.terrain_def = "Gravel"
	cell.zone = ""

	if ThingManager:
		var item := Item.new(item_name)
		item.stack_count = count
		item.grid_pos = job.target_pos
		ThingManager.spawn_thing(item, job.target_pos)

	var skill: int = pawn.get_skill_level("Mining")
	var bonus_yield: int = roundi(count * skill * 0.03)
	if bonus_yield > 0:
		if ThingManager:
			var bonus := Item.new(item_name)
			bonus.stack_count = bonus_yield
			bonus.grid_pos = job.target_pos
			ThingManager.spawn_thing(bonus, job.target_pos)

	pawn.gain_xp("Mining", 60.0)

	if ColonyLog:
		var total: int = count + bonus_yield
		ColonyLog.add_entry("Work", "%s mined %d %s." % [pawn.pawn_name, total, item_name], "info")

	end_job(true)


func _find_adjacent_passable(map: MapData, pos: Vector2i) -> Vector2i:
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for d: Vector2i in dirs:
		var check := pos + d
		if map.in_bounds(check.x, check.y):
			var c := map.get_cell(check.x, check.y)
			if c and c.is_passable():
				return check
	return Vector2i(-1, -1)
