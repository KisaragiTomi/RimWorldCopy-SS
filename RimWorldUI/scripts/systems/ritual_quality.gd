extends Node

const QUALITY_FACTORS: Dictionary = {
	"RoomImpressiveness": {"weight": 0.2, "desc": "Ritual room quality"},
	"ParticipantCount": {"weight": 0.15, "desc": "Number of participants"},
	"ParticipantMood": {"weight": 0.1, "desc": "Average mood of attendees"},
	"LeaderSkill": {"weight": 0.2, "desc": "Social skill of ritual leader"},
	"Ideology_Match": {"weight": 0.15, "desc": "How well ritual fits beliefs"},
	"SpecialItems": {"weight": 0.1, "desc": "Presence of ritual-specific items"},
	"TimeOfDay": {"weight": 0.05, "desc": "Performed at preferred time"},
	"Lighting": {"weight": 0.05, "desc": "Adequate lighting in room"}
}

const QUALITY_OUTCOMES: Dictionary = {
	"Terrible": {"threshold": 0.0, "mood_effect": -5, "duration_days": 3},
	"Poor": {"threshold": 0.2, "mood_effect": 0, "duration_days": 3},
	"Decent": {"threshold": 0.4, "mood_effect": 5, "duration_days": 5},
	"Good": {"threshold": 0.6, "mood_effect": 10, "duration_days": 7},
	"Excellent": {"threshold": 0.8, "mood_effect": 18, "duration_days": 10},
	"Spectacular": {"threshold": 0.95, "mood_effect": 30, "duration_days": 15}
}

func calc_quality(factors: Dictionary) -> float:
	var total: float = 0.0
	for factor_name: String in factors:
		if QUALITY_FACTORS.has(factor_name):
			total += factors[factor_name] * QUALITY_FACTORS[factor_name]["weight"]
	return clampf(total, 0.0, 1.0)

func get_outcome(quality_score: float) -> Dictionary:
	var result: Dictionary = QUALITY_OUTCOMES["Terrible"]
	var result_name: String = "Terrible"
	for outcome: String in QUALITY_OUTCOMES:
		if quality_score >= QUALITY_OUTCOMES[outcome]["threshold"]:
			result = QUALITY_OUTCOMES[outcome]
			result_name = outcome
	return {"outcome": result_name, "mood_effect": result["mood_effect"], "duration": result["duration_days"]}

func get_most_important_factor() -> String:
	var best: String = ""
	var best_w: float = 0.0
	for f: String in QUALITY_FACTORS:
		var w: float = float(QUALITY_FACTORS[f].get("weight", 0.0))
		if w > best_w:
			best_w = w
			best = f
	return best


func get_best_outcome() -> Dictionary:
	var best: String = ""
	var best_t: float = 0.0
	for o: String in QUALITY_OUTCOMES:
		var t: float = float(QUALITY_OUTCOMES[o].get("threshold", 0.0))
		if t > best_t:
			best_t = t
			best = o
	if best == "":
		return {}
	return {"outcome": best, "mood_effect": QUALITY_OUTCOMES[best].get("mood_effect", 0), "duration": QUALITY_OUTCOMES[best].get("duration_days", 0)}


func get_total_weight() -> float:
	var total: float = 0.0
	for f: String in QUALITY_FACTORS:
		total += float(QUALITY_FACTORS[f].get("weight", 0.0))
	return total


func get_best_possible_outcome() -> String:
	var best: String = ""
	var best_mood: int = -999
	for outcome: String in QUALITY_OUTCOMES:
		var m: int = int(QUALITY_OUTCOMES[outcome].get("mood_effect", -999))
		if m > best_mood:
			best_mood = m
			best = outcome
	return best


func get_avg_outcome_mood() -> float:
	if QUALITY_OUTCOMES.is_empty():
		return 0.0
	var total: float = 0.0
	for outcome: String in QUALITY_OUTCOMES:
		total += float(QUALITY_OUTCOMES[outcome].get("mood_effect", 0))
	return total / QUALITY_OUTCOMES.size()


func get_least_important_factor() -> String:
	var worst: String = ""
	var worst_w: float = 999.0
	for f: String in QUALITY_FACTORS:
		var w: float = float(QUALITY_FACTORS[f].get("weight", 999.0))
		if w < worst_w:
			worst_w = w
			worst = f
	return worst


func get_worst_outcome_mood() -> int:
	var worst: int = 999
	for o: String in QUALITY_OUTCOMES:
		var m: int = int(QUALITY_OUTCOMES[o].get("mood_effect", 999))
		if m < worst:
			worst = m
	return worst


