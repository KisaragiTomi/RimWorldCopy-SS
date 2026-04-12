extends Node

## Tracks roofed areas. Roofs affect temperature insulation and "outdoors" mood.
## Registered as autoload "RoofManager".

var _roofed: Dictionary = {}  # Vector2i key string -> bool
var total_roofed_ops: int = 0
var total_unroofed_ops: int = 0

const COLLAPSE_SPAN: int = 6


func set_roof(pos: Vector2i, has_roof: bool) -> void:
	var key: String = _key(pos)
	if has_roof:
		if not _roofed.has(key):
			total_roofed_ops += 1
		_roofed[key] = true
	else:
		if _roofed.has(key):
			total_unroofed_ops += 1
		_roofed.erase(key)


func is_roofed(pos: Vector2i) -> bool:
	return _roofed.has(_key(pos))


func auto_roof_around_buildings() -> void:
	if not ThingManager:
		return
	for t: Thing in ThingManager.things:
		if t is Building:
			var b := t as Building
			if b.build_state == Building.BuildState.COMPLETE and not b.passable:
				_roof_area_around(b.grid_pos, 3)


func _roof_area_around(center: Vector2i, radius: int) -> void:
	for dx: int in range(-radius, radius + 1):
		for dy: int in range(-radius, radius + 1):
			var pos := center + Vector2i(dx, dy)
			if _is_enclosed(pos):
				set_roof(pos, true)


func _is_enclosed(pos: Vector2i) -> bool:
	if not ThingManager:
		return false
	var map: MapData = GameState.get_map() if GameState else null
	if map == null:
		return false
	if not map.in_bounds(pos.x, pos.y):
		return false
	var cell := map.get_cell(pos.x, pos.y)
	if cell and cell.is_mountain:
		return true

	var wall_count: int = 0
	var dirs: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	for d: Vector2i in dirs:
		var neighbor := pos + d
		if not map.in_bounds(neighbor.x, neighbor.y):
			wall_count += 1
			continue
		var nc := map.get_cell(neighbor.x, neighbor.y)
		if nc and nc.is_mountain:
			wall_count += 1
			continue
		for t: Thing in ThingManager.things:
			if t is Building and t.grid_pos == neighbor:
				var b := t as Building
				if not b.passable and b.build_state == Building.BuildState.COMPLETE:
					wall_count += 1
					break

	return wall_count >= 3


func get_temperature_factor(pos: Vector2i) -> float:
	if is_roofed(pos):
		return 0.3
	return 1.0


func get_roofed_in_area(center: Vector2i, radius: int) -> int:
	var count: int = 0
	for dx: int in range(-radius, radius + 1):
		for dy: int in range(-radius, radius + 1):
			if is_roofed(center + Vector2i(dx, dy)):
				count += 1
	return count


func get_unroofed_buildings() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not ThingManager:
		return result
	for t: Thing in ThingManager.things:
		if t is Building:
			var b := t as Building
			if b.build_state == Building.BuildState.COMPLETE and not is_roofed(b.grid_pos):
				result.append(b.grid_pos)
	return result


func remove_roofs_in_area(center: Vector2i, radius: int) -> int:
	var removed: int = 0
	for dx: int in range(-radius, radius + 1):
		for dy: int in range(-radius, radius + 1):
			var pos := center + Vector2i(dx, dy)
			if is_roofed(pos):
				set_roof(pos, false)
				removed += 1
	return removed


func check_collapse_risk(pos: Vector2i) -> bool:
	if not is_roofed(pos):
		return false
	var map: MapData = GameState.get_map() if GameState else null
	if map == null:
		return false
	for dx: int in range(-COLLAPSE_SPAN, COLLAPSE_SPAN + 1):
		for dy: int in range(-COLLAPSE_SPAN, COLLAPSE_SPAN + 1):
			var np := pos + Vector2i(dx, dy)
			if not map.in_bounds(np.x, np.y):
				continue
			var nc := map.get_cell(np.x, np.y)
			if nc and nc.is_mountain:
				return false
			if ThingManager:
				for t: Thing in ThingManager.things:
					if t is Building and t.grid_pos == np:
						var b := t as Building
						if not b.passable and b.build_state == Building.BuildState.COMPLETE:
							return false
	return true


func get_outdoor_colonists() -> Array[Pawn]:
	var result: Array[Pawn] = []
	if not PawnManager:
		return result
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed:
			continue
		if not is_roofed(p.grid_pos):
			result.append(p)
	return result


