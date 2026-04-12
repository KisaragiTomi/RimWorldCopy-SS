extends Node

const SEVERITY_LABELS: Array[String] = ["Minor", "Moderate", "Severe", "Critical", "Fatal"]

const WOUND_EFFECTS: Dictionary = {
	"Bruise": {"pain": 0.05, "bleed": 0.0, "move_penalty": 0.0},
	"Cut": {"pain": 0.10, "bleed": 0.05, "move_penalty": 0.0},
	"Scratch": {"pain": 0.03, "bleed": 0.02, "move_penalty": 0.0},
	"Stab": {"pain": 0.15, "bleed": 0.10, "move_penalty": 0.05},
	"Gunshot": {"pain": 0.20, "bleed": 0.15, "move_penalty": 0.10},
	"Burn": {"pain": 0.12, "bleed": 0.0, "move_penalty": 0.05},
	"Bite": {"pain": 0.08, "bleed": 0.08, "move_penalty": 0.0},
	"Crush": {"pain": 0.18, "bleed": 0.02, "move_penalty": 0.15},
	"Shattered": {"pain": 0.25, "bleed": 0.05, "move_penalty": 0.30},
}


func get_pawn_wound_summary(pawn: Pawn) -> Dictionary:
	if not pawn.health or not pawn.health.has_method("get_hediffs"):
		return {"wounds": [], "total_pain": 0.0, "total_bleed": 0.0, "move_penalty": 0.0}

	var hediffs: Array = pawn.health.get_hediffs()
	var wounds: Array[Dictionary] = []
	var total_pain: float = 0.0
	var total_bleed: float = 0.0
	var total_move: float = 0.0

	for h in hediffs:
		var hdict: Dictionary = h if h is Dictionary else {}
		var wound_type: String = str(hdict.get("type", ""))
		var severity: float = float(hdict.get("severity", 0.0))
		var part: String = str(hdict.get("part", ""))

		var effects: Dictionary = WOUND_EFFECTS.get(wound_type, {"pain": 0.05, "bleed": 0.0, "move_penalty": 0.0})
		var pain: float = effects.pain * severity
		var bleed: float = effects.bleed * severity
		var move: float = effects.move_penalty * severity

		total_pain += pain
		total_bleed += bleed
		total_move += move

		wounds.append({
			"type": wound_type,
			"part": part,
			"severity": snappedf(severity, 0.01),
			"pain": snappedf(pain, 0.001),
			"bleed": snappedf(bleed, 0.001),
		})

	return {
		"wounds": wounds,
		"total_pain": snappedf(total_pain, 0.01),
		"total_bleed": snappedf(total_bleed, 0.01),
		"move_penalty": snappedf(total_move, 0.01),
		"severity_label": _get_overall_severity(total_pain),
	}


func _get_overall_severity(total_pain: float) -> String:
	if total_pain >= 0.8:
		return "Fatal"
	if total_pain >= 0.5:
		return "Critical"
	if total_pain >= 0.3:
		return "Severe"
	if total_pain >= 0.1:
		return "Moderate"
	return "Minor"


func get_most_wounded_pawn() -> Dictionary:
	if not PawnManager:
		return {}
	var worst_name: String = ""
	var worst_pain: float = 0.0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var ws: Dictionary = get_pawn_wound_summary(p)
		if ws.total_pain > worst_pain:
			worst_pain = ws.total_pain
			worst_name = p.pawn_name
	if worst_name.is_empty():
		return {}
	return {"name": worst_name, "pain": snappedf(worst_pain, 0.01)}


func get_colony_bleed_rate() -> float:
	if not PawnManager:
		return 0.0
	var total: float = 0.0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var ws: Dictionary = get_pawn_wound_summary(p)
		total += ws.total_bleed
	return snappedf(total, 0.01)


func get_wound_type_distribution() -> Dictionary:
	if not PawnManager:
		return {}
	var counts: Dictionary = {}
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if not p.health or not p.health.has_method("get_hediffs"):
			continue
		var hediffs: Array = p.health.get_hediffs()
		for h in hediffs:
			var hdict: Dictionary = h if h is Dictionary else {}
			var wtype: String = str(hdict.get("type", "Unknown"))
			counts[wtype] = counts.get(wtype, 0) + 1
	return counts


func get_avg_bleed_per_pawn() -> float:
	if not PawnManager or PawnManager.pawns.is_empty():
		return 0.0
	var total_bleed: float = 0.0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		count += 1
		if p.health and p.health.has_method("get_hediffs"):
			for h: Dictionary in p.health.get_hediffs():
				total_bleed += h.get("bleed_rate", 0.0)
	if count == 0:
		return 0.0
	return snappedf(total_bleed / float(count), 0.01)


