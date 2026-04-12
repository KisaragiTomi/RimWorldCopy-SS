class_name Thing
extends RefCounted

## Base class for all world objects: buildings, items, plants, etc.

enum ThingState { UNSPAWNED, SPAWNED, DESTROYED }

var id: int = 0
var def_name: String = ""
var label: String = ""
var grid_pos: Vector2i = Vector2i.ZERO
var rotation: int = 0  # 0=N, 1=E, 2=S, 3=W
var hit_points: int = 100
var max_hit_points: int = 100
var state: ThingState = ThingState.UNSPAWNED

static var _next_id: int = 1


func _init(def: String = "") -> void:
	id = _next_id
	_next_id += 1
	def_name = def
	label = def


func spawn_at(pos: Vector2i) -> void:
	grid_pos = pos
	state = ThingState.SPAWNED


func destroy() -> void:
	state = ThingState.DESTROYED


func take_damage(amount: int) -> void:
	hit_points = maxi(0, hit_points - amount)
	if hit_points <= 0:
		destroy()


func get_color() -> Color:
	return Color(0.6, 0.6, 0.6)


func to_dict() -> Dictionary:
	return {
		"id": id, "def": def_name, "label": label,
		"x": grid_pos.x, "y": grid_pos.y,
		"rotation": rotation,
		"hp": hit_points, "max_hp": max_hit_points,
	}
