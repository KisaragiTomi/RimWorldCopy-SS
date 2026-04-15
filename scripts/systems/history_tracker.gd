extends Node

## Tracks colony statistics over time for graphs and summaries.
## Registered as autoload "HistoryTracker".

var records: Array[Dictionary] = []
var max_records: int = 500

var peak_wealth: float = 0.0
var peak_population: int = 0
var peak_wealth_day: int = 0
var peak_population_day: int = 0


func _ready() -> void:
	if TickManager:
		TickManager.long_tick.connect(_on_long_tick)


func _on_long_tick(_tick: int) -> void:
	var day: int = GameState.game_date.get("day", 0) if GameState else 0
	if not records.is_empty() and records[-1].get("day", -1) == day:
		return

	var record := _snapshot()
	record["day"] = day
	record["tick"] = TickManager.current_tick if TickManager else 0
	records.append(record)
	if records.size() > max_records:
		records.pop_front()

	_update_peaks(record, day)


func _update_peaks(record: Dictionary, day: int) -> void:
	var w: float = record.get("wealth", 0.0)
	if w > peak_wealth:
		peak_wealth = w
		peak_wealth_day = day
	var pop: int = record.get("population", 0)
	if pop > peak_population:
		peak_population = pop
		peak_population_day = day


func _snapshot() -> Dictionary:
	var wealth: float = GameState.get_colony_wealth() if GameState else 0.0
	var pawn_count: int = 0
	var alive_count: int = 0
	var downed_count: int = 0
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			pawn_count += 1
			if not p.dead:
				alive_count += 1
			if p.downed and not p.dead:
				downed_count += 1

	var animal_count: int = AnimalManager.animals.size() if AnimalManager else 0
	var tamed_count: int = 0
	if AnimalManager:
		for a: Animal in AnimalManager.animals:
			if a.tamed:
				tamed_count += 1

	var things_count: int = ThingManager.things.size() if ThingManager else 0
	var temp: float = GameState.temperature if GameState else 15.0

	var avg_mood: float = 0.0
	var mood_count: int = 0
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if not p.dead:
				avg_mood += p.get_need("Mood")
				mood_count += 1
	if mood_count > 0:
		avg_mood /= float(mood_count)

	var kills: int = CombatUtil.total_kills if CombatUtil else 0
	var raids: int = RaidManager.total_raids if RaidManager else 0
	var research_done: int = ResearchManager.total_completed if ResearchManager else 0

	return {
		"wealth": snappedf(wealth, 1.0),
		"population": alive_count,
		"total_pawns": pawn_count,
		"downed": downed_count,
		"animals": animal_count,
		"tamed_animals": tamed_count,
		"things": things_count,
		"temperature": snappedf(temp, 0.1),
		"weather": WeatherManager.current_weather if WeatherManager else "Clear",
		"avg_mood": snappedf(avg_mood, 0.01),
		"total_kills": kills,
		"total_raids": raids,
		"research_completed": research_done,
	}


func get_latest() -> Dictionary:
	if records.is_empty():
		return _snapshot()
	return records[-1]


func get_history(count: int = 30) -> Array[Dictionary]:
	var start := maxi(0, records.size() - count)
	var result: Array[Dictionary] = []
	for i: int in range(start, records.size()):
		result.append(records[i])
	return result


func get_field_history(field: String, count: int = 30) -> Array:
	var result: Array = []
	var start := maxi(0, records.size() - count)
	for i: int in range(start, records.size()):
		result.append(records[i].get(field, 0))
	return result


func get_wealth_trend(days: int = 7) -> float:
	if records.size() < 2:
		return 0.0
	var start_idx := maxi(0, records.size() - days)
	var start_wealth: float = records[start_idx].get("wealth", 0.0)
	var end_wealth: float = records[-1].get("wealth", 0.0)
	return end_wealth - start_wealth


func get_population_trend(days: int = 7) -> int:
	if records.size() < 2:
		return 0
	var start_idx := maxi(0, records.size() - days)
	var start_pop: int = records[start_idx].get("population", 0)
	var end_pop: int = records[-1].get("population", 0)
	return end_pop - start_pop


func get_mood_trend(days: int = 7) -> float:
	if records.size() < 2:
		return 0.0
	var start_idx := maxi(0, records.size() - days)
	var start_mood: float = records[start_idx].get("avg_mood", 0.5)
	var end_mood: float = records[-1].get("avg_mood", 0.5)
	return end_mood - start_mood


func get_worst_day() -> Dictionary:
	var worst: Dictionary = {}
	var worst_mood: float = 999.0
	for r: Dictionary in records:
		var m: float = r.get("avg_mood", 0.5)
		if m < worst_mood:
			worst_mood = m
			worst = r
	return worst


func get_best_day() -> Dictionary:
	var best: Dictionary = {}
	var best_mood: float = -1.0
	for r: Dictionary in records:
		var m: float = r.get("avg_mood", 0.5)
		if m > best_mood:
			best_mood = m
			best = r
	return best


