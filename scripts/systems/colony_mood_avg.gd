extends Node

var _mood_snapshots: Array = []
const MAX_SNAPSHOTS: int = 60

const MOOD_THRESHOLDS: Dictionary = {
	"Ecstatic": 90.0,
	"Happy": 70.0,
	"Content": 50.0,
	"Neutral": 35.0,
	"Stressed": 25.0,
	"OnEdge": 15.0,
	"Breaking": 5.0
}

const BREAK_RISK_LEVELS: Dictionary = {
	"None": 70.0,
	"Minor": 35.0,
	"Major": 20.0,
	"Extreme": 5.0
}

func record_snapshot(pawn_moods: Dictionary) -> Dictionary:
	if pawn_moods.is_empty():
		return {}
	var total: float = 0.0
	var min_mood: float = 100.0
	var max_mood: float = 0.0
	for pid: int in pawn_moods:
		var m: float = pawn_moods[pid]
		total += m
		min_mood = minf(min_mood, m)
		max_mood = maxf(max_mood, m)
	var avg: float = total / pawn_moods.size()
	var snapshot: Dictionary = {
		"avg": avg,
		"min": min_mood,
		"max": max_mood,
		"count": pawn_moods.size(),
		"label": _get_mood_label(avg)
	}
	_mood_snapshots.append(snapshot)
	if _mood_snapshots.size() > MAX_SNAPSHOTS:
		_mood_snapshots.pop_front()
	return snapshot

func _get_mood_label(mood: float) -> String:
	for label: String in MOOD_THRESHOLDS:
		if mood >= MOOD_THRESHOLDS[label]:
			return label
	return "Breaking"

func get_break_risk(mood: float) -> String:
	for risk: String in BREAK_RISK_LEVELS:
		if mood >= BREAK_RISK_LEVELS[risk]:
			return risk
	return "Extreme"

func get_trend() -> float:
	if _mood_snapshots.size() < 2:
		return 0.0
	var recent: float = _mood_snapshots[-1]["avg"]
	var old: float = _mood_snapshots[0]["avg"]
	return recent - old

func get_latest_snapshot() -> Dictionary:
	if _mood_snapshots.is_empty():
		return {}
	return _mood_snapshots[-1].duplicate()


func get_lowest_recorded() -> float:
	var lowest: float = 100.0
	for snap: Dictionary in _mood_snapshots:
		var v: float = float(snap.get("min", 100.0))
		if v < lowest:
			lowest = v
	return lowest


func get_label_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for snap: Dictionary in _mood_snapshots:
		var l: String = String(snap.get("label", "Neutral"))
		dist[l] = int(dist.get(l, 0)) + 1
	return dist


func get_highest_recorded() -> float:
	var highest: float = 0.0
	for snap: Dictionary in _mood_snapshots:
		var v: float = float(snap.get("max", 0.0))
		if v > highest:
			highest = v
	return highest


func get_avg_mood_across_snapshots() -> float:
	if _mood_snapshots.is_empty():
		return 0.0
	var total: float = 0.0
	for snap: Dictionary in _mood_snapshots:
		total += float(snap.get("avg", 0.0))
	return total / _mood_snapshots.size()


func get_most_common_label() -> String:
	var dist: Dictionary = get_label_distribution()
	var best: String = ""
	var best_count: int = 0
	for l: String in dist:
		if int(dist[l]) > best_count:
			best_count = int(dist[l])
			best = l
	return best


func get_volatility() -> float:
	if _mood_snapshots.size() < 2:
		return 0.0
	var total_diff: float = 0.0
	for i: int in range(1, _mood_snapshots.size()):
		total_diff += absf(float(_mood_snapshots[i].get("avg", 0.0)) - float(_mood_snapshots[i - 1].get("avg", 0.0)))
	return snappedf(total_diff / float(_mood_snapshots.size() - 1), 0.01)


func get_breaking_snapshot_count() -> int:
	var count: int = 0
	for snap: Dictionary in _mood_snapshots:
		if String(snap.get("label", "")) == "Breaking":
			count += 1
	return count


func get_positive_snapshot_pct() -> float:
	if _mood_snapshots.is_empty():
		return 0.0
	var positive: int = 0
	for snap: Dictionary in _mood_snapshots:
		if float(snap.get("avg", 0.0)) >= 50.0:
			positive += 1
	return snappedf(float(positive) / float(_mood_snapshots.size()) * 100.0, 0.1)


