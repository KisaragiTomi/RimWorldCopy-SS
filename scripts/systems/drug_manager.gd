extends Node

## Manages drug policies, addictions, and consumption effects.
## Registered as autoload "DrugManager".

const DRUG_DEFS: Dictionary = {
	"Beer": {
		"label": "Beer",
		"joy": 0.15,
		"mood": 0.05,
		"consciousness_offset": -0.03,
		"addiction_chance": 0.01,
		"tolerance_gain": 0.015,
		"category": "Social",
	},
	"Smokeleaf": {
		"label": "Smokeleaf joint",
		"joy": 0.20,
		"mood": 0.10,
		"consciousness_offset": -0.10,
		"addiction_chance": 0.02,
		"tolerance_gain": 0.03,
		"category": "Social",
	},
	"Penoxycyline": {
		"label": "Penoxycyline",
		"joy": 0.0,
		"mood": 0.0,
		"consciousness_offset": 0.0,
		"addiction_chance": 0.0,
		"tolerance_gain": 0.0,
		"category": "Medical",
		"disease_immunity": 0.5,
	},
	"GoJuice": {
		"label": "Go-juice",
		"joy": 0.10,
		"mood": 0.05,
		"consciousness_offset": 0.10,
		"addiction_chance": 0.08,
		"tolerance_gain": 0.04,
		"category": "Hard",
		"pain_offset": -0.5,
	},
	"Yayo": {
		"label": "Yayo",
		"joy": 0.25,
		"mood": 0.15,
		"consciousness_offset": 0.05,
		"addiction_chance": 0.05,
		"tolerance_gain": 0.04,
		"category": "Hard",
	},
}

var pawn_addictions: Dictionary = {}  # pawn_id -> Array[{drug, severity, need}]
var pawn_tolerances: Dictionary = {}  # pawn_id -> {drug: float}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = randi()


func consume_drug(pawn: Pawn, drug_name: String) -> Dictionary:
	var def: Dictionary = DRUG_DEFS.get(drug_name, {})
	if def.is_empty():
		return {"error": "Unknown drug"}

	total_consumed += 1

	var joy_amount: float = def.get("joy", 0.0)
	if joy_amount > 0.0:
		pawn.set_need("Joy", minf(1.0, pawn.get_need("Joy") + joy_amount))

	var mood_amount: float = def.get("mood", 0.0)
	if mood_amount != 0.0 and pawn.thought_tracker:
		pawn.thought_tracker.add_thought("Drug_" + drug_name)

	_add_tolerance(pawn.id, drug_name, def.get("tolerance_gain", 0.0))
	_check_addiction(pawn.id, drug_name, def.get("addiction_chance", 0.0))
	var overdosed := check_overdose(pawn, drug_name)

	return {"consumed": drug_name, "joy": joy_amount, "mood": mood_amount, "overdosed": overdosed}


func _add_tolerance(pawn_id: int, drug_name: String, amount: float) -> void:
	if amount <= 0.0:
		return
	if not pawn_tolerances.has(pawn_id):
		pawn_tolerances[pawn_id] = {}
	var tol: Dictionary = pawn_tolerances[pawn_id]
	tol[drug_name] = minf(1.0, tol.get(drug_name, 0.0) + amount)


func _check_addiction(pawn_id: int, drug_name: String, base_chance: float) -> void:
	if base_chance <= 0.0:
		return
	var tol: float = _get_tolerance(pawn_id, drug_name)
	var chance: float = base_chance + tol * 0.15
	if _rng.randf() < chance:
		_add_addiction(pawn_id, drug_name)


func _add_addiction(pawn_id: int, drug_name: String) -> void:
	if not pawn_addictions.has(pawn_id):
		pawn_addictions[pawn_id] = []
	var addictions: Array = pawn_addictions[pawn_id]
	for a: Dictionary in addictions:
		if a.get("drug", "") == drug_name:
			a["severity"] = minf(1.0, a.get("severity", 0.5) + 0.2)
			return
	addictions.append({"drug": drug_name, "severity": 0.5, "need": 1.0})
	if ColonyLog:
		ColonyLog.add_entry("Health", "Pawn " + str(pawn_id) + " addicted to " + drug_name, "warning")


func _get_tolerance(pawn_id: int, drug_name: String) -> float:
	if not pawn_tolerances.has(pawn_id):
		return 0.0
	return pawn_tolerances[pawn_id].get(drug_name, 0.0)


