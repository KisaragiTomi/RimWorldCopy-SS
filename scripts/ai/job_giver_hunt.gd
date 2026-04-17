class_name JobGiverHunt
extends ThinkNode

## Issues a Hunt job to kill a wild animal for meat.

const HUNT_RANGE := 50
const PREFERRED_SPECIES := ["Rabbit", "Deer", "Squirrel", "Turkey", "Ibex"]
const LARGE_SPECIES := ["Elk", "Muffalo", "Alphabeaver"]


func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.drafted or pawn.dead or pawn.downed:
		return {}
	if not pawn.is_capable_of("Hunting"):
		return {}
	if not AnimalManager:
		return {}

	var shoot_skill: int = pawn.get_skill_level("Shooting")

	var reserved := _get_reserved_animal_ids()
	var best_animal: Animal = null
	var best_score: float = -1.0
	for a: Animal in AnimalManager.animals:
		if a.dead or a.tamed:
			continue
		if reserved.has(a.id):
			continue
		var threat: String = a.get_tame_difficulty()
		if threat == "Extreme":
			continue
		if threat == "Predator" and shoot_skill < 8:
			continue
		if a.species in LARGE_SPECIES and shoot_skill < 4:
			continue
		var dist: int = absi(a.grid_pos.x - pawn.grid_pos.x) + absi(a.grid_pos.y - pawn.grid_pos.y)
		if dist > HUNT_RANGE:
			continue
		var score: float = _score_animal(a, dist, shoot_skill)
		if score > best_score:
			best_score = score
			best_animal = a

	if best_animal == null:
		return {}

	var job := Job.new()
	job.job_def = "Hunt"
	job.target_pos = best_animal.grid_pos
	job.meta_data["animal_id"] = best_animal.id
	return {"job": job}


func _get_reserved_animal_ids() -> Dictionary:
	var reserved := {}
	if not PawnManager:
		return reserved
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed:
			continue
		if p.current_job_name == "Hunt" and PawnManager._drivers.has(p.id):
			var driver = PawnManager._drivers[p.id]
			if driver and driver.job and driver.job.meta_data.has("animal_id"):
				reserved[driver.job.meta_data["animal_id"]] = true
	return reserved


func get_huntable_count() -> int:
	if not AnimalManager:
		return 0
	var cnt: int = 0
	for a: Animal in AnimalManager.animals:
		if not a.dead and not a.tamed and a.get_tame_difficulty() != "Extreme":
			cnt += 1
	return cnt


func get_best_hunt_target() -> Dictionary:
	if not AnimalManager:
		return {}
	var best: Animal = null
	var best_meat: float = 0.0
	for a: Animal in AnimalManager.animals:
		if a.dead or a.tamed:
			continue
		if a.get_tame_difficulty() == "Extreme":
			continue
		var data: Dictionary = Animal.SPECIES_DATA.get(a.species, {}) as Dictionary
		var meat: float = float(data.get("meat_yield", 10))
		if meat > best_meat:
			best_meat = meat
			best = a
	if best == null:
		return {}
	return {"species": best.species, "meat_yield": best_meat}


func get_estimated_meat_total() -> float:
	if not AnimalManager:
		return 0.0
	var total: float = 0.0
	for a: Animal in AnimalManager.animals:
		if a.dead or a.tamed:
			continue
		var data: Dictionary = Animal.SPECIES_DATA.get(a.species, {}) as Dictionary
		total += float(data.get("meat_yield", 10))
	return total


func _score_animal(a: Animal, dist: int, skill: int) -> float:
	var data: Dictionary = Animal.SPECIES_DATA.get(a.species, {}) as Dictionary
	var meat: float = float(data.get("meat_yield", 10))
	var danger: float = 0.0
	if a.get_tame_difficulty() == "Predator":
		danger = 20.0
	var preferred_bonus: float = 10.0 if a.species in PREFERRED_SPECIES else 0.0
	return meat + preferred_bonus - float(dist) * 0.5 - danger + float(skill) * 0.5

func get_predator_count() -> int:
	if not AnimalManager:
		return 0
	var count: int = 0
	for a: Animal in AnimalManager.animals:
		if not a.dead and a.get_tame_difficulty() == "Predator":
			count += 1
	return count

func get_preferred_species_count() -> int:
	return PREFERRED_SPECIES.size()

func get_safe_huntable_count() -> int:
	if not AnimalManager:
		return 0
	var count: int = 0
	for a: Animal in AnimalManager.animals:
		if a.dead or a.tamed:
			continue
		if a.get_tame_difficulty() != "Predator":
			count += 1
	return count


func get_hunt_danger_ratio() -> float:
	var total: int = get_huntable_count()
	if total <= 0:
		return 0.0
	return snappedf(float(get_predator_count()) / float(total) * 100.0, 0.1)


func get_avg_meat_per_animal() -> float:
	var count: int = get_huntable_count()
	if count <= 0:
		return 0.0
	return snappedf(get_estimated_meat_total() / float(count), 0.1)


func get_food_security_from_hunting() -> float:
	var meat := get_estimated_meat_total()
	var safe := float(get_safe_huntable_count())
	return snapped(meat * (safe / maxf(float(get_huntable_count()), 1.0)), 0.1)

func get_hunting_risk_reward() -> String:
	var danger := get_hunt_danger_ratio()
	var meat := get_avg_meat_per_animal()
	if danger <= 10.0 and meat >= 50.0:
		return "Excellent"
	elif danger <= 25.0 and meat >= 30.0:
		return "Good"
	elif danger <= 40.0:
		return "Risky"
	return "Dangerous"

func get_sustainable_yield() -> float:
	var safe := get_safe_huntable_count()
	var avg_meat := get_avg_meat_per_animal()
	return snapped(float(safe) * avg_meat * 0.5, 0.1)

func get_hunt_summary() -> Dictionary:
	return {
		"huntable": get_huntable_count(),
		"total_meat": snappedf(get_estimated_meat_total(), 0.1),
		"predators": get_predator_count(),
		"preferred_species": get_preferred_species_count(),
		"safe_huntable": get_safe_huntable_count(),
		"danger_ratio_pct": get_hunt_danger_ratio(),
		"avg_meat_per_animal": get_avg_meat_per_animal(),
		"food_security": get_food_security_from_hunting(),
		"risk_reward": get_hunting_risk_reward(),
		"sustainable_yield": get_sustainable_yield(),
		"hunt_ecosystem_health": get_hunt_ecosystem_health(),
		"wildlife_governance": get_wildlife_governance(),
		"predation_maturity_index": get_predation_maturity_index(),
	}

func get_hunt_ecosystem_health() -> float:
	var food := get_food_security_from_hunting()
	var rr := get_hunting_risk_reward()
	var rr_val: float = 90.0 if rr == "Excellent" else (65.0 if rr == "Good" else (40.0 if rr == "Fair" else 15.0))
	var yield_f := get_sustainable_yield()
	return snapped((minf(food, 100.0) + rr_val + minf(yield_f, 100.0)) / 3.0, 0.1)

func get_wildlife_governance() -> String:
	var eco := get_hunt_ecosystem_health()
	var mat := get_predation_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_huntable_count() > 0:
		return "Nascent"
	return "Dormant"

func get_predation_maturity_index() -> float:
	var danger := get_hunt_danger_ratio()
	var safety := maxf(100.0 - danger, 0.0)
	var safe_count := minf(float(get_safe_huntable_count()) * 10.0, 100.0)
	var avg_meat := minf(get_avg_meat_per_animal(), 100.0)
	return snapped((safety + safe_count + avg_meat) / 3.0, 0.1)
