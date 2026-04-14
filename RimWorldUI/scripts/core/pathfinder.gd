class_name Pathfinder
extends RefCounted

## A* pathfinding on the MapData grid.
## Pre-allocates buffers and reuses them across calls to avoid GC pressure.

var map: MapData
var _max_search: int = 2000

var _g_scores: PackedFloat32Array
var _came_from: PackedInt32Array
var _open_keys: PackedInt32Array
var _open_f: PackedFloat32Array
var _generation: int = 0
var _gen_map: PackedInt32Array
var _closed_gen: PackedInt32Array

func _init(m: MapData) -> void:
	map = m
	var total := m.width * m.height
	_g_scores = PackedFloat32Array()
	_g_scores.resize(total)
	_came_from = PackedInt32Array()
	_came_from.resize(total)
	_gen_map = PackedInt32Array()
	_gen_map.resize(total)
	_gen_map.fill(0)
	_closed_gen = PackedInt32Array()
	_closed_gen.resize(total)
	_closed_gen.fill(0)
	_open_keys = PackedInt32Array()
	_open_f = PackedFloat32Array()


func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if not map.in_bounds(from.x, from.y) or not map.in_bounds(to.x, to.y):
		return []

	var goal_cell := map.get_cell_v(to)
	if goal_cell == null or not goal_cell.is_passable():
		return []

	if from == to:
		return [to]

	var dist := absi(from.x - to.x) + absi(from.y - to.y)
	if dist > 200:
		return []

	_generation += 1
	var gen := _generation

	var w := map.width
	var start_key: int = from.y * w + from.x

	_g_scores[start_key] = 0.0
	_gen_map[start_key] = gen
	_came_from[start_key] = -1

	_open_keys.resize(0)
	_open_f.resize(0)
	_open_keys.append(start_key)
	_open_f.append(_heuristic_i(from.x, from.y, to.x, to.y))

	var searched: int = 0
	var target_key: int = to.y * w + to.x

	var dx := [0, 1, 0, -1]
	var dy := [-1, 0, 1, 0]

	while _open_keys.size() > 0 and searched < _max_search:
		var best_idx: int = 0
		var best_f: float = _open_f[0]
		for i: int in range(1, _open_f.size()):
			if _open_f[i] < best_f:
				best_f = _open_f[i]
				best_idx = i

		var cur_key: int = _open_keys[best_idx]
		var last := _open_keys.size() - 1
		_open_keys[best_idx] = _open_keys[last]
		_open_f[best_idx] = _open_f[last]
		_open_keys.resize(last)
		_open_f.resize(last)

		if _closed_gen[cur_key] == gen:
			continue
		_closed_gen[cur_key] = gen
		searched += 1

		if cur_key == target_key:
			return _reconstruct(cur_key, w)

		var cx: int = cur_key % w
		var cy: int = cur_key / w
		var cur_g: float = _g_scores[cur_key]

		for dir: int in 4:
			var nx: int = cx + dx[dir]
			var ny: int = cy + dy[dir]
			if nx < 0 or nx >= w or ny < 0 or ny >= map.height:
				continue
			var nkey: int = ny * w + nx
			if _closed_gen[nkey] == gen:
				continue
			var cell = map.cells[nkey]
			if cell == null or not cell.is_passable():
				continue
			var move_cost: float = float(cell.get_move_cost())
			var new_g: float = cur_g + move_cost
			var old_g: float = _g_scores[nkey] if _gen_map[nkey] == gen else 999999.0
			if new_g < old_g:
				_g_scores[nkey] = new_g
				_came_from[nkey] = cur_key
				_gen_map[nkey] = gen
				var f_val: float = new_g + _heuristic_i(nx, ny, to.x, to.y)
				_open_keys.append(nkey)
				_open_f.append(f_val)

	return []


func _heuristic_i(ax: int, ay: int, bx: int, by: int) -> float:
	return float(absi(ax - bx) + absi(ay - by)) * 2.0


func _reconstruct(end_key: int, w: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var k := end_key
	while k >= 0:
		result.append(Vector2i(k % w, k / w))
		k = _came_from[k]
	result.reverse()
	return result
