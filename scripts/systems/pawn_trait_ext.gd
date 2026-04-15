extends Node

const TRAITS: Dictionary = {
	"Tough": {"label": "Tough", "category": "Physical", "effects": {"damage_mult": 0.5}, "degree": 0},
	"Wimp": {"label": "Wimp", "category": "Physical", "effects": {"pain_threshold": 0.2}, "degree": 0},
	"Brawler": {"label": "Brawler", "category": "Combat", "effects": {"melee_hit_chance": 0.12, "ranged_accuracy": -0.1}, "degree": 0},
	"Industrious": {"label": "Industrious", "category": "Work", "effects": {"work_speed": 0.35}, "degree": 2},
	"Lazy": {"label": "Lazy", "category": "Work", "effects": {"work_speed": -0.2}, "degree": -2},
	"Greedy": {"label": "Greedy", "category": "Social", "effects": {"room_req_mult": 1.5}, "degree": 0},
	"Ascetic": {"label": "Ascetic", "category": "Social", "effects": {"room_req_mult": 0.0, "food_mood_bonus": 0}, "degree": 0},
	"Pyromaniac": {"label": "Pyromaniac", "category": "Mental", "effects": {"fire_break_chance": 0.04}, "degree": 0},
	"Bloodlust": {"label": "Bloodlust", "category": "Combat", "effects": {"kill_mood": 8, "organ_harvest_mood": 0}, "degree": 0},
	"Kind": {"label": "Kind", "category": "Social", "effects": {"social_impact": 0.2, "insult_chance": 0.0}, "degree": 0},
	"Abrasive": {"label": "Abrasive", "category": "Social", "effects": {"social_impact": -0.2, "insult_chance": 0.15}, "degree": 0},
	"Iron-Willed": {"label": "Iron-Willed", "category": "Mental", "effects": {"break_threshold_mult": 0.7}, "degree": 0},
	"Volatile": {"label": "Volatile", "category": "Mental", "effects": {"break_threshold_mult": 1.4}, "degree": 0},
	"NightOwl": {"label": "Night Owl", "category": "Lifestyle", "effects": {"night_work_bonus": 0.2, "day_mood_penalty": -10}, "degree": 0},
	"Psychopath": {"label": "Psychopath", "category": "Social", "effects": {"opinion_of_others": 0, "negative_social_immunity": true}, "degree": 0},
	"Cannibal": {"label": "Cannibal", "category": "Lifestyle", "effects": {"human_meat_mood": 15, "butcher_mood": 0}, "degree": 0},
	"QuickSleeper": {"label": "Quick Sleeper", "category": "Lifestyle", "effects": {"rest_rate_mult": 1.2}, "degree": 0},
	"SlowLearner": {"label": "Slow Learner", "category": "Work", "effects": {"learn_rate_mult": 0.75}, "degree": 0},
	"FastLearner": {"label": "Fast Learner", "category": "Work", "effects": {"learn_rate_mult": 1.75}, "degree": 0},
	"Beautiful": {"label": "Beautiful", "category": "Social", "effects": {"beauty_offset": 2}, "degree": 2}
}

const EXCLUSIONS: Dictionary = {
	"Tough": ["Wimp"],
	"Brawler": [],
	"Industrious": ["Lazy"],
	"Greedy": ["Ascetic"],
	"Kind": ["Abrasive", "Psychopath"],
	"Iron-Willed": ["Volatile"],
	"NightOwl": [],
	"FastLearner": ["SlowLearner"],
	"Bloodlust": ["Kind"]
}

func can_add_trait(existing: Array, new_trait: String) -> bool:
	if not TRAITS.has(new_trait):
		return false
	for excl_key: String in EXCLUSIONS:
		var excl_list: Array = EXCLUSIONS[excl_key]
		if new_trait == excl_key and existing.has(excl_key):
			return false
		if new_trait in excl_list and excl_key in existing:
			return false
		if excl_key == new_trait:
			for e: String in excl_list:
				if e in existing:
					return false
	return true

func get_traits_by_category(category: String) -> Array[String]:
	var result: Array[String] = []
	for t: String in TRAITS:
		if TRAITS[t]["category"] == category:
			result.append(t)
	return result

func get_positive_traits() -> Array[String]:
	var result: Array[String] = []
	for t: String in TRAITS:
		var eff: Dictionary = TRAITS[t]["effects"]
		var positive: bool = false
		for k: String in eff:
			if eff[k] is float and eff[k] > 0.0:
				positive = true
			elif eff[k] is int and eff[k] > 0:
				positive = true
		if positive:
			result.append(t)
	return result

func get_category_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for t: String in TRAITS:
		var cat: String = TRAITS[t]["category"]
		dist[cat] = dist.get(cat, 0) + 1
	return dist

func get_negative_trait_count() -> int:
	var count: int = 0
	for t: String in TRAITS:
		if float(TRAITS[t].get("mood_bonus", 0)) < 0:
			count += 1
	return count


