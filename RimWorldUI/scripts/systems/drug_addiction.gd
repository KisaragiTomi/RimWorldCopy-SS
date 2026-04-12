extends Node

var _addictions: Dictionary = {}

const DRUGS: Dictionary = {
	"Smokeleaf": {"addiction_chance": 0.02, "tolerance_gain": 0.03, "severity_per_day": -0.03, "overdose_severity": 0.18},
	"Beer": {"addiction_chance": 0.01, "tolerance_gain": 0.016, "severity_per_day": -0.03, "overdose_severity": 0.08},
	"Flake": {"addiction_chance": 0.2, "tolerance_gain": 0.04, "severity_per_day": -0.045, "overdose_severity": 0.3},
	"Yayo": {"addiction_chance": 0.1, "tolerance_gain": 0.03, "severity_per_day": -0.04, "overdose_severity": 0.2},
	"GoJuice": {"addiction_chance": 0.08, "tolerance_gain": 0.06, "severity_per_day": -0.04, "overdose_severity": 0.25},
	"WakeUp": {"addiction_chance": 0.1, "tolerance_gain": 0.04, "severity_per_day": -0.04, "overdose_severity": 0.2},
	"Luciferium": {"addiction_chance": 1.0, "tolerance_gain": 0.0, "severity_per_day": 0.1, "overdose_severity": 0.0},
	"Psychite": {"addiction_chance": 0.05, "tolerance_gain": 0.02, "severity_per_day": -0.035, "overdose_severity": 0.15},
	"Ambrosia": {"addiction_chance": 0.01, "tolerance_gain": 0.02, "severity_per_day": -0.05, "overdose_severity": 0.12},
	"Penoxycyline": {"addiction_chance": 0.0, "tolerance_gain": 0.0, "severity_per_day": 0.0, "overdose_severity": 0.0}
}

const WITHDRAWAL_EFFECTS: Dictionary = {
	"Smokeleaf": {"mood": -15, "consciousness": -0.1, "duration_days": 30},
	"Beer": {"mood": -10, "consciousness": -0.05, "duration_days": 15},
	"Flake": {"mood": -25, "consciousness": -0.2, "break_chance": 0.04, "duration_days": 40},
	"Yayo": {"mood": -20, "consciousness": -0.15, "break_chance": 0.03, "duration_days": 35},
	"GoJuice": {"mood": -20, "consciousness": -0.15, "moving": -0.2, "duration_days": 25},
	"WakeUp": {"mood": -15, "consciousness": -0.1, "duration_days": 20},
	"Luciferium": {"mood": -30, "consciousness": -0.5, "break_chance": 0.1, "lethal_days": 10}
}

func use_drug(pawn_id: String, drug: String) -> Dictionary:
	if not DRUGS.has(drug):
		return {"error": "unknown_drug"}
	var d: Dictionary = DRUGS[drug]
	var addicted: bool = randf() < d["addiction_chance"]
	if addicted:
		_addictions[pawn_id + "_" + drug] = {"drug": drug, "severity": 0.5, "days_since_last": 0}
	return {"drug": drug, "addicted": addicted, "tolerance_gain": d["tolerance_gain"]}

func advance_day(pawn_id: String) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	for key: String in _addictions.keys():
		if key.begins_with(pawn_id + "_"):
			var a: Dictionary = _addictions[key]
			a["days_since_last"] += 1
			a["severity"] += DRUGS[a["drug"]]["severity_per_day"]
			if a["severity"] <= 0.0:
				_addictions.erase(key)
				effects.append({"drug": a["drug"], "cured": true})
			elif WITHDRAWAL_EFFECTS.has(a["drug"]):
				effects.append({"drug": a["drug"], "withdrawal": WITHDRAWAL_EFFECTS[a["drug"]]})
	return effects

func get_most_addictive() -> String:
	var best: String = ""
	var best_c: float = 0.0
	for d: String in DRUGS:
		if DRUGS[d]["addiction_chance"] > best_c:
			best_c = DRUGS[d]["addiction_chance"]
			best = d
	return best

func get_lethal_drugs() -> Array[String]:
	var result: Array[String] = []
	for d: String in WITHDRAWAL_EFFECTS:
		if WITHDRAWAL_EFFECTS[d].has("lethal_days"):
			result.append(d)
	return result

func get_safest_drug() -> String:
	var best: String = ""
	var best_c: float = 999.0
	for d: String in DRUGS:
		if DRUGS[d]["addiction_chance"] < best_c and DRUGS[d]["addiction_chance"] >= 0.0:
			best_c = DRUGS[d]["addiction_chance"]
			best = d
	return best

func get_least_addictive_drug() -> String:
	var best: String = ""
	var best_rate: float = 999.0
	for d: String in DRUGS:
		var r: float = float(DRUGS[d].get("addiction_chance", 999.0))
		if r < best_rate:
			best_rate = r
			best = d
	return best

func get_avg_addiction_chance() -> float:
	if DRUGS.is_empty():
		return 0.0
	var total: float = 0.0
	for d: String in DRUGS:
		total += float(DRUGS[d].get("addiction_chance", 0.0))
	return total / DRUGS.size()

func get_active_withdrawal_count() -> int:
	var count: int = 0
	for pid: int in _addictions:
		if bool(_addictions[pid].get("withdrawing", false)):
			count += 1
	return count

