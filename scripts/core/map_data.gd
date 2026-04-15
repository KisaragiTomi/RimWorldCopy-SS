class_name MapData
extends RefCounted

## Holds a 2D grid of Cells representing the local map.

signal map_generated

var width: int
var height: int
var cells: Array = []   # flat array, indexed [y * width + x]
var seed: int = 42


func _init(w: int = 275, h: int = 275) -> void:
	width = w
	height = h
	_alloc_cells()


func _alloc_cells() -> void:
	cells.resize(width * height)
	for y: int in height:
		for x: int in width:
			cells[y * width + x] = Cell.new(x, y)


func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height


func get_cell(x: int, y: int) -> Cell:
	if not in_bounds(x, y):
		return null
	return cells[y * width + x]


func get_cell_v(pos: Vector2i) -> Cell:
	return get_cell(pos.x, pos.y)


func set_terrain(x: int, y: int, terrain: String) -> void:
	var c := get_cell(x, y)
	if c:
		c.terrain_def = terrain


func get_terrain(x: int, y: int) -> String:
	var c := get_cell(x, y)
	return c.terrain_def if c else ""


func neighbors_4(x: int, y: int) -> Array[Cell]:
	var result: Array[Cell] = []
	for offset: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		var c := get_cell(x + offset.x, y + offset.y)
		if c:
			result.append(c)
	return result


func neighbors_8(x: int, y: int) -> Array[Cell]:
	var result: Array[Cell] = []
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var c := get_cell(x + dx, y + dy)
			if c:
				result.append(c)
	return result


func cells_in_rect(rx: int, ry: int, rw: int, rh: int) -> Array[Cell]:
	var result: Array[Cell] = []
	for y: int in range(maxi(0, ry), mini(height, ry + rh)):
		for x: int in range(maxi(0, rx), mini(width, rx + rw)):
			result.append(cells[y * width + x])
	return result


func cells_in_radius(cx: int, cy: int, radius: float) -> Array[Cell]:
	var result: Array[Cell] = []
	var r2 := radius * radius
	var ri := int(ceil(radius))
	for dy: int in range(-ri, ri + 1):
		for dx: int in range(-ri, ri + 1):
			if dx * dx + dy * dy <= r2:
				var c := get_cell(cx + dx, cy + dy)
				if c:
					result.append(c)
	return result


func to_dict() -> Dictionary:
	var cell_arr: Array = []
	for c: Cell in cells:
		cell_arr.append(c.to_dict())
	return {
		"width": width,
		"height": height,
		"seed": seed,
		"cells": cell_arr,
	}


static func from_dict(d: Dictionary) -> MapData:
	var m := MapData.new(d.get("width", 275), d.get("height", 275))
	m.seed = d.get("seed", 42)
	var cell_arr: Array = d.get("cells", [])
	for i: int in cell_arr.size():
		if i < m.cells.size():
			m.cells[i] = Cell.from_dict(cell_arr[i])
	return m
