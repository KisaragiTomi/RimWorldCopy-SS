class_name JobGiverDeconstruct
extends ThinkNode

## Issues a Deconstruct job for buildings marked for deconstruction.


func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.drafted or pawn.dead or pawn.downed:
		return {}
	if not pawn.is_capable_of("Construction"):
		return {}
	if not ThingManager:
		return {}

	for t: Thing in ThingManager.things:
		if not (t is Building):
			continue
		var b := t as Building
		if not b.has_meta("marked_deconstruct"):
			continue
		if not b.get_meta("marked_deconstruct"):
			continue

		var job := Job.new()
		job.job_def = "Deconstruct"
		job.target_pos = b.grid_pos
		return {"job": job}

	return {}


func get_marked_count() -> int:
	if not ThingManager:
		return 0
	var cnt: int = 0
	for t: Thing in ThingManager.things:
		if t is Building and t.has_meta("marked_deconstruct") and t.get_meta("marked_deconstruct"):
			cnt += 1
	return cnt


func get_nearest_marked(from: Vector2i) -> Vector2i:
	if not ThingManager:
		return Vector2i(-1, -1)
	var best := Vector2i(-1, -1)
	var best_dist: int = 999999
	for t: Thing in ThingManager.things:
		if t is Building and t.has_meta("marked_deconstruct") and t.get_meta("marked_deconstruct"):
			var d: int = absi(t.grid_pos.x - from.x) + absi(t.grid_pos.y - from.y)
			if d < best_dist:
				best_dist = d
				best = t.grid_pos
	return best


func get_estimated_resource_return() -> int:
	if not ThingManager:
		return 0
	var total: int = 0
	for t: Thing in ThingManager.things:
		if t is Building and t.has_meta("marked_deconstruct") and t.get_meta("marked_deconstruct"):
			total += (t as Building).max_hit_points / 10
	return total


func get_avg_hp_marked() -> float:
	if not ThingManager:
		return 0.0
	var total: float = 0.0
	var cnt: int = 0
	for t: Thing in ThingManager.things:
		if t is Building and t.has_meta("marked_deconstruct") and t.get_meta("marked_deconstruct"):
			total += float((t as Building).max_hit_points)
			cnt += 1
	if cnt == 0:
		return 0.0
	return total / float(cnt)


func get_resource_per_building() -> float:
	var count: int = get_marked_count()
	if count <= 0:
		return 0.0
	return snappedf(float(get_estimated_resource_return()) / float(count), 0.1)

func get_deconstruct_priority() -> String:
	var count: int = get_marked_count()
	if count == 0:
		return "None"
	elif count <= 2:
		return "Low"
	elif count <= 6:
		return "Normal"
	return "High"

func is_any_marked() -> bool:
	return get_marked_count() > 0

func get_salvage_value_assessment() -> String:
	var per_building := get_resource_per_building()
	if per_building >= 50.0:
		return "Valuable"
	elif per_building >= 20.0:
		return "Worthwhile"
	elif per_building > 0.0:
		return "Marginal"
	return "None"

func get_demolition_impact() -> float:
	var marked := get_marked_count()
	if marked <= 0:
		return 0.0
	var avg_hp := get_avg_hp_marked()
	return snapped(float(marked) * (100.0 - avg_hp) / 100.0, 0.1)

func get_cleanup_urgency() -> String:
	var marked := get_marked_count()
	if marked >= 10:
		return "High"
	elif marked >= 5:
		return "Normal"
	elif marked > 0:
		return "Low"
	return "None"

func get_deconstruct_summary() -> Dictionary:
	return {
		"marked": get_marked_count(),
		"resource_return": get_estimated_resource_return(),
		"avg_hp": snappedf(get_avg_hp_marked(), 0.1),
		"resource_per_building": get_resource_per_building(),
		"priority": get_deconstruct_priority(),
		"has_work": is_any_marked(),
		"salvage_assessment": get_salvage_value_assessment(),
		"demolition_impact": get_demolition_impact(),
		"cleanup_urgency": get_cleanup_urgency(),
		"deconstruct_ecosystem_health": get_deconstruct_ecosystem_health(),
		"salvage_governance": get_salvage_governance(),
		"demolition_maturity_index": get_demolition_maturity_index(),
	}

func get_deconstruct_ecosystem_health() -> float:
	var salvage := get_salvage_value_assessment()
	var s_val: float = 90.0 if salvage == "Valuable" else (60.0 if salvage == "Moderate" else 25.0)
	var impact := get_demolition_impact()
	var urgency := get_cleanup_urgency()
	var u_val: float = 90.0 if urgency == "Low" else (60.0 if urgency == "Medium" else 30.0)
	return snapped((s_val + minf(impact, 100.0) + u_val) / 3.0, 0.1)

func get_salvage_governance() -> String:
	var eco := get_deconstruct_ecosystem_health()
	var mat := get_demolition_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif is_any_marked():
		return "Nascent"
	return "Dormant"

func get_demolition_maturity_index() -> float:
	var per_building := get_resource_per_building()
	var impact := get_demolition_impact()
	var avg_hp := get_avg_hp_marked()
	var hp_inv := maxf(100.0 - avg_hp, 0.0)
	return snapped((minf(per_building, 100.0) + minf(impact, 100.0) + hp_inv) / 3.0, 0.1)
