extends Node

## Manages room temperatures and thermal appliances (heaters, coolers).
## Registered as autoload "TemperatureManager".

var room_temps: Dictionary = {}  # room_id -> float (temperature)
var appliances: Array[Dictionary] = []  # {pos, type, target_temp, power_on}

const AMBIENT_LERP := 0.02
const HEATER_POWER := 3.0
const COOLER_POWER := 4.0
const DEFAULT_TARGET := 21.0


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func add_heater(pos: Vector2i, target_temp: float = DEFAULT_TARGET) -> void:
	appliances.append({
		"pos": pos,
		"type": "Heater",
		"target_temp": target_temp,
		"power_on": true,
	})


func add_cooler(pos: Vector2i, target_temp: float = DEFAULT_TARGET) -> void:
	appliances.append({
		"pos": pos,
		"type": "Cooler",
		"target_temp": target_temp,
		"power_on": true,
	})


func get_temperature_at(pos: Vector2i) -> float:
	var room_id: int = _get_room_id(pos)
	if room_temps.has(room_id):
		return room_temps[room_id]
	return _get_outdoor_temp()


func _on_rare_tick(_tick: int) -> void:
	var outdoor: float = _get_outdoor_temp()

	for a: Dictionary in appliances:
		if not a.get("power_on", false):
			continue
		var rid: int = _get_room_id(a.get("pos", Vector2i.ZERO))
		var current: float = room_temps.get(rid, outdoor)
		var target: float = a.get("target_temp", DEFAULT_TARGET)

		match a.get("type", ""):
			"Heater":
				if current < target:
					room_temps[rid] = minf(target, current + HEATER_POWER)
			"Cooler":
				if current > target:
					room_temps[rid] = maxf(target, current - COOLER_POWER)

	for rid: int in room_temps:
		room_temps[rid] = lerpf(room_temps[rid], outdoor, AMBIENT_LERP)


func _get_outdoor_temp() -> float:
	var base: float = GameState.temperature if GameState else 15.0
	if SeasonManager:
		base += SeasonManager.get_temp_offset()
	if WeatherManager:
		base += WeatherManager.get_temp_offset()
	return base


func _get_room_id(pos: Vector2i) -> int:
	return pos.x * 10000 + pos.y


func set_appliance_target(pos: Vector2i, target_temp: float) -> void:
	for a: Dictionary in appliances:
		if a.get("pos", Vector2i.ZERO) == pos:
			a["target_temp"] = target_temp
			return


func toggle_appliance(pos: Vector2i) -> void:
	for a: Dictionary in appliances:
		if a.get("pos", Vector2i.ZERO) == pos:
			a["power_on"] = not a.get("power_on", true)
			return


func get_warmest_room() -> Dictionary:
	var best_id: int = -1
	var best_temp: float = -999.0
	for rid: int in room_temps:
		if room_temps[rid] > best_temp:
			best_temp = room_temps[rid]
			best_id = rid
	return {"room_id": best_id, "temp": best_temp}


func get_coldest_room() -> Dictionary:
	var best_id: int = -1
	var best_temp: float = 999.0
	for rid: int in room_temps:
		if room_temps[rid] < best_temp:
			best_temp = room_temps[rid]
			best_id = rid
	return {"room_id": best_id, "temp": best_temp}


func count_heated_rooms() -> int:
	var count: int = 0
	var outdoor := _get_outdoor_temp()
	for rid: int in room_temps:
		if room_temps[rid] > outdoor + 2.0:
			count += 1
	return count


func get_comfortable_rooms() -> int:
	var cnt: int = 0
	for rid: int in room_temps:
		var t: float = room_temps[rid]
		if t >= 16.0 and t <= 28.0:
			cnt += 1
	return cnt


func get_freezing_rooms() -> int:
	var cnt: int = 0
	for rid: int in room_temps:
		if room_temps[rid] < 0.0:
			cnt += 1
	return cnt


