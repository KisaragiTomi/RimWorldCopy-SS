class_name JobGiverRepair
extends ThinkNode

## Issues a Repair job for damaged buildings.


func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.drafted or pawn.dead or pawn.downed:
		return {}
	if not pawn.is_capable_of("Construction"):
		return {}
	if not ThingManager:
		return {}

	var best_building: Building = null
	var best_score: float = -999.0

	for t: Thing in ThingManager.things:
		if not (t is Building):
			continue
		var b := t as Building
		if b.build_state != Building.BuildState.COMPLETE:
			continue
		if b.hit_points >= b.max_hit_points:
			continue
		var damage_pct: float = 1.0 - float(b.hit_points) / float(b.max_hit_points)
		if damage_pct < 0.1:
			continue

		var dist: int = absi(pawn.grid_pos.x - b.grid_pos.x) + absi(pawn.grid_pos.y - b.grid_pos.y)
		if dist > 50:
			continue
		var score: float = damage_pct * 50.0 - float(dist) * 0.5
		if b.def_name in ["MiniTurret", "Battery", "SolarGenerator", "WoodFiredGenerator"]:
			score += 20.0
		if score > best_score:
			best_score = score
			best_building = b

	if best_building == null:
		return {}

	var job := Job.new()
	job.job_def = "Repair"
	job.target_pos = best_building.grid_pos
	return {"job": job}


func get_damaged_building_count() -> int:
	if not ThingManager:
		return 0
	var cnt: int = 0
	for t: Thing in ThingManager.things:
		if t is Building:
			var b := t as Building
			if b.build_state == Building.BuildState.COMPLETE and b.hit_points < b.max_hit_points:
				cnt += 1
	return cnt


func get_most_damaged_building() -> Dictionary:
	if not ThingManager:
		return {}
	var worst: Building = null
	var worst_pct: float = 1.0
	for t: Thing in ThingManager.things:
		if t is Building:
			var b := t as Building
			if b.build_state != Building.BuildState.COMPLETE or b.max_hit_points == 0:
				continue
			var pct: float = float(b.hit_points) / float(b.max_hit_points)
			if pct < worst_pct:
				worst_pct = pct
				worst = b
	if worst == null:
		return {}
	return {"name": worst.label, "hp_pct": snappedf(worst_pct * 100.0, 0.1)}


func get_total_repair_needed() -> int:
	if not ThingManager:
		return 0
	var total: int = 0
	for t: Thing in ThingManager.things:
		if t is Building:
			var b := t as Building
			if b.build_state == Building.BuildState.COMPLETE:
				total += maxi(0, b.max_hit_points - b.hit_points)
	return total


func get_avg_building_health_pct() -> float:
	if not ThingManager:
		return 100.0
	var total_pct: float = 0.0
	var cnt: int = 0
	for t: Thing in ThingManager.things:
		if t is Building:
			var b := t as Building
			if b.build_state == Building.BuildState.COMPLETE and b.max_hit_points > 0:
				total_pct += float(b.hit_points) / float(b.max_hit_points)
				cnt += 1
	if cnt == 0:
		return 100.0
	return total_pct / float(cnt) * 100.0


func get_critical_damage_count() -> int:
	if not ThingManager:
		return 0
	var cnt: int = 0
	for t: Thing in ThingManager.things:
		if t is Building:
			var b := t as Building
			if b.build_state == Building.BuildState.COMPLETE and b.max_hit_points > 0:
				if float(b.hit_points) / float(b.max_hit_points) < 0.25:
					cnt += 1
	return cnt

func get_repair_per_building() -> float:
	var damaged: int = get_damaged_building_count()
	if damaged <= 0:
		return 0.0
	return snappedf(float(get_total_repair_needed()) / float(damaged), 0.1)

func get_repair_urgency() -> String:
	var critical: int = get_critical_damage_count()
	if critical >= 3:
		return "Emergency"
	elif critical >= 1:
		return "High"
	elif get_damaged_building_count() > 0:
		return "Normal"
	return "None"

func get_infrastructure_decay_rate() -> float:
	var total := get_damaged_building_count()
	var critical := get_critical_damage_count()
	if total <= 0:
		return 0.0
	return snapped(float(critical) / float(total) * 100.0, 0.1)

func get_repair_workload() -> String:
	var repair := get_total_repair_needed()
	if repair <= 0:
		return "None"
	elif repair < 100:
		return "Light"
	elif repair < 500:
		return "Moderate"
	return "Heavy"

func get_structural_health_trend() -> String:
	var avg := get_avg_building_health_pct()
	if avg >= 90.0:
		return "Excellent"
	elif avg >= 70.0:
		return "Good"
	elif avg >= 50.0:
		return "Deteriorating"
	return "Critical"

func get_repair_summary() -> Dictionary:
	return {
		"damaged": get_damaged_building_count(),
		"total_repair": get_total_repair_needed(),
		"most_damaged": get_most_damaged_building(),
		"avg_health_pct": snappedf(get_avg_building_health_pct(), 0.1),
		"critical_count": get_critical_damage_count(),
		"repair_per_building": get_repair_per_building(),
		"urgency": get_repair_urgency(),
		"decay_rate_pct": get_infrastructure_decay_rate(),
		"workload": get_repair_workload(),
		"health_trend": get_structural_health_trend(),
		"repair_ecosystem_health": get_repair_ecosystem_health(),
		"maintenance_governance": get_maintenance_governance(),
		"infrastructure_maturity_index": get_infrastructure_maturity_index(),
	}

func get_repair_ecosystem_health() -> float:
	var decay := get_infrastructure_decay_rate()
	var decay_inv := maxf(100.0 - decay, 0.0)
	var workload := get_repair_workload()
	var w_val: float = 90.0 if workload == "None" else (70.0 if workload == "Light" else (40.0 if workload == "Moderate" else 15.0))
	var trend := get_structural_health_trend()
	var t_val: float = 90.0 if trend == "Excellent" else (65.0 if trend == "Good" else (35.0 if trend == "Declining" else 15.0))
	return snapped((decay_inv + w_val + t_val) / 3.0, 0.1)

func get_maintenance_governance() -> String:
	var eco := get_repair_ecosystem_health()
	var mat := get_infrastructure_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_damaged_building_count() > 0:
		return "Nascent"
	return "Dormant"

func get_infrastructure_maturity_index() -> float:
	var avg_health := get_avg_building_health_pct()
	var decay_inv := maxf(100.0 - get_infrastructure_decay_rate(), 0.0)
	var repair := get_repair_per_building()
	var repair_norm := maxf(100.0 - minf(repair, 100.0), 0.0)
	return snapped((avg_health + decay_inv + repair_norm) / 3.0, 0.1)
