class_name Storyteller
extends RefCounted

## Controls event pacing based on storyteller personality.
## Cassandra = steady escalation, Phoebe = peaceful long breaks, Randy = chaos.
## Adaptive difficulty scales threat points based on colony performance.

enum Type { CASSANDRA, PHOEBE, RANDY }

var storyteller_type: Type = Type.CASSANDRA
var threat_points: float = 0.0
var days_since_last_threat: int = 0
var total_threats: int = 0
var difficulty_factor: float = 1.0
var recent_deaths: int = 0
var event_history: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

const MAX_HISTORY := 30

const POSITIVE_EVENTS: PackedStringArray = [
	"TraderVisit", "WandererJoin", "ResourceDrop", "CargoDropPod",
	"RefugeePodCrash", "OrbitalTrader",
]

const NEGATIVE_EVENTS: PackedStringArray = [
	"Raid", "Infestation", "Disease", "SolarFlare",
	"VolcanicWinter", "ColdSnap", "HeatWave", "Blight",
	"ManhunterPack", "MechanoidCluster",
]


func _init(stype: Type = Type.CASSANDRA) -> void:
	storyteller_type = stype
	_rng.seed = randi()


func should_fire_incident(colony_wealth: float, pawn_count: int, current_day: int) -> Dictionary:
	days_since_last_threat += 1
	threat_points = _calc_threat_points(colony_wealth, pawn_count)
	_adapt_difficulty(pawn_count)

	match storyteller_type:
		Type.CASSANDRA:
			return _cassandra_check(current_day)
		Type.PHOEBE:
			return _phoebe_check(current_day)
		Type.RANDY:
			return _randy_check()
	return {}


func notify_colonist_death() -> void:
	recent_deaths += 1


func _cassandra_check(day: int) -> Dictionary:
	var interval: int = maxi(3, 8 - total_threats / 2)
	if days_since_last_threat < interval:
		return {}

	var roll := _rng.randf()
	if roll < 0.35:
		return _fire("Raid", threat_points * difficulty_factor)
	elif roll < 0.45:
		return _fire(_pick_negative_event(), threat_points * difficulty_factor * 0.5)
	elif roll < 0.65:
		return _fire("TraderVisit", 0.0)
	elif roll < 0.8:
		return _fire("WandererJoin", 0.0)
	elif roll < 0.9:
		return _fire("ResourceDrop", 0.0)
	else:
		return _fire("TemperatureShift", 0.0)


func _phoebe_check(day: int) -> Dictionary:
	var interval: int = maxi(5, 14 - total_threats / 3)
	if days_since_last_threat < interval:
		return {}

	var roll := _rng.randf()
	if roll < 0.15:
		return _fire("Raid", threat_points * difficulty_factor * 0.6)
	elif roll < 0.25:
		return _fire(_pick_negative_event(), threat_points * difficulty_factor * 0.3)
	elif roll < 0.5:
		return _fire("TraderVisit", 0.0)
	elif roll < 0.7:
		return _fire("WandererJoin", 0.0)
	elif roll < 0.85:
		return _fire("ResourceDrop", 0.0)
	else:
		return _fire("CargoDropPod", 0.0)


func _randy_check() -> Dictionary:
	if _rng.randf() > 0.14:
		return {}

	var roll := _rng.randf()
	if roll < 0.2:
		return _fire("Raid", threat_points * difficulty_factor * _rng.randf_range(0.3, 2.5))
	elif roll < 0.3:
		return _fire(_pick_negative_event(), threat_points * difficulty_factor)
	elif roll < 0.45:
		return _fire("TraderVisit", 0.0)
	elif roll < 0.55:
		return _fire("WandererJoin", 0.0)
	elif roll < 0.65:
		return _fire("ResourceDrop", 0.0)
	elif roll < 0.75:
		return _fire("CargoDropPod", 0.0)
	elif roll < 0.85:
		return _fire("TemperatureShift", 0.0)
	elif roll < 0.92:
		return _fire("Disease", 0.0)
	else:
		return _fire("RefugeePodCrash", 0.0)


func _fire(event_name: String, points: float) -> Dictionary:
	days_since_last_threat = 0
	total_threats += 1
	var entry := {"event": event_name, "points": snappedf(points, 0.1), "threat_num": total_threats}
	event_history.append(entry)
	if event_history.size() > MAX_HISTORY:
		event_history.pop_front()
	return entry


func _pick_negative_event() -> String:
	return NEGATIVE_EVENTS[_rng.randi_range(0, NEGATIVE_EVENTS.size() - 1)]


func _adapt_difficulty(pawn_count: int) -> void:
	if recent_deaths >= 2:
		difficulty_factor = maxf(0.5, difficulty_factor - 0.15)
		recent_deaths = 0
	elif days_since_last_threat > 15 and pawn_count >= 5:
		difficulty_factor = minf(2.0, difficulty_factor + 0.05)


