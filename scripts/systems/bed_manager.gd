extends Node

## Tracks bed assignments and rest quality bonuses.
## Registered as autoload "BedManager".

var _assignments: Dictionary = {}
var _bed_owners: Dictionary = {}

const BED_QUALITY: Dictionary = {
	"Bed": 0.9,
	"DoubleBed": 1.0,
	"HospitalBed": 1.1,
	"RoyalBed": 1.3,
}
const REST_QUALITY_GROUND := 0.6
const THOUGHT_SLEPT_IN_BED := "SleptInBed"
const THOUGHT_SLEPT_ON_GROUND := "SleptOnGround"
const THOUGHT_SLEPT_IN_BARRACKS := "SleptInBarracks"


func assign_bed(pawn: Pawn, bed: Building) -> void:
	unassign_bed(pawn)
	_assignments[pawn.id] = bed
	var key: String = _pos_key(bed.grid_pos)
	_bed_owners[key] = pawn.id


func unassign_bed(pawn: Pawn) -> void:
	if _assignments.has(pawn.id):
		var old_bed: Building = _assignments[pawn.id]
		_bed_owners.erase(_pos_key(old_bed.grid_pos))
		_assignments.erase(pawn.id)


func get_assigned_bed(pawn: Pawn) -> Building:
	return _assignments.get(pawn.id) as Building


func is_bed_taken(bed: Building) -> bool:
	return _bed_owners.has(_pos_key(bed.grid_pos))


func find_best_bed(pawn: Pawn) -> Building:
	var assigned: Building = get_assigned_bed(pawn)
	if assigned and assigned.build_state == Building.BuildState.COMPLETE:
		return assigned

	if not ThingManager:
		return null

	var best: Building = null
	var best_quality: float = 0.0
	for t: Thing in ThingManager.things:
		if not (t is Building):
			continue
		var b := t as Building
		if b.build_state != Building.BuildState.COMPLETE:
			continue
		if not BED_QUALITY.has(b.def_name):
			continue
		if is_bed_taken(b):
			continue
		var q: float = BED_QUALITY.get(b.def_name, 0.9)
		var dist: float = float(absi(pawn.grid_pos.x - b.grid_pos.x) + absi(pawn.grid_pos.y - b.grid_pos.y))
		q -= dist * 0.001
		if q > best_quality or best == null:
			best = b
			best_quality = q

	if best:
		assign_bed(pawn, best)
	return best


func get_rest_quality(pawn: Pawn) -> float:
	var bed: Building = get_assigned_bed(pawn)
	if bed and bed.build_state == Building.BuildState.COMPLETE:
		return BED_QUALITY.get(bed.def_name, 0.9)
	return REST_QUALITY_GROUND


func apply_sleep_thought(pawn: Pawn) -> void:
	if pawn.thought_tracker == null:
		return
	var bed: Building = get_assigned_bed(pawn)
	if bed and bed.build_state == Building.BuildState.COMPLETE:
		pawn.thought_tracker.add_thought(THOUGHT_SLEPT_IN_BED)
		if _is_barracks_bed(bed):
			pawn.thought_tracker.add_thought(THOUGHT_SLEPT_IN_BARRACKS)
	else:
		pawn.thought_tracker.add_thought(THOUGHT_SLEPT_ON_GROUND)


func get_total_beds() -> int:
	var count: int = 0
	if ThingManager:
		for t: Thing in ThingManager.things:
			if t is Building and BED_QUALITY.has(t.def_name):
				if (t as Building).build_state == Building.BuildState.COMPLETE:
					count += 1
	return count


func get_available_beds() -> int:
	var count: int = 0
	if ThingManager:
		for t: Thing in ThingManager.things:
			if t is Building and BED_QUALITY.has(t.def_name):
				var b := t as Building
				if b.build_state == Building.BuildState.COMPLETE and not is_bed_taken(b):
					count += 1
	return count


func _is_barracks_bed(bed: Building) -> bool:
	if not ThingManager:
		return false
	var bed_count: int = 0
	for t: Thing in ThingManager.things:
		if t is Building and BED_QUALITY.has(t.def_name):
			var dist: int = absi(t.grid_pos.x - bed.grid_pos.x) + absi(t.grid_pos.y - bed.grid_pos.y)
			if dist < 8:
				bed_count += 1
	return bed_count >= 3


func _pos_key(pos: Vector2i) -> String:
	return str(pos.x) + "," + str(pos.y)


func get_bed_deficit() -> int:
	var colonist_count: int = 0
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if not p.dead and (not p.has_meta("faction") or p.get_meta("faction") == "colony"):
				colonist_count += 1
	return maxi(0, colonist_count - get_total_beds())


