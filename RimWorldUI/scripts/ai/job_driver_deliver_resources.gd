class_name JobDriverDeliverResources
extends JobDriver

## Finds a required resource item on the map, picks it up, walks to the
## blueprint building, and delivers materials. Awards Construction XP.

var _target_building: Building
var _source_item: Item
var _material_name: String = ""
var _deliver_amount: int = 0


func _make_toils() -> Array[Dictionary]:
	_find_target_building()
	if _target_building == null or not _target_building.needs_materials():
		return []
	if not _find_source_item():
		return []
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
			"name": "goto_blueprint",
			"complete_mode": "never",
		},
		{
			"name": "deliver",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"goto_item":
			_start_walk_to_item()
		"pickup":
			_pickup_item()
		"goto_blueprint":
			_start_walk_to_blueprint()
		"deliver":
			_deliver_material()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"goto_item", "goto_blueprint":
			_walk_tick()


func _find_target_building() -> void:
	if not ThingManager:
		return
	for thing: Thing in ThingManager.things:
		if thing.id == job.target_thing_id and thing is Building:
			_target_building = thing as Building
			return


func _find_source_item() -> bool:
	if not ThingManager or _target_building == null:
		return false
	var missing: Dictionary = _target_building.get_missing_materials()
	if missing.is_empty():
		return false

	var best_item: Item = null
	var best_dist: int = 9999
	var best_mat: String = ""

	for thing: Thing in ThingManager.things:
		if not (thing is Item):
			continue
		var item: Item = thing as Item
		if item.forbidden or item.hauled_by >= 0:
			continue
		if item.state != Thing.ThingState.SPAWNED:
			continue
		if not missing.has(item.def_name):
			continue
		var dist: int = absi(item.grid_pos.x - pawn.grid_pos.x) + absi(item.grid_pos.y - pawn.grid_pos.y)
		if dist < best_dist:
			best_dist = dist
			best_item = item
			best_mat = item.def_name

	if best_item == null:
		return false

	_source_item = best_item
	_material_name = best_mat
	_deliver_amount = mini(best_item.stack_count, missing[best_mat])
	_source_item.hauled_by = pawn.id
	return true


func _start_walk_to_item() -> void:
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		end_job(false)
		return
	pawn.path = pf.find_path(pawn.grid_pos, _source_item.grid_pos)
	pawn.path_index = 0
	if pawn.path.is_empty():
		end_job(false)


func _walk_tick() -> void:
	if not pawn.has_path():
		_advance_toil()
		return
	var next := pawn.next_path_step()
	pawn.set_grid_pos(next)


func _pickup_item() -> void:
	if _source_item == null or _source_item.state == Thing.ThingState.DESTROYED:
		end_job(false)
		return
	if _deliver_amount >= _source_item.stack_count:
		ThingManager.remove_thing(_source_item)
	else:
		_source_item.stack_count -= _deliver_amount
	_source_item.hauled_by = -1
	_advance_toil()


func _start_walk_to_blueprint() -> void:
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		end_job(false)
		return
	var target := _find_adjacent_passable(_target_building.grid_pos, pf.map)
	pawn.path = pf.find_path(pawn.grid_pos, target)
	pawn.path_index = 0
	if pawn.path.is_empty():
		end_job(false)


func _find_adjacent_passable(pos: Vector2i, map: MapData) -> Vector2i:
	for offset: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		var adj := pos + offset
		if map.in_bounds(adj.x, adj.y):
			var cell := map.get_cell_v(adj)
			if cell and cell.is_passable():
				return adj
	return pos


func _deliver_material() -> void:
	if _target_building == null or _target_building.state == Thing.ThingState.DESTROYED:
		end_job(false)
		return
	var used: int = _target_building.deliver_material(_material_name, _deliver_amount)
	if used > 0:
		pawn.gain_xp("Construction", float(used) * 5.0)
		if ColonyLog:
			ColonyLog.add_entry("Build", "%s delivered %d %s to %s." % [
				pawn.pawn_name, used, _material_name, _target_building.label
			], "info")
	end_job(true)


func _get_map() -> MapData:
	if GameState and GameState.has_method("get_map"):
		return GameState.get_map()
	return null
