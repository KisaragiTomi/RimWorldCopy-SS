extends Node

var _pawn_hediffs: Dictionary = {}

const HEDIFF_TYPES: Dictionary = {
	"Asthma": {"chronic": true, "severity_base": 0.3, "breath_penalty": -0.15, "treatable": true},
	"BadBack": {"chronic": true, "severity_base": 0.4, "move_penalty": -0.20, "treatable": false},
	"Cataracts": {"chronic": true, "severity_base": 0.3, "sight_penalty": -0.25, "treatable": true},
	"Dementia": {"chronic": true, "severity_base": 0.5, "consciousness_penalty": -0.15, "treatable": false},
	"Frailty": {"chronic": true, "severity_base": 0.4, "move_penalty": -0.30, "treatable": false},
	"HearingLoss": {"chronic": true, "severity_base": 0.3, "hearing_penalty": -0.30, "treatable": true},
	"Carcinoma": {"chronic": true, "severity_base": 0.2, "progresses": true, "lethal_at": 1.0, "treatable": true},
	"Artery": {"chronic": true, "severity_base": 0.5, "bleed_rate": 0.001, "treatable": true},
	"ChemicalDamage": {"chronic": true, "severity_base": 0.6, "consciousness_penalty": -0.10, "treatable": false},
	"MuscleParasites": {"chronic": false, "severity_base": 0.3, "move_penalty": -0.15, "duration_days": 15, "treatable": true},
	"GutWorms": {"chronic": false, "severity_base": 0.2, "hunger_rate": 1.5, "duration_days": 20, "treatable": true},
	"FibrousMechanites": {"chronic": false, "severity_base": 0.4, "breath_penalty": -0.20, "duration_days": 30, "treatable": true}
}

func add_hediff(pawn_id: int, hediff_type: String, severity: float = -1.0) -> bool:
	if not HEDIFF_TYPES.has(hediff_type):
		return false
	if not _pawn_hediffs.has(pawn_id):
		_pawn_hediffs[pawn_id] = []
	var sev: float = severity if severity >= 0 else HEDIFF_TYPES[hediff_type]["severity_base"]
	_pawn_hediffs[pawn_id].append({"type": hediff_type, "severity": sev, "tended": false, "days": 0})
	return true

func get_hediffs(pawn_id: int) -> Array:
	return _pawn_hediffs.get(pawn_id, [])

func tend_hediff(pawn_id: int, hediff_idx: int, medicine_quality: float) -> bool:
	if not _pawn_hediffs.has(pawn_id):
		return false
	var hediffs: Array = _pawn_hediffs[pawn_id]
	if hediff_idx < 0 or hediff_idx >= hediffs.size():
		return false
	hediffs[hediff_idx]["tended"] = true
	hediffs[hediff_idx]["severity"] = maxf(0.0, hediffs[hediff_idx]["severity"] - medicine_quality * 0.1)
	return true

func get_total_penalties(pawn_id: int) -> Dictionary:
	var penalties: Dictionary = {"move": 0.0, "sight": 0.0, "consciousness": 0.0, "hearing": 0.0}
	for h: Dictionary in get_hediffs(pawn_id):
		var htype: Dictionary = HEDIFF_TYPES.get(h["type"], {})
		if htype.has("move_penalty"):
			penalties["move"] += htype["move_penalty"] * h["severity"]
		if htype.has("sight_penalty"):
			penalties["sight"] += htype["sight_penalty"] * h["severity"]
		if htype.has("consciousness_penalty"):
			penalties["consciousness"] += htype["consciousness_penalty"] * h["severity"]
		if htype.has("hearing_penalty"):
			penalties["hearing"] += htype["hearing_penalty"] * h["severity"]
	return penalties

func get_treatable_hediffs() -> Array[String]:
	var result: Array[String] = []
	for h: String in HEDIFF_TYPES:
		if bool(HEDIFF_TYPES[h].get("treatable", false)):
			result.append(h)
	return result


func get_most_afflicted_pawn() -> Dictionary:
	var best_id: int = -1
	var best_count: int = 0
	for pid: int in _pawn_hediffs:
		if _pawn_hediffs[pid].size() > best_count:
			best_count = _pawn_hediffs[pid].size()
			best_id = pid
	if best_id < 0:
		return {}
	return {"pawn_id": best_id, "hediff_count": best_count}


func get_total_hediff_count() -> int:
	var total: int = 0
	for pid: int in _pawn_hediffs:
		total += _pawn_hediffs[pid].size()
	return total


