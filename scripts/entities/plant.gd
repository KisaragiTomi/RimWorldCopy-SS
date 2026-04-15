class_name Plant
extends Thing

## A plant that grows over time and can be harvested.

enum GrowthStage { SEEDLING, GROWING, MATURE, HARVESTABLE }

var growth: float = 0.0
var growth_stage: GrowthStage = GrowthStage.SEEDLING
var growth_rate_per_tick: float = 0.0005
var harvest_yield: int = 10
var harvest_item: String = "RawFood"
var is_sown: bool = false
var designated_cut: bool = false
var days_to_mature: float = 6.0


func _init(plant_def: String = "Potato") -> void:
	super._init()
	def_name = plant_def
	label = plant_def
	_apply_plant_def()


func _apply_plant_def() -> void:
	match def_name:
		"Potato":
			harvest_item = "RawFood"
			harvest_yield = 11
			days_to_mature = 5.6
			growth_rate_per_tick = 0.0007
		"Rice":
			harvest_item = "RawFood"
			harvest_yield = 6
			days_to_mature = 3.0
			growth_rate_per_tick = 0.0013
		"Corn":
			harvest_item = "RawFood"
			harvest_yield = 22
			days_to_mature = 11.3
			growth_rate_per_tick = 0.00035
		"Cotton":
			harvest_item = "Cloth"
			harvest_yield = 10
			days_to_mature = 6.4
			growth_rate_per_tick = 0.0006
		"Healroot":
			harvest_item = "HerbalMedicine"
			harvest_yield = 1
			days_to_mature = 8.0
			growth_rate_per_tick = 0.0005
		"Tree":
			harvest_item = "Wood"
			harvest_yield = 25
			days_to_mature = 14.0
			growth_rate_per_tick = 0.0003
			is_sown = false


var frozen_ticks: int = 0
var heat_stress_ticks: int = 0
const FREEZE_KILL_THRESHOLD := 2000
const HEAT_KILL_THRESHOLD := 1500
const OPTIMAL_TEMP_MIN := 10.0
const OPTIMAL_TEMP_MAX := 42.0

const CROP_TEMP_PREFS: Dictionary = {
	"Rice": {"min": 12.0, "max": 40.0},
	"Corn": {"min": 10.0, "max": 38.0},
	"Potato": {"min": 5.0, "max": 35.0},
	"Cotton": {"min": 15.0, "max": 45.0},
	"Healroot": {"min": 8.0, "max": 36.0},
}

func tick_growth(fertility: float = 1.0, tick_interval: int = 1) -> void:
	if growth_stage == GrowthStage.HARVESTABLE:
		return

	var temp: float = GameState.temperature if GameState else 15.0
	if WeatherManager:
		temp += WeatherManager.get_temp_offset()

	var prefs: Dictionary = CROP_TEMP_PREFS.get(def_name, {})
	var min_temp: float = prefs.get("min", OPTIMAL_TEMP_MIN)
	var max_temp: float = prefs.get("max", OPTIMAL_TEMP_MAX)

	if temp < 0.0:
		frozen_ticks += 1
		heat_stress_ticks = 0
		if frozen_ticks >= FREEZE_KILL_THRESHOLD and is_sown:
			growth = 0.0
			growth_stage = GrowthStage.SEEDLING
			frozen_ticks = 0
			if ColonyLog:
				ColonyLog.add_entry("Farm", "%s killed by frost at (%d,%d)." % [def_name, grid_pos.x, grid_pos.y], "warning")
		return

	if temp > 55.0:
		heat_stress_ticks += 1
		frozen_ticks = 0
		if heat_stress_ticks >= HEAT_KILL_THRESHOLD and is_sown:
			growth = maxf(0.0, growth - 0.3)
			heat_stress_ticks = 0
			if ColonyLog:
				ColonyLog.add_entry("Farm", "%s scorched by extreme heat at (%d,%d)." % [def_name, grid_pos.x, grid_pos.y], "warning")
		return

	frozen_ticks = 0
	heat_stress_ticks = 0

	var temp_factor: float = 1.0
	if temp < min_temp:
		temp_factor = maxf(0.1, temp / min_temp)
	elif temp > max_temp:
		temp_factor = maxf(0.1, 1.0 - (temp - max_temp) * 0.05)

	var weather_factor: float = WeatherManager.get_plant_factor() if WeatherManager else 1.0
	growth += growth_rate_per_tick * float(tick_interval) * fertility * temp_factor * weather_factor
	growth = minf(growth, 1.0)
	_update_stage()


