extends Node

const ENVIRONMENT_THOUGHTS: Dictionary = {
	"ImpressiveRoom": {"mood": 6, "threshold": "beauty >= 50"},
	"DecentRoom": {"mood": 3, "threshold": "beauty >= 20"},
	"UglyRoom": {"mood": -3, "threshold": "beauty < -10"},
	"HorribleRoom": {"mood": -6, "threshold": "beauty < -30"},
	"Cramped": {"mood": -5, "threshold": "space < 12"},
	"Spacious": {"mood": 3, "threshold": "space >= 30"},
	"Dirty": {"mood": -3, "threshold": "filth >= 3"},
	"VeryDirty": {"mood": -6, "threshold": "filth >= 8"},
	"DarkRoom": {"mood": -3, "threshold": "light < 0.3"},
	"BrightRoom": {"mood": 2, "threshold": "light >= 0.7"},
	"Outdoors": {"mood": -3, "threshold": "roofed == false"},
	"Shared Bedroom": {"mood": -4, "threshold": "bed_count >= 2"},
}


func evaluate_room(beauty: float, space: float, filth: int, light: float, roofed: bool, bed_count: int) -> Array:
	var active_thoughts: Array = []
	if beauty >= 50:
		active_thoughts.append({"thought": "ImpressiveRoom", "mood": 6})
	elif beauty >= 20:
		active_thoughts.append({"thought": "DecentRoom", "mood": 3})
	elif beauty < -30:
		active_thoughts.append({"thought": "HorribleRoom", "mood": -6})
	elif beauty < -10:
		active_thoughts.append({"thought": "UglyRoom", "mood": -3})

	if space < 12:
		active_thoughts.append({"thought": "Cramped", "mood": -5})
	elif space >= 30:
		active_thoughts.append({"thought": "Spacious", "mood": 3})

	if filth >= 8:
		active_thoughts.append({"thought": "VeryDirty", "mood": -6})
	elif filth >= 3:
		active_thoughts.append({"thought": "Dirty", "mood": -3})

	if light < 0.3:
		active_thoughts.append({"thought": "DarkRoom", "mood": -3})
	elif light >= 0.7:
		active_thoughts.append({"thought": "BrightRoom", "mood": 2})

	if not roofed:
		active_thoughts.append({"thought": "Outdoors", "mood": -3})
	if bed_count >= 2:
		active_thoughts.append({"thought": "Shared Bedroom", "mood": -4})

	return active_thoughts


func get_total_mood_from_room(beauty: float, space: float, filth: int, light: float, roofed: bool, bed_count: int) -> int:
	var thoughts: Array = evaluate_room(beauty, space, filth, light, roofed, bed_count)
	var total: int = 0
	for t: Dictionary in thoughts:
		total += int(t.get("mood", 0))
	return total


func get_positive_thoughts() -> Array[String]:
	var result: Array[String] = []
	for tid: String in ENVIRONMENT_THOUGHTS:
		if int(ENVIRONMENT_THOUGHTS[tid].get("mood", 0)) > 0:
			result.append(tid)
	return result


func get_negative_thoughts() -> Array[String]:
	var result: Array[String] = []
	for tid: String in ENVIRONMENT_THOUGHTS:
		if int(ENVIRONMENT_THOUGHTS[tid].get("mood", 0)) < 0:
			result.append(tid)
	return result


func get_strongest_positive_thought() -> String:
	var best: String = ""
	var best_val: int = 0
	for t: String in ENVIRONMENT_THOUGHTS:
		var v: int = int(ENVIRONMENT_THOUGHTS[t].get("mood_offset", 0))
		if v > best_val:
			best_val = v
			best = t
	return best


func get_strongest_negative_thought() -> String:
	var worst: String = ""
	var worst_val: int = 0
	for t: String in ENVIRONMENT_THOUGHTS:
		var v: int = int(ENVIRONMENT_THOUGHTS[t].get("mood_offset", 0))
		if v < worst_val:
			worst_val = v
			worst = t
	return worst


func get_avg_mood_offset() -> float:
	if ENVIRONMENT_THOUGHTS.is_empty():
		return 0.0
	var total: int = 0
	for t: String in ENVIRONMENT_THOUGHTS:
		total += int(ENVIRONMENT_THOUGHTS[t].get("mood_offset", 0))
	return snappedf(float(total) / float(ENVIRONMENT_THOUGHTS.size()), 0.1)


func get_mood_range() -> Dictionary:
	var lo: int = 0
	var hi: int = 0
	for t: String in ENVIRONMENT_THOUGHTS:
		var v: int = int(ENVIRONMENT_THOUGHTS[t].get("mood", 0))
		if v < lo:
			lo = v
		if v > hi:
			hi = v
	return {"worst": lo, "best": hi}


