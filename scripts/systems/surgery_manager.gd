extends Node

## Manages medical operations (prosthetics, amputations, organ harvesting).
## Surgery success depends on Medical skill. Registered as autoload "SurgeryManager".

enum Outcome { SUCCESS, MINOR_FAIL, CATASTROPHIC_FAIL }

const OPERATIONS: Dictionary = {
	"InstallPegLeg": {
		"label": "Install peg leg",
		"target_part": "Leg",
		"hediff_add": "PegLeg",
		"work_ticks": 800,
		"medicine_cost": 1,
		"skill_min": 4,
		"base_success": 0.85,
	},
	"InstallWoodenArm": {
		"label": "Install wooden arm",
		"target_part": "Arm",
		"hediff_add": "WoodenArm",
		"work_ticks": 800,
		"medicine_cost": 1,
		"skill_min": 4,
		"base_success": 0.85,
	},
	"InstallBionicEye": {
		"label": "Install bionic eye",
		"target_part": "Eye",
		"hediff_add": "BionicEye",
		"work_ticks": 1200,
		"medicine_cost": 3,
		"skill_min": 8,
		"base_success": 0.70,
	},
	"InstallBionicLeg": {
		"label": "Install bionic leg",
		"target_part": "Leg",
		"hediff_add": "BionicLeg",
		"work_ticks": 1200,
		"medicine_cost": 3,
		"skill_min": 8,
		"base_success": 0.70,
	},
	"InstallBionicArm": {
		"label": "Install bionic arm",
		"target_part": "Arm",
		"hediff_add": "BionicArm",
		"work_ticks": 1200,
		"medicine_cost": 3,
		"skill_min": 8,
		"base_success": 0.70,
	},
	"AmputateLeg": {
		"label": "Amputate leg",
		"target_part": "Leg",
		"hediff_add": "",
		"work_ticks": 600,
		"medicine_cost": 1,
		"skill_min": 3,
		"base_success": 0.95,
	},
	"AmputateArm": {
		"label": "Amputate arm",
		"target_part": "Arm",
		"hediff_add": "",
		"work_ticks": 600,
		"medicine_cost": 1,
		"skill_min": 3,
		"base_success": 0.95,
	},
	"HarvestOrgan": {
		"label": "Harvest organ (kidney)",
		"target_part": "Torso",
		"hediff_add": "MissingOrgan",
		"work_ticks": 1500,
		"medicine_cost": 2,
		"skill_min": 6,
		"base_success": 0.75,
	},
}

var _queued_ops: Array[Dictionary] = []  # {op_name, patient_id, surgeon_id, side}
var _completed: int = 0
var _failed: int = 0
var _op_history: Array[Dictionary] = []
var _success_by_type: Dictionary = {}
var _fail_by_type: Dictionary = {}

const MEDICINE_QUALITY: Dictionary = {
	"MedicineHerbal": 0.6,
	"MedicineIndustrial": 1.0,
	"MedicineGlitterworld": 1.3,
}


func queue_operation(op_name: String, patient_id: int, side: String = "Left") -> bool:
	if not OPERATIONS.has(op_name):
		return false
	for q: Dictionary in _queued_ops:
		if q.patient_id == patient_id and q.op_name == op_name and q.side == side:
			return false
	_queued_ops.append({"op_name": op_name, "patient_id": patient_id, "surgeon_id": -1, "side": side})
	return true


func cancel_operation(patient_id: int, op_name: String) -> void:
	_queued_ops = _queued_ops.filter(
		func(q: Dictionary) -> bool: return not (q.patient_id == patient_id and q.op_name == op_name)
	)


func get_next_operation() -> Dictionary:
	for q: Dictionary in _queued_ops:
		if q.surgeon_id < 0:
			return q
	return {}


func claim_operation(patient_id: int, surgeon_id: int) -> void:
	for q: Dictionary in _queued_ops:
		if q.patient_id == patient_id and q.surgeon_id < 0:
			q.surgeon_id = surgeon_id
			return


func calc_success_chance(op_name: String, surgeon_skill: int, medicine_type: String = "MedicineIndustrial") -> float:
	var op: Dictionary = OPERATIONS.get(op_name, {})
	if op.is_empty():
		return 0.0
	var base: float = op.base_success
	var skill_bonus: float = clampf((surgeon_skill - op.skill_min) * 0.03, -0.2, 0.2)
	var med_factor: float = MEDICINE_QUALITY.get(medicine_type, 1.0)
	return clampf((base + skill_bonus) * med_factor, 0.05, 0.98)


