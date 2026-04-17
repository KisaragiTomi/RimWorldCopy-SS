extends Node

var _spots: Array[Dictionary] = []
var _last_generate_tick: int = 0
var _total_harvested: int = 0
var _total_generated: int = 0
var _harvested_by_type: Dictionary = {}
const GENERATE_INTERVAL: int = 30000

const SPOT_TYPES: Dictionary = {
	"SteelVein": {"resource": "Steel", "amount_range": [30, 80], "rarity": 0.4},
	"GoldDeposit": {"resource": "Gold", "amount_range": [5, 20], "rarity": 0.1},
	"UraniumDeposit": {"resource": "Uranium", "amount_range": [3, 10], "rarity": 0.05},
	"ComponentCluster": {"resource": "Components", "amount_range": [2, 8], "rarity": 0.15},
	"JadeVein": {"resource": "Jade", "amount_range": [5, 15], "rarity": 0.08},
	"SilverVein": {"resource": "Silver", "amount_range": [20, 60], "rarity": 0.2},
	"MedicineHerbs": {"resource": "Herbal Medicine", "amount_range": [3, 10], "rarity": 0.25},
	"AncientDanger": {"resource": "Mixed", "amount_range": [50, 150], "rarity": 0.03},
}


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func _on_rare_tick(tick: int) -> void:
	if tick - _last_generate_tick >= GENERATE_INTERVAL:
		_last_generate_tick = tick
		_try_generate_spot()


func _try_generate_spot() -> void:
	for spot_type: String in SPOT_TYPES:
		var def: Dictionary = SPOT_TYPES[spot_type]
		if randf() < def.rarity * 0.1:
			var pos: Vector2i = Vector2i(randi_range(10, 265), randi_range(10, 265))
			var amount_range: Array = def.get("amount_range", [10, 30])
			var amount: int = randi_range(int(amount_range[0]), int(amount_range[1]))
			_spots.append({
				"type": spot_type,
				"resource": def.resource,
				"amount": amount,
				"pos": pos,
				"discovered": false,
			})
			_total_generated += 1
			break


func discover_spot(index: int) -> void:
	if index >= 0 and index < _spots.size():
		_spots[index].discovered = true


func harvest_spot(index: int) -> Dictionary:
	if index < 0 or index >= _spots.size():
		return {"success": false}
	var spot: Dictionary = _spots[index]
	_spots.remove_at(index)
	_total_harvested += 1
	_harvested_by_type[spot.type] = _harvested_by_type.get(spot.type, 0) + 1
	if ColonyLog and ColonyLog.has_method("add_entry"):
		ColonyLog.add_entry("Resource", "Harvested %s: %d %s" % [spot.type, spot.amount, spot.resource], "positive")
	return {"success": true, "resource": spot.resource, "amount": spot.amount}


func get_spots() -> Array[Dictionary]:
	return _spots


func get_richest_spot() -> Dictionary:
	var best: Dictionary = {}
	var best_amount: int = 0
	for s: Dictionary in _spots:
		if s.amount > best_amount:
			best_amount = s.amount
			best = s
	return best


func get_undiscovered_count() -> int:
	var count: int = 0
	for s: Dictionary in _spots:
		if not s.discovered:
			count += 1
	return count


func get_most_harvested_type() -> String:
	var best: String = ""
	var best_n: int = 0
	for t: String in _harvested_by_type:
		if _harvested_by_type[t] > best_n:
			best_n = _harvested_by_type[t]
			best = t
	return best


func get_harvest_rate() -> float:
	if _total_generated == 0:
		return 0.0
	return snappedf(float(_total_harvested) / float(_total_generated), 0.01)


func get_depleted_count() -> int:
	var count: int = 0
	for s: Dictionary in _spots:
		if s.get("depleted", false):
			count += 1
	return count


func get_resource_health() -> String:
	var depletion: float = float(get_depleted_count()) / maxf(float(_spots.size()), 1.0)
	if depletion == 0.0:
		return "Abundant"
	elif depletion < 0.3:
		return "Healthy"
	elif depletion < 0.6:
		return "Declining"
	return "Scarce"

func get_discovery_rate() -> float:
	if _spots.is_empty():
		return 0.0
	var discovered: int = _spots.filter(func(s: Dictionary) -> bool: return s.discovered).size()
	return snappedf(float(discovered) / float(_spots.size()) * 100.0, 0.1)

func get_exploitation_efficiency() -> float:
	if _total_generated <= 0:
		return 0.0
	return snappedf(float(_total_harvested) / float(_total_generated) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"total_spots": _spots.size(),
		"spot_types": SPOT_TYPES.size(),
		"discovered": _spots.filter(func(s: Dictionary) -> bool: return s.discovered).size(),
		"undiscovered": get_undiscovered_count(),
		"total_generated": _total_generated,
		"total_harvested": _total_harvested,
		"harvested_by_type": _harvested_by_type.duplicate(),
		"most_harvested_type": get_most_harvested_type(),
		"harvest_rate": get_harvest_rate(),
		"depleted": get_depleted_count(),
		"depletion_pct": snappedf(float(get_depleted_count()) / maxf(float(_spots.size()), 1.0) * 100.0, 0.1),
		"avg_harvest_per_spot": snappedf(float(_total_harvested) / maxf(float(_spots.size()), 1.0), 0.1),
		"resource_health": get_resource_health(),
		"discovery_rate_pct": get_discovery_rate(),
		"exploitation_efficiency": get_exploitation_efficiency(),
		"extraction_sustainability": get_extraction_sustainability(),
		"resource_security": get_resource_security(),
		"prospecting_efficiency": get_prospecting_efficiency(),
		"geological_stewardship": get_geological_stewardship(),
		"extraction_mastery": get_extraction_mastery(),
		"resource_lifecycle_health": get_resource_lifecycle_health(),
	}

func get_geological_stewardship() -> float:
	var depleted := float(get_depleted_count())
	var total := float(_spots.size())
	if total <= 0.0:
		return 0.0
	return snapped((1.0 - depleted / total) * 100.0, 0.1)

func get_extraction_mastery() -> String:
	var sustainability := get_extraction_sustainability()
	var efficiency := get_exploitation_efficiency()
	if sustainability == "Sustainable" and efficiency >= 70.0:
		return "Expert"
	elif sustainability in ["Critical", "Exhausted"]:
		return "Reckless"
	return "Adequate"

func get_resource_lifecycle_health() -> float:
	var harvest := get_harvest_rate()
	var discovery := get_discovery_rate()
	return snapped((harvest + discovery) / 2.0, 0.1)

func get_extraction_sustainability() -> String:
	var depleted := get_depleted_count()
	var total := _spots.size()
	if total <= 0:
		return "N/A"
	var depletion_ratio := float(depleted) / float(total)
	if depletion_ratio < 0.2:
		return "Sustainable"
	elif depletion_ratio < 0.5:
		return "Moderate"
	return "Depleting"

func get_resource_security() -> String:
	var undiscovered := get_undiscovered_count()
	var health := get_resource_health()
	if health in ["Abundant", "Healthy"] and undiscovered > 0:
		return "Secure"
	elif health in ["Abundant", "Healthy"]:
		return "Adequate"
	return "Vulnerable"

func get_prospecting_efficiency() -> float:
	var discovered := _spots.filter(func(s: Dictionary) -> bool: return s.discovered).size()
	if _spots.is_empty():
		return 0.0
	return snapped(float(discovered) / float(_spots.size()) * 100.0, 0.1)
