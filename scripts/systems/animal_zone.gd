extends Node

var _zones: Dictionary = {}
var _animal_assignments: Dictionary = {}
var _next_id: int = 1


func create_zone(zone_name: String, cells: Array) -> int:
	var zid: int = _next_id
	_next_id += 1
	_zones[zid] = {"name": zone_name, "cells": cells}
	return zid


func remove_zone(zone_id: int) -> void:
	_zones.erase(zone_id)
	var to_remove: Array = []
	for animal_id: int in _animal_assignments:
		if int(_animal_assignments[animal_id]) == zone_id:
			to_remove.append(animal_id)
	for aid: int in to_remove:
		_animal_assignments.erase(aid)


func assign_animal(animal_id: int, zone_id: int) -> bool:
	if not _zones.has(zone_id):
		return false
	_animal_assignments[animal_id] = zone_id
	return true


func unassign_animal(animal_id: int) -> void:
	_animal_assignments.erase(animal_id)


func get_animal_zone(animal_id: int) -> int:
	return int(_animal_assignments.get(animal_id, -1))


func is_in_zone(animal_id: int, pos: Vector2i) -> bool:
	var zid: int = get_animal_zone(animal_id)
	if zid < 0:
		return true
	var zone: Dictionary = _zones.get(zid, {})
	var cells: Array = zone.get("cells", [])
	return cells.has(pos)


func get_zone_info(zone_id: int) -> Dictionary:
	return _zones.get(zone_id, {})


func get_animals_in_zone(zone_id: int) -> Array[int]:
	var result: Array[int] = []
	for animal_id: int in _animal_assignments:
		if int(_animal_assignments[animal_id]) == zone_id:
			result.append(animal_id)
	return result


func get_unassigned_animals() -> Array[int]:
	if not AnimalManager:
		return []
	var result: Array[int] = []
	if AnimalManager.has_method("get_all_tamed"):
		var tamed: Array = AnimalManager.get_all_tamed()
		for a in tamed:
			if a is Animal and not _animal_assignments.has(a.id):
				result.append(a.id)
	return result


func get_zone_sizes() -> Dictionary:
	var result: Dictionary = {}
	for zid: int in _zones:
		var zone: Dictionary = _zones[zid]
		result[zone.get("name", str(zid))] = zone.get("cells", []).size()
	return result


func get_largest_zone() -> String:
	var sizes := get_zone_sizes()
	var best: String = ""
	var best_n: int = 0
	for zname: String in sizes:
		if sizes[zname] > best_n:
			best_n = sizes[zname]
			best = zname
	return best


func get_unassigned_animal_count() -> int:
	return get_unassigned_animals().size()


func get_avg_animals_per_zone() -> float:
	if _zones.is_empty():
		return 0.0
	return snappedf(float(_animal_assignments.size()) / float(_zones.size()), 0.1)


func get_containment_rating() -> String:
	var unassigned: int = get_unassigned_animal_count()
	if unassigned == 0:
		return "Full"
	elif unassigned <= 2:
		return "Mostly Contained"
	return "Loose"

func get_zone_efficiency() -> float:
	if _zones.is_empty():
		return 0.0
	var used: int = 0
	for zid: String in _zones:
		var count: int = 0
		for aid: int in _animal_assignments:
			if _animal_assignments[aid] == zid:
				count += 1
		if count > 0:
			used += 1
	return snappedf(float(used) / float(_zones.size()) * 100.0, 0.1)

func get_crowding_risk() -> String:
	var avg: float = get_avg_animals_per_zone()
	if avg >= 8.0:
		return "Overcrowded"
	elif avg >= 4.0:
		return "Moderate"
	elif avg > 0.0:
		return "Spacious"
	return "Empty"

func get_summary() -> Dictionary:
	return {
		"zone_count": _zones.size(),
		"assigned_animals": _animal_assignments.size(),
		"zone_sizes": get_zone_sizes(),
		"largest_zone": get_largest_zone(),
		"unassigned": get_unassigned_animal_count(),
		"avg_per_zone": get_avg_animals_per_zone(),
		"unassigned_pct": snappedf(float(get_unassigned_animal_count()) / maxf(float(_animal_assignments.size() + get_unassigned_animal_count()), 1.0) * 100.0, 0.1),
		"zone_utilization": snappedf(float(_animal_assignments.size()) / maxf(float(_zones.size()), 1.0), 0.1),
		"containment_rating": get_containment_rating(),
		"zone_efficiency_pct": get_zone_efficiency(),
		"crowding_risk": get_crowding_risk(),
		"habitat_management": get_habitat_management(),
		"animal_welfare_index": get_animal_welfare_index(),
		"zone_optimization": get_zone_optimization(),
		"husbandry_infrastructure": get_husbandry_infrastructure(),
		"territorial_governance": get_territorial_governance(),
		"livestock_welfare_ecosystem": get_livestock_welfare_ecosystem(),
	}

func get_husbandry_infrastructure() -> float:
	var efficiency := get_zone_efficiency()
	var welfare := get_animal_welfare_index()
	return snapped((efficiency + welfare) / 2.0, 0.1)

func get_territorial_governance() -> String:
	var management := get_habitat_management()
	var crowding := get_crowding_risk()
	if management == "Well Managed" and crowding in ["Low", "None"]:
		return "Optimal"
	elif management == "Neglected" or crowding == "Critical":
		return "Chaotic"
	return "Adequate"

func get_livestock_welfare_ecosystem() -> float:
	var unassigned := float(get_unassigned_animal_count())
	var total := float(_animal_assignments.size() + get_unassigned_animal_count())
	if total <= 0.0:
		return 100.0
	return snapped((1.0 - unassigned / total) * get_animal_welfare_index(), 0.1)

func get_habitat_management() -> String:
	var containment := get_containment_rating()
	var efficiency := get_zone_efficiency()
	if containment in ["Secure", "Tight"] and efficiency >= 70.0:
		return "Well Managed"
	elif efficiency >= 40.0:
		return "Adequate"
	return "Needs Attention"

func get_animal_welfare_index() -> float:
	var crowding := get_crowding_risk()
	var unassigned_pct := snappedf(float(get_unassigned_animal_count()) / maxf(float(_animal_assignments.size() + get_unassigned_animal_count()), 1.0) * 100.0, 0.1)
	var base := 50.0
	match crowding:
		"Spacious":
			base = 90.0
		"Moderate":
			base = 65.0
		"Overcrowded":
			base = 30.0
	return snapped(base - unassigned_pct * 0.3, 0.1)

func get_zone_optimization() -> String:
	var efficiency := get_zone_efficiency()
	var avg := get_avg_animals_per_zone()
	if efficiency >= 80.0 and avg >= 1.0 and avg <= 6.0:
		return "Optimal"
	elif efficiency >= 50.0:
		return "Satisfactory"
	return "Suboptimal"
