extends Node

const ANIMAL_WILDNESS: Dictionary = {
	"Rabbit": {"wildness": 0.85, "attack_chance": 0.0, "tame_difficulty": 0.2},
	"Deer": {"wildness": 0.9, "attack_chance": 0.0, "tame_difficulty": 0.3},
	"Squirrel": {"wildness": 0.8, "attack_chance": 0.0, "tame_difficulty": 0.15},
	"Chicken": {"wildness": 0.3, "attack_chance": 0.0, "tame_difficulty": 0.1},
	"Cow": {"wildness": 0.2, "attack_chance": 0.05, "tame_difficulty": 0.1},
	"Muffalo": {"wildness": 0.4, "attack_chance": 0.1, "tame_difficulty": 0.25},
	"Wolf": {"wildness": 0.85, "attack_chance": 0.5, "tame_difficulty": 0.6},
	"Bear": {"wildness": 0.9, "attack_chance": 0.4, "tame_difficulty": 0.7},
	"Boar": {"wildness": 0.6, "attack_chance": 0.3, "tame_difficulty": 0.4},
	"Elephant": {"wildness": 0.75, "attack_chance": 0.2, "tame_difficulty": 0.5},
	"Panther": {"wildness": 0.95, "attack_chance": 0.6, "tame_difficulty": 0.8},
	"Cobra": {"wildness": 0.99, "attack_chance": 0.7, "tame_difficulty": 0.95},
}


func get_wildness(species: String) -> float:
	var data: Dictionary = ANIMAL_WILDNESS.get(species, {})
	return float(data.get("wildness", 0.5))


func get_attack_chance(species: String) -> float:
	var data: Dictionary = ANIMAL_WILDNESS.get(species, {})
	return float(data.get("attack_chance", 0.0))


func get_tame_difficulty(species: String) -> float:
	var data: Dictionary = ANIMAL_WILDNESS.get(species, {})
	return float(data.get("tame_difficulty", 0.5))


func will_attack_on_approach(species: String) -> bool:
	return randf() < get_attack_chance(species)


func calc_tame_chance(species: String, animals_skill: int) -> float:
	var difficulty: float = get_tame_difficulty(species)
	var skill_factor: float = float(animals_skill) * 0.05
	var chance: float = clampf(0.3 + skill_factor - difficulty, 0.02, 0.95)
	return snappedf(chance, 0.01)


func get_sorted_by_tame_difficulty() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for species: String in ANIMAL_WILDNESS:
		var data: Dictionary = ANIMAL_WILDNESS[species]
		result.append({"species": species, "difficulty": data.tame_difficulty})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.difficulty < b.difficulty
	)
	return result


func get_predators() -> Array[String]:
	var result: Array[String] = []
	for species: String in ANIMAL_WILDNESS:
		if ANIMAL_WILDNESS[species].attack_chance >= 0.3:
			result.append(species)
	return result


func get_easiest_to_tame() -> String:
	var best: String = ""
	var best_diff: float = 999.0
	for species: String in ANIMAL_WILDNESS:
		if ANIMAL_WILDNESS[species].tame_difficulty < best_diff:
			best_diff = ANIMAL_WILDNESS[species].tame_difficulty
			best = species
	return best


func get_hardest_to_tame() -> String:
	var worst: String = ""
	var worst_diff: float = -1.0
	for species: String in ANIMAL_WILDNESS:
		if ANIMAL_WILDNESS[species].tame_difficulty > worst_diff:
			worst_diff = ANIMAL_WILDNESS[species].tame_difficulty
			worst = species
	return worst


func get_avg_wildness() -> float:
	if ANIMAL_WILDNESS.is_empty():
		return 0.0
	var total: float = 0.0
	for species: String in ANIMAL_WILDNESS:
		total += ANIMAL_WILDNESS[species].wildness
	return snappedf(total / float(ANIMAL_WILDNESS.size()), 0.01)


func get_predator_count() -> int:
	return get_predators().size()


