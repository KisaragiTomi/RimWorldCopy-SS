extends Node

## Tracks colony-wide average mood over time for trend analysis.
## Registered as autoload "MoodTracker".

const MAX_HISTORY: int = 500
const DANGER_THRESHOLD: float = 0.25
const WARNING_THRESHOLD: float = 0.35

var _history: Array[Dictionary] = []
var _current_avg: float = 0.5
var _trend: float = 0.0
var _peak_avg: float = 0.0
var _trough_avg: float = 1.0
var _danger_ticks: int = 0


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func _on_rare_tick(_tick: int) -> void:
	_update_mood()
	_check_alerts()


func _update_mood() -> void:
	if not PawnManager:
		return

	var total: float = 0.0
	var count: int = 0
	var lowest: float = 1.0
	var highest: float = 0.0

	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var mood: float = p.get_need("Mood")
		total += mood
		count += 1
		lowest = minf(lowest, mood)
		highest = maxf(highest, mood)

	if count == 0:
		return

	var new_avg: float = total / float(count)
	_trend = new_avg - _current_avg
	_current_avg = new_avg
	if new_avg > _peak_avg:
		_peak_avg = new_avg
	if new_avg < _trough_avg:
		_trough_avg = new_avg
	if new_avg < DANGER_THRESHOLD:
		_danger_ticks += 1

	var entry := {
		"tick": TickManager.current_tick if TickManager else 0,
		"avg_mood": snappedf(new_avg, 0.01),
		"lowest": snappedf(lowest, 0.01),
		"highest": snappedf(highest, 0.01),
		"count": count,
	}
	_history.append(entry)
	if _history.size() > MAX_HISTORY:
		_history = _history.slice(-MAX_HISTORY)


func _check_alerts() -> void:
	if not AlertManager:
		return
	if _current_avg < DANGER_THRESHOLD:
		if ColonyLog:
			ColonyLog.add_entry("Alert", "Colony mood is critically low! Mental breaks imminent.", "danger")
	elif _current_avg < WARNING_THRESHOLD:
		if ColonyLog:
			ColonyLog.add_entry("Alert", "Colony mood is low. Consider improving conditions.", "warning")


func get_average_mood() -> float:
	return snappedf(_current_avg, 0.01)


func get_trend() -> float:
	return snappedf(_trend, 0.001)


func get_trend_label() -> String:
	if _trend > 0.01:
		return "Improving"
	elif _trend < -0.01:
		return "Worsening"
	return "Stable"


func get_history(last_n: int = 50) -> Array[Dictionary]:
	var start: int = maxi(0, _history.size() - last_n)
	return _history.slice(start) as Array[Dictionary]


func get_lowest_pawn() -> Dictionary:
	if not PawnManager:
		return {}
	var worst: Pawn = null
	var worst_mood: float = 2.0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var m: float = p.get_need("Mood")
		if m < worst_mood:
			worst_mood = m
			worst = p
	if worst == null:
		return {}
	return {"pawn_id": worst.id, "name": worst.pawn_name, "mood": snappedf(worst_mood, 0.01)}


func get_break_risk_count() -> int:
	var count: int = 0
	if not PawnManager:
		return count
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if p.get_need("Mood") < DANGER_THRESHOLD:
			count += 1
	return count


func get_mood_distribution() -> Dictionary:
	var dist := {"happy": 0, "content": 0, "neutral": 0, "sad": 0, "critical": 0}
	if not PawnManager:
		return dist
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var m: float = p.get_need("Mood")
		if m >= 0.7:
			dist.happy += 1
		elif m >= 0.5:
			dist.content += 1
		elif m >= 0.35:
			dist.neutral += 1
		elif m >= 0.25:
			dist.sad += 1
		else:
			dist.critical += 1
	return dist


func get_happiest_pawn() -> Dictionary:
	if not PawnManager:
		return {}
	var best: Pawn = null
	var best_mood: float = -1.0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var m: float = p.get_need("Mood")
		if m > best_mood:
			best_mood = m
			best = p
	if best == null:
		return {}
	return {"pawn_id": best.id, "name": best.pawn_name, "mood": snappedf(best_mood, 0.01)}


func get_mood_volatility() -> float:
	if _history.size() < 2:
		return 0.0
	var sum_delta: float = 0.0
	for i: int in range(1, _history.size()):
		sum_delta += absf(_history[i].avg_mood - _history[i - 1].avg_mood)
	return snappedf(sum_delta / float(_history.size() - 1), 0.001)


