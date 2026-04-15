extends Node

const POLICIES: Dictionary = {
	"DrugPolicy_None": {"category": "Drug", "effect": "no_drugs_allowed", "mood": 0, "work_mult": 1.0},
	"DrugPolicy_Social": {"category": "Drug", "effect": "social_drugs_only", "mood": 3, "work_mult": 0.98},
	"DrugPolicy_Free": {"category": "Drug", "effect": "all_drugs_allowed", "mood": 5, "work_mult": 0.9},
	"FoodPolicy_Paste": {"category": "Food", "effect": "nutrient_paste_only", "mood": -4, "work_mult": 1.0},
	"FoodPolicy_Simple": {"category": "Food", "effect": "simple_meals", "mood": 0, "work_mult": 1.0},
	"FoodPolicy_Fine": {"category": "Food", "effect": "fine_meals_preferred", "mood": 3, "work_mult": 1.0},
	"FoodPolicy_Lavish": {"category": "Food", "effect": "lavish_meals", "mood": 8, "work_mult": 1.0},
	"OutfitPolicy_Worker": {"category": "Outfit", "effect": "work_clothes", "mood": 0, "work_mult": 1.05},
	"OutfitPolicy_Soldier": {"category": "Outfit", "effect": "armor_required", "mood": -2, "work_mult": 0.95},
	"OutfitPolicy_Nudist": {"category": "Outfit", "effect": "minimal_clothing", "mood": 0, "work_mult": 1.0},
	"MedPolicy_NoCare": {"category": "Medical", "effect": "no_medical_care", "mood": -5, "work_mult": 1.0},
	"MedPolicy_HerbalOnly": {"category": "Medical", "effect": "herbal_medicine_only", "mood": 0, "work_mult": 1.0},
	"MedPolicy_Best": {"category": "Medical", "effect": "best_medicine", "mood": 2, "work_mult": 1.0},
	"WorkPolicy_Hard": {"category": "Work", "effect": "no_breaks", "mood": -8, "work_mult": 1.2},
	"WorkPolicy_Normal": {"category": "Work", "effect": "normal_schedule", "mood": 0, "work_mult": 1.0},
	"WorkPolicy_Relaxed": {"category": "Work", "effect": "extra_breaks", "mood": 5, "work_mult": 0.85}
}

const POLICY_CATEGORIES: Array = ["Drug", "Food", "Outfit", "Medical", "Work"]

func get_policies_by_category(category: String) -> Array:
	var result: Array = []
	for key: String in POLICIES:
		if POLICIES[key]["category"] == category:
			result.append(key)
	return result

func get_colony_mood_from_policies(active_policies: Array) -> float:
	var total: float = 0.0
	for p: String in active_policies:
		if POLICIES.has(p):
			total += POLICIES[p]["mood"]
	return total

func get_best_mood_policy(category: String) -> String:
	var best: String = ""
	var best_m: float = -999.0
	for key: String in POLICIES:
		if POLICIES[key]["category"] == category and POLICIES[key]["mood"] > best_m:
			best_m = POLICIES[key]["mood"]
			best = key
	return best

func get_best_work_policy(category: String) -> String:
	var best: String = ""
	var best_w: float = 0.0
	for key: String in POLICIES:
		if POLICIES[key]["category"] == category and POLICIES[key]["work_mult"] > best_w:
			best_w = POLICIES[key]["work_mult"]
			best = key
	return best

func get_negative_mood_policies() -> Array[String]:
	var result: Array[String] = []
	for key: String in POLICIES:
		if POLICIES[key]["mood"] < 0:
			result.append(key)
	return result

func get_avg_mood_effect() -> float:
	var total: float = 0.0
	for k: String in POLICIES:
		total += POLICIES[k].get("mood", 0.0)
	if POLICIES.is_empty():
		return 0.0
	return snappedf(total / float(POLICIES.size()), 0.01)

func get_highest_work_mult_policy() -> String:
	var best: String = ""
	var best_w: float = 0.0
	for k: String in POLICIES:
		var w: float = POLICIES[k].get("work_mult", 0.0)
		if w > best_w:
			best_w = w
			best = k
	return best

func get_positive_mood_policy_count() -> int:
	var count: int = 0
	for k: String in POLICIES:
		if POLICIES[k].get("mood", 0.0) > 0:
			count += 1
	return count

func get_neutral_mood_policy_count() -> int:
	var count: int = 0
	for k: String in POLICIES:
		if int(POLICIES[k].get("mood", -1)) == 0:
			count += 1
	return count


