extends Node

## Calculates cover bonuses during ranged combat. Walls and sandbags between
## shooter and target reduce hit chance. Registered as autoload "CoverSystem".

const COVER_DEFS: Dictionary = {
	"Wall": {"cover": 0.75, "passable": false, "destructible": true, "hp": 300},
	"Sandbag": {"cover": 0.55, "passable": true, "destructible": true, "hp": 100},
	"Barricade": {"cover": 0.50, "passable": true, "destructible": true, "hp": 200},
	"Chunk": {"cover": 0.35, "passable": true, "destructible": false, "hp": 0},
	"Tree": {"cover": 0.25, "passable": true, "destructible": true, "hp": 150},
	"Door": {"cover": 0.40, "passable": true, "destructible": true, "hp": 200},
}

var _cover_queries: int = 0
var _total_cover_applied: float = 0.0


func get_cover_bonus(shooter_pos: Vector2i, target_pos: Vector2i) -> float:
	if not ThingManager:
		return 0.0

	_cover_queries += 1
	var best_cover: float = 0.0
	var adjacent_positions := _get_adjacent(target_pos)

	for adj: Vector2i in adjacent_positions:
		if not _is_between(adj, shooter_pos, target_pos):
			continue
		var cover := _get_cover_at(adj)
		best_cover = maxf(best_cover, cover)

	_total_cover_applied += best_cover
	return best_cover


func get_hit_chance_modifier(shooter_pos: Vector2i, target_pos: Vector2i) -> float:
	var cover := get_cover_bonus(shooter_pos, target_pos)
	return 1.0 - cover


func _get_cover_at(pos: Vector2i) -> float:
	if not ThingManager:
		return 0.0
	for t: Thing in ThingManager.things:
		if t.grid_pos == pos and t is Building:
			return COVER_DEFS.get(t.def_name, {}).get("cover", 0.0)
	var map: MapData = GameState.get_map() if GameState else null
	if map:
		var cell := map.get_cell(pos.x, pos.y)
		if cell and cell.is_mountain:
			return 0.80
	return 0.0


func _is_between(point: Vector2i, a: Vector2i, b: Vector2i) -> bool:
	var dx := b.x - a.x
	var dy := b.y - a.y
	var px := point.x - a.x
	var py := point.y - a.y

	if dx == 0 and dy == 0:
		return false

	var dot: float = float(px * dx + py * dy)
	var len_sq: float = float(dx * dx + dy * dy)
	var t: float = dot / len_sq

	if t < 0.5 or t > 1.0:
		return false

	var proj_x: float = float(a.x) + t * float(dx)
	var proj_y: float = float(a.y) + t * float(dy)
	var dist: float = sqrt((float(point.x) - proj_x) ** 2 + (float(point.y) - proj_y) ** 2)

	return dist < 1.5


func _get_adjacent(pos: Vector2i) -> Array[Vector2i]:
	return [
		pos + Vector2i(1, 0),
		pos + Vector2i(-1, 0),
		pos + Vector2i(0, 1),
		pos + Vector2i(0, -1),
		pos + Vector2i(1, 1),
		pos + Vector2i(-1, -1),
		pos + Vector2i(1, -1),
		pos + Vector2i(-1, 1),
	]


func find_best_cover_near(pos: Vector2i, against: Vector2i, radius: int = 5) -> Vector2i:
	var best_pos: Vector2i = pos
	var best_val: float = 0.0
	for dx: int in range(-radius, radius + 1):
		for dy: int in range(-radius, radius + 1):
			var check := Vector2i(pos.x + dx, pos.y + dy)
			var cv := _get_cover_at(check)
			if cv > best_val and _is_between(check, against, pos):
				best_val = cv
				best_pos = check
	return best_pos


func get_cover_at_pos(pos: Vector2i) -> float:
	return _get_cover_at(pos)


func get_avg_cover_applied() -> float:
	if _cover_queries == 0:
		return 0.0
	return snappedf(_total_cover_applied / float(_cover_queries), 0.01)


