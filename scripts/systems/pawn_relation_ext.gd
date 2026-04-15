extends Node

const RELATION_TYPES: Dictionary = {
	"Spouse": {"opinion": 30, "category": "Romantic", "breakable": true, "mood_on_death": -20},
	"Lover": {"opinion": 20, "category": "Romantic", "breakable": true, "mood_on_death": -15},
	"Fiance": {"opinion": 25, "category": "Romantic", "breakable": true, "mood_on_death": -12},
	"ExSpouse": {"opinion": -5, "category": "Romantic", "breakable": false, "mood_on_death": -5},
	"ExLover": {"opinion": -3, "category": "Romantic", "breakable": false, "mood_on_death": -3},
	"Parent": {"opinion": 10, "category": "Family", "breakable": false, "mood_on_death": -15},
	"Child": {"opinion": 10, "category": "Family", "breakable": false, "mood_on_death": -25},
	"Sibling": {"opinion": 8, "category": "Family", "breakable": false, "mood_on_death": -10},
	"HalfSibling": {"opinion": 5, "category": "Family", "breakable": false, "mood_on_death": -7},
	"Grandparent": {"opinion": 5, "category": "Family", "breakable": false, "mood_on_death": -8},
	"Grandchild": {"opinion": 5, "category": "Family", "breakable": false, "mood_on_death": -12},
	"Uncle": {"opinion": 3, "category": "Family", "breakable": false, "mood_on_death": -5},
	"Cousin": {"opinion": 2, "category": "Family", "breakable": false, "mood_on_death": -3},
	"Friend": {"opinion": 15, "category": "Social", "breakable": true, "mood_on_death": -8},
	"Rival": {"opinion": -20, "category": "Social", "breakable": true, "mood_on_death": 5},
	"BondedPet": {"opinion": 0, "category": "Animal", "breakable": false, "mood_on_death": -12},
	"Master": {"opinion": 10, "category": "Hierarchy", "breakable": true, "mood_on_death": -5}
}

const RELATION_TRIGGERS: Dictionary = {
	"Friend": {"min_opinion": 40, "interactions_needed": 5},
	"Rival": {"max_opinion": -40, "insults_needed": 3},
	"Lover": {"min_opinion": 30, "romance_attempts": 1},
	"Spouse": {"min_opinion": 50, "proposal_needed": true}
}

func get_opinion_from_relation(relation: String) -> int:
	return RELATION_TYPES.get(relation, {}).get("opinion", 0)

func get_death_mood(relation: String) -> int:
	return RELATION_TYPES.get(relation, {}).get("mood_on_death", 0)

func get_romantic_relations() -> Array[String]:
	var result: Array[String] = []
	for r: String in RELATION_TYPES:
		if RELATION_TYPES[r]["category"] == "Romantic":
			result.append(r)
	return result

func get_worst_death_mood_relation() -> String:
	var worst: String = ""
	var worst_v: int = 0
	for r: String in RELATION_TYPES:
		if RELATION_TYPES[r]["mood_on_death"] < worst_v:
			worst_v = RELATION_TYPES[r]["mood_on_death"]
			worst = r
	return worst

func get_relations_by_category(category: String) -> Array[String]:
	var result: Array[String] = []
	for r: String in RELATION_TYPES:
		if RELATION_TYPES[r]["category"] == category:
			result.append(r)
	return result

func get_avg_opinion_impact() -> float:
	if RELATION_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for rt: String in RELATION_TYPES:
		total += float(RELATION_TYPES[rt].get("opinion", 0.0))
	return total / RELATION_TYPES.size()

func get_hostile_relation_count() -> int:
	var count: int = 0
	for rt: String in RELATION_TYPES:
		if float(RELATION_TYPES[rt].get("opinion", 0.0)) < -20.0:
			count += 1
	return count

func get_family_relation_count() -> int:
	var count: int = 0
	for rt: String in RELATION_TYPES:
		if bool(RELATION_TYPES[rt].get("family", false)):
			count += 1
	return count

func get_breakable_relation_count() -> int:
	var count: int = 0
	for rt: String in RELATION_TYPES:
		if bool(RELATION_TYPES[rt].get("breakable", false)):
			count += 1
	return count


func get_best_opinion_relation() -> String:
	var best: String = ""
	var best_o: int = -999
	for rt: String in RELATION_TYPES:
		var o: int = int(RELATION_TYPES[rt].get("opinion", -999))
		if o > best_o:
			best_o = o
			best = rt
	return best