func get_danger_percentage() -> float:
	if _history.is_empty():
		return 0.0
	return snappedf(float(_danger_ticks) / float(_history.size()) * 100.0, 0.1)


func get_mood_health() -> String:
	if _current_avg >= 0.65:
		return "Happy"
	elif _current_avg >= 0.45:
		return "Content"
	elif _current_avg >= 0.30:
		return "Stressed"
	return "Critical"

func get_stability_score() -> float:
	var vol: float = get_mood_volatility()
	return snappedf(maxf(0.0, 100.0 - vol * 1000.0), 0.1)

func is_crisis_risk() -> bool:
	return get_break_risk_count() >= 2 or _current_avg < 0.25

func get_emotional_forecast() -> String:
	var trend := get_trend_label()
	var health := get_mood_health()
	if trend == "Rising" and health != "Critical":
		return "Improving"
	elif trend == "Falling" and health == "Critical":
		return "Deteriorating"
	elif health == "Happy":
		return "Bright"
	return "Uncertain"

func get_wellbeing_score() -> float:
	return snapped(_current_avg * 100.0 * (1.0 - get_mood_volatility() * 10.0), 0.1)

func get_intervention_priority() -> String:
	if is_crisis_risk():
		return "Immediate"
	elif get_mood_health() == "Stressed":
		return "Soon"
	elif get_danger_percentage() > 10.0:
		return "Monitor"
	return "None"

func get_summary() -> Dictionary:
	return {
		"current_avg": snappedf(_current_avg, 0.01),
		"trend": snappedf(_trend, 0.001),
		"trend_label": get_trend_label(),
		"peak_avg": snappedf(_peak_avg, 0.01),
		"trough_avg": snappedf(_trough_avg, 0.01),
		"danger_ticks": _danger_ticks,
		"break_risk_count": get_break_risk_count(),
		"distribution": get_mood_distribution(),
		"history_size": _history.size(),
		"volatility": get_mood_volatility(),
		"danger_pct": get_danger_percentage(),
		"mood_range": snappedf(_peak_avg - _trough_avg, 0.01),
		"is_declining": _trend < -0.001,
		"mood_health": get_mood_health(),
		"stability_score": get_stability_score(),
		"crisis_risk": is_crisis_risk(),
		"emotional_forecast": get_emotional_forecast(),
		"wellbeing_score": get_wellbeing_score(),
		"intervention_priority": get_intervention_priority(),
		"colony_morale_index": get_colony_morale_index(),
		"psychological_resilience": get_psychological_resilience(),
		"happiness_sustainability": get_happiness_sustainability(),
		"emotional_ecosystem_health": get_emotional_ecosystem_health(),
		"mood_governance": get_mood_governance(),
		"affective_maturity_index": get_affective_maturity_index(),
	}

func get_colony_morale_index() -> float:
	var avg := _current_avg
	var stability := get_stability_score()
	return snapped(avg * stability / 100.0 * 100.0, 0.1)

func get_psychological_resilience() -> String:
	var volatility := get_mood_volatility()
	var health := get_mood_health()
	if volatility < 0.05 and health in ["Good", "Excellent"]:
		return "Resilient"
	elif volatility < 0.15:
		return "Moderate"
	return "Fragile"

func get_happiness_sustainability() -> String:
	var forecast := get_emotional_forecast()
	var crisis := is_crisis_risk()
	if not crisis and forecast in ["Improving", "Stable"]:
		return "Sustainable"
	elif not crisis:
		return "At Risk"
	return "Unsustainable"

func get_emotional_ecosystem_health() -> float:
	var morale := get_colony_morale_index()
	var wellbeing := get_wellbeing_score()
	var resilience := get_psychological_resilience()
	var r_val: float = 90.0 if resilience == "Resilient" else (60.0 if resilience == "Moderate" else 30.0)
	return snapped((morale + wellbeing + r_val) / 3.0, 0.1)

func get_mood_governance() -> String:
	var health := get_emotional_ecosystem_health()
	var sustainability := get_happiness_sustainability()
	if health >= 65.0 and sustainability == "Sustainable":
		return "Proactive"
	elif health >= 35.0:
		return "Responsive"
	return "Neglected"

func get_affective_maturity_index() -> float:
	var stability := get_stability_score()
	var forecast := get_emotional_forecast()
	var f_val: float = 90.0 if forecast in ["Improving", "Stable"] else (50.0 if forecast == "Uncertain" else 20.0)
	return snapped((stability + f_val) / 2.0, 0.1)