func get_temp_status() -> String:
	var temp: float = GameState.temperature if GameState else 15.0
	if temp < 0.0:
		return "Freezing"
	var prefs: Dictionary = CROP_TEMP_PREFS.get(def_name, {})
	var min_t: float = prefs.get("min", OPTIMAL_TEMP_MIN)
	var max_t: float = prefs.get("max", OPTIMAL_TEMP_MAX)
	if temp < min_t:
		return "Cold"
	if temp > max_t:
		return "Hot"
	return "Optimal"


func _update_stage() -> void:
	if growth >= 1.0:
		growth_stage = GrowthStage.HARVESTABLE
	elif growth >= 0.5:
		growth_stage = GrowthStage.MATURE
	elif growth >= 0.1:
		growth_stage = GrowthStage.GROWING
	else:
		growth_stage = GrowthStage.SEEDLING


var blighted: bool = false
var sow_skill_bonus: float = 0.0


func harvest() -> Dictionary:
	if growth_stage != GrowthStage.HARVESTABLE:
		return {}
	if blighted:
		return {"item": harvest_item, "count": 1}
	var skill_mult: float = 1.0 + sow_skill_bonus * 0.05
	var actual_yield: int = maxi(1, roundi(harvest_yield * growth * skill_mult))
	return {"item": harvest_item, "count": actual_yield}


func apply_blight() -> void:
	if growth_stage == GrowthStage.SEEDLING:
		return
	blighted = true
	growth = maxf(0.1, growth * 0.3)
	_update_stage()


func is_alive() -> bool:
	return state == ThingState.SPAWNED and growth > 0.0


func get_growth_percent() -> int:
	return roundi(growth * 100.0)


func get_color() -> Color:
	if blighted:
		return Color(0.5, 0.3, 0.1)
	var green: float = 0.3 + growth * 0.5
	return Color(0.2, green, 0.15)


func get_expected_harvest_value() -> float:
	var values: Dictionary = {"RawFood": 1.1, "Cloth": 1.5, "HerbalMedicine": 10.0, "Wood": 1.2}
	var base_val: float = values.get(harvest_item, 1.0)
	return base_val * harvest_yield * growth


func get_days_remaining() -> float:
	if growth >= 1.0 or growth_rate_per_tick <= 0.0:
		return 0.0
	var remaining_growth: float = 1.0 - growth
	var ticks_per_day: float = 2500.0
	return remaining_growth / (growth_rate_per_tick * ticks_per_day)


func get_optimal_temp_range() -> Dictionary:
	var prefs: Dictionary = CROP_TEMP_PREFS.get(def_name, {})
	return {"min": prefs.get("min", OPTIMAL_TEMP_MIN), "max": prefs.get("max", OPTIMAL_TEMP_MAX)}


func get_growth_efficiency() -> float:
	if growth_rate_per_tick <= 0.0:
		return 0.0
	var frozen_penalty: float = 1.0 - minf(1.0, float(frozen_ticks) / 2500.0)
	var blight_penalty: float = 0.0 if blighted else 1.0
	return snappedf(frozen_penalty * blight_penalty, 0.01)

func get_value_at_harvest() -> float:
	return get_expected_harvest_value() / maxf(0.01, growth)

func is_harvestable() -> bool:
	return growth >= 1.0 and not blighted

func get_temp_tolerance_range() -> float:
	var prefs: Dictionary = get_optimal_temp_range()
	return prefs.get("max", OPTIMAL_TEMP_MAX) - prefs.get("min", OPTIMAL_TEMP_MIN)

