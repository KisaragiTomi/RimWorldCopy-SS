extends Node

var _current_severity: Dictionary = {}

const WEATHER_SCALES: Dictionary = {
	"Rain": {"min": 0.1, "max": 1.0, "temp_offset_per": -2.0, "outdoor_penalty_per": -0.05, "crop_mod_per": 0.1},
	"Snow": {"min": 0.1, "max": 1.0, "temp_offset_per": -5.0, "outdoor_penalty_per": -0.08, "move_penalty_per": -0.1},
	"Fog": {"min": 0.3, "max": 0.8, "sight_penalty_per": -0.3, "accuracy_penalty_per": -0.15},
	"Thunderstorm": {"min": 0.5, "max": 1.0, "temp_offset_per": -3.0, "fire_chance_per": 0.002, "mood_per": -3.0},
	"HeatWave": {"min": 0.3, "max": 1.0, "temp_offset_per": 15.0, "outdoor_penalty_per": -0.10},
	"ColdSnap": {"min": 0.3, "max": 1.0, "temp_offset_per": -20.0, "crop_mod_per": -0.5},
	"ToxicFallout": {"min": 0.5, "max": 1.0, "outdoor_penalty_per": -0.15, "severity_gain_per": 0.001},
	"VolcanicWinter": {"min": 0.4, "max": 0.9, "temp_offset_per": -10.0, "crop_mod_per": -0.4, "mood_per": -5.0},
	"Eclipse": {"min": 1.0, "max": 1.0, "mood_per": -3.0, "sight_penalty_per": -0.2},
	"Flashstorm": {"min": 0.6, "max": 1.0, "fire_chance_per": 0.005, "duration_hours": 4}
}

func set_severity(weather: String, severity: float) -> bool:
	if not WEATHER_SCALES.has(weather):
		return false
	var scale: Dictionary = WEATHER_SCALES[weather]
	severity = clampf(severity, scale["min"], scale["max"])
	_current_severity[weather] = severity
	return true

func get_severity(weather: String) -> float:
	return _current_severity.get(weather, 0.0)

func get_temp_offset() -> float:
	var total: float = 0.0
	for w: String in _current_severity:
		var scale: Dictionary = WEATHER_SCALES.get(w, {})
		if scale.has("temp_offset_per"):
			total += scale["temp_offset_per"] * _current_severity[w]
	return total

func get_outdoor_penalty() -> float:
	var total: float = 0.0
	for w: String in _current_severity:
		var scale: Dictionary = WEATHER_SCALES.get(w, {})
		if scale.has("outdoor_penalty_per"):
			total += scale["outdoor_penalty_per"] * _current_severity[w]
	return total

func get_active_weather() -> Array:
	return _current_severity.keys()

func get_most_severe() -> Dictionary:
	var best_w: String = ""
	var best_sev: float = 0.0
	for w: String in _current_severity:
		if _current_severity[w] > best_sev:
			best_sev = _current_severity[w]
			best_w = w
	if best_w.is_empty():
		return {}
	return {"weather": best_w, "severity": snapped(best_sev, 0.01)}


func get_crop_modifier() -> float:
	var total: float = 0.0
	for w: String in _current_severity:
		var scale: Dictionary = WEATHER_SCALES.get(w, {})
		if scale.has("crop_mod_per"):
			total += float(scale["crop_mod_per"]) * _current_severity[w]
	return total


func clear_weather(weather: String) -> void:
	_current_severity.erase(weather)


func get_avg_active_severity() -> float:
	if _current_severity.is_empty():
		return 0.0
	var total: float = 0.0
	for w: String in _current_severity:
		total += _current_severity[w]
	return total / _current_severity.size()


func get_dangerous_weather_count() -> int:
	var count: int = 0
	for w: String in _current_severity:
		var scale: Dictionary = WEATHER_SCALES.get(w, {})
		if scale.has("severity_gain_per") or scale.has("fire_chance_per") or float(scale.get("temp_offset_per", 0.0)) <= -10.0 or float(scale.get("temp_offset_per", 0.0)) >= 10.0:
			count += 1
	return count


func get_total_mood_offset() -> float:
	var total: float = 0.0
	for w: String in _current_severity:
		var scale: Dictionary = WEATHER_SCALES.get(w, {})
		if scale.has("mood_per"):
			total += float(scale["mood_per"]) * _current_severity[w]
	return total


func get_crop_affecting_count() -> int:
	var count: int = 0
	for w: String in _current_severity:
		if WEATHER_SCALES.get(w, {}).has("crop_mod_per"):
			count += 1
	return count


