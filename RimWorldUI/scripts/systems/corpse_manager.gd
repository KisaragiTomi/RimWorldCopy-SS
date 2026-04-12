extends Node

## Manages corpses and death effects.
## When a pawn dies, spawns a corpse item and applies mood thoughts.
## Registered as autoload "CorpseManager".

var corpses: Array[Dictionary] = []
var total_colonist_deaths: int = 0
var total_enemy_deaths: int = 0
var total_animal_deaths: int = 0

const DECOMPOSE_TICKS: int = 90000  # ~15 in-game days
const ROT_TICKS: int = 15000        # ~2.5 days to start rotting


func _ready() -> void:
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			_watch_pawn(p)
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func _watch_pawn(p: Pawn) -> void:
	if p.health and not p.health.pawn_died.is_connected(_on_pawn_died):
		p.health.pawn_died.connect(_on_pawn_died)


func on_pawn_added(p: Pawn) -> void:
	_watch_pawn(p)


func _on_rare_tick(_tick: int) -> void:
	_update_corpse_states()


func _update_corpse_states() -> void:
	var now: int = TickManager.current_tick if TickManager else 0
	for i: int in range(corpses.size() - 1, -1, -1):
		var c: Dictionary = corpses[i]
		var age: int = now - c.get("tick_created", 0)
		if age >= DECOMPOSE_TICKS and not c.get("decomposed", false):
			c["decomposed"] = true
			c["state"] = "Dessicated"
		elif age >= ROT_TICKS and not c.get("rotting", false):
			c["rotting"] = true
			c["state"] = "Rotting"
			_apply_rotting_thoughts(c)


func _apply_rotting_thoughts(c: Dictionary) -> void:
	if not PawnManager:
		return
	var cx: int = c.get("pos", [0, 0])[0]
	var cy: int = c.get("pos", [0, 0])[1]
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var dist: int = absi(p.grid_pos.x - cx) + absi(p.grid_pos.y - cy)
		if dist < 10 and p.thought_tracker:
			p.thought_tracker.add_thought("ObservedCorpse")


func _on_pawn_died(pawn_id: int) -> void:
	var dead_pawn: Pawn = null
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.id == pawn_id:
				dead_pawn = p
				break
	if dead_pawn == null:
		return

	var is_colonist: bool = not (dead_pawn.has_meta("faction") and dead_pawn.get_meta("faction") == "enemy")
	var faction_str: String = dead_pawn.get_meta("faction") if dead_pawn.has_meta("faction") else "colony"

	if is_colonist:
		total_colonist_deaths += 1
	else:
		total_enemy_deaths += 1

	var cause_of_death: String = "Unknown"
	if dead_pawn.health:
		var worst := dead_pawn.health.get_worst_hediff()
		if not worst.is_empty():
			cause_of_death = worst.get("name", "Unknown")

	corpses.append({
		"name": dead_pawn.pawn_name,
		"pos": [dead_pawn.grid_pos.x, dead_pawn.grid_pos.y],
		"faction": faction_str,
		"tick_created": TickManager.current_tick if TickManager else 0,
		"cause": cause_of_death,
		"state": "Fresh",
		"rotting": false,
		"decomposed": false,
		"buried": false,
	})

	if ThingManager:
		var corpse_item := Item.new("Corpse", 1)
		corpse_item.grid_pos = dead_pawn.grid_pos
		ThingManager.spawn_thing(corpse_item, dead_pawn.grid_pos)

	if is_colonist and PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.dead or p.id == pawn_id:
				continue
			if p.thought_tracker:
				p.thought_tracker.add_thought("ColonistDied")
			var dist: int = absi(p.grid_pos.x - dead_pawn.grid_pos.x) + absi(p.grid_pos.y - dead_pawn.grid_pos.y)
			if dist < 15 and p.thought_tracker:
				p.thought_tracker.add_thought("WitnessedDeath")

	if ColonyLog:
		var severity: String = "danger" if is_colonist else "info"
		ColonyLog.add_entry("Death", "%s has died. Cause: %s" % [dead_pawn.pawn_name, cause_of_death], severity)


func mark_buried(corpse_name: String) -> bool:
	for c: Dictionary in corpses:
		if c.get("name", "") == corpse_name and not c.get("buried", false):
			c["buried"] = true
			if ColonyLog:
				ColonyLog.add_entry("Burial", corpse_name + " has been buried.", "info")
			return true
	return false


func get_unburied() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for c: Dictionary in corpses:
		if not c.get("buried", false) and not c.get("decomposed", false):
			result.append(c)
	return result


func get_rotting_count() -> int:
	var count: int = 0
	for c: Dictionary in corpses:
		if c.get("rotting", false) and not c.get("buried", false):
			count += 1
	return count


func on_animal_died(animal_name: String, pos: Vector2i) -> void:
	total_animal_deaths += 1
	corpses.append({
		"name": animal_name,
		"pos": [pos.x, pos.y],
		"faction": "animal",
		"tick_created": TickManager.current_tick if TickManager else 0,
		"cause": "Slaughtered",
		"state": "Fresh",
		"rotting": false,
		"decomposed": false,
		"buried": false,
	})
	if ThingManager:
		var c_item := Item.new("AnimalCorpse", 1)
		c_item.grid_pos = pos
		ThingManager.spawn_thing(c_item, pos)


