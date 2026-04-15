extends Node

## Auto-turrets that detect and fire at enemy pawns within range.
## Requires power. Registered as autoload "TurretAI".

const TURRET_DEFS: Dictionary = {
	"MiniTurret": {
		"range": 25,
		"damage": 12,
		"damage_type": "Bullet",
		"fire_interval": 40,
		"accuracy": 0.65,
		"power_draw": 80.0,
	},
	"AutoCannon": {
		"range": 35,
		"damage": 20,
		"damage_type": "Bullet",
		"fire_interval": 60,
		"accuracy": 0.55,
		"power_draw": 150.0,
	},
	"UraniumSlug": {
		"range": 45,
		"damage": 50,
		"damage_type": "Bullet",
		"fire_interval": 120,
		"accuracy": 0.75,
		"power_draw": 200.0,
	},
}

var _turrets: Dictionary = {}  # building_id -> {pos, def_name, fire_cooldown}
var _total_kills: int = 0
var _total_shots: int = 0
var _total_hits: int = 0
var _total_damage: int = 0
var _kills_by_type: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 67
	if TickManager:
		TickManager.tick.connect(_on_tick)


func register_turret(building_id: int, def_name: String, pos: Vector2i) -> void:
	if not TURRET_DEFS.has(def_name):
		return
	_turrets[building_id] = {
		"pos": pos,
		"def_name": def_name,
		"fire_cooldown": 0,
	}


func unregister_turret(building_id: int) -> void:
	_turrets.erase(building_id)


func _on_tick(_tick: int) -> void:
	for tid: int in _turrets:
		var turret: Dictionary = _turrets[tid]
		if turret.fire_cooldown > 0:
			turret.fire_cooldown -= 1
			continue
		_try_fire(tid, turret)


func _try_fire(tid: int, turret: Dictionary) -> void:
	if not PawnManager:
		return

	var def: Dictionary = TURRET_DEFS.get(turret.def_name, {})
	if def.is_empty():
		return

	var has_power := true
	if PowerConsumption:
		has_power = PowerConsumption.has_power(tid)
	if not has_power:
		return

	var best_target: Pawn = null
	var best_dist: float = 999.0
	var turret_pos: Vector2i = turret.pos
	var max_range: float = float(def.range)

	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed:
			continue
		if not p.has_meta("faction") or p.get_meta("faction") != "enemy":
			continue
		var dist: float = float(turret_pos.distance_to(p.grid_pos))
		if dist <= max_range and dist < best_dist:
			best_dist = dist
			best_target = p

	if best_target == null:
		return

	turret.fire_cooldown = def.fire_interval
	_total_shots += 1

	var accuracy: float = def.accuracy
	if _rng.randf() > accuracy:
		return

	_total_hits += 1
	_total_damage += def.damage
	var parts := ["Torso", "Head", "LeftArm", "RightArm", "LeftLeg", "RightLeg"]
	var hit_part: String = parts[_rng.randi_range(0, parts.size() - 1)]
	best_target.health.add_injury(hit_part, float(def.damage), def.damage_type)

	if best_target.health.is_dead:
		_total_kills += 1
		_kills_by_type[turret.def_name] = _kills_by_type.get(turret.def_name, 0) + 1

	if ColonyLog:
		ColonyLog.add_entry("Combat", turret.def_name + " hit " + best_target.pawn_name + " (" + str(def.damage) + " " + def.damage_type + " to " + hit_part + ")", "positive")


func get_accuracy() -> float:
	if _total_shots == 0:
		return 0.0
	return snappedf(float(_total_hits) / float(_total_shots), 0.01)


func get_turrets_by_type() -> Dictionary:
	var result: Dictionary = {}
	for tid: int in _turrets:
		var d: String = _turrets[tid].def_name
		result[d] = result.get(d, 0) + 1
	return result


func get_total_dps() -> float:
	var dps: float = 0.0
	for tid: int in _turrets:
		var def: Dictionary = TURRET_DEFS.get(_turrets[tid].def_name, {})
		if def.is_empty():
			continue
		dps += float(def.damage) * def.accuracy / float(def.fire_interval)
	return snappedf(dps, 0.01)


