extends Node

var _children: Dictionary = {}

const GROWTH_STAGES: Dictionary = {
	"Baby": {"age_range": [0, 1], "needs": ["food", "comfort"], "can_walk": false},
	"Toddler": {"age_range": [1, 3], "needs": ["food", "play", "comfort"], "can_walk": true, "learning_rate": 0.5},
	"Child": {"age_range": [3, 7], "needs": ["food", "play", "learning"], "can_walk": true, "learning_rate": 1.0, "work_allowed": false},
	"PreTeen": {"age_range": [7, 13], "needs": ["food", "play", "learning", "social"], "can_walk": true, "learning_rate": 1.5, "work_allowed": true},
	"Teen": {"age_range": [13, 18], "needs": ["food", "joy", "learning", "social"], "can_walk": true, "learning_rate": 1.2, "work_allowed": true}
}

const GROWTH_MOMENTS: Dictionary = {
	3: {"event": "FirstSteps", "choice": "trait_selection"},
	7: {"event": "SchoolStart", "choice": "passion_selection"},
	13: {"event": "ComingOfAge", "choice": "backstory_selection"},
	18: {"event": "Adulthood", "choice": "final_traits"}
}

func register_child(pawn_id: int, age: float) -> Dictionary:
	var stage: String = _get_stage(age)
	_children[pawn_id] = {"age": age, "stage": stage, "growth_points": 0}
	return {"registered": true, "stage": stage}

func _get_stage(age: float) -> String:
	for stage: String in GROWTH_STAGES:
		var r: Array = GROWTH_STAGES[stage]["age_range"]
		if age >= r[0] and age < r[1]:
			return stage
	return "Teen"

func advance_year(pawn_id: int) -> Dictionary:
	if not _children.has(pawn_id):
		return {"error": "not_child"}
	_children[pawn_id]["age"] += 1
	var new_stage: String = _get_stage(_children[pawn_id]["age"])
	var old_stage: String = _children[pawn_id]["stage"]
	_children[pawn_id]["stage"] = new_stage
	var age_int: int = int(_children[pawn_id]["age"])
	var moment: Dictionary = GROWTH_MOMENTS.get(age_int, {})
	return {"age": _children[pawn_id]["age"], "stage": new_stage, "stage_changed": new_stage != old_stage, "growth_moment": moment}

func get_stage_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pid: int in _children:
		var s: String = String(_children[pid].get("stage", "Baby"))
		dist[s] = int(dist.get(s, 0)) + 1
	return dist


func get_near_growth_moment() -> Array:
	var result: Array = []
	for pid: int in _children:
		var age_int: int = int(_children[pid].get("age", 0))
		for gm_age: int in [3, 7, 13, 18]:
			if age_int == gm_age - 1:
				result.append({"pawn_id": pid, "next_moment_age": gm_age})
				break
	return result


func get_babies_count() -> int:
	var count: int = 0
	for pid: int in _children:
		if String(_children[pid].get("stage", "")) == "Baby":
			count += 1
	return count


func get_avg_child_age() -> float:
	if _children.is_empty():
		return 0.0
	var total: float = 0.0
	for pid: int in _children:
		total += float(_children[pid].get("age", 0.0))
	return total / _children.size()


func get_teens_count() -> int:
	var count: int = 0
	for pid: int in _children:
		if String(_children[pid].get("stage", "")) == "Teen":
			count += 1
	return count


func get_near_adulthood_count() -> int:
	var count: int = 0
	for pid: int in _children:
		if float(_children[pid].get("age", 0.0)) >= 16.0:
			count += 1
	return count


func get_work_capable_count() -> int:
	var count: int = 0
	for pid: int in _children:
		var stage: String = String(_children[pid].get("stage", "Baby"))
		if bool(GROWTH_STAGES.get(stage, {}).get("work_allowed", false)):
			count += 1
	return count


func get_near_growth_moment_count() -> int:
	return get_near_growth_moment().size()


func get_children_count() -> int:
	var count: int = 0
	for pid: int in _children:
		if String(_children[pid].get("stage", "")) == "Child":
			count += 1
	return count


