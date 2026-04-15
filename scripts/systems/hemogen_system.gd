extends Node

var _hemogen_levels: Dictionary = {}

const MAX_HEMOGEN: float = 100.0
const HEMOGEN_DECAY_PER_DAY: float = 4.0
const CRITICAL_THRESHOLD: float = 10.0

const HEMOGEN_SOURCES: Dictionary = {
	"BloodPack": {"gain": 30.0, "work": 0},
	"BitePrisoner": {"gain": 20.0, "mood_penalty_victim": -15},
	"BiteColonist": {"gain": 20.0, "mood_penalty_victim": -10, "opinion_penalty": -25},
	"CorpseDrain": {"gain": 15.0, "mood_penalty_self": -5},
	"AnimalDrain": {"gain": 10.0, "mood_penalty_self": 0}
}

const LOW_HEMOGEN_EFFECTS: Dictionary = {
	"move_speed": -0.2,
	"consciousness": -0.1,
	"hunger_rate": 1.5
}

func set_hemogen(pawn_id: int, amount: float) -> void:
	_hemogen_levels[pawn_id] = clampf(amount, 0.0, MAX_HEMOGEN)

func get_hemogen(pawn_id: int) -> float:
	return _hemogen_levels.get(pawn_id, MAX_HEMOGEN)

func consume_hemogen(pawn_id: int, source: String) -> Dictionary:
	if not HEMOGEN_SOURCES.has(source):
		return {"error": "unknown_source"}
	var current: float = get_hemogen(pawn_id)
	var gain: float = HEMOGEN_SOURCES[source]["gain"]
	set_hemogen(pawn_id, current + gain)
	return {"source": source, "gained": gain, "current": get_hemogen(pawn_id)}

func advance_day() -> Dictionary:
	var critical: Array = []
	for pid: int in _hemogen_levels:
		_hemogen_levels[pid] -= HEMOGEN_DECAY_PER_DAY
		if _hemogen_levels[pid] <= 0:
			_hemogen_levels[pid] = 0.0
		if _hemogen_levels[pid] < CRITICAL_THRESHOLD:
			critical.append(pid)
	return {"decayed_count": _hemogen_levels.size(), "critical_pawns": critical}

func get_critical_pawns() -> Array:
	var result: Array = []
	for pid: int in _hemogen_levels:
		if float(_hemogen_levels[pid]) < CRITICAL_THRESHOLD:
			result.append(pid)
	return result


func get_best_source() -> String:
	var best: String = ""
	var best_gain: float = 0.0
	for s: String in HEMOGEN_SOURCES:
		var g: float = float(HEMOGEN_SOURCES[s].get("gain", 0.0))
		if g > best_gain:
			best_gain = g
			best = s
	return best


func get_average_hemogen() -> float:
	if _hemogen_levels.is_empty():
		return 0.0
	var total: float = 0.0
	for pid: int in _hemogen_levels:
		total += float(_hemogen_levels[pid])
	return total / float(_hemogen_levels.size())


func get_best_hemogen_source() -> String:
	var best: String = ""
	var best_gain: float = 0.0
	for src: String in HEMOGEN_SOURCES:
		var g: float = float(HEMOGEN_SOURCES[src].get("gain", 0.0))
		if g > best_gain:
			best_gain = g
			best = src
	return best


func get_full_hemogen_count() -> int:
	var count: int = 0
	for pid: int in _hemogen_levels:
		if float(_hemogen_levels[pid]) >= MAX_HEMOGEN:
			count += 1
	return count


func get_days_until_critical(pawn_id: int) -> float:
	var current: float = _hemogen_levels.get(pawn_id, MAX_HEMOGEN)
	var needed: float = current - CRITICAL_THRESHOLD
	if needed <= 0.0:
		return 0.0
	return needed / HEMOGEN_DECAY_PER_DAY


func get_safe_pawn_count() -> int:
	var count: int = 0
	for pid: int in _hemogen_levels:
		if float(_hemogen_levels[pid]) >= 50.0:
			count += 1
	return count


func get_harmful_source_count() -> int:
	var count: int = 0
	for s: String in HEMOGEN_SOURCES:
		if float(HEMOGEN_SOURCES[s].get("mood_penalty_victim", 0.0)) < 0 or float(HEMOGEN_SOURCES[s].get("mood_penalty_self", 0.0)) < 0:
			count += 1
	return count


func get_avg_gain_per_source() -> float:
	if HEMOGEN_SOURCES.is_empty():
		return 0.0
	var total: float = 0.0
	for s: String in HEMOGEN_SOURCES:
		total += float(HEMOGEN_SOURCES[s].get("gain", 0.0))
	return snappedf(total / float(HEMOGEN_SOURCES.size()), 0.1)


