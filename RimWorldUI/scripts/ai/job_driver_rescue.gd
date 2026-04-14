class_name JobDriverRescue
extends JobDriver

## Carries a downed pawn to the nearest available bed or resting spot.

var _patient: Pawn = null
var _bed_pos: Vector2i = Vector2i(-1, -1)


func _make_toils() -> Array[Dictionary]:
	_patient = _find_patient()
	if _patient == null or not _patient.downed:
		return []

	_bed_pos = _find_bed_position()
	if _bed_pos == Vector2i(-1, -1):
		_bed_pos = pawn.grid_pos

	_patient.set_meta("being_rescued", true)

	return [
		{"name": "goto_patient", "complete_mode": "never"},
		{"name": "pickup", "complete_mode": "instant"},
		{"name": "goto_bed", "complete_mode": "never"},
		{"name": "place", "complete_mode": "instant"},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"goto_patient":
			_start_walk_to_patient()
		"pickup":
			_pickup_patient()
		"goto_bed":
			_start_walk_to_bed()
		"place":
			_place_patient()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"goto_patient", "goto_bed":
			_walk_tick()


func _find_patient() -> Pawn:
	if not PawnManager:
		return null
	for p: Pawn in PawnManager.pawns:
		if p.id == job.target_thing_id:
			return p
	return null


func _find_bed_position() -> Vector2i:
	if BedManager and _patient:
		var bed: Building = BedManager.find_best_bed(_patient)
		if bed:
			return bed.grid_pos
	return Vector2i(-1, -1)


func _start_walk_to_patient() -> void:
	if _patient == null or _patient.dead:
		_release_patient()
		end_job(false)
		return
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		_release_patient()
		end_job(false)
		return
	pawn.path = pf.find_path(pawn.grid_pos, _patient.grid_pos)
	pawn.path_index = 0
	if pawn.path.is_empty():
		_release_patient()
		end_job(false)


func _pickup_patient() -> void:
	if _patient == null or _patient.dead:
		_release_patient()
		end_job(false)
		return
	_advance_toil()


func _start_walk_to_bed() -> void:
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		_release_patient()
		end_job(false)
		return
	pawn.path = pf.find_path(pawn.grid_pos, _bed_pos)
	pawn.path_index = 0
	if pawn.path.is_empty():
		_release_patient()
		end_job(false)


func _place_patient() -> void:
	if _patient == null:
		end_job(false)
		return
	_patient.set_grid_pos(_bed_pos)
	if BedManager:
		var bed: Building = BedManager.find_best_bed(_patient)
		if bed:
			BedManager.assign_bed(_patient, bed)
	pawn.gain_xp("Medical", 10.0)
	if ColonyLog:
		ColonyLog.add_entry("Rescue", "%s rescued %s." % [pawn.pawn_name, _patient.pawn_name], "info")
	_release_patient()
	end_job(true)


func _walk_tick() -> void:
	if not pawn.has_path():
		_advance_toil()
		return
	var next := pawn.next_path_step()
	pawn.set_grid_pos(next)


func end_job(succeeded: bool) -> void:
	_release_patient()
	super.end_job(succeeded)


func _release_patient() -> void:
	if _patient:
		_patient.set_meta("being_rescued", false)
