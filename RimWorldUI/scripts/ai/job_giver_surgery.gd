class_name JobGiverSurgery
extends ThinkNode

## Issues a Surgery job when SurgeryManager has queued operations and a
## capable pawn (Medical skill >= op minimum) is available.


func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.drafted or pawn.downed:
		return {}
	if not SurgeryManager:
		return {}

	var med_skill: int = pawn.skills.get("Medical", 0)
	if med_skill < 1:
		return {}

	var next_op := SurgeryManager.get_next_operation()
	if next_op.is_empty():
		return {}

	var op_def: Dictionary = SurgeryManager.OPERATIONS.get(next_op.op_name, {})
	if op_def.is_empty():
		return {}
	if med_skill < op_def.get("skill_min", 0):
		return {}

	var patient: Pawn = _find_patient(next_op.patient_id)
	if patient == null:
		return {}

	SurgeryManager.claim_operation(next_op.patient_id, pawn.id)

	var job := Job.new()
	job.job_def = "Surgery"
	job.target_pos = patient.grid_pos
	job.set_meta("patient_id", next_op.patient_id)
	job.set_meta("op_name", next_op.op_name)
	job.set_meta("side", next_op.get("side", "Left"))
	return {"job": job}


func _find_patient(patient_id: int) -> Pawn:
	if not PawnManager:
		return null
	for p: Pawn in PawnManager.pawns:
		if p.id == patient_id and not p.dead:
			return p
	return null
