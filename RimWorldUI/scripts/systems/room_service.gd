extends Node

var _manager := RoomManager.new()
var _dirty := true
var _last_map: MapData


func _ready() -> void:
	if TickManager:
		TickManager.long_tick.connect(_on_long_tick)
	if ThingManager:
		ThingManager.thing_spawned.connect(_on_thing_changed)
		ThingManager.thing_destroyed.connect(_on_thing_changed)


func _on_thing_changed(_thing: Thing) -> void:
	_dirty = true


func _on_long_tick(_tick: int) -> void:
	if not _dirty:
		return
	_dirty = false
	var map: MapData = GameState.get_map() if GameState else null
	if map == null:
		return
	_last_map = map
	_manager.detect_rooms(map)


func mark_dirty() -> void:
	_dirty = true


func get_rooms() -> Array[Dictionary]:
	return _manager.rooms


func get_room_at(pos: Vector2i) -> Dictionary:
	return _manager.get_room_at(pos)


func get_room_type_at(pos: Vector2i) -> String:
	return _manager.get_room_type_at(pos)


func get_impressiveness_label(imp: float) -> String:
	return _manager.get_impressiveness_label(imp)


func get_room_mood_thought(pos: Vector2i) -> String:
	return _manager.get_room_mood_thought(pos)


func get_stats() -> Dictionary:
	return _manager.get_stats()