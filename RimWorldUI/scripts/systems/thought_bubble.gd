extends Node

var _active_bubbles: Dictionary = {}

const BUBBLE_ICONS: Dictionary = {
	"happy": "^_^",
	"sad": "T_T",
	"angry": ">_<",
	"hungry": "...",
	"tired": "zzZ",
	"inspired": "!!!",
	"stressed": "~~~",
	"social": "<3",
	"pain": "ouch",
	"cold": "brr",
	"hot": "swt",
}

const MOOD_THRESHOLDS: Dictionary = {
	"happy": 0.7,
	"sad": 0.3,
	"stressed": 0.2,
}


func set_bubble(pawn_id: int, bubble_type: String, duration: float = 5.0) -> void:
	_active_bubbles[pawn_id] = {
		"type": bubble_type,
		"icon": BUBBLE_ICONS.get(bubble_type, "?"),
		"expires_at": Time.get_ticks_msec() + int(duration * 1000),
	}


func get_bubble(pawn_id: int) -> Dictionary:
	if not _active_bubbles.has(pawn_id):
		return {}
	var b: Dictionary = _active_bubbles[pawn_id]
	if Time.get_ticks_msec() > int(b.get("expires_at", 0)):
		_active_bubbles.erase(pawn_id)
		return {}
	return b


func update_from_mood(pawn_id: int, mood_level: float) -> void:
	if mood_level >= 0.7:
		set_bubble(pawn_id, "happy", 10.0)
	elif mood_level <= 0.2:
		set_bubble(pawn_id, "stressed", 10.0)
	elif mood_level <= 0.3:
		set_bubble(pawn_id, "sad", 10.0)


func clear_bubble(pawn_id: int) -> void:
	_active_bubbles.erase(pawn_id)


func get_bubble_distribution() -> Dictionary:
	var dist: Dictionary = {}
	var now: int = Time.get_ticks_msec()
	for pid: int in _active_bubbles:
		var b: Dictionary = _active_bubbles[pid]
		if now <= int(b.get("expires_at", 0)):
			var btype: String = str(b.get("type", ""))
			dist[btype] = dist.get(btype, 0) + 1
	return dist


func get_all_active() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var now: int = Time.get_ticks_msec()
	for pid: int in _active_bubbles:
		var b: Dictionary = _active_bubbles[pid]
		if now <= int(b.get("expires_at", 0)):
			result.append({"pawn_id": pid, "type": b.type, "icon": b.icon})
	return result


func clear_all() -> int:
	var count: int = _active_bubbles.size()
	_active_bubbles.clear()
	return count


func get_most_common_bubble() -> String:
	var dist := get_bubble_distribution()
	var best: String = ""
	var best_n: int = 0
	for t: String in dist:
		if dist[t] > best_n:
			best_n = dist[t]
			best = t
	return best


func get_positive_bubble_count() -> int:
	var count: int = 0
	var dist := get_bubble_distribution()
	for t: String in dist:
		if t.begins_with("good") or t == "inspired" or t == "happy":
			count += dist[t]
	return count


func get_bubble_coverage() -> float:
	if not PawnManager:
		return 0.0
	var alive: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			alive += 1
	if alive == 0:
		return 0.0
	return snappedf(float(_active_bubbles.size()) / float(alive) * 100.0, 0.1)


func get_negative_bubble_count() -> int:
	var count: int = 0
	var dist := get_bubble_distribution()
	for t: String in dist:
		if t == "sad" or t == "angry" or t == "stressed" or t == "pain" or t == "hungry":
			count += dist[t]
	return count


func get_unique_bubble_type_count() -> int:
	return get_bubble_distribution().size()


func get_avg_bubbles_per_pawn() -> float:
	if not PawnManager:
		return 0.0
	var alive: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			alive += 1
	if alive == 0:
		return 0.0
	var active_count: int = get_bubble_distribution().values().reduce(func(a, b): return a + b, 0)
	return snappedf(float(active_count) / float(alive), 0.01)


func get_mood_signal() -> String:
	var pos: int = get_positive_bubble_count()
	var neg: int = get_negative_bubble_count()
	if pos > neg * 2:
		return "Positive"
	elif pos > neg:
		return "Leaning Positive"
	elif pos == neg:
		return "Neutral"
	elif neg > pos * 2:
		return "Distressed"
	return "Leaning Negative"

func get_expressiveness_pct() -> float:
	if BUBBLE_ICONS.is_empty():
		return 0.0
	return snappedf(float(get_unique_bubble_type_count()) / float(BUBBLE_ICONS.size()) * 100.0, 0.1)

func get_negativity_ratio() -> float:
	var total: int = _active_bubbles.size()
	if total == 0:
		return 0.0
	return snappedf(float(get_negative_bubble_count()) / float(total) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"icon_types": BUBBLE_ICONS.size(),
		"active_bubbles": _active_bubbles.size(),
		"distribution": get_bubble_distribution(),
		"most_common": get_most_common_bubble(),
		"positive_count": get_positive_bubble_count(),
		"negative_count": get_negative_bubble_count(),
		"coverage_pct": get_bubble_coverage(),
		"unique_types": get_unique_bubble_type_count(),
		"avg_per_pawn": get_avg_bubbles_per_pawn(),
		"mood_signal": get_mood_signal(),
		"expressiveness_pct": get_expressiveness_pct(),
		"negativity_ratio": get_negativity_ratio(),
		"emotional_bandwidth": get_emotional_bandwidth(),
		"mood_forecast": get_mood_forecast(),
		"sentiment_stability": get_sentiment_stability(),
		"emotional_intelligence_index": get_emotional_intelligence_index(),
		"mood_ecology_score": get_mood_ecology_score(),
		"psychological_transparency": get_psychological_transparency(),
	}

func get_emotional_intelligence_index() -> float:
	var positive := float(get_positive_bubble_count())
	var total := float(_active_bubbles.size())
	if total <= 0.0:
		return 0.0
	return snapped(positive / total * 100.0, 0.1)

func get_mood_ecology_score() -> float:
	var coverage := get_bubble_coverage()
	var expressiveness := get_expressiveness_pct()
	return snapped((coverage + expressiveness) / 2.0, 0.1)

func get_psychological_transparency() -> String:
	var bandwidth := get_emotional_bandwidth()
	var stability := get_sentiment_stability()
	if bandwidth == "Rich" and stability in ["Stable", "Very Stable"]:
		return "Crystal Clear"
	elif bandwidth == "Narrow":
		return "Opaque"
	return "Translucent"

func get_emotional_bandwidth() -> String:
	var unique := get_unique_bubble_type_count()
	if unique >= 6:
		return "Rich"
	elif unique >= 3:
		return "Moderate"
	elif unique > 0:
		return "Narrow"
	return "None"

func get_mood_forecast() -> String:
	var signal_val := get_mood_signal()
	var neg_ratio := get_negativity_ratio()
	if signal_val in ["Positive", "Leaning Positive"] and neg_ratio < 30.0:
		return "Improving"
	elif signal_val in ["Distressed"] or neg_ratio > 60.0:
		return "Declining"
	return "Stable"

func get_sentiment_stability() -> float:
	var pos := get_positive_bubble_count()
	var neg := get_negative_bubble_count()
	var total := pos + neg
	if total <= 0:
		return 100.0
	return snapped((1.0 - absf(float(pos - neg)) / float(total)) * 100.0, 0.1)
