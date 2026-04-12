extends Node

## Weather system. Season-aware cycling with temperature, plant, and mood effects.
## Supports weather forecast and transition tracking.
## Registered as autoload "WeatherManager".

signal weather_changed(old_type: String, new_type: String)

enum WeatherType { CLEAR, RAIN, FOG, SNOW, THUNDERSTORM, DRIZZLE, HAIL }

const WEATHER_DATA: Dictionary = {
	"Clear": {"temp_offset": 0.0, "move_factor": 1.0, "plant_factor": 1.0, "mood": 0.0, "min_hours": 6, "max_hours": 48},
	"Rain": {"temp_offset": -3.0, "move_factor": 0.85, "plant_factor": 1.2, "mood": -0.02, "min_hours": 3, "max_hours": 18},
	"Drizzle": {"temp_offset": -1.5, "move_factor": 0.92, "plant_factor": 1.1, "mood": -0.01, "min_hours": 2, "max_hours": 10},
	"Fog": {"temp_offset": -1.0, "move_factor": 0.9, "plant_factor": 0.9, "mood": -0.01, "min_hours": 2, "max_hours": 12},
	"Snow": {"temp_offset": -8.0, "move_factor": 0.7, "plant_factor": 0.0, "mood": -0.04, "min_hours": 4, "max_hours": 24},
	"Thunderstorm": {"temp_offset": -5.0, "move_factor": 0.6, "plant_factor": 0.8, "mood": -0.06, "min_hours": 1, "max_hours": 8},
	"Hail": {"temp_offset": -4.0, "move_factor": 0.65, "plant_factor": 0.3, "mood": -0.05, "min_hours": 1, "max_hours": 6},
}

const SEASON_WEIGHTS: Dictionary = {
	"Spring": {"Clear": 3, "Rain": 2, "Drizzle": 2, "Fog": 1, "Thunderstorm": 1},
	"Summer": {"Clear": 4, "Rain": 1, "Drizzle": 1, "Thunderstorm": 2, "Hail": 1},
	"Fall": {"Clear": 2, "Rain": 3, "Drizzle": 2, "Fog": 2, "Snow": 1},
	"Winter": {"Clear": 2, "Snow": 4, "Fog": 1, "Hail": 1},
}

var current_weather: String = "Clear"
var previous_weather: String = "Clear"
var weather_history: Array[String] = []
var _ticks_until_change: int = 0
var _rng := RandomNumberGenerator.new()

const MAX_HISTORY := 10


func _ready() -> void:
	_rng.seed = randi()
	_schedule_next_change()
	if TickManager:
		TickManager.tick.connect(_on_tick)


func get_current_weather() -> String:
	return current_weather


func get_weather_data() -> Dictionary:
	return WEATHER_DATA.get(current_weather, WEATHER_DATA["Clear"])


func get_temp_offset() -> float:
	return get_weather_data().get("temp_offset", 0.0)


func get_move_factor() -> float:
	return get_weather_data().get("move_factor", 1.0)


func get_plant_factor() -> float:
	return get_weather_data().get("plant_factor", 1.0)


func get_mood_effect() -> float:
	return get_weather_data().get("mood", 0.0)


func is_outdoor_dangerous() -> bool:
	return current_weather in ["Thunderstorm", "Hail", "Snow"]


func _on_tick(_tick: int) -> void:
	_ticks_until_change -= 1
	if _ticks_until_change <= 0:
		_change_weather()


func _change_weather() -> void:
	previous_weather = current_weather
	var season: String = _get_season()
	var weights: Dictionary = SEASON_WEIGHTS.get(season, SEASON_WEIGHTS["Spring"])

	var chosen: String = _weighted_pick(weights)
	current_weather = chosen
	_schedule_next_change()

	weather_history.append(chosen)
	if weather_history.size() > MAX_HISTORY:
		weather_history.pop_front()

	if ColonyLog and previous_weather != chosen:
		ColonyLog.add_entry("Weather", "Weather: %s → %s." % [previous_weather, chosen], "info")
	weather_changed.emit(previous_weather, chosen)


func _weighted_pick(weights: Dictionary) -> String:
	var total: int = 0
	for w: String in weights:
		total += int(weights[w])
	var roll: int = _rng.randi_range(0, total - 1)
	var acc: int = 0
	for w: String in weights:
		acc += int(weights[w])
		if roll < acc:
			return w
	return "Clear"


func _get_season() -> String:
	if GameState:
		return GameState.season
	return "Spring"


func _schedule_next_change() -> void:
	var d: Dictionary = WEATHER_DATA.get(current_weather, WEATHER_DATA["Clear"])
	var min_h: int = d.get("min_hours", 4)
	var max_h: int = d.get("max_hours", 24)
	var hours: int = _rng.randi_range(min_h, max_h)
	_ticks_until_change = hours * 250


func get_forecast() -> Array[String]:
	var result: Array[String] = [current_weather]
	var season: String = _get_season()
	var weights: Dictionary = SEASON_WEIGHTS.get(season, SEASON_WEIGHTS["Spring"])
	for i: int in 2:
		result.append(_weighted_pick(weights))
	return result


