class_name JobGiverSow
extends ThinkNode

## Issues sow/harvest jobs for plants in growing zones.

func try_issue_job(pawn: Pawn) -> Dictionary:
	if not pawn.is_capable_of("Growing"):
		return {}
	if pawn.drafted:
		return {}

	var harvest_job := _find_harvest(pawn)
	if not harvest_job.is_empty():
		return harvest_job

	if SeasonManager and not SeasonManager.is_growing_season():
		return {}

	var sow_job := _find_sow_spot(pawn)
	return sow_job


func _find_harvest(pawn: Pawn) -> Dictionary:
	if not ThingManager:
		return {}
	var best: Thing = null
	var best_dist: float = INF
	for t: Thing in ThingManager.things:
		if not (t is Plant):
			continue
		var p := t as Plant
		if p.growth_stage != Plant.GrowthStage.HARVESTABLE:
			continue
		var d := pawn.grid_pos.distance_to(p.grid_pos) as float
		if d < best_dist:
			best_dist = d
			best = t
	if best == null:
		return {}
	var j := Job.new("Harvest", best.grid_pos)
	j.target_thing_id = best.id
	return {"job": j, "source": self}


func _find_sow_spot(pawn: Pawn) -> Dictionary:
	var map: MapData = GameState.get_map() if GameState else null
	if map == null or not ZoneManager or not ZoneManager.zones:
		return {}
	var reserved := _get_reserved_sow_positions()
	var best_pos := Vector2i(-1, -1)
	var best_dist: float = INF
	for pos: Vector2i in ZoneManager.zones:
		if ZoneManager.zones[pos] != "GrowingZone":
			continue
		var cell := map.get_cell(pos.x, pos.y)
		if cell == null or not cell.is_passable():
			continue
		if ThingManager and _has_plant_at(pos):
			continue
		if reserved.has(pos):
			continue
		var d := pawn.grid_pos.distance_to(pos) as float
		if d < best_dist:
			best_dist = d
			best_pos = pos
	if best_pos == Vector2i(-1, -1):
		return {}
	var j := Job.new("Sow", best_pos)
	return {"job": j, "source": self}


func _get_reserved_sow_positions() -> Dictionary:
	var reserved := {}
	if not PawnManager:
		return reserved
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed:
			continue
		if p.current_job_name == "Sow":
			var driver = p.get_meta("job_driver") if p.has_meta("job_driver") else null
			if driver and driver.job:
				reserved[driver.job.target_pos] = true
	return reserved


var _plant_cache: Dictionary = {}
var _cache_tick: int = -1

func _has_plant_at(pos: Vector2i) -> bool:
	var cur_tick: int = TickManager.current_tick if TickManager else 0
	if _cache_tick != cur_tick:
		_plant_cache.clear()
		for t: Thing in ThingManager.things:
			if t is Plant:
				_plant_cache[t.grid_pos] = true
		_cache_tick = cur_tick
	return _plant_cache.has(pos)
