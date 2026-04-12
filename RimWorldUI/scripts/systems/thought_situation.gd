extends Node

const SITUATIONAL_THOUGHTS: Dictionary = {
	"Outdoors": {"mood": 5, "condition": "outside", "category": "Environment"},
	"Indoors": {"mood": 0, "condition": "inside", "category": "Environment"},
	"CabinFever": {"mood": -3, "condition": "inside_long", "threshold_days": 5, "category": "Environment"},
	"Darkness": {"mood": -5, "condition": "light_below_0.3", "category": "Environment"},
	"UglyEnvironment": {"mood": -4, "condition": "beauty_below_-5", "category": "Environment"},
	"BeautifulEnv": {"mood": 5, "condition": "beauty_above_10", "category": "Environment"},
	"ImpressiveRoom": {"mood": 6, "condition": "room_impressive", "category": "Room"},
	"AwfulRoom": {"mood": -4, "condition": "room_awful", "category": "Room"},
	"SleptOnGround": {"mood": -4, "condition": "no_bed", "category": "Comfort"},
	"SleptInCold": {"mood": -3, "condition": "temp_below_5", "category": "Comfort"},
	"SleptInHeat": {"mood": -3, "condition": "temp_above_35", "category": "Comfort"},
	"SharedRoom": {"mood": -3, "condition": "room_shared_nonlover", "category": "Comfort"},
	"AteWithoutTable": {"mood": -3, "condition": "ate_standing", "category": "Dining"},
	"AteRawFood": {"mood": -7, "condition": "ate_raw", "category": "Dining"},
	"AteLavishMeal": {"mood": 12, "condition": "ate_lavish", "category": "Dining"},
	"AteFineReal": {"mood": 5, "condition": "ate_fine", "category": "Dining"},
	"WoreRags": {"mood": -3, "condition": "apparel_tattered", "category": "Apparel"},
	"NakedDislike": {"mood": -6, "condition": "naked", "category": "Apparel"},
	"HospitalPatient": {"mood": -3, "condition": "in_hospital", "category": "Health"},
	"Recovering": {"mood": -2, "condition": "recovering_injury", "category": "Health"}
}

const MOOD_STACKING: Dictionary = {
	"max_situational_bonus": 30,
	"max_situational_penalty": -40,
	"same_category_diminish": 0.7
}

func calc_situational_mood(active_conditions: Array) -> Dictionary:
	var total: float = 0.0
	var category_counts: Dictionary = {}
	var applied: Array[String] = []
	for thought_key: String in SITUATIONAL_THOUGHTS:
		var t: Dictionary = SITUATIONAL_THOUGHTS[thought_key]
		if t["condition"] in active_conditions:
			var cat: String = t["category"]
			var count: int = category_counts.get(cat, 0)
			var diminish: float = pow(MOOD_STACKING["same_category_diminish"], count)
			total += t["mood"] * diminish
			category_counts[cat] = count + 1
			applied.append(thought_key)
	total = clampf(total, MOOD_STACKING["max_situational_penalty"], MOOD_STACKING["max_situational_bonus"])
	return {"total_mood": total, "applied_thoughts": applied.size()}

func get_worst_thought() -> String:
	var worst: String = ""
	var worst_m: int = 999
	for t: String in SITUATIONAL_THOUGHTS:
		if SITUATIONAL_THOUGHTS[t]["mood"] < worst_m:
			worst_m = SITUATIONAL_THOUGHTS[t]["mood"]
			worst = t
	return worst

func get_best_thought() -> String:
	var best: String = ""
	var best_m: int = -999
	for t: String in SITUATIONAL_THOUGHTS:
		if SITUATIONAL_THOUGHTS[t]["mood"] > best_m:
			best_m = SITUATIONAL_THOUGHTS[t]["mood"]
			best = t
	return best

func get_thoughts_by_category(category: String) -> Array[String]:
	var result: Array[String] = []
	for t: String in SITUATIONAL_THOUGHTS:
		if SITUATIONAL_THOUGHTS[t]["category"] == category:
			result.append(t)
	return result

func get_avg_mood_effect() -> float:
	if SITUATIONAL_THOUGHTS.is_empty():
		return 0.0
	var total: float = 0.0
	for t: String in SITUATIONAL_THOUGHTS:
		total += float(SITUATIONAL_THOUGHTS[t].get("mood", 0))
	return total / SITUATIONAL_THOUGHTS.size()

func get_positive_thought_count() -> int:
	var count: int = 0
	for t: String in SITUATIONAL_THOUGHTS:
		if float(SITUATIONAL_THOUGHTS[t].get("mood", 0)) > 0:
			count += 1
	return count

func get_negative_thought_count() -> int:
	var count: int = 0
	for t: String in SITUATIONAL_THOUGHTS:
		if float(SITUATIONAL_THOUGHTS[t].get("mood", 0)) < 0:
			count += 1
	return count

