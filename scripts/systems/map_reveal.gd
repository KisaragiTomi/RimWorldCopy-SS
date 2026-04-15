extends Node

var _revealed: Dictionary = {}
var _map_width: int = 275
var _map_height: int = 275
var _total_reveals: int = 0
const DEFAULT_VISION_RANGE: int = 12
const ENHANCED_VISION_RANGE: int = 18


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func _on_rare_tick(_tick: int) -> void:
	_update_vision()


func _update_vision() -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed:
			continue
		_reveal_around(p.grid_pos, DEFAULT_VISION_RANGE)


func _reveal_around(center: Vector2i, radius: int) -> void:
	for dx: int in range(-radius, radius + 1):
		for dy: int in range(-radius, radius + 1):
			if dx * dx + dy * dy <= radius * radius:
				var pos: Vector2i = Vector2i(center.x + dx, center.y + dy)
				if pos.x >= 0 and pos.x < _map_width and pos.y >= 0 and pos.y < _map_height:
					if not _revealed.has(pos):
						_total_reveals += 1
					_revealed[pos] = true


func is_revealed(pos: Vector2i) -> bool:
	return _revealed.has(pos)


func get_revealed_count() -> int:
	return _revealed.size()


func get_revealed_percent() -> float:
	var total: int = _map_width * _map_height
	if total == 0:
		return 0.0
	return snappedf(float(_revealed.size()) / float(total) * 100.0, 0.1)


func reveal_all() -> void:
	for x: int in range(_map_width):
		for y: int in range(_map_height):
			_revealed[Vector2i(x, y)] = true


func reveal_area(center: Vector2i, radius: int) -> int:
	var before: int = _revealed.size()
	_reveal_around(center, radius)
	return _revealed.size() - before


func get_unrevealed_adjacent() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for pos: Vector2i in _revealed:
		for d: Vector2i in dirs:
			var neighbor := pos + d
			if not _revealed.has(neighbor) and neighbor.x >= 0 and neighbor.x < _map_width and neighbor.y >= 0 and neighbor.y < _map_height:
				if not result.has(neighbor):
					result.append(neighbor)
				if result.size() >= 50:
					return result
	return result


func get_unrevealed_count() -> int:
	return (_map_width * _map_height) - get_revealed_count()


func get_reveals_per_event() -> float:
	if _total_reveals == 0:
		return 0.0
	return snappedf(float(get_revealed_count()) / float(_total_reveals), 0.1)


func is_fully_revealed() -> bool:
	return get_revealed_count() >= (_map_width * _map_height)


func get_exploration_rating() -> String:
	var pct: float = get_revealed_percent()
	if pct >= 95.0:
		return "Complete"
	elif pct >= 70.0:
		return "Thorough"
	elif pct >= 40.0:
		return "Partial"
	return "Unexplored"

func get_discovery_pace() -> float:
	if _total_reveals <= 0:
		return 0.0
	return snappedf(float(get_revealed_count()) / float(_total_reveals), 0.1)

func get_fog_density() -> String:
	var unrevealed: float = 100.0 - get_revealed_percent()
	if unrevealed <= 5.0:
		return "Clear"
	elif unrevealed <= 30.0:
		return "Light"
	elif unrevealed <= 60.0:
		return "Dense"
	return "Heavy"

func get_summary() -> Dictionary:
	return {
		"revealed_cells": get_revealed_count(),
		"revealed_percent": get_revealed_percent(),
		"map_size": _map_width * _map_height,
		"total_reveals": _total_reveals,
		"frontier_size": get_unrevealed_adjacent().size(),
		"unrevealed": get_unrevealed_count(),
		"cells_per_reveal": get_reveals_per_event(),
		"fully_revealed": is_fully_revealed(),
		"reveal_efficiency": snappedf(float(get_revealed_count()) / maxf(float(_total_reveals), 1.0), 0.1),
		"frontier_pct": snappedf(float(get_unrevealed_adjacent().size()) / maxf(float(get_unrevealed_count()), 1.0) * 100.0, 0.1),
		"exploration_rating": get_exploration_rating(),
		"discovery_pace": get_discovery_pace(),
		"fog_density": get_fog_density(),
		"exploration_completeness": get_exploration_completeness(),
		"discovery_efficiency": get_discovery_efficiency(),
		"information_coverage": get_information_coverage(),
		"cartographic_maturity": get_cartographic_maturity(),
		"reconnaissance_depth": get_reconnaissance_depth(),
		"situational_awareness_score": get_situational_awareness_score(),
	}

func get_cartographic_maturity() -> float:
	var pct := get_revealed_percent()
	var efficiency := float(get_revealed_count()) / maxf(float(_total_reveals), 1.0)
	return snapped(pct * efficiency, 0.1)

func get_reconnaissance_depth() -> float:
	var revealed := float(get_revealed_count())
	var total := float(_map_width * _map_height)
	if total <= 0.0:
		return 0.0
	var frontier := float(get_unrevealed_adjacent().size())
	return snapped((revealed + frontier) / total * 100.0, 0.1)

func get_situational_awareness_score() -> String:
	var completeness := get_exploration_completeness()
	var coverage := get_information_coverage()
	if completeness == "Complete" and coverage == "Full":
		return "Omniscient"
	elif completeness in ["Complete", "Extensive"]:
		return "Informed"
	return "Blind Spots"

func get_exploration_completeness() -> String:
	var pct := get_revealed_percent()
	if pct >= 95.0:
		return "Complete"
	elif pct >= 70.0:
		return "Extensive"
	elif pct >= 40.0:
		return "Partial"
	return "Minimal"

func get_discovery_efficiency() -> float:
	if _total_reveals <= 0:
		return 0.0
	return snapped(float(get_revealed_count()) / float(_total_reveals), 0.1)

func get_information_coverage() -> String:
	var density := get_fog_density()
	if density == "None":
		return "Full"
	elif density in ["None", "Light"]:
		return "High"
	elif density in ["Moderate"]:
		return "Moderate"
	return "Low"
