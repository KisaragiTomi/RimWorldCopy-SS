class_name Item
extends Thing

## A stackable item on the map. Extends Thing with quantity and quality.

var stack_count: int = 1
var max_stack: int = 75
var quality: int = 0  # 0=none, 1=awful..6=legendary
var forbidden: bool = false
var hauled_by: int = -1
var decay_rate: float = 0.0  # per rare_tick, 0 = no decay
var decay_progress: float = 0.0  # 0..1, at 1 item is destroyed
var is_perishable: bool = false


func _init(item_def: String = "", count: int = 1) -> void:
	super._init()
	def_name = item_def
	label = item_def
	max_stack = _get_max_stack(item_def)
	stack_count = mini(count, max_stack)
	_apply_decay_properties()


func _get_max_stack(idef: String) -> int:
	var stacks: Dictionary = {
		"Steel": 75, "Wood": 75, "Stone": 75,
		"Silver": 500, "Gold": 500,
		"Components": 25, "AdvancedComponents": 10,
		"Medicine": 25, "HerbalMedicine": 25,
		"MealSimple": 10, "MealFine": 10, "RawFood": 75,
		"Cloth": 75, "Leather": 75,
	}
	return stacks.get(idef, 75)


func _apply_decay_properties() -> void:
	var perishable: Dictionary = {
		"RawFood": 0.005,
		"Meat": 0.004,
		"Meal": 0.002,
		"MealSimple": 0.002,
		"MealFine": 0.0015,
		"NutrientPaste": 0.001,
		"HerbalMedicine": 0.001,
		"Corpse": 0.01,
		"AnimalCorpse": 0.01,
	}
	if perishable.has(def_name):
		is_perishable = true
		decay_rate = perishable[def_name]


func tick_decay(temperature: float) -> bool:
	if not is_perishable or decay_rate <= 0.0:
		return false
	var temp_factor: float = 1.0
	if temperature < 0.0:
		temp_factor = 0.0
	elif temperature < 10.0:
		temp_factor = temperature / 10.0 * 0.3
	elif temperature > 30.0:
		temp_factor = 1.0 + (temperature - 30.0) * 0.05
	decay_progress += decay_rate * temp_factor
	if decay_progress >= 1.0:
		return true
	return false


func get_freshness_percent() -> int:
	if not is_perishable:
		return 100
	return maxi(0, roundi((1.0 - decay_progress) * 100.0))


func get_freshness_label() -> String:
	var pct: int = get_freshness_percent()
	if pct >= 80:
		return "Fresh"
	elif pct >= 50:
		return "Stale"
	elif pct >= 20:
		return "Spoiling"
	return "Rotten"


func get_freshness_color() -> Color:
	if not is_perishable:
		return Color(1, 1, 1)
	var pct: float = 1.0 - decay_progress
	return Color(1.0, pct, pct * 0.5)


func is_refrigerated(temperature: float) -> bool:
	return is_perishable and temperature < 0.0


func can_merge(other: Item) -> bool:
	return other.def_name == def_name and stack_count + other.stack_count <= max_stack


func merge(other: Item) -> int:
	var space := max_stack - stack_count
	var take := mini(space, other.stack_count)
	stack_count += take
	other.stack_count -= take
	return take


func split(amount: int) -> Item:
	var take := mini(amount, stack_count)
	stack_count -= take
	var new_item := Item.new(def_name, take)
	new_item.grid_pos = grid_pos
	return new_item


func get_market_value() -> float:
	var values: Dictionary = {
		"Steel": 1.9, "Wood": 1.2, "Stone": 1.0,
		"Silver": 1.0, "Gold": 10.0,
		"Components": 32.0, "AdvancedComponents": 200.0,
		"Medicine": 18.0, "HerbalMedicine": 10.0,
		"MealSimple": 15.0, "MealFine": 25.0, "RawFood": 1.1,
		"Cloth": 1.5, "Leather": 2.1, "Plasteel": 9.0,
		"Rice": 1.1, "Corn": 1.2, "Meat": 1.3,
		"NutrientPaste": 5.0,
	}
	var base: float = values.get(def_name, 1.0)
	if is_perishable:
		base *= maxf(0.1, 1.0 - decay_progress * 0.5)
	return base * stack_count


func get_total_weight() -> float:
	var weights: Dictionary = {
		"Steel": 0.5, "Wood": 0.4, "Stone": 1.0,
		"Silver": 0.01, "Gold": 0.02,
		"Components": 0.3, "Medicine": 0.1,
		"MealSimple": 0.3, "MealFine": 0.3, "RawFood": 0.1,
	}
	return weights.get(def_name, 0.2) * stack_count