func get_yield_per_day() -> float:
	if days_to_mature <= 0.0:
		return 0.0
	return snappedf(float(harvest_yield) / days_to_mature, 0.01)


func get_frost_risk() -> String:
	if frozen_ticks >= FREEZE_KILL_THRESHOLD * 0.8:
		return "Critical"
	elif frozen_ticks >= FREEZE_KILL_THRESHOLD * 0.4:
		return "High"
	elif frozen_ticks > 0:
		return "Moderate"
	return "None"


func get_roi_per_tile() -> float:
	if days_to_mature <= 0.0:
		return 0.0
	var value_at_harvest := get_value_at_harvest()
	var area := 1.0
	return snapped(value_at_harvest / days_to_mature / area, 0.01)

func get_climate_resilience() -> float:
	var frost_score := 1.0 - minf(1.0, float(frozen_ticks) / float(FREEZE_KILL_THRESHOLD))
	var heat_score := 1.0 - minf(1.0, float(heat_stress_ticks) / float(HEAT_KILL_THRESHOLD))
	var blight_score := 0.0 if blighted else 1.0
	var tolerance := get_temp_tolerance_range()
	var range_bonus := clampf(tolerance / 40.0, 0.0, 1.0)
	return snapped((frost_score + heat_score + blight_score + range_bonus) / 4.0, 0.01)

func get_harvest_window_days() -> float:
	if growth_stage == GrowthStage.HARVESTABLE:
		if growth_rate_per_tick <= 0.0:
			return 0.0
		return 999.0
	var days_left := get_days_remaining()
	if days_left <= 0.0:
		return 0.0
	var prefs: Dictionary = CROP_TEMP_PREFS.get(def_name, {})
	var max_temp: float = prefs.get("max", OPTIMAL_TEMP_MAX)
	var temp: float = GameState.temperature if GameState else 15.0
	var margin := maxf(0.0, max_temp - temp) / 5.0
	return snapped(margin * 10.0, 0.1)

func get_plant_summary() -> Dictionary:
	return {
		"def_name": def_name,
		"growth_pct": get_growth_percent(),
		"stage": GrowthStage.keys()[growth_stage],
		"days_remaining": snappedf(get_days_remaining(), 0.1),
		"yield_per_day": get_yield_per_day(),
		"harvest_value": snappedf(get_expected_harvest_value(), 0.1),
		"efficiency": get_growth_efficiency(),
		"frost_risk": get_frost_risk(),
		"blighted": blighted,
		"temp_status": get_temp_status(),
		"roi_per_tile": get_roi_per_tile(),
		"climate_resilience": get_climate_resilience(),
		"harvest_window_days": get_harvest_window_days(),
		"plant_ecosystem_health": get_plant_ecosystem_health(),
		"agriculture_governance": get_agriculture_governance(),
		"cultivation_maturity_index": get_cultivation_maturity_index(),
	}


func get_plant_ecosystem_health() -> float:
	var roi := minf(get_roi_per_tile() * 10.0, 100.0)
	var resilience := get_climate_resilience() * 100.0
	var window := minf(get_harvest_window_days() * 10.0, 100.0)
	return snapped((roi + resilience + window) / 3.0, 0.1)

func get_agriculture_governance() -> String:
	var eco := get_plant_ecosystem_health()
	var mat := get_cultivation_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif growth > 0.0:
		return "Nascent"
	return "Dormant"

func get_cultivation_maturity_index() -> float:
	var growth_pct := get_growth_percent()
	var eff := get_growth_efficiency() * 100.0
	var yield_score := minf(get_yield_per_day() * 50.0, 100.0)
	return snapped((growth_pct + eff + yield_score) / 3.0, 0.1)

func to_dict() -> Dictionary:
	var d := super.to_dict()
	d["growth"] = growth
	d["growth_stage"] = growth_stage
	d["harvest_item"] = harvest_item
	d["harvest_yield"] = harvest_yield
	d["is_sown"] = is_sown
	d["blighted"] = blighted
	d["frozen_ticks"] = frozen_ticks
	d["decay_progress"] = 0.0
	return d
