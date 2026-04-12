extends Node

## Tracks per-building power consumption and applies brownout/blackout penalties.
## Works alongside the existing PowerManager. Registered as autoload "PowerConsumption".

signal brownout_started()
signal brownout_ended()

const POWER_DRAW_DEFS: Dictionary = {
	"Heater": 175.0,
	"Cooler": 200.0,
	"SunLamp": 2900.0,
	"MiniTurret": 80.0,
	"CookingStove": 350.0,
	"MachiningTable": 350.0,
	"HiTechResearchBench": 250.0,
	"CommsConsole": 200.0,
	"StandingLamp": 75.0,
	"AutoDoor": 50.0,
	"DeepDrill": 300.0,
	"ElectricSmelter": 700.0,
}

const PRIORITY_ORDER: PackedStringArray = [
	"StandingLamp", "AutoDoor", "CommsConsole", "Cooler", "Heater",
	"CookingStove", "MachiningTable", "HiTechResearchBench", "MiniTurret",
	"SunLamp", "DeepDrill", "ElectricSmelter",
]

const BROWNOUT_WORK_PENALTY: float = 0.7
const BLACKOUT_MOOD_PENALTY: float = -0.06

var _powered_buildings: Dictionary = {}  # building_id -> {def_name, pos, draw, has_power}
var is_brownout: bool = false
var total_generation: float = 0.0
var total_consumption: float = 0.0
var brownout_ticks: int = 0
var peak_consumption: float = 0.0
var peak_generation: float = 0.0


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func register_building(building_id: int, def_name: String, pos: Vector2i) -> void:
	var draw: float = POWER_DRAW_DEFS.get(def_name, 0.0)
	if draw <= 0.0:
		return
	_powered_buildings[building_id] = {
		"def_name": def_name,
		"pos": pos,
		"draw": draw,
		"has_power": true,
	}


func unregister_building(building_id: int) -> void:
	_powered_buildings.erase(building_id)


func has_power(building_id: int) -> bool:
	if not _powered_buildings.has(building_id):
		return true
	return _powered_buildings[building_id].has_power


func get_work_speed_modifier() -> float:
	if is_brownout:
		return BROWNOUT_WORK_PENALTY
	return 1.0


func _on_rare_tick(_tick: int) -> void:
	_update_power_status()
	if is_brownout:
		brownout_ticks += 1
		_apply_blackout_thoughts()


func _update_power_status() -> void:
	total_generation = 0.0
	total_consumption = 0.0

	if ThingManager:
		for t: Thing in ThingManager.things:
			if t is Building:
				var b := t as Building
				if b.build_state == Building.BuildState.COMPLETE:
					if b.def_name == "WoodFiredGenerator":
						total_generation += 1000.0
					elif b.def_name == "SolarGenerator":
						total_generation += 1700.0

	for bid: int in _powered_buildings:
		total_consumption += _powered_buildings[bid].draw

	if total_consumption > peak_consumption:
		peak_consumption = total_consumption
	if total_generation > peak_generation:
		peak_generation = total_generation

	var old_brownout := is_brownout
	is_brownout = total_consumption > total_generation and total_generation > 0.0

	if is_brownout:
		_apply_priority_shedding()
	else:
		for bid: int in _powered_buildings:
			_powered_buildings[bid].has_power = true

	if is_brownout and not old_brownout:
		brownout_started.emit()
		if ColonyLog:
			ColonyLog.add_entry("Alert", "Power shortage! Some buildings lack power.", "warning")
	elif not is_brownout and old_brownout:
		brownout_ended.emit()


func _apply_blackout_thoughts() -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if not p.dead and p.thought_tracker:
			p.thought_tracker.add_thought("InDarkness")


func _apply_priority_shedding() -> void:
	var remaining: float = total_generation
	var sorted_ids: Array[int] = []
	for bid: int in _powered_buildings:
		sorted_ids.append(bid)

	sorted_ids.sort_custom(func(a: int, b: int) -> bool:
		var da: String = _powered_buildings[a].def_name
		var db: String = _powered_buildings[b].def_name
		var ia: int = PRIORITY_ORDER.find(da)
		var ib: int = PRIORITY_ORDER.find(db)
		if ia < 0: ia = 999
		if ib < 0: ib = 999
		return ia < ib
	)

	for bid: int in sorted_ids:
		var draw: float = _powered_buildings[bid].draw
		if remaining >= draw:
			_powered_buildings[bid].has_power = true
			remaining -= draw
		else:
			_powered_buildings[bid].has_power = false


func get_unpowered_buildings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for bid: int in _powered_buildings:
		var b: Dictionary = _powered_buildings[bid]
		if not b.has_power:
			result.append({"id": bid, "def_name": b.def_name, "pos": b.pos})
	return result


func get_consumption_by_type() -> Dictionary:
	var result: Dictionary = {}
	for bid: int in _powered_buildings:
		var def_name: String = _powered_buildings[bid].def_name
		result[def_name] = result.get(def_name, 0.0) + _powered_buildings[bid].draw
	return result


