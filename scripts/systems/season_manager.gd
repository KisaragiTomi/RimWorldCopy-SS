extends Node

## Tracks seasons and applies seasonal effects: temperature modifiers, crop
## growth rates, and event frequency. Registered as autoload "SeasonManager".

enum Season { SPRING, SUMMER, FALL, WINTER }

const SEASON_DATA: Dictionary = {
	0: {"name": "Spring", "temp_offset": 0.0, "growth_factor": 1.0, "raid_chance_mod": 0.8},
	1: {"name": "Summer", "temp_offset": 8.0, "growth_factor": 1.3, "raid_chance_mod": 1.0},
	2: {"name": "Fall", "temp_offset": -2.0, "growth_factor": 0.8, "raid_chance_mod": 1.2},
	3: {"name": "Winter", "temp_offset": -15.0, "growth_factor": 0.0, "raid_chance_mod": 0.6},
}

const QUADRUM_TO_SEASON: Dictionary = {
	"Aprimay": Season.SPRING,
	"Jugust": Season.SUMMER,
	"Septober": Season.FALL,
	"Decembary": Season.WINTER,
}

var current_season: int = Season.SPRING
var _last_quadrum: String = ""
var _season_history: Array[Dictionary] = []
var _days_in_season: int = 0
var total_season_changes: int = 0

const SEASON_EVENTS: Dictionary = {
	0: "ColdSnap",
	1: "HeatWave",
	2: "ToxicFallout",
	3: "VolcanicWinter",
}


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


const BASE_TEMPERATURE := 21.0

func _on_rare_tick(_tick: int) -> void:
	_update_season()
	_sync_temperature()

func _sync_temperature() -> void:
	if not GameState:
		return
	var seasonal_base: float = BASE_TEMPERATURE + get_temp_offset()
	var event_shift: float = 0.0
	if IncidentManager and IncidentManager.has_method("get_temp_shift"):
		event_shift = IncidentManager.get_temp_shift()
		IncidentManager.decay_temp_shift()
	GameState.temperature = seasonal_base + event_shift


func _update_season() -> void:
	if not GameState:
		return

	var quadrum: String = "Aprimay"
	if GameState and GameState.has_method("get_quadrum"):
		quadrum = GameState.get_quadrum()
	elif GameState and "game_date" in GameState and GameState.game_date is Dictionary:
		quadrum = str(GameState.game_date.get("quadrum", "Aprimay"))
	if quadrum == _last_quadrum:
		return

	_last_quadrum = quadrum
	var new_season: int = QUADRUM_TO_SEASON.get(quadrum, Season.SPRING)

	if new_season != current_season:
		_season_history.append({"season": current_season, "days": _days_in_season})
		if _season_history.size() > 20:
			_season_history.pop_front()
		current_season = new_season
		_days_in_season = 0
		total_season_changes += 1
		if ColonyLog:
			var data: Dictionary = SEASON_DATA[current_season]
			ColonyLog.add_entry("Season", data.name + " has arrived.", "info")
	else:
		_days_in_season += 1


func get_temp_offset() -> float:
	return SEASON_DATA[current_season].get("temp_offset", 0.0)


func get_growth_factor() -> float:
	return SEASON_DATA[current_season].get("growth_factor", 1.0)


func get_raid_chance_modifier() -> float:
	return SEASON_DATA[current_season].get("raid_chance_mod", 1.0)


func get_season_name() -> String:
	return SEASON_DATA[current_season].get("name", "Unknown")


func is_growing_season() -> bool:
	return current_season != Season.WINTER


func get_next_season() -> String:
	var next_idx: int = (current_season + 1) % 4
	return SEASON_DATA[next_idx].name


func get_associated_event() -> String:
	return SEASON_EVENTS.get(current_season, "")


func get_season_history() -> Array[Dictionary]:
	return _season_history.duplicate()


func get_year_count() -> int:
	return total_season_changes / 4


func get_avg_days_per_season() -> float:
	if _season_history.is_empty():
		return 0.0
	var total: int = 0
	for entry: Dictionary in _season_history:
		total += entry.get("days", 0)
	return snappedf(float(total) / float(_season_history.size()), 0.1)