var total_consumed: int = 0
var total_overdoses: int = 0

const WITHDRAWAL_THOUGHTS: Dictionary = {
	"Beer": "AlcoholWithdrawal",
	"Smokeleaf": "SmokeleafWithdrawal",
	"GoJuice": "GoJuiceWithdrawal",
	"Yayo": "YayoWithdrawal",
}
const OVERDOSE_THRESHOLD: float = 0.85


func tick_addictions() -> void:
	for pawn_id: int in pawn_addictions:
		var addictions: Array = pawn_addictions[pawn_id]
		var i := addictions.size() - 1
		while i >= 0:
			var a: Dictionary = addictions[i]
			a["need"] = maxf(0.0, a.get("need", 1.0) - 0.001)
			if a["need"] <= 0.3:
				a["severity"] = maxf(0.0, a.get("severity", 0.5) - 0.0005)
				_apply_withdrawal(pawn_id, a.get("drug", ""))
			if a["severity"] <= 0.0:
				addictions.remove_at(i)
				if ColonyLog:
					ColonyLog.add_entry("Health", "Pawn %d recovered from %s addiction." % [pawn_id, a.get("drug", "")], "info")
			i -= 1

	for pawn_id: int in pawn_tolerances:
		var tol: Dictionary = pawn_tolerances[pawn_id]
		for drug: String in tol:
			tol[drug] = maxf(0.0, tol[drug] - 0.0002)


func _apply_withdrawal(pawn_id: int, drug_name: String) -> void:
	if not PawnManager:
		return
	var thought_name: String = WITHDRAWAL_THOUGHTS.get(drug_name, "")
	if thought_name.is_empty():
		return
	for p: Pawn in PawnManager.pawns:
		if p.id == pawn_id and p.thought_tracker:
			p.thought_tracker.add_thought(thought_name)
			break


func check_overdose(pawn: Pawn, drug_name: String) -> bool:
	var tol: float = _get_tolerance(pawn.id, drug_name)
	if tol >= OVERDOSE_THRESHOLD and _rng.randf() < 0.15:
		total_overdoses += 1
		if pawn.health:
			pawn.health.add_hediff("Overdose", "Torso", 0.6)
		if ColonyLog:
			ColonyLog.add_entry("Health", "%s overdosed on %s!" % [pawn.pawn_name, drug_name], "danger")
		return true
	return false


func is_addicted(pawn_id: int, drug_name: String) -> bool:
	var addictions: Array = pawn_addictions.get(pawn_id, [])
	for a: Dictionary in addictions:
		if a.get("drug", "") == drug_name:
			return true
	return false


func get_pawn_addictions(pawn_id: int) -> Array:
	return pawn_addictions.get(pawn_id, [])


func get_all_addicts() -> Array[int]:
	var result: Array[int] = []
	for pid: int in pawn_addictions:
		if not pawn_addictions[pid].is_empty():
			result.append(pid)
	return result


func get_most_addictive_drug() -> String:
	var counts: Dictionary = {}
	for pid: int in pawn_addictions:
		for a: Dictionary in pawn_addictions[pid]:
			var d: String = a.get("drug", "Unknown")
			counts[d] = counts.get(d, 0) + 1
	var best: String = ""
	var best_c: int = 0
	for d: String in counts:
		if counts[d] > best_c:
			best_c = counts[d]
			best = d
	return best


func get_clean_pawns_count() -> int:
	var cnt: int = 0
	for pid: int in pawn_addictions:
		if pawn_addictions[pid].is_empty():
			cnt += 1
	return cnt


func get_overdose_rate() -> float:
	if total_consumed == 0:
		return 0.0
	return float(total_overdoses) / float(total_consumed)


func get_unique_drug_count() -> int:
	var types: Dictionary = {}
	for pid: int in pawn_addictions:
		for a: Dictionary in pawn_addictions[pid]:
			types[a.get("drug", "")] = true
	return types.size()


func get_addicted_pawn_count() -> int:
	var cnt: int = 0
	for pid: int in pawn_addictions:
		if not pawn_addictions[pid].is_empty():
			cnt += 1
	return cnt


func get_addiction_per_pawn() -> float:
	if pawn_addictions.is_empty():
		return 0.0
	var total: int = 0
	for pid: int in pawn_addictions:
		total += pawn_addictions[pid].size()
	return float(total) / float(pawn_addictions.size())


