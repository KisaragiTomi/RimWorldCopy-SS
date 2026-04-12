extends Node

## Handles animal product collection: milking, shearing, and egg gathering.
## Tamed animals produce resources on a schedule.
## Registered as autoload "AnimalProducts".

const PRODUCT_DEFS: Dictionary = {
	"Cow": {
		"products": [{"type": "Milk", "amount": 12, "interval_ticks": 2500}],
	},
	"Muffalo": {
		"products": [{"type": "MuffaloWool", "amount": 60, "interval_ticks": 7500}],
	},
	"Chicken": {
		"products": [{"type": "Egg", "amount": 1, "interval_ticks": 1500}],
	},
	"Alpaca": {
		"products": [{"type": "AlpacaWool", "amount": 50, "interval_ticks": 7500}],
	},
	"Dromedary": {
		"products": [{"type": "CamelMilk", "amount": 8, "interval_ticks": 3000}],
	},
}

var _timers: Dictionary = {}  # animal_id -> {last_collected_tick, product_def}
var _total_collected: Dictionary = {}  # product_type -> total_amount
var total_collections: int = 0


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func register_animal(animal_id: int, species: String) -> void:
	if not PRODUCT_DEFS.has(species):
		return
	_timers[animal_id] = {
		"species": species,
		"last_collected_tick": TickManager.current_tick if TickManager else 0,
	}


func unregister_animal(animal_id: int) -> void:
	_timers.erase(animal_id)


func _on_rare_tick(_tick: int) -> void:
	_check_production()


func _check_production() -> void:
	var current_tick: int = TickManager.current_tick if TickManager else 0

	for aid: int in _timers:
		var timer: Dictionary = _timers[aid]
		var species: String = timer.species
		if not PRODUCT_DEFS.has(species):
			continue

		var products: Array = PRODUCT_DEFS[species].products
		for prod: Dictionary in products:
			var interval: int = prod.get("interval_ticks", 5000)
			var elapsed: int = current_tick - timer.get("last_collected_tick", 0)
			if elapsed >= interval:
				_collect_product(aid, prod)
				timer.last_collected_tick = current_tick


func _collect_product(animal_id: int, product: Dictionary) -> void:
	var ptype: String = product.get("type", "")
	var amount: int = product.get("amount", 1)

	_total_collected[ptype] = _total_collected.get(ptype, 0) + amount
	total_collections += 1

	if ThingManager and ThingManager.has_method("spawn_item"):
		var pos := Vector2i(128, 128)
		if AnimalManager:
			for a: Animal in AnimalManager.animals:
				if a.id == animal_id:
					pos = a.grid_pos
					break
		ThingManager.spawn_item(ptype, amount, pos)

	if ColonyLog:
		ColonyLog.add_entry("Animals", "Collected %d %s from animal #%d." % [amount, ptype, animal_id], "info")


func can_produce(species: String) -> bool:
	return PRODUCT_DEFS.has(species)


func get_products_for(species: String) -> Array:
	if not PRODUCT_DEFS.has(species):
		return []
	return PRODUCT_DEFS[species].get("products", [])


func get_production_rate() -> Dictionary:
	var rates: Dictionary = {}
	for aid: int in _timers:
		var species: String = _timers[aid].species
		if not PRODUCT_DEFS.has(species):
			continue
		for prod: Dictionary in PRODUCT_DEFS[species].products:
			var ptype: String = prod.get("type", "")
			var amount: int = prod.get("amount", 0)
			rates[ptype] = rates.get(ptype, 0) + amount
	return rates


func get_most_produced() -> String:
	var best: String = ""
	var best_count: int = 0
	for ptype: String in _total_collected:
		if _total_collected[ptype] > best_count:
			best_count = _total_collected[ptype]
			best = ptype
	return best


func get_animals_by_species() -> Dictionary:
	var result: Dictionary = {}
	for aid: int in _timers:
		var sp: String = _timers[aid].species
		result[sp] = result.get(sp, 0) + 1
	return result


func get_avg_collection_rate() -> float:
	if not TickManager or TickManager.current_tick <= 0:
		return 0.0
	return snappedf(float(total_collections) / float(TickManager.current_tick) * 60000.0, 0.01)


func get_total_value_produced() -> float:
	var total: float = 0.0
	var value_map: Dictionary = {"Milk": 1.5, "MuffaloWool": 2.0, "Egg": 3.0, "AlpacaWool": 2.5, "CamelMilk": 1.8}
	for ptype: String in _total_collected:
		total += float(_total_collected[ptype]) * value_map.get(ptype, 1.0)
	return snappedf(total, 0.1)


