extends Node

var _desires: Dictionary = {}

const LEARNING_CATEGORIES: Dictionary = {
	"Shooting": {"growth_points_per_day": 0.8, "passion_mult": 1.5},
	"Melee": {"growth_points_per_day": 0.8, "passion_mult": 1.5},
	"Construction": {"growth_points_per_day": 0.7, "passion_mult": 1.4},
	"Mining": {"growth_points_per_day": 0.6, "passion_mult": 1.3},
	"Cooking": {"growth_points_per_day": 0.7, "passion_mult": 1.4},
	"Plants": {"growth_points_per_day": 0.7, "passion_mult": 1.3},
	"Animals": {"growth_points_per_day": 0.6, "passion_mult": 1.3},
	"Crafting": {"growth_points_per_day": 0.8, "passion_mult": 1.5},
	"Artistic": {"growth_points_per_day": 0.5, "passion_mult": 1.6},
	"Medical": {"growth_points_per_day": 0.9, "passion_mult": 1.5},
	"Social": {"growth_points_per_day": 0.6, "passion_mult": 1.3},
	"Intellectual": {"growth_points_per_day": 1.0, "passion_mult": 1.6}
}

const GROWTH_POINT_THRESHOLDS: Dictionary = {
	"TraitSlot": 200,
	"PassionSlot": 500,
	"SkillBoost": 100
}

func set_desire(pawn_id: int, category: String, level: float) -> Dictionary:
	if not LEARNING_CATEGORIES.has(category):
		return {"error": "unknown_category"}
	if not _desires.has(pawn_id):
		_desires[pawn_id] = {}
	_desires[pawn_id][category] = clampf(level, 0.0, 1.0)
	return {"set": true, "category": category, "level": level}

func gain_growth_points(pawn_id: int, category: String, hours: float) -> float:
	if not LEARNING_CATEGORIES.has(category):
		return 0.0
	var base: float = LEARNING_CATEGORIES[category]["growth_points_per_day"]
	var desire: float = _desires.get(pawn_id, {}).get(category, 0.5)
	return base * (hours / 24.0) * (1.0 + desire)

func get_fastest_learning_category() -> String:
	var best: String = ""
	var best_rate: float = 0.0
	for cat: String in LEARNING_CATEGORIES:
		var r: float = float(LEARNING_CATEGORIES[cat].get("growth_points_per_day", 0.0))
		if r > best_rate:
			best_rate = r
			best = cat
	return best


func get_highest_passion_mult_category() -> String:
	var best: String = ""
	var best_m: float = 0.0
	for cat: String in LEARNING_CATEGORIES:
		var m: float = float(LEARNING_CATEGORIES[cat].get("passion_mult", 0.0))
		if m > best_m:
			best_m = m
			best = cat
	return best


func get_desire_distribution(pawn_id: int) -> Dictionary:
	return _desires.get(pawn_id, {}).duplicate()


func get_slowest_learning_category() -> String:
	var worst: String = ""
	var worst_rate: float = 999.0
	for cat: String in LEARNING_CATEGORIES:
		var r: float = float(LEARNING_CATEGORIES[cat].get("growth_points_per_day", 999.0))
		if r < worst_rate:
			worst_rate = r
			worst = cat
	return worst


func get_avg_growth_rate() -> float:
	if LEARNING_CATEGORIES.is_empty():
		return 0.0
	var total: float = 0.0
	for cat: String in LEARNING_CATEGORIES:
		total += float(LEARNING_CATEGORIES[cat].get("growth_points_per_day", 0.0))
	return total / LEARNING_CATEGORIES.size()


func get_high_passion_categories() -> int:
	var count: int = 0
	for cat: String in LEARNING_CATEGORIES:
		if float(LEARNING_CATEGORIES[cat].get("passion_mult", 0.0)) >= 1.5:
			count += 1
	return count


func get_passion_spread() -> float:
	var lo: float = 999.0
	var hi: float = 0.0
	for cat: String in LEARNING_CATEGORIES:
		var m: float = float(LEARNING_CATEGORIES[cat].get("passion_mult", 0.0))
		if m < lo:
			lo = m
		if m > hi:
			hi = m
	if lo > hi:
		return 0.0
	return hi - lo


func get_combat_category_count() -> int:
	var count: int = 0
	for cat: String in LEARNING_CATEGORIES:
		if cat in ["Shooting", "Melee"]:
			count += 1
	return count


