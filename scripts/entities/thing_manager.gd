extends Node

## Manages all things (buildings, items, plants) on the map.
## Registered as autoload "ThingManager".

signal thing_spawned(thing: Thing)
signal thing_destroyed(thing: Thing)

var things: Array[Thing] = []
var _grid: Dictionary = {}  # "x,y" -> Array[Thing]


func spawn_thing(thing: Thing, pos: Vector2i) -> void:
	thing.spawn_at(pos)
	things.append(thing)
	var key := _key(pos)
	if not _grid.has(key):
		_grid[key] = []
	_grid[key].append(thing)
	thing_spawned.emit(thing)


func remove_thing(thing: Thing) -> void:
	thing.destroy()
	things.erase(thing)
	var key := _key(thing.grid_pos)
	if _grid.has(key):
		_grid[key].erase(thing)
	thing_destroyed.emit(thing)


func destroy_thing(thing: Thing) -> void:
	remove_thing(thing)


func get_things_at(pos: Vector2i) -> Array:
	return _grid.get(_key(pos), [])


func get_building_at(pos: Vector2i) -> Building:
	for t: Thing in get_things_at(pos):
		if t is Building:
			return t as Building
	return null


func has_building_at(pos: Vector2i) -> bool:
	return get_building_at(pos) != null


func place_blueprint(def_name: String, pos: Vector2i) -> Building:
	if has_building_at(pos):
		return null
	var map: MapData = GameState.get_map() if GameState else null
	if map:
		var cell := map.get_cell_v(pos)
		if cell == null or cell.is_mountain:
			return null
	var b := Building.new(def_name)
	b.place_blueprint()
	spawn_thing(b, pos)
	if ColonyLog:
		ColonyLog.add_entry("Build", "Blueprint placed: %s at (%d,%d)." % [b.label, pos.x, pos.y], "info")
	return b


func cancel_blueprint(pos: Vector2i) -> void:
	var b := get_building_at(pos)
	if b == null or b.build_state == Building.BuildState.COMPLETE:
		return
	var refund: Dictionary = b.get_refund_materials()
	for mat: String in refund:
		var item := Item.new(mat, refund[mat])
		spawn_thing(item, pos)
	remove_thing(b)


func get_blueprints() -> Array[Building]:
	var arr: Array[Building] = []
	for t: Thing in things:
		if t is Building:
			var b: Building = t as Building
			if b.build_state != Building.BuildState.COMPLETE:
				arr.append(b)
	return arr


func get_buildings() -> Array[Building]:
	var arr: Array[Building] = []
	for t: Thing in things:
		if t is Building:
			var b: Building = t as Building
			if b.build_state == Building.BuildState.COMPLETE:
				arr.append(b)
	return arr


func get_items_of_type(item_def: String) -> Array[Item]:
	var arr: Array[Item] = []
	for t: Thing in things:
		if t is Item:
			var item: Item = t as Item
			if item.def_name == item_def and item.state == Thing.ThingState.SPAWNED:
				arr.append(item)
	return arr


func count_items(item_def: String) -> int:
	var total: int = 0
	for t: Thing in things:
		if t is Item:
			var item: Item = t as Item
			if item.def_name == item_def and item.state == Thing.ThingState.SPAWNED:
				total += item.stack_count
	return total


func _key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]