func get_worst_mood_policy() -> String:
	var worst: String = ""
	var worst_m: float = 999.0
	for k: String in POLICIES:
		var m: float = float(POLICIES[k].get("mood", 999.0))
		if m < worst_m:
			worst_m = m
			worst = k
	return worst


func get_below_normal_work_count() -> int:
	var count: int = 0
	for k: String in POLICIES:
		if float(POLICIES[k].get("work_mult", 1.0)) < 1.0:
			count += 1
	return count


func get_policy_flexibility() -> int:
	var cat_has_pos := {}
	var cat_has_neg := {}
	for p in POLICIES.values():
		var c: String = p["category"]
		if p["mood"] > 0:
			cat_has_pos[c] = true
		elif p["mood"] < 0:
			cat_has_neg[c] = true
	var flex := 0
	for c in POLICY_CATEGORIES:
		if cat_has_pos.has(c) and cat_has_neg.has(c):
			flex += 1
	return flex

func get_productivity_risk_pct() -> float:
	var below := 0
	for p in POLICIES.values():
		if p["work_mult"] < 1.0:
			below += 1
	return snapped(float(below) / maxf(POLICIES.size(), 1.0) * 100.0, 0.1)

func get_morale_optimization() -> float:
	var cat_best := {}
	for p in POLICIES.values():
		var c: String = p["category"]
		if not cat_best.has(c) or p["mood"] > cat_best[c]:
			cat_best[c] = p["mood"]
	var total := 0.0
	for v in cat_best.values():
		total += v
	return snapped(total, 0.1)

func get_summary() -> Dictionary:
	return {
		"policy_count": POLICIES.size(),
		"categories": POLICY_CATEGORIES.size(),
		"negative_mood_count": get_negative_mood_policies().size(),
		"avg_mood_effect": get_avg_mood_effect(),
		"highest_work_mult_policy": get_highest_work_mult_policy(),
		"positive_mood_policies": get_positive_mood_policy_count(),
		"neutral_mood_policies": get_neutral_mood_policy_count(),
		"worst_mood_policy": get_worst_mood_policy(),
		"low_work_mult_policies": get_below_normal_work_count(),
		"policy_flexibility": get_policy_flexibility(),
		"productivity_risk_pct": get_productivity_risk_pct(),
		"morale_optimization": get_morale_optimization(),
		"governance_effectiveness": get_governance_effectiveness(),
		"labor_policy_balance": get_labor_policy_balance(),
		"colony_satisfaction_index": get_colony_satisfaction_index(),
		"policy_ecosystem_health": get_policy_ecosystem_health(),
		"regulatory_maturity": get_regulatory_maturity(),
		"governance_resilience_score": get_governance_resilience_score(),
	}

func get_policy_ecosystem_health() -> String:
	var effectiveness: String = get_governance_effectiveness()
	var satisfaction: float = get_colony_satisfaction_index()
	if effectiveness in ["Effective", "Excellent"] and satisfaction >= 70.0:
		return "Thriving"
	if satisfaction >= 40.0:
		return "Functional"
	return "Strained"

func get_regulatory_maturity() -> float:
	var categories: int = POLICY_CATEGORIES.size()
	var policies: int = POLICIES.size()
	var productivity_risk: float = get_productivity_risk_pct()
	var score: float = float(policies) * 3.0 + float(categories) * 10.0 - productivity_risk
	return snappedf(clampf(score, 0.0, 100.0), 0.1)

func get_governance_resilience_score() -> float:
	var balance: float = get_labor_policy_balance()
	var morale: float = get_morale_optimization()
	var base: float = 50.0
	if balance >= 70.0:
		base += 25.0
	elif balance >= 40.0:
		base += 15.0
	if morale >= 70.0:
		base += 25.0
	elif morale >= 40.0:
		base += 15.0
	return snappedf(clampf(base, 0.0, 100.0), 0.1)

func get_governance_effectiveness() -> String:
	var flexibility := get_policy_flexibility()
	var morale := get_morale_optimization()
	if flexibility in ["Flexible", "Adaptive"] and morale in ["Optimized", "Excellent"]:
		return "Exemplary"
	elif flexibility in ["Moderate", "Flexible"]:
		return "Functional"
	return "Rigid"

func get_labor_policy_balance() -> float:
	var positive := get_positive_mood_policy_count()
	var negative := get_negative_mood_policies().size()
	var total := POLICIES.size()
	if total <= 0:
		return 0.0
	return snapped(float(positive) / float(total) * 100.0, 0.1)

func get_colony_satisfaction_index() -> float:
	var avg_mood := get_avg_mood_effect()
	var neutral := get_neutral_mood_policy_count()
	return snapped(avg_mood + float(neutral) * 0.5, 0.1)
