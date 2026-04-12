extends Node

var _death_records: Array = []


func record_death(pawn_name: String, cause: String, age: int, killer: String = "") -> Dictionary:
	var record: Dictionary = {
		"name": pawn_name,
		"cause": cause,
		"age": age,
		"killer": killer,
		"tick": TickManager.current_tick if TickManager else 0,
	}
	_death_records.append(record)

	var msg: String = pawn_name + " has died"
	if not cause.is_empty():
		msg += " (" + cause + ")"
	if not killer.is_empty():
		msg += " killed by " + killer
	msg += " at age " + str(age)

	if EventLetter and EventLetter.has_method("send_letter"):
		EventLetter.send_letter("Death: " + pawn_name, msg, 1)
	if ColonyLog and ColonyLog.has_method("add_entry"):
		ColonyLog.add_entry("Death", msg, "critical")
	return record


func get_death_count() -> int:
	return _death_records.size()


func get_recent_deaths(count: int = 5) -> Array:
	var start: int = maxi(0, _death_records.size() - count)
	return _death_records.slice(start)


func get_deaths_by_cause() -> Dictionary:
	var dist: Dictionary = {}
	for r: Dictionary in _death_records:
		var c: String = String(r.get("cause", "Unknown"))
		dist[c] = dist.get(c, 0) + 1
	return dist


func get_deadliest_cause() -> String:
	var dist: Dictionary = get_deaths_by_cause()
	var best: String = ""
	var best_count: int = 0
	for c: String in dist:
		if dist[c] > best_count:
			best_count = dist[c]
			best = c
	return best


func get_avg_death_age() -> float:
	if _death_records.is_empty():
		return 0.0
	var total: float = 0.0
	for r: Dictionary in _death_records:
		total += float(r.get("age", 0))
	return snappedf(total / float(_death_records.size()), 0.1)


func get_youngest_death_age() -> float:
	if _death_records.is_empty():
		return 0.0
	var youngest: float = 999.0
	for r: Dictionary in _death_records:
		var age: float = float(r.get("age", 999))
		if age < youngest:
			youngest = age
	return youngest


func get_unique_cause_count() -> int:
	return get_deaths_by_cause().size()


func get_combat_death_count() -> int:
	var count: int = 0
	for r: Dictionary in _death_records:
		var cause: String = String(r.get("cause", ""))
		if cause == "Combat" or cause == "Gunshot" or cause == "Melee":
			count += 1
	return count


func get_combat_death_pct() -> float:
	if _death_records.is_empty():
		return 0.0
	return snappedf(float(get_combat_death_count()) / float(_death_records.size()) * 100.0, 0.1)


func get_oldest_death_age() -> float:
	if _death_records.is_empty():
		return 0.0
	var oldest: float = 0.0
	for r: Dictionary in _death_records:
		var age: float = float(r.get("age", 0))
		if age > oldest:
			oldest = age
	return oldest


func get_deaths_with_killer_count() -> int:
	var count: int = 0
	for r: Dictionary in _death_records:
		if not String(r.get("killer", "")).is_empty():
			count += 1
	return count


func get_mortality_trend() -> String:
	if _death_records.is_empty():
		return "None"
	var combat_pct: float = get_combat_death_pct()
	if combat_pct >= 60.0:
		return "War-Torn"
	elif combat_pct >= 30.0:
		return "Violent"
	elif combat_pct > 0.0:
		return "Mixed"
	return "Peaceful"

func get_life_expectancy() -> String:
	var avg: float = get_avg_death_age()
	if avg >= 60.0:
		return "High"
	elif avg >= 40.0:
		return "Moderate"
	elif avg > 0.0:
		return "Low"
	return "N/A"

func get_cause_diversity_pct() -> float:
	if _death_records.is_empty():
		return 0.0
	var causes: Dictionary = get_deaths_by_cause()
	var total_types: int = causes.size()
	return snappedf(float(total_types) / maxf(float(_death_records.size()), 1.0) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"total_deaths": _death_records.size(),
		"recent": get_recent_deaths(3),
		"by_cause": get_deaths_by_cause(),
		"avg_age": get_avg_death_age(),
		"deadliest_cause": get_deadliest_cause(),
		"youngest_age": get_youngest_death_age(),
		"unique_causes": get_unique_cause_count(),
		"combat_deaths": get_combat_death_count(),
		"combat_death_pct": get_combat_death_pct(),
		"oldest_age": get_oldest_death_age(),
		"killed_by_count": get_deaths_with_killer_count(),
		"mortality_trend": get_mortality_trend(),
		"life_expectancy": get_life_expectancy(),
		"cause_diversity_pct": get_cause_diversity_pct(),
		"survival_outlook": get_survival_outlook(),
		"combat_lethality_index": get_combat_lethality_index(),
		"mortality_pressure": get_mortality_pressure(),
		"mortality_ecosystem_health": get_mortality_ecosystem_health(),
		"demographic_resilience_index": get_demographic_resilience_index(),
		"survival_governance": get_survival_governance(),
	}

func get_survival_outlook() -> String:
	var expectancy := get_life_expectancy()
	var trend := get_mortality_trend()
	if expectancy in ["High"] and trend in ["Peaceful"]:
		return "Optimistic"
	elif expectancy in ["Moderate", "High"]:
		return "Stable"
	return "Grim"

func get_combat_lethality_index() -> float:
	var combat_pct := get_combat_death_pct()
	var total := _death_records.size()
	return snapped(combat_pct * float(total) / 100.0, 0.1)

func get_mortality_pressure() -> String:
	var total := _death_records.size()
	if total == 0:
		return "None"
	elif total <= 3:
		return "Low"
	elif total <= 10:
		return "Moderate"
	return "Heavy"

func get_mortality_ecosystem_health() -> float:
	var outlook := get_survival_outlook()
	var o_val: float = 90.0 if outlook == "Optimistic" else (60.0 if outlook == "Stable" else 30.0)
	var diversity := get_cause_diversity_pct()
	var pressure := get_mortality_pressure()
	var p_val: float = 90.0 if pressure == "None" else (70.0 if pressure == "Low" else (40.0 if pressure == "Moderate" else 20.0))
	return snapped((o_val + maxf(100.0 - diversity, 0.0) + p_val) / 3.0, 0.1)

func get_demographic_resilience_index() -> float:
	var lethality := get_combat_lethality_index()
	var total := _death_records.size()
	var combat_pct := get_combat_death_pct()
	var non_combat_survival := maxf(100.0 - combat_pct, 0.0)
	var death_penalty := minf(float(total) * 5.0, 50.0)
	return snapped(maxf(non_combat_survival - death_penalty + lethality * 2.0, 0.0), 0.1)

func get_survival_governance() -> String:
	var health := get_mortality_ecosystem_health()
	var resilience := get_demographic_resilience_index()
	if health >= 65.0 and resilience >= 60.0:
		return "Proactive"
	elif health >= 35.0 or resilience >= 30.0:
		return "Reactive"
	return "Neglected"
