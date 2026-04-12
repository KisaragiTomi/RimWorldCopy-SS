extends Node

## Prioritizes hauling tasks: perishables, medicine, and critical resources
## get hauled before general items. Registered as autoload "HaulingPriority".

enum HaulPriority { URGENT, HIGH, NORMAL, LOW }

const PRIORITY_MAP: Dictionary = {
	"RawFood": HaulPriority.URGENT,
	"Meal": HaulPriority.URGENT,
	"SimpleMeal": HaulPriority.URGENT,
	"HerbalMed": HaulPriority.URGENT,
	"Medicine": HaulPriority.HIGH,
	"Component": HaulPriority.HIGH,
	"Steel": HaulPriority.NORMAL,
	"Wood": HaulPriority.NORMAL,
	"Silver": HaulPriority.HIGH,
	"Gold": HaulPriority.HIGH,
	"Plasteel": HaulPriority.HIGH,
	"Cloth": HaulPriority.NORMAL,
	"Leather": HaulPriority.NORMAL,
	"Beer": HaulPriority.LOW,
	"Smokeleaf": HaulPriority.LOW,
}

const PRIORITY_LABELS: PackedStringArray = ["URGENT", "HIGH", "NORMAL", "LOW"]
const SPOILABLE: PackedStringArray = ["RawFood", "Meal", "SimpleMeal", "MealFine", "MealLavish"]

var total_hauled: int = 0
var total_spoiled: int = 0


func get_priority(item_def: String) -> int:
	return int(PRIORITY_MAP.get(item_def, HaulPriority.NORMAL))


func get_priority_label(item_def: String) -> String:
	var p := get_priority(item_def)
	if p >= 0 and p < PRIORITY_LABELS.size():
		return PRIORITY_LABELS[p]
	return "NORMAL"


func sort_haul_targets(items: Array[Dictionary]) -> Array[Dictionary]:
	var sorted := items.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa: int = get_priority(a.get("def", ""))
		var pb: int = get_priority(b.get("def", ""))
		if pa != pb:
			return pa < pb
		var dist_a: float = a.get("distance", 999.0)
		var dist_b: float = b.get("distance", 999.0)
		return dist_a < dist_b
	)
	return sorted


func get_haulable_items(pawn_pos: Vector2i) -> Array[Dictionary]:
	if not ThingManager:
		return []

	var targets: Array[Dictionary] = []
	for t: Thing in ThingManager.things:
		if not (t is Item):
			continue
		var item := t as Item
		if item.state != Thing.ThingState.SPAWNED:
			continue
		var dist: float = float(pawn_pos.distance_to(item.grid_pos))
		targets.append({
			"id": item.id,
			"def": item.def_name,
			"pos": item.grid_pos,
			"distance": dist,
			"priority": get_priority(item.def_name),
		})

	return sort_haul_targets(targets)


func mark_hauled(item_def: String) -> void:
	total_hauled += 1


func mark_spoiled(item_def: String) -> void:
	total_spoiled += 1


func is_spoilable(item_def: String) -> bool:
	return item_def in SPOILABLE


func get_urgent_items(pawn_pos: Vector2i, max_count: int = 5) -> Array[Dictionary]:
	var all := get_haulable_items(pawn_pos)
	var result: Array[Dictionary] = []
	for entry: Dictionary in all:
		if entry.get("priority", HaulPriority.NORMAL) <= HaulPriority.HIGH:
			result.append(entry)
			if result.size() >= max_count:
				break
	return result


func get_spoilable_on_ground() -> int:
	var count: int = 0
	if not ThingManager:
		return count
	for t: Thing in ThingManager.things:
		if t is Item and t.state == Thing.ThingState.SPAWNED:
			if is_spoilable(t.def_name):
				count += 1
	return count


func get_spoil_rate() -> float:
	var total := total_hauled + total_spoiled
	if total == 0:
		return 0.0
	return snappedf(float(total_spoiled) / float(total), 0.01)


func get_haul_efficiency() -> float:
	var total := total_hauled + total_spoiled
	if total == 0:
		return 1.0
	return snappedf(float(total_hauled) / float(total), 0.01)