func get_unique_categories() -> int:
	var cats: Dictionary = {}
	for t: String in SITUATIONAL_THOUGHTS:
		cats[String(SITUATIONAL_THOUGHTS[t].get("category", ""))] = true
	return cats.size()


func get_comfort_thought_count() -> int:
	var count: int = 0
	for t: String in SITUATIONAL_THOUGHTS:
		if String(SITUATIONAL_THOUGHTS[t].get("category", "")) == "Comfort":
			count += 1
	return count


func get_mood_range() -> int:
	var lo: int = 0
	var hi: int = 0
	for t: String in SITUATIONAL_THOUGHTS:
		var m: int = int(SITUATIONAL_THOUGHTS[t].get("mood", 0))
		if m < lo:
			lo = m
		if m > hi:
			hi = m
	return hi - lo


func get_emotional_volatility() -> float:
	var moods: Array[int] = []
	for t in SITUATIONAL_THOUGHTS.values():
		moods.append(t["mood"])
	if moods.size() < 2:
		return 0.0
	var avg := get_avg_mood_effect()
	var variance := 0.0
	for m in moods:
		variance += (m - avg) * (m - avg)
	return snapped(sqrt(variance / moods.size()), 0.01)

func get_category_pressure_pct() -> float:
	var cat_totals := {}
	for t in SITUATIONAL_THOUGHTS.values():
		var c: String = t["category"]
		cat_totals[c] = cat_totals.get(c, 0) + t["mood"]
	var negative := 0
	for v in cat_totals.values():
		if v < 0:
			negative += 1
	return snapped(float(negative) / maxf(cat_totals.size(), 1.0) * 100.0, 0.1)

func get_wellbeing_baseline() -> float:
	var total := 0.0
	for t in SITUATIONAL_THOUGHTS.values():
		total += t["mood"]
	return snapped(total / maxf(SITUATIONAL_THOUGHTS.size(), 1.0), 0.1)

func get_summary() -> Dictionary:
	return {
		"thought_types": SITUATIONAL_THOUGHTS.size(),
		"categories": 6,
		"worst_thought": get_worst_thought(),
		"best_thought": get_best_thought(),
		"avg_mood": snapped(get_avg_mood_effect(), 0.1),
		"positive_count": get_positive_thought_count(),
		"negative_count": get_negative_thought_count(),
		"unique_categories": get_unique_categories(),
		"comfort_thoughts": get_comfort_thought_count(),
		"mood_range": get_mood_range(),
		"emotional_volatility": get_emotional_volatility(),
		"category_pressure_pct": get_category_pressure_pct(),
		"wellbeing_baseline": get_wellbeing_baseline(),
		"mood_stability_index": get_mood_stability_index(),
		"environmental_comfort": get_environmental_comfort(),
		"thought_diversity_score": get_thought_diversity_score(),
		"emotional_ecosystem_health": get_emotional_ecosystem_health(),
		"wellbeing_governance": get_wellbeing_governance(),
		"psychological_maturity_index": get_psychological_maturity_index(),
	}

func get_mood_stability_index() -> float:
	var range_val := get_mood_range()
	var volatility := get_emotional_volatility()
	var penalty := 0.0
	if volatility in ["High", "Extreme"]:
		penalty = 30.0
	return snapped(maxf(0.0, 100.0 - range_val - penalty), 0.1)

func get_environmental_comfort() -> String:
	var comfort := get_comfort_thought_count()
	var positive := get_positive_thought_count()
	if comfort >= 3 and positive > 0:
		return "Cozy"
	elif comfort >= 1:
		return "Adequate"
	return "Harsh"

func get_thought_diversity_score() -> float:
	var categories := get_unique_categories()
	var total := 6
	return snapped(float(categories) / float(total) * 100.0, 0.1)

func get_emotional_ecosystem_health() -> float:
	var stability := get_mood_stability_index()
	var comfort := get_environmental_comfort()
	var c_val: float = 90.0 if comfort == "Cozy" else (60.0 if comfort == "Adequate" else 30.0)
	var baseline := get_wellbeing_baseline()
	var b_val: float = minf(maxf(baseline + 50.0, 0.0), 100.0)
	return snapped((stability + c_val + b_val) / 3.0, 0.1)

func get_psychological_maturity_index() -> float:
	var diversity := get_thought_diversity_score()
	var pressure := get_category_pressure_pct()
	var p_val: float = maxf(100.0 - pressure, 0.0)
	var volatility := get_emotional_volatility()
	var v_val: float = maxf(100.0 - volatility, 0.0)
	return snapped((diversity + p_val + v_val) / 3.0, 0.1)

func get_wellbeing_governance() -> String:
	var ecosystem := get_emotional_ecosystem_health()
	var maturity := get_psychological_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif SITUATIONAL_THOUGHTS.size() > 0:
		return "Nascent"
	return "Dormant"
