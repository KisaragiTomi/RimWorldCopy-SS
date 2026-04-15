extends Node

## Generates a yearly summary of colony events and progress.
## Registered as autoload "YearlyRecap".

signal recap_generated(year: int, recap: Dictionary)

var recaps: Array[Dictionary] = []
var _last_year: int = 5500


func _ready() -> void:
	if TickManager:
		TickManager.long_tick.connect(_on_long_tick)


func _on_long_tick(_tick: int) -> void:
	if not GameState:
		return
	var current_year: int = GameState.game_date.get("year", 5500) as int

	if current_year > _last_year:
		var recap := generate_recap(_last_year)
		recaps.append(recap)
		recap_generated.emit(_last_year, recap)
		_last_year = current_year

		if ColonyLog:
			ColonyLog.add_entry("System", "Year " + str(_last_year - 1) + " recap generated.", "info")


func generate_recap(year: int) -> Dictionary:
	var recap := {
		"year": year,
		"population": PawnManager.pawns.size() if PawnManager else 0,
		"wealth": 0.0,
		"animals_tamed": 0,
		"research_completed": 0,
		"deaths": 0,
		"raids": 0,
		"buildings": 0,
	}

	if GameState:
		recap["wealth"] = GameState.get("colony_wealth") if GameState.get("colony_wealth") else 0.0

	if AnimalManager:
		var tamed: int = 0
		for a: Animal in AnimalManager.animals:
			if a.tamed:
				tamed += 1
		recap["animals_tamed"] = tamed

	if ResearchManager:
		recap["research_completed"] = ResearchManager._completed.size()

	if ThingManager:
		var buildings: int = 0
		for t: Thing in ThingManager.things:
			if t is Building:
				buildings += 1
		recap["buildings"] = buildings

	if HistoryTracker and not HistoryTracker.records.is_empty():
		var latest: Dictionary = HistoryTracker.records[-1]
		recap["wealth"] = latest.get("wealth", 0.0)

	return recap


func get_all_recaps() -> Array[Dictionary]:
	return recaps


func get_summary() -> Dictionary:
	return {
		"total_recaps": recaps.size(),
		"last_year": _last_year,
	}