func get_unassigned_pawns() -> Array[int]:
	var result: Array[int] = []
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.dead:
				continue
			if not _assignments.has(p.id):
				result.append(p.id)
	return result


func get_occupancy_rate() -> float:
	var total: int = get_total_beds()
	if total == 0:
		return 0.0
	return float(_bed_owners.size()) / float(total)


func get_medical_bed_count() -> int:
	if not ThingManager:
		return 0
	var cnt: int = 0
	for t: Thing in ThingManager.things:
		if t is Building and (t as Building).def_name == "HospitalBed":
			if (t as Building).build_state == Building.BuildState.COMPLETE:
				cnt += 1
	return cnt


func get_double_bed_count() -> int:
	if not ThingManager:
		return 0
	var cnt: int = 0
	for t: Thing in ThingManager.things:
		if t is Building and (t as Building).def_name == "DoubleBed":
			if (t as Building).build_state == Building.BuildState.COMPLETE:
				cnt += 1
	return cnt


func has_bed_crisis() -> bool:
	return get_bed_deficit() >= 2


func get_unassigned_pawn_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead and not _assignments.has(p.id):
			count += 1
	return count


func get_bed_type_variety() -> int:
	if not ThingManager:
		return 0
	var types: Dictionary = {}
	for t: Thing in ThingManager.things:
		if t is Building and (t as Building).def_name.contains("Bed"):
			types[(t as Building).def_name] = true
	return types.size()


func get_assignment_rate() -> float:
	var total: int = get_total_beds()
	if total <= 0:
		return 0.0
	return snappedf(float(_assignments.size()) / float(total) * 100.0, 0.1)


func get_housing_adequacy() -> String:
	var deficit := get_bed_deficit()
	var rate := get_occupancy_rate()
	if deficit > 3:
		return "Severe Shortage"
	elif deficit > 0:
		return "Shortage"
	elif rate > 90.0:
		return "Near Capacity"
	elif rate > 50.0:
		return "Adequate"
	return "Surplus"

func get_medical_readiness() -> float:
	var medical := get_medical_bed_count()
	var total := get_total_beds()
	if total <= 0:
		return 0.0
	return snapped(float(medical) / float(total) * 100.0, 0.1)

func get_comfort_infrastructure() -> String:
	var variety := get_bed_type_variety()
	var doubles := get_double_bed_count()
	if variety >= 4 and doubles >= 2:
		return "Luxurious"
	elif variety >= 3 or doubles >= 1:
		return "Comfortable"
	elif variety >= 2:
		return "Basic"
	return "Spartan"

func get_summary() -> Dictionary:
	return {
		"assigned_count": _assignments.size(),
		"beds_taken": _bed_owners.size(),
		"total_beds": get_total_beds(),
		"available_beds": get_available_beds(),
		"deficit": get_bed_deficit(),
		"occupancy": snappedf(get_occupancy_rate(), 0.01),
		"medical_beds": get_medical_bed_count(),
		"double_beds": get_double_bed_count(),
		"crisis": has_bed_crisis(),
		"unassigned_pawns": get_unassigned_pawn_count(),
		"bed_type_variety": get_bed_type_variety(),
		"assignment_rate_pct": get_assignment_rate(),
		"housing_adequacy": get_housing_adequacy(),
		"medical_readiness_pct": get_medical_readiness(),
		"comfort_infrastructure": get_comfort_infrastructure(),
		"residential_maturity": get_residential_maturity(),
		"population_capacity_ratio": get_population_capacity_ratio(),
		"welfare_infrastructure_score": get_welfare_infrastructure_score(),
	}

func get_residential_maturity() -> String:
	var total: int = get_total_beds()
	var variety: int = get_bed_type_variety()
	var doubles: int = get_double_bed_count()
	if total >= 15 and variety >= 3 and doubles >= 3:
		return "Mature"
	if total >= 8 and variety >= 2:
		return "Developing"
	if total >= 3:
		return "Basic"
	return "Primitive"

func get_population_capacity_ratio() -> float:
	var total: int = get_total_beds()
	var assigned: int = _assignments.size()
	if total == 0:
		return 0.0
	return snappedf(float(assigned) / float(total) * 100.0, 0.1)

func get_welfare_infrastructure_score() -> float:
	var med_ready: float = get_medical_readiness()
	var occupancy: float = get_occupancy_rate()
	var assignment: float = get_assignment_rate()
	var score: float = med_ready * 0.3 + occupancy * 0.3 + assignment * 0.4
	return snappedf(clampf(score, 0.0, 100.0), 0.1)
