extends Node

const LAYERS: Dictionary = {
	"Underwear": {"order": 0, "covers": ["Torso", "Legs"]},
	"Middle": {"order": 1, "covers": ["Torso", "Legs", "Arms"]},
	"Outer": {"order": 2, "covers": ["Torso", "Legs", "Arms"]},
	"Head": {"order": 3, "covers": ["Head"]},
	"Belt": {"order": 4, "covers": ["Waist"]},
}

var _pawn_gear: Dictionary = {}


func equip(pawn_id: int, item_id: String, layer: String) -> Dictionary:
	if not LAYERS.has(layer):
		return {"success": false, "reason": "Invalid layer"}
	if not _pawn_gear.has(pawn_id):
		_pawn_gear[pawn_id] = {}
	var prev: String = String(_pawn_gear[pawn_id].get(layer, ""))
	_pawn_gear[pawn_id][layer] = item_id
	return {"success": true, "replaced": prev}


func unequip(pawn_id: int, layer: String) -> String:
	if not _pawn_gear.has(pawn_id):
		return ""
	var item: String = String(_pawn_gear[pawn_id].get(layer, ""))
	if _pawn_gear.has(pawn_id) and _pawn_gear[pawn_id].has(layer):
		_pawn_gear[pawn_id].erase(layer)
	return item


func get_all_gear(pawn_id: int) -> Dictionary:
	return _pawn_gear.get(pawn_id, {})


func get_total_armor(pawn_id: int) -> float:
	var gear: Dictionary = get_all_gear(pawn_id)
	return float(gear.size()) * 5.0


func get_covered_parts(pawn_id: int) -> Array:
	var gear: Dictionary = get_all_gear(pawn_id)
	var parts: Array = []
	for layer: String in gear:
		if LAYERS.has(layer):
			for p in LAYERS[layer].covers:
				if not parts.has(p):
					parts.append(p)
	return parts


func get_empty_slots(pawn_id: int) -> Array[String]:
	var gear: Dictionary = get_all_gear(pawn_id)
	var empty: Array[String] = []
	for layer: String in LAYERS:
		if not gear.has(layer) or String(gear[layer]).is_empty():
			empty.append(layer)
	return empty


func get_fully_equipped_count() -> int:
	var count: int = 0
	for pid: int in _pawn_gear:
		if _pawn_gear[pid].size() >= LAYERS.size():
			count += 1
	return count


func get_coverage_percent(pawn_id: int) -> float:
	var gear: Dictionary = get_all_gear(pawn_id)
	if LAYERS.size() == 0:
		return 0.0
	return snappedf(float(gear.size()) / float(LAYERS.size()) * 100.0, 0.1)


func get_avg_coverage() -> float:
	if _pawn_gear.is_empty():
		return 0.0
	var total: float = 0.0
	for pid: int in _pawn_gear:
		total += get_coverage_percent(pid)
	return snappedf(total / float(_pawn_gear.size()), 0.1)


func get_most_empty_layer() -> String:
	var layer_filled: Dictionary = {}
	for layer: String in LAYERS:
		layer_filled[layer] = 0
	for pid: int in _pawn_gear:
		for layer: String in _pawn_gear[pid]:
			layer_filled[layer] = layer_filled.get(layer, 0) + 1
	var worst: String = ""
	var worst_n: int = 99999
	for layer: String in layer_filled:
		if layer_filled[layer] < worst_n:
			worst_n = layer_filled[layer]
			worst = layer
	return worst


func get_naked_pawn_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var pid: int = p.pawn_id if "pawn_id" in p else 0
		if not _pawn_gear.has(pid) or _pawn_gear[pid].is_empty():
			count += 1
	return count


func get_equip_rate_pct() -> float:
	if not PawnManager:
		return 0.0
	var alive: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			alive += 1
	if alive == 0:
		return 0.0
	var equipped: int = 0
	for pid: int in _pawn_gear:
		if not _pawn_gear[pid].is_empty():
			equipped += 1
	return snappedf(float(equipped) / float(alive) * 100.0, 0.1)


func get_empty_layer_type_count() -> int:
	var filled_layers: Dictionary = {}
	for pid: int in _pawn_gear:
		for layer: String in _pawn_gear[pid]:
			filled_layers[layer] = true
	var empty_count: int = 0
	for layer: String in LAYERS:
		if not filled_layers.has(layer):
			empty_count += 1
	return empty_count


