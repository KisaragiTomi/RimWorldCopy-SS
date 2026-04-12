extends Node

var dispensers: Array[Dictionary] = []
var _meals_produced: int = 0
var _total_raw_consumed: int = 0
var _failed_dispenses: int = 0
const RAW_FOOD_PER_MEAL: int = 6
const MEAL_NUTRITION: float = 0.9

func register_dispenser(pos: Vector2i) -> void:
	for d: Dictionary in dispensers:
		if d.pos == pos:
			return
	dispensers.append({"pos": pos, "powered": true, "hoppers": []})


func unregister_dispenser(pos: Vector2i) -> void:
	for i: int in range(dispensers.size() - 1, -1, -1):
		if dispensers[i].pos == pos:
			dispensers.remove_at(i)


func dispense_meal(dispenser_pos: Vector2i) -> Dictionary:
	if not ResourceCounter:
		_failed_dispenses += 1
		return {"success": false, "reason": "No ResourceCounter"}
	var raw_count: int = ResourceCounter.get_resource_count("RawFood")
	if raw_count < RAW_FOOD_PER_MEAL:
		_failed_dispenses += 1
		return {"success": false, "reason": "Not enough raw food (%d/%d)" % [raw_count, RAW_FOOD_PER_MEAL]}
	ResourceCounter.consume_resource("RawFood", RAW_FOOD_PER_MEAL)
	_meals_produced += 1
	_total_raw_consumed += RAW_FOOD_PER_MEAL
	if ColonyLog and ColonyLog.has_method("add_entry"):
		ColonyLog.add_entry("Food", "Nutrient paste #%d dispensed at %s" % [_meals_produced, str(dispenser_pos)], "info")
	return {"success": true, "nutrition": MEAL_NUTRITION, "quality": "Awful"}


func get_nearest_dispenser(pos: Vector2i) -> Dictionary:
	var best: Dictionary = {}
	var best_dist: float = 999999.0
	for d: Dictionary in dispensers:
		if not d.powered:
			continue
		var dist: float = float(abs(d.pos.x - pos.x) + abs(d.pos.y - pos.y))
		if dist < best_dist:
			best_dist = dist
			best = d
	return best


func get_powered_count() -> int:
	var count: int = 0
	for d: Dictionary in dispensers:
		if d.powered:
			count += 1
	return count


func set_dispenser_power(pos: Vector2i, powered: bool) -> void:
	for d: Dictionary in dispensers:
		if d.pos == pos:
			d.powered = powered
			return


func can_dispense() -> bool:
	if not ResourceCounter:
		return false
	return ResourceCounter.get_resource_count("RawFood") >= RAW_FOOD_PER_MEAL and get_powered_count() > 0


func get_efficiency() -> float:
	var total_attempts: int = _meals_produced + _failed_dispenses
	if total_attempts == 0:
		return 1.0
	return snappedf(float(_meals_produced) / float(total_attempts), 0.01)


func get_meals_per_raw() -> float:
	if _total_raw_consumed == 0:
		return 0.0
	return snappedf(float(_meals_produced) / float(_total_raw_consumed), 0.01)


func get_unpowered_count() -> int:
	return dispensers.size() - get_powered_count()


func get_failure_rate() -> float:
	var total: int = _meals_produced + _failed_dispenses
	if total == 0:
		return 0.0
	return snappedf(float(_failed_dispenses) / float(total), 0.01)


func get_operational_rating() -> String:
	var fail: float = get_failure_rate()
	if fail == 0.0 and get_powered_count() > 0:
		return "Optimal"
	elif fail < 10.0:
		return "Good"
	elif fail < 30.0:
		return "Degraded"
	return "Failing"

func get_reliability_score() -> float:
	return snappedf(100.0 - get_failure_rate(), 0.1)

func get_capacity_rating() -> String:
	var avg: float = float(_meals_produced) / maxf(float(dispensers.size()), 1.0)
	if avg >= 50.0:
		return "High"
	elif avg >= 20.0:
		return "Moderate"
	elif avg > 0.0:
		return "Low"
	return "None"

func get_capacity_utilization() -> float:
	if dispensers.is_empty():
		return 0.0
	var powered := get_powered_count()
	var produced_per := float(_meals_produced) / maxf(float(dispensers.size()), 1.0)
	return snapped(minf((float(powered) / float(dispensers.size())) * (produced_per / 50.0) * 100.0, 100.0), 0.1)

func get_failure_resilience() -> String:
	var fail := get_failure_rate()
	var unpowered := get_unpowered_count()
	if fail == 0.0 and unpowered == 0:
		return "Resilient"
	elif fail < 10.0 and unpowered <= 1:
		return "Stable"
	elif fail < 30.0:
		return "Fragile"
	return "Vulnerable"

func get_food_pipeline_health() -> String:
	var rating := get_operational_rating()
	var reliability := get_reliability_score()
	if rating == "Optimal" and reliability >= 90.0:
		return "Excellent"
	elif rating in ["Optimal", "Good"] and reliability >= 70.0:
		return "Healthy"
	elif rating == "Degraded":
		return "Stressed"
	return "Failing"

func get_summary() -> Dictionary:
	return {
		"dispensers": dispensers.size(),
		"powered": get_powered_count(),
		"meals_produced": _meals_produced,
		"raw_food_per_meal": RAW_FOOD_PER_MEAL,
		"total_raw_consumed": _total_raw_consumed,
		"failed_dispenses": _failed_dispenses,
		"efficiency": get_efficiency(),
		"can_dispense": can_dispense(),
		"meals_per_raw": get_meals_per_raw(),
		"unpowered": get_unpowered_count(),
		"failure_rate": get_failure_rate(),
		"powered_pct": snappedf(float(get_powered_count()) / maxf(float(dispensers.size()), 1.0) * 100.0, 0.1),
		"avg_meals_per_dispenser": snappedf(float(_meals_produced) / maxf(float(dispensers.size()), 1.0), 0.1),
		"operational_rating": get_operational_rating(),
		"reliability_score": get_reliability_score(),
		"capacity_rating": get_capacity_rating(),
		"capacity_utilization": get_capacity_utilization(),
		"failure_resilience": get_failure_resilience(),
		"food_pipeline_health": get_food_pipeline_health(),
		"dispensary_maturity": get_dispensary_maturity(),
		"nutritional_throughput_index": get_nutritional_throughput_index(),
		"food_security_rating": get_food_security_rating(),
	}

func get_dispensary_maturity() -> float:
	if dispensers.is_empty():
		return 0.0
	var reliability := get_reliability_score()
	var utilization := get_capacity_utilization()
	return snapped((reliability + utilization) / 2.0, 0.1)

func get_nutritional_throughput_index() -> float:
	var meals := float(_meals_produced)
	var count := float(dispensers.size())
	if count <= 0.0:
		return 0.0
	var powered_ratio := float(get_powered_count()) / count
	return snapped(meals / count * powered_ratio, 0.1)

func get_food_security_rating() -> String:
	var pipeline := get_food_pipeline_health()
	var resilience := get_failure_resilience()
	if pipeline == "Excellent" and resilience == "Resilient":
		return "Secure"
	elif pipeline in ["Excellent", "Healthy"] and resilience != "Vulnerable":
		return "Adequate"
	return "At Risk"
