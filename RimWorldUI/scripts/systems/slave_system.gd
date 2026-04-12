extends Node

var _slaves: Dictionary = {}

const SUPPRESSION_METHODS: Dictionary = {
	"SlaveCollar": {"suppression": 0.3, "comfort_penalty": -0.1},
	"SlaveBodystrap": {"suppression": 0.15, "comfort_penalty": -0.05},
	"Terror": {"suppression": 0.2, "mood_penalty": -8},
	"Kindness": {"suppression": -0.05, "mood_bonus": 5, "recruit_chance": 0.01}
}

const REVOLT_THRESHOLD: float = 0.2
const SUPPRESSION_DECAY_PER_DAY: float = 0.02

func enslave(pawn_id: int) -> Dictionary:
	_slaves[pawn_id] = {"suppression": 0.5, "mood_offset": -10, "revolt_risk": 0.0}
	return {"enslaved": true, "pawn_id": pawn_id}

func apply_suppression(pawn_id: int, method: String) -> Dictionary:
	if not _slaves.has(pawn_id):
		return {"error": "not_slave"}
	if not SUPPRESSION_METHODS.has(method):
		return {"error": "unknown_method"}
	var info: Dictionary = SUPPRESSION_METHODS[method]
	_slaves[pawn_id]["suppression"] = clampf(_slaves[pawn_id]["suppression"] + info["suppression"], 0.0, 1.0)
	return {"suppression": _slaves[pawn_id]["suppression"], "method": method}

func advance_day() -> Dictionary:
	var revolts: Array = []
	for pid: int in _slaves:
		_slaves[pid]["suppression"] -= SUPPRESSION_DECAY_PER_DAY
		if _slaves[pid]["suppression"] < 0:
			_slaves[pid]["suppression"] = 0.0
		_slaves[pid]["revolt_risk"] = maxf(0.0, REVOLT_THRESHOLD - _slaves[pid]["suppression"])
		if randf() < _slaves[pid]["revolt_risk"] * 0.1:
			revolts.append(pid)
	return {"slave_count": _slaves.size(), "revolts": revolts}

func free_slave(pawn_id: int) -> Dictionary:
	if not _slaves.has(pawn_id):
		return {"error": "not_slave"}
	_slaves.erase(pawn_id)
	return {"freed": true, "pawn_id": pawn_id}

func get_revolt_risk_pawns() -> Array:
	var result: Array = []
	for pid: int in _slaves:
		if float(_slaves[pid].get("revolt_risk", 0.0)) > 0.0:
			result.append(pid)
	return result


func get_average_suppression() -> float:
	if _slaves.is_empty():
		return 0.0
	var total: float = 0.0
	for pid: int in _slaves:
		total += float(_slaves[pid].get("suppression", 0.0))
	return total / float(_slaves.size())


func get_strongest_suppression() -> String:
	var best: String = ""
	var best_s: float = 0.0
	for m: String in SUPPRESSION_METHODS:
		var s: float = float(SUPPRESSION_METHODS[m].get("suppression", 0.0))
		if s > best_s:
			best_s = s
			best = m
	return best


func get_strongest_suppression_method() -> String:
	var best: String = ""
	var best_val: float = 0.0
	for m: String in SUPPRESSION_METHODS:
		var v: float = float(SUPPRESSION_METHODS[m].get("suppression", 0.0))
		if v > best_val:
			best_val = v
			best = m
	return best


func get_high_suppression_count() -> int:
	var count: int = 0
	for pid: int in _slaves:
		if float(_slaves[pid].get("suppression", 0.0)) > 0.7:
			count += 1
	return count


func get_recruitable_count() -> int:
	var count: int = 0
	for pid: int in _slaves:
		if float(_slaves[pid].get("suppression", 0.0)) < 0.3:
			count += 1
	return count


func get_kindness_method_exists() -> bool:
	return SUPPRESSION_METHODS.has("Kindness")


func get_avg_comfort_penalty() -> float:
	var total: float = 0.0
	var count: int = 0
	for m: String in SUPPRESSION_METHODS:
		if SUPPRESSION_METHODS[m].has("comfort_penalty"):
			total += float(SUPPRESSION_METHODS[m].get("comfort_penalty", 0.0))
			count += 1
	if count == 0:
		return 0.0
	return snappedf(total / float(count), 0.01)