func get_idle_producers() -> int:
	var count: int = 0
	var current_tick: int = TickManager.current_tick if TickManager else 0
	for aid: int in _timers:
		var timer: Dictionary = _timers[aid]
		var species: String = timer.species
		if not PRODUCT_DEFS.has(species):
			continue
		var products: Array = PRODUCT_DEFS[species].products
		var all_ready: bool = true
		for prod: Dictionary in products:
			var elapsed: int = current_tick - timer.get("last_collected_tick", 0)
			if elapsed < prod.get("interval_ticks", 5000):
				all_ready = false
				break
		if all_ready:
			count += 1
	return count


func get_herd_productivity() -> String:
	var rates: Dictionary = get_production_rate()
	var total_rate: float = 0.0
	for key: String in rates:
		total_rate += float(rates[key])
	var normalized: float = total_rate / maxf(float(_timers.size()), 1.0)
	if normalized >= 0.8:
		return "Excellent"
	elif normalized >= 0.5:
		return "Good"
	elif normalized > 0.0:
		return "Low"
	return "None"

func get_avg_value_per_animal() -> float:
	if _timers.is_empty():
		return 0.0
	return snappedf(get_total_value_produced() / float(_timers.size()), 0.1)

func get_species_diversity_score() -> float:
	var species: Dictionary = get_animals_by_species()
	if species.is_empty() or PRODUCT_DEFS.is_empty():
		return 0.0
	return snappedf(float(species.size()) / float(PRODUCT_DEFS.size()) * 100.0, 0.1)

func get_pastoral_economy() -> String:
	var value := get_total_value_produced()
	var productivity := get_herd_productivity()
	if value > 500.0 and productivity == "Excellent":
		return "Thriving"
	elif value > 100.0:
		return "Active"
	return "Subsistence"

func get_yield_optimization() -> float:
	var avg_val := get_avg_value_per_animal()
	var rates: Dictionary = get_production_rate()
	var total_rate: float = 0.0
	for key: String in rates:
		total_rate += float(rates[key])
	return snapped(avg_val * total_rate / maxf(float(_timers.size()), 1.0), 0.1)

func get_livestock_investment_score() -> String:
	var species := get_species_diversity_score()
	var economy := get_pastoral_economy()
	if species >= 50.0 and economy == "Thriving":
		return "High Return"
	elif species >= 20.0:
		return "Moderate Return"
	return "Low Return"

func get_summary() -> Dictionary:
	return {
		"tracked_animals": _timers.size(),
		"total_collected": _total_collected.duplicate(),
		"total_collections": total_collections,
		"producing_species": PRODUCT_DEFS.size(),
		"by_species": get_animals_by_species(),
		"most_produced": get_most_produced(),
		"production_rate": get_production_rate(),
		"collection_rate_per_day": get_avg_collection_rate(),
		"total_value": get_total_value_produced(),
		"value_per_collection": snappedf(get_total_value_produced() / maxf(float(total_collections), 1.0), 0.1),
		"unique_products": _total_collected.size(),
		"herd_productivity": get_herd_productivity(),
		"avg_value_per_animal": get_avg_value_per_animal(),
		"species_diversity_pct": get_species_diversity_score(),
		"pastoral_economy": get_pastoral_economy(),
		"yield_optimization": get_yield_optimization(),
		"livestock_investment": get_livestock_investment_score(),
		"pastoral_sustainability": get_pastoral_sustainability(),
		"production_pipeline_health": get_production_pipeline_health(),
		"husbandry_mastery": get_husbandry_mastery(),
	}

func get_pastoral_sustainability() -> float:
	var diversity := get_species_diversity_score()
	var optimization := get_yield_optimization()
	var animals := float(_timers.size())
	if animals <= 0.0:
		return 0.0
	return snapped((diversity + optimization) / 2.0, 0.1)

func get_production_pipeline_health() -> String:
	var economy := get_pastoral_economy()
	var productivity := get_herd_productivity()
	if economy == "Thriving" and productivity == "Excellent":
		return "Optimal"
	elif economy != "Subsistence":
		return "Functional"
	return "Fragile"

func get_husbandry_mastery() -> float:
	var avg_val := get_avg_value_per_animal()
	var invest := get_livestock_investment_score()
	var base: float = avg_val * 2.0
	if invest == "High Return":
		base *= 1.5
	elif invest == "Moderate Return":
		base *= 1.0
	else:
		base *= 0.5
	return snapped(base, 0.1)