func get_longest_season() -> Dictionary:
	var best: Dictionary = {}
	var best_days: int = 0
	for entry: Dictionary in _season_history:
		if entry.get("days", 0) > best_days:
			best_days = entry.get("days", 0)
			best = entry
	return best


func is_harsh_season() -> bool:
	return current_season == Season.WINTER or SEASON_DATA[current_season].get("temp_offset", 0.0) < -10.0


func get_season_progress_pct() -> float:
	return snappedf(float(_days_in_season) / 15.0 * 100.0, 0.1)

func get_raid_danger() -> String:
	var data: Dictionary = SEASON_DATA[current_season]
	var mod: float = data.get("raid_chance_mod", 1.0)
	if mod >= 1.5:
		return "High"
	elif mod >= 1.0:
		return "Normal"
	return "Low"

func get_farming_outlook() -> String:
	if is_growing_season():
		var factor: float = SEASON_DATA[current_season].get("growth_factor", 1.0)
		if factor >= 1.2:
			return "Excellent"
		return "Good"
	return "Dormant"

func get_seasonal_preparedness() -> String:
	var harsh := is_harsh_season()
	var next_idx: int = (current_season + 1) % 4
	var next_data: Dictionary = SEASON_DATA.get(next_idx, {})
	if harsh:
		return "Enduring"
	elif next_data.get("temp_offset", 0.0) < -10.0:
		return "Prepare for Winter"
	return "Comfortable"

func get_climate_stability() -> float:
	var avg := get_avg_days_per_season()
	return snapped(minf(avg / 15.0, 1.0) * 100.0, 0.1)

func get_year_maturity() -> String:
	var years := get_year_count()
	if years >= 5:
		return "Veteran"
	elif years >= 2:
		return "Established"
	elif years >= 1:
		return "Settled"
	return "New"

func get_summary() -> Dictionary:
	var data: Dictionary = SEASON_DATA[current_season]
	return {
		"current_season": data.name,
		"days_in_season": _days_in_season,
		"temp_offset": data.temp_offset,
		"growth_factor": data.growth_factor,
		"raid_modifier": data.raid_chance_mod,
		"is_growing": is_growing_season(),
		"next_season": get_next_season(),
		"associated_event": get_associated_event(),
		"total_changes": total_season_changes,
		"year_count": get_year_count(),
		"avg_days_per_season": get_avg_days_per_season(),
		"is_harsh": is_harsh_season(),
		"seasons_per_year": 4,
		"days_until_next": maxi(0, 15 - _days_in_season),
		"season_progress_pct": get_season_progress_pct(),
		"raid_danger": get_raid_danger(),
		"farming_outlook": get_farming_outlook(),
		"seasonal_preparedness": get_seasonal_preparedness(),
		"climate_stability": get_climate_stability(),
		"year_maturity": get_year_maturity(),
		"agricultural_window_pct": get_agricultural_window_pct(),
		"survival_challenge_rating": get_survival_challenge_rating(),
		"seasonal_rhythm_score": get_seasonal_rhythm_score(),
	}

func get_agricultural_window_pct() -> float:
	var growing_seasons: int = 0
	for s: int in range(4):
		var d: Dictionary = SEASON_DATA[s]
		if float(d.get("growth_factor", 0.0)) > 0.5:
			growing_seasons += 1
	return snapped(float(growing_seasons) / 4.0 * 100.0, 0.1)

func get_survival_challenge_rating() -> String:
	var harsh := is_harsh_season()
	var raid := get_raid_danger()
	if harsh and raid in ["High", "Extreme"]:
		return "Brutal"
	elif harsh or raid in ["High", "Extreme"]:
		return "Challenging"
	elif raid in ["Moderate", "High"]:
		return "Moderate"
	return "Easy"

func get_seasonal_rhythm_score() -> float:
	if total_season_changes <= 0:
		return 0.0
	var avg := get_avg_days_per_season()
	var deviation := absf(avg - 15.0)
	return snapped(maxf(0.0, 100.0 - deviation * 10.0), 0.1)
