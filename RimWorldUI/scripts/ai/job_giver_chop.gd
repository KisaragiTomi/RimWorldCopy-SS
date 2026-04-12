class_name JobGiverChop
extends ThinkNode

## Issues a Chop job when there are plants designated for cutting.


func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.drafted or pawn.dead or pawn.downed:
		return {}
	if not pawn.is_capable_of("PlantCutting"):
		return {}
	if not ThingManager:
		return {}

	for t: Thing in ThingManager.things:
		if not (t is Plant):
			continue
		var p := t as Plant
		if not p.designated_cut:
			continue

		var dist: int = absi(pawn.grid_pos.x - p.grid_pos.x) + absi(pawn.grid_pos.y - p.grid_pos.y)
		if dist > 40:
			continue

		var job := Job.new()
		job.job_def = "Chop"
		job.target_pos = p.grid_pos
		return {"job": job}

	return {}


func get_designated_count() -> int:
	if not ThingManager:
		return 0
	var cnt: int = 0
	for t: Thing in ThingManager.things:
		if t is Plant and (t as Plant).designated_cut:
			cnt += 1
	return cnt


func get_nearest_designated(from: Vector2i) -> Vector2i:
	if not ThingManager:
		return Vector2i(-1, -1)
	var best := Vector2i(-1, -1)
	var best_dist: int = 999999
	for t: Thing in ThingManager.things:
		if t is Plant and (t as Plant).designated_cut:
			var d: int = absi(t.grid_pos.x - from.x) + absi(t.grid_pos.y - from.y)
			if d < best_dist:
				best_dist = d
				best = t.grid_pos
	return best


func get_estimated_wood_yield() -> int:
	if not ThingManager:
		return 0
	var total: int = 0
	for t: Thing in ThingManager.things:
		if t is Plant and (t as Plant).designated_cut:
			total += (t as Plant).harvest_yield
	return total


func get_mature_tree_count() -> int:
	if not ThingManager:
		return 0
	var cnt: int = 0
	for t: Thing in ThingManager.things:
		if t is Plant and (t as Plant).growth >= 1.0 and (t as Plant).harvest_yield > 0:
			cnt += 1
	return cnt


func get_avg_yield_per_tree() -> float:
	var count: int = get_designated_count()
	if count <= 0:
		return 0.0
	return snappedf(float(get_estimated_wood_yield()) / float(count), 0.1)

func get_chop_density() -> float:
	var map: MapData = GameState.get_map() if GameState else null
	if map == null or map.width * map.height == 0:
		return 0.0
	return snappedf(float(get_designated_count()) / float(map.width * map.height) * 100.0, 0.01)

func is_deforestation_risk() -> bool:
	return get_designated_count() > get_mature_tree_count() * 0.5

func get_sustainability_index() -> float:
	var mature := get_mature_tree_count()
	var designated := get_designated_count()
	if mature <= 0:
		return 0.0
	var harvest_ratio := float(designated) / float(mature)
	if harvest_ratio > 0.5:
		return snapped(maxf(0.0, 100.0 - harvest_ratio * 100.0), 0.1)
	return snapped(100.0 - harvest_ratio * 50.0, 0.1)

func get_wood_supply_outlook() -> String:
	var mature := get_mature_tree_count()
	var designated := get_designated_count()
	if mature <= 0:
		return "Barren"
	if designated <= 0:
		return "Untouched"
	if is_deforestation_risk():
		return "Endangered"
	return "Sustainable"

func get_harvest_efficiency() -> float:
	var yield_val := float(get_estimated_wood_yield())
	var designated := get_designated_count()
	if designated <= 0:
		return 0.0
	return snapped(yield_val / float(designated), 0.1)

func get_chop_summary() -> Dictionary:
	return {
		"designated": get_designated_count(),
		"estimated_wood": get_estimated_wood_yield(),
		"mature_trees": get_mature_tree_count(),
		"avg_yield": get_avg_yield_per_tree(),
		"chop_density_pct": get_chop_density(),
		"deforestation_risk": is_deforestation_risk(),
		"sustainability_index": get_sustainability_index(),
		"supply_outlook": get_wood_supply_outlook(),
		"harvest_efficiency": get_harvest_efficiency(),
		"forestry_ecosystem_health": get_forestry_ecosystem_health(),
		"timber_governance": get_timber_governance(),
		"woodcraft_maturity_index": get_woodcraft_maturity_index(),
	}

func get_forestry_ecosystem_health() -> float:
	var sustain := get_sustainability_index()
	var outlook := get_wood_supply_outlook()
	var o_val: float = 90.0 if outlook == "Sustainable" else (65.0 if outlook == "Adequate" else (35.0 if outlook == "Declining" else 15.0))
	var eff := get_harvest_efficiency()
	return snapped((minf(sustain, 100.0) + o_val + minf(eff, 100.0)) / 3.0, 0.1)

func get_timber_governance() -> String:
	var eco := get_forestry_ecosystem_health()
	var mat := get_woodcraft_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_designated_count() > 0:
		return "Nascent"
	return "Dormant"

func get_woodcraft_maturity_index() -> float:
	var mature := minf(float(get_mature_tree_count()) * 5.0, 100.0)
	var density := get_chop_density()
	var sustain := minf(get_sustainability_index(), 100.0)
	return snapped((mature + density + sustain) / 3.0, 0.1)
