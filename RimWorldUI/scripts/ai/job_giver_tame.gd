class_name JobGiverTame
extends ThinkNode

## Issues a Tame job when there are untamed animals within range.
## Requires Animals skill >= 2 and Handling capability. Checks food availability.

const TAME_FOOD_DEFS: PackedStringArray = ["RawFood", "Rice", "Corn", "Meat"]
const MAX_TAME_RANGE := 50

func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.drafted or pawn.dead or pawn.downed:
		return {}
	if not pawn.is_capable_of("Handling"):
		return {}
	var skill_level: int = pawn.get_skill_level("Animals")
	if skill_level < 2:
		return {}
	if not AnimalManager:
		return {}
	if not _has_tame_food():
		return {}

	var best_animal: Animal = null
	var best_score: float = -999.0
	for a: Animal in AnimalManager.animals:
		if a.dead or a.tamed:
			continue
		var threat: String = a.get_tame_difficulty()
		if threat == "Predator" or threat == "Extreme":
			if skill_level < 8:
				continue
		elif threat == "Hard":
			if skill_level < 5:
				continue
		var dist: int = absi(a.grid_pos.x - pawn.grid_pos.x) + absi(a.grid_pos.y - pawn.grid_pos.y)
		if dist > MAX_TAME_RANGE:
			continue
		var score: float = _score_animal(a, dist, skill_level)
		if score > best_score:
			best_score = score
			best_animal = a

	if best_animal == null:
		return {}

	var j := Job.new("Tame", best_animal.grid_pos)
	j.meta_data["animal_id"] = best_animal.id
	return {"job": j, "source": self}


const USEFUL_SPECIES: PackedStringArray = ["Muffalo", "Husky", "Horse", "Alpaca", "Cow", "Chicken"]

func _score_animal(a: Animal, dist: int, skill: int) -> float:
	var score: float = 0.0
	score -= float(dist) * 0.5
	if a.species in USEFUL_SPECIES:
		score += 20.0
	score += a.meat_yield * 0.1
	var difficulty: String = a.get_tame_difficulty()
	if difficulty == "Easy":
		score += 10.0
	elif difficulty == "Medium":
		score += 5.0
	elif difficulty == "Hard":
		score -= 5.0
	elif difficulty == "Extreme" or difficulty == "Predator":
		score -= 15.0
	return score


func get_tameable_count() -> int:
	if not AnimalManager:
		return 0
	var cnt: int = 0
	for a: Animal in AnimalManager.animals:
		if not a.dead and not a.tamed:
			cnt += 1
	return cnt


func get_easiest_target() -> Dictionary:
	if not AnimalManager:
		return {}
	var best: Animal = null
	var best_score: float = -999.0
	for a: Animal in AnimalManager.animals:
		if a.dead or a.tamed:
			continue
		var diff: String = a.get_tame_difficulty()
		var s: float = 0.0
		if diff == "Easy":
			s = 30.0
		elif diff == "Medium":
			s = 15.0
		elif diff == "Hard":
			s = 0.0
		else:
			s = -20.0
		if a.species in USEFUL_SPECIES:
			s += 10.0
		if s > best_score:
			best_score = s
			best = a
	if best == null:
		return {}
	return {"species": best.species, "difficulty": best.get_tame_difficulty(), "score": best_score}


func get_tame_food_count() -> int:
	if not ThingManager:
		return 0
	var total: int = 0
	for t: Thing in ThingManager.things:
		if t is Item:
			var item := t as Item
			if item.state == Thing.ThingState.SPAWNED and item.def_name in TAME_FOOD_DEFS:
				total += item.stack_count
	return total


func _has_tame_food() -> bool:
	if not ThingManager:
		return false
	for t: Thing in ThingManager.things:
		if t is Item:
			var item := t as Item
			if item.state == Thing.ThingState.SPAWNED and item.def_name in TAME_FOOD_DEFS:
				if item.stack_count >= 1:
					return true
	return false

func get_useful_species_count() -> int:
	return USEFUL_SPECIES.size()

func get_tame_range() -> int:
	return MAX_TAME_RANGE

func get_tame_food_type_count() -> int:
	return TAME_FOOD_DEFS.size()

func get_easiest_tameable_species() -> String:
	if not AnimalManager:
		return ""
	var best: String = ""
	var best_wild: float = 999.0
	for a: Animal in AnimalManager.animals:
		if a.tamed:
			continue
		var wild: float = a.wildness if "wildness" in a else 0.5
		if wild < best_wild:
			best_wild = wild
			best = a.species
	return best


func has_sufficient_food() -> bool:
	return get_tame_food_count() >= 3


func get_tameable_species_diversity() -> int:
	if not AnimalManager:
		return 0
	var sp: Dictionary = {}
	for a: Animal in AnimalManager.animals:
		if not a.tamed:
			sp[a.species] = true
	return sp.size()


func get_taming_efficiency() -> float:
	var tameable := get_tameable_count()
	var food := get_tame_food_count()
	if tameable <= 0:
		return 0.0
	var food_ratio := minf(float(food) / float(tameable), 3.0) / 3.0
	var diversity := float(get_tameable_species_diversity()) / maxf(float(tameable), 1.0)
	return snapped((food_ratio * 0.6 + diversity * 0.4) * 100.0, 0.1)

func get_domestication_outlook() -> String:
	var eff := get_taming_efficiency()
	var food_ok := has_sufficient_food()
	if eff >= 60.0 and food_ok:
		return "Favorable"
	elif eff >= 30.0:
		return "Possible"
	elif get_tameable_count() > 0:
		return "Challenging"
	return "None Available"

func get_herd_growth_potential() -> float:
	var useful := float(get_useful_species_count())
	var tameable := float(get_tameable_count())
	return snapped(useful * tameable / 10.0, 0.1)

func get_tame_summary() -> Dictionary:
	return {
		"tameable": get_tameable_count(),
		"tame_food_available": get_tame_food_count(),
		"useful_species": get_useful_species_count(),
		"max_range": MAX_TAME_RANGE,
		"easiest_species": get_easiest_tameable_species(),
		"food_sufficient": has_sufficient_food(),
		"tameable_diversity": get_tameable_species_diversity(),
		"taming_efficiency": get_taming_efficiency(),
		"domestication_outlook": get_domestication_outlook(),
		"herd_growth_potential": get_herd_growth_potential(),
		"tame_ecosystem_health": get_tame_ecosystem_health(),
		"animal_governance": get_animal_governance(),
		"husbandry_maturity_index": get_husbandry_maturity_index(),
	}

func get_tame_ecosystem_health() -> float:
	var eff := get_taming_efficiency()
	var outlook := get_domestication_outlook()
	var o_val: float = 90.0 if outlook == "Favorable" else (60.0 if outlook == "Possible" else 25.0)
	var growth := get_herd_growth_potential()
	return snapped((eff + o_val + minf(growth, 100.0)) / 3.0, 0.1)

func get_animal_governance() -> String:
	var eco := get_tame_ecosystem_health()
	var mat := get_husbandry_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_tameable_count() > 0:
		return "Nascent"
	return "Dormant"

func get_husbandry_maturity_index() -> float:
	var diversity := float(get_tameable_species_diversity())
	var growth := get_herd_growth_potential()
	var food_ok := 80.0 if has_sufficient_food() else 30.0
	return snapped((minf(diversity * 10.0, 100.0) + minf(growth, 100.0) + food_ok) / 3.0, 0.1)
