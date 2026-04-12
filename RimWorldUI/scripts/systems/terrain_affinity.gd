extends Node

## Maps terrain types to crop yield and growth modifiers. Fertile soil
## boosts crops, while sand/gravel reduces them.
## Registered as autoload "TerrainAffinity".

const TERRAIN_GROWTH_FACTOR: Dictionary = {
	"Soil": 1.0,
	"RichSoil": 1.4,
	"GravelySoil": 0.7,
	"Sand": 0.3,
	"MarshySoil": 0.85,
	"IceSheet": 0.0,
	"DeepWater": 0.0,
	"ShallowWater": 0.0,
	"SoftSand": 0.2,
	"PackedDirt": 0.6,
}

const TERRAIN_YIELD_FACTOR: Dictionary = {
	"Soil": 1.0,
	"RichSoil": 1.5,
	"GravelySoil": 0.65,
	"Sand": 0.25,
	"MarshySoil": 0.9,
	"IceSheet": 0.0,
	"DeepWater": 0.0,
	"ShallowWater": 0.0,
	"SoftSand": 0.15,
	"PackedDirt": 0.55,
}

const CROP_TERRAIN_PREFERENCE: Dictionary = {
	"Potato": {"preferred": ["Soil", "RichSoil", "GravelySoil"], "bonus": 1.1},
	"Rice": {"preferred": ["RichSoil", "Soil", "MarshySoil"], "bonus": 1.15},
	"Corn": {"preferred": ["RichSoil", "Soil"], "bonus": 1.2},
	"Strawberry": {"preferred": ["RichSoil", "Soil"], "bonus": 1.1},
	"Cotton": {"preferred": ["Soil", "RichSoil"], "bonus": 1.0},
	"Healroot": {"preferred": ["RichSoil"], "bonus": 1.3},
}


func get_growth_factor(terrain_def: String) -> float:
	return TERRAIN_GROWTH_FACTOR.get(terrain_def, 0.5)


func get_yield_factor(terrain_def: String) -> float:
	return TERRAIN_YIELD_FACTOR.get(terrain_def, 0.5)


func get_crop_bonus(crop_def: String, terrain_def: String) -> float:
	if not CROP_TERRAIN_PREFERENCE.has(crop_def):
		return 1.0
	var pref: Dictionary = CROP_TERRAIN_PREFERENCE[crop_def]
	var preferred: Array = pref.get("preferred", [])
	if terrain_def in preferred:
		return float(pref.get("bonus", 1.0))
	return 1.0


func can_grow_on(terrain_def: String) -> bool:
	return get_growth_factor(terrain_def) > 0.0


func get_best_terrain_for(crop_def: String) -> String:
	if not CROP_TERRAIN_PREFERENCE.has(crop_def):
		return "RichSoil"
	var pref: Dictionary = CROP_TERRAIN_PREFERENCE[crop_def]
	var preferred: Array = pref.get("preferred", [])
	if preferred.size() > 0:
		return str(preferred[0])
	return "RichSoil"


func get_terrain_report(map: MapData) -> Dictionary:
	if map == null:
		return {}
	var counts: Dictionary = {}
	for y: int in range(map.height):
		for x: int in range(map.width):
			var cell := map.get_cell(x, y)
			if cell:
				var t: String = cell.terrain_def
				counts[t] = counts.get(t, 0) + 1
	var growable := 0
	for t: String in counts:
		if can_grow_on(t):
			growable += counts[t]
	return {
		"terrain_counts": counts,
		"growable_cells": growable,
	}


func get_effective_factor(crop_def: String, terrain_def: String) -> float:
	return get_growth_factor(terrain_def) * get_crop_bonus(crop_def, terrain_def)


func get_all_crops_for_terrain(terrain_def: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for crop: String in CROP_TERRAIN_PREFERENCE:
		var factor: float = get_effective_factor(crop, terrain_def)
		if factor > 0.0:
			result.append({"crop": crop, "factor": snappedf(factor, 0.01)})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.factor > b.factor
	)
	return result


