extends Node

## Sorts injured pawns by severity so doctors treat the most critical first.
## Registered as autoload "MedicalTriage".

enum Priority { CRITICAL, HIGH, MEDIUM, LOW, NONE }

const BLEED_CRITICAL_THRESHOLD: float = 0.15
const BLEED_HIGH_THRESHOLD: float = 0.05
const DISEASE_CRITICAL_SEVERITY: float = 0.7
const DISEASE_HIGH_SEVERITY: float = 0.4
const INFECTION_WEIGHT: float = 1.5

var _total_assessments: int = 0
var _critical_count: int = 0


func get_triage_list() -> Array[Dictionary]:
	if not PawnManager:
		return []

	var entries: Array[Dictionary] = []
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var priority := _assess(p)
		if priority == Priority.NONE:
			continue
		_total_assessments += 1
		if priority == Priority.CRITICAL:
			_critical_count += 1
		var urgency_score := _calc_urgency(p, priority)
		entries.append({
			"pawn_id": p.id,
			"pawn_name": p.pawn_name,
			"priority": priority,
			"priority_label": _label(priority),
			"urgency": urgency_score,
			"bleed_rate": p.health._bleed_rate if p.health else 0.0,
			"injuries": p.health.hediffs.size() if p.health else 0,
			"downed": p.downed,
		})

	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.priority != b.priority:
			return a.priority < b.priority
		return a.urgency > b.urgency
	)
	return entries


func get_most_critical() -> Dictionary:
	var list := get_triage_list()
	if list.is_empty():
		return {}
	return list[0]


func _assess(pawn: Pawn) -> int:
	if pawn.health == null:
		return Priority.NONE

	var h := pawn.health
	if h.hediffs.is_empty():
		return Priority.NONE

	if h._bleed_rate >= BLEED_CRITICAL_THRESHOLD:
		return Priority.CRITICAL
	if pawn.downed:
		return Priority.CRITICAL

	for hediff: Dictionary in h.hediffs:
		if hediff.get("type", "") == "Disease" and hediff.get("severity", 0.0) >= DISEASE_CRITICAL_SEVERITY:
			return Priority.CRITICAL

	if h._bleed_rate >= BLEED_HIGH_THRESHOLD:
		return Priority.HIGH

	for hediff: Dictionary in h.hediffs:
		if hediff.get("type", "") == "Disease" and hediff.get("severity", 0.0) >= DISEASE_HIGH_SEVERITY:
			return Priority.HIGH
		if hediff.get("type", "") == "Injury" and not hediff.get("tended", false):
			return Priority.HIGH

	var untended_count := 0
	for hediff: Dictionary in h.hediffs:
		if not hediff.get("tended", false):
			untended_count += 1
	if untended_count > 0:
		return Priority.MEDIUM

	return Priority.LOW


func _label(p: int) -> String:
	match p:
		Priority.CRITICAL: return "CRITICAL"
		Priority.HIGH: return "HIGH"
		Priority.MEDIUM: return "MEDIUM"
		Priority.LOW: return "LOW"
	return "NONE"


func _calc_urgency(pawn: Pawn, priority: int) -> float:
	var score: float = float(4 - priority) * 10.0
	if pawn.health:
		score += pawn.health._bleed_rate * 100.0
		for h: Dictionary in pawn.health.hediffs:
			if h.get("type", "") == "Disease":
				score += h.get("severity", 0.0) * INFECTION_WEIGHT * 10.0
			if not h.get("tended", false):
				score += 3.0
	if pawn.downed:
		score += 15.0
	return snappedf(score, 0.1)


