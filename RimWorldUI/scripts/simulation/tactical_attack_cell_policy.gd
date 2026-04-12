extends RefCounted
## 同一地图格上不能同时站两个「正在攻击」的单位：多出的单位被排挤到最近可走空地。
## 被排挤过程中保持强制攻击意图，但 [may_attack_this_tick] 在够不着目标时为 false；
## 到达目标格后若仍够不着敌人则退出攻击状态。
class_name TacticalAttackCellPolicy

enum Phase { NONE, ATTACKING, ATTACKING_RELOCATING }

const _NO_CELL := Vector2i(999999, 999999)

var max_attack_range: int = 1
## true：切比雪夫距离（邻接八格为 1）；false：曼哈顿
var use_chebyshev: bool = true

var _unit_cell: Dictionary = {}  # Variant -> Vector2i
var _phase: Dictionary = {}  # Variant -> Phase
var _target_cell: Dictionary = {}  # Variant -> Vector2i

static var _DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]


func clear() -> void:
	_unit_cell.clear()
	_phase.clear()
	_target_cell.clear()


func set_unit_cell(unit_id: Variant, cell: Vector2i) -> void:
	_unit_cell[unit_id] = cell


func remove_unit(unit_id: Variant) -> void:
	_unit_cell.erase(unit_id)
	_phase.erase(unit_id)
	_target_cell.erase(unit_id)


func get_phase(unit_id: Variant) -> Phase:
	return _phase.get(unit_id, Phase.NONE) as Phase


func get_attack_target_cell(unit_id: Variant) -> Variant:
	return _target_cell.get(unit_id, null)


## 开始攻击 [target_cell]；若当前与另一攻击者同格，会在 [resolve_overlapping_attackers] 中被要求换位。
func set_attacking(unit_id: Variant, target_cell: Vector2i) -> void:
	_target_cell[unit_id] = target_cell
	if _phase.get(unit_id, Phase.NONE) == Phase.ATTACKING_RELOCATING:
		return
	_phase[unit_id] = Phase.ATTACKING


func clear_attacking(unit_id: Variant) -> void:
	_phase[unit_id] = Phase.NONE
	_target_cell.erase(unit_id)


func _is_attacking_phase(p: Phase) -> bool:
	return p == Phase.ATTACKING or p == Phase.ATTACKING_RELOCATING


func _dist(a: Vector2i, b: Vector2i) -> int:
	if use_chebyshev:
		return maxi(absi(a.x - b.x), absi(a.y - b.y))
	return absi(a.x - b.x) + absi(a.y - b.y)


func _can_hit_from(unit_id: Variant, from_cell: Vector2i) -> bool:
	if not _target_cell.has(unit_id):
		return false
	var t: Vector2i = _target_cell[unit_id]
	return _dist(from_cell, t) <= max_attack_range


## 本 tick 是否允许结算伤害：强制攻击态下只有够得着目标才为 true。
func may_attack_this_tick(unit_id: Variant) -> bool:
	var p: Phase = _phase.get(unit_id, Phase.NONE) as Phase
	if not _is_attacking_phase(p):
		return false
	var cell: Vector2i = _unit_cell.get(unit_id, _NO_CELL) as Vector2i
	if cell == _NO_CELL:
		return false
	return _can_hit_from(unit_id, cell)


## 单位到达新格后调用（走路结束）。若在排挤途中且仍够不着目标则取消攻击。
func notify_unit_arrived_at_cell(unit_id: Variant, cell: Vector2i) -> void:
	_unit_cell[unit_id] = cell
	var p: Phase = _phase.get(unit_id, Phase.NONE) as Phase
	if p != Phase.ATTACKING_RELOCATING:
		return
	if _can_hit_from(unit_id, cell):
		_phase[unit_id] = Phase.ATTACKING
	else:
		_phase[unit_id] = Phase.NONE
		_target_cell.erase(unit_id)


func _build_occupied_cells() -> Dictionary:
	var occ: Dictionary = {}
	for uid in _unit_cell:
		var c: Vector2i = _unit_cell[uid] as Vector2i
		occ[c] = true
	return occ


func _find_nearest_empty(from: Vector2i, reserved: Dictionary, occ: Dictionary, is_walkable: Callable) -> Vector2i:
	var visited: Dictionary = {}
	var q: Array[Vector2i] = []
	var qi := 0
	q.append(from)
	while qi < q.size():
		var c: Vector2i = q[qi]
		qi += 1
		if visited.has(c):
			continue
		visited[c] = true
		if is_walkable.call(c) and not occ.has(c) and not reserved.has(c):
			return c
		for d: Vector2i in _DIRS:
			var n: Vector2i = c + d
			if not visited.has(n):
				q.append(n)
	return _NO_CELL


## 解决同格多个攻击者：保留 id 较小（稳定）者，其余得到最近空地位。返回 { unit_id: destination }。
func resolve_overlapping_attackers(is_walkable: Callable) -> Dictionary:
	var orders: Dictionary = {}
	var cell_to_attackers: Dictionary = {}
	for uid in _unit_cell:
		var p: Phase = _phase.get(uid, Phase.NONE) as Phase
		if not _is_attacking_phase(p):
			continue
		var c: Vector2i = _unit_cell[uid] as Vector2i
		if not cell_to_attackers.has(c):
			cell_to_attackers[c] = []
		(cell_to_attackers[c] as Array).append(uid)

	var reserved: Dictionary = {}
	for cell in cell_to_attackers:
		var group: Array = cell_to_attackers[cell] as Array
		if group.size() < 2:
			continue
		group.sort()
		var keeper: Variant = group[0]
		for i in range(1, group.size()):
			var mover: Variant = group[i]
			var from_cell: Vector2i = _unit_cell[mover] as Vector2i
			var occ: Dictionary = _build_occupied_cells()
			var dest: Vector2i = _find_nearest_empty(from_cell, reserved, occ, is_walkable)
			if dest == _NO_CELL:
				continue
			reserved[dest] = true
			_phase[mover] = Phase.ATTACKING_RELOCATING
			orders[mover] = dest
	return orders


## 将 [orders] 中的单位立即更新为目的地格（瞬移/路径走完后的最终一步由你方移动系统调用 [notify_unit_arrived_at_cell]）。
func apply_relocation_destination(unit_id: Variant, dest: Vector2i) -> void:
	_unit_cell[unit_id] = dest
	notify_unit_arrived_at_cell(unit_id, dest)
