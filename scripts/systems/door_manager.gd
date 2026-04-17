extends Node

## Manages door state (open/closed/forbidden). Doors auto-open when a pawn
## approaches and auto-close after a delay. Registered as autoload "DoorManager".

const OPEN_TICKS: int = 120
const DOOR_SPEED_PENALTY: float = 0.45
const PROXIMITY_RANGE: int = 1

var _doors: Dictionary = {}  # Vector2i -> {open, forbidden, close_timer, building_id, held_open, locked, total_opens}
var total_opens: int = 0


func register_door(pos: Vector2i, building_id: int) -> void:
	_doors[pos] = {
		"open": false,
		"forbidden": false,
		"close_timer": 0,
		"building_id": building_id,
		"held_open": false,
		"locked": false,
		"open_count": 0,
	}


func unregister_door(pos: Vector2i) -> void:
	_doors.erase(pos)


func is_door(pos: Vector2i) -> bool:
	return _doors.has(pos)


func is_open(pos: Vector2i) -> bool:
	if not _doors.has(pos):
		return false
	return _doors[pos].open


func is_forbidden(pos: Vector2i) -> bool:
	if not _doors.has(pos):
		return false
	return _doors[pos].forbidden


func set_forbidden(pos: Vector2i, value: bool) -> void:
	if _doors.has(pos):
		_doors[pos].forbidden = value


func request_open(pos: Vector2i) -> void:
	if not _doors.has(pos):
		return
	var d: Dictionary = _doors[pos]
	if d.forbidden or d.locked:
		return
	if not d.open:
		d.open_count += 1
		total_opens += 1
	d.open = true
	d.close_timer = OPEN_TICKS


func set_held_open(pos: Vector2i, value: bool) -> void:
	if _doors.has(pos):
		_doors[pos].held_open = value
		if value:
			_doors[pos].open = true


func is_held_open(pos: Vector2i) -> bool:
	if not _doors.has(pos):
		return false
	return _doors[pos].held_open


func set_locked(pos: Vector2i, value: bool) -> void:
	if _doors.has(pos):
		_doors[pos].locked = value
		if value:
			_doors[pos].open = false


func is_locked(pos: Vector2i) -> bool:
	if not _doors.has(pos):
		return false
	return _doors[pos].locked


func get_path_cost_modifier(pos: Vector2i) -> float:
	if not _doors.has(pos):
		return 0.0
	if _doors[pos].forbidden:
		return 999.0
	if _doors[pos].open:
		return DOOR_SPEED_PENALTY * 0.3
	return DOOR_SPEED_PENALTY


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func _on_rare_tick(_tick: int) -> void:
	for pos: Vector2i in _doors:
		var d: Dictionary = _doors[pos]
		if d.held_open:
			continue
		if d.open and d.close_timer > 0:
			d.close_timer -= 250
			if d.close_timer <= 0:
				d.open = false
	_check_proximity_opens()


func get_door_count() -> int:
	return _doors.size()


func _check_proximity_opens() -> void:
	if not PawnManager:
		return
	for pos: Vector2i in _doors:
		var d: Dictionary = _doors[pos]
		if d.open or d.forbidden or d.locked:
			continue
		for p: Pawn in PawnManager.pawns:
			if p.dead:
				continue
			var dist: int = absi(p.grid_pos.x - pos.x) + absi(p.grid_pos.y - pos.y)
			if dist <= PROXIMITY_RANGE:
				request_open(pos)
				break


func get_locked_count() -> int:
	var count: int = 0
	for pos: Vector2i in _doors:
		if _doors[pos].locked:
			count += 1
	return count


func get_most_used_door() -> Vector2i:
	var best_pos := Vector2i(-1, -1)
	var best_count: int = 0
	for pos: Vector2i in _doors:
		var cnt: int = _doors[pos].get("open_count", 0)
		if cnt > best_count:
			best_count = cnt
			best_pos = pos
	return best_pos


func get_avg_opens_per_door() -> float:
	if _doors.is_empty():
		return 0.0
	return snappedf(float(total_opens) / float(_doors.size()), 0.01)


func get_open_percentage() -> float:
	if _doors.is_empty():
		return 0.0
	var open_c: int = 0
	for pos: Vector2i in _doors:
		if _doors[pos].open:
			open_c += 1
	return snappedf(float(open_c) / float(_doors.size()) * 100.0, 0.1)


func get_traffic_level() -> String:
	var avg: float = get_avg_opens_per_door()
	if avg >= 20.0:
		return "Heavy"
	elif avg >= 10.0:
		return "Moderate"
	elif avg > 0.0:
		return "Light"
	return "None"