func resolve_operation(op_name: String, patient: Pawn, surgeon_skill: int, rng: RandomNumberGenerator) -> Dictionary:
	var op: Dictionary = OPERATIONS.get(op_name, {})
	if op.is_empty():
		return {"outcome": Outcome.CATASTROPHIC_FAIL, "message": "Unknown operation"}

	var success_chance := calc_success_chance(op_name, surgeon_skill)
	var roll := rng.randf()

	var outcome: Outcome
	var message: String

	if roll <= success_chance:
		outcome = Outcome.SUCCESS
		message = _apply_success(op, patient, op_name)
		_completed += 1
		_success_by_type[op_name] = _success_by_type.get(op_name, 0) + 1
	elif roll <= success_chance + (1.0 - success_chance) * 0.6:
		outcome = Outcome.MINOR_FAIL
		message = _apply_minor_fail(op, patient)
		_failed += 1
		_fail_by_type[op_name] = _fail_by_type.get(op_name, 0) + 1
	else:
		outcome = Outcome.CATASTROPHIC_FAIL
		message = _apply_catastrophic_fail(op, patient)
		_failed += 1
		_fail_by_type[op_name] = _fail_by_type.get(op_name, 0) + 1

	_op_history.append({"op": op_name, "outcome": outcome, "patient_id": patient.id})
	if _op_history.size() > 50:
		_op_history = _op_history.slice(_op_history.size() - 50)

	_queued_ops = _queued_ops.filter(
		func(q: Dictionary) -> bool: return q.patient_id != patient.id or q.op_name != op_name
	)

	if ColonyLog:
		var severity := "positive" if outcome == Outcome.SUCCESS else "danger"
		ColonyLog.add_entry("Medical", message, severity)

	return {"outcome": outcome, "message": message}


func _apply_success(op: Dictionary, patient: Pawn, op_name: String) -> String:
	var part_target: String = op.target_part
	var side := "Left"
	for q: Dictionary in _queued_ops:
		if q.patient_id == patient.id and q.op_name == op_name:
			side = q.get("side", "Left")
			break

	var full_part := side + part_target
	if part_target == "Torso":
		full_part = "Torso"

	if op.hediff_add == "":
		patient.health.get_part(full_part)["destroyed"] = true
		return "%s: %s amputated successfully." % [patient.name, full_part]

	if op.hediff_add == "MissingOrgan":
		var hediff := {
			"type": "Prosthetic",
			"damage_type": "MissingOrgan",
			"part": full_part,
			"severity": 0.0,
			"bleed_rate": 0.0,
			"tended": true,
			"immunity": 0.0,
		}
		patient.health.hediffs.append(hediff)
		return "%s: organ harvested from %s." % [patient.name, full_part]

	var part_dict := patient.health.get_part(full_part)
	if not part_dict.is_empty():
		part_dict["destroyed"] = false
		part_dict["hp"] = part_dict.max_hp

	var hediff := {
		"type": "Prosthetic",
		"damage_type": op.hediff_add,
		"part": full_part,
		"severity": 0.0,
		"bleed_rate": 0.0,
		"tended": true,
		"immunity": 0.0,
	}
	patient.health.hediffs.append(hediff)
	return "%s: %s installed on %s." % [patient.name, op.hediff_add, full_part]


func _apply_minor_fail(op: Dictionary, patient: Pawn) -> String:
	var part_target: String = op.target_part
	var full_part := "Left" + part_target if part_target != "Torso" else "Torso"
	patient.health.add_injury(full_part, 5.0, "Cut")
	return "%s: surgery on %s had a minor complication (small cut)." % [patient.name, full_part]


func _apply_catastrophic_fail(op: Dictionary, patient: Pawn) -> String:
	var part_target: String = op.target_part
	var full_part := "Left" + part_target if part_target != "Torso" else "Torso"
	patient.health.add_injury(full_part, 20.0, "Cut")
	if patient.health.get_part(full_part).hp <= 0:
		return "%s: catastrophic surgery failure destroyed %s!" % [patient.name, full_part]
	return "%s: surgery on %s failed badly (severe cut)." % [patient.name, full_part]


func get_queued_count() -> int:
	return _queued_ops.size()


func get_available_ops_for(pawn: Pawn, surgeon_skill: int) -> Array[String]:
	var result: Array[String] = []
	for op_name: String in OPERATIONS:
		var op: Dictionary = OPERATIONS[op_name]
		if surgeon_skill >= op.skill_min:
			result.append(op_name)
	return result


func get_success_rate(op_name: String) -> float:
	var s: int = _success_by_type.get(op_name, 0)
	var f: int = _fail_by_type.get(op_name, 0)
	if s + f == 0:
		return 0.0
	return float(s) / float(s + f)


func get_op_history(count: int = 10) -> Array[Dictionary]:
	var start: int = maxi(0, _op_history.size() - count)
	return _op_history.slice(start) as Array[Dictionary]


func get_most_successful_op() -> String:
	var best: String = ""
	var best_rate: float = -1.0
	for op_name: String in OPERATIONS:
		var s: int = _success_by_type.get(op_name, 0)
		var f: int = _fail_by_type.get(op_name, 0)
		if s + f == 0:
			continue
		var rate: float = float(s) / float(s + f)
		if rate > best_rate:
			best_rate = rate
			best = op_name
	return best