func get_urgent_count() -> int:
	var count: int = 0
	if not ThingManager:
		return count
	for t: Thing in ThingManager.things:
		if t is Item and t.state == Thing.ThingState.SPAWNED:
			if get_priority(t.def_name) <= HaulPriority.HIGH:
				count += 1
	return count


func get_spoilage_risk() -> String:
	var spoilable: int = get_spoilable_on_ground()
	if spoilable == 0:
		return "None"
	elif spoilable <= 3:
		return "Low"
	elif spoilable <= 8:
		return "Moderate"
	return "High"

func get_haul_backlog() -> int:
	if not ThingManager:
		return 0
	var count: int = 0
	for t: Thing in ThingManager.things:
		if t is Item and t.state == Thing.ThingState.SPAWNED:
			count += 1
	return count

func get_throughput_rating() -> String:
	var eff: float = get_haul_efficiency()
	if eff >= 0.9:
		return "Excellent"
	elif eff >= 0.7:
		return "Good"
	elif eff >= 0.5:
		return "Fair"
	return "Poor"

func get_logistics_health() -> String:
	var spoil := get_spoilage_risk()
	var backlog := get_haul_backlog()
	if spoil == "Safe" and backlog <= 5:
		return "Optimal"
	elif spoil == "High" or backlog > 20:
		return "Critical"
	return "Normal"

func get_waste_prevention_score() -> float:
	if total_hauled + total_spoiled <= 0:
		return 100.0
	return snapped(float(total_hauled) / float(total_hauled + total_spoiled) * 100.0, 0.1)

func get_workforce_demand() -> String:
	var urgent := get_urgent_count()
	if urgent >= 10:
		return "Desperate"
	elif urgent >= 5:
		return "High"
	elif urgent > 0:
		return "Moderate"
	return "Low"

func get_summary() -> Dictionary:
	var total := 0
	var by_priority: Dictionary = {}
	if ThingManager:
		for t: Thing in ThingManager.things:
			if t is Item and t.state == Thing.ThingState.SPAWNED:
				total += 1
				var p := get_priority_label(t.def_name)
				by_priority[p] = by_priority.get(p, 0) + 1
	return {
		"total_haulable": total,
		"by_priority": by_priority,
		"total_hauled": total_hauled,
		"total_spoiled": total_spoiled,
		"spoilable_on_ground": get_spoilable_on_ground(),
		"spoil_rate": get_spoil_rate(),
		"haul_efficiency": get_haul_efficiency(),
		"urgent_count": get_urgent_count(),
		"priority_types": by_priority.size(),
		"avg_hauls_per_item": snappedf(float(total_hauled) / maxf(float(total), 1.0), 0.01),
		"spoilage_risk": get_spoilage_risk(),
		"haul_backlog": get_haul_backlog(),
		"throughput_rating": get_throughput_rating(),
		"logistics_health": get_logistics_health(),
		"waste_prevention_score": get_waste_prevention_score(),
		"workforce_demand": get_workforce_demand(),
		"material_flow_maturity": get_material_flow_maturity(),
		"spoilage_prevention_index": get_spoilage_prevention_index(),
		"hauling_system_efficiency": get_hauling_system_efficiency(),
	}

func get_material_flow_maturity() -> String:
	var health: String = get_logistics_health()
	var throughput: String = get_throughput_rating()
	if health == "Healthy" and throughput in ["High", "Optimal"]:
		return "Optimized"
	if health in ["Healthy", "Fair"]:
		return "Functional"
	return "Chaotic"

func get_spoilage_prevention_index() -> float:
	var waste_score: float = get_waste_prevention_score()
	var spoil_rate: float = get_spoil_rate()
	var penalty: float = spoil_rate * 20.0
	return snappedf(clampf(waste_score - penalty, 0.0, 100.0), 0.1)

func get_hauling_system_efficiency() -> float:
	var efficiency: float = get_haul_efficiency()
	var backlog: int = get_haul_backlog()
	var penalty: float = float(backlog) * 2.0
	return snappedf(clampf(efficiency - penalty, 0.0, 100.0), 0.1)