func get_worst_terrain() -> String:
	var worst: String = ""
	var worst_val: float = 2.0
	for t: String in TERRAIN_GROWTH_FACTOR:
		var v: float = TERRAIN_GROWTH_FACTOR[t]
		if v > 0.0 and v < worst_val:
			worst_val = v
			worst = t
	return worst


func get_terrain_tier(terrain_def: String) -> String:
	var factor: float = get_growth_factor(terrain_def)
	if factor >= 1.3:
		return "Excellent"
	elif factor >= 0.9:
		return "Good"
	elif factor >= 0.5:
		return "Poor"
	elif factor > 0.0:
		return "Terrible"
	return "Barren"


func get_best_crop_for_terrain(terrain_def: String) -> String:
	var best: String = ""
	var best_f: float = 0.0
	for crop: String in CROP_TERRAIN_PREFERENCE:
		var f: float = get_effective_factor(crop, terrain_def)
		if f > best_f:
			best_f = f
			best = crop
	return best


func get_growable_terrain_list() -> Array[String]:
	var result: Array[String] = []
	for t: String in TERRAIN_GROWTH_FACTOR:
		if TERRAIN_GROWTH_FACTOR[t] > 0.0:
			result.append(t)
	return result


func get_barren_terrain_list() -> Array[String]:
	var result: Array[String] = []
	for t: String in TERRAIN_GROWTH_FACTOR:
		if TERRAIN_GROWTH_FACTOR[t] <= 0.0:
			result.append(t)
	return result


func get_avg_growth_factor() -> float:
	var total: float = 0.0
	if TERRAIN_GROWTH_FACTOR.is_empty():
		return 0.0
	for t: String in TERRAIN_GROWTH_FACTOR:
		total += TERRAIN_GROWTH_FACTOR[t]
	return snappedf(total / float(TERRAIN_GROWTH_FACTOR.size()), 0.01)

func get_crop_variety_count() -> int:
	return CROP_TERRAIN_PREFERENCE.size()

func get_fertile_terrain_count() -> int:
	var count: int = 0
	for t: String in TERRAIN_GROWTH_FACTOR:
		if TERRAIN_GROWTH_FACTOR[t] >= 1.0:
			count += 1
	return count

func get_best_crop_bonus() -> float:
	var best: float = 0.0
	for crop: String in CROP_TERRAIN_PREFERENCE:
		var b: float = CROP_TERRAIN_PREFERENCE[crop].get("bonus", 1.0)
		if b > best:
			best = b
	return best

func get_avg_yield_factor() -> float:
	if TERRAIN_YIELD_FACTOR.is_empty():
		return 0.0
	var total: float = 0.0
	for t: String in TERRAIN_YIELD_FACTOR:
		total += TERRAIN_YIELD_FACTOR[t]
	return snappedf(total / float(TERRAIN_YIELD_FACTOR.size()), 0.01)

func get_multi_terrain_crop_count() -> int:
	var count: int = 0
	for crop: String in CROP_TERRAIN_PREFERENCE:
		if CROP_TERRAIN_PREFERENCE[crop].get("preferred", []).size() >= 3:
			count += 1
	return count

func get_terrain_diversity_score() -> float:
	if TERRAIN_GROWTH_FACTOR.is_empty():
		return 0.0
	var growable: int = get_growable_terrain_list().size()
	return snappedf(float(growable) / float(TERRAIN_GROWTH_FACTOR.size()) * 100.0, 0.1)

func get_crop_adaptability() -> String:
	var multi: int = get_multi_terrain_crop_count()
	var total: int = CROP_TERRAIN_PREFERENCE.size()
	if total <= 0:
		return "None"
	var ratio: float = float(multi) / float(total)
	if ratio >= 0.6:
		return "Highly Adaptable"
	elif ratio >= 0.3:
		return "Moderate"
	return "Specialized"

func get_fertility_rating() -> String:
	var avg: float = get_avg_growth_factor()
	if avg >= 1.2:
		return "Excellent"
	elif avg >= 1.0:
		return "Good"
	elif avg >= 0.7:
		return "Fair"
	return "Poor"

func get_agricultural_potential() -> float:
	var avg_growth := get_avg_growth_factor()
	var fertile := float(get_fertile_terrain_count())
	var total := float(TERRAIN_GROWTH_FACTOR.size())
	if total <= 0.0:
		return 0.0
	return snapped(avg_growth * (fertile / total) * 100.0, 0.1)