func get_above_avg_categories() -> int:
	var avg: float = get_avg_growth_rate()
	var count: int = 0
	for cat: String in LEARNING_CATEGORIES:
		if float(LEARNING_CATEGORIES[cat].get("growth_points_per_day", 0.0)) > avg:
			count += 1
	return count


func get_intellectual_vigor() -> String:
	var above: int = get_above_avg_categories()
	var total: int = LEARNING_CATEGORIES.size()
	if total == 0:
		return "NoData"
	var ratio: float = float(above) / float(total)
	if ratio >= 0.6:
		return "Enthusiastic"
	if ratio >= 0.3:
		return "Engaged"
	return "Apathetic"


func get_specialization_index_pct() -> float:
	var high: int = get_high_passion_categories()
	return snappedf(float(high) / maxf(float(LEARNING_CATEGORIES.size()), 1.0) * 100.0, 0.1)


func get_growth_trajectory() -> String:
	var avg: float = get_avg_growth_rate()
	if avg >= 1.5:
		return "Accelerating"
	if avg >= 0.8:
		return "Steady"
	if avg > 0.0:
		return "Slow"
	return "Stagnant"


func get_summary() -> Dictionary:
	return {
		"learning_categories": LEARNING_CATEGORIES.size(),
		"growth_thresholds": GROWTH_POINT_THRESHOLDS.size(),
		"tracked_pawns": _desires.size(),
		"fastest_category": get_fastest_learning_category(),
		"slowest_category": get_slowest_learning_category(),
		"avg_growth": snapped(get_avg_growth_rate(), 0.01),
		"high_passion_cats": get_high_passion_categories(),
		"passion_spread": snapped(get_passion_spread(), 0.01),
		"combat_categories": get_combat_category_count(),
		"above_avg_cats": get_above_avg_categories(),
		"intellectual_vigor": get_intellectual_vigor(),
		"specialization_index_pct": get_specialization_index_pct(),
		"growth_trajectory": get_growth_trajectory(),
		"learning_momentum": get_learning_momentum(),
		"knowledge_breadth": get_knowledge_breadth(),
		"skill_ceiling_potential": get_skill_ceiling_potential(),
		"learning_ecosystem_health": get_learning_ecosystem_health(),
		"education_governance": get_education_governance(),
		"knowledge_maturity_index": get_knowledge_maturity_index(),
	}

func get_learning_momentum() -> String:
	var trajectory := get_growth_trajectory()
	var vigor := get_intellectual_vigor()
	if trajectory in ["Ascending", "Accelerating"] and vigor in ["High", "Exceptional"]:
		return "Surging"
	elif trajectory in ["Steady", "Ascending"]:
		return "Building"
	return "Stagnant"

func get_knowledge_breadth() -> float:
	var above_avg := get_above_avg_categories()
	var total := LEARNING_CATEGORIES.size()
	if total <= 0:
		return 0.0
	return snapped(float(above_avg) / float(total) * 100.0, 0.1)

func get_skill_ceiling_potential() -> String:
	var high_passion := get_high_passion_categories()
	if high_passion >= 4:
		return "Exceptional"
	elif high_passion >= 2:
		return "Good"
	return "Limited"

func get_learning_ecosystem_health() -> float:
	var momentum := get_learning_momentum()
	var m_val: float = 90.0 if momentum in ["Surging", "Accelerating"] else (60.0 if momentum in ["Building", "Steady"] else 30.0)
	var breadth := get_knowledge_breadth()
	var ceiling := get_skill_ceiling_potential()
	var c_val: float = 90.0 if ceiling == "Exceptional" else (60.0 if ceiling == "Good" else 30.0)
	return snapped((m_val + breadth + c_val) / 3.0, 0.1)

func get_knowledge_maturity_index() -> float:
	var vigor := get_intellectual_vigor()
	var v_val: float = 90.0 if vigor in ["Burning", "Intense"] else (60.0 if vigor in ["Active", "Moderate"] else 30.0)
	var specialization := get_specialization_index_pct()
	var trajectory := get_growth_trajectory()
	var t_val: float = 90.0 if trajectory in ["Accelerating", "Rocketing"] else (60.0 if trajectory in ["Steady", "Rising"] else 30.0)
	return snapped((v_val + specialization + t_val) / 3.0, 0.1)

func get_education_governance() -> String:
	var ecosystem := get_learning_ecosystem_health()
	var maturity := get_knowledge_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _desires.size() > 0:
		return "Nascent"
	return "Dormant"