func get_healthy_pawn_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if p.health and p.health.has_method("get_hediffs"):
			if p.health.get_hediffs().is_empty():
				count += 1
		else:
			count += 1
	return count


func get_critical_wound_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if p.health and p.health.has_method("get_hediffs"):
			for h: Dictionary in p.health.get_hediffs():
				if h.get("severity", 0.0) > 0.8:
					count += 1
	return count


func get_medical_urgency() -> String:
	var crit: int = get_critical_wound_count()
	if crit == 0:
		return "None"
	elif crit <= 1:
		return "Low"
	elif crit <= 3:
		return "High"
	return "Emergency"

func get_colony_health_rating() -> String:
	var healthy: int = get_healthy_pawn_count()
	if not PawnManager:
		return "Unknown"
	var total: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			total += 1
	if total <= 0:
		return "Unknown"
	var ratio: float = float(healthy) / float(total)
	if ratio >= 0.9:
		return "Excellent"
	elif ratio >= 0.7:
		return "Good"
	elif ratio >= 0.5:
		return "Fair"
	return "Poor"

func is_bleed_crisis() -> bool:
	return get_colony_bleed_rate() >= 3.0

func get_summary() -> Dictionary:
	if not PawnManager:
		return {"pawn_count": 0}
	var wounded: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if p.health and p.health.has_method("get_hediffs"):
			var h: Array = p.health.get_hediffs()
			if h.size() > 0:
				wounded += 1
	return {
		"wound_types": WOUND_EFFECTS.size(),
		"wounded_pawns": wounded,
		"colony_bleed_rate": get_colony_bleed_rate(),
		"most_wounded": get_most_wounded_pawn(),
		"type_distribution": get_wound_type_distribution(),
		"avg_bleed_per_pawn": get_avg_bleed_per_pawn(),
		"healthy_pawns": get_healthy_pawn_count(),
		"critical_wounds": get_critical_wound_count(),
		"wounded_pct": snappedf(float(wounded) / maxf(float(PawnManager.pawns.size()), 1.0) * 100.0, 0.1),
		"wound_types_active": get_wound_type_distribution().size(),
		"medical_urgency": get_medical_urgency(),
		"colony_health_rating": get_colony_health_rating(),
		"bleed_crisis": is_bleed_crisis(),
		"treatment_coverage": get_treatment_coverage(),
		"casualty_posture": get_casualty_posture(),
		"recovery_outlook": get_recovery_outlook(),
		"medical_readiness_depth": get_medical_readiness_depth(),
		"trauma_management_index": get_trauma_management_index(),
		"colony_durability": get_colony_durability(),
	}

func get_medical_readiness_depth() -> float:
	var coverage := get_treatment_coverage()
	var healthy := float(get_healthy_pawn_count())
	var total := float(PawnManager.pawns.size()) if PawnManager else 1.0
	return snapped((coverage * 0.6 + healthy / maxf(total, 1.0) * 100.0 * 0.4), 0.1)

func get_trauma_management_index() -> float:
	var critical := float(get_critical_wound_count())
	var bleed := get_avg_bleed_per_pawn()
	return snapped(maxf(100.0 - critical * 15.0 - bleed * 10.0, 0.0), 0.1)

func get_colony_durability() -> String:
	var outlook := get_recovery_outlook()
	var posture := get_casualty_posture()
	if outlook == "Favorable" and posture in ["Secure", "Resilient"]:
		return "Hardy"
	elif outlook == "Critical" or posture == "Critical":
		return "Fragile"
	return "Moderate"

func get_treatment_coverage() -> float:
	if not PawnManager:
		return 100.0
	var total_wounds: int = 0
	var treated: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if p.health and p.health.has_method("get_hediffs"):
			for h: Dictionary in p.health.get_hediffs():
				total_wounds += 1
				if h.get("tended", false):
					treated += 1
	if total_wounds <= 0:
		return 100.0
	return snapped(float(treated) / float(total_wounds) * 100.0, 0.1)

func get_casualty_posture() -> String:
	var critical := get_critical_wound_count()
	var bleed := is_bleed_crisis()
	if critical == 0 and not bleed:
		return "Safe"
	elif critical <= 1:
		return "Minor Casualties"
	elif bleed:
		return "Mass Casualty"
	return "Under Pressure"

func get_recovery_outlook() -> String:
	var health := get_colony_health_rating()
	var urgency := get_medical_urgency()
	if health in ["Healthy", "Stable"] and urgency in ["None", "Low"]:
		return "Good"
	elif urgency in ["High", "Critical"]:
		return "Uncertain"
	return "Moderate"
