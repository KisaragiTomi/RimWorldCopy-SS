extends Node

const RECIPES: Dictionary = {
	"SimpleMeal": {"research": "", "skill": "Cooking", "min_level": 0},
	"FineMeal": {"research": "", "skill": "Cooking", "min_level": 6},
	"LavishMeal": {"research": "", "skill": "Cooking", "min_level": 10},
	"Medicine": {"research": "MedicineProduction", "skill": "Medical", "min_level": 6},
	"Penoxycyline": {"research": "PenoxycylineProduction", "skill": "Medical", "min_level": 8},
	"ComponentIndustrial": {"research": "Fabrication", "skill": "Crafting", "min_level": 8},
	"Flak Vest": {"research": "FlakArmor", "skill": "Crafting", "min_level": 6},
	"Flak Helmet": {"research": "FlakArmor", "skill": "Crafting", "min_level": 6},
	"PowerArmor": {"research": "PowerArmor", "skill": "Crafting", "min_level": 12},
	"BionicLeg": {"research": "Bionics", "skill": "Crafting", "min_level": 10},
	"BionicArm": {"research": "Bionics", "skill": "Crafting", "min_level": 10},
	"Mortar": {"research": "Mortars", "skill": "Crafting", "min_level": 5},
}

var _unlocked_research: Dictionary = {}


func unlock_research(research_id: String) -> Array:
	_unlocked_research[research_id] = true
	var newly_available: Array = []
	for recipe: String in RECIPES:
		var data: Dictionary = RECIPES[recipe]
		var req: String = String(data.get("research", ""))
		if req == research_id:
			newly_available.append(recipe)
	return newly_available


func is_recipe_available(recipe_id: String) -> bool:
	if not RECIPES.has(recipe_id):
		return false
	var data: Dictionary = RECIPES[recipe_id]
	var req: String = String(data.get("research", ""))
	if req.is_empty():
		return true
	return _unlocked_research.has(req)


func get_available_recipes() -> Array:
	var available: Array = []
	for recipe: String in RECIPES:
		if is_recipe_available(recipe):
			available.append(recipe)
	return available


func get_locked_recipes() -> Array:
	var locked: Array = []
	for recipe: String in RECIPES:
		if not is_recipe_available(recipe):
			locked.append(recipe)
	return locked


func get_recipes_for_skill(skill: String) -> Array[String]:
	var result: Array[String] = []
	for recipe: String in RECIPES:
		if String(RECIPES[recipe].get("skill", "")) == skill:
			result.append(recipe)
	return result


func get_required_research_for(recipe_id: String) -> String:
	return String(RECIPES.get(recipe_id, {}).get("research", ""))


func get_unlock_percentage() -> float:
	if RECIPES.is_empty():
		return 0.0
	return snappedf(float(get_available_recipes().size()) / float(RECIPES.size()) * 100.0, 0.1)


func get_most_restrictive_recipe() -> String:
	var worst: String = ""
	var worst_reqs: int = 0
	for rid: String in RECIPES:
		var total: int = 0
		if RECIPES[rid].has("required_research"):
			total += 1
		if RECIPES[rid].has("min_skill"):
			total += int(RECIPES[rid].get("min_skill", 0))
		if total > worst_reqs:
			worst_reqs = total
			worst = rid
	return worst


func get_research_coverage() -> float:
	var total_research: Dictionary = {}
	for rid: String in RECIPES:
		var r: String = str(RECIPES[rid].get("required_research", ""))
		if not r.is_empty():
			total_research[r] = true
	if total_research.is_empty():
		return 100.0
	var unlocked: int = 0
	for r: String in total_research:
		if _unlocked_research.has(r):
			unlocked += 1
	return snappedf(float(unlocked) / float(total_research.size()) * 100.0, 0.1)


func get_unique_required_research_count() -> int:
	var research: Dictionary = {}
	for rid: String in RECIPES:
		var r: String = String(RECIPES[rid].get("research", ""))
		if not r.is_empty():
			research[r] = true
	return research.size()


