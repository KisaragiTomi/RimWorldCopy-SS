extends Node

var _logs: Array = []
var _daily_summaries: Dictionary = {}

const LOG_CATEGORIES: Dictionary = {
	"Combat": {"icon": "sword", "priority": 3},
	"Social": {"icon": "chat", "priority": 1},
	"Work": {"icon": "hammer", "priority": 1},
	"Health": {"icon": "heart", "priority": 2},
	"Event": {"icon": "alert", "priority": 3},
	"Trade": {"icon": "coin", "priority": 2},
	"Research": {"icon": "book", "priority": 1},
	"Construction": {"icon": "build", "priority": 1},
	"Crime": {"icon": "skull", "priority": 3},
	"Mood": {"icon": "face", "priority": 2}
}

const MAX_LOGS: int = 500

func log_activity(day: int, category: String, message: String, pawn_id: int = -1) -> Dictionary:
	if not LOG_CATEGORIES.has(category):
		return {"error": "unknown_category"}
	var entry: Dictionary = {"day": day, "category": category, "message": message, "pawn_id": pawn_id}
	_logs.append(entry)
	if _logs.size() > MAX_LOGS:
		_logs.pop_front()
	if not _daily_summaries.has(day):
		_daily_summaries[day] = {}
	_daily_summaries[day][category] = _daily_summaries[day].get(category, 0) + 1
	return {"logged": true, "total_logs": _logs.size()}

func get_day_summary(day: int) -> Dictionary:
	return _daily_summaries.get(day, {})

func get_recent_logs(count: int) -> Array:
	var start: int = maxi(0, _logs.size() - count)
	return _logs.slice(start)

func get_category_totals() -> Dictionary:
	var totals: Dictionary = {}
	for entry: Dictionary in _logs:
		var c: String = String(entry.get("category", ""))
		totals[c] = int(totals.get(c, 0)) + 1
	return totals


func get_most_active_category() -> String:
	var totals: Dictionary = get_category_totals()
	var best: String = ""
	var best_c: int = 0
	for c: String in totals:
		if int(totals[c]) > best_c:
			best_c = int(totals[c])
			best = c
	return best


func get_high_priority_logs(min_priority: int = 3) -> Array:
	var result: Array = []
	for entry: Dictionary in _logs:
		var cat: String = String(entry.get("category", ""))
		if int(LOG_CATEGORIES.get(cat, {}).get("priority", 0)) >= min_priority:
			result.append(entry)
	return result


func get_high_priority_count() -> int:
	var count: int = 0
	for l: Dictionary in _logs:
		var cat: String = String(l.get("category", ""))
		if LOG_CATEGORIES.has(cat) and int(LOG_CATEGORIES[cat].get("priority", 0)) >= 3:
			count += 1
	return count


func get_avg_logs_per_day() -> float:
	if _daily_summaries.is_empty():
		return 0.0
	return float(_logs.size()) / _daily_summaries.size()


func get_unique_categories_used() -> int:
	var cats: Dictionary = {}
	for l: Dictionary in _logs:
		cats[String(l.get("category", ""))] = true
	return cats.size()


func get_low_priority_count() -> int:
	var count: int = 0
	for l: Dictionary in _logs:
		var cat: String = String(l.get("category", ""))
		if LOG_CATEGORIES.has(cat) and int(LOG_CATEGORIES[cat].get("priority", 0)) <= 1:
			count += 1
	return count


func get_unique_pawns_logged() -> int:
	var pawns: Dictionary = {}
	for l: Dictionary in _logs:
		var pid: int = int(l.get("pawn_id", -1))
		if pid >= 0:
			pawns[pid] = true
	return pawns.size()


func get_most_logged_day() -> int:
	var best_day: int = -1
	var best_count: int = 0
	for day: int in _daily_summaries:
		var total: int = 0
		for cat: String in _daily_summaries[day]:
			total += int(_daily_summaries[day][cat])
		if total > best_count:
			best_count = total
			best_day = day
	return best_day


