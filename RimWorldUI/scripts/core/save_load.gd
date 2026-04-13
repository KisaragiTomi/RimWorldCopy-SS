class_name SaveLoad
extends RefCounted

## JSON-based save/load system.
## Serializes MapData and game state to user://saves/.

const SAVE_DIR := "user://saves"
const SAVE_EXT := ".rws"   # RimWorld Save


static func ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


static func save_game(filename: String, map: MapData) -> Error:
	ensure_save_dir()
	var path := SAVE_DIR.path_join(filename + SAVE_EXT)

	var data := {
		"version": 2,
		"timestamp": Time.get_datetime_string_from_system(),
		"game_state": _serialize_game_state(),
		"map": map.to_dict(),
		"pawns": _serialize_pawns(),
		"things": _serialize_things(),
		"zones": _serialize_zones(),
		"research": _serialize_research(),
		"trade": _serialize_trade(),
	}

	var json_str := JSON.stringify(data)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveLoad: cannot write %s" % path)
		return FileAccess.get_open_error()
	file.store_string(json_str)
	file.close()
	print("SaveLoad: saved to %s" % path)
	return OK


static func load_game(filename: String) -> Dictionary:
	var path := SAVE_DIR.path_join(filename + SAVE_EXT)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveLoad: cannot read %s" % path)
		return {}
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("SaveLoad: parse error in %s" % path)
		return {}

	return json.data as Dictionary


static func load_map(filename: String) -> MapData:
	var data := load_game(filename)
	if data.is_empty() or not data.has("map"):
		return null
	var map := MapData.from_dict(data["map"])
	_restore_game_state(data.get("game_state", {}))
	_restore_zones(data.get("zones", {}), map)
	return map


static func _restore_zones(zone_data: Dictionary, map: MapData) -> void:
	if not ZoneManager:
		return
	ZoneManager.zones.clear()
	for key: String in zone_data:
		var parts := key.split(",")
		if parts.size() != 2:
			continue
		var pos := Vector2i(int(parts[0]), int(parts[1]))
		var zone_type: String = zone_data[key]
		ZoneManager.zones[pos] = zone_type
	for y: int in map.height:
		for x: int in map.width:
			var cell := map.get_cell(x, y)
			if cell and cell.zone != "":
				var pos := Vector2i(x, y)
				if not ZoneManager.zones.has(pos):
					ZoneManager.zones[pos] = cell.zone


static func list_saves() -> PackedStringArray:
	ensure_save_dir()
	var saves := PackedStringArray()
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return saves
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.ends_with(SAVE_EXT):
			saves.append(entry.get_basename())
		entry = dir.get_next()
	return saves


static func delete_save(filename: String) -> Error:
	var path := SAVE_DIR.path_join(filename + SAVE_EXT)
	return DirAccess.remove_absolute(path)


static func _serialize_pawns() -> Array:
	if not PawnManager:
		return []
	var result: Array = []
	for p: Pawn in PawnManager.pawns:
		var d := p.to_dict()
		if p.health:
			d["health"] = p.health.to_dict()
		if p.equipment:
			d["equipment"] = p.equipment.get_summary()
		d["is_enemy"] = p.has_meta("faction") and p.get_meta("faction") == "enemy"
		result.append(d)
	return result


static func _serialize_things() -> Array:
	if not ThingManager:
		return []
	var result: Array = []
	for t: Thing in ThingManager.things:
		result.append(t.to_dict())
	return result


static func _serialize_zones() -> Dictionary:
	if not ZoneManager:
		return {}
	var result: Dictionary = {}
	for pos: Vector2i in ZoneManager.zones:
		result[str(pos.x) + "," + str(pos.y)] = ZoneManager.zones[pos]
	return result


static func _serialize_research() -> Dictionary:
	if not ResearchManager:
		return {}
	return ResearchManager.get_summary()


static func _serialize_trade() -> Dictionary:
	if not TradeManager:
		return {}
	return TradeManager.get_summary()


static func get_save_section_count() -> int:
	return 7

static func get_save_version() -> int:
	return 2

static func get_save_count() -> int:
	return list_saves().size()

static func get_latest_save_name() -> String:
	var saves: Array = list_saves()
	if saves.is_empty():
		return ""
	return saves[-1]


static func has_any_save() -> bool:
	return not list_saves().is_empty()


static func get_save_slot_usage_pct(max_slots: int = 10) -> float:
	if max_slots <= 0:
		return 0.0
	return snappedf(float(get_save_count()) / float(max_slots) * 100.0, 0.1)


static func get_data_integrity_score() -> float:
	var version := get_save_version()
	var sections := get_save_section_count()
	var has := has_any_save()
	var score := 0.0
	if version > 0:
		score += 30.0
	if sections >= 3:
		score += 30.0
	elif sections >= 1:
		score += 15.0
	if has:
		score += 40.0
	return snapped(score, 0.1)

static func get_backup_redundancy() -> String:
	var count := get_save_count()
	if count >= 5:
		return "Excellent"
	elif count >= 3:
		return "Good"
	elif count >= 1:
		return "Minimal"
	return "None"

static func get_storage_efficiency() -> float:
	var slots := get_save_slot_usage_pct()
	var count := get_save_count()
	if count <= 0:
		return 0.0
	return snapped(minf(slots, 100.0) * (1.0 - absf(slots - 50.0) / 100.0), 0.1)

static func get_summary() -> Dictionary:
	return {
		"save_version": get_save_version(),
		"save_sections": get_save_section_count(),
		"save_count": get_save_count(),
		"latest_save": get_latest_save_name(),
		"has_saves": has_any_save(),
		"slot_usage_pct": get_save_slot_usage_pct(),
		"data_integrity": get_data_integrity_score(),
		"backup_redundancy": get_backup_redundancy(),
		"storage_efficiency": get_storage_efficiency(),
		"persistence_reliability": get_persistence_reliability(),
		"save_ecosystem_health": get_save_ecosystem_health(),
		"data_governance_score": get_data_governance_score(),
	}

static func get_persistence_reliability() -> String:
	var integrity: float = get_data_integrity_score()
	var redundancy: String = get_backup_redundancy()
	if integrity >= 80.0 and redundancy in ["Excellent", "Good"]:
		return "Reliable"
	if integrity >= 50.0:
		return "Adequate"
	return "Fragile"

static func get_save_ecosystem_health() -> String:
	var saves: bool = has_any_save()
	var slots: float = get_save_slot_usage_pct()
	if saves and slots >= 30.0:
		return "Healthy"
	if saves:
		return "Minimal"
	return "None"

static func get_data_governance_score() -> float:
	var integrity: float = get_data_integrity_score()
	var efficiency: float = get_storage_efficiency()
	return snappedf(clampf((integrity + efficiency) / 2.0, 0.0, 100.0), 0.1)

static func _serialize_game_state() -> Dictionary:
	if not GameState:
		return {}
	return {
		"colony_name": GameState.colony_name,
		"game_date": GameState.game_date,
		"temperature": GameState.temperature,
		"season": GameState.season,
		"time_speed": GameState.time_speed,
	}


static func _restore_game_state(d: Dictionary) -> void:
	if not GameState or d.is_empty():
		return
	GameState.colony_name = d.get("colony_name", GameState.colony_name)
	if d.has("game_date"):
		GameState.game_date = d["game_date"]
	GameState.temperature = d.get("temperature", GameState.temperature)
	GameState.season = d.get("season", GameState.season)
	GameState.time_speed = d.get("time_speed", 1)
