extends Node

var _active_precepts: Array = []

const PRECEPTS: Dictionary = {
	"Cannibalism_Abhorrent": {"category": "diet", "mood_if_violated": -20, "desc": "Eating human meat is abhorrent"},
	"Cannibalism_Acceptable": {"category": "diet", "mood_if_violated": 0, "mood_bonus": 0, "desc": "Eating human meat is fine"},
	"Cannibalism_Required": {"category": "diet", "mood_if_not": -8, "mood_bonus": 15, "desc": "Must eat human meat"},
	"OrganHarvest_Abhorrent": {"category": "medical", "mood_if_violated": -15, "desc": "Organ harvesting is abhorrent"},
	"OrganHarvest_Acceptable": {"category": "medical", "mood_if_violated": 0, "desc": "Organ harvesting is fine"},
	"Slavery_Abhorrent": {"category": "social", "mood_if_violated": -10, "desc": "Slavery is wrong"},
	"Slavery_Acceptable": {"category": "social", "mood_if_violated": 0, "desc": "Slavery is acceptable"},
	"BlindingRitual": {"category": "ritual", "mood_bonus": 5, "desc": "Blinding as spiritual act"},
	"TreeConnection": {"category": "nature", "mood_bonus": 3, "desc": "Connection to Anima tree"},
	"Nudity_Male_OK": {"category": "apparel", "mood_if_violated": 0, "desc": "Male nudity accepted"},
	"Nudity_Female_OK": {"category": "apparel", "mood_if_violated": 0, "desc": "Female nudity accepted"},
	"DarknessCombat": {"category": "combat", "darkness_bonus": 0.15, "desc": "Fight better in dark"}
}

func add_precept(precept: String) -> Dictionary:
	if not PRECEPTS.has(precept):
		return {"error": "unknown_precept"}
	if precept in _active_precepts:
		return {"error": "already_active"}
	_active_precepts.append(precept)
	return {"added": precept, "category": PRECEPTS[precept]["category"]}

func check_violation(action: String) -> float:
	var total_penalty: float = 0.0
	for p: String in _active_precepts:
		if PRECEPTS[p].get("desc", "").find(action) >= 0:
			total_penalty += PRECEPTS[p].get("mood_if_violated", 0)
	return total_penalty

func get_precepts_by_category(cat: String) -> Array[String]:
	var result: Array[String] = []
	for p: String in PRECEPTS:
		if String(PRECEPTS[p].get("category", "")) == cat:
			result.append(p)
	return result


func get_category_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for p: String in PRECEPTS:
		var c: String = String(PRECEPTS[p].get("category", ""))
		dist[c] = int(dist.get(c, 0)) + 1
	return dist


func get_harshest_penalty_precept() -> String:
	var worst: String = ""
	var worst_pen: float = 0.0
	for p: String in PRECEPTS:
		var pen: float = absf(float(PRECEPTS[p].get("mood_if_violated", 0)))
		if pen > worst_pen:
			worst_pen = pen
			worst = p
	return worst


func get_avg_violation_penalty() -> float:
	if PRECEPTS.is_empty():
		return 0.0
	var total: float = 0.0
	var count: int = 0
	for p: String in PRECEPTS:
		var pen: float = float(PRECEPTS[p].get("mood_if_violated", 0))
		if pen < 0.0:
			total += pen
			count += 1
	if count == 0:
		return 0.0
	return total / count


func get_bonus_precepts_count() -> int:
	var count: int = 0
	for p: String in PRECEPTS:
		if float(PRECEPTS[p].get("mood_bonus", 0)) > 0.0:
			count += 1
	return count


func get_inactive_precepts_count() -> int:
	return PRECEPTS.size() - _active_precepts.size()


func get_unique_category_count() -> int:
	return get_category_distribution().size()


func get_no_penalty_precept_count() -> int:
	var count: int = 0
	for p: String in PRECEPTS:
		if float(PRECEPTS[p].get("mood_if_violated", 0)) == 0.0:
			count += 1
	return count