func get_supply_stability() -> String:
	var critical: int = get_critical_pawns().size()
	var total: int = _hemogen_levels.size()
	if total == 0:
		return "NoData"
	var ratio: float = float(critical) / float(total)
	if ratio == 0.0:
		return "Stable"
	if ratio < 0.3:
		return "Strained"
	return "Crisis"


func get_self_sufficiency_pct() -> float:
	var safe: int = get_safe_pawn_count()
	var total: int = _hemogen_levels.size()
	if total == 0:
		return 0.0
	return snappedf(float(safe) / float(total) * 100.0, 0.1)


func get_ethical_sourcing() -> String:
	var harmful: int = get_harmful_source_count()
	var total: int = HEMOGEN_SOURCES.size()
	if total == 0:
		return "NoData"
	var ratio: float = float(harmful) / float(total)
	if ratio >= 0.5:
		return "Questionable"
	if ratio >= 0.2:
		return "Mixed"
	return "Clean"


func get_summary() -> Dictionary:
	return {
		"hemogen_sources": HEMOGEN_SOURCES.size(),
		"tracked_pawns": _hemogen_levels.size(),
		"max_hemogen": MAX_HEMOGEN,
		"decay_per_day": HEMOGEN_DECAY_PER_DAY,
		"critical_count": get_critical_pawns().size(),
		"avg_hemogen": get_average_hemogen(),
		"best_source": get_best_hemogen_source(),
		"full_count": get_full_hemogen_count(),
		"safe_pawns": get_safe_pawn_count(),
		"harmful_sources": get_harmful_source_count(),
		"avg_gain": get_avg_gain_per_source(),
		"supply_stability": get_supply_stability(),
		"self_sufficiency_pct": get_self_sufficiency_pct(),
		"ethical_sourcing": get_ethical_sourcing(),
		"blood_economy_health": get_blood_economy_health(),
		"reserve_adequacy": get_reserve_adequacy(),
		"consumption_sustainability": get_consumption_sustainability(),
		"hemogen_ecosystem_health": get_hemogen_ecosystem_health(),
		"blood_governance": get_blood_governance(),
		"vampiric_maturity_index": get_vampiric_maturity_index(),
	}

func get_blood_economy_health() -> String:
	var stability := get_supply_stability()
	var self_suff := get_self_sufficiency_pct()
	if stability in ["Stable", "Surplus"] and self_suff >= 70.0:
		return "Thriving"
	elif self_suff >= 40.0:
		return "Functional"
	return "Crisis"

func get_reserve_adequacy() -> float:
	var avg := get_average_hemogen()
	return snapped(avg / float(MAX_HEMOGEN) * 100.0, 0.1)

func get_consumption_sustainability() -> String:
	var critical := get_critical_pawns().size()
	var total := _hemogen_levels.size()
	if total <= 0:
		return "N/A"
	var crisis_pct := float(critical) / float(total) * 100.0
	if crisis_pct <= 10.0:
		return "Sustainable"
	elif crisis_pct <= 30.0:
		return "Strained"
	return "Unsustainable"

func get_hemogen_ecosystem_health() -> float:
	var economy := get_blood_economy_health()
	var e_val: float = 90.0 if economy == "Thriving" else (60.0 if economy == "Healthy" else 25.0)
	var adequacy := get_reserve_adequacy()
	var sustainability := get_consumption_sustainability()
	var s_val: float = 90.0 if sustainability == "Sustainable" else (50.0 if sustainability == "Strained" else 15.0)
	return snapped((e_val + adequacy + s_val) / 3.0, 0.1)

func get_blood_governance() -> String:
	var ecosystem := get_hemogen_ecosystem_health()
	var stability := get_supply_stability()
	var st_val: float = 90.0 if stability in ["Stable", "Surplus"] else (60.0 if stability == "Adequate" else 25.0)
	var combined := (ecosystem + st_val) / 2.0
	if combined >= 70.0:
		return "Self-Sufficient"
	elif combined >= 40.0:
		return "Dependent"
	elif _hemogen_levels.size() > 0:
		return "Critical"
	return "None"

func get_vampiric_maturity_index() -> float:
	var self_suff := get_self_sufficiency_pct()
	var ethical := get_ethical_sourcing()
	var eth_val: float = 90.0 if ethical == "Ethical" else (60.0 if ethical == "Mixed" else 25.0)
	return snapped((self_suff + eth_val) / 2.0, 0.1)