func get_overdose_risk_count() -> int:
	var count: int = 0
	for d: String in DRUGS:
		if float(DRUGS[d].get("overdose_severity", 0.0)) >= 0.2:
			count += 1
	return count


func get_zero_addiction_drug_count() -> int:
	var count: int = 0
	for d: String in DRUGS:
		if float(DRUGS[d].get("addiction_chance", 1.0)) <= 0.0:
			count += 1
	return count


func get_avg_withdrawal_mood() -> float:
	if WITHDRAWAL_EFFECTS.is_empty():
		return 0.0
	var total: float = 0.0
	for d: String in WITHDRAWAL_EFFECTS:
		total += float(WITHDRAWAL_EFFECTS[d].get("mood", 0))
	return total / WITHDRAWAL_EFFECTS.size()


func get_colony_sobriety() -> String:
	var addicted: int = _addictions.size()
	if addicted == 0:
		return "clean"
	if addicted >= 5:
		return "epidemic"
	if addicted >= 2:
		return "concerning"
	return "isolated"

func get_substance_danger_pct() -> float:
	var dangerous: int = 0
	for d: String in DRUGS:
		if DRUGS[d]["addiction_chance"] >= 0.1 or DRUGS[d]["overdose_severity"] >= 0.2:
			dangerous += 1
	if DRUGS.is_empty():
		return 0.0
	return snapped(dangerous * 100.0 / DRUGS.size(), 0.1)

func get_recovery_outlook() -> String:
	var withdrawing: int = get_active_withdrawal_count()
	var total_addicted: int = _addictions.size()
	if total_addicted == 0:
		return "none_needed"
	if withdrawing > 0 and withdrawing >= total_addicted:
		return "all_recovering"
	if withdrawing > 0:
		return "partial_recovery"
	return "stable_addiction"

func get_summary() -> Dictionary:
	return {
		"drug_types": DRUGS.size(),
		"withdrawal_types": WITHDRAWAL_EFFECTS.size(),
		"active_addictions": _addictions.size(),
		"most_addictive": get_most_addictive(),
		"lethal_count": get_lethal_drugs().size(),
		"safest": get_least_addictive_drug(),
		"avg_addiction_rate": snapped(get_avg_addiction_chance(), 0.01),
		"withdrawing": get_active_withdrawal_count(),
		"high_overdose_drugs": get_overdose_risk_count(),
		"zero_addiction_drugs": get_zero_addiction_drug_count(),
		"avg_withdrawal_mood": snapped(get_avg_withdrawal_mood(), 0.1),
		"colony_sobriety": get_colony_sobriety(),
		"substance_danger_pct": get_substance_danger_pct(),
		"recovery_outlook": get_recovery_outlook(),
		"addiction_cascade_risk": get_addiction_cascade_risk(),
		"harm_reduction_score": get_harm_reduction_score(),
		"substance_policy_effectiveness": get_substance_policy_effectiveness(),
		"substance_ecosystem_health": get_substance_ecosystem_health(),
		"addiction_governance": get_addiction_governance(),
		"sobriety_maturity_index": get_sobriety_maturity_index(),
	}

func get_addiction_cascade_risk() -> String:
	var active := _addictions.size()
	var lethal := get_lethal_drugs().size()
	if active >= 3 and lethal >= 2:
		return "Critical"
	elif active >= 1:
		return "Moderate"
	return "Low"

func get_harm_reduction_score() -> float:
	var safe := get_zero_addiction_drug_count()
	var total := DRUGS.size()
	if total <= 0:
		return 0.0
	return snapped(float(safe) / float(total) * 100.0, 0.1)

func get_substance_policy_effectiveness() -> String:
	var sobriety := get_colony_sobriety()
	var recovery := get_recovery_outlook()
	if sobriety in ["Sober", "Clean"] and recovery in ["Good", "Excellent"]:
		return "Effective"
	elif sobriety in ["Moderate"]:
		return "Partial"
	return "Ineffective"

func get_substance_ecosystem_health() -> float:
	var cascade := get_addiction_cascade_risk()
	var ca_val: float = 90.0 if cascade == "Low" else (50.0 if cascade == "Moderate" else 20.0)
	var policy := get_substance_policy_effectiveness()
	var p_val: float = 90.0 if policy == "Effective" else (60.0 if policy == "Partial" else 30.0)
	var harm := get_harm_reduction_score()
	return snapped((ca_val + p_val + harm) / 3.0, 0.1)

func get_sobriety_maturity_index() -> float:
	var sobriety := get_colony_sobriety()
	var s_val: float = 90.0 if sobriety in ["clean", "Sober"] else (60.0 if sobriety in ["Moderate", "moderate"] else 30.0)
	var recovery := get_recovery_outlook()
	var r_val: float = 90.0 if recovery in ["Good", "Excellent", "none_needed"] else (60.0 if recovery in ["Fair", "Partial"] else 30.0)
	var danger := get_substance_danger_pct()
	var d_val: float = maxf(100.0 - danger, 0.0)
	return snapped((s_val + r_val + d_val) / 3.0, 0.1)

func get_addiction_governance() -> String:
	var ecosystem := get_substance_ecosystem_health()
	var maturity := get_sobriety_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _addictions.size() > 0:
		return "Nascent"
	return "Dormant"