func get_avg_indoor_temp() -> float:
	if room_temps.is_empty():
		return _get_outdoor_temp()
	var total: float = 0.0
	for rid: int in room_temps:
		total += room_temps[rid]
	return total / float(room_temps.size())


func get_temp_spread() -> float:
	if room_temps.size() < 2:
		return 0.0
	var mn: float = 999.0
	var mx: float = -999.0
	for rid: int in room_temps:
		if room_temps[rid] < mn:
			mn = room_temps[rid]
		if room_temps[rid] > mx:
			mx = room_temps[rid]
	return mx - mn


func get_overheated_rooms() -> int:
	var cnt: int = 0
	for rid: int in room_temps:
		if room_temps[rid] > 35.0:
			cnt += 1
	return cnt


func get_comfort_percentage() -> float:
	if room_temps.is_empty():
		return 0.0
	return float(get_comfortable_rooms()) / float(room_temps.size()) * 100.0


func get_unheated_room_count() -> int:
	return room_temps.size() - count_heated_rooms()


func get_temp_danger_count() -> int:
	return get_freezing_rooms() + get_overheated_rooms()


func is_climate_safe() -> bool:
	return get_freezing_rooms() == 0 and get_overheated_rooms() == 0


func get_thermal_efficiency() -> float:
	var total := room_temps.size()
	if total <= 0:
		return 0.0
	var comfy := float(get_comfortable_rooms())
	var heated := float(count_heated_rooms())
	if heated <= 0.0:
		return comfy / float(total) * 100.0
	return snapped(comfy / heated * 100.0, 0.1)

func get_energy_waste_pct() -> float:
	var heated := count_heated_rooms()
	var overheated := get_overheated_rooms()
	if heated <= 0:
		return 0.0
	return snapped(float(overheated) / float(heated) * 100.0, 0.1)

func get_climate_resilience() -> String:
	var safe := is_climate_safe()
	var comfort := get_comfort_percentage()
	if safe and comfort >= 90.0:
		return "Excellent"
	elif safe and comfort >= 60.0:
		return "Good"
	elif comfort >= 40.0:
		return "Fragile"
	return "Vulnerable"

func get_summary() -> Dictionary:
	return {
		"appliances": appliances.size(),
		"tracked_rooms": room_temps.size(),
		"outdoor_temp": snappedf(_get_outdoor_temp(), 0.1),
		"heated_rooms": count_heated_rooms(),
		"warmest": get_warmest_room(),
		"coldest": get_coldest_room(),
		"comfortable": get_comfortable_rooms(),
		"freezing": get_freezing_rooms(),
		"avg_indoor": snappedf(get_avg_indoor_temp(), 0.1),
		"temp_spread": snappedf(get_temp_spread(), 0.1),
		"overheated": get_overheated_rooms(),
		"comfort_pct": snappedf(get_comfort_percentage(), 0.1),
		"unheated": get_unheated_room_count(),
		"danger_count": get_temp_danger_count(),
		"climate_safe": is_climate_safe(),
		"thermal_efficiency": get_thermal_efficiency(),
		"energy_waste_pct": get_energy_waste_pct(),
		"climate_resilience": get_climate_resilience(),
		"habitability_score": get_habitability_score(),
		"thermal_coverage_pct": get_thermal_coverage_pct(),
		"hvac_maturity": get_hvac_maturity(),
	}

func get_habitability_score() -> float:
	var comfort := get_comfort_percentage()
	var danger := get_temp_danger_count()
	return snapped(comfort * maxf(1.0 - float(danger) * 0.1, 0.0), 0.1)

func get_thermal_coverage_pct() -> float:
	var heated := count_heated_rooms()
	var total := room_temps.size()
	if total <= 0:
		return 0.0
	return snappedf(float(heated) / float(total) * 100.0, 0.1)

func get_hvac_maturity() -> String:
	var efficiency := get_thermal_efficiency()
	var coverage := get_thermal_coverage_pct()
	if efficiency in ["Excellent", "High"] and coverage >= 80.0:
		return "Advanced"
	elif coverage >= 50.0:
		return "Developing"
	return "Basic"