func get_security_rating() -> String:
	if _doors.is_empty():
		return "None"
	var restricted: int = get_locked_count()
	for pos: Vector2i in _doors:
		if _doors[pos].forbidden:
			restricted += 1
	if restricted == 0:
		return "Open"
	elif float(restricted) / float(_doors.size()) < 0.3:
		return "Partial"
	return "Secured"

func get_held_open_pct() -> float:
	if _doors.is_empty():
		return 0.0
	var held: int = 0
	for pos: Vector2i in _doors:
		if _doors[pos].get("held_open", false):
			held += 1
	return snappedf(float(held) / float(_doors.size()) * 100.0, 0.1)

func get_access_control_health() -> String:
	var security := get_security_rating()
	var held := get_held_open_pct()
	if security == "Secured" and held < 20.0:
		return "Robust"
	elif security == "Partial":
		return "Moderate"
	elif held > 50.0:
		return "Compromised"
	return "Open"

func get_flow_efficiency() -> float:
	if _doors.is_empty():
		return 0.0
	var accessible := 0
	for pos: Vector2i in _doors:
		var d: Dictionary = _doors[pos]
		if not d.get("forbidden", false) and not d.get("locked", false):
			accessible += 1
	return snapped(float(accessible) / float(_doors.size()) * 100.0, 0.1)

func get_vulnerability_index() -> float:
	var held := get_held_open_pct()
	var open := get_open_percentage()
	return snapped((held + open) / 2.0, 0.1)

func get_summary() -> Dictionary:
	var open_count := 0
	var forbidden_count := 0
	var held_count := 0
	var locked_count := 0
	for pos: Vector2i in _doors:
		var d: Dictionary = _doors[pos]
		if d.open:
			open_count += 1
		if d.forbidden:
			forbidden_count += 1
		if d.get("held_open", false):
			held_count += 1
		if d.get("locked", false):
			locked_count += 1
	var accessible: int = _doors.size() - forbidden_count - locked_count
	return {
		"total_doors": _doors.size(),
		"open": open_count,
		"forbidden": forbidden_count,
		"held_open": held_count,
		"locked": locked_count,
		"total_opens": total_opens,
		"avg_opens_per_door": get_avg_opens_per_door(),
		"open_pct": get_open_percentage(),
		"accessible": accessible,
		"restricted_pct": snappedf((float(forbidden_count + locked_count) / maxf(float(_doors.size()), 1.0)) * 100.0, 0.1),
		"traffic_level": get_traffic_level(),
		"security_rating": get_security_rating(),
		"held_open_pct": get_held_open_pct(),
		"access_control_health": get_access_control_health(),
		"flow_efficiency": get_flow_efficiency(),
		"vulnerability_index": get_vulnerability_index(),
		"portal_management_maturity": get_portal_management_maturity(),
		"transit_optimization": get_transit_optimization(),
		"security_posture_score": get_security_posture_score(),
	}

func get_portal_management_maturity() -> String:
	var total: int = _doors.size()
	var security: String = get_security_rating()
	if total >= 15 and security in ["Secure", "Fortified"]:
		return "Mature"
	if total >= 8:
		return "Developing"
	if total >= 3:
		return "Basic"
	return "Minimal"

func get_transit_optimization() -> float:
	var flow: float = get_flow_efficiency()
	var held_pct: float = get_held_open_pct()
	var score: float = flow * 0.7 + held_pct * 0.3
	return snappedf(clampf(score, 0.0, 100.0), 0.1)

func get_security_posture_score() -> float:
	var vuln: float = get_vulnerability_index()
	var score: float = 100.0 - vuln
	return snappedf(clampf(score, 0.0, 100.0), 0.1)


func to_dict() -> Dictionary:
	var data: Dictionary = {}
	for pos: Vector2i in _doors:
		data["%d,%d" % [pos.x, pos.y]] = {
			"open": _doors[pos].open,
			"forbidden": _doors[pos].forbidden,
			"building_id": _doors[pos].building_id,
		}
	return data


func from_dict(data: Dictionary) -> void:
	_doors.clear()
	for key: String in data:
		var parts := key.split(",")
		if parts.size() == 2:
			var pos := Vector2i(int(parts[0]), int(parts[1]))
			var d: Dictionary = data[key]
			_doors[pos] = {
				"open": d.get("open", false),
				"forbidden": d.get("forbidden", false),
				"close_timer": 0,
				"building_id": d.get("building_id", 0),
			}
