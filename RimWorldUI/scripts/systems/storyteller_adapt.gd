extends Node

var _difficulty: float = 1.0
var _threat_cycle: float = 0.0
var _last_adapt_tick: int = 0
var _difficulty_history: Array[float] = []
var _peak_difficulty: float = 0.0

const ADAPT_INTERVAL: int = 15000
const DIFFICULTY_RANGE: Array = [0.3, 3.0]


func _ready() -> void:
	if TickManager and TickManager.has_signal("tick"):
		TickManager.tick.connect(_on_tick)


func _on_tick(_tick: int) -> void:
	if TickManager.current_tick - _last_adapt_tick < ADAPT_INTERVAL:
		return
	_last_adapt_tick = TickManager.current_tick
	_adapt()


func _adapt() -> void:
	var wealth: float = 0.0
	if GameState:
		var w: Variant = GameState.get("colony_wealth")
		if w != null:
			wealth = float(w)

	var pop: int = 0
	if PawnManager and PawnManager.has_method("get_all_pawns"):
		pop = PawnManager.get_all_pawns().size()

	var threat: float = 0.0
	if ThreatAssessment and ThreatAssessment.has_method("get_summary"):
		var ts: Dictionary = ThreatAssessment.get_summary()
		threat = float(ts.get("score", 0.0))

	var wealth_factor: float = clampf(wealth / 5000.0, 0.5, 2.0)
	var pop_factor: float = clampf(float(pop) / 5.0, 0.5, 2.0)
	var recovery: float = 1.0
	if threat > 20.0:
		recovery = 0.7

	_difficulty = clampf(wealth_factor * pop_factor * recovery, DIFFICULTY_RANGE[0], DIFFICULTY_RANGE[1])
	_threat_cycle += 0.1
	if _difficulty > _peak_difficulty:
		_peak_difficulty = _difficulty
	_difficulty_history.append(_difficulty)
	if _difficulty_history.size() > 30:
		_difficulty_history.pop_front()


func get_difficulty() -> float:
	return _difficulty


func get_event_points() -> float:
	return _difficulty * 100.0


func get_difficulty_trend() -> String:
	if _difficulty_history.size() < 2:
		return "stable"
	var recent: float = _difficulty_history[-1]
	var older: float = _difficulty_history[0]
	if recent > older + 0.1:
		return "rising"
	elif recent < older - 0.1:
		return "falling"
	return "stable"


func get_avg_difficulty() -> float:
	if _difficulty_history.is_empty():
		return _difficulty
	var total: float = 0.0
	for d: float in _difficulty_history:
		total += d
	return snappedf(total / float(_difficulty_history.size()), 0.01)


func get_difficulty_volatility() -> float:
	if _difficulty_history.size() < 2:
		return 0.0
	var avg: float = get_avg_difficulty()
	var sum_sq: float = 0.0
	for d: float in _difficulty_history:
		sum_sq += (d - avg) * (d - avg)
	return snappedf(sqrt(sum_sq / float(_difficulty_history.size())), 0.01)


func is_at_peak() -> bool:
	return absf(_difficulty - _peak_difficulty) < 0.02


func get_difficulty_range() -> Dictionary:
	if _difficulty_history.is_empty():
		return {"min": _difficulty, "max": _difficulty}
	var lo: float = _difficulty_history[0]
	var hi: float = _difficulty_history[0]
	for d: float in _difficulty_history:
		if d < lo:
			lo = d
		if d > hi:
			hi = d
	return {"min": snapped(lo, 0.01), "max": snapped(hi, 0.01)}


func get_difficulty_spread() -> float:
	var r := get_difficulty_range()
	return snappedf(float(r.get("max", 0.0)) - float(r.get("min", 0.0)), 0.01)


func get_adaptation_rate() -> float:
	if _difficulty_history.size() < 2:
		return 0.0
	var last: float = _difficulty_history[-1]
	var prev: float = _difficulty_history[-2]
	return snappedf(last - prev, 0.001)