func _calc_threat_points(wealth: float, pawns: int) -> float:
	return wealth * 0.01 + pawns * 15.0 + total_threats * 2.0


func get_positive_event_count() -> int:
	var cnt: int = 0
	for e: Dictionary in event_history:
		if e["event"] in POSITIVE_EVENTS:
			cnt += 1
	return cnt


func get_negative_event_count() -> int:
	var cnt: int = 0
	for e: Dictionary in event_history:
		if e["event"] in NEGATIVE_EVENTS:
			cnt += 1
	return cnt


func get_event_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for e: Dictionary in event_history:
		var ename: String = e["event"]
		dist[ename] = dist.get(ename, 0) + 1
	return dist


func get_threat_density() -> float:
	if days_since_last_threat <= 0:
		return 0.0
	return snappedf(float(total_threats) / maxf(1.0, float(days_since_last_threat)), 0.01)

func get_neutral_event_count() -> int:
	var positive: int = get_positive_event_count()
	var negative: int = get_negative_event_count()
	return event_history.size() - positive - negative

func get_avg_threat_points() -> float:
	if total_threats <= 0:
		return 0.0
	return snappedf(threat_points / float(total_threats), 0.1)

func get_most_common_event() -> String:
	var dist: Dictionary = get_event_distribution()
	var best: String = ""
	var best_c: int = 0
	for e: String in dist:
		if dist[e] > best_c:
			best_c = dist[e]
			best = e
	return best


func get_threat_escalation_rate() -> float:
	if event_history.size() < 2:
		return 0.0
	var first_pts: float = event_history[0].get("points", 0.0)
	var last_pts: float = event_history[-1].get("points", 0.0)
	return snappedf(last_pts - first_pts, 0.1)


func get_positive_ratio() -> float:
	if event_history.is_empty():
		return 0.0
	return snappedf(float(get_positive_event_count()) / float(event_history.size()) * 100.0, 0.1)


func get_narrative_tension() -> float:
	var density := get_threat_density()
	var escalation := absf(get_threat_escalation_rate())
	var recency := 1.0 / maxf(float(days_since_last_threat), 1.0)
	return snapped((density * 30.0 + escalation * 0.5 + recency * 20.0), 0.1)

func get_pacing_quality() -> String:
	if event_history.size() < 3:
		return "Developing"
	var positive := get_positive_event_count()
	var negative := get_negative_event_count()
	var ratio := float(positive) / maxf(float(negative), 1.0)
	if ratio >= 0.8 and ratio <= 1.5:
		return "Well-Paced"
	elif ratio >= 0.4:
		return "Uneven"
	return "Oppressive"

func get_difficulty_trajectory() -> String:
	var esc := get_threat_escalation_rate()
	if esc > 50.0:
		return "Escalating"
	elif esc > 10.0:
		return "Rising"
	elif esc > -10.0:
		return "Stable"
	elif esc > -50.0:
		return "Easing"
	return "Declining"

func get_summary() -> Dictionary:
	var names := ["Cassandra", "Phoebe", "Randy"]
	return {
		"storyteller": names[storyteller_type],
		"threat_points": snappedf(threat_points, 0.1),
		"difficulty_factor": snappedf(difficulty_factor, 0.01),
		"days_since_threat": days_since_last_threat,
		"total_threats": total_threats,
		"recent_events": event_history.slice(-5),
		"threat_density": get_threat_density(),
		"neutral_events": get_neutral_event_count(),
		"avg_threat_points": get_avg_threat_points(),
		"most_common_event": get_most_common_event(),
		"escalation_rate": get_threat_escalation_rate(),
		"positive_ratio_pct": get_positive_ratio(),
		"narrative_tension": get_narrative_tension(),
		"pacing_quality": get_pacing_quality(),
		"difficulty_trajectory": get_difficulty_trajectory(),
		"dramatic_arc_score": get_dramatic_arc_score(),
		"player_agency_index": get_player_agency_index(),
		"story_completeness_pct": get_story_completeness(),
	}

func get_dramatic_arc_score() -> float:
	var tension: float = get_narrative_tension()
	var pacing: String = get_pacing_quality()
	var t_val: float = 1.0 if tension >= 50.0 else (0.6 if tension >= 25.0 else 0.3)
	var p_val: float = 1.0 if pacing == "Smooth" else (0.7 if pacing == "Dynamic" else 0.4)
	return snapped(t_val * p_val * 100.0, 0.1)

func get_player_agency_index() -> float:
	var positive_ratio := get_positive_ratio()
	var density := get_threat_density()
	if density <= 0.0:
		return 100.0
	return snapped(minf(positive_ratio / maxf(density, 0.01) * 10.0, 100.0), 0.1)

func get_story_completeness() -> float:
	var events := event_history.size()
	var unique: Dictionary = {}
	for e: Dictionary in event_history:
		unique[e.get("type", "")] = true
	if events <= 0:
		return 0.0
	return snapped(float(unique.size()) / maxf(float(events), 1.0) * 100.0, 0.1)