func get_fire_risk_count() -> int:
	var count: int = 0
	for w: String in _current_severity:
		if WEATHER_SCALES.get(w, {}).has("fire_chance_per"):
			count += 1
	return count


func get_inactive_count() -> int:
	return WEATHER_SCALES.size() - _current_severity.size()


func get_weather_danger() -> String:
	var dangerous: int = get_dangerous_weather_count()
	if dangerous >= 3:
		return "Extreme"
	elif dangerous >= 2:
		return "High"
	elif dangerous >= 1:
		return "Elevated"
	return "Clear"

func get_outdoor_viability() -> String:
	var fire: int = get_fire_risk_count()
	var crop: int = get_crop_affecting_count()
	if fire + crop >= 4:
		return "Hostile"
	elif fire + crop >= 2:
		return "Challenging"
	elif fire + crop >= 1:
		return "Manageable"
	return "Favorable"

func get_weather_volatility_pct() -> float:
	if WEATHER_SCALES.is_empty():
		return 0.0
	return snappedf(float(_current_severity.size()) / float(WEATHER_SCALES.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"weather_types": WEATHER_SCALES.size(),
		"active_count": _current_severity.size(),
		"temp_offset": snapped(get_temp_offset(), 0.1),
		"most_severe": get_most_severe(),
		"avg_severity": snapped(get_avg_active_severity(), 0.01),
		"dangerous_count": get_dangerous_weather_count(),
		"mood_offset": snapped(get_total_mood_offset(), 0.1),
		"crop_affecting": get_crop_affecting_count(),
		"fire_risk": get_fire_risk_count(),
		"inactive_types": get_inactive_count(),
		"weather_danger": get_weather_danger(),
		"outdoor_viability": get_outdoor_viability(),
		"weather_volatility_pct": get_weather_volatility_pct(),
		"climate_harshness": get_climate_harshness(),
		"shelter_necessity": get_shelter_necessity(),
		"agricultural_weather_risk": get_agricultural_weather_risk(),
		"weather_ecosystem_health": get_weather_ecosystem_health(),
		"meteorological_governance": get_meteorological_governance(),
		"climate_maturity_index": get_climate_maturity_index(),
	}

func get_climate_harshness() -> String:
	var danger := get_weather_danger()
	var volatility := get_weather_volatility_pct()
	if danger in ["Severe", "Extreme"] and volatility >= 50.0:
		return "Brutal"
	elif danger in ["Moderate", "Severe"]:
		return "Harsh"
	return "Mild"

func get_shelter_necessity() -> String:
	var outdoor := get_outdoor_viability()
	if outdoor in ["Dangerous", "Deadly"]:
		return "Essential"
	elif outdoor in ["Risky"]:
		return "Recommended"
	return "Optional"

func get_agricultural_weather_risk() -> float:
	var crop := get_crop_affecting_count()
	var fire := get_fire_risk_count()
	var total := WEATHER_SCALES.size()
	if total <= 0:
		return 0.0
	return snapped(float(crop + fire) / float(total) * 100.0, 0.1)

func get_weather_ecosystem_health() -> float:
	var harshness := get_climate_harshness()
	var h_val: float = 90.0 if harshness == "Mild" else (50.0 if harshness == "Harsh" else 20.0)
	var shelter := get_shelter_necessity()
	var s_val: float = 90.0 if shelter == "Optional" else (50.0 if shelter == "Recommended" else 20.0)
	var risk := get_agricultural_weather_risk()
	var r_val: float = maxf(100.0 - risk, 0.0)
	return snapped((h_val + s_val + r_val) / 3.0, 0.1)

func get_climate_maturity_index() -> float:
	var danger := get_weather_danger()
	var d_val: float = 90.0 if danger in ["None", "Low"] else (50.0 if danger in ["Moderate"] else 20.0)
	var volatility := get_weather_volatility_pct()
	var v_val: float = maxf(100.0 - volatility, 0.0)
	var outdoor := get_outdoor_viability()
	var o_val: float = 90.0 if outdoor in ["Safe", "Good"] else (50.0 if outdoor in ["Risky", "Moderate"] else 20.0)
	return snapped((d_val + v_val + o_val) / 3.0, 0.1)

func get_meteorological_governance() -> String:
	var ecosystem := get_weather_ecosystem_health()
	var maturity := get_climate_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _current_severity.size() > 0:
		return "Nascent"
	return "Dormant"