func get_history_length() -> int:
	return _difficulty_history.size()


func get_pacing_quality() -> String:
	var vol: float = get_difficulty_volatility()
	if vol < 0.1:
		return "Smooth"
	elif vol < 0.3:
		return "Dynamic"
	elif vol < 0.5:
		return "Chaotic"
	return "Extreme"

func get_threat_pressure() -> String:
	var avg: float = get_avg_difficulty()
	if avg >= 0.8:
		return "Crushing"
	elif avg >= 0.6:
		return "Heavy"
	elif avg >= 0.3:
		return "Moderate"
	return "Light"

func get_cycle_maturity() -> float:
	var length: int = get_history_length()
	if length == 0:
		return 0.0
	return snappedf(minf(float(length) / 100.0, 1.0) * 100.0, 0.1)

func get_player_experience_rating() -> String:
	var vol: float = get_difficulty_volatility()
	var pacing: String = get_pacing_quality()
	if pacing == "Smooth" and vol < 0.1:
		return "Excellent"
	if pacing in ["Smooth", "Dynamic"] or vol < 0.3:
		return "Good"
	return "Rough"

func get_escalation_forecast_pct() -> float:
	var current: float = _difficulty
	var peak: float = _peak_difficulty
	if peak <= 0.0:
		return 0.0
	return snapped(current * 100.0 / peak, 0.1)

func get_narrative_tension() -> String:
	var trend: String = get_difficulty_trend()
	var pressure: String = get_threat_pressure()
	if trend == "rising" and pressure == "high":
		return "climactic"
	if trend == "rising" or pressure == "high":
		return "building"
	if trend == "falling":
		return "relaxing"
	return "steady"

func get_summary() -> Dictionary:
	return {
		"difficulty": snapped(_difficulty, 0.01),
		"event_points": snapped(get_event_points(), 0.1),
		"threat_cycle": snapped(_threat_cycle, 0.01),
		"peak_difficulty": snapped(_peak_difficulty, 0.01),
		"avg_difficulty": get_avg_difficulty(),
		"trend": get_difficulty_trend(),
		"volatility": get_difficulty_volatility(),
		"at_peak": is_at_peak(),
		"range": get_difficulty_range(),
		"spread": get_difficulty_spread(),
		"adapt_rate": get_adaptation_rate(),
		"history_length": get_history_length(),
		"pacing_quality": get_pacing_quality(),
		"threat_pressure": get_threat_pressure(),
		"cycle_maturity_pct": get_cycle_maturity(),
		"player_experience_rating": get_player_experience_rating(),
		"escalation_forecast_pct": get_escalation_forecast_pct(),
		"narrative_tension": get_narrative_tension(),
		"narrative_ecosystem_health": get_narrative_ecosystem_health(),
		"dramatic_sophistication": get_dramatic_sophistication(),
		"storytelling_governance": get_storytelling_governance(),
	}

func get_narrative_ecosystem_health() -> float:
	var pacing := get_pacing_quality()
	var pacing_val: float = 90.0 if pacing == "good" else (60.0 if pacing == "moderate" else 30.0)
	var maturity := get_cycle_maturity()
	var tension := get_narrative_tension()
	var tension_val: float = 80.0 if tension == "climactic" else (60.0 if tension == "building" else (40.0 if tension == "relaxing" else 20.0))
	return snapped((pacing_val + maturity + tension_val) / 3.0, 0.1)

func get_dramatic_sophistication() -> float:
	var volatility := get_difficulty_volatility()
	var spread := get_difficulty_spread()
	var adapt := get_adaptation_rate()
	return snapped((volatility * 20.0 + spread * 10.0 + adapt * 10.0) / 3.0, 0.1)

func get_storytelling_governance() -> String:
	var health := get_narrative_ecosystem_health()
	var sophistication := get_dramatic_sophistication()
	if health >= 60.0 and sophistication >= 40.0:
		return "Masterful"
	elif health >= 35.0 or sophistication >= 20.0:
		return "Competent"
	return "Rudimentary"
