extends Node

## Colony event log and notification system.
## Registered as autoload "ColonyLog".

signal log_added(entry: Dictionary)

var entries: Array[Dictionary] = []
var max_entries: int = 500
var category_counts: Dictionary = {}
var severity_counts: Dictionary = {"info": 0, "positive": 0, "warning": 0, "danger": 0}
var pinned: Array[Dictionary] = []

const SEVERITY_ORDER := {"danger": 3, "warning": 2, "positive": 1, "info": 0}


func _ready() -> void:
	if IncidentManager:
		IncidentManager.incident_fired.connect(_on_incident)
	if PawnManager:
		PawnManager.mental_break_started.connect(_on_mental_break)
	if RaidManager:
		RaidManager.raid_started.connect(_on_raid_started)
		RaidManager.raid_ended.connect(_on_raid_ended)
	if ResearchManager:
		ResearchManager.research_completed.connect(_on_research_done)
	if TradeManager:
		TradeManager.trader_arrived.connect(_on_trader_arrived)
		TradeManager.trader_left.connect(_on_trader_left)
	if GameState and GameState.has_signal("game_over_triggered"):
		GameState.game_over_triggered.connect(_on_game_over)


func add_entry(category: String, message: String, severity: String = "info") -> void:
	var day: int = GameState.game_date.get("day", 0) if GameState else 0
	var hour: int = GameState.game_date.get("hour", 0) if GameState else 0
	var entry := {
		"tick": TickManager.current_tick if TickManager else 0,
		"day": day,
		"hour": hour,
		"category": category,
		"message": message,
		"severity": severity,
	}
	entries.append(entry)
	if entries.size() > max_entries:
		entries.pop_front()
	category_counts[category] = category_counts.get(category, 0) + 1
	severity_counts[severity] = severity_counts.get(severity, 0) + 1
	log_added.emit(entry)


func pin_entry(entry: Dictionary) -> void:
	if entry not in pinned:
		pinned.append(entry)


func get_recent(count: int = 20) -> Array[Dictionary]:
	var start := maxi(0, entries.size() - count)
	var result: Array[Dictionary] = []
	for i: int in range(start, entries.size()):
		result.append(entries[i])
	return result


func get_by_category(category: String, count: int = 30) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var idx: int = entries.size() - 1
	while idx >= 0 and result.size() < count:
		if entries[idx]["category"] == category:
			result.append(entries[idx])
		idx -= 1
	result.reverse()
	return result


func get_by_severity(severity: String, count: int = 30) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var idx: int = entries.size() - 1
	while idx >= 0 and result.size() < count:
		if entries[idx]["severity"] == severity:
			result.append(entries[idx])
		idx -= 1
	result.reverse()
	return result