func get_total_bonus_mood() -> float:
	var total: float = 0.0
	for p: String in PRECEPTS:
		total += float(PRECEPTS[p].get("mood_bonus", 0.0))
	return total


func get_strictness_level() -> String:
	var avg: float = get_avg_violation_penalty()
	if avg >= 15.0:
		return "Draconian"
	if avg >= 8.0:
		return "Strict"
	if avg >= 3.0:
		return "Moderate"
	return "Lenient"


func get_moral_coverage_pct() -> float:
	var active: int = _active_precepts.size()
	return snappedf(float(active) / maxf(float(PRECEPTS.size()), 1.0) * 100.0, 0.1)


func get_doctrine_balance() -> String:
	var bonus: int = get_bonus_precepts_count()
	var penalty_based: int = PRECEPTS.size() - get_no_penalty_precept_count()
	if bonus > penalty_based:
		return "Rewarding"
	if penalty_based > bonus * 2:
		return "Punitive"
	return "Balanced"


func get_summary() -> Dictionary:
	return {
		"total_precepts": PRECEPTS.size(),
		"active_precepts": _active_precepts.size(),
		"categories": get_category_distribution().size(),
		"harshest": get_harshest_penalty_precept(),
		"avg_penalty": snapped(get_avg_violation_penalty(), 0.1),
		"bonus_precepts": get_bonus_precepts_count(),
		"inactive": get_inactive_precepts_count(),
		"no_penalty_count": get_no_penalty_precept_count(),
		"total_bonus_mood": get_total_bonus_mood(),
		"strictness_level": get_strictness_level(),
		"moral_coverage_pct": get_moral_coverage_pct(),
		"doctrine_balance": get_doctrine_balance(),
		"ideological_coherence": get_ideological_coherence(),
		"social_control_index": get_social_control_index(),
		"belief_adoption_rate": get_belief_adoption_rate(),
		"doctrine_ecosystem_health": get_doctrine_ecosystem_health(),
		"belief_governance": get_belief_governance(),
		"faith_maturity_index": get_faith_maturity_index(),
	}

func get_ideological_coherence() -> String:
	var balance := get_doctrine_balance()
	var coverage := get_moral_coverage_pct()
	if balance in ["Balanced", "Harmonious"] and coverage >= 70.0:
		return "Unified"
	elif coverage >= 40.0:
		return "Fragmented"
	return "Incoherent"

func get_social_control_index() -> float:
	var strict := get_strictness_level()
	var bonus := 0.0
	if strict in ["Strict", "Draconian"]:
		bonus = 20.0
	elif strict in ["Moderate"]:
		bonus = 10.0
	return snapped(get_moral_coverage_pct() + bonus, 0.1)

func get_belief_adoption_rate() -> float:
	var active := _active_precepts.size()
	var total := PRECEPTS.size()
	if total <= 0:
		return 0.0
	return snapped(float(active) / float(total) * 100.0, 0.1)

func get_doctrine_ecosystem_health() -> float:
	var coherence := get_ideological_coherence()
	var c_val: float = 90.0 if coherence == "Unified" else (70.0 if coherence == "Aligned" else (50.0 if coherence == "Fragmented" else 20.0))
	var adoption := get_belief_adoption_rate()
	var control := get_social_control_index()
	return snapped((c_val + adoption + minf(control, 100.0)) / 3.0, 0.1)

func get_faith_maturity_index() -> float:
	var strict := get_strictness_level()
	var s_val: float = 90.0 if strict in ["Strict", "Draconian"] else (60.0 if strict == "Moderate" else 30.0)
	var coverage := get_moral_coverage_pct()
	var adoption := get_belief_adoption_rate()
	return snapped((s_val + coverage + adoption) / 3.0, 0.1)

func get_belief_governance() -> String:
	var ecosystem := get_doctrine_ecosystem_health()
	var maturity := get_faith_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _active_precepts.size() > 0:
		return "Nascent"
	return "Dormant"