func get_patients_by_priority(target_priority: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in get_triage_list():
		if entry.get("priority", Priority.NONE) == target_priority:
			result.append(entry)
	return result


func get_total_bleed_rate() -> float:
	var total: float = 0.0
	if not PawnManager:
		return total
	for p: Pawn in PawnManager.pawns:
		if not p.dead and p.health:
			total += p.health._bleed_rate
	return snappedf(total, 0.01)


func get_avg_urgency() -> float:
	var list := get_triage_list()
	if list.is_empty():
		return 0.0
	var total: float = 0.0
	for entry: Dictionary in list:
		total += entry.get("urgency", 0.0)
	return snappedf(total / float(list.size()), 0.1)


func get_untended_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.health == null:
			continue
		for h: Dictionary in p.health.hediffs:
			if not h.get("tended", false):
				count += 1
				break
	return count


func needs_immediate_attention() -> bool:
	var list := get_triage_list()
	for entry: Dictionary in list:
		if entry.get("priority", Priority.NONE) == Priority.CRITICAL:
			return true
	return false


func get_bleed_emergency() -> bool:
	return get_total_bleed_rate() >= BLEED_CRITICAL_THRESHOLD

func get_medical_load() -> String:
	var list := get_triage_list()
	if list.is_empty():
		return "Clear"
	elif list.size() <= 2:
		return "Light"
	elif list.size() <= 5:
		return "Moderate"
	return "Overwhelmed"

func get_high_priority_count() -> int:
	var count: int = 0
	for entry: Dictionary in get_triage_list():
		if entry.get("priority", Priority.NONE) <= Priority.HIGH:
			count += 1
	return count

func get_triage_efficiency() -> String:
	var untended := get_untended_count()
	var total := get_triage_list().size()
	if total <= 0:
		return "Idle"
	var tended_pct := 1.0 - float(untended) / float(total)
	if tended_pct >= 0.9:
		return "Excellent"
	elif tended_pct >= 0.6:
		return "Adequate"
	return "Overwhelmed"

func get_mortality_risk() -> String:
	var critical := _critical_count
	var bleed := get_total_bleed_rate()
	if critical >= 3 or bleed > 5.0:
		return "Critical"
	elif critical >= 1 or bleed > 2.0:
		return "Elevated"
	return "Low"

func get_care_quality() -> float:
	var list := get_triage_list()
	if list.is_empty():
		return 100.0
	var tended := list.size() - get_untended_count()
	return snapped(float(tended) / float(list.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	var list := get_triage_list()
	var by_priority: Dictionary = {}
	for entry: Dictionary in list:
		var pl: String = entry.get("priority_label", "NONE")
		by_priority[pl] = by_priority.get(pl, 0) + 1
	return {
		"total_patients": list.size(),
		"by_priority": by_priority,
		"total_assessments": _total_assessments,
		"critical_count": _critical_count,
		"total_bleed_rate": get_total_bleed_rate(),
		"avg_urgency": get_avg_urgency(),
		"untended": get_untended_count(),
		"needs_immediate": needs_immediate_attention(),
		"critical_pct": snappedf(float(_critical_count) / maxf(float(_total_assessments), 1.0) * 100.0, 0.1),
		"tended_rate": snappedf(1.0 - float(get_untended_count()) / maxf(float(list.size()), 1.0), 0.01),
		"bleed_emergency": get_bleed_emergency(),
		"medical_load": get_medical_load(),
		"high_priority_count": get_high_priority_count(),
		"triage_efficiency": get_triage_efficiency(),
		"mortality_risk": get_mortality_risk(),
		"care_quality_pct": get_care_quality(),
		"medical_infrastructure_rating": get_medical_infrastructure_rating(),
		"emergency_response_score": get_emergency_response_score(),
		"healthcare_sustainability": get_healthcare_sustainability(),
	}

func get_medical_infrastructure_rating() -> String:
	var quality := get_care_quality()
	var load := get_medical_load()
	if quality >= 80.0 and load in ["Light", "Manageable"]:
		return "Advanced"
	elif quality >= 50.0:
		return "Adequate"
	return "Insufficient"

func get_emergency_response_score() -> float:
	var tended := 1.0 - float(get_untended_count()) / maxf(float(get_triage_list().size()), 1.0)
	var efficiency := get_triage_efficiency()
	var e_val: float = 1.0 if efficiency in ["Excellent", "High"] else (0.6 if efficiency in ["Good", "Adequate"] else 0.3)
	return snapped(tended * e_val * 100.0, 0.1)

func get_healthcare_sustainability() -> String:
	var risk := get_mortality_risk()
	var quality := get_care_quality()
	if risk in ["None", "Low"] and quality >= 70.0:
		return "Sustainable"
	elif risk not in ["Critical", "Extreme"]:
		return "Fragile"
	return "Unsustainable"
