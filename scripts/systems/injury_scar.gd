extends Node

const SCAR_TYPES: Dictionary = {
	"Scar": {"pain": 0.02, "move_penalty": 0.0, "manipulation_penalty": 0.0},
	"GunScar": {"pain": 0.03, "move_penalty": 0.0, "manipulation_penalty": 0.0},
	"BurnScar": {"pain": 0.04, "move_penalty": 0.0, "manipulation_penalty": 0.0},
	"StabScar": {"pain": 0.03, "move_penalty": 0.0, "manipulation_penalty": 0.0},
	"MissingScar_Finger": {"pain": 0.01, "move_penalty": 0.0, "manipulation_penalty": 0.08},
	"MissingScar_Toe": {"pain": 0.01, "move_penalty": 0.05, "manipulation_penalty": 0.0},
	"MissingScar_Eye": {"pain": 0.02, "move_penalty": 0.0, "manipulation_penalty": 0.0, "sight_penalty": 0.5},
	"MissingScar_Ear": {"pain": 0.01, "move_penalty": 0.0, "manipulation_penalty": 0.0, "hearing_penalty": 0.5},
	"CrushedScar": {"pain": 0.05, "move_penalty": 0.1, "manipulation_penalty": 0.05},
	"ChemicalBurn": {"pain": 0.03, "move_penalty": 0.0, "manipulation_penalty": 0.02},
}

var _pawn_scars: Dictionary = {}


func add_scar(pawn_id: int, scar_type: String, body_part: String) -> Dictionary:
	if not SCAR_TYPES.has(scar_type):
		return {"success": false, "reason": "Unknown scar type"}
	if not _pawn_scars.has(pawn_id):
		_pawn_scars[pawn_id] = []
	_pawn_scars[pawn_id].append({
		"type": scar_type,
		"part": body_part,
		"tick_added": TickManager.current_tick if TickManager else 0,
	})
	return {"success": true, "type": scar_type}


func get_pawn_scars(pawn_id: int) -> Array:
	return _pawn_scars.get(pawn_id, [])


func get_total_penalties(pawn_id: int) -> Dictionary:
	var scars: Array = get_pawn_scars(pawn_id)
	var pain: float = 0.0
	var move: float = 0.0
	var manip: float = 0.0
	for s in scars:
		var sd: Dictionary = s if s is Dictionary else {}
		var stype: String = str(sd.get("type", ""))
		var effects: Dictionary = SCAR_TYPES.get(stype, {})
		pain += float(effects.get("pain", 0.0))
		move += float(effects.get("move_penalty", 0.0))
		manip += float(effects.get("manipulation_penalty", 0.0))
	return {
		"total_pain": snappedf(pain, 0.01),
		"move_penalty": snappedf(move, 0.01),
		"manipulation_penalty": snappedf(manip, 0.01),
		"scar_count": scars.size(),
	}


func get_total_scar_count() -> int:
	var total: int = 0
	for pid: int in _pawn_scars:
		total += _pawn_scars[pid].size()
	return total


func get_most_scarred_pawn() -> Dictionary:
	var best_id: int = -1
	var best_count: int = 0
	for pid: int in _pawn_scars:
		if _pawn_scars[pid].size() > best_count:
			best_count = _pawn_scars[pid].size()
			best_id = pid
	if best_id < 0:
		return {}
	return {"pawn_id": best_id, "scar_count": best_count}


func get_scar_type_distribution() -> Dictionary:
	var counts: Dictionary = {}
	for pid: int in _pawn_scars:
		for s in _pawn_scars[pid]:
			var sd: Dictionary = s if s is Dictionary else {}
			var stype: String = str(sd.get("type", ""))
			counts[stype] = counts.get(stype, 0) + 1
	return counts


func get_avg_scars_per_pawn() -> float:
	if _pawn_scars.is_empty():
		return 0.0
	return snappedf(float(get_total_scar_count()) / float(_pawn_scars.size()), 0.1)


func get_scar_free_count() -> int:
	if not PawnManager:
		return 0
	var total_pawns: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			total_pawns += 1
	return maxi(total_pawns - _pawn_scars.size(), 0)