func get_by_day(day: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for e: Dictionary in entries:
		if e["day"] == day:
			result.append(e)
	return result


func search(keyword: String, count: int = 30) -> Array[Dictionary]:
	var lower_key: String = keyword.to_lower()
	var result: Array[Dictionary] = []
	var idx: int = entries.size() - 1
	while idx >= 0 and result.size() < count:
		if entries[idx]["message"].to_lower().contains(lower_key):
			result.append(entries[idx])
		idx -= 1
	result.reverse()
	return result


func get_entries_per_day_avg() -> float:
	if entries.is_empty():
		return 0.0
	var first_day: int = entries[0].get("day", 0)
	var last_day: int = entries[entries.size() - 1].get("day", 0)
	var days: int = maxi(1, last_day - first_day + 1)
	return snappedf(float(entries.size()) / float(days), 0.01)

func get_unique_category_count() -> int:
	return category_counts.size()

func get_stats() -> Dictionary:
	return {
		"total": entries.size(),
		"categories": category_counts.duplicate(),
		"severities": severity_counts.duplicate(),
		"danger_count": severity_counts.get("danger", 0),
		"warning_count": severity_counts.get("warning", 0),
		"pinned_count": pinned.size(),
		"busiest_category": get_busiest_category(),
		"entries_per_day": get_entries_per_day_avg(),
		"unique_categories": get_unique_category_count(),
	}


func export_text(count: int = 100) -> String:
	var lines: PackedStringArray = []
	var recent: Array[Dictionary] = get_recent(count)
	for e: Dictionary in recent:
		lines.append("[Day %d %02d:00] [%s] %s" % [e["day"], e["hour"], e["severity"].to_upper(), e["message"]])
	return "\n".join(lines)


func _on_incident(name: String, data: Dictionary) -> void:
	match name:
		"WandererJoin":
			add_entry("Event", data.get("pawn_name", "Someone") + " has joined the colony.", "positive")
		"ResourceDrop":
			add_entry("Event", "A cargo pod containing " + data.get("resource", "supplies") + " has landed nearby.", "positive")
		"ColdSnap":
			add_entry("Event", "A cold snap has begun. Temperature dropped by " + str(snappedf(absf(data.get("shift", 0.0)), 0.1)) + "°C.", "warning")
		"HeatWave":
			add_entry("Event", "A heat wave has begun. Temperature rose by " + str(snappedf(data.get("shift", 0.0), 0.1)) + "°C.", "warning")
		"Disease":
			add_entry("Event", data.get("pawn", "A colonist") + " has contracted " + data.get("disease", "an illness") + ".", "danger")
		"Raid":
			add_entry("Threat", str(data.get("count", 0)) + " raiders are attacking!", "danger")
		"TraderVisit":
			add_entry("Event", "A trade caravan has arrived.", "positive")
		"Eclipse":
			add_entry("Event", "A solar eclipse has begun.", "warning")
		"Blight":
			add_entry("Event", "Blight has struck your crops!", "danger")
		_:
			add_entry("Event", name + " has occurred.", "info")


func _on_mental_break(pawn: Pawn, break_type: String) -> void:
	add_entry("Mental", pawn.pawn_name + " is having a mental break: " + break_type, "danger")


func _on_raid_started(count: int, edge: String) -> void:
	add_entry("Threat", str(count) + " raiders approaching from the " + edge + "!", "danger")


func _on_raid_ended() -> void:
	add_entry("Threat", "The raid has ended.", "info")


func _on_research_done(project_name: String) -> void:
	add_entry("Research", "Research complete: " + project_name, "positive")


func _on_trader_arrived(trader_name: String, _goods: Array) -> void:
	add_entry("Trade", trader_name + " has arrived to trade.", "positive")


func _on_trader_left(trader_name: String) -> void:
	add_entry("Trade", trader_name + " has left the area.", "info")


func get_danger_rate() -> float:
	if entries.is_empty():
		return 0.0
	return float(severity_counts.get("danger", 0)) / float(entries.size())


func get_busiest_category() -> String:
	var best: String = ""
	var best_c: int = 0
	for cat: String in category_counts:
		if category_counts[cat] > best_c:
			best_c = category_counts[cat]
			best = cat
	return best


func get_entries_last_n_days(days: int) -> Array[Dictionary]:
	var current_day: int = GameState.game_date.get("day", 0) if GameState else 0
	var cutoff: int = current_day - days
	var result: Array[Dictionary] = []
	for e: Dictionary in entries:
		if e["day"] >= cutoff:
			result.append(e)
	return result


func get_severity_distribution() -> Dictionary:
	return severity_counts.duplicate()


func get_warning_count() -> int:
	return severity_counts.get("warning", 0)


func get_positive_entry_count() -> int:
	return severity_counts.get("positive", 0)


func get_operational_tempo() -> float:
	if entries.is_empty():
		return 0.0
	var days := float(GameState.game_date.get("day", 1)) if GameState else 1.0
	return snapped(float(entries.size()) / maxf(days, 1.0), 0.01)

func get_crisis_frequency() -> float:
	var danger := float(severity_counts.get("danger", 0))
	var warning := float(severity_counts.get("warning", 0))
	var total := float(entries.size())
	if total <= 0.0:
		return 0.0
	return snapped((danger + warning) / total * 100.0, 0.1)

func get_log_health() -> String:
	var positive := float(severity_counts.get("positive", 0))
	var danger := float(severity_counts.get("danger", 0))
	var warning := float(severity_counts.get("warning", 0))
	var good := positive
	var bad := danger + warning
	if bad <= 0.0 or good > bad * 2.0:
		return "Peaceful"
	elif good > bad:
		return "Stable"
	elif good > bad * 0.5:
		return "Turbulent"
	return "Crisis"

func _on_game_over() -> void:
	add_entry("Colony", "The colony has fallen.", "danger")