func get_avg_wealth_growth() -> float:
	if records.size() < 2:
		return 0.0
	var first_w: float = records[0].get("wealth", 0.0)
	var last_w: float = records[-1].get("wealth", 0.0)
	var days: int = records[-1].get("day", 1) - records[0].get("day", 0)
	if days <= 0:
		return 0.0
	return (last_w - first_w) / float(days)


func get_days_since_peak_pop() -> int:
	if records.is_empty():
		return 0
	var current_day: int = records[-1].get("day", 0)
	return current_day - peak_population_day


func get_mood_volatility() -> float:
	if records.size() < 2:
		return 0.0
	var diffs: float = 0.0
	for i: int in range(1, records.size()):
		diffs += absf(records[i].get("avg_mood", 0.5) - records[i - 1].get("avg_mood", 0.5))
	return diffs / float(records.size() - 1)


func get_wealth_peak_ratio() -> float:
	if peak_wealth <= 0.0:
		return 0.0
	var latest := get_latest()
	return snappedf(latest.get("wealth", 0.0) / peak_wealth * 100.0, 0.1)


func get_avg_mood_all_time() -> float:
	if records.is_empty():
		return 0.0
	var total: float = 0.0
	for r: Dictionary in records:
		total += r.get("avg_mood", 0.5)
	return snappedf(total / float(records.size()), 0.01)


func is_in_decline() -> bool:
	return get_wealth_trend(7) < 0.0 and get_mood_trend(7) < 0.0


func get_growth_momentum() -> String:
	var w_trend := get_wealth_trend(7)
	var p_trend := get_population_trend(7)
	if w_trend > 0.0 and p_trend > 0:
		return "Booming"
	elif w_trend > 0.0:
		return "Growing"
	elif w_trend > -100.0 and p_trend >= 0:
		return "Stable"
	elif w_trend < -100.0:
		return "Declining"
	return "Stagnant"

func get_historical_stability() -> float:
	if records.size() < 3:
		return 100.0
	var mood_vol := get_mood_volatility()
	var wealth_ratio := get_wealth_peak_ratio()
	var stability := (wealth_ratio * 0.5) + ((1.0 - minf(mood_vol * 10.0, 1.0)) * 50.0)
	return snapped(clampf(stability, 0.0, 100.0), 0.1)

func get_era_assessment() -> String:
	var days := 0
	if not records.is_empty():
		days = records[-1].get("day", 0) - records[0].get("day", 0)
	if days < 15:
		return "Founding"
	elif days < 60:
		return "Establishment"
	elif is_in_decline():
		return "Decline"
	elif get_wealth_trend(7) > 200.0:
		return "Golden Age"
	return "Maturity"

func get_summary() -> Dictionary:
	var latest := get_latest()
	var first_day: int = records[0].get("day", 0) if not records.is_empty() else 0
	var last_day: int = records[-1].get("day", 0) if not records.is_empty() else 0
	return {
		"days_tracked": last_day - first_day + 1,
		"records_count": records.size(),
		"current": latest,
		"peak_wealth": snappedf(peak_wealth, 1.0),
		"peak_wealth_day": peak_wealth_day,
		"peak_population": peak_population,
		"peak_population_day": peak_population_day,
		"wealth_trend_7d": snappedf(get_wealth_trend(7), 1.0),
		"population_trend_7d": get_population_trend(7),
		"mood_trend_7d": snappedf(get_mood_trend(7), 0.01),
		"avg_wealth_growth": snappedf(get_avg_wealth_growth(), 0.1),
		"days_since_peak_pop": get_days_since_peak_pop(),
		"mood_volatility": snappedf(get_mood_volatility(), 0.001),
		"wealth_peak_ratio_pct": get_wealth_peak_ratio(),
		"avg_mood_all_time": get_avg_mood_all_time(),
		"in_decline": is_in_decline(),
		"growth_momentum": get_growth_momentum(),
		"historical_stability": get_historical_stability(),
		"era": get_era_assessment(),
		"prosperity_trajectory": get_prosperity_trajectory(),
		"cyclical_pattern_score": get_cyclical_pattern_score(),
		"civilization_maturity": get_civilization_maturity(),
	}

func get_prosperity_trajectory() -> String:
	var trend_7: float = get_wealth_trend(7)
	var trend_30: float = get_wealth_trend(30) if records.size() >= 30 else trend_7
	if trend_7 > 0.0 and trend_30 > 0.0:
		return "Ascending"
	if trend_7 < 0.0 and trend_30 < 0.0:
		return "Declining"
	if trend_7 > 0.0 and trend_30 <= 0.0:
		return "Recovering"
	return "Plateauing"

func get_cyclical_pattern_score() -> float:
	if records.size() < 14:
		return 0.0
	var mood_vol: float = get_mood_volatility()
	var stability: float = 100.0 - mood_vol * 1000.0
	return snappedf(clampf(stability, 0.0, 100.0), 0.1)

func get_civilization_maturity() -> String:
	var days: int = records.size()
	var pop_peak: int = peak_population
	if days >= 60 and pop_peak >= 10:
		return "Established"
	if days >= 30 and pop_peak >= 5:
		return "Developing"
	if days >= 10:
		return "Frontier"
	return "Nascent"
