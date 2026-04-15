class_name JobDriverSow
extends JobDriver

## Handles both Sow and Harvest jobs for plants.


func _make_toils() -> Array[Dictionary]:
	if job.job_def == "Harvest":
		return _harvest_toils()
	return _sow_toils()


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"goto_spot", "goto_plant":
			_goto_target()
		"finish_sow":
			_do_sow()
		"finish_harvest":
			_do_harvest()


func _on_toil_tick(toil_name: String) -> void:
	if toil_name == "goto_spot" or toil_name == "goto_plant":
		if not pawn.has_path():
			_advance_toil()
			return
		var next := pawn.next_path_step()
		pawn.set_grid_pos(next)
		if not pawn.has_path():
			_advance_toil()


func _sow_toils() -> Array[Dictionary]:
	return [
		{
			"name": "goto_spot",
			"complete_mode": "custom",
		},
		{
			"name": "sow",
			"complete_mode": "delay",
			"delay_ticks": 300,
		},
		{
			"name": "finish_sow",
			"complete_mode": "instant",
		},
	]


func _harvest_toils() -> Array[Dictionary]:
	return [
		{
			"name": "goto_plant",
			"complete_mode": "custom",
		},
		{
			"name": "harvest",
			"complete_mode": "delay",
			"delay_ticks": 200,
		},
		{
			"name": "finish_harvest",
			"complete_mode": "instant",
		},
	]


func _goto_target() -> void:
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		return
	pawn.path = pf.find_path(pawn.grid_pos, job.target_pos)
	pawn.path_index = 0


func _do_sow() -> void:
	if not ThingManager:
		return
	for t: Thing in ThingManager.things:
		if t is Plant and t.grid_pos == job.target_pos:
			return
	var plant := Plant.new("Potato")
	plant.is_sown = true
	plant.spawn_at(job.target_pos)
	ThingManager.spawn_thing(plant, job.target_pos)


func _do_harvest() -> void:
	if not ThingManager:
		return
	for t: Thing in ThingManager.things:
		if t.id == job.target_thing_id and t is Plant:
			var p := t as Plant
			var result := p.harvest()
			if not result.is_empty():
				var pos := t.grid_pos
				ThingManager.remove_thing(t)
				var item := Item.new(result.item, result.count)
				item.spawn_at(pos)
				ThingManager.spawn_thing(item, pos)
			break
