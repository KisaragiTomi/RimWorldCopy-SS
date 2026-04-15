class_name JobDriverDoctor
extends JobDriver

## Walk to patient, tend their injuries/diseases. Medicine skill affects quality.

var _patient: Pawn = null
var _has_medicine: bool = false


func _make_toils() -> Array[Dictionary]:
	_patient = _find_patient()
	if _patient == null:
		return []

	return [
		{
			"name": "goto_patient",
			"complete_mode": "never",
		},
		{
			"name": "tend",
			"complete_mode": "delay",
			"delay_ticks": 200,
		},
		{
			"name": "finish_tend",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"goto_patient":
			_start_walk()
		"tend":
			_begin_tend()
		"finish_tend":
			_do_tend()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"goto_patient":
			_walk_tick()


func _find_patient() -> Pawn:
	if not PawnManager:
		return null
	for p: Pawn in PawnManager.pawns:
		if p.id == job.target_thing_id:
			return p
	return null


func _start_walk() -> void:
	if _patient == null:
		end_job(false)
		return
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		end_job(false)
		return
	var target := _get_adjacent(pf.map, _patient.grid_pos)
	pawn.path = pf.find_path(pawn.grid_pos, target)
	pawn.path_index = 0
	if pawn.path.is_empty():
		end_job(false)


func _walk_tick() -> void:
	if not pawn.has_path():
		_advance_toil()
		return
	var next := pawn.next_path_step()
	pawn.set_grid_pos(next)


func _begin_tend() -> void:
	_has_medicine = _try_consume_medicine()


func _do_tend() -> void:
	if _patient == null or _patient.health == null:
		end_job(false)
		return

	var skill: int = pawn.get_skill_level("Medicine")
	var base_quality: float = clampf(0.3 + skill * 0.07, 0.2, 0.95)
	if _has_medicine:
		base_quality = minf(base_quality + 0.2, 0.98)

	var tended_count: int = 0
	for i: int in _patient.health.hediffs.size():
		var h: Dictionary = _patient.health.hediffs[i]
		if not h.get("tended", false):
			_patient.health.tend_injury(i, base_quality)
			tended_count += 1
			if tended_count >= 2:
				break

	if tended_count > 0:
		pawn.gain_xp("Medicine", float(tended_count) * 40.0)
		if ColonyLog:
			ColonyLog.add_entry("Medical", "%s tended %s (quality %.0f%%)." % [
				pawn.pawn_name, _patient.pawn_name, base_quality * 100.0
			], "info")

	end_job(true)


func _try_consume_medicine() -> bool:
	if not ThingManager:
		return false
	for t: Thing in ThingManager.things:
		if t is Item:
			var item := t as Item
			if item.state != Thing.ThingState.SPAWNED:
				continue
			if item.def_name == "Medicine" or item.def_name == "HerbalMedicine":
				if item.stack_count <= 1:
					ThingManager.remove_thing(item)
				else:
					item.stack_count -= 1
				return true
	return false


func _get_adjacent(map: MapData, pos: Vector2i) -> Vector2i:
	for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nb: Vector2i = pos + dir
		if map.in_bounds(nb.x, nb.y):
			var cell := map.get_cell(nb.x, nb.y)
			if cell and cell.is_passable():
				return nb
	return pos


func get_triage_priority(patient: Pawn) -> float:
	if patient == null or patient.health == null:
		return 0.0
	var severity: float = 0.0
	for h: Dictionary in patient.health.hediffs:
		severity += h.get("severity", 0.0)
		if h.get("is_bleeding", false):
			severity += 5.0
		if h.get("is_infection", false):
			severity += 3.0
	if patient.downed:
		severity += 8.0
	return severity


func estimate_tend_quality() -> float:
	var skill: int = pawn.get_skill_level("Medicine")
	var base: float = clampf(0.3 + skill * 0.07, 0.2, 0.95)
	if _has_medicine:
		base = minf(base + 0.2, 0.98)
	return base


func can_self_tend() -> bool:
	return pawn.get_skill_level("Medicine") >= 4 and not pawn.downed


func _get_map() -> MapData:
	if GameState and GameState.has_method("get_map"):
		return GameState.get_map()
	return null
