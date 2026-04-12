extends Node

enum ThreatLevel { MINIMAL, LOW, MODERATE, HIGH, CRITICAL }

var _current_level: int = ThreatLevel.MINIMAL
var _threat_score: float = 0.0
var _score_breakdown: Dictionary = {}
var _peak_score: float = 0.0
var _peak_level: int = ThreatLevel.MINIMAL
var _history: Array[Dictionary] = []
const MAX_HISTORY: int = 30


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func _on_rare_tick(_tick: int) -> void:
	_recalculate()


func _recalculate() -> void:
	var score: float = 0.0
	var breakdown: Dictionary = {"enemies": 0.0, "downed": 0.0, "fire": 0.0, "mood": 0.0, "biome": 0.0, "breaks": 0.0}
	if PawnManager:
		var enemy_count: int = 0
		for p: Pawn in PawnManager.pawns:
			if p.has_meta("faction") and p.get_meta("faction") == "enemy" and not p.dead:
				enemy_count += 1
		breakdown.enemies = float(enemy_count) * 15.0
		score += breakdown.enemies
		var downed: int = 0
		for p2: Pawn in PawnManager.pawns:
			if not p2.dead and p2.downed:
				downed += 1
		breakdown.downed = float(downed) * 8.0
		score += breakdown.downed
	if FireManager and "active_fires" in FireManager:
		breakdown.fire = float(FireManager.active_fires) * 5.0
		score += breakdown.fire
	if MoodTracker and MoodTracker.has_method("get_average_mood"):
		var avg_mood: float = MoodTracker.get_average_mood()
		if avg_mood < 0.25:
			breakdown.mood = 20.0
		elif avg_mood < 0.35:
			breakdown.mood = 10.0
		score += breakdown.mood
	if BiomeEvents and BiomeEvents.has_method("get_active_events"):
		var active: Array = BiomeEvents.get_active_events()
		for evt in active:
			var evt_str: String = str(evt)
			if evt_str == "ToxicFallout" or evt_str == "VolcanicWinter":
				breakdown.biome += 15.0
			else:
				breakdown.biome += 5.0
		score += breakdown.biome
	if MentalBreakExpanded and MentalBreakExpanded.has_method("get_summary"):
		var breaks: Dictionary = MentalBreakExpanded.get_summary()
		breakdown.breaks = float(breaks.get("active_breaks", 0)) * 6.0
		score += breakdown.breaks
	_threat_score = score
	_score_breakdown = breakdown
	_current_level = _score_to_level(score)
	if score > _peak_score:
		_peak_score = score
		_peak_level = _current_level
	_history.append({"tick": TickManager.current_tick if TickManager else 0, "score": snappedf(score, 0.1), "level": _current_level})
	if _history.size() > MAX_HISTORY:
		_history.pop_front()


func _score_to_level(score: float) -> int:
	if score >= 60.0:
		return ThreatLevel.CRITICAL
	if score >= 40.0:
		return ThreatLevel.HIGH
	if score >= 20.0:
		return ThreatLevel.MODERATE
	if score >= 5.0:
		return ThreatLevel.LOW
	return ThreatLevel.MINIMAL


func get_threat_level() -> int:
	return _current_level


func get_threat_label() -> String:
	var labels: Array[String] = ["Minimal", "Low", "Moderate", "High", "Critical"]
	if _current_level >= 0 and _current_level < labels.size():
		return labels[_current_level]
	return "Unknown"


func get_threat_score() -> float:
	return snappedf(_threat_score, 0.1)


func get_breakdown() -> Dictionary:
	return _score_breakdown.duplicate()


func get_primary_threat() -> String:
	var best_cat: String = "none"
	var best_val: float = 0.0
	for cat: String in _score_breakdown:
		if _score_breakdown[cat] > best_val:
			best_val = _score_breakdown[cat]
			best_cat = cat
	return best_cat


func get_threat_trend() -> String:
	if _history.size() < 2:
		return "stable"
	var recent: float = _history[-1].score
	var older: float = _history[0].score
	if recent > older + 5.0:
		return "rising"
	elif recent < older - 5.0:
		return "falling"
	return "stable"