func get_operational_tempo() -> String:
	var avg: float = get_avg_logs_per_day()
	if avg >= 20.0:
		return "intense"
	if avg >= 8.0:
		return "active"
	if avg >= 2.0:
		return "moderate"
	return "quiet"

func get_focus_distribution_pct() -> float:
	var totals: Dictionary = get_category_totals()
	if totals.is_empty():
		return 0.0
	var max_count: int = 0
	var total: int = 0
	for cat: String in totals:
		total += totals[cat]
		if totals[cat] > max_count:
			max_count = totals[cat]
	if total == 0:
		return 0.0
	return snapped(max_count * 100.0 / total, 0.1)

func get_alert_saturation() -> String:
	var high: int = get_high_priority_count()
	var total: int = _logs.size()
	if total == 0:
		return "clear"
	var ratio: float = high * 1.0 / total
	if ratio >= 0.5:
		return "critical"
	if ratio >= 0.2:
		return "elevated"
	return "normal"

func get_summary() -> Dictionary:
	return {
		"log_categories": LOG_CATEGORIES.size(),
		"total_logs": _logs.size(),
		"days_tracked": _daily_summaries.size(),
		"most_active": get_most_active_category(),
		"high_priority": get_high_priority_count(),
		"avg_per_day": snapped(get_avg_logs_per_day(), 0.1),
		"categories_used": get_unique_categories_used(),
		"low_priority": get_low_priority_count(),
		"unique_pawns": get_unique_pawns_logged(),
		"busiest_day": get_most_logged_day(),
		"operational_tempo": get_operational_tempo(),
		"focus_distribution_pct": get_focus_distribution_pct(),
		"alert_saturation": get_alert_saturation(),
		"colony_activity_index": get_colony_activity_index(),
		"event_density_trend": get_event_density_trend(),
		"situational_awareness": get_situational_awareness(),
		"information_governance": get_information_governance(),
		"logging_maturity_score": get_logging_maturity_score(),
		"operational_insight_index": get_operational_insight_index(),
	}

func get_information_governance() -> String:
	var categories: int = get_unique_categories_used()
	var saturation: String = get_alert_saturation()
	if categories >= 5 and saturation != "Overloaded":
		return "Well-Governed"
	if categories >= 3:
		return "Adequate"
	return "Minimal"

func get_logging_maturity_score() -> float:
	var days: int = _daily_summaries.size()
	var cats: int = get_unique_categories_used()
	var total: int = LOG_CATEGORIES.size()
	var coverage: float = float(cats) / float(maxi(total, 1)) * 100.0
	var age_bonus: float = minf(float(days) * 2.0, 40.0)
	return snappedf(clampf(coverage * 0.6 + age_bonus, 0.0, 100.0), 0.1)

func get_operational_insight_index() -> float:
	var activity: float = get_colony_activity_index()
	var awareness: String = get_situational_awareness()
	var base: float = minf(activity, 80.0)
	if awareness == "High":
		base += 20.0
	elif awareness == "Medium":
		base += 10.0
	return snappedf(clampf(base, 0.0, 100.0), 0.1)

func get_colony_activity_index() -> float:
	var avg := get_avg_logs_per_day()
	var categories := get_unique_categories_used()
	return snapped(avg * float(categories), 0.1)

func get_event_density_trend() -> String:
	var days := _daily_summaries.size()
	if days <= 1:
		return "Insufficient Data"
	var total := _logs.size()
	var recent_avg := float(total) / float(days)
	if recent_avg >= 10.0:
		return "Intensifying"
	elif recent_avg >= 3.0:
		return "Steady"
	return "Quiet"

func get_situational_awareness() -> String:
	var categories := get_unique_categories_used()
	var total := LOG_CATEGORIES.size()
	if total <= 0:
		return "None"
	var coverage := float(categories) / float(total)
	if coverage >= 0.8:
		return "Comprehensive"
	elif coverage >= 0.5:
		return "Moderate"
	return "Limited"