func get_avg_min_level() -> float:
	if RECIPES.is_empty():
		return 0.0
	var total: int = 0
	for rid: String in RECIPES:
		total += int(RECIPES[rid].get("min_level", 0))
	return snappedf(float(total) / float(RECIPES.size()), 0.1)


func get_highest_skill_recipe() -> String:
	var best: String = ""
	var best_lvl: int = 0
	for rid: String in RECIPES:
		var lvl: int = int(RECIPES[rid].get("min_level", 0))
		if lvl > best_lvl:
			best_lvl = lvl
			best = rid
	return best


func get_tech_progress() -> String:
	var pct: float = get_unlock_percentage()
	if pct >= 90.0:
		return "Advanced"
	elif pct >= 60.0:
		return "Developed"
	elif pct >= 30.0:
		return "Emerging"
	return "Primitive"

func get_bottleneck_severity() -> float:
	if RECIPES.is_empty():
		return 0.0
	return snappedf(float(get_locked_recipes().size()) / float(RECIPES.size()) * 100.0, 0.1)

func get_skill_demand() -> String:
	var avg: float = get_avg_min_level()
	if avg >= 12.0:
		return "Expert"
	elif avg >= 8.0:
		return "Skilled"
	elif avg >= 4.0:
		return "Moderate"
	return "Basic"

func get_summary() -> Dictionary:
	return {
		"total_recipes": RECIPES.size(),
		"available": get_available_recipes().size(),
		"locked": get_locked_recipes().size(),
		"researched": _unlocked_research.size(),
		"unlock_pct": get_unlock_percentage(),
		"most_restrictive": get_most_restrictive_recipe(),
		"research_coverage_pct": get_research_coverage(),
		"unique_research_needed": get_unique_required_research_count(),
		"avg_min_level": get_avg_min_level(),
		"highest_skill_recipe": get_highest_skill_recipe(),
		"tech_progress": get_tech_progress(),
		"bottleneck_severity_pct": get_bottleneck_severity(),
		"skill_demand": get_skill_demand(),
		"innovation_readiness": get_innovation_readiness(),
		"research_roi": get_research_roi(),
		"crafting_potential": get_crafting_potential(),
		"recipe_ecosystem_health": get_recipe_ecosystem_health(),
		"innovation_pipeline_index": get_innovation_pipeline_index(),
		"crafting_governance": get_crafting_governance(),
	}

func get_innovation_readiness() -> String:
	var progress := get_tech_progress()
	var bottleneck := get_bottleneck_severity()
	if progress in ["Advanced", "Developed"] and bottleneck < 30.0:
		return "Ready"
	elif progress in ["Emerging", "Developed"]:
		return "Progressing"
	return "Blocked"

func get_research_roi() -> float:
	var unlocked := get_available_recipes().size()
	var researched := _unlocked_research.size()
	if researched <= 0:
		return 0.0
	return snapped(float(unlocked) / float(researched), 0.1)

func get_crafting_potential() -> String:
	var unlock_pct := get_unlock_percentage()
	if unlock_pct >= 80.0:
		return "Full Arsenal"
	elif unlock_pct >= 50.0:
		return "Well Equipped"
	elif unlock_pct >= 20.0:
		return "Basic"
	return "Minimal"

func get_recipe_ecosystem_health() -> float:
	var unlock := get_unlock_percentage()
	var roi := get_research_roi()
	var bottleneck := get_bottleneck_severity()
	return snapped((unlock + minf(roi * 20.0, 100.0) + maxf(100.0 - bottleneck, 0.0)) / 3.0, 0.1)

func get_innovation_pipeline_index() -> float:
	var coverage := get_research_coverage()
	var readiness := get_innovation_readiness()
	var r_val: float = 90.0 if readiness == "Ready" else (60.0 if readiness == "Progressing" else 30.0)
	return snapped((coverage + r_val) / 2.0, 0.1)

func get_crafting_governance() -> String:
	var health := get_recipe_ecosystem_health()
	var pipeline := get_innovation_pipeline_index()
	if health >= 65.0 and pipeline >= 60.0:
		return "Advanced"
	elif health >= 35.0 or pipeline >= 30.0:
		return "Developing"
	return "Primitive"