func get_low_suppression_count() -> int:
	var count: int = 0
	for pid: int in _slaves:
		if float(_slaves[pid].get("suppression", 0.0)) < REVOLT_THRESHOLD:
			count += 1
	return count


func get_stability_rating() -> String:
	var risk: int = get_revolt_risk_pawns().size()
	var total: int = _slaves.size()
	if total == 0:
		return "NoSlaves"
	var ratio: float = float(risk) / float(total)
	if ratio == 0.0:
		return "Secure"
	if ratio < 0.3:
		return "Watchful"
	return "Volatile"


func get_control_efficiency_pct() -> float:
	var high: int = get_high_suppression_count()
	var total: int = _slaves.size()
	if total == 0:
		return 0.0
	return snappedf(float(high) / float(total) * 100.0, 0.1)


func get_integration_potential() -> String:
	var recruitable: int = get_recruitable_count()
	var total: int = _slaves.size()
	if total == 0:
		return "None"
	var ratio: float = float(recruitable) / float(total)
	if ratio >= 0.5:
		return "High"
	if ratio >= 0.2:
		return "Moderate"
	return "Low"


func get_summary() -> Dictionary:
	return {
		"suppression_methods": SUPPRESSION_METHODS.size(),
		"slave_count": _slaves.size(),
		"revolt_threshold": REVOLT_THRESHOLD,
		"revolt_risk_count": get_revolt_risk_pawns().size(),
		"avg_suppression": get_average_suppression(),
		"strongest_method": get_strongest_suppression_method(),
		"high_suppression": get_high_suppression_count(),
		"recruitable": get_recruitable_count(),
		"has_kindness": get_kindness_method_exists(),
		"avg_comfort_penalty": get_avg_comfort_penalty(),
		"low_suppression": get_low_suppression_count(),
		"stability_rating": get_stability_rating(),
		"control_efficiency_pct": get_control_efficiency_pct(),
		"integration_potential": get_integration_potential(),
		"oppression_index": get_oppression_index(),
		"rebellion_forecast": get_rebellion_forecast(),
		"labor_exploitation_rate": get_labor_exploitation_rate(),
		"servitude_ecosystem_health": get_servitude_ecosystem_health(),
		"slave_governance": get_slave_governance(),
		"bondage_maturity_index": get_bondage_maturity_index(),
	}

func get_oppression_index() -> float:
	var avg := get_average_suppression()
	var comfort := get_avg_comfort_penalty()
	return snapped(avg + absf(comfort), 0.1)

func get_rebellion_forecast() -> String:
	var risk := get_revolt_risk_pawns().size()
	var total := _slaves.size()
	if total <= 0:
		return "No Slaves"
	var ratio := float(risk) / float(total)
	if ratio >= 0.5:
		return "Imminent"
	elif ratio >= 0.2:
		return "Simmering"
	return "Contained"

func get_labor_exploitation_rate() -> float:
	var total := _slaves.size()
	var recruitable := get_recruitable_count()
	if total <= 0:
		return 0.0
	return snapped(float(total - recruitable) / float(total) * 100.0, 0.1)

func get_servitude_ecosystem_health() -> float:
	var stability := get_stability_rating()
	var s_val: float = 90.0 if stability == "Rock Solid" else (70.0 if stability == "Stable" else (40.0 if stability == "Shaky" else 20.0))
	var control := get_control_efficiency_pct()
	var exploitation := get_labor_exploitation_rate()
	return snapped((s_val + control + exploitation) / 3.0, 0.1)

func get_bondage_maturity_index() -> float:
	var oppression := get_oppression_index()
	var rebellion := get_rebellion_forecast()
	var r_val: float = 90.0 if rebellion == "Contained" else (50.0 if rebellion == "Simmering" else (20.0 if rebellion == "Imminent" else 60.0))
	var exploitation := get_labor_exploitation_rate()
	return snapped((minf(oppression, 100.0) + r_val + exploitation) / 3.0, 0.1)

func get_slave_governance() -> String:
	var ecosystem := get_servitude_ecosystem_health()
	var maturity := get_bondage_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _slaves.size() > 0:
		return "Nascent"
	return "Dormant"