func get_quality_label() -> String:
	match quality:
		1: return "Awful"
		2: return "Poor"
		3: return "Normal"
		4: return "Good"
		5: return "Excellent"
		6: return "Legendary"
	return "N/A"


func get_stack_fill_percent() -> float:
	if max_stack <= 0:
		return 100.0
	return (float(stack_count) / float(max_stack)) * 100.0


func is_worth_hauling(min_value: float = 5.0) -> bool:
	return get_market_value() >= min_value and not forbidden and hauled_by < 0


func get_value_per_unit() -> float:
	if stack_count <= 0:
		return 0.0
	return snappedf(get_market_value() / float(stack_count), 0.01)

func get_decay_pct() -> float:
	return snappedf(decay_progress * 100.0, 0.1)

func is_full_stack() -> bool:
	return stack_count >= max_stack

func get_remaining_stack_space() -> int:
	return maxi(0, max_stack - stack_count)

func get_weight_per_unit() -> float:
	if stack_count <= 0:
		return 0.0
	return snappedf(get_total_weight() / float(stack_count), 0.001)


func get_spoilage_risk() -> String:
	if not is_perishable:
		return "None"
	if decay_progress >= 0.8:
		return "Critical"
	elif decay_progress >= 0.5:
		return "High"
	elif decay_progress >= 0.2:
		return "Moderate"
	return "Low"


func get_logistics_score() -> float:
	var value_density := get_value_per_unit() / maxf(get_weight_per_unit(), 0.01)
	var fill_bonus := get_stack_fill_percent() / 100.0
	var spoil_penalty := 1.0 - decay_progress if is_perishable else 1.0
	return snapped(value_density * fill_bonus * spoil_penalty, 0.01)

func get_storage_priority() -> int:
	var priority := 0
	if is_perishable and decay_progress >= 0.5:
		priority += 30
	elif is_perishable:
		priority += 15
	if get_market_value() > 100.0:
		priority += 20
	if stack_count < max_stack and stack_count > 0:
		priority += 10
	if forbidden:
		priority -= 50
	return priority

func get_shelf_life_days() -> float:
	if not is_perishable or decay_rate <= 0.0:
		return -1.0
	var remaining := 1.0 - decay_progress
	if remaining <= 0.0:
		return 0.0
	return snapped(remaining / decay_rate / 2.5, 0.1)

func get_item_summary() -> Dictionary:
	return {
		"def_name": def_name,
		"stack": "%d/%d" % [stack_count, max_stack],
		"quality": get_quality_label(),
		"market_value": snappedf(get_market_value(), 0.1),
		"value_per_unit": get_value_per_unit(),
		"weight": snappedf(get_total_weight(), 0.1),
		"weight_per_unit": get_weight_per_unit(),
		"freshness": get_freshness_label() if is_perishable else "N/A",
		"spoilage_risk": get_spoilage_risk(),
		"logistics_score": get_logistics_score(),
		"storage_priority": get_storage_priority(),
		"shelf_life_days": get_shelf_life_days(),
		"item_ecosystem_health": get_item_ecosystem_health(),
		"inventory_governance": get_inventory_governance(),
		"supply_maturity_index": get_supply_maturity_index(),
	}


func get_item_ecosystem_health() -> float:
	var logistics := minf(get_logistics_score() * 10.0, 100.0)
	var priority := minf(float(get_storage_priority()), 100.0)
	var freshness: float = (1.0 - decay_progress) * 100.0 if is_perishable else 100.0
	return snapped((logistics + priority + freshness) / 3.0, 0.1)

func get_inventory_governance() -> String:
	var eco := get_item_ecosystem_health()
	var mat := get_supply_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif stack_count > 0:
		return "Nascent"
	return "Dormant"

func get_supply_maturity_index() -> float:
	var fill := get_stack_fill_percent()
	var value := minf(get_value_per_unit() * 5.0, 100.0)
	var shelf := get_shelf_life_days()
	var shelf_score: float = minf(shelf * 10.0, 100.0) if shelf >= 0.0 else 100.0
	return snapped((fill + value + shelf_score) / 3.0, 0.1)

func to_dict() -> Dictionary:
	var d := super.to_dict()
	d["stack_count"] = stack_count
	d["max_stack"] = max_stack
	d["quality"] = quality
	d["forbidden"] = forbidden
	d["decay_progress"] = snappedf(decay_progress, 0.01)
	d["is_perishable"] = is_perishable
	return d