func get_worst_possible_mood() -> int:
	var total: int = 0
	for t: String in ENVIRONMENT_THOUGHTS:
		var v: int = int(ENVIRONMENT_THOUGHTS[t].get("mood", 0))
		if v < 0:
			total += v
	return total


func get_positive_ratio_pct() -> float:
	if ENVIRONMENT_THOUGHTS.is_empty():
		return 0.0
	return snappedf(float(get_positive_thoughts().size()) / float(ENVIRONMENT_THOUGHTS.size()) * 100.0, 0.1)


func get_ambient_mood() -> String:
	var avg: float = get_avg_mood_offset()
	if avg >= 5.0:
		return "Uplifting"
	elif avg >= 0.0:
		return "Neutral"
	elif avg >= -5.0:
		return "Depressing"
	return "Miserable"

func get_environmental_risk() -> float:
	var neg: int = get_negative_thoughts().size()
	var total: int = ENVIRONMENT_THOUGHTS.size()
	if total == 0:
		return 0.0
	return snappedf(float(neg) / float(total) * 100.0, 0.1)

func get_comfort_balance() -> String:
	var pos_ratio: float = get_positive_ratio_pct()
	if pos_ratio >= 70.0:
		return "Comfortable"
	elif pos_ratio >= 40.0:
		return "Mixed"
	elif pos_ratio > 0.0:
		return "Uncomfortable"
	return "Hostile"

func get_summary() -> Dictionary:
	return {
		"thought_types": ENVIRONMENT_THOUGHTS.size(),
		"positive_count": get_positive_thoughts().size(),
		"negative_count": get_negative_thoughts().size(),
		"strongest_positive": get_strongest_positive_thought(),
		"strongest_negative": get_strongest_negative_thought(),
		"avg_offset": get_avg_mood_offset(),
		"mood_range": get_mood_range(),
		"worst_possible_mood": get_worst_possible_mood(),
		"positive_ratio_pct": get_positive_ratio_pct(),
		"ambient_mood": get_ambient_mood(),
		"environmental_risk_pct": get_environmental_risk(),
		"comfort_balance": get_comfort_balance(),
		"living_quality_index": get_living_quality_index(),
		"mood_environment_synergy": get_mood_environment_synergy(),
		"atmosphere_rating": get_atmosphere_rating(),
		"environmental_wellbeing_index": get_environmental_wellbeing_index(),
		"habitat_governance": get_habitat_governance(),
		"ambient_maturity": get_ambient_maturity(),
	}

func get_living_quality_index() -> float:
	var pos_ratio := get_positive_ratio_pct()
	var avg := get_avg_mood_offset()
	return snapped((pos_ratio + maxf(avg + 50.0, 0.0)) / 2.0, 0.1)

func get_mood_environment_synergy() -> String:
	var ambiance := get_ambient_mood()
	var balance := get_comfort_balance()
	if ambiance in ["Pleasant", "Uplifting"] and balance in ["Comfortable"]:
		return "Harmonious"
	elif ambiance in ["Neutral", "Pleasant"]:
		return "Neutral"
	return "Discordant"

func get_atmosphere_rating() -> String:
	var risk := get_environmental_risk()
	var positive_pct := get_positive_ratio_pct()
	if risk < 20.0 and positive_pct >= 60.0:
		return "Excellent"
	elif risk < 40.0:
		return "Good"
	elif risk < 60.0:
		return "Fair"
	return "Poor"

func get_environmental_wellbeing_index() -> float:
	var quality := get_living_quality_index()
	var atmosphere := get_atmosphere_rating()
	var a_val: float = 90.0 if atmosphere == "Excellent" else (70.0 if atmosphere == "Good" else (50.0 if atmosphere == "Fair" else 20.0))
	var synergy := get_mood_environment_synergy()
	var s_val: float = 90.0 if synergy == "Harmonious" else (60.0 if synergy == "Neutral" else 30.0)
	return snapped((quality + a_val + s_val) / 3.0, 0.1)

func get_habitat_governance() -> String:
	var wellbeing := get_environmental_wellbeing_index()
	var balance := get_comfort_balance()
	if wellbeing >= 65.0 and balance in ["Comfortable", "Cozy"]:
		return "Optimized"
	elif wellbeing >= 35.0:
		return "Adequate"
	return "Neglected"

func get_ambient_maturity() -> float:
	var positive_ratio := get_positive_ratio_pct()
	var risk := get_environmental_risk()
	return snapped((positive_ratio + maxf(100.0 - risk, 0.0)) / 2.0, 0.1)