func get_unique_categories() -> int:
	var cats: Dictionary = {}
	for rt: String in RELATION_TYPES:
		cats[String(RELATION_TYPES[rt].get("category", ""))] = true
	return cats.size()


func get_social_fabric() -> String:
	var family: int = get_family_relation_count()
	var hostile: int = get_hostile_relation_count()
	if family > hostile * 2:
		return "Tight-Knit"
	elif family > hostile:
		return "Cohesive"
	elif family == hostile:
		return "Mixed"
	return "Fractured"

func get_bond_depth() -> float:
	if RELATION_TYPES.is_empty():
		return 0.0
	var romantic: int = get_romantic_relations().size()
	var family: int = get_family_relation_count()
	return snappedf(float(romantic + family) / float(RELATION_TYPES.size()) * 100.0, 0.1)

func get_conflict_potential() -> String:
	var hostile: int = get_hostile_relation_count()
	if hostile == 0:
		return "None"
	elif hostile <= 2:
		return "Low"
	elif hostile <= 5:
		return "Moderate"
	return "High"

func get_network_density() -> String:
	var types: int = RELATION_TYPES.size()
	var family: int = get_family_relation_count()
	var romantic: int = get_romantic_relations().size()
	var connected: int = family + romantic
	if types == 0:
		return "isolated"
	var ratio: float = connected * 1.0 / types
	if ratio >= 0.5:
		return "tightly_knit"
	if ratio >= 0.25:
		return "loosely_connected"
	return "fragmented"

func get_emotional_volatility_pct() -> float:
	var breakable: int = get_breakable_relation_count()
	var hostile: int = get_hostile_relation_count()
	var total: int = RELATION_TYPES.size()
	if total == 0:
		return 0.0
	return snapped((breakable + hostile) * 100.0 / total, 0.1)

func get_community_health() -> String:
	var avg: float = get_avg_opinion_impact()
	var hostile: int = get_hostile_relation_count()
	if hostile >= 3:
		return "fractured"
	if avg >= 10.0:
		return "thriving"
	if avg >= 0.0:
		return "stable"
	return "strained"

func get_summary() -> Dictionary:
	return {
		"relation_types": RELATION_TYPES.size(),
		"triggers": RELATION_TRIGGERS.size(),
		"romantic_count": get_romantic_relations().size(),
		"worst_death_relation": get_worst_death_mood_relation(),
		"avg_opinion": snapped(get_avg_opinion_impact(), 0.1),
		"hostile_types": get_hostile_relation_count(),
		"family_types": get_family_relation_count(),
		"breakable_types": get_breakable_relation_count(),
		"best_opinion": get_best_opinion_relation(),
		"unique_categories": get_unique_categories(),
		"social_fabric": get_social_fabric(),
		"bond_depth_pct": get_bond_depth(),
		"conflict_potential": get_conflict_potential(),
		"network_density": get_network_density(),
		"emotional_volatility_pct": get_emotional_volatility_pct(),
		"community_health": get_community_health(),
		"social_ecosystem_health": get_social_ecosystem_health(),
		"relationship_governance": get_relationship_governance(),
		"community_maturity_index": get_community_maturity_index(),
	}

func get_social_ecosystem_health() -> float:
	var fabric := get_social_fabric()
	var f_val: float = 90.0 if fabric == "Tight-Knit" else (60.0 if fabric in ["Cordial", "Neutral"] else 30.0)
	var health := get_community_health()
	var h_val: float = 90.0 if health == "thriving" else (60.0 if health == "stable" else 30.0)
	var density := get_network_density()
	var d_val: float = 90.0 if density in ["dense", "interconnected"] else (60.0 if density in ["moderate", "sparse"] else 30.0)
	return snapped((f_val + h_val + d_val) / 3.0, 0.1)

func get_community_maturity_index() -> float:
	var depth := get_bond_depth()
	var conflict := get_conflict_potential()
	var c_val: float = 90.0 if conflict == "None" else (60.0 if conflict == "Low" else 30.0)
	var volatility := get_emotional_volatility_pct()
	var v_val: float = maxf(100.0 - volatility, 0.0)
	return snapped((depth + c_val + v_val) / 3.0, 0.1)

func get_relationship_governance() -> String:
	var ecosystem := get_social_ecosystem_health()
	var maturity := get_community_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif RELATION_TYPES.size() > 0:
		return "Nascent"
	return "Dormant"