func get_crop_terrain_synergy() -> float:
	var multi := get_multi_terrain_crop_count()
	var total := CROP_TERRAIN_PREFERENCE.size()
	var diversity := get_terrain_diversity_score()
	if total <= 0:
		return 0.0
	return snapped(float(multi) / float(total) * diversity, 0.1)

func get_food_sustainability() -> String:
	var potential := get_agricultural_potential()
	var adaptability := get_crop_adaptability()
	if potential >= 50.0 and adaptability == "Highly Adaptable":
		return "Self-Sufficient"
	elif potential >= 30.0:
		return "Adequate"
	elif potential >= 15.0:
		return "Supplemental"
	return "Infertile"

func get_soil_optimization() -> float:
	var fertile := get_fertile_terrain_count()
	var growable := get_growable_terrain_list().size()
	if growable <= 0:
		return 0.0
	return snapped(float(fertile) / float(growable) * 100.0, 0.1)

func get_biodiversity_index() -> float:
	var multi := get_multi_terrain_crop_count()
	var varieties := get_crop_variety_count()
	if varieties <= 0:
		return 0.0
	return snapped(float(multi) / float(varieties) * 100.0, 0.1)

func get_famine_resilience() -> String:
	var sustainability := get_food_sustainability()
	var diversity := get_terrain_diversity_score()
	if sustainability == "Self-Sufficient" and diversity > 50.0:
		return "Robust"
	elif sustainability == "Adequate":
		return "Moderate"
	return "Vulnerable"

func get_summary() -> Dictionary:
	return {
		"terrain_types": TERRAIN_GROWTH_FACTOR.size(),
		"crop_preferences": CROP_TERRAIN_PREFERENCE.size(),
		"best_terrain": "RichSoil",
		"worst_growable": get_worst_terrain(),
		"growable_count": get_growable_terrain_list().size(),
		"barren_count": get_barren_terrain_list().size(),
		"avg_growth_factor": get_avg_growth_factor(),
		"crop_varieties": get_crop_variety_count(),
		"fertile_count": get_fertile_terrain_count(),
		"best_crop_bonus": get_best_crop_bonus(),
		"avg_yield_factor": get_avg_yield_factor(),
		"multi_terrain_crops": get_multi_terrain_crop_count(),
		"terrain_diversity_pct": get_terrain_diversity_score(),
		"crop_adaptability": get_crop_adaptability(),
		"fertility_rating": get_fertility_rating(),
		"agricultural_potential": get_agricultural_potential(),
		"crop_terrain_synergy": get_crop_terrain_synergy(),
		"food_sustainability": get_food_sustainability(),
		"soil_optimization": get_soil_optimization(),
		"biodiversity_index": get_biodiversity_index(),
		"famine_resilience": get_famine_resilience(),
		"agricultural_mastery": get_agricultural_mastery(),
		"terrain_utilization_index": get_terrain_utilization_index(),
		"crop_security_score": get_crop_security_score(),
	}

func get_agricultural_mastery() -> String:
	var potential: float = get_agricultural_potential()
	var diversity: float = get_terrain_diversity_score()
	if potential >= 80.0 and diversity >= 70.0:
		return "Expert"
	if potential >= 50.0:
		return "Proficient"
	return "Developing"

func get_terrain_utilization_index() -> float:
	var growable: int = get_growable_terrain_list().size()
	var total: int = TERRAIN_GROWTH_FACTOR.size()
	var avg_yield: float = get_avg_yield_factor()
	if total == 0:
		return 0.0
	return snappedf(float(growable) / float(total) * 50.0 + avg_yield * 50.0, 0.1)

func get_crop_security_score() -> float:
	var resilience: String = get_famine_resilience()
	var adaptability: String = get_crop_adaptability()
	var base: float = 50.0
	if resilience == "Resilient":
		base += 30.0
	elif resilience == "Moderate":
		base += 15.0
	if adaptability == "Highly Adaptable":
		base += 20.0
	elif adaptability == "Adaptable":
		base += 10.0
	return snappedf(clampf(base, 0.0, 100.0), 0.1)
