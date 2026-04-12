extends Node

## Manages traps: deadfall, spike, and IED traps that trigger when enemies
## step on them. Traps can be reset by colonists.
## Registered as autoload "TrapManager".

const TRAP_DEFS: Dictionary = {
	"DeadfallTrap": {
		"label": "Deadfall trap",
		"damage": 50,
		"damage_type": "Blunt",
		"rearmable": true,
		"rearm_work": 120,
		"build_cost": {"Wood": 5},
		"color": [0.45, 0.38, 0.30],
	},
	"SpikeTrap": {
		"label": "Spike trap",
		"damage": 70,
		"damage_type": "Stab",
		"rearmable": true,
		"rearm_work": 150,
		"build_cost": {"Steel": 3},
		"color": [0.55, 0.55, 0.58],
	},
	"IEDTrap": {
		"label": "IED trap",
		"damage": 120,
		"damage_type": "Bomb",
		"rearmable": false,
		"rearm_work": 0,
		"build_cost": {"Steel": 2, "Component": 1},
		"color": [0.70, 0.35, 0.25],
	},
}

var _traps: Dictionary = {}  # Vector2i -> {def_name, armed, building_id}
var _total_triggered: int = 0
var _total_kills: int = 0
var _total_damage_dealt: int = 0
var _triggers_by_type: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 73
	if TickManager:
		TickManager.tick.connect(_on_tick)


func place_trap(pos: Vector2i, def_name: String, building_id: int) -> bool:
	if not TRAP_DEFS.has(def_name):
		return false
	if _traps.has(pos):
		return false
	_traps[pos] = {"def_name": def_name, "armed": true, "building_id": building_id}
	return true


func remove_trap(pos: Vector2i) -> void:
	_traps.erase(pos)


func is_trap(pos: Vector2i) -> bool:
	return _traps.has(pos)


func is_armed(pos: Vector2i) -> bool:
	if not _traps.has(pos):
		return false
	return _traps[pos].armed


func rearm_trap(pos: Vector2i) -> bool:
	if not _traps.has(pos):
		return false
	var def_name: String = _traps[pos].def_name
	if not TRAP_DEFS[def_name].get("rearmable", false):
		return false
	_traps[pos].armed = true
	return true


func _on_tick(_tick: int) -> void:
	_check_triggers()


func _check_triggers() -> void:
	if not PawnManager:
		return

	for pos: Vector2i in _traps:
		if not _traps[pos].armed:
			continue

		for p: Pawn in PawnManager.pawns:
			if p.dead:
				continue
			if not p.has_meta("faction"):
				continue
			if p.get_meta("faction") != "enemy":
				continue
			if p.grid_pos == pos:
				_trigger(pos, p)
				break


func _trigger(pos: Vector2i, target: Pawn) -> void:
	var trap: Dictionary = _traps[pos]
	var def: Dictionary = TRAP_DEFS.get(trap.def_name, {})

	var damage: int = def.get("damage", 30)
	var dmg_type: String = def.get("damage_type", "Blunt")

	var parts := ["Torso", "LeftLeg", "RightLeg", "Head"]
	var hit_part: String = parts[_rng.randi_range(0, parts.size() - 1)]

	if target.health:
		target.health.add_injury(hit_part, float(damage), dmg_type)

	trap.armed = false
	_total_triggered += 1
	_total_damage_dealt += damage
	_triggers_by_type[trap.def_name] = _triggers_by_type.get(trap.def_name, 0) + 1

	if target.health and target.health.is_dead:
		_total_kills += 1

	if not def.get("rearmable", false):
		_traps.erase(pos)

	if ColonyLog:
		ColonyLog.add_entry("Combat", def.get("label", "Trap") + " triggered on " + target.pawn_name + "! (" + str(damage) + " " + dmg_type + " to " + hit_part + ")", "positive")


func get_trap_count() -> int:
	return _traps.size()


func get_armed_count() -> int:
	var count := 0
	for pos: Vector2i in _traps:
		if _traps[pos].armed:
			count += 1
	return count


func get_disarmed_traps() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pos: Vector2i in _traps:
		if not _traps[pos].armed:
			result.append(pos)
	return result


func get_traps_near(center: Vector2i, radius: int = 10) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for pos: Vector2i in _traps:
		var dist: int = absi(pos.x - center.x) + absi(pos.y - center.y)
		if dist <= radius:
			result.append({"pos": pos, "def_name": _traps[pos].def_name, "armed": _traps[pos].armed})
	return result


func get_avg_damage_per_trigger() -> float:
	if _total_triggered == 0:
		return 0.0
	return float(_total_damage_dealt) / float(_total_triggered)


