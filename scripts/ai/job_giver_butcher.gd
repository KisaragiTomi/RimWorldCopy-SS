class_name JobGiverButcher
extends ThinkNode

## Issues a Butcher job when there are corpses or raw animal products to process.


func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.drafted or pawn.dead or pawn.downed:
		return {}
	if not pawn.is_capable_of("Cooking"):
		return {}
	if not ThingManager:
		return {}

	var best_item: Item = null
	var best_dist: int = 999
	for t: Thing in ThingManager.things:
		if not (t is Item):
			continue
		var item := t as Item
		if item.state != Thing.ThingState.SPAWNED:
			continue
		if item.def_name != "Corpse" and item.def_name != "AnimalCorpse":
			continue
		var dist: int = absi(pawn.grid_pos.x - item.grid_pos.x) + absi(pawn.grid_pos.y - item.grid_pos.y)
		if dist > 40:
			continue
		if dist < best_dist:
			best_dist = dist
			best_item = item

	if best_item == null:
		return {}

	var bench := _find_butcher_table(pawn)
	var target := bench.grid_pos if bench else best_item.grid_pos

	var job := Job.new()
	job.job_def = "Butcher"
	job.target_pos = best_item.grid_pos
	job.meta_data["corpse_type"] = best_item.def_name
	return {"job": job}


func get_butcherable_count() -> int:
	if not ThingManager:
		return 0
	var cnt: int = 0
	for t: Thing in ThingManager.things:
		if t is Item and t.state == Thing.ThingState.SPAWNED:
			if t.def_name in ["Corpse", "AnimalCorpse"]:
				cnt += 1
	return cnt


func has_butcher_table() -> bool:
	if not ThingManager:
		return false
	for t: Thing in ThingManager.things:
		if t is Building and t.def_name == "ButcherTable":
			if (t as Building).build_state == Building.BuildState.COMPLETE:
				return true
	return false


func get_animal_corpse_count() -> int:
	if not ThingManager:
		return 0
	var cnt: int = 0
	for t: Thing in ThingManager.things:
		if t is Item and t.state == Thing.ThingState.SPAWNED and t.def_name == "AnimalCorpse":
			cnt += 1
	return cnt


func _find_butcher_table(p: Pawn) -> Building:
	if not ThingManager:
		return null
	for t: Thing in ThingManager.things:
		if t is Building and t.def_name == "ButcherTable":
			if (t as Building).build_state == Building.BuildState.COMPLETE:
				return t as Building
	return null


func get_human_corpse_count() -> int:
	if not ThingManager:
		return 0
	var cnt: int = 0
	for t: Thing in ThingManager.things:
		if t is Item and t.state == Thing.ThingState.SPAWNED and t.def_name == "Corpse":
			cnt += 1
	return cnt


func get_animal_corpse_ratio() -> float:
	var total: int = get_butcherable_count()
	if total <= 0:
		return 0.0
	return snappedf(float(get_animal_corpse_count()) / float(total) * 100.0, 0.1)

func get_butcher_readiness() -> String:
	if not has_butcher_table():
		return "NoTable"
	if get_butcherable_count() == 0:
		return "Idle"
	return "Ready"

func get_corpse_backlog() -> String:
	var count: int = get_butcherable_count()
	if count == 0:
		return "Clear"
	elif count <= 3:
		return "Low"
	elif count <= 8:
		return "Moderate"
	return "High"

func get_processing_efficiency() -> float:
	var butcherable := get_butcherable_count()
	if butcherable <= 0:
		return 100.0
	if not has_butcher_table():
		return 0.0
	return snapped(maxf(100.0 - float(butcherable) * 10.0, 0.0), 0.1)

func get_meat_pipeline() -> String:
	var animal := get_animal_corpse_count()
	if animal >= 5:
		return "Abundant"
	elif animal >= 2:
		return "Steady"
	elif animal >= 1:
		return "Trickle"
	return "Empty"

func get_waste_risk() -> String:
	var human := get_human_corpse_count()
	var total := get_butcherable_count()
	if human > 3:
		return "High"
	elif total > 8:
		return "Overflow"
	elif total > 3:
		return "Moderate"
	return "Low"

func get_butcher_summary() -> Dictionary:
	return {
		"butcherable": get_butcherable_count(),
		"animal_corpses": get_animal_corpse_count(),
		"human_corpses": get_human_corpse_count(),
		"has_table": has_butcher_table(),
		"animal_ratio_pct": get_animal_corpse_ratio(),
		"readiness": get_butcher_readiness(),
		"backlog": get_corpse_backlog(),
		"processing_efficiency": get_processing_efficiency(),
		"meat_pipeline": get_meat_pipeline(),
		"waste_risk": get_waste_risk(),
		"butcher_ecosystem_health": get_butcher_ecosystem_health(),
		"carcass_governance": get_carcass_governance(),
		"processing_maturity_index": get_processing_maturity_index(),
	}

func get_butcher_ecosystem_health() -> float:
	var eff := get_processing_efficiency()
	var pipeline := get_meat_pipeline()
	var p_val: float = 90.0 if pipeline == "Abundant" else (65.0 if pipeline == "Steady" else (35.0 if pipeline == "Sparse" else 15.0))
	var waste := get_waste_risk()
	var w_val: float = 90.0 if waste == "Low" else (60.0 if waste == "Moderate" else 25.0)
	return snapped((eff + p_val + w_val) / 3.0, 0.1)

func get_carcass_governance() -> String:
	var eco := get_butcher_ecosystem_health()
	var mat := get_processing_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif has_butcher_table():
		return "Nascent"
	return "Dormant"

func get_processing_maturity_index() -> float:
	var eff := get_processing_efficiency()
	var animal_ratio := get_animal_corpse_ratio()
	var table_ready: float = 80.0 if has_butcher_table() else 20.0
	return snapped((eff + animal_ratio + table_ready) / 3.0, 0.1)