func get_most_common_scar_type() -> String:
	var dist := get_scar_type_distribution()
	var best: String = ""
	var best_n: int = 0
	for t: String in dist:
		if dist[t] > best_n:
			best_n = dist[t]
			best = t
	return best


func get_combat_veteran_ratio() -> float:
	var total: int = _pawn_scars.size() + get_scar_free_count()
	if total <= 0:
		return 0.0
	return snappedf(float(_pawn_scars.size()) / float(total) * 100.0, 0.1)

func get_scar_severity() -> String:
	var avg: float = get_avg_scars_per_pawn()
	if avg >= 3.0:
		return "Heavy"
	elif avg >= 1.5:
		return "Moderate"
	elif avg > 0.0:
		return "Light"
	return "None"

func get_recovery_rating() -> String:
	var free_pct: float = float(get_scar_free_count()) / maxf(float(_pawn_scars.size() + get_scar_free_count()), 1.0) * 100.0
	if free_pct >= 70.0:
		return "Healthy"
	elif free_pct >= 40.0:
		return "Battle-Worn"
	return "Scarred"

func get_summary() -> Dictionary:
	return {
		"scar_types": SCAR_TYPES.size(),
		"pawns_with_scars": _pawn_scars.size(),
		"total_scars": get_total_scar_count(),
		"most_scarred": get_most_scarred_pawn(),
		"type_distribution": get_scar_type_distribution(),
		"avg_scars_per_pawn": get_avg_scars_per_pawn(),
		"scar_free": get_scar_free_count(),
		"most_common_type": get_most_common_scar_type(),
		"scar_free_pct": snappedf(float(get_scar_free_count()) / maxf(float(_pawn_scars.size() + get_scar_free_count()), 1.0) * 100.0, 0.1),
		"active_scar_types": get_scar_type_distribution().size(),
		"veteran_ratio_pct": get_combat_veteran_ratio(),
		"scar_severity": get_scar_severity(),
		"recovery_rating": get_recovery_rating(),
		"battle_hardened_index": get_battle_hardened_index(),
		"long_term_health_impact": get_long_term_health_impact(),
		"rehabilitation_outlook": get_rehabilitation_outlook(),
		"combat_legacy_index": get_combat_legacy_index(),
		"population_resilience_score": get_population_resilience_score(),
		"medical_rehabilitation_depth": get_medical_rehabilitation_depth(),
	}

func get_combat_legacy_index() -> float:
	var hardened := get_battle_hardened_index()
	var veteran := get_combat_veteran_ratio()
	return snapped(hardened * veteran / 100.0, 0.1)

func get_population_resilience_score() -> float:
	var scar_free := float(get_scar_free_count())
	var total := float(_pawn_scars.size() + get_scar_free_count())
	if total <= 0.0:
		return 0.0
	return snapped(scar_free / total * 100.0, 0.1)

func get_medical_rehabilitation_depth() -> String:
	var outlook := get_rehabilitation_outlook()
	var recovery := get_recovery_rating()
	if outlook in ["Good", "Excellent"] and recovery in ["Good", "Excellent"]:
		return "Comprehensive"
	elif outlook == "Poor":
		return "Inadequate"
	return "Basic"

func get_battle_hardened_index() -> float:
	var veterans := get_combat_veteran_ratio()
	var severity := get_scar_severity()
	if severity in ["None", "Minor"]:
		return snapped(veterans * 0.5, 0.1)
	return snapped(veterans, 0.1)

func get_long_term_health_impact() -> String:
	var avg := get_avg_scars_per_pawn()
	if avg <= 0.5:
		return "Minimal"
	elif avg <= 2.0:
		return "Moderate"
	return "Significant"

func get_rehabilitation_outlook() -> String:
	var recovery := get_recovery_rating()
	var scar_free := get_scar_free_count()
	if recovery in ["Excellent", "Good"] and scar_free > 0:
		return "Positive"
	elif recovery in ["Good", "Fair"]:
		return "Stable"
	return "Concerning"
