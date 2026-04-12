extends Node

var _infections: Dictionary = {}

const INFECTION_TYPES: Dictionary = {
	"WoundInfection": {"severity_rate": 0.003, "lethal_at": 1.0, "immunity_rate": 0.005},
	"Flu": {"severity_rate": 0.002, "lethal_at": 0.9, "immunity_rate": 0.008},
	"Plague": {"severity_rate": 0.004, "lethal_at": 0.8, "immunity_rate": 0.003},
	"Malaria": {"severity_rate": 0.003, "lethal_at": 0.85, "immunity_rate": 0.004},
	"GutWorms": {"severity_rate": 0.001, "lethal_at": 0.7, "immunity_rate": 0.006},
	"MuscleParasites": {"severity_rate": 0.002, "lethal_at": 0.75, "immunity_rate": 0.005},
	"FibrousMechanites": {"severity_rate": 0.001, "lethal_at": 0.0, "immunity_rate": 0.0},
	"SensoryMechanites": {"severity_rate": 0.001, "lethal_at": 0.0, "immunity_rate": 0.0},
}

const TREATMENT_BONUS: Dictionary = {
	"None": 0.0,
	"HerbalMedicine": 0.6,
	"Medicine": 1.0,
	"GlitterworldMedicine": 1.6,
}


func add_infection(pawn_id: int, infection_type: String) -> Dictionary:
	if not INFECTION_TYPES.has(infection_type):
		return {"success": false}
	if not _infections.has(pawn_id):
		_infections[pawn_id] = []
	_infections[pawn_id].append({
		"type": infection_type,
		"severity": 0.01,
		"immunity": 0.0,
		"treated": false,
		"medicine": "None",
	})
	return {"success": true, "infection": infection_type}


func tick_infections(pawn_id: int) -> Array:
	var results: Array = []
	var infects: Array = _infections.get(pawn_id, [])
	for inf in infects:
		var id: Dictionary = inf if inf is Dictionary else {}
		var itype: String = String(id.get("type", ""))
		var data: Dictionary = INFECTION_TYPES.get(itype, {})
		var severity: float = float(id.get("severity", 0.0))
		var immunity: float = float(id.get("immunity", 0.0))
		severity += float(data.get("severity_rate", 0.0))
		var med: String = String(id.get("medicine", "None"))
		var bonus: float = float(TREATMENT_BONUS.get(med, 0.0))
		immunity += float(data.get("immunity_rate", 0.0)) * (1.0 + bonus)
		id.severity = severity
		id.immunity = immunity
		if immunity >= severity:
			results.append({"type": itype, "outcome": "immune"})
		elif severity >= float(data.get("lethal_at", 1.0)) and float(data.get("lethal_at", 0.0)) > 0.0:
			results.append({"type": itype, "outcome": "lethal"})
		else:
			results.append({"type": itype, "severity": snapped(severity, 0.01), "immunity": snapped(immunity, 0.01)})
	return results


func get_deadliest_infection() -> String:
	var best: String = ""
	var best_rate: float = 0.0
	for itype: String in INFECTION_TYPES:
		var r: float = float(INFECTION_TYPES[itype].get("severity_rate", 0.0))
		if r > best_rate:
			best_rate = r
			best = itype
	return best


func get_total_infections() -> int:
	var total: int = 0
	for pid: int in _infections:
		total += _infections[pid].size()
	return total


func get_infection_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pid: int in _infections:
		for inf in _infections[pid]:
			var id: Dictionary = inf if inf is Dictionary else {}
			var t: String = String(id.get("type", ""))
			dist[t] = dist.get(t, 0) + 1
	return dist


func get_immunity_winning_count() -> int:
	var count: int = 0
	for pid: int in _infections:
		for inf in _infections[pid]:
			var d: Dictionary = inf if inf is Dictionary else {}
			if float(d.get("immunity", 0.0)) > float(d.get("severity", 0.0)):
				count += 1
	return count


func get_untreated_count() -> int:
	var count: int = 0
	for pid: int in _infections:
		for inf in _infections[pid]:
			var d: Dictionary = inf if inf is Dictionary else {}
			if not bool(d.get("treated", false)):
				count += 1
	return count


func get_avg_severity() -> float:
	var total: float = 0.0
	var n: int = 0
	for pid: int in _infections:
		for inf in _infections[pid]:
			var d: Dictionary = inf if inf is Dictionary else {}
			total += float(d.get("severity", 0.0))
			n += 1
	return total / maxf(n, 1)


