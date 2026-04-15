extends Node

var _deterioration_map: Dictionary = {}
var _total_destroyed: int = 0
const DETERIORATION_RATE: float = 0.001
const WEATHER_MULTIPLIER: Dictionary = {
	"Clear": 1.0,
	"Rain": 2.5,
	"Fog": 1.5,
	"Snow": 2.0,
	"Thunderstorm": 3.0,
}


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func _on_rare_tick(_tick: int) -> void:
	_update_deterioration()


func register_outdoor_item(item_id: int, pos: Vector2i, max_hp: float) -> void:
	_deterioration_map[item_id] = {
		"pos": pos,
		"hp": max_hp,
		"max_hp": max_hp,
	}


func unregister_item(item_id: int) -> void:
	_deterioration_map.erase(item_id)


func _update_deterioration() -> void:
	var weather: String = "Clear"
	if WeatherManager and WeatherManager.has_method("get_current_weather"):
		weather = str(WeatherManager.get_current_weather())
	var weather_mult: float = WEATHER_MULTIPLIER.get(weather, 1.0)
	var to_remove: Array[int] = []
	for item_id: int in _deterioration_map:
		var data: Dictionary = _deterioration_map[item_id]
		var is_outdoor: bool = true
		if RoofManager and RoofManager.has_method("has_roof"):
			is_outdoor = not RoofManager.has_roof(data.pos)
		if is_outdoor:
			data.hp -= DETERIORATION_RATE * weather_mult * data.max_hp
			if data.hp <= 0.0:
				to_remove.append(item_id)
	for rid: int in to_remove:
		_deterioration_map.erase(rid)
		_total_destroyed += 1
		if ColonyLog and ColonyLog.has_method("add_entry"):
			ColonyLog.add_entry("Item", "Outdoor item #%d destroyed by deterioration." % rid, "warning")


func get_most_damaged() -> Dictionary:
	var worst_id: int = -1
	var worst_pct: float = 999.0
	for item_id: int in _deterioration_map:
		var data: Dictionary = _deterioration_map[item_id]
		var pct: float = data.hp / maxf(data.max_hp, 0.01)
		if pct < worst_pct:
			worst_pct = pct
			worst_id = item_id
	if worst_id < 0:
		return {}
	return {"item_id": worst_id, "hp_pct": snappedf(worst_pct, 0.01)}


func get_outdoor_count() -> int:
	var count: int = 0
	for item_id: int in _deterioration_map:
		var data: Dictionary = _deterioration_map[item_id]
		var is_outdoor: bool = true
		if RoofManager and RoofManager.has_method("has_roof"):
			is_outdoor = not RoofManager.has_roof(data.pos)
		if is_outdoor:
			count += 1
	return count


func get_item_hp(item_id: int) -> float:
	var data: Dictionary = _deterioration_map.get(item_id, {})
	if data.is_empty():
		return -1.0
	return snappedf(data.hp / maxf(data.max_hp, 0.01), 0.01)


func get_decay_severity() -> String:
	if _deterioration_map.is_empty():
		return "None"
	var outdoor: int = get_outdoor_count()
	var ratio: float = float(outdoor) / float(_deterioration_map.size()) * 100.0
	if ratio >= 50.0:
		return "Severe"
	elif ratio >= 20.0:
		return "Moderate"
	elif ratio > 0.0:
		return "Mild"
	return "Minimal"

func get_loss_rate() -> float:
	if _deterioration_map.is_empty():
		return 0.0
	return snappedf(float(_total_destroyed) / float(_deterioration_map.size()) * 100.0, 0.1)

func get_exposure_risk_pct() -> float:
	if _deterioration_map.is_empty():
		return 0.0
	return snappedf(float(get_outdoor_count()) / float(_deterioration_map.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"tracked_items": _deterioration_map.size(),
		"weather_multipliers": WEATHER_MULTIPLIER.size(),
		"total_destroyed": _total_destroyed,
		"outdoor_count": get_outdoor_count(),
		"most_damaged": get_most_damaged(),
		"decay_severity": get_decay_severity(),
		"loss_rate_pct": get_loss_rate(),
		"exposure_risk_pct": get_exposure_risk_pct(),
		"preservation_strategy": get_preservation_strategy(),
		"wastage_prevention_score": get_wastage_prevention_score(),
		"inventory_safety": get_inventory_safety(),
		"storage_climate_index": get_storage_climate_index(),
		"material_lifespan_outlook": get_material_lifespan_outlook(),
		"entropy_resistance": get_entropy_resistance(),
	}

func get_storage_climate_index() -> float:
	var exposure := get_exposure_risk_pct()
	return snapped(maxf(100.0 - exposure, 0.0), 0.1)

func get_material_lifespan_outlook() -> String:
	var strategy := get_preservation_strategy()
	var loss := get_loss_rate()
	if strategy == "Excellent" and loss < 5.0:
		return "Long-lasting"
	elif strategy == "Critical" or loss >= 30.0:
		return "Rapid Decay"
	return "Moderate"

func get_entropy_resistance() -> float:
	var wastage := get_wastage_prevention_score()
	var safety := get_inventory_safety()
	var bonus: float = 1.2 if safety == "Safe" else 0.8
	return snapped(wastage * bonus, 0.1)

func get_preservation_strategy() -> String:
	var exposure := get_exposure_risk_pct()
	if exposure < 10.0:
		return "Excellent"
	elif exposure < 30.0:
		return "Good"
	elif exposure < 60.0:
		return "Needs Work"
	return "Critical"

func get_wastage_prevention_score() -> float:
	var loss := get_loss_rate()
	return snapped(maxf(0.0, 100.0 - loss), 0.1)

func get_inventory_safety() -> String:
	var severity := get_decay_severity()
	var outdoor := get_outdoor_count()
	if severity in ["None", "Minor"] and outdoor == 0:
		return "Secure"
	elif outdoor <= 2:
		return "Adequate"
	return "At Risk"
