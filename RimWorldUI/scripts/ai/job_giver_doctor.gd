class_name JobGiverDoctor
extends ThinkNode

## Issues tend/doctor jobs when colonists have untended injuries or diseases.
## Supports self-tending, prisoner treatment, and animal treatment.

const SELF_TEND_PENALTY := 0.7
const MAX_TEND_RANGE := 80


func try_issue_job(pawn: Pawn) -> Dictionary:
	if not pawn.is_capable_of("Doctor"):
		return {}
	if pawn.drafted or pawn.downed or pawn.dead:
		return {}

	var patient := _find_patient(pawn)
	if patient == null:
		patient = _check_self_tend(pawn)
	if patient == null:
		return {}

	var j := Job.new("TendPatient", patient.grid_pos)
	j.target_thing_id = patient.id
	if patient == pawn:
		j.meta_data["self_tend"] = true
	return {"job": j, "source": self}


func _find_patient(doctor: Pawn) -> Pawn:
	if not PawnManager:
		return null
	var best: Pawn = null
	var best_score: float = -1.0
	for p: Pawn in PawnManager.pawns:
		if p == doctor or p.dead:
			continue
		if p.health == null:
			continue
		if not _has_untended(p.health):
			continue
		var dist: int = absi(doctor.grid_pos.x - p.grid_pos.x) + absi(doctor.grid_pos.y - p.grid_pos.y)
		if dist > MAX_TEND_RANGE:
			continue
		var is_prisoner: bool = p.has_meta("faction") and p.get_meta("faction") == "prisoner"
		var is_enemy: bool = p.has_meta("faction") and p.get_meta("faction") == "enemy"
		if is_enemy:
			continue
		var urgency: float = _get_urgency(p.health)
		if is_prisoner:
			urgency *= 0.5
		var score: float = urgency * 100.0 - float(dist)
		if score > best_score:
			best_score = score
			best = p
	return best


func _check_self_tend(doctor: Pawn) -> Pawn:
	if doctor.health == null:
		return null
	if not _has_untended(doctor.health):
		return null
	var urgency: float = _get_urgency(doctor.health)
	if urgency > 2.0:
		return doctor
	return null


func _has_untended(h: PawnHealth) -> bool:
	for hediff: Dictionary in h.hediffs:
		if not hediff.get("tended", false):
			return true
	return false


func _get_urgency(h: PawnHealth) -> float:
	var urgency: float = 0.0
	for hediff: Dictionary in h.hediffs:
		if hediff.get("tended", false):
			continue
		var bleed: float = hediff.get("bleed_rate", 0.0)
		urgency += bleed * 15.0
		if hediff.get("type", "") == "Disease":
			urgency += hediff.get("severity", 0.0) * 5.0
		elif hediff.get("type", "") == "Infection":
			urgency += hediff.get("severity", 0.0) * 8.0
		else:
			urgency += hediff.get("severity", 0.0) * 1.5
	if h.is_downed:
		urgency += 8.0
	return urgency

func get_tend_range() -> int:
	return MAX_TEND_RANGE

func get_self_tend_penalty_value() -> float:
	return SELF_TEND_PENALTY

func estimate_tend_quality(doctor: Pawn) -> float:
	var skill: int = doctor.get_skill_level("Medicine")
	return clampf(0.2 + float(skill) * 0.07, 0.0, 1.0)

func get_untended_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.health == null:
			continue
		if _has_untended(p.health):
			count += 1
	return count


func get_critical_patient_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.health == null:
			continue
		if _get_urgency(p.health) >= 8.0:
			count += 1
	return count


func get_avg_urgency() -> float:
	if not PawnManager:
		return 0.0
	var total: float = 0.0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.health == null:
			continue
		var u: float = _get_urgency(p.health)
		if u > 0.0:
			total += u
			count += 1
	if count <= 0:
		return 0.0
	return snappedf(total / float(count), 0.01)


func get_medical_capacity_score() -> float:
	if not PawnManager:
		return 0.0
	var doctors := 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if p.get_skill_level("Medicine") >= 4:
			doctors += 1
	var patients := get_untended_count()
	if patients <= 0:
		return 100.0
	return snapped(minf(float(doctors) / float(patients), 3.0) / 3.0 * 100.0, 0.1)

func get_triage_efficiency() -> float:
	var critical := get_critical_patient_count()
	var untended := get_untended_count()
	if untended <= 0:
		return 100.0
	if critical <= 0:
		return 80.0
	return snapped(maxf(0.0, 100.0 - float(critical) / float(untended) * 60.0), 0.1)

func get_outbreak_readiness() -> String:
	var cap := get_medical_capacity_score()
	var critical := get_critical_patient_count()
	if cap >= 80.0 and critical == 0:
		return "Prepared"
	elif cap >= 50.0 and critical <= 1:
		return "Adequate"
	elif cap >= 20.0:
		return "Strained"
	return "Overwhelmed"

func get_medical_summary() -> Dictionary:
	return {
		"tend_range": MAX_TEND_RANGE,
		"self_tend_penalty": SELF_TEND_PENALTY,
		"untended": get_untended_count(),
		"critical_patients": get_critical_patient_count(),
		"avg_urgency": get_avg_urgency(),
		"medical_capacity": get_medical_capacity_score(),
		"triage_efficiency": get_triage_efficiency(),
		"outbreak_readiness": get_outbreak_readiness(),
		"medical_ecosystem_health": get_medical_ecosystem_health(),
		"healthcare_governance": get_healthcare_governance(),
		"clinical_maturity_index": get_clinical_maturity_index(),
	}

func get_medical_ecosystem_health() -> float:
	var cap := get_medical_capacity_score()
	var triage := get_triage_efficiency()
	var readiness := get_outbreak_readiness()
	var r_val: float = 90.0 if readiness == "Prepared" else (65.0 if readiness == "Ready" else (35.0 if readiness == "Vulnerable" else 15.0))
	return snapped((cap + triage + r_val) / 3.0, 0.1)

func get_healthcare_governance() -> String:
	var eco := get_medical_ecosystem_health()
	var mat := get_clinical_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_untended_count() > 0 or get_critical_patient_count() > 0:
		return "Nascent"
	return "Dormant"

func get_clinical_maturity_index() -> float:
	var cap := get_medical_capacity_score()
	var triage := get_triage_efficiency()
	var urgency := get_avg_urgency()
	var urg_inv := maxf(100.0 - urgency, 0.0)
	return snapped((cap + triage + urg_inv) / 3.0, 0.1)
