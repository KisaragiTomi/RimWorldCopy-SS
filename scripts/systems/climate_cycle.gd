extends Node

const CYCLE_LENGTH_YEARS: int = 6
const TEMP_AMPLITUDE: float = 8.0
const RAINFALL_AMPLITUDE: float = 0.3

var _current_year: int = 0
var _current_day: int = 0

func set_date(year: int, day: int) -> void:
	_current_year = year
	_current_day = day

func get_temp_offset() -> float:
	var phase: float = float(_current_year * 60 + _current_day) / float(CYCLE_LENGTH_YEARS * 60) * TAU
	return sin(phase) * TEMP_AMPLITUDE

func get_rainfall_factor() -> float:
	var phase: float = float(_current_year * 60 + _current_day) / float(CYCLE_LENGTH_YEARS * 60) * TAU
	return 1.0 + cos(phase + PI / 3.0) * RAINFALL_AMPLITUDE

func get_growing_season_modifier() -> float:
	var temp_off: float = get_temp_offset()
	if temp_off > 3.0:
		return 1.15
	elif temp_off < -3.0:
		return 0.85
	return 1.0

func get_current_cycle_phase() -> String:
	var temp: float = get_temp_offset()
	if temp > 4.0:
		return "Warm Period"
	elif temp > 0.0:
		return "Warming"
	elif temp > -4.0:
		return "Cooling"
	else:
		return "Cold Period"

func is_extreme_weather() -> bool:
	return absf(get_temp_offset()) > TEMP_AMPLITUDE * 0.7


func get_cycle_progress() -> float:
	var total_days: int = CYCLE_LENGTH_YEARS * 60
	return fmod(float(_current_year * 60 + _current_day), float(total_days)) / float(total_days)


func get_days_until_phase_change() -> int:
	var current_phase: String = get_current_cycle_phase()
	var sim_year: int = _current_year
	var sim_day: int = _current_day
	for i: int in range(1, CYCLE_LENGTH_YEARS * 60 + 1):
		sim_day += 1
		if sim_day >= 60:
			sim_day = 0
			sim_year += 1
		var saved_y: int = _current_year
		var saved_d: int = _current_day
		_current_year = sim_year
		_current_day = sim_day
		var new_phase: String = get_current_cycle_phase()
		_current_year = saved_y
		_current_day = saved_d
		if new_phase != current_phase:
			return i
	return CYCLE_LENGTH_YEARS * 60


func get_rainfall_factor_now() -> float:
	return get_rainfall_factor()


func get_growing_modifier_now() -> float:
	return get_growing_season_modifier()


func get_days_since_cycle_start() -> int:
	return _current_year * 60 + _current_day


func get_total_cycle_days() -> int:
	return CYCLE_LENGTH_YEARS * 60


func get_days_remaining_in_cycle() -> int:
	return get_total_cycle_days() - ((_current_year * 60 + _current_day) % get_total_cycle_days())


func get_phase_count() -> int:
	return 4


func get_agricultural_outlook() -> String:
	var grow_mod: float = get_growing_modifier_now()
	var rain: float = get_rainfall_factor_now()
	var combined: float = (grow_mod + rain) / 2.0
	if combined >= 1.2:
		return "Excellent"
	if combined >= 0.8:
		return "Good"
	if combined >= 0.5:
		return "Poor"
	return "Dire"


func get_climate_stability_pct() -> float:
	var progress: float = get_cycle_progress()
	var extreme: bool = is_extreme_weather()
	var base: float = 80.0
	if extreme:
		base -= 30.0
	base -= absf(progress - 0.5) * 40.0
	return snappedf(clampf(base, 0.0, 100.0), 0.1)


func get_season_transition_risk() -> String:
	var remaining: int = get_days_remaining_in_cycle()
	var total: int = get_total_cycle_days()
	if total == 0:
		return "Unknown"
	var pct: float = float(remaining) / float(total)
	if pct <= 0.1:
		return "Imminent"
	if pct <= 0.3:
		return "Approaching"
	return "Distant"


func get_summary() -> Dictionary:
	return {
		"cycle_length_years": CYCLE_LENGTH_YEARS,
		"temp_amplitude": TEMP_AMPLITUDE,
		"current_offset": get_temp_offset(),
		"current_phase": get_current_cycle_phase(),
		"extreme_weather": is_extreme_weather(),
		"cycle_progress": get_cycle_progress(),
		"rainfall_factor": snapped(get_rainfall_factor_now(), 0.01),
		"growing_mod": snapped(get_growing_modifier_now(), 0.01),
		"days_in_cycle": get_days_since_cycle_start(),
		"total_cycle_days": get_total_cycle_days(),
		"days_remaining": get_days_remaining_in_cycle(),
		"phase_count": get_phase_count(),
		"agricultural_outlook": get_agricultural_outlook(),
		"climate_stability_pct": get_climate_stability_pct(),
		"season_transition_risk": get_season_transition_risk(),
		"weather_adaptation_need": get_weather_adaptation_need(),
		"crop_window_quality": get_crop_window_quality(),
		"long_term_forecast": get_long_term_forecast(),
		"climate_ecosystem_health": get_climate_ecosystem_health(),
		"seasonal_governance": get_seasonal_governance(),
		"climate_adaptation_index": get_climate_adaptation_index(),
	}

func get_weather_adaptation_need() -> String:
	var extreme := is_extreme_weather()
	var stability := get_climate_stability_pct()
	if extreme and stability < 50.0:
		return "Critical"
	elif extreme or stability < 70.0:
		return "Moderate"
	return "Low"

func get_crop_window_quality() -> float:
	var growing := get_growing_modifier_now()
	var rainfall := get_rainfall_factor_now()
	return snapped((growing + rainfall) / 2.0 * 100.0, 0.1)

func get_long_term_forecast() -> String:
	var remaining := get_days_remaining_in_cycle()
	var total := get_total_cycle_days()
	if total <= 0:
		return "Unknown"
	var progress_pct := float(total - remaining) / float(total) * 100.0
	if progress_pct >= 75.0:
		return "Cycle Ending"
	elif progress_pct >= 25.0:
		return "Mid Cycle"
	return "Cycle Beginning"

func get_climate_ecosystem_health() -> float:
	var stability := get_climate_stability_pct()
	var crop_quality := get_crop_window_quality()
	var adaptation := get_weather_adaptation_need()
	var a_val: float = 90.0 if adaptation == "Low" else (60.0 if adaptation == "Moderate" else 25.0)
	return snapped((stability + crop_quality + a_val) / 3.0, 0.1)

func get_seasonal_governance() -> String:
	var ecosystem := get_climate_ecosystem_health()
	var forecast := get_long_term_forecast()
	var f_val: float = 70.0 if forecast == "Mid Cycle" else (50.0 if forecast == "Cycle Beginning" else 40.0)
	var combined := (ecosystem + f_val) / 2.0
	if combined >= 70.0:
		return "Climate Mastery"
	elif combined >= 40.0:
		return "Seasonally Aware"
	return "Weather Dependent"

func get_climate_adaptation_index() -> float:
	var stability := get_climate_stability_pct()
	var outlook := get_agricultural_outlook()
	var o_val: float = 90.0 if outlook == "Excellent" else (60.0 if outlook in ["Good", "Moderate"] else 25.0)
	return snapped((stability + o_val) / 2.0, 0.1)
