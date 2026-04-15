extends Node

var _containers: Dictionary = {}

const CONTAINER_TYPES: Dictionary = {
	"Shelf": {"capacity": 2, "stack_mult": 1.0, "size": Vector2i(1, 2), "beauty": 0},
	"Pallet": {"capacity": 4, "stack_mult": 2.0, "size": Vector2i(2, 2), "beauty": -2},
	"Crate": {"capacity": 3, "stack_mult": 1.5, "size": Vector2i(1, 1), "beauty": -1},
	"Refrigerator": {"capacity": 2, "stack_mult": 1.0, "size": Vector2i(1, 2), "beauty": 0, "temperature": -5.0},
	"WeaponRack": {"capacity": 5, "stack_mult": 1.0, "size": Vector2i(2, 1), "beauty": 2, "item_filter": "Weapon"},
	"ToolCabinet": {"capacity": 4, "stack_mult": 1.0, "size": Vector2i(1, 1), "beauty": 1, "item_filter": "Tool"},
	"MedicineCabinet": {"capacity": 3, "stack_mult": 1.5, "size": Vector2i(1, 1), "beauty": 1, "item_filter": "Medicine"},
	"SkipContainer": {"capacity": 8, "stack_mult": 3.0, "size": Vector2i(1, 1), "beauty": 0, "power": 50}
}

const BASE_STACK_SIZE: Dictionary = {
	"Steel": 75,
	"Wood": 75,
	"Silver": 500,
	"Gold": 500,
	"Plasteel": 75,
	"ComponentIndustrial": 25,
	"ComponentSpacer": 10,
	"Medicine": 25,
	"MealSimple": 10,
	"MealFine": 10
}

func place_container(container_id: String, ctype: String, pos: Vector2i) -> Dictionary:
	if not CONTAINER_TYPES.has(ctype):
		return {"error": "unknown_type"}
	_containers[container_id] = {"type": ctype, "pos": pos, "items": [], "item_count": 0}
	return {"placed": container_id, "type": ctype, "capacity": CONTAINER_TYPES[ctype]["capacity"]}

func store_item(container_id: String, item: String, count: int) -> Dictionary:
	if not _containers.has(container_id):
		return {"error": "unknown_container"}
	var c: Dictionary = _containers[container_id]
	var ctype: Dictionary = CONTAINER_TYPES[c["type"]]
	if c["item_count"] >= ctype["capacity"]:
		return {"error": "container_full"}
	var max_stack: int = int(BASE_STACK_SIZE.get(item, 50) * ctype["stack_mult"])
	var stored: int = mini(count, max_stack)
	c["items"].append({"item": item, "count": stored})
	c["item_count"] += 1
	return {"stored": item, "count": stored, "remaining_slots": ctype["capacity"] - c["item_count"]}

func get_largest_container() -> String:
	var best: String = ""
	var best_cap: int = 0
	for ct: String in CONTAINER_TYPES:
		if CONTAINER_TYPES[ct]["capacity"] > best_cap:
			best_cap = CONTAINER_TYPES[ct]["capacity"]
			best = ct
	return best

func get_full_containers() -> Array[String]:
	var result: Array[String] = []
	for cid: String in _containers:
		var c: Dictionary = _containers[cid]
		var cap: int = CONTAINER_TYPES[c["type"]]["capacity"]
		if c["item_count"] >= cap:
			result.append(cid)
	return result

func get_powered_containers() -> Array[String]:
	var result: Array[String] = []
	for ct: String in CONTAINER_TYPES:
		if CONTAINER_TYPES[ct].has("power"):
			result.append(ct)
	return result

func get_avg_container_capacity() -> float:
	if CONTAINER_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for ct: String in CONTAINER_TYPES:
		total += float(CONTAINER_TYPES[ct].get("capacity", 0))
	return total / CONTAINER_TYPES.size()


func get_powered_container_count() -> int:
	var count: int = 0
	for ct: String in CONTAINER_TYPES:
		if bool(CONTAINER_TYPES[ct].get("requires_power", false)):
			count += 1
	return count


func get_empty_container_count() -> int:
	var count: int = 0
	for cid: int in _containers:
		if _containers[cid].get("stored", []).is_empty():
			count += 1
	return count


func get_filtered_container_count() -> int:
	var count: int = 0
	for ct: String in CONTAINER_TYPES:
		if CONTAINER_TYPES[ct].has("item_filter"):
			count += 1
	return count


func get_total_type_capacity() -> int:
	var total: int = 0
	for ct: String in CONTAINER_TYPES:
		total += int(CONTAINER_TYPES[ct].get("capacity", 0))
	return total


