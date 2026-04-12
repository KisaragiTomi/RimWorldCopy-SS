extends Node

var _harvest_log: Array = []

const ORGANS: Dictionary = {
	"Heart": {"value": 500, "lethal": true, "body_part": "Torso", "surgery_difficulty": 0.8},
	"Lung": {"value": 400, "lethal": false, "body_part": "Torso", "surgery_difficulty": 0.6, "max_harvest": 1},
	"Kidney": {"value": 250, "lethal": false, "body_part": "Torso", "surgery_difficulty": 0.5, "max_harvest": 1},
	"Liver": {"value": 500, "lethal": true, "body_part": "Torso", "surgery_difficulty": 0.7},
	"Stomach": {"value": 200, "lethal": false, "body_part": "Torso", "surgery_difficulty": 0.6},
	"Eye": {"value": 300, "lethal": false, "body_part": "Head", "surgery_difficulty": 0.4, "max_harvest": 1},
	"Ear": {"value": 150, "lethal": false, "body_part": "Head", "surgery_difficulty": 0.3, "max_harvest": 1},
	"Nose": {"value": 100, "lethal": false, "body_part": "Head", "surgery_difficulty": 0.3},
	"Jaw": {"value": 200, "lethal": false, "body_part": "Head", "surgery_difficulty": 0.5}
}

const MOOD_PENALTY_HARVESTED: int = -5
const MOOD_PENALTY_WITNESSED: int = -6
const MOOD_PENALTY_COLONY: int = -4

func perform_harvest(surgeon_id: int, patient_id: int, organ: String, surgery_skill: float) -> Dictionary:
	if not ORGANS.has(organ):
		return {"success": false, "reason": "unknown_organ"}
	var info: Dictionary = ORGANS[organ]
	var difficulty: float = info["surgery_difficulty"]
	var success_chance: float = clampf(surgery_skill * 0.08 - difficulty * 0.3 + 0.5, 0.1, 0.98)
	var success: bool = randf() < success_chance
	var result: Dictionary = {
		"organ": organ,
		"success": success,
		"lethal": info["lethal"] if success else false,
		"value": info["value"] if success else 0,
		"mood_penalties": {
			"colony": MOOD_PENALTY_COLONY,
			"witnessed": MOOD_PENALTY_WITNESSED
		}
	}
	_harvest_log.append({"surgeon": surgeon_id, "patient": patient_id, "organ": organ, "success": success})
	return result

func get_organ_value(organ: String) -> int:
	return ORGANS.get(organ, {}).get("value", 0)

func get_harvest_success_rate() -> float:
	if _harvest_log.is_empty():
		return 0.0
	var successes: int = 0
	for entry: Dictionary in _harvest_log:
		if bool(entry.get("success", false)):
			successes += 1
	return float(successes) / float(_harvest_log.size())


func get_lethal_organs() -> Array[String]:
	var result: Array[String] = []
	for o: String in ORGANS:
		if bool(ORGANS[o].get("lethal", false)):
			result.append(o)
	return result


func get_total_value_harvested() -> int:
	var total: int = 0
	for entry: Dictionary in _harvest_log:
		if bool(entry.get("success", false)):
			var organ_name: String = String(entry.get("organ", ""))
			total += int(ORGANS.get(organ_name, {}).get("value", 0))
	return total


func get_avg_value_per_organ() -> float:
	var total: float = 0.0
	for o: String in ORGANS:
		total += float(ORGANS[o].get("value", 0))
	return total / maxf(ORGANS.size(), 1)


func get_most_harvested_organ() -> String:
	var counts: Dictionary = {}
	for entry: Dictionary in _harvest_log:
		var o: String = String(entry.get("organ", ""))
		counts[o] = counts.get(o, 0) + 1
	var best: String = ""
	var best_count: int = 0
	for o: String in counts:
		if int(counts[o]) > best_count:
			best_count = int(counts[o])
			best = o
	return best


func get_failure_count() -> int:
	var count: int = 0
	for entry: Dictionary in _harvest_log:
		if not bool(entry.get("success", false)):
			count += 1
	return count


func get_head_organ_count() -> int:
	var count: int = 0
	for o: String in ORGANS:
		if String(ORGANS[o].get("body_part", "")) == "Head":
			count += 1
	return count


func get_highest_value_organ() -> String:
	var best: String = ""
	var best_val: int = 0
	for o: String in ORGANS:
		var v: int = int(ORGANS[o].get("value", 0))
		if v > best_val:
			best_val = v
			best = o
	return best


