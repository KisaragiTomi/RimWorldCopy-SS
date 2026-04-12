extends Node

var _pawn_heat: Dictionary = {}

const MAX_HEAT: float = 100.0
const HEAT_RECOVERY_RATE: float = 0.15
const OVERHEAT_THRESHOLD: float = 80.0

const ABILITY_HEAT_COST: Dictionary = {
	"Skip": 12.0, "Stun": 8.0, "Berserk": 35.0, "Invisibility": 40.0,
	"BerserkPulse": 55.0, "MassHeal": 60.0, "Farskip": 45.0,
	"WordOfJoy": 15.0, "Burden": 8.0, "BlindingPulse": 20.0,
	"NeuralHeatDump": 0.0, "Waterskip": 10.0
}

func add_heat(pawn_id: int, ability_name: String) -> Dictionary:
	var cost: float = ABILITY_HEAT_COST.get(ability_name, 10.0)
	var current: float = _pawn_heat.get(pawn_id, 0.0)
	var new_heat: float = minf(current + cost, MAX_HEAT + 20.0)
	_pawn_heat[pawn_id] = new_heat
	var overheated: bool = new_heat >= MAX_HEAT
	var downed: bool = new_heat >= MAX_HEAT + 10.0
	return {"heat": new_heat, "overheated": overheated, "downed": downed}

func recover_heat(pawn_id: int, delta: float) -> float:
	if not _pawn_heat.has(pawn_id):
		return 0.0
	_pawn_heat[pawn_id] = maxf(0.0, _pawn_heat[pawn_id] - HEAT_RECOVERY_RATE * delta)
	return _pawn_heat[pawn_id]

func get_heat(pawn_id: int) -> float:
	return _pawn_heat.get(pawn_id, 0.0)

func get_heat_percent(pawn_id: int) -> float:
	return _pawn_heat.get(pawn_id, 0.0) / MAX_HEAT

func can_use_ability(pawn_id: int, ability_name: String) -> bool:
	var cost: float = ABILITY_HEAT_COST.get(ability_name, 10.0)
	var current: float = _pawn_heat.get(pawn_id, 0.0)
	return current + cost <= MAX_HEAT

func get_overheated_pawns() -> Array[int]:
	var result: Array[int] = []
	for pid: int in _pawn_heat:
		if _pawn_heat[pid] >= OVERHEAT_THRESHOLD:
			result.append(pid)
	return result


func get_cheapest_ability() -> String:
	var best: String = ""
	var best_cost: float = 999.0
	for a: String in ABILITY_HEAT_COST:
		if ABILITY_HEAT_COST[a] > 0 and ABILITY_HEAT_COST[a] < best_cost:
			best_cost = ABILITY_HEAT_COST[a]
			best = a
	return best


func get_most_expensive_ability() -> String:
	var worst: String = ""
	var worst_cost: float = 0.0
	for a: String in ABILITY_HEAT_COST:
		if ABILITY_HEAT_COST[a] > worst_cost:
			worst_cost = ABILITY_HEAT_COST[a]
			worst = a
	return worst


func get_avg_heat() -> float:
	if _pawn_heat.is_empty():
		return 0.0
	var total: float = 0.0
	for pid: int in _pawn_heat:
		total += _pawn_heat[pid]
	return total / _pawn_heat.size()


func get_avg_heat_cost() -> float:
	var total: float = 0.0
	var n: int = 0
	for a: String in ABILITY_HEAT_COST:
		if ABILITY_HEAT_COST[a] > 0:
			total += ABILITY_HEAT_COST[a]
			n += 1
	return total / maxf(n, 1)


func get_heat_utilization() -> float:
	if _pawn_heat.is_empty():
		return 0.0
	var total_pct: float = 0.0
	for pid: int in _pawn_heat:
		total_pct += _pawn_heat[pid] / MAX_HEAT
	return total_pct / _pawn_heat.size()


func get_free_heat_abilities() -> int:
	var count: int = 0
	for a: String in ABILITY_HEAT_COST:
		if ABILITY_HEAT_COST[a] <= 0.0:
			count += 1
	return count


func get_heat_cost_range() -> Dictionary:
	var lo: float = 999.0
	var hi: float = 0.0
	for a: String in ABILITY_HEAT_COST:
		if ABILITY_HEAT_COST[a] > 0:
			if ABILITY_HEAT_COST[a] < lo:
				lo = ABILITY_HEAT_COST[a]
		if ABILITY_HEAT_COST[a] > hi:
			hi = ABILITY_HEAT_COST[a]
	return {"min": snapped(lo, 0.1), "max": snapped(hi, 0.1)}


