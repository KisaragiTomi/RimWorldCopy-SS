extends Node

var _last_check_tick: int = 0
var _break_cooldown: int = 50000
var _total_breaks: int = 0
var _successful_breaks: int = 0
var _total_escaped: int = 0
var _break_history: Array[Dictionary] = []
const CHECK_INTERVAL: int = 5000
const BASE_BREAK_CHANCE: float = 0.02
const MAX_HISTORY: int = 20


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func _on_rare_tick(tick: int) -> void:
	if tick - _last_check_tick < CHECK_INTERVAL:
		return
	_last_check_tick = tick
	_check_prison_break(tick)


func _check_prison_break(tick: int) -> void:
	if not PrisonerManager:
		return
	if tick < _break_cooldown:
		return

	var prisoners: Array = PrisonerManager.prisoners if "prisoners" in PrisonerManager else []
	if prisoners.size() < 1:
		return

	var leader_resistance: float = 999.0
	var leader: Pawn = null
	for p in prisoners:
		if p is Pawn and not p.dead and not p.downed:
			var resist: float = p.get_meta("resistance", 10.0) if p.has_meta("resistance") else 10.0
			if resist < leader_resistance:
				leader_resistance = resist
				leader = p

	if leader == null:
		return

	var chance: float = BASE_BREAK_CHANCE * float(prisoners.size())
	if leader_resistance < 3.0:
		chance *= 2.0
	chance = minf(chance, 0.15)

	if randf() > chance:
		return

	_total_breaks += 1
	var escaped: int = 0
	for p in prisoners:
		if p is Pawn and not p.dead and not p.downed:
			var escape_roll: float = randf()
			if escape_roll < 0.5:
				if PrisonerManager.has_method("release_prisoner"):
					PrisonerManager.release_prisoner(p)
				escaped += 1

	_total_escaped += escaped
	if escaped > 0:
		_successful_breaks += 1
	_break_history.append({"tick": tick, "escaped": escaped, "total_prisoners": prisoners.size(), "leader": leader.pawn_name if leader else ""})
	if _break_history.size() > MAX_HISTORY:
		_break_history.pop_front()

	if ColonyLog and ColonyLog.has_method("add_entry"):
		ColonyLog.add_entry("Security", "Prison break #%d! %d of %d prisoner(s) escaped. Leader: %s" % [_total_breaks, escaped, prisoners.size(), leader.pawn_name if leader else "unknown"], "danger")
	if AlertManager and AlertManager.has_method("add_alert"):
		AlertManager.add_alert("PrisonBreak", "Prison break in progress!", "danger")

	_break_cooldown = tick + 50000


func get_escape_rate() -> float:
	if _total_breaks == 0:
		return 0.0
	return snappedf(float(_successful_breaks) / float(_total_breaks), 0.01)


func get_break_history() -> Array[Dictionary]:
	return _break_history.duplicate()


func get_avg_escaped_per_break() -> float:
	if _total_breaks == 0:
		return 0.0
	return snappedf(float(_total_escaped) / float(_total_breaks), 0.1)


func get_last_break() -> Dictionary:
	if _break_history.is_empty():
		return {}
	return _break_history[-1]


func is_overdue() -> bool:
	if _total_breaks == 0:
		return false
	var now: int = TickManager.current_tick if TickManager else 0
	return now > _break_cooldown


func get_security_rating() -> String:
	var rate: float = get_escape_rate()
	if rate == 0.0 and _total_breaks == 0:
		return "Secure"
	elif rate < 20.0:
		return "Guarded"
	elif rate < 50.0:
		return "Vulnerable"
	return "Compromised"

func get_threat_level() -> String:
	if is_overdue():
		return "Imminent"
	elif _total_breaks > 5:
		return "High"
	elif _total_breaks > 0:
		return "Low"
	return "None"

func get_containment_score() -> float:
	if _total_breaks <= 0:
		return 100.0
	return snappedf(100.0 - get_escape_rate(), 0.1)

func get_summary() -> Dictionary:
	return {
		"total_breaks": _total_breaks,
		"successful_breaks": _successful_breaks,
		"total_escaped": _total_escaped,
		"escape_rate": get_escape_rate(),
		"avg_escaped": get_avg_escaped_per_break(),
		"last_break": get_last_break(),
		"overdue": is_overdue(),
		"success_rate": snappedf(float(_successful_breaks) / maxf(float(_total_breaks), 1.0) * 100.0, 0.1),
		"escaped_per_success": snappedf(float(_total_escaped) / maxf(float(_successful_breaks), 1.0), 0.1),
		"security_rating": get_security_rating(),
		"threat_level": get_threat_level(),
		"containment_score": get_containment_score(),
		"escape_frequency_trend": get_escape_frequency_trend(),
		"deterrence_effectiveness": get_deterrence_effectiveness(),
		"security_investment_roi": get_security_investment_roi(),
		"containment_ecosystem_health": get_containment_ecosystem_health(),
		"recidivism_risk_index": get_recidivism_risk_index(),
		"security_maturity": get_security_maturity(),
	}

func get_containment_ecosystem_health() -> float:
	var containment := get_containment_score()
	var deterrence := get_deterrence_effectiveness()
	var base: float = containment
	if deterrence == "Strong":
		base *= 1.3
	elif deterrence == "Weak":
		base *= 0.6
	return snapped(clampf(base, 0.0, 100.0), 0.1)

func get_recidivism_risk_index() -> float:
	var rate := get_escape_rate()
	var success := float(_successful_breaks) / maxf(float(_total_breaks), 1.0) * 100.0
	return snapped(rate * 0.5 + success * 0.5, 0.1)

func get_security_maturity() -> String:
	var roi := get_security_investment_roi()
	var trend := get_escape_frequency_trend()
	if roi == "Excellent" and trend == "Controlled":
		return "Fortified"
	elif roi == "Poor" or trend == "Escalating":
		return "Vulnerable"
	return "Adequate"

func get_escape_frequency_trend() -> String:
	if _total_breaks <= 1:
		return "Stable"
	var recent_rate := get_escape_rate()
	if recent_rate >= 50.0:
		return "Escalating"
	elif recent_rate >= 20.0:
		return "Concerning"
	return "Controlled"

func get_deterrence_effectiveness() -> String:
	var success_rate := float(_successful_breaks) / maxf(float(_total_breaks), 1.0) * 100.0
	if success_rate == 0.0:
		return "Perfect"
	elif success_rate < 30.0:
		return "Effective"
	elif success_rate < 60.0:
		return "Weak"
	return "Failing"

func get_security_investment_roi() -> String:
	var containment := get_containment_score()
	var security := get_security_rating()
	if security == "Maximum" and containment >= 80.0:
		return "Excellent"
	elif security in ["Maximum", "High"]:
		return "Good"
	return "Needs Improvement"
