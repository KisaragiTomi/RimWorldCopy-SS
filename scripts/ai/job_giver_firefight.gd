class_name JobGiverFirefight
extends ThinkNode

## Highest priority: extinguish nearby fires.
## Prioritizes fires near buildings and colonists.

const MAX_RANGE := 60


func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.dead or pawn.downed:
		return {}
	if not FireManager or FireManager.fires.is_empty():
		return {}

	var best_pos := Vector2i(-1, -1)
	var best_score: float = -1.0
	for pos: Vector2i in FireManager.fires:
		var dist: int = absi(pos.x - pawn.grid_pos.x) + absi(pos.y - pawn.grid_pos.y)
		if dist > MAX_RANGE:
			continue
		var score: float = _score_fire(pos, dist)
		if score > best_score:
			best_score = score
			best_pos = pos

	if best_pos.x < 0:
		return {}

	var job := Job.new()
	job.job_def = "Firefight"
	job.target_pos = best_pos
	return {"job": job}


func get_fire_count() -> int:
	if not FireManager:
		return 0
	return FireManager.fires.size()


func get_critical_fire_count() -> int:
	if not FireManager:
		return 0
	var cnt: int = 0
	for pos: Vector2i in FireManager.fires:
		if FireManager.fires[pos].get("intensity", 0.0) > 0.7:
			cnt += 1
	return cnt


func is_emergency() -> bool:
	return get_fire_count() >= 3 or get_critical_fire_count() >= 1


func _score_fire(pos: Vector2i, dist: int) -> float:
	var score: float = 100.0 - float(dist)
	if ThingManager:
		for thing: Thing in ThingManager.get_things_at(pos):
			if thing is Building:
				score += 50.0
				break
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.dead:
				continue
			var pd: int = absi(p.grid_pos.x - pos.x) + absi(p.grid_pos.y - pos.y)
			if pd <= 2:
				score += 80.0
				break
	return score


func get_building_adjacent_fire_count() -> int:
	if not FireManager or not ThingManager:
		return 0
	var cnt: int = 0
	for pos: Vector2i in FireManager.fires:
		for thing: Thing in ThingManager.get_things_at(pos):
			if thing is Building:
				cnt += 1
				break
	return cnt


func get_avg_fire_distance(pawn: Pawn) -> float:
	if not FireManager or FireManager.fires.is_empty():
		return 0.0
	var total: float = 0.0
	for pos: Vector2i in FireManager.fires:
		total += float(absi(pawn.grid_pos.x - pos.x) + absi(pawn.grid_pos.y - pos.y))
	return total / float(FireManager.fires.size())


func get_containment_ratio() -> float:
	var total: int = get_fire_count()
	if total <= 0:
		return 100.0
	var critical: int = get_critical_fire_count()
	return snappedf(float(total - critical) / float(total) * 100.0, 0.1)


func get_threat_level() -> String:
	if get_fire_count() == 0:
		return "None"
	if is_emergency():
		return "Critical"
	if get_critical_fire_count() > 0:
		return "High"
	return "Moderate"


func get_building_threat_pct() -> float:
	var total: int = get_fire_count()
	if total <= 0:
		return 0.0
	return snappedf(float(get_building_adjacent_fire_count()) / float(total) * 100.0, 0.1)


func get_resource_allocation() -> float:
	if not PawnManager:
		return 0.0
	var firefighters := 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead and p.current_job_name == "Firefight":
			firefighters += 1
	var fires := get_fire_count()
	if fires <= 0:
		return 100.0
	return snapped(minf(float(firefighters) / float(fires), 3.0) / 3.0 * 100.0, 0.1)

func get_damage_mitigation_score() -> float:
	var containment := get_containment_ratio()
	var building_pct := get_building_threat_pct()
	return snapped(containment * (1.0 - building_pct / 100.0), 0.1)

func get_situation_assessment() -> String:
	var threat := get_threat_level()
	var containment := get_containment_ratio()
	if threat == "None":
		return "All Clear"
	elif containment >= 80.0 and threat != "Critical":
		return "Contained"
	elif containment >= 40.0:
		return "Battling"
	return "Losing Ground"

func get_firefight_summary() -> Dictionary:
	return {
		"fires": get_fire_count(),
		"critical": get_critical_fire_count(),
		"emergency": is_emergency(),
		"building_adjacent": get_building_adjacent_fire_count(),
		"containment_pct": get_containment_ratio(),
		"threat_level": get_threat_level(),
		"building_threat_pct": get_building_threat_pct(),
		"resource_allocation": get_resource_allocation(),
		"damage_mitigation": get_damage_mitigation_score(),
		"situation_assessment": get_situation_assessment(),
		"firefight_ecosystem_health": get_firefight_ecosystem_health(),
		"emergency_governance": get_emergency_governance(),
		"response_maturity_index": get_response_maturity_index(),
	}

func get_firefight_ecosystem_health() -> float:
	var contain := get_containment_ratio()
	var dmg := get_damage_mitigation_score()
	var alloc := get_resource_allocation()
	return snapped((contain + minf(dmg, 100.0) + minf(alloc * 10.0, 100.0)) / 3.0, 0.1)

func get_emergency_governance() -> String:
	var eco := get_firefight_ecosystem_health()
	var mat := get_response_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_fire_count() > 0:
		return "Nascent"
	return "Dormant"

func get_response_maturity_index() -> float:
	var threat := get_threat_level()
	var t_val: float = 90.0 if threat == "None" else (70.0 if threat == "Low" else (40.0 if threat == "Moderate" else 15.0))
	var assess := get_situation_assessment()
	var a_val: float = 90.0 if assess == "All Clear" else (70.0 if assess == "Under Control" else (40.0 if assess == "Manageable" else 15.0))
	var contain := get_containment_ratio()
	return snapped((t_val + a_val + contain) / 3.0, 0.1)