func get_deadliest_op() -> String:
	var worst: String = ""
	var worst_fails: int = 0
	for op_name: String in _fail_by_type:
		if _fail_by_type[op_name] > worst_fails:
			worst_fails = _fail_by_type[op_name]
			worst = op_name
	return worst


func get_pending_patient_ids() -> Array[int]:
	var ids: Array[int] = []
	for q: Dictionary in _queued_ops:
		if not ids.has(q.patient_id):
			ids.append(q.patient_id)
	return ids


func get_unique_op_types_performed() -> int:
	return _success_by_type.size() + _fail_by_type.size()


func get_pending_patient_count() -> int:
	return get_pending_patient_ids().size()


func get_avg_ops_per_patient() -> float:
	var patients: int = get_pending_patient_count()
	if patients == 0:
		return 0.0
	return float(_queued_ops.size()) / float(patients)


func get_surgery_backlog() -> String:
	var q: int = _queued_ops.size()
	if q == 0:
		return "Clear"
	elif q <= 2:
		return "Low"
	elif q <= 5:
		return "Moderate"
	return "Heavy"

func get_failure_pct() -> float:
	var total: int = _completed + _failed
	if total <= 0:
		return 0.0
	return snappedf(float(_failed) / float(total) * 100.0, 0.1)

func get_bionic_success_rate() -> float:
	var bionic_ops: Array[String] = ["InstallBionicEye", "InstallBionicLeg", "InstallBionicArm"]
	var success: int = 0
	var fail: int = 0
	for op: String in bionic_ops:
		success += _success_by_type.get(op, 0) as int
		fail += _fail_by_type.get(op, 0) as int
	if success + fail <= 0:
		return 0.0
	return snappedf(float(success) / float(success + fail) * 100.0, 0.1)

func get_surgical_excellence() -> float:
	var total := _completed + _failed
	if total <= 0:
		return 0.0
	var success := float(_completed) / float(total)
	var bionic := get_bionic_success_rate() / 100.0
	return snapped((success * 60.0 + bionic * 40.0), 0.1)

func get_medical_infrastructure() -> String:
	var queued := _queued_ops.size()
	var backlog := get_surgery_backlog()
	if backlog == "Critical":
		return "Overwhelmed"
	elif backlog == "Heavy":
		return "Strained"
	elif queued > 0:
		return "Active"
	return "Ready"

func get_risk_management() -> String:
	var failure := get_failure_pct()
	if failure > 20.0:
		return "Poor"
	elif failure > 10.0:
		return "Moderate"
	elif failure > 0.0:
		return "Good"
	return "Excellent"

func get_summary() -> Dictionary:
	var success_rate: float = 0.0
	if _completed + _failed > 0:
		success_rate = float(_completed) / float(_completed + _failed)
	return {
		"queued": _queued_ops.size(),
		"completed": _completed,
		"failed": _failed,
		"success_rate": snappedf(success_rate, 0.01),
		"available_operations": OPERATIONS.size(),
		"success_by_type": _success_by_type.duplicate(),
		"recent_ops": get_op_history(5),
		"most_successful": get_most_successful_op(),
		"deadliest": get_deadliest_op(),
		"unique_ops_done": get_unique_op_types_performed(),
		"pending_patients": get_pending_patient_count(),
		"ops_per_patient": snappedf(get_avg_ops_per_patient(), 0.1),
		"backlog": get_surgery_backlog(),
		"failure_pct": get_failure_pct(),
		"bionic_success_pct": get_bionic_success_rate(),
		"surgical_excellence": get_surgical_excellence(),
		"medical_infrastructure": get_medical_infrastructure(),
		"risk_management": get_risk_management(),
		"surgical_mastery_index": get_surgical_mastery_index(),
		"patient_outcome_score": get_patient_outcome_score(),
		"operating_room_readiness": get_operating_room_readiness(),
	}

func get_surgical_mastery_index() -> float:
	var success: float = 0.0
	if _completed + _failed > 0:
		success = float(_completed) / float(_completed + _failed) * 100.0
	var bionic: float = get_bionic_success_rate()
	return snappedf((success * 0.6 + bionic * 0.4), 0.1)

func get_patient_outcome_score() -> String:
	var failure: float = get_failure_pct()
	if failure <= 5.0:
		return "Excellent"
	if failure <= 15.0:
		return "Good"
	if failure <= 30.0:
		return "Acceptable"
	return "Poor"

func get_operating_room_readiness() -> String:
	var backlog: String = get_surgery_backlog()
	var infra: String = get_medical_infrastructure()
	if backlog in ["None", "Low"] and infra in ["Advanced", "Standard"]:
		return "Ready"
	if backlog != "Critical":
		return "Partial"
	return "Unprepared"
