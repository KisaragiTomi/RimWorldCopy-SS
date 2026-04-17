extends Node

## Fire system. Fires can start, spread, damage buildings/pawns, and be extinguished.
## Rain reduces fire intensity. Registered as autoload "FireManager".

signal fire_started(pos: Vector2i)
signal fire_extinguished(pos: Vector2i)
signal all_fires_out

var fires: Dictionary = {}  # Vector2i -> {ticks: int, intensity: float}
var total_fires_started: int = 0
var total_fires_extinguished: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = randi()
	if TickManager:
		TickManager.tick.connect(_on_tick)
		TickManager.long_tick.connect(_on_long_tick)


func start_fire(pos: Vector2i) -> void:
	if fires.has(pos):
		return
	fires[pos] = {"ticks": 0, "intensity": 0.3}
	total_fires_started += 1
	fire_started.emit(pos)
	if ColonyLog:
		ColonyLog.add_entry("Alert", "Fire at (%d, %d)!" % [pos.x, pos.y], "danger")


func extinguish(pos: Vector2i) -> void:
	if fires.has(pos):
		fires.erase(pos)
		total_fires_extinguished += 1
		fire_extinguished.emit(pos)
		if fires.is_empty():
			all_fires_out.emit()


func _on_tick(_tick: int) -> void:
	if _tick % 5 != 0:
		return
	var to_remove: Array[Vector2i] = []
	var is_raining: bool = _is_raining()

	for pos: Vector2i in fires:
		var fire: Dictionary = fires[pos]
		fire["ticks"] = fire.get("ticks", 0) + 5

		var growth: float = 0.005
		if is_raining:
			growth = -0.015
		fire["intensity"] = clampf(fire.get("intensity", 0.3) + growth, 0.0, 1.0)

		if fire.get("intensity", 0.0) <= 0.0 or fire.get("ticks", 0) > 3000:
			to_remove.append(pos)
			continue

		_apply_fire_damage(pos, fire)
		_apply_pawn_burn(pos, fire)

	for pos: Vector2i in to_remove:
		extinguish(pos)


