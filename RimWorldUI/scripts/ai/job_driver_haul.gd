class_name JobDriverHaul
extends JobDriver

## Haul item to stockpile with walk ticks, merge on drop, and XP.

var _target_item: Item = null
var _stockpile_pos: Vector2i = Vector2i(-1, -1)
var _carried_def: String = ""
var _carried_count: int = 0


func _make_toils() -> Array[Dictionary]:
	_target_item = _find_item()
	if _target_item == null:
		return []
	_stockpile_pos = _find_stockpile()
	if _stockpile_pos == Vector2i(-1, -1):
		return []

	_target_item.hauled_by = pawn.id

	return [
		{
			"name": "goto_item",
			"complete_mode": "never",
		},
		{
			"name": "pickup",
			"complete_mode": "instant",
		},
		{
			"name": "goto_stockpile",
			"complete_mode": "never",
		},
		{
			"name": "drop",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"goto_item":
			_start_walk_item()
		"pickup":
			_pickup()
		"goto_stockpile":
			_start_walk_stockpile()
		"drop":
			_drop()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"goto_item", "goto_stockpile":
			_walk_tick()


func _find_item() -> Item:
	if not ThingManager:
		return null
	for t: Thing in ThingManager.things:
		if t.id == job.target_thing_id and t is Item:
			return t as Item
	return null


func _find_stockpile() -> Vector2i:
	if ZoneManager:
		var cells: Array[Vector2i] = ZoneManager.get_zone_cells("Stockpile")
		var best_pos := Vector2i(-1, -1)
		var best_dist: int = 999999
		for pos: Vector2i in cells:
			var dist: int = absi(pos.x - pawn.grid_pos.x) + absi(pos.y - pawn.grid_pos.y)
			if dist < best_dist:
				best_dist = dist
				best_pos = pos
		if best_pos != Vector2i(-1, -1):
			return best_pos

	var map: MapData = _get_map()
	if map == null:
		return Vector2i(-1, -1)
	var best_pos := Vector2i(-1, -1)
	var best_dist: int = 999999
	for y: int in map.height:
		for x: int in map.width:
			var cell := map.get_cell(x, y)
			if cell and cell.zone == "Stockpile" and cell.is_passable():
				var dist: int = absi(x - pawn.grid_pos.x) + absi(y - pawn.grid_pos.y)
				if dist < best_dist:
					best_dist = dist
					best_pos = Vector2i(x, y)
	return best_pos


func _start_walk_item() -> void:
	if _target_item == null:
		end_job(false)
		return
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		end_job(false)
		return
	pawn.path = pf.find_path(pawn.grid_pos, _target_item.grid_pos)
	pawn.path_index = 0
	if pawn.path.is_empty():
		_target_item.hauled_by = -1
		end_job(false)


func _walk_tick() -> void:
	if not pawn.has_path():
		_advance_toil()
		return
	var next := pawn.next_path_step()
	pawn.set_grid_pos(next)


func _pickup() -> void:
	if _target_item == null:
		end_job(false)
		return
	_carried_def = _target_item.def_name
	_carried_count = _target_item.stack_count
	ThingManager.remove_thing(_target_item)
	_advance_toil()


func _start_walk_stockpile() -> void:
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		end_job(false)
		return
	pawn.path = pf.find_path(pawn.grid_pos, _stockpile_pos)
	pawn.path_index = 0
	if pawn.path.is_empty():
		end_job(false)


func _drop() -> void:
	if _carried_def.is_empty():
		end_job(false)
		return

	var merged: bool = _try_merge_at_stockpile()
	if not merged:
		var new_item := Item.new(_carried_def, _carried_count)
		new_item.grid_pos = _stockpile_pos
		new_item.hauled_by = -1
		if ThingManager:
			ThingManager.spawn_thing(new_item, _stockpile_pos)

	pawn.gain_xp("Hauling", 15.0)
	end_job(true)


func _try_merge_at_stockpile() -> bool:
	if not ThingManager:
		return false
	for t: Thing in ThingManager.things:
		if t is Item:
			var existing := t as Item
			if existing.grid_pos == _stockpile_pos and existing.def_name == _carried_def:
				var space: int = existing.max_stack - existing.stack_count
				if space >= _carried_count:
					existing.stack_count += _carried_count
					return true
	return false


func _get_map() -> MapData:
	if GameState and GameState.has_method("get_map"):
		return GameState.get_map()
	return null
