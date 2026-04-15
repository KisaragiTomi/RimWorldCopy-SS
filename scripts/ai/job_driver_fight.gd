class_name JobDriverFight
extends JobDriver

## Executes ranged or melee attack jobs.

var _target: Pawn = null
var _is_ranged: bool = false


func _make_toils() -> Array[Dictionary]:
	_is_ranged = job.job_def == "RangedAttack"
	_target = _find_target()
	if _target == null:
		return []

	var toils: Array[Dictionary] = []

	if _is_ranged:
		toils.append({
			"name": "aim",
			"complete_mode": "delay",
			"delay_ticks": 20,
		})
		toils.append({
			"name": "fire",
			"complete_mode": "instant",
		})
	else:
		toils.append({
			"name": "goto_melee",
			"complete_mode": "custom",
		})
		toils.append({
			"name": "strike",
			"complete_mode": "instant",
		})
	return toils


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"fire":
			_do_ranged_attack()
		"goto_melee":
			_goto_target()
		"strike":
			_do_melee_attack()


func _on_toil_tick(toil_name: String) -> void:
	if toil_name == "goto_melee":
		if _target == null or _target.dead or _target.downed:
			end_job(false)
			return
		var dist := pawn.grid_pos.distance_to(_target.grid_pos) as float
		if dist <= 1.5:
			_advance_toil()
			return
		if pawn.has_path():
			var next := pawn.next_path_step()
			pawn.set_grid_pos(next)
		elif _toil_ticks > 10:
			_goto_target()
		if _toil_ticks > 300:
			end_job(false)


func _find_target() -> Pawn:
	if not PawnManager:
		return null
	for p: Pawn in PawnManager.pawns:
		if p.id == job.target_thing_id and not p.dead:
			return p
	return null


func _goto_target() -> void:
	if _target == null or _target.dead:
		return
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		return
	var adjacent := _get_adjacent(pf.map, _target.grid_pos)
	if adjacent == Vector2i(-1, -1):
		return
	pawn.path = pf.find_path(pawn.grid_pos, adjacent)
	pawn.path_index = 0


func _get_adjacent(map: MapData, target_pos: Vector2i) -> Vector2i:
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for d: Vector2i in dirs:
		var check := target_pos + d
		if map.in_bounds(check.x, check.y):
			var cell := map.get_cell(check.x, check.y)
			if cell and cell.is_passable():
				return check
	return Vector2i(-1, -1)


func _do_ranged_attack() -> void:
	if _target == null or _target.dead:
		return
	CombatUtil.ranged_attack(pawn, _target)


func _do_melee_attack() -> void:
	if _target == null or _target.dead:
		return
	CombatUtil.melee_attack(pawn, _target)