func get_chronic_count() -> int:
	var count: int = 0
	for pid: int in _pawn_hediffs:
		for h: Dictionary in _pawn_hediffs[pid]:
			var htype: Dictionary = HEDIFF_TYPES.get(h.get("type", ""), {})
			if bool(htype.get("chronic", false)):
				count += 1
	return count


func get_avg_hediffs_per_pawn() -> float:
	if _pawn_hediffs.is_empty():
		return 0.0
	return float(get_total_hediff_count()) / _pawn_hediffs.size()


func get_untended_count() -> int:
	var count: int = 0
	for pid: int in _pawn_hediffs:
		for h: Dictionary in _pawn_hediffs[pid]:
			if not bool(h.get("tended", false)):
				count += 1
	return count


func get_colony_health_status() -> String:
	var avg: float = get_avg_hediffs_per_pawn()
	if avg <= 0.5:
		return "Healthy"
	elif avg <= 1.5:
		return "Fair"
	elif avg <= 3.0:
		return "Ailing"
	return "Critical"

func get_medical_burden_pct() -> float:
	if _pawn_hediffs.is_empty():
		return 0.0
	var needing_care: int = get_treatable_hediffs().size() + get_untended_count()
	return snappedf(float(needing_care) / maxf(float(get_total_hediff_count()), 1.0) * 100.0, 0.1)

func get_chronic_risk() -> String:
	var chronic: int = get_chronic_count()
	if chronic == 0:
		return "None"
	elif chronic <= 3:
		return "Low"
	elif chronic <= 8:
		return "Moderate"
	return "High"

func get_summary() -> Dictionary:
	return {
		"hediff_types": HEDIFF_TYPES.size(),
		"tracked_pawns": _pawn_hediffs.size(),
		"total_hediffs": get_total_hediff_count(),
		"treatable": get_treatable_hediffs().size(),
		"chronic": get_chronic_count(),
		"avg_per_pawn": snapped(get_avg_hediffs_per_pawn(), 0.1),
		"untended": get_untended_count(),
		"colony_health_status": get_colony_health_status(),
		"medical_burden_pct": get_medical_burden_pct(),
		"chronic_risk": get_chronic_risk(),
		"treatment_priority": get_treatment_priority(),
		"health_forecast": get_health_forecast(),
		"care_efficiency": get_care_efficiency(),
		"hediff_ecosystem_health": get_hediff_ecosystem_health(),
		"medical_governance": get_medical_governance(),
		"wellness_maturity_index": get_wellness_maturity_index(),
	}

func get_treatment_priority() -> String:
	var untended := get_untended_count()
	var chronic := get_chronic_count()
	if untended >= 3:
		return "Critical"
	elif untended > 0 or chronic >= 5:
		return "High"
	elif chronic > 0:
		return "Normal"
	return "Low"

func get_health_forecast() -> String:
	var status := get_colony_health_status()
	var burden := get_medical_burden_pct()
	if status in ["Healthy", "Good"] and burden < 30.0:
		return "Improving"
	elif burden < 60.0:
		return "Stable"
	return "Deteriorating"

func get_care_efficiency() -> float:
	var treatable := get_treatable_hediffs().size()
	var untended := get_untended_count()
	if treatable <= 0:
		return 100.0
	return snapped(float(treatable - untended) / float(treatable) * 100.0, 0.1)

func get_hediff_ecosystem_health() -> float:
	var forecast := get_health_forecast()
	var f_val: float = 90.0 if forecast == "Improving" else (60.0 if forecast == "Stable" else 30.0)
	var care := get_care_efficiency()
	var priority := get_treatment_priority()
	var p_val: float = 90.0 if priority == "Low" else (70.0 if priority == "Normal" else (40.0 if priority == "High" else 20.0))
	return snapped((f_val + care + p_val) / 3.0, 0.1)

func get_wellness_maturity_index() -> float:
	var status := get_colony_health_status()
	var s_val: float = 90.0 if status in ["Healthy", "Good"] else (60.0 if status in ["Fair", "Moderate"] else 30.0)
	var burden := get_medical_burden_pct()
	var b_val: float = maxf(100.0 - burden, 0.0)
	var risk := get_chronic_risk()
	var r_val: float = 90.0 if risk == "None" else (60.0 if risk == "Low" else (40.0 if risk == "Moderate" else 20.0))
	return snapped((s_val + b_val + r_val) / 3.0, 0.1)

func get_medical_governance() -> String:
	var ecosystem := get_hediff_ecosystem_health()
	var maturity := get_wellness_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _pawn_hediffs.size() > 0:
		return "Nascent"
	return "Dormant"
