extends Node

const HEALTH_CATEGORIES: Dictionary = {
	"Excellent": {"min_percent": 90, "color": "green"},
	"Good": {"min_percent": 70, "color": "light_green"},
	"Fair": {"min_percent": 50, "color": "yellow"},
	"Poor": {"min_percent": 30, "color": "orange"},
	"Critical": {"min_percent": 10, "color": "red"},
	"Dead": {"min_percent": 0, "color": "gray"}
}

const VITAL_STATS: Array = [
	"Consciousness", "Moving", "Manipulation", "Talking",
	"Eating", "Breathing", "BloodPumping", "BloodFiltration",
	"Sight", "Hearing", "Metabolism"
]

func get_health_category(health_percent: float) -> String:
	for cat: String in HEALTH_CATEGORIES:
		if health_percent >= HEALTH_CATEGORIES[cat]["min_percent"]:
			return cat
	return "Dead"

func generate_health_report(pawn_data: Dictionary) -> Dictionary:
	var overall: float = pawn_data.get("health_percent", 100.0)
	var injuries: Array = pawn_data.get("injuries", [])
	var diseases: Array = pawn_data.get("diseases", [])
	var prosthetics: Array = pawn_data.get("prosthetics", [])
	return {
		"category": get_health_category(overall),
		"overall_percent": overall,
		"injury_count": injuries.size(),
		"disease_count": diseases.size(),
		"prosthetic_count": prosthetics.size(),
		"needs_treatment": injuries.size() > 0 or diseases.size() > 0
	}

func get_colony_health_overview(pawns: Array) -> Dictionary:
	var healthy: int = 0
	var injured: int = 0
	var sick: int = 0
	var critical: int = 0
	for p: Dictionary in pawns:
		var hp: float = p.get("health_percent", 100.0)
		if hp >= 90:
			healthy += 1
		elif hp >= 50:
			injured += 1
		elif hp >= 20:
			sick += 1
		else:
			critical += 1
	return {"healthy": healthy, "injured": injured, "sick": sick, "critical": critical}

func get_critical_threshold() -> float:
	return float(HEALTH_CATEGORIES.get("Critical", {}).get("min_percent", 10))


func get_category_thresholds() -> Dictionary:
	var result: Dictionary = {}
	for cat: String in HEALTH_CATEGORIES:
		result[cat] = int(HEALTH_CATEGORIES[cat].get("min_percent", 0))
	return result


func get_vital_stat_count() -> int:
	return VITAL_STATS.size()


func get_excellent_threshold() -> float:
	return float(HEALTH_CATEGORIES.get("Excellent", {}).get("min_percent", 90))


func get_category_count() -> int:
	return HEALTH_CATEGORIES.size()


func get_avg_threshold() -> float:
	var total: float = 0.0
	for cat: String in HEALTH_CATEGORIES:
		total += float(HEALTH_CATEGORIES[cat].get("min_percent", 0))
	return total / maxf(HEALTH_CATEGORIES.size(), 1)


func get_threshold_range() -> Dictionary:
	var lo: int = 999
	var hi: int = 0
	for cat: String in HEALTH_CATEGORIES:
		var v: int = int(HEALTH_CATEGORIES[cat].get("min_percent", 0))
		if v < lo:
			lo = v
		if v > hi:
			hi = v
	return {"min": lo, "max": hi}


func get_chronic_condition_count(pawns: Array) -> int:
	var count: int = 0
	for p: Dictionary in pawns:
		count += p.get("chronic_conditions", []).size()
	return count


func get_untreated_injury_count(pawns: Array) -> int:
	var count: int = 0
	for p: Dictionary in pawns:
		for inj in p.get("injuries", []):
			var d: Dictionary = inj if inj is Dictionary else {}
			if not bool(d.get("treated", false)):
				count += 1
	return count