func get_sobriety_rate() -> float:
	if pawn_addictions.is_empty():
		return 100.0
	return snappedf(float(get_clean_pawns_count()) / float(pawn_addictions.size()) * 100.0, 0.1)


func get_most_consumed_drug() -> String:
	var by_drug: Dictionary = {}
	for pid: int in pawn_addictions:
		for a: Dictionary in pawn_addictions[pid]:
			var d: String = a.get("drug", "Unknown")
			by_drug[d] = by_drug.get(d, 0) + 1
	var best: String = ""
	var best_c: int = 0
	for d: String in by_drug:
		if by_drug[d] > best_c:
			best_c = by_drug[d]
			best = d
	return best


func get_addiction_severity_avg() -> float:
	var total: float = 0.0
	var count: int = 0
	for pid: int in pawn_addictions:
		for a: Dictionary in pawn_addictions[pid]:
			total += a.get("severity", 0.0) as float
			count += 1
	if count <= 0:
		return 0.0
	return snappedf(total / float(count), 0.01)


func get_substance_risk_level() -> String:
	var avg_sev := get_addiction_severity_avg()
	var od_rate := get_overdose_rate()
	if avg_sev > 0.6 or od_rate > 10.0:
		return "Dangerous"
	elif avg_sev > 0.3 or od_rate > 5.0:
		return "Concerning"
	elif get_addicted_pawn_count() > 0:
		return "Moderate"
	return "Minimal"


func get_recovery_outlook() -> float:
	var addicted := get_addicted_pawn_count()
	var clean := get_clean_pawns_count()
	if addicted + clean <= 0:
		return 100.0
	return snapped(float(clean) / float(addicted + clean) * 100.0, 0.1)


func get_policy_effectiveness() -> String:
	var sobriety := get_sobriety_rate()
	var od := get_overdose_rate()
	if sobriety >= 90.0 and od <= 1.0:
		return "Excellent"
	elif sobriety >= 70.0:
		return "Good"
	elif sobriety >= 50.0:
		return "Fair"
	return "Poor"


func get_summary() -> Dictionary:
	var total_addicted: int = 0
	var by_drug: Dictionary = {}
	for pid: int in pawn_addictions:
		for a: Dictionary in pawn_addictions[pid]:
			total_addicted += 1
			var d: String = a.get("drug", "Unknown")
			by_drug[d] = by_drug.get(d, 0) + 1
	return {
		"total_addictions": total_addicted,
		"tracked_pawns": pawn_addictions.size(),
		"by_drug": by_drug,
		"total_consumed": total_consumed,
		"total_overdoses": total_overdoses,
		"most_addictive": get_most_addictive_drug(),
		"clean_pawns": get_clean_pawns_count(),
		"overdose_rate": snappedf(get_overdose_rate(), 0.01),
		"unique_drugs": get_unique_drug_count(),
		"addicted_pawns": get_addicted_pawn_count(),
		"addiction_per_pawn": snappedf(get_addiction_per_pawn(), 0.01),
		"sobriety_rate_pct": get_sobriety_rate(),
		"most_consumed": get_most_consumed_drug(),
		"avg_severity": get_addiction_severity_avg(),
		"substance_risk": get_substance_risk_level(),
		"recovery_outlook": get_recovery_outlook(),
		"policy_effectiveness": get_policy_effectiveness(),
		"substance_governance_index": get_substance_governance_index(),
		"addiction_trajectory": get_addiction_trajectory(),
		"colony_sobriety_health": get_colony_sobriety_health(),
	}

func get_substance_governance_index() -> float:
	var sobriety: float = get_sobriety_rate()
	var od_rate: float = get_overdose_rate()
	var score: float = sobriety * 0.6 + (100.0 - od_rate * 100.0) * 0.4
	return snappedf(clampf(score, 0.0, 100.0), 0.1)

func get_addiction_trajectory() -> String:
	var addicted: int = get_addicted_pawn_count()
	var clean: int = get_clean_pawns_count()
	if addicted == 0:
		return "Clean"
	if clean > addicted * 2:
		return "Improving"
	if clean >= addicted:
		return "Stable"
	return "Worsening"

func get_colony_sobriety_health() -> String:
	var sobriety: float = get_sobriety_rate()
	if sobriety >= 90.0:
		return "Excellent"
	if sobriety >= 70.0:
		return "Good"
	if sobriety >= 50.0:
		return "Concerning"
	return "Critical"