func get_safe_count() -> int:
	var count: int = 0
	for pid: int in _pawn_heat:
		if _pawn_heat[pid] < OVERHEAT_THRESHOLD:
			count += 1
	return count


func get_burnout_risk() -> String:
	if _pawn_heat.is_empty():
		return "N/A"
	var overheated: int = get_overheated_pawns().size()
	var ratio: float = float(overheated) / float(_pawn_heat.size())
	if ratio >= 0.5:
		return "Critical"
	elif ratio >= 0.25:
		return "High"
	elif ratio >= 0.1:
		return "Moderate"
	return "Low"

func get_heat_efficiency() -> String:
	var util: float = get_heat_utilization()
	if util >= 0.7:
		return "Optimal"
	elif util >= 0.4:
		return "Good"
	elif util >= 0.15:
		return "Underused"
	return "Dormant"

func get_psycaster_safety_pct() -> float:
	if _pawn_heat.is_empty():
		return 100.0
	return snappedf(float(get_safe_count()) / float(_pawn_heat.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"ability_heat_types": ABILITY_HEAT_COST.size(),
		"tracked_pawns": _pawn_heat.size(),
		"max_heat": MAX_HEAT,
		"overheated": get_overheated_pawns().size(),
		"avg_heat": snapped(get_avg_heat(), 0.1),
		"avg_cost": snapped(get_avg_heat_cost(), 0.1),
		"utilization": snapped(get_heat_utilization(), 0.01),
		"free_abilities": get_free_heat_abilities(),
		"cost_range": get_heat_cost_range(),
		"safe_count": get_safe_count(),
		"burnout_risk": get_burnout_risk(),
		"heat_efficiency": get_heat_efficiency(),
		"psycaster_safety_pct": get_psycaster_safety_pct(),
		"heat_management_skill": get_heat_management_skill(),
		"psionic_endurance": get_psionic_endurance(),
		"safe_cast_margin": get_safe_cast_margin(),
		"heat_ecosystem_health": get_heat_ecosystem_health(),
		"neural_governance": get_neural_governance(),
		"psycaster_maturity_index": get_psycaster_maturity_index(),
	}

func get_heat_management_skill() -> String:
	var efficiency := get_heat_efficiency()
	var safety := get_psycaster_safety_pct()
	if efficiency in ["Excellent"] and safety >= 80.0:
		return "Expert"
	elif efficiency in ["Good", "Excellent"]:
		return "Skilled"
	return "Novice"

func get_psionic_endurance() -> float:
	var safe := get_safe_count()
	var total := _pawn_heat.size()
	if total <= 0:
		return 100.0
	return snapped(float(safe) / float(total) * 100.0, 0.1)

func get_safe_cast_margin() -> String:
	var avg := get_avg_heat()
	var max_h := float(MAX_HEAT)
	if max_h <= 0.0:
		return "N/A"
	var pct := avg / max_h * 100.0
	if pct < 30.0:
		return "Wide"
	elif pct < 70.0:
		return "Moderate"
	return "Narrow"

func get_heat_ecosystem_health() -> float:
	var skill := get_heat_management_skill()
	var sk_val: float = 90.0 if skill in ["Expert", "Master"] else (60.0 if skill in ["Competent", "Moderate"] else 30.0)
	var endurance := get_psionic_endurance()
	var e_val: float = 90.0 if endurance in ["Tireless", "Strong"] else (60.0 if endurance in ["Moderate", "Average"] else 30.0)
	var margin := get_safe_cast_margin()
	var m_val: float = 90.0 if margin == "Wide" else (60.0 if margin == "Moderate" else 30.0)
	return snapped((sk_val + e_val + m_val) / 3.0, 0.1)

func get_psycaster_maturity_index() -> float:
	var risk := get_burnout_risk()
	var r_val: float = 90.0 if risk in ["None", "Low"] else (50.0 if risk in ["Moderate"] else 20.0)
	var efficiency := get_heat_efficiency()
	var ef_val: float = 90.0 if efficiency in ["Excellent", "Optimal"] else (60.0 if efficiency in ["Good", "Moderate"] else 30.0)
	var safety := get_psycaster_safety_pct()
	return snapped((r_val + ef_val + safety) / 3.0, 0.1)

func get_neural_governance() -> String:
	var ecosystem := get_heat_ecosystem_health()
	var maturity := get_psycaster_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _pawn_heat.size() > 0:
		return "Nascent"
	return "Dormant"
