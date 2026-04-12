extends Node

var _presets: Dictionary = {}
var _pawn_loadouts: Dictionary = {}
var _next_id: int = 1


func create_preset(preset_name: String, gear: Dictionary) -> int:
	var pid: int = _next_id
	_next_id += 1
	_presets[pid] = {"name": preset_name, "gear": gear}
	return pid


func delete_preset(preset_id: int) -> void:
	_presets.erase(preset_id)


func assign_loadout(pawn_id: int, preset_id: int) -> bool:
	if not _presets.has(preset_id):
		return false
	_pawn_loadouts[pawn_id] = preset_id
	return true


func get_pawn_loadout(pawn_id: int) -> Dictionary:
	var pid: int = int(_pawn_loadouts.get(pawn_id, -1))
	if pid < 0 or not _presets.has(pid):
		return {}
	return _presets[pid]


func get_all_presets() -> Dictionary:
	return _presets.duplicate()


func create_default_presets() -> void:
	create_preset("Soldier", {"Outer": "FlakVest", "Head": "FlakHelmet", "Belt": "Pistol"})
	create_preset("Worker", {"Outer": "Jacket", "Head": "Cowboy Hat"})
	create_preset("Doctor", {"Middle": "Labcoat", "Head": "None"})
	create_preset("Crafter", {"Middle": "Apron", "Head": "None"})


func get_unassigned_pawns(all_pawn_ids: Array) -> Array:
	var result: Array = []
	for pid in all_pawn_ids:
		if not _pawn_loadouts.has(int(pid)):
			result.append(pid)
	return result


func get_preset_usage() -> Dictionary:
	var usage: Dictionary = {}
	for pawn_id: int in _pawn_loadouts:
		var preset_id: int = int(_pawn_loadouts[pawn_id])
		var pname: String = String(_presets.get(preset_id, {}).get("name", "Unknown"))
		usage[pname] = usage.get(pname, 0) + 1
	return usage


func rename_preset(preset_id: int, new_name: String) -> bool:
	if not _presets.has(preset_id):
		return false
	_presets[preset_id]["name"] = new_name
	return true


func get_most_popular_preset() -> String:
	var usage := get_preset_usage()
	var best: String = ""
	var best_n: int = 0
	for p: String in usage:
		if usage[p] > best_n:
			best_n = usage[p]
			best = p
	return best


func get_unused_preset_count() -> int:
	var usage := get_preset_usage()
	return maxi(_presets.size() - usage.size(), 0)


func get_coverage_pct() -> float:
	if not PawnManager:
		return 0.0
	var alive: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			alive += 1
	if alive == 0:
		return 0.0
	return snappedf(float(_pawn_loadouts.size()) / float(alive) * 100.0, 0.1)


func get_unique_used_preset_count() -> int:
	var used: Dictionary = {}
	for pawn_id: int in _pawn_loadouts:
		used[_pawn_loadouts[pawn_id]] = true
	return used.size()


func get_avg_pawns_per_preset() -> float:
	var used: int = get_unique_used_preset_count()
	if used == 0:
		return 0.0
	return snappedf(float(_pawn_loadouts.size()) / float(used), 0.1)


func get_assignment_rate_pct() -> float:
	return get_coverage_pct()


func get_loadout_health() -> String:
	var unused: int = get_unused_preset_count()
	if unused == 0:
		return "Optimal"
	elif unused <= 2:
		return "Good"
	elif unused <= _presets.size() / 2:
		return "Wasteful"
	return "Poor"

func get_standardization_pct() -> float:
	if _pawn_loadouts.is_empty():
		return 0.0
	var usage: Dictionary = get_preset_usage()
	var max_used: int = 0
	for pid: String in usage:
		if usage[pid] > max_used:
			max_used = usage[pid]
	return snappedf(float(max_used) / float(_pawn_loadouts.size()) * 100.0, 0.1)

func get_flexibility_score() -> float:
	if _presets.is_empty():
		return 0.0
	return snappedf(float(get_unique_used_preset_count()) / float(_presets.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"preset_count": _presets.size(),
		"assigned_pawns": _pawn_loadouts.size(),
		"usage": get_preset_usage(),
		"most_popular": get_most_popular_preset(),
		"unused_presets": get_unused_preset_count(),
		"coverage_pct": get_coverage_pct(),
		"unique_used_presets": get_unique_used_preset_count(),
		"avg_pawns_per_preset": get_avg_pawns_per_preset(),
		"assignment_rate_pct": get_assignment_rate_pct(),
		"loadout_health": get_loadout_health(),
		"standardization_pct": get_standardization_pct(),
		"flexibility_pct": get_flexibility_score(),
		"equipment_readiness": get_equipment_readiness(),
		"loadout_diversity": get_loadout_diversity(),
		"allocation_efficiency": get_allocation_efficiency(),
		"loadout_ecosystem_health": get_loadout_ecosystem_health(),
		"tactical_readiness_index": get_tactical_readiness_index(),
		"logistical_maturity": get_logistical_maturity(),
	}

func get_equipment_readiness() -> String:
	var health := get_loadout_health()
	var coverage := get_coverage_pct()
	if health in ["Good", "Excellent"] and coverage >= 80.0:
		return "Combat Ready"
	elif coverage >= 50.0:
		return "Partially Equipped"
	return "Underprepared"

func get_loadout_diversity() -> float:
	var unique := get_unique_used_preset_count()
	var total := _presets.size()
	if total <= 0:
		return 0.0
	return snapped(float(unique) / float(total) * 100.0, 0.1)

func get_allocation_efficiency() -> String:
	var unused := get_unused_preset_count()
	var total := _presets.size()
	if total <= 0:
		return "N/A"
	var waste_pct := float(unused) / float(total) * 100.0
	if waste_pct <= 10.0:
		return "Efficient"
	elif waste_pct <= 40.0:
		return "Moderate"
	return "Wasteful"

func get_loadout_ecosystem_health() -> float:
	var diversity := get_loadout_diversity()
	var coverage := get_coverage_pct()
	var allocation := get_allocation_efficiency()
	var alloc_val: float = 90.0 if allocation == "Efficient" else (60.0 if allocation == "Moderate" else 30.0)
	return snapped((diversity + coverage + alloc_val) / 3.0, 0.1)

func get_tactical_readiness_index() -> float:
	var readiness := get_equipment_readiness()
	var readiness_val: float = 90.0 if readiness == "Combat Ready" else (50.0 if readiness == "Partially Equipped" else 20.0)
	var standardization := get_standardization_pct()
	return snapped((readiness_val + standardization) / 2.0, 0.1)

func get_logistical_maturity() -> String:
	var health := get_loadout_ecosystem_health()
	var tactical := get_tactical_readiness_index()
	if health >= 70.0 and tactical >= 65.0:
		return "Advanced"
	elif health >= 40.0 or tactical >= 35.0:
		return "Developing"
	return "Rudimentary"