func get_weather_frequency() -> Dictionary:
	var freq: Dictionary = {}
	for w: String in weather_history:
		freq[w] = freq.get(w, 0) + 1
	return freq


func get_most_common_weather() -> String:
	var freq: Dictionary = get_weather_frequency()
	var best: String = "Clear"
	var best_c: int = 0
	for w: String in freq:
		if freq[w] > best_c:
			best_c = freq[w]
			best = w
	return best


func get_hours_until_change() -> float:
	return float(_ticks_until_change) / 250.0


func get_unique_weather_experienced() -> int:
	var seen: Dictionary = {}
	for w: String in weather_history:
		seen[w] = true
	return seen.size()

func get_dangerous_weather_count() -> int:
	var count: int = 0
	for w: String in weather_history:
		if w in ["Toxic Fallout", "Flashstorm", "Volcanic Winter"]:
			count += 1
	return count

func get_clear_weather_pct() -> float:
	if weather_history.is_empty():
		return 0.0
	var clear: int = 0
	for w: String in weather_history:
		if w == "Clear":
			clear += 1
	return snappedf(float(clear) / float(weather_history.size()) * 100.0, 0.1)

func get_weather_streak() -> int:
	if weather_history.is_empty():
		return 0
	var current: String = weather_history[-1]
	var streak: int = 1
	for i: int in range(weather_history.size() - 2, -1, -1):
		if weather_history[i] == current:
			streak += 1
		else:
			break
	return streak


func get_avg_temp_offset_history() -> float:
	if weather_history.is_empty():
		return 0.0
	var total: float = 0.0
	for w: String in weather_history:
		var data: Dictionary = WEATHER_DATA.get(w, {})
		total += float(data.get("temp", 0.0))
	return snappedf(total / float(weather_history.size()), 0.1)


func is_favorable_for_crops() -> bool:
	return get_plant_factor() >= 0.8 and not is_outdoor_dangerous()


func get_climate_stability() -> float:
	if weather_history.size() < 3:
		return 100.0
	var changes := 0
	for i: int in range(1, weather_history.size()):
		if weather_history[i] != weather_history[i - 1]:
			changes += 1
	return snapped((1.0 - float(changes) / float(weather_history.size())) * 100.0, 0.1)

func get_outdoor_viability_pct() -> float:
	if weather_history.is_empty():
		return 100.0
	var safe := 0
	for w: String in weather_history:
		var data: Dictionary = WEATHER_DATA.get(w, {})
		var mood: float = data.get("mood", 0.0)
		if mood > -0.04:
			safe += 1
	return snapped(float(safe) / float(weather_history.size()) * 100.0, 0.1)

func get_agricultural_forecast() -> String:
	var plant_f := get_plant_factor()
	var crop_ok := is_favorable_for_crops()
	var streak := get_weather_streak()
	if crop_ok and plant_f >= 1.0:
		return "Excellent"
	elif crop_ok:
		return "Good"
	elif plant_f >= 0.5:
		return "Marginal"
	return "Hostile"

func get_summary() -> Dictionary:
	return {
		"weather": current_weather,
		"previous": previous_weather,
		"temp_offset": get_temp_offset(),
		"move_factor": get_move_factor(),
		"plant_factor": get_plant_factor(),
		"mood_effect": get_mood_effect(),
		"outdoor_dangerous": is_outdoor_dangerous(),
		"ticks_until_change": _ticks_until_change,
		"forecast": get_forecast(),
		"history": weather_history,
		"most_common": get_most_common_weather(),
		"hours_until_change": get_hours_until_change(),
		"unique_weather_types": get_unique_weather_experienced(),
		"dangerous_count": get_dangerous_weather_count(),
		"clear_pct": get_clear_weather_pct(),
		"weather_streak": get_weather_streak(),
		"avg_temp_offset": get_avg_temp_offset_history(),
		"crop_favorable": is_favorable_for_crops(),
		"climate_stability": get_climate_stability(),
		"outdoor_viability_pct": get_outdoor_viability_pct(),
		"agricultural_forecast": get_agricultural_forecast(),
		"seasonal_predictability": get_seasonal_predictability(),
		"extreme_weather_risk_pct": get_extreme_weather_risk(),
		"meteorological_diversity": get_meteorological_diversity(),
	}

func get_seasonal_predictability() -> String:
	if weather_history.size() < 3:
		return "Unknown"
	var streak := get_weather_streak()
	var stability := get_climate_stability()
	if stability in ["Stable", "Mild"] and streak >= 3:
		return "Highly Predictable"
	elif stability in ["Stable", "Mild"]:
		return "Predictable"
	return "Unpredictable"

func get_extreme_weather_risk() -> float:
	var dangerous := get_dangerous_weather_count()
	var total := weather_history.size()
	if total <= 0:
		return 0.0
	return snappedf(float(dangerous) / float(total) * 100.0, 0.1)

func get_meteorological_diversity() -> float:
	var unique := get_unique_weather_experienced()
	var total_types := WEATHER_DATA.size()
	if total_types <= 0:
		return 0.0
	return snappedf(float(unique) / float(total_types) * 100.0, 0.1)