func _on_long_tick(_tick: int) -> void:
	if fires.is_empty():
		return
	var spread_candidates: Array[Vector2i] = []
	for pos: Vector2i in fires:
		var fire: Dictionary = fires[pos]
		if fire.get("intensity", 0.0) < 0.5:
			continue
		var spread_chance: float = 0.1
		if _is_flammable_at(pos):
			spread_chance = 0.18
		if _rng.randf() >= spread_chance:
			continue
		var dirs: Array[Vector2i] = [
			Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		var dir: Vector2i = dirs[_rng.randi_range(0, 3)]
		var target: Vector2i = pos + dir
		if not fires.has(target):
			spread_candidates.append(target)

	for pos: Vector2i in spread_candidates:
		start_fire(pos)


func _apply_fire_damage(pos: Vector2i, fire: Dictionary) -> void:
	if not ThingManager:
		return
	if fire.get("ticks", 0) % 60 != 0:
		return

	var intensity: float = fire.get("intensity", 0.3)
	for t: Thing in ThingManager.get_things_at(pos):
		if t.state == Thing.ThingState.SPAWNED:
			t.hit_points -= roundi(intensity * 10.0)
			if t.hit_points <= 0:
				ThingManager.destroy_thing(t)
				total_buildings_destroyed += 1
				if ColonyLog:
					ColonyLog.add_entry("Alert", "%s destroyed by fire." % t.label, "danger")


func _apply_pawn_burn(pos: Vector2i, fire: Dictionary) -> void:
	if not PawnManager:
		return
	if fire.get("ticks", 0) % 120 != 0:
		return
	var intensity: float = fire.get("intensity", 0.3)
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.grid_pos != pos:
			continue
		if p.health:
			p.health.add_injury("Torso", intensity * 8.0, "Burn")
			total_burn_injuries += 1
			if ColonyLog:
				ColonyLog.add_entry("Alert", "%s burned!" % p.pawn_name, "danger")


func _is_raining() -> bool:
	if WeatherManager and WeatherManager.has_method("get_current_weather"):
		var weather: String = WeatherManager.get_current_weather()
		return weather == "Rain" or weather == "Thunderstorm"
	return false


const FLAMMABLE_DEFS: PackedStringArray = [
	"Wall", "WoodenWall", "Bed", "DoubleBed", "Table",
	"DiningChair", "Shelf", "Armchair", "WoodFiredGenerator",
]

var total_buildings_destroyed: int = 0
var total_burn_injuries: int = 0


func _is_flammable_at(pos: Vector2i) -> bool:
	if not ThingManager:
		return false
	for t: Thing in ThingManager.things:
		if t.grid_pos == pos and t is Building:
			if t.def_name in FLAMMABLE_DEFS:
				return true
	return false


func get_fire_at(pos: Vector2i) -> Dictionary:
	return fires.get(pos, {})


func get_nearest_fire(from: Vector2i, max_dist: int = 50) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_dist: int = 999999
	for pos: Vector2i in fires:
		var dist: int = absi(pos.x - from.x) + absi(pos.y - from.y)
		if dist < best_dist and dist <= max_dist:
			best_dist = dist
			best = pos
	return best


func get_highest_intensity_fire() -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_intensity: float = 0.0
	for pos: Vector2i in fires:
		var intensity: float = fires[pos].get("intensity", 0.0)
		if intensity > best_intensity:
			best_intensity = intensity
			best = pos
	return best


func get_total_intensity() -> float:
	var total: float = 0.0
	for pos: Vector2i in fires:
		total += fires[pos].get("intensity", 0.0)
	return total


func get_average_intensity() -> float:
	if fires.is_empty():
		return 0.0
	return get_total_intensity() / float(fires.size())


func get_threatened_buildings() -> int:
	if not ThingManager:
		return 0
	var cnt: int = 0
	for pos: Vector2i in fires:
		for t: Thing in ThingManager.things:
			if t.grid_pos == pos and t is Building and t.state == Thing.ThingState.SPAWNED:
				cnt += 1
				break
	return cnt


func is_fire_emergency() -> bool:
	return fires.size() >= 3 or get_total_intensity() > 2.0


func get_extinguish_rate() -> float:
	if total_fires_started == 0:
		return 0.0
	return float(total_fires_extinguished) / float(total_fires_started)


func get_max_fire_intensity() -> float:
	if fires.is_empty():
		return 0.0
	var mx: float = 0.0
	for fire_data: Dictionary in fires.values():
		var intensity: float = fire_data.get("intensity", 0.0)
		if intensity > mx:
			mx = intensity
	return mx


func get_injury_per_fire() -> float:
	if total_fires_started == 0:
		return 0.0
	return float(total_burn_injuries) / float(total_fires_started)


func get_fire_spread_risk() -> String:
	if fires.is_empty():
		return "None"
	var avg: float = get_average_intensity()
	if avg >= 0.8:
		return "Critical"
	elif avg >= 0.5:
		return "High"
	elif avg >= 0.2:
		return "Moderate"
	return "Low"


func get_destruction_rate() -> float:
	if total_fires_started <= 0:
		return 0.0
	return snappedf(float(total_buildings_destroyed) / float(total_fires_started) * 100.0, 0.1)


func get_active_fire_pct() -> float:
	if total_fires_started <= 0:
		return 0.0
	return snappedf(float(fires.size()) / float(total_fires_started) * 100.0, 0.1)


func get_containment_effectiveness() -> float:
	if total_fires_started <= 0:
		return 100.0
	var ext_ratio := float(total_fires_extinguished) / float(total_fires_started)
	var dest_penalty := float(total_buildings_destroyed) / maxf(float(total_fires_started), 1.0)
	return snapped(maxf(0.0, ext_ratio * 100.0 - dest_penalty * 50.0), 0.1)

func get_fire_danger_index() -> float:
	var active := float(fires.size())
	var avg_int := get_average_intensity()
	var threatened := float(get_threatened_buildings())
	return snapped(active * avg_int * 10.0 + threatened * 5.0, 0.1)

func get_response_readiness() -> String:
	var active := fires.size()
	var emergency := is_fire_emergency()
	var rate := get_extinguish_rate()
	if active == 0:
		return "Standby"
	elif not emergency and rate >= 0.5:
		return "Controlled"
	elif rate >= 0.2:
		return "Responding"
	return "Overwhelmed"

func get_summary() -> Dictionary:
	return {
		"active_fires": fires.size(),
		"total_started": total_fires_started,
		"total_extinguished": total_fires_extinguished,
		"total_intensity": snappedf(get_total_intensity(), 0.1),
		"buildings_destroyed": total_buildings_destroyed,
		"burn_injuries": total_burn_injuries,
		"positions": fires.keys().map(func(p: Vector2i) -> Array: return [p.x, p.y]),
		"avg_intensity": snappedf(get_average_intensity(), 0.01),
		"threatened_buildings": get_threatened_buildings(),
		"emergency": is_fire_emergency(),
		"extinguish_rate": snappedf(get_extinguish_rate(), 0.01),
		"max_intensity": snappedf(get_max_fire_intensity(), 0.01),
		"injury_per_fire": snappedf(get_injury_per_fire(), 0.01),
		"spread_risk": get_fire_spread_risk(),
		"destruction_rate_pct": get_destruction_rate(),
		"active_fire_pct": get_active_fire_pct(),
		"containment_effectiveness": get_containment_effectiveness(),
		"fire_danger_index": get_fire_danger_index(),
		"response_readiness": get_response_readiness(),
		"infrastructure_vulnerability_pct": get_infrastructure_vulnerability(),
		"fire_suppression_capacity": get_fire_suppression_capacity(),
		"colony_fire_resilience": get_colony_fire_resilience(),
	}

func get_infrastructure_vulnerability() -> float:
	var threatened := get_threatened_buildings()
	var total_fires := fires.size()
	if total_fires <= 0:
		return 0.0
	return snappedf(float(threatened) / maxf(float(total_fires), 1.0) * 100.0, 0.1)

func get_fire_suppression_capacity() -> String:
	var ext_rate := get_extinguish_rate()
	var danger := get_fire_danger_index()
	if ext_rate >= 0.8 and danger < 10.0:
		return "Excellent"
	elif ext_rate >= 0.5:
		return "Adequate"
	elif ext_rate > 0.0:
		return "Strained"
	return "None"

func get_colony_fire_resilience() -> String:
	var readiness := get_response_readiness()
	var containment := get_containment_effectiveness()
	if readiness in ["Standby", "Controlled"] and containment >= 70.0:
		return "Resilient"
	elif readiness in ["Standby", "Controlled"]:
		return "Moderate"
	return "Vulnerable"
