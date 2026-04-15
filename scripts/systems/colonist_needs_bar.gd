extends Node

const NEED_THRESHOLDS: Dictionary = {
	"Food": {"critical": 0.1, "low": 0.3, "ok": 0.6},
	"Rest": {"critical": 0.1, "low": 0.25, "ok": 0.5},
	"Joy": {"critical": 0.05, "low": 0.2, "ok": 0.5},
	"Mood": {"critical": 0.15, "low": 0.3, "ok": 0.5},
}


func get_pawn_needs(pawn: Pawn) -> Array[Dictionary]:
	if not pawn.needs:
		return []
	var result: Array[Dictionary] = []
	for need_name: String in pawn.needs:
		var value: float = float(pawn.needs[need_name])
		var thresholds: Dictionary = NEED_THRESHOLDS.get(need_name, {"critical": 0.1, "low": 0.3, "ok": 0.6})
		var status: String = "ok"
		if value <= thresholds.critical:
			status = "critical"
		elif value <= thresholds.low:
			status = "low"
		elif value <= thresholds.ok:
			status = "moderate"
		result.append({
			"name": need_name,
			"value": snappedf(value, 0.01),
			"percent": int(value * 100.0),
			"status": status,
		})
	return result


func get_colony_needs_overview() -> Array[Dictionary]:
	if not PawnManager:
		return []
	var result: Array[Dictionary] = []
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		result.append({
			"name": p.pawn_name,
			"needs": get_pawn_needs(p),
		})
	return result


func get_critical_needs() -> Array[Dictionary]:
	if not PawnManager:
		return []
	var critical: Array[Dictionary] = []
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var needs: Array[Dictionary] = get_pawn_needs(p)
		for n: Dictionary in needs:
			if n.status == "critical":
				critical.append({"pawn": p.pawn_name, "need": n.name, "value": n.value})
	return critical


func get_colony_averages() -> Dictionary:
	if not PawnManager:
		return {}
	var sums: Dictionary = {}
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead or not p.needs:
			continue
		count += 1
		for need_name: String in p.needs:
			sums[need_name] = sums.get(need_name, 0.0) + float(p.needs[need_name])
	if count == 0:
		return {}
	var avgs: Dictionary = {}
	for need_name: String in sums:
		avgs[need_name] = snappedf(sums[need_name] / float(count), 0.01)
	return avgs


func get_lowest_need() -> Dictionary:
	if not PawnManager:
		return {}
	var worst_name: String = ""
	var worst_need: String = ""
	var worst_val: float = 999.0
	for p: Pawn in PawnManager.pawns:
		if p.dead or not p.needs:
			continue
		for need_name: String in p.needs:
			var v: float = float(p.needs[need_name])
			if v < worst_val:
				worst_val = v
				worst_name = p.pawn_name
				worst_need = need_name
	if worst_name.is_empty():
		return {}
	return {"pawn": worst_name, "need": worst_need, "value": snappedf(worst_val, 0.01)}


func get_needs_status_counts() -> Dictionary:
	var counts: Dictionary = {"critical": 0, "low": 0, "moderate": 0, "ok": 0}
	if not PawnManager:
		return counts
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var needs := get_pawn_needs(p)
		for n: Dictionary in needs:
			counts[n.status] = counts.get(n.status, 0) + 1
	return counts


func get_avg_need_level() -> float:
	var avgs := get_colony_averages()
	if avgs.is_empty():
		return 0.0
	var total: float = 0.0
	for k: String in avgs:
		total += avgs[k]
	return snappedf(total / float(avgs.size()), 0.01)


func get_critical_need_count() -> int:
	return get_needs_status_counts().get("critical", 0)


func get_most_deprived_need() -> String:
	var avgs := get_colony_averages()
	var worst: String = ""
	var worst_val: float = 999.0
	for k: String in avgs:
		if avgs[k] < worst_val:
			worst_val = avgs[k]
			worst = k
	return worst


func get_welfare_rating() -> String:
	var avg: float = get_avg_need_level()
	if avg >= 0.7:
		return "Thriving"
	elif avg >= 0.5:
		return "Adequate"
	elif avg >= 0.3:
		return "Struggling"
	return "Dire"

func get_satisfaction_pct() -> float:
	if NEED_THRESHOLDS.is_empty():
		return 0.0
	var satisfied: int = NEED_THRESHOLDS.size() - get_critical_need_count()
	return snappedf(float(satisfied) / float(NEED_THRESHOLDS.size()) * 100.0, 0.1)

func get_deprivation_severity() -> String:
	var crit: int = get_critical_need_count()
	if crit == 0:
		return "None"
	elif crit <= 1:
		return "Mild"
	elif crit <= 3:
		return "Severe"
	return "Critical"

func get_summary() -> Dictionary:
	return {
		"need_types": NEED_THRESHOLDS.size(),
		"critical_alerts": get_critical_needs().size(),
		"averages": get_colony_averages(),
		"lowest": get_lowest_need(),
		"status_counts": get_needs_status_counts(),
		"avg_need_level": get_avg_need_level(),
		"critical_count": get_critical_need_count(),
		"most_deprived": get_most_deprived_need(),
		"critical_pct": snappedf(float(get_critical_need_count()) / maxf(float(NEED_THRESHOLDS.size()), 1.0) * 100.0, 0.1),
		"satisfied_types": NEED_THRESHOLDS.size() - get_critical_need_count(),
		"welfare_rating": get_welfare_rating(),
		"satisfaction_pct": get_satisfaction_pct(),
		"deprivation_severity": get_deprivation_severity(),
		"welfare_safety_net": get_welfare_safety_net(),
		"deprivation_forecast": get_deprivation_forecast(),
		"need_fulfillment_efficiency": get_need_fulfillment_efficiency(),
		"wellbeing_ecosystem_health": get_wellbeing_ecosystem_health(),
		"subsistence_security_index": get_subsistence_security_index(),
		"care_infrastructure": get_care_infrastructure(),
	}

func get_wellbeing_ecosystem_health() -> float:
	var satisfaction := get_satisfaction_pct()
	var efficiency := get_need_fulfillment_efficiency()
	return snapped((satisfaction + efficiency) / 2.0, 0.1)

func get_subsistence_security_index() -> float:
	var critical := float(get_critical_need_count())
	var total := float(NEED_THRESHOLDS.size())
	if total <= 0.0:
		return 100.0
	return snapped((1.0 - critical / total) * 100.0, 0.1)

func get_care_infrastructure() -> String:
	var safety := get_welfare_safety_net()
	var forecast := get_deprivation_forecast()
	if safety == "Strong" and forecast == "Stable":
		return "Comprehensive"
	elif safety == "Weak" or forecast == "Worsening":
		return "Insufficient"
	return "Basic"

func get_welfare_safety_net() -> String:
	var satisfaction := get_satisfaction_pct()
	var critical := get_critical_need_count()
	if satisfaction >= 80.0 and critical == 0:
		return "Strong"
	elif satisfaction >= 50.0:
		return "Adequate"
	return "Weak"

func get_deprivation_forecast() -> String:
	var severity := get_deprivation_severity()
	var critical := get_critical_need_count()
	if severity == "None" and critical == 0:
		return "Clear"
	elif severity in ["None", "Minor"]:
		return "Watch"
	return "Warning"

func get_need_fulfillment_efficiency() -> float:
	var satisfied := NEED_THRESHOLDS.size() - get_critical_need_count()
	if NEED_THRESHOLDS.is_empty():
		return 0.0
	return snapped(float(satisfied) / float(NEED_THRESHOLDS.size()) * 100.0, 0.1)
