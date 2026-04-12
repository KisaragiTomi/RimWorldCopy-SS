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
	if map == null:
		return {}
	var best_pos := Vector2i(-1, -1)
	var best_dist: float = INF
	for y: int in map.height:
		for x: int in map.width:
			var cell := map.get_cell(x, y)
			if cell == null or cell.zone != "GrowingZone":
				continue
			if not cell.is_passable():
				continue
			if ThingManager and _has_plant_at(Vector2i(x, y)):
				continue
			var d := pawn.grid_pos.distance_to(Vector2i(x, y)) as float
			if d < best_dist:
				best_dist = d
				best_pos = Vector2i(x, y)
	if best_pos == Vector2i(-1, -1):
		return {}
	var j := Job.new("Sow", best_pos)
	return {"job": j, "source": self}


func _has_plant_at(pos: Vector2i) -> bool:
	for t: Thing in ThingManager.things:
		if t is Plant and t.grid_pos == pos:
			return true
	return false
