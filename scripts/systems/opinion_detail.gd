extends Node

const OPINION_FACTORS: Dictionary = {
	"Chatted": {"value": 5, "duration": 8000, "stacks": true, "max_stacks": 3},
	"Insulted": {"value": -15, "duration": 15000, "stacks": true, "max_stacks": 5},
	"RebuffedMe": {"value": -10, "duration": 12000, "stacks": true, "max_stacks": 3},
	"HadNiceChat": {"value": 10, "duration": 10000, "stacks": true, "max_stacks": 3},
	"GaveMeFood": {"value": 8, "duration": 10000, "stacks": false, "max_stacks": 1},
	"RescuedMe": {"value": 25, "duration": 30000, "stacks": false, "max_stacks": 1},
	"AttackedMe": {"value": -30, "duration": 40000, "stacks": true, "max_stacks": 5},
	"KilledMyFriend": {"value": -40, "duration": 60000, "stacks": false, "max_stacks": 1},
	"SharedMeal": {"value": 3, "duration": 5000, "stacks": true, "max_stacks": 5},
	"BeautifulPawn": {"value": 8, "duration": 0, "stacks": false, "max_stacks": 1},
	"UglyPawn": {"value": -8, "duration": 0, "stacks": false, "max_stacks": 1},
	"AnnoyingVoice": {"value": -5, "duration": 0, "stacks": false, "max_stacks": 1},
	"KindWords": {"value": 6, "duration": 8000, "stacks": true, "max_stacks": 3},
}


func calc_opinion(memories: Array) -> int:
	var total: int = 0
	for m in memories:
		var mdict: Dictionary = m if m is Dictionary else {}
		var factor_name: String = str(mdict.get("factor", ""))
		var factor: Dictionary = OPINION_FACTORS.get(factor_name, {})
		total += int(factor.get("value", 0))
	return total


func get_opinion_breakdown(memories: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for m in memories:
		var mdict: Dictionary = m if m is Dictionary else {}
		var factor_name: String = str(mdict.get("factor", ""))
		var factor: Dictionary = OPINION_FACTORS.get(factor_name, {})
		if not factor.is_empty():
			result.append({
				"factor": factor_name,
				"value": int(factor.get("value", 0)),
				"duration": int(factor.get("duration", 0)),
				"stacks": bool(factor.get("stacks", false)),
			})
	return result


func get_positive_factors() -> Array[String]:
	var result: Array[String] = []
	for f: String in OPINION_FACTORS:
		if OPINION_FACTORS[f].value > 0:
			result.append(f)
	return result


func get_negative_factors() -> Array[String]:
	var result: Array[String] = []
	for f: String in OPINION_FACTORS:
		if OPINION_FACTORS[f].value < 0:
			result.append(f)
	return result


func get_strongest_factor(memories: Array) -> Dictionary:
	var best_factor: String = ""
	var best_abs: int = 0
	for m in memories:
		var mdict: Dictionary = m if m is Dictionary else {}
		var factor_name: String = str(mdict.get("factor", ""))
		var factor: Dictionary = OPINION_FACTORS.get(factor_name, {})
		var v: int = absi(int(factor.get("value", 0)))
		if v > best_abs:
			best_abs = v
			best_factor = factor_name
	return {"factor": best_factor, "abs_value": best_abs}


func get_strongest_positive() -> String:
	var best: String = ""
	var best_val: int = 0
	for f: String in OPINION_FACTORS:
		var v: int = int(OPINION_FACTORS[f].get("value", 0))
		if v > best_val:
			best_val = v
			best = f
	return best


func get_strongest_negative() -> String:
	var worst: String = ""
	var worst_val: int = 0
	for f: String in OPINION_FACTORS:
		var v: int = int(OPINION_FACTORS[f].get("value", 0))
		if v < worst_val:
			worst_val = v
			worst = f
	return worst


func get_avg_opinion_value() -> float:
	if OPINION_FACTORS.is_empty():
		return 0.0
	var total: int = 0
	for f: String in OPINION_FACTORS:
		total += int(OPINION_FACTORS[f].get("value", 0))
	return snappedf(float(total) / float(OPINION_FACTORS.size()), 0.1)


func get_social_climate() -> String:
	var avg: float = get_avg_opinion_value()
	if avg >= 20.0:
		return "Harmonious"
	elif avg >= 5.0:
		return "Positive"
	elif avg >= -5.0:
		return "Neutral"
	return "Toxic"

func get_conflict_risk() -> bool:
	return get_negative_factors().size() > get_positive_factors().size()

func get_factor_balance() -> float:
	var pos: int = get_positive_factors().size()
	var total: int = OPINION_FACTORS.size()
	if total <= 0:
		return 0.0
	return snappedf(float(pos) / float(total) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"opinion_factors": OPINION_FACTORS.size(),
		"positive_count": get_positive_factors().size(),
		"negative_count": get_negative_factors().size(),
		"strongest_positive": get_strongest_positive(),
		"strongest_negative": get_strongest_negative(),
		"avg_value": get_avg_opinion_value(),
		"positive_pct": snappedf(float(get_positive_factors().size()) / maxf(float(OPINION_FACTORS.size()), 1.0) * 100.0, 0.1),
		"opinion_spread": absf(get_avg_opinion_value()) * 2.0,
		"social_climate": get_social_climate(),
		"conflict_risk": get_conflict_risk(),
		"factor_balance_pct": get_factor_balance(),
		"relationship_resilience": get_relationship_resilience(),
		"conflict_forecast": get_conflict_forecast(),
		"social_health_index": get_social_health_index(),
		"bond_depth_index": get_bond_depth_index(),
		"harmony_quotient": get_harmony_quotient(),
		"social_fabric_strength": get_social_fabric_strength(),
	}

func get_bond_depth_index() -> float:
	var positive := float(get_positive_factors().size())
	var total := float(OPINION_FACTORS.size())
	if total <= 0.0:
		return 0.0
	return snapped(positive / total * absf(get_avg_opinion_value()) * 2.0, 0.1)

func get_harmony_quotient() -> float:
	var balance := get_factor_balance()
	var health := get_social_health_index()
	return snapped((balance + health) / 2.0, 0.1)

func get_social_fabric_strength() -> String:
	var resilience := get_relationship_resilience()
	var forecast := get_conflict_forecast()
	if resilience == "Resilient" and forecast in ["Peaceful", "Calm"]:
		return "Unbreakable"
	elif resilience == "Fragile" or forecast in ["Volatile", "Dangerous"]:
		return "Fraying"
	return "Holding"

func get_relationship_resilience() -> String:
	var balance := get_factor_balance()
	var climate := get_social_climate()
	if balance >= 60.0 and climate in ["Warm", "Friendly"]:
		return "Resilient"
	elif balance >= 40.0:
		return "Moderate"
	return "Fragile"

func get_conflict_forecast() -> String:
	var risk: bool = get_conflict_risk()
	var avg := get_avg_opinion_value()
	if not risk and avg >= 0.0:
		return "Clear"
	elif not risk:
		return "Watch"
	return "Storm Brewing"

func get_social_health_index() -> float:
	var positive := get_positive_factors().size()
	var total := OPINION_FACTORS.size()
	if total <= 0:
		return 0.0
	return snapped(float(positive) / float(total) * 100.0, 0.1)