func get_avg_items_per_layer() -> float:
	if _pawn_gear.is_empty():
		return 0.0
	var layer_counts: Dictionary = {}
	for layer: String in LAYERS:
		layer_counts[layer] = 0
	for pid: int in _pawn_gear:
		for layer: String in _pawn_gear[pid]:
			layer_counts[layer] = layer_counts.get(layer, 0) + 1
	var total: int = 0
	for layer: String in layer_counts:
		total += int(layer_counts[layer])
	return snappedf(float(total) / float(LAYERS.size()), 0.1)


func get_summary() -> Dictionary:
	return {
		"layer_count": LAYERS.size(),
		"equipped_pawns": _pawn_gear.size(),
		"fully_equipped": get_fully_equipped_count(),
		"avg_coverage_pct": get_avg_coverage(),
		"most_empty_layer": get_most_empty_layer(),
		"naked_pawns": get_naked_pawn_count(),
		"equip_rate_pct": get_equip_rate_pct(),
		"empty_layer_types": get_empty_layer_type_count(),
		"avg_items_per_layer": get_avg_items_per_layer(),
		"coverage_rating": get_coverage_rating(),
		"conflict_density_pct": get_conflict_density_pct(),
		"versatility_pct": get_versatility_pct(),
		"wardrobe_completeness": get_wardrobe_completeness(),
		"protection_balance": get_protection_balance(),
		"layering_efficiency": get_layering_efficiency(),
		"armor_ecosystem_health": get_armor_ecosystem_health(),
		"defensive_readiness_index": get_defensive_readiness_index(),
		"equipment_governance": get_equipment_governance(),
	}

func get_coverage_rating() -> String:
	var avg := get_avg_coverage()
	if avg >= 80.0:
		return "Well Covered"
	elif avg >= 50.0:
		return "Partial"
	elif avg > 0.0:
		return "Sparse"
	return "None"

func get_conflict_density_pct() -> float:
	var naked := get_naked_pawn_count()
	var total := _pawn_gear.size() + naked
	if total <= 0:
		return 0.0
	return snapped(float(naked) / float(total) * 100.0, 0.1)

func get_versatility_pct() -> float:
	var equipped_layers := LAYERS.size() - get_empty_layer_type_count()
	if LAYERS.is_empty():
		return 0.0
	return snapped(float(equipped_layers) / float(LAYERS.size()) * 100.0, 0.1)

func get_wardrobe_completeness() -> String:
	var rate := get_equip_rate_pct()
	var coverage := get_avg_coverage()
	if rate >= 90.0 and coverage >= 70.0:
		return "Complete"
	elif rate >= 60.0:
		return "Adequate"
	return "Incomplete"

func get_protection_balance() -> String:
	var empty := get_empty_layer_type_count()
	if empty == 0:
		return "Balanced"
	elif empty <= LAYERS.size() / 3:
		return "Minor Gaps"
	return "Exposed"

func get_layering_efficiency() -> float:
	var avg_items := get_avg_items_per_layer()
	var coverage := get_avg_coverage()
	return snapped((avg_items * 20.0 + coverage) / 2.0, 0.1)

func get_armor_ecosystem_health() -> float:
	var coverage := get_avg_coverage()
	var efficiency := get_layering_efficiency()
	var conflict := get_conflict_density_pct()
	return snapped((coverage + efficiency + maxf(100.0 - conflict, 0.0)) / 3.0, 0.1)

func get_defensive_readiness_index() -> float:
	var equipped := get_fully_equipped_count()
	var total := _pawn_gear.size()
	if total <= 0:
		return 0.0
	var ratio := float(equipped) / float(total) * 100.0
	var versatility := get_versatility_pct()
	return snapped((ratio + versatility) / 2.0, 0.1)

func get_equipment_governance() -> String:
	var health := get_armor_ecosystem_health()
	var readiness := get_defensive_readiness_index()
	if health >= 70.0 and readiness >= 70.0:
		return "Well Governed"
	elif health >= 40.0 or readiness >= 40.0:
		return "Partial"
	return "Ungoverned"