func get_taming_difficulty() -> String:
	var avg: float = get_avg_wildness()
	if avg >= 0.7:
		return "Very Hard"
	elif avg >= 0.4:
		return "Moderate"
	elif avg > 0.0:
		return "Easy"
	return "None"

func get_ecosystem_danger() -> String:
	var pred_pct: float = float(get_predator_count()) / maxf(float(ANIMAL_WILDNESS.size()), 1.0)
	if pred_pct >= 0.4:
		return "Dangerous"
	elif pred_pct >= 0.2:
		return "Moderate"
	elif pred_pct > 0.0:
		return "Safe"
	return "Harmless"

func get_domestication_potential() -> float:
	var tameable: int = 0
	for species: String in ANIMAL_WILDNESS:
		if ANIMAL_WILDNESS[species].wildness < 0.5:
			tameable += 1
	if ANIMAL_WILDNESS.is_empty():
		return 0.0
	return snappedf(float(tameable) / float(ANIMAL_WILDNESS.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"species_count": ANIMAL_WILDNESS.size(),
		"predators": get_predators(),
		"predator_count": get_predator_count(),
		"easiest_tame": get_easiest_to_tame(),
		"hardest_tame": get_hardest_to_tame(),
		"avg_wildness": get_avg_wildness(),
		"tame_count": ANIMAL_WILDNESS.size() - get_predator_count(),
		"predator_pct": snappedf(float(get_predator_count()) / maxf(float(ANIMAL_WILDNESS.size()), 1.0) * 100.0, 0.1),
		"taming_difficulty": get_taming_difficulty(),
		"ecosystem_danger": get_ecosystem_danger(),
		"domestication_potential_pct": get_domestication_potential(),
		"domestication_feasibility": get_domestication_feasibility(),
		"ecological_risk": get_ecological_risk(),
		"husbandry_potential": get_husbandry_potential(),
		"fauna_management_index": get_fauna_management_index(),
		"species_coexistence": get_species_coexistence(),
		"wildlife_governance": get_wildlife_governance(),
	}

func get_fauna_management_index() -> float:
	var potential := get_domestication_potential()
	var danger := get_ecosystem_danger()
	var base: float = potential
	if danger in ["High", "Extreme"]:
		base *= 0.5
	return snapped(base, 0.1)

func get_species_coexistence() -> String:
	var predator_ratio := float(get_predator_count()) / maxf(float(ANIMAL_WILDNESS.size()), 1.0)
	if predator_ratio < 0.2:
		return "Harmonious"
	elif predator_ratio < 0.4:
		return "Balanced"
	return "Hostile"

func get_wildlife_governance() -> float:
	var feasibility := get_domestication_feasibility()
	var avg := get_avg_wildness()
	var base: float = (1.0 - avg) * 100.0
	if feasibility == "Highly Feasible":
		base *= 1.3
	return snapped(clampf(base, 0.0, 100.0), 0.1)

func get_domestication_feasibility() -> String:
	var potential := get_domestication_potential()
	var difficulty := get_taming_difficulty()
	if potential >= 60.0 and difficulty in ["Easy", "Moderate"]:
		return "Highly Feasible"
	elif potential >= 30.0:
		return "Feasible"
	return "Challenging"

func get_ecological_risk() -> String:
	var danger := get_ecosystem_danger()
	var pred_pct := float(get_predator_count()) / maxf(float(ANIMAL_WILDNESS.size()), 1.0) * 100.0
	if danger in ["Dangerous", "Hostile"] or pred_pct >= 40.0:
		return "High"
	elif pred_pct >= 20.0:
		return "Moderate"
	return "Low"

func get_husbandry_potential() -> String:
	var tame_count := ANIMAL_WILDNESS.size() - get_predator_count()
	if tame_count >= 5:
		return "Excellent"
	elif tame_count >= 3:
		return "Good"
	elif tame_count > 0:
		return "Limited"
	return "None"