func get_monitoring_depth() -> String:
	var cats: int = HEALTH_CATEGORIES.size()
	if cats >= 8:
		return "Comprehensive"
	elif cats >= 5:
		return "Thorough"
	elif cats >= 3:
		return "Basic"
	return "Minimal"

func get_vital_coverage_pct() -> float:
	if HEALTH_CATEGORIES.is_empty():
		return 0.0
	return snappedf(float(VITAL_STATS.size()) / float(HEALTH_CATEGORIES.size()) * 100.0, 0.1)

func get_diagnostic_precision() -> String:
	var range_info: Dictionary = get_threshold_range()
	var spread: float = range_info.get("max", 1.0) - range_info.get("min", 0.0)
	if spread <= 0.2:
		return "Precise"
	elif spread <= 0.4:
		return "Standard"
	elif spread <= 0.6:
		return "Broad"
	return "Coarse"

func get_summary() -> Dictionary:
	return {
		"health_categories": HEALTH_CATEGORIES.size(),
		"vital_stats": VITAL_STATS.size(),
		"critical_threshold": get_critical_threshold(),
		"excellent_threshold": get_excellent_threshold(),
		"avg_threshold": snapped(get_avg_threshold(), 0.1),
		"threshold_range": get_threshold_range(),
		"category_count": get_category_count(),
		"monitoring_depth": get_monitoring_depth(),
		"vital_coverage_pct": get_vital_coverage_pct(),
		"diagnostic_precision": get_diagnostic_precision(),
		"health_risk_assessment": get_health_risk_assessment(),
		"medical_readiness": get_medical_readiness(),
		"triage_efficiency": get_triage_efficiency(),
		"medical_ecosystem_health": get_medical_ecosystem_health(),
		"healthcare_governance": get_healthcare_governance(),
		"clinical_maturity_index": get_clinical_maturity_index(),
	}

func get_health_risk_assessment() -> String:
	var critical := get_critical_threshold()
	var avg := get_avg_threshold()
	if critical <= 0.2 and avg >= 0.5:
		return "Low Risk"
	elif avg >= 0.3:
		return "Moderate Risk"
	return "High Risk"

func get_medical_readiness() -> String:
	var coverage := get_vital_coverage_pct()
	var depth := get_monitoring_depth()
	if coverage >= 80.0 and depth in ["Comprehensive", "Advanced"]:
		return "Fully Prepared"
	elif coverage >= 50.0:
		return "Adequate"
	return "Underprepared"

func get_triage_efficiency() -> float:
	var cats := get_category_count()
	var total := HEALTH_CATEGORIES.size()
	if total <= 0:
		return 0.0
	return snapped(float(cats) / float(total) * 100.0, 0.1)

func get_medical_ecosystem_health() -> float:
	var readiness := get_medical_readiness()
	var r_val: float = 90.0 if readiness == "Fully Prepared" else (60.0 if readiness == "Adequate" else 25.0)
	var precision := get_diagnostic_precision()
	var p_val: float = 90.0 if precision == "High" else (60.0 if precision == "Moderate" else 25.0)
	var triage := get_triage_efficiency()
	return snapped((r_val + p_val + triage) / 3.0, 0.1)

func get_healthcare_governance() -> String:
	var ecosystem := get_medical_ecosystem_health()
	var risk := get_health_risk_assessment()
	var rk_val: float = 90.0 if risk == "Low Risk" else (60.0 if risk == "Moderate Risk" else 25.0)
	var combined := (ecosystem + rk_val) / 2.0
	if combined >= 70.0:
		return "Excellent"
	elif combined >= 40.0:
		return "Adequate"
	elif HEALTH_CATEGORIES.size() > 0:
		return "Deficient"
	return "None"

func get_clinical_maturity_index() -> float:
	var coverage := get_vital_coverage_pct()
	var depth := get_monitoring_depth()
	var d_val: float = 90.0 if depth == "Comprehensive" else (60.0 if depth == "Standard" else 25.0)
	return snapped((coverage + d_val) / 2.0, 0.1)
