extends Node

const PROSTHETICS: Dictionary = {
	"PegLeg": {"part": "Leg", "efficiency": 0.6, "cost": {"Wood": 30}, "tech_required": ""},
	"DentureLeg": {"part": "Leg", "efficiency": 0.5, "cost": {"Wood": 20}, "tech_required": ""},
	"SimpleProstheticLeg": {"part": "Leg", "efficiency": 0.85, "cost": {"Steel": 30, "Component": 2}, "tech_required": "Prosthetics"},
	"SimpleProstheticArm": {"part": "Arm", "efficiency": 0.85, "cost": {"Steel": 30, "Component": 2}, "tech_required": "Prosthetics"},
	"BionicLeg": {"part": "Leg", "efficiency": 1.25, "cost": {"Plasteel": 15, "Component": 4}, "tech_required": "Bionics"},
	"BionicArm": {"part": "Arm", "efficiency": 1.25, "cost": {"Plasteel": 15, "Component": 4}, "tech_required": "Bionics"},
	"BionicEye": {"part": "Eye", "efficiency": 1.5, "cost": {"Plasteel": 10, "Component": 3}, "tech_required": "Bionics"},
	"BionicEar": {"part": "Ear", "efficiency": 1.5, "cost": {"Plasteel": 8, "Component": 2}, "tech_required": "Bionics"},
	"ArchotechLeg": {"part": "Leg", "efficiency": 1.5, "cost": {}, "tech_required": "Archotech"},
	"ArchotechArm": {"part": "Arm", "efficiency": 1.5, "cost": {}, "tech_required": "Archotech"},
	"ArchotechEye": {"part": "Eye", "efficiency": 2.0, "cost": {}, "tech_required": "Archotech"},
}

var _installed: Dictionary = {}


func install_prosthetic(pawn_id: int, prosthetic_id: String) -> Dictionary:
	if not PROSTHETICS.has(prosthetic_id):
		return {"success": false, "reason": "Unknown prosthetic"}
	var data: Dictionary = PROSTHETICS[prosthetic_id]
	if not _installed.has(pawn_id):
		_installed[pawn_id] = []
	_installed[pawn_id].append({
		"id": prosthetic_id,
		"part": data.part,
		"efficiency": data.efficiency,
	})
	if ColonyLog and ColonyLog.has_method("add_entry"):
		ColonyLog.add_entry("Medical", "Installed " + prosthetic_id + " on pawn " + str(pawn_id), "info")
	return {"success": true, "prosthetic": prosthetic_id, "efficiency": data.efficiency}


func get_pawn_prosthetics(pawn_id: int) -> Array:
	return _installed.get(pawn_id, [])


func get_efficiency_modifier(pawn_id: int, part_type: String) -> float:
	var prosthetics: Array = get_pawn_prosthetics(pawn_id)
	var best: float = 0.0
	for p in prosthetics:
		var pd: Dictionary = p if p is Dictionary else {}
		if pd.get("part", "") == part_type:
			best = maxf(best, float(pd.get("efficiency", 0.0)))
	return best if best > 0.0 else 1.0


func get_total_installed() -> int:
	var total: int = 0
	for pid: int in _installed:
		total += _installed[pid].size()
	return total


func get_prosthetics_by_tier() -> Dictionary:
	var tiers: Dictionary = {"basic": 0, "simple": 0, "bionic": 0, "archotech": 0}
	for pid: int in _installed:
		for p in _installed[pid]:
			var pd: Dictionary = p if p is Dictionary else {}
			var pid_str: String = str(pd.get("id", ""))
			if pid_str.begins_with("Archotech"):
				tiers.archotech += 1
			elif pid_str.begins_with("Bionic"):
				tiers.bionic += 1
			elif pid_str.begins_with("Simple"):
				tiers.simple += 1
			else:
				tiers.basic += 1
	return tiers


func get_available_for_part(part_type: String) -> Array[String]:
	var result: Array[String] = []
	for prosthetic_id: String in PROSTHETICS:
		if PROSTHETICS[prosthetic_id].part == part_type:
			result.append(prosthetic_id)
	return result


