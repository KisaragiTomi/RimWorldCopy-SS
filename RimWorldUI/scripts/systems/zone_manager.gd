extends Node

## Manages map zones: Stockpile, GrowingZone, etc.
## Supports named groups, priority, and item filtering.
## Registered as autoload "ZoneManager".

signal zone_placed(zone_type: String, pos: Vector2i)
signal zone_removed(pos: Vector2i)
signal zone_group_created(group_name: String)

var zones: Dictionary = {}  # Vector2i -> zone_type
var zone_groups: Array[Dictionary] = []  # [{name, type, priority, filter, cells}]
var _next_group_id: int = 1

const ZONE_COLORS: Dictionary = {
	"Stockpile": Color(0.9, 0.8, 0.3, 0.3),
	"GrowingZone": Color(0.3, 0.8, 0.3, 0.3),
	"Dumping": Color(0.6, 0.4, 0.2, 0.3),
	"HomeArea": Color(0.3, 0.6, 0.9, 0.15),
	"AnimalArea": Color(0.9, 0.5, 0.2, 0.3),
}


func place_zone(zone_type: String, pos: Vector2i) -> bool:
	var map: MapData = GameState.get_map() if GameState else null
	if map == null:
		return false
	var cell := map.get_cell(pos.x, pos.y)
	if cell == null or not cell.is_passable():
		return false
	cell.zone = zone_type
	zones[pos] = zone_type
	zone_placed.emit(zone_type, pos)
	return true


func remove_zone(pos: Vector2i) -> void:
	var map: MapData = GameState.get_map() if GameState else null
	if map and map.in_bounds(pos.x, pos.y):
		var cell := map.get_cell(pos.x, pos.y)
		if cell:
			cell.zone = ""
	var old_type: String = zones.get(pos, "")
	zones.erase(pos)
	for group: Dictionary in zone_groups:
		var cells: Array = group.get("cells", [])
		cells.erase(pos)
	zone_removed.emit(pos)


func place_zone_rect(zone_type: String, from: Vector2i, to: Vector2i) -> int:
	var count: int = 0
	var x_min: int = mini(from.x, to.x)
	var x_max: int = maxi(from.x, to.x)
	var y_min: int = mini(from.y, to.y)
	var y_max: int = maxi(from.y, to.y)
	for y: int in range(y_min, y_max + 1):
		for x: int in range(x_min, x_max + 1):
			if place_zone(zone_type, Vector2i(x, y)):
				count += 1
	return count


func clear_zone_rect(from: Vector2i, to: Vector2i) -> int:
	var count: int = 0
	var x_min: int = mini(from.x, to.x)
	var x_max: int = maxi(from.x, to.x)
	var y_min: int = mini(from.y, to.y)
	var y_max: int = maxi(from.y, to.y)
	for y: int in range(y_min, y_max + 1):
		for x: int in range(x_min, x_max + 1):
			var pos := Vector2i(x, y)
			if zones.has(pos):
				remove_zone(pos)
				count += 1
	return count


func create_zone_group(zone_type: String, name_hint: String = "") -> Dictionary:
	var gname: String = name_hint if name_hint != "" else "%s %d" % [zone_type, _next_group_id]
	var group := {
		"id": _next_group_id,
		"name": gname,
		"type": zone_type,
		"priority": 1,
		"filter": [],
		"cells": [],
	}
	_next_group_id += 1
	zone_groups.append(group)
	zone_group_created.emit(gname)
	return group


func set_group_priority(group_id: int, priority: int) -> void:
	for group: Dictionary in zone_groups:
		if group.get("id", -1) == group_id:
			group["priority"] = clampi(priority, 1, 4)
			return


func set_group_filter(group_id: int, allowed_defs: Array) -> void:
	for group: Dictionary in zone_groups:
		if group.get("id", -1) == group_id:
			group["filter"] = allowed_defs
			return


