class_name JobGiverJoy
extends ThinkNode

## Issues joy/recreation jobs, preferring joy buildings if available.

const JOY_THRESHOLD := 0.5
const JOY_BUILDING_DEFS: PackedStringArray = [
	"ChessTable", "HorseshoesPin", "Telescope", "BilliardsTable", "PokerTable",
]

func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.get_need("Joy") > JOY_THRESHOLD:
		return {}
	if pawn.drafted:
		return {}

	var facility: Building = _find_joy_facility(pawn)
	if facility:
		var j := Job.new("JoyActivity", facility.grid_pos)
		j.target_thing_id = facility.id
		return {"job": j, "source": self}

	var j := Job.new("JoyActivity", pawn.grid_pos)
	return {"job": j, "source": self}


func _find_joy_facility(p: Pawn) -> Building:
	if not ThingManager:
		return null
	var best: Building = null
	var best_dist: int = 999
	for t: Thing in ThingManager._buildings:
		var b := t as Building
		if b.build_state != Building.BuildState.COMPLETE:
			continue
		if not (b.def_name in JOY_BUILDING_DEFS):
			continue
		var dist: int = absi(b.grid_pos.x - p.grid_pos.x) + absi(b.grid_pos.y - p.grid_pos.y)
		if dist < best_dist:
			best_dist = dist
			best = b
	return best

func get_joy_threshold() -> float:
	return JOY_THRESHOLD

func get_joy_building_type_count() -> int:
	return JOY_BUILDING_DEFS.size()

func estimate_joy_gain() -> float:
	return snappedf(0.08, 0.001)

func get_available_facility_count() -> int:
	if not ThingManager:
		return 0
	var count: int = 0
	for t: Thing in ThingManager.things:
		if not (t is Building):
			continue
		var b := t as Building
		if b.def_name in JOY_BUILDING_DEFS and b.build_state == Building.BuildState.COMPLETE:
			count += 1
	return count


func get_unique_available_types() -> int:
	if not ThingManager:
		return 0
	var types: Dictionary = {}
	for t: Thing in ThingManager.things:
		if not (t is Building):
			continue
		var b := t as Building
		if b.def_name in JOY_BUILDING_DEFS and b.build_state == Building.BuildState.COMPLETE:
			types[b.def_name] = true
	return types.size()


func get_facility_diversity_pct() -> float:
	var available: int = get_unique_available_types()
	var total: int = JOY_BUILDING_DEFS.size()
	if total <= 0:
		return 0.0
	return snappedf(float(available) / float(total) * 100.0, 0.1)


func get_entertainment_capacity() -> float:
	var facilities := get_available_facility_count()
	if not PawnManager:
		return 0.0
	var pawns := PawnManager.pawns.size()
	if pawns <= 0:
		return 100.0
	return snapped(minf(float(facilities) / float(pawns), 3.0) / 3.0 * 100.0, 0.1)

func get_joy_deficit_risk() -> String:
	var diversity := get_facility_diversity_pct()
	var facilities := get_available_facility_count()
	if diversity >= 60.0 and facilities >= 3:
		return "Low"
	elif diversity >= 30.0 or facilities >= 2:
		return "Moderate"
	elif facilities >= 1:
		return "High"
	return "Critical"

func get_social_enrichment_score() -> float:
	var base := estimate_joy_gain()
	var diversity := get_facility_diversity_pct() / 100.0
	var types := float(get_unique_available_types())
	return snapped(base * (1.0 + diversity) * minf(types, 5.0) / 5.0 * 100.0, 0.1)

func get_joy_summary() -> Dictionary:
	return {
		"threshold": JOY_THRESHOLD,
		"building_types": get_joy_building_type_count(),
		"base_joy_gain": estimate_joy_gain(),
		"available_facilities": get_available_facility_count(),
		"unique_types": get_unique_available_types(),
		"diversity_pct": get_facility_diversity_pct(),
		"entertainment_capacity": get_entertainment_capacity(),
		"joy_deficit_risk": get_joy_deficit_risk(),
		"social_enrichment": get_social_enrichment_score(),
		"joy_ecosystem_health": get_joy_ecosystem_health(),
		"recreation_governance": get_recreation_governance(),
		"leisure_maturity_index": get_leisure_maturity_index(),
	}

func get_joy_ecosystem_health() -> float:
	var cap := get_entertainment_capacity()
	var risk := get_joy_deficit_risk()
	var r_val: float = 90.0 if risk == "Low" else (60.0 if risk == "Moderate" else 25.0)
	var enrichment := get_social_enrichment_score()
	return snapped((minf(cap, 100.0) + r_val + minf(enrichment * 10.0, 100.0)) / 3.0, 0.1)

func get_recreation_governance() -> String:
	var eco := get_joy_ecosystem_health()
	var mat := get_leisure_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_available_facility_count() > 0:
		return "Nascent"
	return "Dormant"

func get_leisure_maturity_index() -> float:
	var diversity := get_facility_diversity_pct()
	var unique := minf(float(get_unique_available_types()) * 15.0, 100.0)
	var enrichment := minf(get_social_enrichment_score() * 10.0, 100.0)
	return snapped((diversity + unique + enrichment) / 3.0, 0.1)