func get_colonist_corpses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for c: Dictionary in corpses:
		if c.get("faction", "") == "colony":
			result.append(c)
	return result


func get_most_common_cause() -> String:
	var causes: Dictionary = {}
	for c: Dictionary in corpses:
		var cause: String = c.get("cause", "Unknown")
		causes[cause] = causes.get(cause, 0) + 1
	var best: String = "Unknown"
	var best_c: int = 0
	for cause: String in causes:
		if causes[cause] > best_c:
			best_c = causes[cause]
			best = cause
	return best


func get_fresh_corpse_count() -> int:
	var cnt: int = 0
	for c: Dictionary in corpses:
		if c.get("state", "") == "Fresh" and not c.get("buried", false):
			cnt += 1
	return cnt


func get_enemy_kill_ratio() -> float:
	var total: int = total_colonist_deaths + total_enemy_deaths + total_animal_deaths
	if total == 0:
		return 0.0
	return float(total_enemy_deaths) / float(total)


func get_burial_rate() -> float:
	if corpses.is_empty():
		return 0.0
	var buried: int = 0
	for c: Dictionary in corpses:
		if c.get("buried", false):
			buried += 1
	return float(buried) / float(corpses.size()) * 100.0


func get_colony_corpse_count() -> int:
	var cnt: int = 0
	for c: Dictionary in corpses:
		if c.get("faction", "") == "colony":
			cnt += 1
	return cnt


func get_total_death_count() -> int:
	return total_colonist_deaths + total_enemy_deaths + total_animal_deaths


func get_death_ratio_enemy_vs_colony() -> float:
	if total_colonist_deaths <= 0:
		return 0.0
	return snappedf(float(total_enemy_deaths) / float(total_colonist_deaths), 0.01)


func get_unburied_pct() -> float:
	if corpses.is_empty():
		return 0.0
	return snappedf(float(get_unburied().size()) / float(corpses.size()) * 100.0, 0.1)


func get_sanitation_score() -> float:
	var total := corpses.size()
	if total <= 0:
		return 100.0
	var unburied := float(get_unburied().size())
	var rotting := float(get_rotting_count())
	var penalty := (unburied * 2.0 + rotting * 3.0) / float(total)
	return snapped(maxf(100.0 - penalty * 20.0, 0.0), 0.1)

func get_mortality_trend() -> String:
	var total := get_total_death_count()
	var colony := total_colonist_deaths
	if total <= 0:
		return "Peaceful"
	var ratio := float(colony) / float(total)
	if ratio > 0.5:
		return "Heavy Losses"
	elif ratio > 0.2:
		return "Moderate Losses"
	elif colony > 0:
		return "Light Losses"
	return "Dominating"

func get_disposal_urgency() -> String:
	var unburied := get_unburied().size()
	var rotting := get_rotting_count()
	if rotting > 3:
		return "Critical"
	elif unburied > 5:
		return "High"
	elif unburied > 0:
		return "Normal"
	return "Clear"

func get_summary() -> Dictionary:
	return {
		"total_corpses": corpses.size(),
		"unburied": get_unburied().size(),
		"rotting": get_rotting_count(),
		"colonist_deaths": total_colonist_deaths,
		"enemy_deaths": total_enemy_deaths,
		"animal_deaths": total_animal_deaths,
		"common_cause": get_most_common_cause(),
		"fresh": get_fresh_corpse_count(),
		"enemy_ratio": snappedf(get_enemy_kill_ratio(), 0.01),
		"burial_rate_pct": snappedf(get_burial_rate(), 0.1),
		"colony_corpses": get_colony_corpse_count(),
		"total_deaths": get_total_death_count(),
		"enemy_colony_ratio": get_death_ratio_enemy_vs_colony(),
		"unburied_pct": get_unburied_pct(),
		"sanitation_score": get_sanitation_score(),
		"mortality_trend": get_mortality_trend(),
		"disposal_urgency": get_disposal_urgency(),
		"biological_decay_index": get_biological_decay_index(),
		"death_response_efficiency": get_death_response_efficiency(),
		"colony_mortality_resilience": get_colony_mortality_resilience(),
	}

func get_biological_decay_index() -> float:
	if corpses.is_empty():
		return 0.0
	var rot_count: int = get_rotting_count()
	var fresh_count: int = get_fresh_corpse_count()
	var total: int = corpses.size()
	var rot_ratio: float = float(rot_count) / float(total) if total > 0 else 0.0
	var fresh_ratio: float = float(fresh_count) / float(total) if total > 0 else 0.0
	return snappedf(rot_ratio * 70.0 + (1.0 - fresh_ratio) * 30.0, 0.1)

func get_death_response_efficiency() -> String:
	var unburied_pct: float = get_unburied_pct()
	var burial: float = get_burial_rate()
	var score: float = burial * 0.6 + (100.0 - unburied_pct) * 0.4
	if score >= 80.0:
		return "Excellent"
	if score >= 60.0:
		return "Good"
	if score >= 40.0:
		return "Adequate"
	return "Poor"

func get_colony_mortality_resilience() -> String:
	var deaths: int = get_total_death_count()
	var enemy_ratio: float = get_enemy_kill_ratio()
	if deaths == 0:
		return "Untested"
	if enemy_ratio >= 2.0 and total_colonist_deaths <= 2:
		return "Resilient"
	if enemy_ratio >= 1.0:
		return "Stable"
	return "Vulnerable"