func get_demographic_outlook() -> String:
	var babies: int = get_babies_count()
	var teens: int = get_teens_count()
	var total: int = _children.size()
	if total == 0:
		return "NoYouth"
	if babies > teens:
		return "BabyBoom"
	if teens > babies:
		return "Maturing"
	return "Stable"


func get_workforce_pipeline_pct() -> float:
	var capable: int = get_work_capable_count() + get_near_adulthood_count()
	var total: int = _children.size()
	if total == 0:
		return 0.0
	return snappedf(float(capable) / float(total) * 100.0, 0.1)


func get_care_intensity() -> String:
	var babies: int = get_babies_count()
	var total: int = _children.size()
	if total == 0:
		return "NoCare"
	var ratio: float = float(babies) / float(total)
	if ratio >= 0.5:
		return "HighDemand"
	if ratio >= 0.2:
		return "Moderate"
	return "Low"


func get_summary() -> Dictionary:
	return {
		"growth_stages": GROWTH_STAGES.size(),
		"growth_moments": GROWTH_MOMENTS.size(),
		"tracked_children": _children.size(),
		"babies": get_babies_count(),
		"avg_age": snapped(get_avg_child_age(), 0.1),
		"teens": get_teens_count(),
		"near_adult": get_near_adulthood_count(),
		"work_capable": get_work_capable_count(),
		"near_moment": get_near_growth_moment_count(),
		"children_stage": get_children_count(),
		"demographic_outlook": get_demographic_outlook(),
		"workforce_pipeline_pct": get_workforce_pipeline_pct(),
		"care_intensity": get_care_intensity(),
		"generational_continuity": get_generational_continuity(),
		"education_investment": get_education_investment(),
		"youth_development_score": get_youth_development_score(),
		"nurture_ecosystem_health": get_nurture_ecosystem_health(),
		"child_governance": get_child_governance(),
		"growth_maturity_index": get_growth_maturity_index(),
	}

func get_generational_continuity() -> String:
	var total := _children.size()
	var near_adult := get_near_adulthood_count()
	if total >= 3 and near_adult >= 1:
		return "Strong"
	elif total >= 1:
		return "Emerging"
	return "At Risk"

func get_education_investment() -> float:
	var work_capable := get_work_capable_count()
	var total := _children.size()
	if total <= 0:
		return 0.0
	return snapped(float(work_capable) / float(total) * 100.0, 0.1)

func get_youth_development_score() -> String:
	var avg_age := get_avg_child_age()
	var pipeline := get_workforce_pipeline_pct()
	if pipeline >= 50.0 and avg_age >= 10.0:
		return "Advanced"
	elif pipeline >= 20.0:
		return "Progressing"
	return "Early Stage"

func get_nurture_ecosystem_health() -> float:
	var continuity := get_generational_continuity()
	var c_val: float = 90.0 if continuity == "Strong" else (60.0 if continuity in ["Emerging", "Stable"] else 30.0)
	var investment := get_education_investment()
	var score := get_youth_development_score()
	var s_val: float = 90.0 if score == "Advanced" else (60.0 if score == "Progressing" else 30.0)
	return snapped((c_val + investment + s_val) / 3.0, 0.1)

func get_growth_maturity_index() -> float:
	var pipeline := get_workforce_pipeline_pct()
	var outlook := get_demographic_outlook()
	var o_val: float = 90.0 if outlook in ["Thriving", "Booming"] else (60.0 if outlook in ["Growing", "Emerging", "Stable"] else 30.0)
	var care := get_care_intensity()
	var care_val: float = 90.0 if care in ["High", "Intensive"] else (60.0 if care in ["Moderate", "Normal"] else 30.0)
	return snapped((pipeline + o_val + care_val) / 3.0, 0.1)

func get_child_governance() -> String:
	var ecosystem := get_nurture_ecosystem_health()
	var maturity := get_growth_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _children.size() > 0:
		return "Nascent"
	return "Dormant"