func get_most_lethal_turret_type() -> String:
	var best: String = ""
	var best_kills: int = 0
	for t: String in _kills_by_type:
		if _kills_by_type[t] > best_kills:
			best_kills = _kills_by_type[t]
			best = t
	return best


func get_avg_damage_per_kill() -> float:
	if _total_kills == 0:
		return 0.0
	return snappedf(float(_total_damage) / float(_total_kills), 0.1)


func get_powered_turret_count() -> int:
	var count: int = 0
	for tid: int in _turrets:
		if not PowerConsumption or PowerConsumption.has_power(tid):
			count += 1
	return count


func get_combat_rating() -> String:
	var acc: float = get_accuracy()
	if acc >= 70.0:
		return "Deadly"
	elif acc >= 40.0:
		return "Effective"
	elif acc > 0.0:
		return "Inaccurate"
	return "Offline"

func get_power_coverage() -> float:
	if _turrets.is_empty():
		return 0.0
	return snappedf(float(get_powered_turret_count()) / float(_turrets.size()) * 100.0, 0.1)

func get_kill_efficiency() -> float:
	if _total_hits <= 0:
		return 0.0
	return snappedf(float(_total_kills) / float(_total_hits) * 100.0, 0.1)

func get_fire_superiority() -> String:
	var dps := get_total_dps()
	var rating := get_combat_rating()
	if dps >= 50.0 and rating == "Deadly":
		return "Dominant"
	elif dps >= 20.0:
		return "Strong"
	elif dps > 0.0:
		return "Moderate"
	return "None"

func get_defense_investment_score() -> float:
	var coverage := get_power_coverage()
	var efficiency := get_kill_efficiency()
	return snapped((coverage * 0.5 + efficiency * 0.5), 0.1)

func get_automated_defense_readiness() -> String:
	var powered := get_powered_turret_count()
	var total := _turrets.size()
	if total <= 0:
		return "None"
	if powered == total:
		return "Fully Operational"
	elif float(powered) / float(total) >= 0.7:
		return "Mostly Ready"
	return "Degraded"

func get_summary() -> Dictionary:
	return {
		"active_turrets": _turrets.size(),
		"by_type": get_turrets_by_type(),
		"total_shots": _total_shots,
		"total_hits": _total_hits,
		"total_kills": _total_kills,
		"total_damage": _total_damage,
		"accuracy": get_accuracy(),
		"total_dps": get_total_dps(),
		"kills_by_type": _kills_by_type.duplicate(),
		"most_lethal": get_most_lethal_turret_type(),
		"avg_dmg_per_kill": get_avg_damage_per_kill(),
		"powered_count": get_powered_turret_count(),
		"shots_per_kill": snappedf(float(_total_shots) / maxf(float(_total_kills), 1.0), 0.1),
		"turret_types": get_turrets_by_type().size(),
		"combat_rating": get_combat_rating(),
		"power_coverage_pct": get_power_coverage(),
		"kill_efficiency_pct": get_kill_efficiency(),
		"fire_superiority": get_fire_superiority(),
		"defense_investment_score": get_defense_investment_score(),
		"automated_defense_readiness": get_automated_defense_readiness(),
		"suppression_capability": get_suppression_capability(),
		"defense_depth_rating": get_defense_depth_rating(),
		"killzone_effectiveness_pct": get_killzone_effectiveness(),
	}

func get_suppression_capability() -> String:
	var dps := get_total_dps()
	var coverage := get_power_coverage()
	if dps >= 50.0 and coverage >= 80.0:
		return "Overwhelming"
	elif dps >= 20.0:
		return "Strong"
	elif dps > 0.0:
		return "Light"
	return "None"

func get_defense_depth_rating() -> float:
	var types: int = get_turrets_by_type().size()
	var total: int = _turrets.size()
	if total <= 0:
		return 0.0
	return snapped(float(types) * float(total) / 10.0 * 100.0, 0.1)

func get_killzone_effectiveness() -> float:
	if _total_shots <= 0:
		return 0.0
	return snappedf(float(_total_kills) / float(_total_shots) * 100.0, 0.1)