func get_zone_cells(zone_type: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pos: Vector2i in zones:
		if zones[pos] == zone_type:
			result.append(pos)
	return result


func get_zone_at(pos: Vector2i) -> String:
	return zones.get(pos, "")


func get_zone_color(zone_type: String) -> Color:
	return ZONE_COLORS.get(zone_type, Color(0.5, 0.5, 0.5, 0.2))


func get_largest_zone_type() -> String:
	var counts: Dictionary = {}
	for pos: Vector2i in zones:
		var zt: String = zones[pos]
		counts[zt] = counts.get(zt, 0) + 1
	var best: String = ""
	var best_c: int = 0
	for zt: String in counts:
		if counts[zt] > best_c:
			best_c = counts[zt]
			best = zt
	return best


func get_growing_zone_count() -> int:
	var cnt: int = 0
	for pos: Vector2i in zones:
		if zones[pos] == "GrowingZone":
			cnt += 1
	return cnt


func get_high_priority_groups() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for group: Dictionary in zone_groups:
		if group.get("priority", 1) >= 3:
			result.append(group)
	return result


func get_unique_zone_type_count() -> int:
	var types: Dictionary = {}
	for pos: Vector2i in zones:
		types[zones[pos]] = true
	return types.size()

func get_avg_cells_per_group() -> float:
	if zone_groups.is_empty():
		return 0.0
	return snappedf(float(zones.size()) / float(zone_groups.size()), 0.01)

func get_stockpile_cell_count() -> int:
	var count: int = 0
	for pos: Vector2i in zones:
		if zones[pos] == "Stockpile":
			count += 1
	return count

func get_empty_group_count() -> int:
	var count: int = 0
	for g: Dictionary in zone_groups:
		if g.get("cells", []).is_empty():
			count += 1
	return count


func get_zone_coverage_pct() -> float:
	var map: MapData = GameState.get_map() if GameState else null
	if map == null or map.width * map.height <= 0:
		return 0.0
	return snappedf(float(zones.size()) / float(map.width * map.height) * 100.0, 0.01)


func get_animal_zone_cell_count() -> int:
	var count: int = 0
	for pos: Vector2i in zones:
		if zones[pos] == "AnimalArea":
			count += 1
	return count


func get_zone_utilization_score() -> float:
	if zone_groups.is_empty():
		return 0.0
	var empty := get_empty_group_count()
	var used := zone_groups.size() - empty
	var fill_ratio := float(used) / float(zone_groups.size())
	var density := minf(1.0, get_avg_cells_per_group() / 50.0)
	return snapped((fill_ratio * 0.6 + density * 0.4) * 100.0, 0.1)

func get_zone_diversity_index() -> float:
	if zones.is_empty():
		return 0.0
	var counts: Dictionary = {}
	for pos: Vector2i in zones:
		var zt: String = zones[pos]
		counts[zt] = counts.get(zt, 0) + 1
	var total := float(zones.size())
	var entropy := 0.0
	for zt: String in counts:
		var p := float(counts[zt]) / total
		if p > 0.0:
			entropy -= p * log(p) / log(2.0)
	var max_entropy := log(float(maxi(counts.size(), 1))) / log(2.0)
	if max_entropy <= 0.0:
		return 100.0
	return snapped(entropy / max_entropy * 100.0, 0.1)

func get_expansion_potential() -> float:
	var map: MapData = GameState.get_map() if GameState else null
	if map == null or map.width * map.height <= 0:
		return 0.0
	var total_cells := float(map.width * map.height)
	var zoned := float(zones.size())
	return snapped((total_cells - zoned) / total_cells * 100.0, 0.1)

func get_summary() -> Dictionary:
	var counts: Dictionary = {}
	for pos: Vector2i in zones:
		var zt: String = zones[pos]
		counts[zt] = counts.get(zt, 0) + 1
	return {
		"zone_counts": counts,
		"total_cells": zones.size(),
		"groups": zone_groups.size(),
		"unique_types": get_unique_zone_type_count(),
		"avg_cells_per_group": get_avg_cells_per_group(),
		"stockpile_cells": get_stockpile_cell_count(),
		"empty_groups": get_empty_group_count(),
		"coverage_pct": get_zone_coverage_pct(),
		"animal_cells": get_animal_zone_cell_count(),
		"utilization_score": get_zone_utilization_score(),
		"diversity_index": get_zone_diversity_index(),
		"expansion_potential": get_expansion_potential(),
		"zone_efficiency_rating": get_zone_efficiency_rating(),
		"storage_pressure_pct": get_storage_pressure(),
		"territorial_optimization": get_territorial_optimization(),
	}

func get_zone_efficiency_rating() -> String:
	var util := get_zone_utilization_score()
	var empty := get_empty_group_count()
	if util >= 80.0 and empty == 0:
		return "Optimal"
	elif util >= 50.0:
		return "Adequate"
	elif util > 0.0:
		return "Underused"
	return "Empty"

func get_storage_pressure() -> float:
	var stockpile := get_stockpile_cell_count()
	var total := zones.size()
	if total <= 0:
		return 0.0
	return snappedf(float(stockpile) / float(total) * 100.0, 0.1)

func get_territorial_optimization() -> float:
	var coverage := get_zone_coverage_pct()
	var diversity := get_zone_diversity_index()
	return snapped(coverage * diversity / 100.0, 0.1)