func get_roofed_percentage() -> float:
	var map: MapData = GameState.get_map() if GameState else null
	if map == null or map.width * map.height == 0:
		return 0.0
	return float(_roofed.size()) / float(map.width * map.height) * 100.0


func get_collapse_risk_count() -> int:
	var cnt: int = 0
	for key: String in _roofed:
		var parts: PackedStringArray = key.split(",")
		if parts.size() == 2:
			var pos := Vector2i(int(parts[0]), int(parts[1]))
			if check_collapse_risk(pos):
				cnt += 1
	return cnt


func needs_roofing_count() -> int:
	return get_unroofed_buildings().size()


func get_roof_ops_total() -> int:
	return total_roofed_ops + total_unroofed_ops


func get_safe_roof_percentage() -> float:
	if _roofed.is_empty():
		return 100.0
	var risky: int = get_collapse_risk_count()
	return (1.0 - float(risky) / float(_roofed.size())) * 100.0


func get_unroofed_room_count() -> int:
	return get_unroofed_buildings().size()


func get_roof_density() -> String:
	var pct: float = get_roofed_percentage()
	if pct >= 50.0:
		return "Dense"
	elif pct >= 25.0:
		return "Moderate"
	elif pct > 0.0:
		return "Sparse"
	return "None"

func get_outdoor_risk_count() -> int:
	return get_outdoor_colonists().size() + get_collapse_risk_count()

func get_roof_health() -> String:
	if get_collapse_risk_count() == 0 and get_unroofed_buildings().is_empty():
		return "Excellent"
	elif get_collapse_risk_count() == 0:
		return "Good"
	elif get_collapse_risk_count() <= 3:
		return "Fair"
	return "Poor"

func get_structural_integrity() -> float:
	var safe := get_safe_roof_percentage()
	var risks := get_collapse_risk_count()
	var total := _roofed.size()
	if total <= 0:
		return 100.0
	var penalty := float(risks) / float(total) * 100.0
	return snapped(maxf(safe - penalty * 2.0, 0.0), 0.1)

func get_shelter_coverage() -> String:
	var pct := get_roofed_percentage()
	if pct >= 90.0:
		return "Full"
	elif pct >= 60.0:
		return "Adequate"
	elif pct >= 30.0:
		return "Partial"
	return "Minimal"

func get_maintenance_backlog() -> int:
	return get_collapse_risk_count() + get_unroofed_buildings().size()

func get_summary() -> Dictionary:
	return {
		"roofed_cells": _roofed.size(),
		"total_roofed_ops": total_roofed_ops,
		"total_unroofed_ops": total_unroofed_ops,
		"unroofed_buildings": get_unroofed_buildings().size(),
		"outdoor_colonists": get_outdoor_colonists().size(),
		"roofed_pct": snappedf(get_roofed_percentage(), 0.1),
		"collapse_risks": get_collapse_risk_count(),
		"total_ops": get_roof_ops_total(),
		"safe_pct": snappedf(get_safe_roof_percentage(), 0.1),
		"roof_density": get_roof_density(),
		"outdoor_risk_count": get_outdoor_risk_count(),
		"roof_health": get_roof_health(),
		"structural_integrity": get_structural_integrity(),
		"shelter_coverage": get_shelter_coverage(),
		"maintenance_backlog": get_maintenance_backlog(),
		"architectural_completeness": get_architectural_completeness(),
		"weather_protection_score": get_weather_protection_score(),
		"structural_lifecycle_health": get_structural_lifecycle_health(),
	}

func get_architectural_completeness() -> float:
	var roofed_pct: float = get_roofed_percentage()
	var risks: int = get_collapse_risk_count()
	var penalty: float = float(risks) * 5.0
	return snappedf(clampf(roofed_pct - penalty, 0.0, 100.0), 0.1)

func get_weather_protection_score() -> String:
	var safe: float = get_safe_roof_percentage()
	var outdoor: int = get_outdoor_risk_count()
	if safe >= 90.0 and outdoor == 0:
		return "Complete"
	if safe >= 70.0:
		return "Adequate"
	if safe >= 40.0:
		return "Partial"
	return "Exposed"

func get_structural_lifecycle_health() -> String:
	var integrity: float = get_structural_integrity()
	var backlog: int = get_maintenance_backlog()
	if integrity >= 80.0 and backlog <= 2:
		return "Excellent"
	if integrity >= 50.0:
		return "Good"
	return "Deteriorating"


func _key(pos: Vector2i) -> String:
	return str(pos.x) + "," + str(pos.y)