func get_best_cover_type() -> String:
	var best: String = ""
	var best_val: float = 0.0
	for ctype: String in COVER_DEFS:
		if COVER_DEFS[ctype].get("cover", 0.0) > best_val:
			best_val = COVER_DEFS[ctype].get("cover", 0.0)
			best = ctype
	return best


func get_passable_covers() -> Array[String]:
	var result: Array[String] = []
	for ctype: String in COVER_DEFS:
		if COVER_DEFS[ctype].get("passable", false):
			result.append(ctype)
	return result


func get_cover_effectiveness() -> float:
	if _cover_queries == 0:
		return 0.0
	return snappedf(1.0 - get_avg_cover_applied(), 0.01)


func get_defense_quality() -> String:
	var eff: float = get_cover_effectiveness()
	if eff >= 70.0:
		return "Excellent"
	elif eff >= 40.0:
		return "Adequate"
	elif eff > 0.0:
		return "Minimal"
	return "None"

func get_passable_ratio() -> float:
	if COVER_DEFS.is_empty():
		return 0.0
	return snappedf(float(get_passable_covers().size()) / float(COVER_DEFS.size()) * 100.0, 0.1)

func get_tactical_score() -> float:
	var eff: float = get_cover_effectiveness()
	var pass_ratio: float = get_passable_ratio()
	return snappedf((eff * 0.7 + pass_ratio * 0.3), 0.1)

func get_battlefield_readiness() -> String:
	var quality := get_defense_quality()
	var tactical := get_tactical_score()
	if quality == "Excellent" and tactical >= 60.0:
		return "Battle Ready"
	elif quality == "Adequate":
		return "Defensible"
	return "Exposed"

func get_cover_gap_analysis() -> float:
	var passable := get_passable_covers().size()
	var total := COVER_DEFS.size()
	if total <= 0:
		return 0.0
	return snapped((1.0 - float(passable) / float(total)) * 100.0, 0.1)

func get_positional_advantage() -> String:
	var avg := get_avg_cover_applied()
	if avg >= 60:
		return "Superior"
	elif avg >= 30:
		return "Moderate"
	return "Minimal"

func get_summary() -> Dictionary:
	return {
		"cover_types": COVER_DEFS.size(),
		"available_covers": COVER_DEFS.keys(),
		"total_queries": _cover_queries,
		"avg_cover": get_avg_cover_applied(),
		"best_cover_type": get_best_cover_type(),
		"passable_covers": get_passable_covers().size(),
		"effectiveness": get_cover_effectiveness(),
		"avg_block_chance": snappedf(float(get_avg_cover_applied()) / 100.0, 0.01),
		"queries_per_type": snappedf(float(_cover_queries) / maxf(float(COVER_DEFS.size()), 1.0), 0.1),
		"defense_quality": get_defense_quality(),
		"passable_ratio_pct": get_passable_ratio(),
		"tactical_score": get_tactical_score(),
		"battlefield_readiness": get_battlefield_readiness(),
		"cover_gap_pct": get_cover_gap_analysis(),
		"positional_advantage": get_positional_advantage(),
		"fortification_index": get_fortification_index(),
		"survivability_multiplier": get_survivability_multiplier(),
		"tactical_superiority": get_tactical_superiority(),
	}

func get_fortification_index() -> float:
	var best := get_best_cover_type()
	var best_val: float = 0.0
	if COVER_DEFS.has(best):
		best_val = float(COVER_DEFS[best].get("block_chance", 0))
	var types := COVER_DEFS.size()
	return snapped(best_val * float(types) / 10.0, 0.01)

func get_survivability_multiplier() -> float:
	var avg := get_avg_cover_applied()
	if avg <= 0:
		return 1.0
	return snapped(1.0 + float(avg) / 100.0, 0.01)

func get_tactical_superiority() -> String:
	var quality := get_defense_quality()
	var advantage := get_positional_advantage()
	if quality in ["Excellent", "Fortified"] and advantage in ["Dominant", "Strong"]:
		return "Total"
	elif quality in ["Good", "Excellent"]:
		return "Partial"
	return "Contested"