func get_colony_morale() -> String:
	var avg: float = get_avg_mood_across_snapshots()
	if avg >= 75.0:
		return "Thriving"
	elif avg >= 55.0:
		return "Content"
	elif avg >= 35.0:
		return "Strained"
	return "Critical"

func get_stability_rating() -> String:
	var vol: float = get_volatility()
	if vol <= 5.0:
		return "Rock-Solid"
	elif vol <= 12.0:
		return "Stable"
	elif vol <= 25.0:
		return "Turbulent"
	return "Chaotic"

func get_crisis_frequency_pct() -> float:
	if _mood_snapshots.is_empty():
		return 0.0
	return snappedf(float(get_breaking_snapshot_count()) / float(_mood_snapshots.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"snapshots": _mood_snapshots.size(),
		"mood_labels": MOOD_THRESHOLDS.size(),
		"break_risk_levels": BREAK_RISK_LEVELS.size(),
		"trend": get_trend(),
		"lowest_ever": get_lowest_recorded(),
		"highest_ever": get_highest_recorded(),
		"avg_across": snapped(get_avg_mood_across_snapshots(), 0.1),
		"most_common_label": get_most_common_label(),
		"volatility": get_volatility(),
		"breaking_count": get_breaking_snapshot_count(),
		"positive_pct": get_positive_snapshot_pct(),
		"colony_morale": get_colony_morale(),
		"stability_rating": get_stability_rating(),
		"crisis_frequency_pct": get_crisis_frequency_pct(),
		"emotional_resilience": get_emotional_resilience(),
		"mood_recovery_speed": get_mood_recovery_speed(),
		"happiness_sustainability": get_happiness_sustainability(),
		"colony_mood_ecosystem_health": get_colony_mood_ecosystem_health(),
		"wellbeing_governance": get_wellbeing_governance(),
		"emotional_maturity_index": get_emotional_maturity_index(),
	}

func get_emotional_resilience() -> String:
	var volatility := get_volatility()
	var positive := get_positive_snapshot_pct()
	if volatility < 5.0 and positive >= 70.0:
		return "Resilient"
	elif volatility < 15.0:
		return "Moderate"
	return "Fragile"

func get_mood_recovery_speed() -> String:
	var breaking := get_breaking_snapshot_count()
	var total := _mood_snapshots.size()
	if total <= 0:
		return "N/A"
	var crisis_pct := float(breaking) / float(total) * 100.0
	if crisis_pct <= 5.0:
		return "Fast"
	elif crisis_pct <= 20.0:
		return "Normal"
	return "Slow"

func get_happiness_sustainability() -> float:
	var positive := get_positive_snapshot_pct()
	var stability := get_stability_rating()
	var bonus := 10.0 if stability == "Stable" else (5.0 if stability == "Moderate" else 0.0)
	return snapped(positive + bonus, 0.1)

func get_colony_mood_ecosystem_health() -> float:
	var resilience := get_emotional_resilience()
	var r_val: float = 90.0 if resilience == "Resilient" else (60.0 if resilience == "Normal" else 30.0)
	var recovery := get_mood_recovery_speed()
	var rc_val: float = 90.0 if recovery == "Fast" else (60.0 if recovery == "Normal" else 20.0)
	var sustainability := get_happiness_sustainability()
	return snapped((r_val + rc_val + sustainability) / 3.0, 0.1)

func get_wellbeing_governance() -> String:
	var ecosystem := get_colony_mood_ecosystem_health()
	var morale := get_colony_morale()
	var m_val: float = 90.0 if morale == "Excellent" else (60.0 if morale == "Good" else 25.0)
	var combined := (ecosystem + m_val) / 2.0
	if combined >= 70.0:
		return "Thriving"
	elif combined >= 40.0:
		return "Managed"
	elif _mood_snapshots.size() > 0:
		return "Struggling"
	return "Unknown"

func get_emotional_maturity_index() -> float:
	var crisis := get_crisis_frequency_pct()
	var positive := get_positive_snapshot_pct()
	return snapped((positive + (100.0 - crisis)) / 2.0, 0.1)