func get_biggest_consumer() -> String:
	var by_type := get_consumption_by_type()
	var best: String = ""
	var best_draw: float = 0.0
	for def_name: String in by_type:
		if by_type[def_name] > best_draw:
			best_draw = by_type[def_name]
			best = def_name
	return best


func get_power_efficiency() -> float:
	if total_generation <= 0.0:
		return 0.0
	return snappedf(minf(total_consumption / total_generation, 1.0) * 100.0, 0.1)


func get_brownout_percentage() -> float:
	if not TickManager or TickManager.current_tick <= 0:
		return 0.0
	return snappedf(float(brownout_ticks) / float(TickManager.current_tick) * 100.0, 0.01)


func get_reserve_ratio() -> float:
	if total_consumption <= 0.0:
		return 999.0
	return total_generation / total_consumption


func get_unique_consumer_types() -> int:
	return get_consumption_by_type().size()


func get_grid_stability() -> String:
	var ratio: float = get_reserve_ratio()
	if ratio >= 2.0:
		return "Stable"
	elif ratio >= 1.2:
		return "Adequate"
	elif ratio >= 1.0:
		return "Tight"
	return "Deficit"

func get_avg_draw_per_building() -> float:
	if _powered_buildings.is_empty():
		return 0.0
	return snappedf(total_consumption / float(_powered_buildings.size()), 0.1)

func get_unpowered_pct() -> float:
	if _powered_buildings.is_empty():
		return 0.0
	return snappedf(float(get_unpowered_buildings().size()) / float(_powered_buildings.size()) * 100.0, 0.1)

func get_load_balance_score() -> float:
	if total_generation <= 0.0:
		return 0.0
	var ratio := total_consumption / total_generation
	if ratio <= 0.5:
		return 100.0
	elif ratio <= 0.8:
		return 80.0
	elif ratio <= 1.0:
		return 60.0
	return snapped(maxf(0.0, 100.0 - (ratio - 1.0) * 100.0), 0.1)

func get_infrastructure_maturity() -> String:
	var types := get_unique_consumer_types()
	var stability := get_grid_stability()
	if types >= 5 and stability == "Stable":
		return "Mature"
	elif types >= 3:
		return "Developing"
	return "Early"

func get_power_crisis_risk() -> String:
	var reserve := get_reserve_ratio()
	var brownout := get_brownout_percentage()
	if brownout > 20.0 or reserve < 0.5:
		return "Critical"
	elif brownout > 10.0 or reserve < 1.0:
		return "High"
	elif brownout > 0.0:
		return "Low"
	return "None"

func get_summary() -> Dictionary:
	return {
		"total_generation": snappedf(total_generation, 0.1),
		"total_consumption": snappedf(total_consumption, 0.1),
		"surplus": snappedf(total_generation - total_consumption, 0.1),
		"is_brownout": is_brownout,
		"brownout_ticks": brownout_ticks,
		"tracked_buildings": _powered_buildings.size(),
		"unpowered": get_unpowered_buildings().size(),
		"peak_consumption": snappedf(peak_consumption, 0.1),
		"peak_generation": snappedf(peak_generation, 0.1),
		"by_type": get_consumption_by_type(),
		"biggest_consumer": get_biggest_consumer(),
		"efficiency_pct": get_power_efficiency(),
		"brownout_pct": get_brownout_percentage(),
		"reserve_ratio": snappedf(get_reserve_ratio(), 0.01),
		"consumer_types": get_unique_consumer_types(),
		"grid_stability": get_grid_stability(),
		"avg_draw_per_building": get_avg_draw_per_building(),
		"unpowered_pct": get_unpowered_pct(),
		"load_balance_score": get_load_balance_score(),
		"infrastructure_maturity": get_infrastructure_maturity(),
		"power_crisis_risk": get_power_crisis_risk(),
		"energy_sovereignty": get_energy_sovereignty(),
		"consumption_efficiency_index": get_consumption_efficiency_index(),
		"grid_resilience_score": get_grid_resilience_score(),
	}

func get_energy_sovereignty() -> String:
	var surplus: float = total_generation - total_consumption
	var reserve: float = get_reserve_ratio()
	if surplus > 0.0 and reserve >= 0.3:
		return "Self-Sufficient"
	if surplus >= 0.0:
		return "Balanced"
	return "Deficit"

func get_consumption_efficiency_index() -> float:
	var efficiency: float = get_power_efficiency()
	var balance: float = get_load_balance_score()
	return snappedf((efficiency + balance) / 2.0, 0.1)

func get_grid_resilience_score() -> float:
	var brownout_pct: float = get_brownout_percentage()
	var unpowered: float = get_unpowered_pct()
	var score: float = 100.0 - brownout_pct - unpowered
	return snappedf(clampf(score, 0.0, 100.0), 0.1)
