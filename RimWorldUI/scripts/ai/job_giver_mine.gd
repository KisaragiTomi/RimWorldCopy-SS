class_name JobGiverMine
extends ThinkNode

## Issues a Mine job when there are designated mining targets.
## Prefers ore veins, avoids collapse-prone deep cells.

const SEARCH_RADIUS := 40
const ORE_TYPES := ["Steel", "Gold", "Silver", "Plasteel", "Uranium", "Jade", "Compacted"]


func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.drafted or pawn.dead or pawn.downed:
		return {}
	if not pawn.is_capable_of("Mining"):
		return {}

	var map: MapData = GameState.get_map() if GameState else null
	if map == null:
		return {}

	var best_pos := Vector2i(-1, -1)
	var best_score: float = -1.0

	for dy: int in range(-SEARCH_RADIUS, SEARCH_RADIUS + 1):
		for dx: int in range(-SEARCH_RADIUS, SEARCH_RADIUS + 1):
			var cx: int = pawn.grid_pos.x + dx
			var cy: int = pawn.grid_pos.y + dy
			if not map.in_bounds(cx, cy):
				continue
			var cell := map.get_cell(cx, cy)
			if cell == null or not cell.is_mountain:
				continue
			if cell.zone != "mine":
				continue
			var dist: int = absi(dx) + absi(dy)
			var score: float = _score_cell(cell, dist)
			if score > best_score:
				best_score = score
				best_pos = Vector2i(cx, cy)

	if best_pos.x < 0:
		return {}

	var job := Job.new()
	job.job_def = "Mine"
	job.target_pos = best_pos
	return {"job": job}


func get_minable_count() -> int:
	var map: MapData = GameState.get_map() if GameState else null
	if map == null:
		return 0
	var cnt: int = 0
	for y: int in range(map.height):
		for x: int in range(map.width):
			var cell := map.get_cell(x, y)
			if cell and cell.is_mountain and cell.zone == "mine":
				cnt += 1
	return cnt


func get_ore_distribution() -> Dictionary:
	var map: MapData = GameState.get_map() if GameState else null
	if map == null:
		return {}
	var dist: Dictionary = {}
	for y: int in range(map.height):
		for x: int in range(map.width):
			var cell := map.get_cell(x, y)
			if cell and cell.is_mountain and cell.zone == "mine":
				var ore: String = cell.ore if not cell.ore.is_empty() else "Rock"
				dist[ore] = dist.get(ore, 0) + 1
	return dist


func get_most_valuable_ore() -> String:
	var ore_dist: Dictionary = get_ore_distribution()
	var priority := ["Uranium", "Gold", "Jade", "Plasteel", "Silver", "Steel"]
	for p: String in priority:
		if ore_dist.has(p):
			return p
	return "Rock"


func _score_cell(cell: Cell, dist: int) -> float:
	var score: float = 100.0 - float(dist)
	var ore_name: String = cell.ore
	if ore_name.is_empty():
		ore_name = cell.terrain_def
	for ore: String in ORE_TYPES:
		if ore_name.contains(ore):
			score += 30.0
			break
	return score

func get_ore_type_count() -> int:
	return ORE_TYPES.size()

func get_total_ore_deposits() -> int:
	var dist: Dictionary = get_ore_distribution()
	var total: int = 0
	for k: String in dist:
		total += dist[k]
	return total

func get_avg_deposit_per_type() -> float:
	var types: int = get_ore_type_count()
	if types <= 0:
		return 0.0
	return snappedf(float(get_total_ore_deposits()) / float(types), 0.01)


func get_rare_ore_count() -> int:
	var dist: Dictionary = get_ore_distribution()
	var count: int = 0
	for ore: String in dist:
		if ore in ["Gold", "Uranium", "Jade"]:
			count += dist[ore]
	return count


func has_valuable_ore() -> bool:
	return get_rare_ore_count() > 0


func get_resource_extraction_score() -> float:
	var deposits := float(get_total_ore_deposits())
	var types := float(get_ore_type_count())
	var rare := float(get_rare_ore_count())
	return snapped((deposits * 0.3 + types * 10.0 + rare * 20.0), 0.1)

func get_mining_sustainability() -> String:
	var deposits := get_total_ore_deposits()
	var types := get_ore_type_count()
	if deposits >= 20 and types >= 3:
		return "Abundant"
	elif deposits >= 10:
		return "Adequate"
	elif deposits >= 3:
		return "Scarce"
	return "Depleted"

func get_strategic_value() -> float:
	var rare := float(get_rare_ore_count())
	var total := float(get_total_ore_deposits())
	if total <= 0.0:
		return 0.0
	return snapped(rare / total * 100.0, 0.1)

func get_mining_summary() -> Dictionary:
	return {
		"minable": get_minable_count(),
		"ore_types": get_ore_type_count(),
		"total_deposits": get_total_ore_deposits(),
		"most_valuable": get_most_valuable_ore(),
		"avg_per_type": get_avg_deposit_per_type(),
		"rare_ore_count": get_rare_ore_count(),
		"has_valuable": has_valuable_ore(),
		"extraction_score": get_resource_extraction_score(),
		"mining_sustainability": get_mining_sustainability(),
		"strategic_value_pct": get_strategic_value(),
		"mining_ecosystem_health": get_mining_ecosystem_health(),
		"resource_governance": get_resource_governance(),
		"extraction_maturity_index": get_extraction_maturity_index(),
	}

func get_mining_ecosystem_health() -> float:
	var score := get_resource_extraction_score()
	var sustain := get_mining_sustainability()
	var s_val: float = 90.0 if sustain == "Abundant" else (60.0 if sustain == "Moderate" else 25.0)
	var strat := get_strategic_value()
	return snapped((minf(score, 100.0) + s_val + minf(strat, 100.0)) / 3.0, 0.1)

func get_resource_governance() -> String:
	var eco := get_mining_ecosystem_health()
	var mat := get_extraction_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_minable_count() > 0:
		return "Nascent"
	return "Dormant"

func get_extraction_maturity_index() -> float:
	var rare := float(get_rare_ore_count())
	var has_val: float = 80.0 if has_valuable_ore() else 20.0
	var deposits := minf(float(get_total_ore_deposits()), 100.0)
	return snapped((rare * 10.0 + has_val + deposits) / 3.0, 0.1)