func get_avg_prosthetics_per_pawn() -> float:
	if _installed.is_empty():
		return 0.0
	return snappedf(float(get_total_installed()) / float(_installed.size()), 0.1)


func get_highest_tier_installed() -> String:
	var tiers := get_prosthetics_by_tier()
	if tiers.archotech > 0:
		return "archotech"
	elif tiers.bionic > 0:
		return "bionic"
	elif tiers.simple > 0:
		return "simple"
	elif tiers.basic > 0:
		return "basic"
	return "none"


func get_most_common_part() -> String:
	var part_counts: Dictionary = {}
	for pid: int in _installed:
		for p in _installed[pid]:
			var pd: Dictionary = p if p is Dictionary else {}
			var part: String = str(pd.get("part", ""))
			part_counts[part] = part_counts.get(part, 0) + 1
	var best: String = ""
	var best_n: int = 0
	for pt: String in part_counts:
		if part_counts[pt] > best_n:
			best_n = part_counts[pt]
			best = pt
	return best


func get_above_normal_efficiency_count() -> int:
	var count: int = 0
	for pid_str: String in PROSTHETICS:
		if float(PROSTHETICS[pid_str].get("efficiency", 0.0)) > 1.0:
			count += 1
	return count


func get_unique_parts_covered() -> int:
	var parts: Dictionary = {}
	for pid_str: String in PROSTHETICS:
		parts[String(PROSTHETICS[pid_str].get("part", ""))] = true
	return parts.size()


func get_no_cost_prosthetic_count() -> int:
	var count: int = 0
	for pid_str: String in PROSTHETICS:
		var cost: Dictionary = PROSTHETICS[pid_str].get("cost", {}) as Dictionary
		if cost.is_empty():
			count += 1
	return count


func get_augmentation_level() -> String:
	var above: int = get_above_normal_efficiency_count()
	if above >= 5:
		return "Heavily Augmented"
	elif above >= 2:
		return "Moderately Augmented"
	elif above > 0:
		return "Lightly Augmented"
	return "Organic"

func get_bionic_ratio() -> float:
	var total: int = get_total_installed()
	if total <= 0:
		return 0.0
	return snappedf(float(get_above_normal_efficiency_count()) / float(total) * 100.0, 0.1)

func get_enhancement_score() -> float:
	if _installed.is_empty():
		return 0.0
	return snappedf(float(get_total_installed()) / float(_installed.size()), 0.1)

func get_summary() -> Dictionary:
	return {
		"prosthetic_types": PROSTHETICS.size(),
		"pawns_with_prosthetics": _installed.size(),
		"total_installed": get_total_installed(),
		"by_tier": get_prosthetics_by_tier(),
		"avg_per_pawn": get_avg_prosthetics_per_pawn(),
		"highest_tier": get_highest_tier_installed(),
		"most_common_part": get_most_common_part(),
		"coverage_pct": snappedf(float(_installed.size()) / maxf(float(_installed.size() + 1), 1.0) * 100.0, 0.1),
		"tier_count": get_prosthetics_by_tier().size(),
		"above_normal": get_above_normal_efficiency_count(),
		"unique_parts": get_unique_parts_covered(),
		"no_cost_types": get_no_cost_prosthetic_count(),
		"augmentation_level": get_augmentation_level(),
		"bionic_ratio_pct": get_bionic_ratio(),
		"enhancement_score": get_enhancement_score(),
		"cybernetic_integration": get_cybernetic_integration(),
		"bionic_readiness": get_bionic_readiness(),
		"augmentation_governance": get_augmentation_governance(),
	}

func get_cybernetic_integration() -> float:
	var bionic := get_bionic_ratio()
	var score := get_enhancement_score()
	return snapped((bionic + score) / 2.0, 0.1)

func get_bionic_readiness() -> float:
	var above := float(get_above_normal_efficiency_count())
	var total := float(get_total_installed())
	if total <= 0.0:
		return 0.0
	return snapped(above / total * 100.0, 0.1)

func get_augmentation_governance() -> String:
	var level := get_augmentation_level()
	var bionic := get_bionic_ratio()
	if level in ["Enhanced", "Augmented"] and bionic >= 30.0:
		return "Advanced"
	elif level == "Basic":
		return "Minimal"
	return "Developing"