func get_negative_beauty_count() -> int:
	var count: int = 0
	for ct: String in CONTAINER_TYPES:
		if int(CONTAINER_TYPES[ct].get("beauty", 0)) < 0:
			count += 1
	return count


func get_storage_efficiency() -> String:
	var total: int = _containers.size()
	if total == 0:
		return "no_storage"
	var full: int = get_full_containers().size()
	var empty: int = get_empty_container_count()
	var usage: float = (total - empty) * 1.0 / total
	if usage >= 0.8:
		return "saturated"
	if usage >= 0.4:
		return "balanced"
	return "underutilized"

func get_specialization_index_pct() -> float:
	var filtered: int = get_filtered_container_count()
	if CONTAINER_TYPES.is_empty():
		return 0.0
	return snapped(filtered * 100.0 / CONTAINER_TYPES.size(), 0.1)

func get_infrastructure_cost() -> String:
	var powered: int = get_powered_container_count()
	var total: int = CONTAINER_TYPES.size()
	if total == 0:
		return "none"
	var ratio: float = powered * 1.0 / total
	if ratio >= 0.5:
		return "high_maintenance"
	if ratio >= 0.2:
		return "moderate"
	return "low_cost"

func get_summary() -> Dictionary:
	return {
		"container_types": CONTAINER_TYPES.size(),
		"stack_items": BASE_STACK_SIZE.size(),
		"active_containers": _containers.size(),
		"largest_container": get_largest_container(),
		"full_count": get_full_containers().size(),
		"avg_capacity": snapped(get_avg_container_capacity(), 0.1),
		"powered_types": get_powered_container_count(),
		"empty": get_empty_container_count(),
		"filtered_types": get_filtered_container_count(),
		"total_type_capacity": get_total_type_capacity(),
		"negative_beauty": get_negative_beauty_count(),
		"storage_efficiency": get_storage_efficiency(),
		"specialization_index_pct": get_specialization_index_pct(),
		"infrastructure_cost": get_infrastructure_cost(),
		"warehouse_capacity_score": get_warehouse_capacity_score(),
		"organization_quality": get_organization_quality(),
		"storage_scalability": get_storage_scalability(),
		"storage_ecosystem_health": get_storage_ecosystem_health(),
		"warehouse_governance": get_warehouse_governance(),
		"logistics_maturity_index": get_logistics_maturity_index(),
	}

func get_warehouse_capacity_score() -> float:
	var total := get_total_type_capacity()
	var containers := _containers.size()
	if containers <= 0:
		return 0.0
	return snapped(float(total) / float(containers), 0.1)

func get_organization_quality() -> String:
	var filtered := get_filtered_container_count()
	var total := _containers.size()
	if total <= 0:
		return "No Storage"
	var ratio := float(filtered) / float(total)
	if ratio >= 0.7:
		return "Meticulous"
	elif ratio >= 0.3:
		return "Organized"
	return "Chaotic"

func get_storage_scalability() -> String:
	var empty := get_empty_container_count()
	var total := _containers.size()
	if total <= 0:
		return "No Storage"
	if float(empty) / float(total) >= 0.3:
		return "Expandable"
	elif empty > 0:
		return "Tight"
	return "Full"

func get_storage_ecosystem_health() -> float:
	var efficiency := get_storage_efficiency()
	var e_val: float = 90.0 if efficiency in ["optimal", "efficient"] else (60.0 if efficiency in ["moderate", "adequate"] else 30.0)
	var quality := get_organization_quality()
	var q_val: float = 90.0 if quality == "Meticulous" else (60.0 if quality == "Organized" else 30.0)
	var capacity := get_warehouse_capacity_score()
	return snapped((e_val + q_val + minf(capacity, 100.0)) / 3.0, 0.1)

func get_logistics_maturity_index() -> float:
	var scalability := get_storage_scalability()
	var s_val: float = 90.0 if scalability == "Expandable" else (60.0 if scalability == "Tight" else 30.0)
	var specialization := get_specialization_index_pct()
	var cost := get_infrastructure_cost()
	var c_val: float = 90.0 if cost == "none" else (70.0 if cost in ["low", "minimal"] else (40.0 if cost in ["moderate", "medium"] else 20.0))
	return snapped((s_val + specialization + c_val) / 3.0, 0.1)

func get_warehouse_governance() -> String:
	var ecosystem := get_storage_ecosystem_health()
	var maturity := get_logistics_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _containers.size() > 0:
		return "Nascent"
	return "Dormant"