func get_avg_factor_weight() -> float:
	if QUALITY_FACTORS.is_empty():
		return 0.0
	var total: float = 0.0
	for f: String in QUALITY_FACTORS:
		total += float(QUALITY_FACTORS[f].get("weight", 0.0))
	return snappedf(total / float(QUALITY_FACTORS.size()), 0.01)


func get_positive_outcome_count() -> int:
	var count: int = 0
	for o: String in QUALITY_OUTCOMES:
		if int(QUALITY_OUTCOMES[o].get("mood_effect", 0)) > 0:
			count += 1
	return count


func get_ceremony_excellence() -> String:
	var positive: int = get_positive_outcome_count()
	var total: int = QUALITY_OUTCOMES.size()
	if total == 0:
		return "Unknown"
	var ratio: float = float(positive) / float(total)
	if ratio >= 0.7:
		return "Outstanding"
	if ratio >= 0.4:
		return "Adequate"
	return "Underwhelming"


func get_mood_swing_range() -> float:
	var best: float = get_avg_outcome_mood()
	var worst: float = float(get_worst_outcome_mood())
	return snappedf(absf(best - worst), 0.1)


func get_preparation_depth() -> String:
	var factors: int = QUALITY_FACTORS.size()
	if factors >= 6:
		return "Thorough"
	if factors >= 3:
		return "Standard"
	return "Minimal"


func get_summary() -> Dictionary:
	return {
		"quality_factors": QUALITY_FACTORS.size(),
		"quality_outcomes": QUALITY_OUTCOMES.size(),
		"most_important_factor": get_most_important_factor(),
		"total_weight": get_total_weight(),
		"best_outcome": get_best_possible_outcome(),
		"avg_outcome_mood": snapped(get_avg_outcome_mood(), 0.1),
		"least_important": get_least_important_factor(),
		"worst_outcome_mood": get_worst_outcome_mood(),
		"avg_factor_weight": get_avg_factor_weight(),
		"positive_outcomes": get_positive_outcome_count(),
		"ceremony_excellence": get_ceremony_excellence(),
		"mood_swing_range": get_mood_swing_range(),
		"preparation_depth": get_preparation_depth(),
		"ritual_mastery": get_ritual_mastery(),
		"congregation_impact": get_congregation_impact(),
		"spiritual_consistency": get_spiritual_consistency(),
		"ritual_ecosystem_health": get_ritual_ecosystem_health(),
		"ceremonial_governance": get_ceremonial_governance(),
		"sacred_maturity_index": get_sacred_maturity_index(),
	}

func get_ritual_mastery() -> String:
	var excellence := get_ceremony_excellence()
	var depth := get_preparation_depth()
	if excellence in ["Magnificent", "Legendary"] and depth in ["Deep", "Thorough"]:
		return "Grandmaster"
	elif excellence in ["Good", "Magnificent"]:
		return "Practiced"
	return "Novice"

func get_congregation_impact() -> float:
	var avg_mood := get_avg_outcome_mood()
	var positive := get_positive_outcome_count()
	var total := QUALITY_OUTCOMES.size()
	if total <= 0:
		return 0.0
	return snapped(avg_mood * (float(positive) / float(total)), 0.1)

func get_spiritual_consistency() -> String:
	var swing := get_mood_swing_range()
	if swing <= 10.0:
		return "Unwavering"
	elif swing <= 25.0:
		return "Steady"
	return "Volatile"

func get_ritual_ecosystem_health() -> float:
	var mastery := get_ritual_mastery()
	var m_val: float = 90.0 if mastery == "Exalted" else (60.0 if mastery == "Proficient" else 25.0)
	var impact := get_congregation_impact()
	var consistency := get_spiritual_consistency()
	var c_val: float = 90.0 if consistency == "Unwavering" else (60.0 if consistency == "Steady" else 25.0)
	return snapped((m_val + minf(impact * 5.0, 100.0) + c_val) / 3.0, 0.1)

func get_ceremonial_governance() -> String:
	var ecosystem := get_ritual_ecosystem_health()
	var excellence := get_ceremony_excellence()
	var e_val: float = 90.0 if excellence in ["Magnificent", "Legendary"] else (60.0 if excellence in ["Good", "Fine"] else 25.0)
	var combined := (ecosystem + e_val) / 2.0
	if combined >= 70.0:
		return "Sacred"
	elif combined >= 40.0:
		return "Reverent"
	elif QUALITY_FACTORS.size() > 0:
		return "Mundane"
	return "None"

func get_sacred_maturity_index() -> float:
	var depth := get_preparation_depth()
	var d_val: float = 90.0 if depth in ["Deep", "Thorough"] else (60.0 if depth == "Moderate" else 25.0)
	var swing := get_mood_swing_range()
	var swing_score: float = maxf(100.0 - swing * 2.0, 0.0)
	return snapped((d_val + swing_score) / 2.0, 0.1)