func get_secondary_threat() -> String:
	var sorted_cats: Array[String] = []
	for cat: String in _score_breakdown:
		sorted_cats.append(cat)
	sorted_cats.sort_custom(func(a: String, b: String) -> bool:
		return _score_breakdown.get(a, 0.0) > _score_breakdown.get(b, 0.0)
	)
	if sorted_cats.size() >= 2:
		return sorted_cats[1]
	return "none"


func get_threat_categories_above(threshold: float) -> int:
	var count: int = 0
	for cat: String in _score_breakdown:
		if _score_breakdown[cat] > threshold:
			count += 1
	return count


func is_escalating() -> bool:
	return get_threat_trend() == "rising"


func get_defense_readiness() -> String:
	var score: float = get_threat_score()
	if score <= 10.0:
		return "Secure"
	elif score <= 30.0:
		return "Alert"
	elif score <= 60.0:
		return "Threatened"
	return "Critical"

func get_threat_diversity() -> int:
	var count: int = 0
	for cat: String in _score_breakdown:
		if _score_breakdown[cat] > 0.0:
			count += 1
	return count

func get_peak_ratio() -> float:
	if _peak_score <= 0.0:
		return 0.0
	return snappedf(get_threat_score() / _peak_score * 100.0, 0.1)

func get_escalation_pressure() -> float:
	var trend := get_threat_trend()
	var score := get_threat_score()
	var base: float = score / maxf(_peak_score, 1.0)
	if trend == "rising":
		base *= 1.5
	return snapped(minf(base * 100.0, 100.0), 0.1)

func get_defense_adequacy() -> String:
	var diversity := get_threat_diversity()
	var readiness := get_defense_readiness()
	if readiness == "Secure" and diversity <= 1:
		return "Sufficient"
	elif readiness in ["Secure", "Alert"] and diversity <= 3:
		return "Adequate"
	elif readiness == "Critical":
		return "Insufficient"
	return "Strained"

func get_threat_forecast() -> String:
	var escalating := is_escalating()
	var score := get_threat_score()
	if escalating and score > 40.0:
		return "Severe Escalation"
	elif escalating:
		return "Rising Tension"
	elif score <= 10.0:
		return "Calm"
	return "Stable"

func get_summary() -> Dictionary:
	return {
		"level": get_threat_label(),
		"score": get_threat_score(),
		"level_id": _current_level,
		"breakdown": _score_breakdown.duplicate(),
		"primary_threat": get_primary_threat(),
		"secondary_threat": get_secondary_threat(),
		"peak_score": snappedf(_peak_score, 0.1),
		"trend": get_threat_trend(),
		"escalating": is_escalating(),
		"active_categories": get_threat_categories_above(5.0),
		"active_category_count": get_threat_categories_above(5.0),
		"avg_category_score": snappedf(get_threat_score() / maxf(float(_score_breakdown.size()), 1.0), 0.1),
		"defense_readiness": get_defense_readiness(),
		"threat_diversity": get_threat_diversity(),
		"peak_ratio_pct": get_peak_ratio(),
		"escalation_pressure": get_escalation_pressure(),
		"defense_adequacy": get_defense_adequacy(),
		"threat_forecast": get_threat_forecast(),
		"threat_intelligence_maturity": get_threat_intelligence_maturity(),
		"security_posture_index": get_security_posture_index(),
		"defense_ecosystem_health": get_defense_ecosystem_health(),
	}

func get_threat_intelligence_maturity() -> float:
	var diversity := float(get_threat_diversity())
	var history_len := float(_history.size()) if _history is Array else 0.0
	return snapped(diversity * history_len / maxf(float(_score_breakdown.size()), 1.0) * 10.0, 0.1)

func get_security_posture_index() -> float:
	var pressure := get_escalation_pressure()
	var peak_r := get_peak_ratio()
	return snapped(maxf(100.0 - pressure * 0.5 - peak_r * 0.3, 0.0), 0.1)

func get_defense_ecosystem_health() -> String:
	var adequacy := get_defense_adequacy()
	var forecast := get_threat_forecast()
	if adequacy == "Sufficient" and forecast == "Calm":
		return "Robust"
	elif adequacy == "Insufficient" or forecast == "Severe Escalation":
		return "Critical"
	return "Functional"
