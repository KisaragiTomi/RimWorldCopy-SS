extends Node

## Periodic autosave system.
## Registered as autoload "AutosaveManager".

signal autosave_started()
signal autosave_completed(path: String)

var autosave_interval_ticks: int = 15000
var max_autosaves: int = 3
var _last_save_tick: int = 0
var _autosave_count: int = 0
var _save_history: Array[Dictionary] = []
var total_bytes_written: int = 0
var enabled: bool = true


func _ready() -> void:
	if TickManager:
		TickManager.long_tick.connect(_on_long_tick)


func _on_long_tick(_tick: int) -> void:
	if not enabled:
		return
	var current_tick: int = TickManager.current_tick if TickManager else 0
	if current_tick - _last_save_tick >= autosave_interval_ticks:
		perform_autosave()
		_last_save_tick = current_tick


func perform_autosave() -> void:
	autosave_started.emit()

	_autosave_count += 1
	var slot: int = (_autosave_count - 1) % max_autosaves + 1
	var save_path: String = "user://autosave_" + str(slot) + ".json"

	var save_data := _build_save_data()
	var json_str: String = JSON.stringify(save_data, "\t")
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		var byte_size: int = json_str.length()
		total_bytes_written += byte_size
		_save_history.append({
			"slot": slot,
			"tick": save_data.get("tick", 0),
			"size_bytes": byte_size,
			"pawn_count": save_data.get("pawn_count", 0),
		})
		if _save_history.size() > 50:
			_save_history = _save_history.slice(_save_history.size() - 50)
		autosave_completed.emit(save_path)

		if ColonyLog:
			ColonyLog.add_entry("System", "Autosave #%d completed (%d bytes)." % [slot, byte_size], "info")


func _build_save_data() -> Dictionary:
	var data := {
		"version": 2,
		"tick": TickManager.current_tick if TickManager else 0,
		"temperature": GameState.temperature if GameState else 15.0,
		"pawn_count": PawnManager.pawns.size() if PawnManager else 0,
		"thing_count": ThingManager.things.size() if ThingManager else 0,
	}

	if WeatherManager:
		data["weather"] = WeatherManager.get_current_weather_name() if WeatherManager.has_method("get_current_weather_name") else "Clear"

	if ResearchManager:
		data["research"] = ResearchManager.get_summary()

	if HistoryTracker:
		data["history_records"] = HistoryTracker.records.size()

	return data


func list_saves() -> Array[String]:
	var saves: Array[String] = []
	for i: int in range(1, max_autosaves + 1):
		var path: String = "user://autosave_" + str(i) + ".json"
		if FileAccess.file_exists(path):
			saves.append(path)
	return saves


func get_save_info(slot: int) -> Dictionary:
	var path: String = "user://autosave_" + str(slot) + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var data: Dictionary = json.data if json.data is Dictionary else {}
	return {
		"slot": slot,
		"tick": data.get("tick", 0),
		"pawn_count": data.get("pawn_count", 0),
		"size_bytes": text.length(),
	}


func get_recent_history(count: int = 10) -> Array[Dictionary]:
	var start: int = maxi(0, _save_history.size() - count)
	return _save_history.slice(start) as Array[Dictionary]


func get_avg_save_size() -> int:
	if _save_history.is_empty():
		return 0
	var total: int = 0
	for s: Dictionary in _save_history:
		total += s.get("bytes", 0) as int
	return total / _save_history.size()


func get_time_until_next_save() -> int:
	if not TickManager or not enabled:
		return -1
	return maxi(0, autosave_interval_ticks - (TickManager.current_tick - _last_save_tick))


func is_save_due() -> bool:
	return get_time_until_next_save() == 0


func get_bytes_per_save() -> float:
	if _autosave_count == 0:
		return 0.0
	return float(total_bytes_written) / float(_autosave_count)


func get_save_slot_usage() -> float:
	var saves: int = list_saves().size()
	if max_autosaves == 0:
		return 0.0
	return float(saves) / float(max_autosaves) * 100.0


func is_slot_full() -> bool:
	return list_saves().size() >= max_autosaves


func get_save_frequency_rating() -> String:
	if not enabled:
		return "Disabled"
	if autosave_interval_ticks <= 5000:
		return "Frequent"
	elif autosave_interval_ticks <= 15000:
		return "Normal"
	return "Infrequent"

func get_total_save_sessions() -> int:
	return _autosave_count

func get_data_efficiency() -> float:
	if _autosave_count <= 0 or total_bytes_written <= 0:
		return 0.0
	return snappedf(float(total_bytes_written) / float(_autosave_count) / 1024.0, 0.01)

func get_data_safety() -> String:
	if not enabled:
		return "Unprotected"
	if is_slot_full():
		return "At Risk"
	var rating := get_save_frequency_rating()
	if rating == "Frequent":
		return "Well Protected"
	elif rating == "Normal":
		return "Protected"
	return "Minimal"

func get_storage_pressure_pct() -> float:
	var usage := get_save_slot_usage()
	return snapped(usage, 0.1)

func get_save_health() -> String:
	var eff := get_data_efficiency()
	var safety := get_data_safety()
	if safety == "Well Protected" and eff < 500.0:
		return "Optimal"
	elif safety == "Unprotected":
		return "Critical"
	elif eff > 1000.0:
		return "Bloated"
	return "Normal"

func get_summary() -> Dictionary:
	return {
		"autosave_count": _autosave_count,
		"interval_ticks": autosave_interval_ticks,
		"max_slots": max_autosaves,
		"last_save_tick": _last_save_tick,
		"enabled": enabled,
		"total_bytes_written": total_bytes_written,
		"save_files": list_saves().size(),
		"recent_history": get_recent_history(5),
		"avg_save_size": get_avg_save_size(),
		"ticks_until_next": get_time_until_next_save(),
		"bytes_per_save": snappedf(get_bytes_per_save(), 0.1),
		"slot_usage_pct": snappedf(get_save_slot_usage(), 0.1),
		"slots_full": is_slot_full(),
		"frequency_rating": get_save_frequency_rating(),
		"total_sessions": get_total_save_sessions(),
		"kb_per_save": get_data_efficiency(),
		"data_safety": get_data_safety(),
		"storage_pressure_pct": get_storage_pressure_pct(),
		"save_health": get_save_health(),
		"backup_reliability": get_backup_reliability(),
		"data_integrity_score": get_data_integrity_score(),
		"save_system_maturity": get_save_system_maturity(),
	}

func get_backup_reliability() -> String:
	var slots: float = get_save_slot_usage()
	var safety: String = get_data_safety()
	if slots >= 50.0 and safety == "Safe":
		return "Reliable"
	if slots >= 20.0:
		return "Adequate"
	return "Insufficient"

func get_data_integrity_score() -> float:
	var pressure: float = get_storage_pressure_pct()
	var health: String = get_save_health()
	var base: float = 100.0 - pressure
	if health == "Healthy":
		base += 10.0
	elif health == "Warning":
		base -= 10.0
	return snappedf(clampf(base, 0.0, 100.0), 0.1)

func get_save_system_maturity() -> String:
	var sessions: int = get_total_save_sessions()
	var saves: int = _autosave_count
	if saves >= 20 and sessions >= 5:
		return "Mature"
	if saves >= 5:
		return "Developing"
	return "Initial"
