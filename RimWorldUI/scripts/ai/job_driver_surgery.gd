class_name JobDriverSurgery
extends JobDriver

## Drives a pawn to perform surgery on a patient. Walks to patient, operates
## over multiple ticks, then resolves outcome via SurgeryManager.

var _work_left: float = 0.0
var _patient_id: int = -1
var _op_name: String = ""
var _side: String = "Left"
var _rng := RandomNumberGenerator.new()


func setup(pawn: Pawn, job: Job) -> void:
	super.setup(pawn, job)
	_patient_id = job.get_meta("patient_id") if job.has_meta("patient_id") else -1
	_op_name = job.get_meta("op_name") if job.has_meta("op_name") else ""
	_side = job.get_meta("side") if job.has_meta("side") else "Left"

	var op_def: Dictionary = SurgeryManager.OPERATIONS.get(_op_name, {})
	_work_left = float(op_def.get("work_ticks", 800))
	_rng.seed = pawn.id * 97 + TickManager.current_tick if TickManager else pawn.id


func driver_tick() -> void:
	if ended:
		return

	var patient := _find_patient()
	if patient == null or patient.dead:
		ended = true
		return

	if pawn.grid_pos.distance_to(patient.grid_pos) > 1.5:
		_move_toward(patient.grid_pos)
		return

	var skill_level: int = pawn.skills.get("Medical", 1)
	var work_speed: float = 1.0 + skill_level * 0.08
	_work_left -= work_speed

	if _work_left <= 0.0:
		var result := SurgeryManager.resolve_operation(_op_name, patient, skill_level, _rng)
		pawn.gain_xp("Medical", 250.0)
		if SkillDecayManager:
			SkillDecayManager.mark_skill_used(pawn.id, "Medical")
		ended = true


func _find_patient() -> Pawn:
	if not PawnManager:
		return null
	for p: Pawn in PawnManager.pawns:
		if p.id == _patient_id:
			return p
	return null


func _move_toward(target: Vector2i) -> void:
	if pawn.has_path() and pawn.path_index < pawn.path.size():
		pawn.set_grid_pos(pawn.next_path_step())
		return

	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		ended = true
		return

	var path := pf.find_path(pawn.grid_pos, target)
	if path.is_empty():
		ended = true
		return
	pawn.path = path
	pawn.path_index = 0
	pawn.set_grid_pos(pawn.next_path_step())
