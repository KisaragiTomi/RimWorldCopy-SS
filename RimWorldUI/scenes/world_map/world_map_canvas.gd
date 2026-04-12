extends Control

signal tile_clicked(tile_pos: Vector2i, tile_data: Dictionary)

const CELL_SIZE := 10.0
const MAP_W := 150
const MAP_H := 80

var _noise: FastNoiseLite
var _offset := Vector2.ZERO
var _dragging := false
var _drag_start := Vector2.ZERO
var _selected_tile := Vector2i(-1, -1)


func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 0.02
	_noise.seed = 42
	clip_contents = true


func _draw() -> void:
	var view_rect: Rect2 = get_rect()
	var world: WorldGrid = _get_world()
	var w: int = world.width if world else MAP_W
	var h: int = world.height if world else MAP_H

	var start_x: int = maxi(0, int(-_offset.x / CELL_SIZE))
	var start_y: int = maxi(0, int(-_offset.y / CELL_SIZE))
	var end_x: int = mini(w, int((-_offset.x + view_rect.size.x) / CELL_SIZE) + 1)
	var end_y: int = mini(h, int((-_offset.y + view_rect.size.y) / CELL_SIZE) + 1)

	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			var color: Color
			if world:
				var tile: Dictionary = world.get_tile(x, y)
				var biome: String = tile.get("biome", "Ocean")
				var bc: Array = world.get_biome_color(biome)
				color = Color(bc[0], bc[1], bc[2])
				var settlement: String = tile.get("settlement", "")
				if not settlement.is_empty():
					color = color.lightened(0.3)
			else:
				var val: float = (_noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
				color = _get_biome_color(val, y)

			var rect: Rect2 = Rect2(
				Vector2(x * CELL_SIZE + _offset.x, y * CELL_SIZE + _offset.y),
				Vector2(CELL_SIZE, CELL_SIZE)
			)
			draw_rect(rect, color)

	if _selected_tile.x >= 0:
		var sel_rect := Rect2(
			Vector2(_selected_tile.x * CELL_SIZE + _offset.x, _selected_tile.y * CELL_SIZE + _offset.y),
			Vector2(CELL_SIZE, CELL_SIZE)
		)
		draw_rect(sel_rect, Color.WHITE, false, 2.0)

	if WorldManager and WorldManager.player_home.x >= 0:
		var home := WorldManager.player_home
		var home_rect := Rect2(
			Vector2(home.x * CELL_SIZE + _offset.x - 2, home.y * CELL_SIZE + _offset.y - 2),
			Vector2(CELL_SIZE + 4, CELL_SIZE + 4)
		)
		draw_rect(home_rect, Color(0.2, 0.7, 1.0), false, 2.0)


func _get_biome_color(val: float, y: int) -> Color:
	var lat: float = absf(float(y) / MAP_H - 0.5) * 2.0
	if val < 0.35:
		return Color(0.15, 0.3, 0.55, 1.0).lerp(Color(0.2, 0.35, 0.6), val)
	elif val < 0.42:
		return Color(0.76, 0.7, 0.5, 1.0)
	elif lat > 0.85:
		return Color(0.9, 0.92, 0.95, 1.0)
	elif lat > 0.65:
		return Color(0.55, 0.6, 0.5, 1.0).lerp(Color(0.85, 0.87, 0.9), lat - 0.65)
	elif val < 0.55:
		return Color(0.35, 0.55, 0.25, 1.0)
	elif val < 0.7:
		return Color(0.25, 0.5, 0.2, 1.0)
	elif val < 0.85:
		return Color(0.5, 0.45, 0.35, 1.0)
	else:
		return Color(0.6, 0.58, 0.55, 1.0)


func _get_world() -> WorldGrid:
	if WorldManager and WorldManager.world:
		return WorldManager.world
	return null


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_drag_start = event.position
			else:
				if _dragging and _drag_start.distance_to(event.position) < 5.0:
					_handle_click(event.position)
				_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		_offset += event.relative
		queue_redraw()


func _handle_click(pos: Vector2) -> void:
	var tx: int = int((pos.x - _offset.x) / CELL_SIZE)
	var ty: int = int((pos.y - _offset.y) / CELL_SIZE)
	_selected_tile = Vector2i(tx, ty)
	queue_redraw()

	var tile_data: Dictionary = {}
	var world := _get_world()
	if world:
		tile_data = world.get_tile(tx, ty)
	tile_clicked.emit(Vector2i(tx, ty), tile_data)