func get_avg_difficulty() -> float:
	if ORGANS.is_empty():
		return 0.0
	var total: float = 0.0
	for o: String in ORGANS:
		total += float(ORGANS[o].get("surgery_difficulty", 0.0))
	return snappedf(total / float(ORGANS.size()), 0.01)


func get_ethics_rating() -> String:
	if _harvest_log.is_empty():
		return "Clean"
	var lethal_ratio: float = float(get_lethal_organs().size()) / float(ORGANS.size())
	if lethal_ratio >= 0.5:
		return "Ruthless"
	elif lethal_ratio >= 0.25:
		return "Questionable"
	return "Restrained"

func get_surgical_competence() -> String:
	var rate: float = get_harvest_success_rate()
	if rate >= 0.9:
		return "Expert"
	elif rate >= 0.7:
		return "Competent"
	elif rate >= 0.4:
		return "Risky"
	return "Dangerous"

func get_profit_efficiency_pct() -> float:
	if _harvest_log.is_empty():
		return 0.0
	var avg_val: float = get_avg_value_per_organ()
	return snappedf(clampf(avg_val / 1000.0 * 100.0, 0.0, 100.0), 0.1)

func get_summary() -> Dictionary:
	return {
		"organ_types": ORGANS.size(),
		"total_harvests": _harvest_log.size(),
		"success_rate": get_harvest_success_rate(),
		"lethal_organs": get_lethal_organs().size(),
		"total_value": get_total_value_harvested(),
		"avg_organ_value": snapped(get_avg_value_per_organ(), 0.1),
		"most_harvested": get_most_harvested_organ(),
		"failures": get_failure_count(),
		"head_organs": get_head_organ_count(),
		"highest_value": get_highest_value_organ(),
		"avg_difficulty": get_avg_difficulty(),
		"ethics_rating": get_ethics_rating(),
		"surgical_competence": get_surgical_competence(),
		"profit_efficiency_pct": get_profit_efficiency_pct(),
		"organ_market_value": get_organ_market_value(),
		"surgical_risk_tolerance": get_surgical_risk_tolerance(),
		"harvest_yield_quality": get_harvest_yield_quality(),
		"surgical_ecosystem_health": get_surgical_ecosystem_health(),
		"bioethics_governance": get_bioethics_governance(),
		"medical_enterprise_index": get_medical_enterprise_index(),
	}

func get_organ_market_value() -> float:
	var total := get_total_value_harvested()
	var harvests := _harvest_log.size()
	if harvests <= 0:
		return 0.0
	return snapped(float(total) / float(harvests), 0.1)

func get_surgical_risk_tolerance() -> String:
	var lethal_pct := 0.0
	var total := _harvest_log.size()
	if total > 0:
		lethal_pct = float(get_lethal_organs().size()) / float(ORGANS.size()) * 100.0
	if lethal_pct >= 40.0:
		return "Reckless"
	elif lethal_pct >= 15.0:
		return "Moderate"
	return "Cautious"

func get_harvest_yield_quality() -> String:
	var success := get_harvest_success_rate()
	if success >= 90.0:
		return "Excellent"
	elif success >= 70.0:
		return "Good"
	elif success > 0.0:
		return "Poor"
	return "None"

func get_surgical_ecosystem_health() -> float:
	var success := get_harvest_success_rate()
	var competence := get_surgical_competence()
	var c_val: float = 90.0 if competence == "Expert" else (60.0 if competence == "Competent" else 30.0)
	var efficiency := get_profit_efficiency_pct()
	return snapped((success + c_val + efficiency) / 3.0, 0.1)

func get_bioethics_governance() -> String:
	var ethics := get_ethics_rating()
	var risk := get_surgical_risk_tolerance()
	var r_val: float = 90.0 if risk == "Cautious" else (50.0 if risk == "Moderate" else 10.0)
	var e_val: float = 90.0 if ethics == "Ethical" else (50.0 if ethics == "Questionable" else 10.0)
	var combined := (r_val + e_val) / 2.0
	if combined >= 70.0:
		return "Responsible"
	elif combined >= 40.0:
		return "Pragmatic"
	elif _harvest_log.size() > 0:
		return "Ruthless"
	return "Inactive"

func get_medical_enterprise_index() -> float:
	var yield_q := get_harvest_yield_quality()
	var y_val: float = 90.0 if yield_q == "Excellent" else (70.0 if yield_q == "Good" else 30.0)
	var market := get_organ_market_value()
	return snapped((y_val + minf(market * 0.1, 100.0)) / 2.0, 0.1)