func get_lethal_infection_count() -> int:
	var count: int = 0
	for itype: String in INFECTION_TYPES:
		if float(INFECTION_TYPES[itype].get("lethal_at", 0.0)) > 0.0:
			count += 1
	return count


func get_avg_immunity_rate() -> float:
	if INFECTION_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for itype: String in INFECTION_TYPES:
		total += float(INFECTION_TYPES[itype].get("immunity_rate", 0.0))
	return snappedf(total / float(INFECTION_TYPES.size()), 0.001)


func get_treated_pct() -> float:
	var total: int = get_total_infections()
	if total == 0:
		return 0.0
	var treated: int = total - get_untreated_count()
	return snappedf(float(treated) / float(total) * 100.0, 0.1)


func get_outbreak_severity() -> String:
	var avg: float = get_avg_severity()
	if avg >= 0.7:
		return "Critical"
	elif avg >= 0.4:
		return "Serious"
	elif avg >= 0.1:
		return "Moderate"
	elif avg > 0.0:
		return "Mild"
	return "None"

func get_medical_response() -> String:
	var treated: float = get_treated_pct()
	if treated >= 90.0:
		return "Excellent"
	elif treated >= 70.0:
		return "Good"
	elif treated >= 40.0:
		return "Inadequate"
	return "Failing"

func get_pandemic_risk() -> float:
	if _infections.is_empty():
		return 0.0
	var untreated: int = get_untreated_count()
	return snappedf(float(untreated) / float(_infections.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"infection_types": INFECTION_TYPES.size(),
		"medicine_tiers": TREATMENT_BONUS.size(),
		"infected_pawns": _infections.size(),
		"total_infections": get_total_infections(),
		"deadliest": get_deadliest_infection(),
		"immunity_winning": get_immunity_winning_count(),
		"untreated": get_untreated_count(),
		"avg_severity": snapped(get_avg_severity(), 0.01),
		"lethal_types": get_lethal_infection_count(),
		"avg_immunity_rate": get_avg_immunity_rate(),
		"treated_pct": get_treated_pct(),
		"outbreak_severity": get_outbreak_severity(),
		"medical_response": get_medical_response(),
		"pandemic_risk_pct": get_pandemic_risk(),
		"healthcare_capacity": get_healthcare_capacity(),
		"disease_containment": get_disease_containment(),
		"colony_immunity_index": get_colony_immunity_index(),
		"infection_ecosystem_health": get_infection_ecosystem_health(),
		"epidemic_governance": get_epidemic_governance(),
		"pandemic_maturity_index": get_pandemic_maturity_index(),
	}

func get_healthcare_capacity() -> String:
	var response := get_medical_response()
	var treated := get_treated_pct()
	if response in ["Excellent", "Good"] and treated >= 80.0:
		return "Full Coverage"
	elif treated >= 50.0:
		return "Partial"
	return "Insufficient"

func get_disease_containment() -> String:
	var severity := get_outbreak_severity()
	var pandemic := get_pandemic_risk()
	if severity in ["None"] and pandemic < 20.0:
		return "Contained"
	elif severity in ["Mild", "None"]:
		return "Monitoring"
	return "Spreading"

func get_colony_immunity_index() -> float:
	var winning := get_immunity_winning_count()
	var total := get_total_infections()
	if total <= 0:
		return 100.0
	return snapped(float(winning) / float(total) * 100.0, 0.1)

func get_infection_ecosystem_health() -> float:
	var capacity := get_healthcare_capacity()
	var cap_val: float = 90.0 if capacity == "Full Coverage" else (60.0 if capacity == "Partial" else 30.0)
	var containment := get_disease_containment()
	var con_val: float = 90.0 if containment == "Contained" else (60.0 if containment == "Monitoring" else 30.0)
	var immunity := get_colony_immunity_index()
	return snapped((cap_val + con_val + immunity) / 3.0, 0.1)

func get_pandemic_maturity_index() -> float:
	var response := get_medical_response()
	var r_val: float = 90.0 if response == "Excellent" else (70.0 if response == "Good" else (40.0 if response == "Adequate" else 20.0))
	var pandemic := get_pandemic_risk()
	var p_val: float = maxf(100.0 - pandemic, 0.0)
	var treated := get_treated_pct()
	return snapped((r_val + p_val + treated) / 3.0, 0.1)

func get_epidemic_governance() -> String:
	var ecosystem := get_infection_ecosystem_health()
	var maturity := get_pandemic_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _infections.size() > 0:
		return "Nascent"
	return "Dormant"