func get_kill_rate() -> float:
	if _total_triggered == 0:
		return 0.0
	return snappedf(float(_total_kills) / float(_total_triggered), 0.01)


func get_most_effective_trap() -> String:
	var best: String = ""
	var best_triggers: int = 0
	for t: String in _triggers_by_type:
		if _triggers_by_type[t] > best_triggers:
			best_triggers = _triggers_by_type[t]
			best = t
	return best


func get_readiness_percentage() -> float:
	if _traps.is_empty():
		return 0.0
	return snappedf(float(get_armed_count()) / float(_traps.size()) * 100.0, 0.1)


func get_defense_rating() -> String:
	var ready: float = get_readiness_percentage()
	if ready >= 90.0:
		return "Strong"
	elif ready >= 60.0:
		return "Moderate"
	elif ready > 0.0:
		return "Weak"
	return "None"

func get_maintenance_needed() -> int:
	return get_disarmed_traps().size()

func get_lethality_pct() -> float:
	if _total_triggered <= 0:
		return 0.0
	return snappedf(float(_total_kills) / float(_total_triggered) * 100.0, 0.1)

func get_perimeter_coverage() -> String:
	var ready := get_readiness_percentage()
	var total := _traps.size()
	if total >= 10 and ready >= 80.0:
		return "Comprehensive"
	elif total >= 5:
		return "Partial"
	elif total > 0:
		return "Minimal"
	return "None"

func get_deterrent_effectiveness() -> float:
	if _total_triggered <= 0:
		return 0.0
	var kill_rate := get_kill_rate()
	var avg_dmg := get_avg_damage_per_trigger()
	return snapped(kill_rate * 50.0 + avg_dmg * 0.5, 0.1)

func get_trap_roi() -> String:
	var kills := _total_kills
	var traps := _traps.size()
	if traps <= 0:
		return "N/A"
	var ratio := float(kills) / float(traps)
	if ratio >= 2.0:
		return "Excellent"
	elif ratio >= 1.0:
		return "Good"
	elif ratio > 0.0:
		return "Low"
	return "None"

func get_summary() -> Dictionary:
	var by_type: Dictionary = {}
	for pos: Vector2i in _traps:
		var d: String = _traps[pos].def_name
		by_type[d] = by_type.get(d, 0) + 1
	return {
		"total_traps": _traps.size(),
		"armed": get_armed_count(),
		"disarmed": get_disarmed_traps().size(),
		"total_triggered": _total_triggered,
		"total_kills": _total_kills,
		"total_damage": _total_damage_dealt,
		"avg_damage": snappedf(get_avg_damage_per_trigger(), 0.1),
		"triggers_by_type": _triggers_by_type.duplicate(),
		"by_type": by_type,
		"kill_rate": get_kill_rate(),
		"most_effective": get_most_effective_trap(),
		"readiness_pct": get_readiness_percentage(),
		"unique_types": by_type.size(),
		"damage_per_kill": snappedf(float(_total_damage_dealt) / maxf(float(_total_kills), 1.0), 0.1),
		"defense_rating": get_defense_rating(),
		"maintenance_needed": get_maintenance_needed(),
		"lethality_pct": get_lethality_pct(),
		"perimeter_coverage": get_perimeter_coverage(),
		"deterrent_effectiveness": get_deterrent_effectiveness(),
		"trap_roi": get_trap_roi(),
		"defense_network_maturity": get_defense_network_maturity(),
		"kill_zone_efficiency": get_kill_zone_efficiency(),
		"passive_defense_score": get_passive_defense_score(),
	}

func get_defense_network_maturity() -> String:
	var total: int = _traps.size()
	var types: int = _triggers_by_type.size()
	var kills: int = _total_kills
	if total >= 15 and types >= 3 and kills >= 10:
		return "Veteran"
	if total >= 8:
		return "Established"
	if total >= 3:
		return "Basic"
	return "Minimal"

func get_kill_zone_efficiency() -> float:
	var kill_rate: float = get_kill_rate()
	var lethality: float = get_lethality_pct()
	return snappedf((kill_rate * 50.0 + lethality * 0.5), 0.1)

func get_passive_defense_score() -> float:
	var readiness: float = get_readiness_percentage()
	var roi: String = get_trap_roi()
	var roi_val: float = 80.0 if roi == "Excellent" else (60.0 if roi == "Good" else (40.0 if roi == "Fair" else 20.0))
	return snappedf(clampf(readiness * 0.5 + roi_val * 0.5, 0.0, 100.0), 0.1)