func get_avg_mood_bonus() -> float:
	if TRAITS.is_empty():
		return 0.0
	var total: float = 0.0
	for t: String in TRAITS:
		total += float(TRAITS[t].get("mood_bonus", 0))
	return total / TRAITS.size()


func get_spectrum_trait_count() -> int:
	var count: int = 0
	for t: String in TRAITS:
		if TRAITS[t].has("degree"):
			count += 1
	return count


func get_lifestyle_trait_count() -> int:
	var count: int = 0
	for t: String in TRAITS:
		if String(TRAITS[t].get("category", "")) == "Lifestyle":
			count += 1
	return count


func get_most_common_category() -> String:
	var dist: Dictionary = get_category_distribution()
	var best: String = ""
	var best_n: int = 0
	for cat: String in dist:
		if int(dist[cat]) > best_n:
			best_n = int(dist[cat])
			best = cat
	return best


func get_total_exclusion_pairs() -> int:
	var count: int = 0
	for key: String in EXCLUSIONS:
		count += EXCLUSIONS[key].size()
	return count


func get_personality_depth() -> String:
	var cats: int = get_category_distribution().size()
	if cats >= 5:
		return "complex"
	if cats >= 3:
		return "moderate"
	return "simple"

func get_conflict_potential_pct() -> float:
	var neg: int = get_negative_trait_count()
	var total: int = TRAITS.size()
	if total == 0:
		return 0.0
	return snapped(neg * 100.0 / total, 0.1)

func get_trait_balance() -> String:
	var pos: int = get_positive_traits().size()
	var neg: int = get_negative_trait_count()
	var total: int = pos + neg
	if total == 0:
		return "neutral"
	var ratio: float = pos * 1.0 / total
	if ratio >= 0.65:
		return "optimistic"
	if ratio >= 0.35:
		return "balanced"
	return "pessimistic"

func get_summary() -> Dictionary:
	return {
		"trait_count": TRAITS.size(),
		"exclusion_rules": EXCLUSIONS.size(),
		"positive_count": get_positive_traits().size(),
		"categories": get_category_distribution().size(),
		"negative_count": get_negative_trait_count(),
		"avg_mood": snapped(get_avg_mood_bonus(), 0.1),
		"spectrum_traits": get_spectrum_trait_count(),
		"lifestyle_traits": get_lifestyle_trait_count(),
		"most_common_cat": get_most_common_category(),
		"exclusion_pairs": get_total_exclusion_pairs(),
		"personality_depth": get_personality_depth(),
		"conflict_potential_pct": get_conflict_potential_pct(),
		"trait_balance": get_trait_balance(),
		"character_complexity": get_character_complexity(),
		"social_friction_index": get_social_friction_index(),
		"colony_personality_profile": get_colony_personality_profile(),
		"trait_ecosystem_health": get_trait_ecosystem_health(),
		"personality_governance": get_personality_governance(),
		"character_maturity_index": get_character_maturity_index(),
	}

func get_character_complexity() -> float:
	var spectrum := get_spectrum_trait_count()
	var lifestyle := get_lifestyle_trait_count()
	var total := TRAITS.size()
	if total <= 0:
		return 0.0
	return snapped(float(spectrum + lifestyle) / float(total) * 100.0, 0.1)

func get_social_friction_index() -> float:
	var exclusions := get_total_exclusion_pairs()
	var negative := get_negative_trait_count()
	return snapped(float(exclusions) + float(negative) * 2.0, 0.1)

func get_colony_personality_profile() -> String:
	var positive := get_positive_traits().size()
	var negative := get_negative_trait_count()
	if positive > negative * 2:
		return "Optimistic"
	elif positive >= negative:
		return "Balanced"
	return "Troubled"

func get_trait_ecosystem_health() -> float:
	var depth := get_personality_depth()
	var d_val: float = 90.0 if depth == "complex" else (60.0 if depth == "moderate" else 30.0)
	var balance := get_trait_balance()
	var b_val: float = 90.0 if balance in ["balanced", "positive"] else (60.0 if balance == "neutral" else 30.0)
	var complexity := get_character_complexity()
	return snapped((d_val + b_val + complexity) / 3.0, 0.1)

func get_character_maturity_index() -> float:
	var friction := get_social_friction_index()
	var f_val: float = maxf(100.0 - friction, 0.0)
	var conflict := get_conflict_potential_pct()
	var c_val: float = maxf(100.0 - conflict, 0.0)
	var profile := get_colony_personality_profile()
	var p_val: float = 90.0 if profile == "Optimistic" else (60.0 if profile == "Balanced" else 30.0)
	return snapped((f_val + c_val + p_val) / 3.0, 0.1)

func get_personality_governance() -> String:
	var ecosystem := get_trait_ecosystem_health()
	var maturity := get_character_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif TRAITS.size() > 0:
		return "Nascent"
	return "Dormant"
