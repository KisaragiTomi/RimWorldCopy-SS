class_name JobDriverSow
extends JobDriver

## Handles both Sow and Harvest jobs for plants.

var _carried_def: String = ""
var _carried_count: int = 0
var _stockpile_pos: Vector2i = Vector2i(-1, -1)


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
		"goto_stockpile":
			_start_walk_stockpile()
		"drop_harvest":
			_drop_at_stockpile()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"goto_spot", "goto_plant", "goto_stockpile":
			if not pawn.has_path():
				_advance_toil()
				return
			var next := pawn.next_path_step()
			pawn.set_grid_pos(next)
			if not pawn.has_path():
				_advance_toil()


func _sow_toils() -> Array[Dictionary]:
	return [
		{"name": "goto_spot", "complete_mode": "custom"},
		{"name": "sow", "complete_mode": "delay", "delay_ticks": 300},
		{"name": "finish_sow", "complete_mode": "instant"},
	]


func _harvest_toils() -> Array[Dictionary]:
	var toils: Array[Dictionary] = [
		{"name": "goto_plant", "complete_mode": "custom"},
		{"name": "harvest", "complete_mode": "delay", "delay_ticks": 200},
		{"name": "finish_harvest", "complete_mode": "instant"},
	]
	if _has_stockpile():
		toils.append({"name": "goto_stockpile", "complete_mode": "custom"})
		toils.append({"name": "drop_harvest", "complete_mode": "instant"})
	return toils


func _goto_target() -> void:
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		return
	pawn.path = pf.find_path(pawn.grid_pos, job.target_pos)
	pawn.path_index = 0


func _do_sow() -> void:
	if not ThingManager:
		return
	for t: Thing in ThingManager.get_plants():
		if t.grid_pos == job.target_pos:
			return
	var plant := Plant.new("Potato")
	plant.is_sown = true
	plant.spawn_at(job.target_pos)
	ThingManager.spawn_thing(plant, job.target_pos)


func _do_harvest() -> void:
	if not ThingManager:
		return
	for t: Thing in ThingManager.get_plants():
		if t.id == job.target_thing_id:
			var p := t as Plant
			var result := p.harvest()
			if not result.is_empty():
				ThingManager.remove_thing(t)
				_carried_def = result.item
				_carried_count = result.count
				if not _has_stockpile():
					var item := Item.new(_carried_def, _carried_count)
					item.spawn_at(pawn.grid_pos)
					ThingManager.spawn_thing(item, pawn.grid_pos)
					_carried_def = ""
			break


func _has_stockpile() -> bool:
	if ZoneManager:
		return not ZoneManager.get_zone_cells("Stockpile").is_empty()
	return false


func _start_walk_stockpile() -> void:
	if _carried_def.is_empty():
		end_job(true)
		return
	_stockpile_pos = _find_nearest_stockpile()
	if _stockpile_pos == Vector2i(-1, -1):
		var item := Item.new(_carried_def, _carried_count)
		item.spawn_at(pawn.grid_pos)
		ThingManager.spawn_thing(item, pawn.grid_pos)
		_carried_def = ""
		end_job(true)
		return
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		end_job(false)
		return
	pawn.path = pf.find_path(pawn.grid_pos, _stockpile_pos)
	pawn.path_index = 0
	if pawn.path.is_empty():
		end_job(false)


func _drop_at_stockpile() -> void:
	if _carried_def.is_empty():
		end_job(true)
		return
	if not _try_merge_at_pos(_stockpile_pos):
		var item := Item.new(_carried_def, _carried_count)
		item.grid_pos = _stockpile_pos
		if ThingManager:
			ThingManager.spawn_thing(item, _stockpile_pos)
	_carried_def = ""
	pawn.gain_xp("Plants", 20.0)
	end_job(true)


func _find_nearest_stockpile() -> Vector2i:
	if not ZoneManager:
		return Vector2i(-1, -1)
	var cells: Array[Vector2i] = ZoneManager.get_zone_cells("Stockpile")
	var best := Vector2i(-1, -1)
	var best_dist: int = 999999
	for pos: Vector2i in cells:
		var dist: int = absi(pos.x - pawn.grid_pos.x) + absi(pos.y - pawn.grid_pos.y)
		if dist < best_dist:
			best_dist = dist
			best = pos
	return best


func _try_merge_at_pos(pos: Vector2i) -> bool:
	if not ThingManager:
		return false
	for t: Thing in ThingManager.things:
		if t is Item:
			var existing := t as Item
			if existing.grid_pos == pos and existing.def_name == _carried_def:
				var space: int = existing.max_stack - existing.stack_count
				if space >= _carried_count:
					existing.stack_count += _carried_count
					return true
	return false
