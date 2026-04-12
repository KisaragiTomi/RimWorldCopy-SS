extends Node

const TERRAIN_FERTILITY: Dictionary = {
	"RichSoil": 1.4, "Soil": 1.0, "GravelySoil": 0.7,
	"Sand": 0.1, "MarshySoil": 0.9, "MossySoil": 1.1,
	"SoftSand": 0.05, "PackedDirt": 0.5, "Ice": 0.0,
	"Gravel": 0.0, "SmoothStone": 0.0, "RoughStone": 0.0,
	"Mud": 0.6, "HydroponicBasin": 2.8
}

const CROP_FERTILITY_SENSITIVITY: Dictionary = {
	"Rice": 1.0, "Potato": 0.6, "Corn": 1.1,
	"Strawberry": 1.2, "Cotton": 0.9, "Haygrass": 0.8,
	"HealRoot": 1.3, "Smokeleaf": 0.9, "Psychoid": 0.8,
	"Hops": 1.0, "Devilstrand": 0.7, "Rose": 1.1
}

func get_fertility(terrain: String) -> float:
	return TERRAIN_FERTILITY.get(terrain, 0.0)

func get_growth_rate(terrain: String, crop: String) -> float:
	var fertility: float = get_fertility(terrain)
	var sensitivity: float = CROP_FERTILITY_SENSITIVITY.get(crop, 1.0)
	return maxf(0.0, lerpf(1.0, fertility, sensitivity))

func get_best_terrain_for_crop(crop: String) -> String:
	var best: String = ""
	var best_rate: float = 0.0
	for terrain: String in TERRAIN_FERTILITY:
		var rate: float = get_growth_rate(terrain, crop)
		if rate > best_rate:
			best_rate = rate
			best = terrain
	return best

func get_infertile_terrains() -> Array[String]:
	var result: Array[String] = []
	for t: String in TERRAIN_FERTILITY:
		if float(TERRAIN_FERTILITY[t]) <= 0.0:
			result.append(t)
	return result


func get_most_sensitive_crop() -> String:
	var best: String = ""
	var best_s: float = 0.0
	for c: String in CROP_FERTILITY_SENSITIVITY:
		var s: float = float(CROP_FERTILITY_SENSITIVITY[c])
		if s > best_s:
			best_s = s
			best = c
	return best


func get_least_sensitive_crop() -> String:
	var best: String = ""
	var best_s: float = 999.0
	for c: String in CROP_FERTILITY_SENSITIVITY:
		var s: float = float(CROP_FERTILITY_SENSITIVITY[c])
		if s < best_s:
			best_s = s
			best = c
	return best


func get_avg_fertility() -> float:
	var total: float = 0.0
	for t: String in TERRAIN_FERTILITY:
		total += TERRAIN_FERTILITY[t]
	return total / maxf(TERRAIN_FERTILITY.size(), 1)


func get_fertile_terrain_count() -> int:
	var count: int = 0
	for t: String in TERRAIN_FERTILITY:
		if float(TERRAIN_FERTILITY[t]) > 0.0:
			count += 1
	return count


func get_avg_sensitivity() -> float:
	var total: float = 0.0
	for c: String in CROP_FERTILITY_SENSITIVITY:
		total += float(CROP_FERTILITY_SENSITIVITY[c])
	return total / maxf(CROP_FERTILITY_SENSITIVITY.size(), 1)


func get_fertility_range() -> Dictionary:
	var lo: float = 999.0
	var hi: float = 0.0
	for t: String in TERRAIN_FERTILITY:
		var v: float = float(TERRAIN_FERTILITY[t])
		if v < lo:
			lo = v
		if v > hi:
			hi = v
	return {"min": snapped(lo, 0.01), "max": snapped(hi, 0.01)}


func get_high_fertility_count() -> int:
	var count: int = 0
	for t: String in TERRAIN_FERTILITY:
		if float(TERRAIN_FERTILITY[t]) >= 1.0:
			count += 1
	return count


func get_sensitivity_spread() -> float:
	var lo: float = 999.0
	var hi: float = 0.0
	for c: String in CROP_FERTILITY_SENSITIVITY:
		var v: float = float(CROP_FERTILITY_SENSITIVITY[c])
		if v < lo:
			lo = v
		if v > hi:
			hi = v
	return snappedf(hi - lo, 0.01)


func get_barren_terrain_count() -> int:
	var count: int = 0
	for t: String in TERRAIN_FERTILITY:
		if float(TERRAIN_FERTILITY[t]) <= 0.0:
			count += 1
	return count


func get_crop_terrain_compatibility_count() -> int:
	var count: int = 0
	for _t: String in TERRAIN_FERTILITY:
		var f: float = float(TERRAIN_FERTILITY[_t])
		if f > 0.0:
			for _c: String in CROP_FERTILITY_SENSITIVITY:
				if f * float(CROP_FERTILITY_SENSITIVITY[_c]) > 0.5:
					count += 1
	return count


func get_agricultural_potential() -> String:
	var avg: float = get_avg_fertility()
	if avg >= 1.2:
		return "Lush"
	elif avg >= 0.8:
		return "Fertile"
	elif avg >= 0.4:
		return "Marginal"
	return "Barren"

func get_crop_resilience() -> String:
	var avg_sens: float = get_avg_sensitivity()
	if avg_sens <= 0.3:
		return "Hardy"
	elif avg_sens <= 0.6:
		return "Normal"
	elif avg_sens <= 0.8:
		return "Delicate"
	return "Fragile"

func get_farming_viability_pct() -> float:
	if TERRAIN_FERTILITY.is_empty():
		return 0.0
	return snappedf(float(get_fertile_terrain_count()) / float(TERRAIN_FERTILITY.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"terrain_types": TERRAIN_FERTILITY.size(),
		"crop_types": CROP_FERTILITY_SENSITIVITY.size(),
		"infertile_count": get_infertile_terrains().size(),
		"most_sensitive": get_most_sensitive_crop(),
		"avg_fertility": snapped(get_avg_fertility(), 0.01),
		"fertile_count": get_fertile_terrain_count(),
		"avg_sensitivity": snapped(get_avg_sensitivity(), 0.01),
		"fertility_range": get_fertility_range(),
		"high_fertility": get_high_fertility_count(),
		"sensitivity_spread": get_sensitivity_spread(),
		"least_sensitive": get_least_sensitive_crop(),
		"barren_count": get_barren_terrain_count(),
		"compatible_pairs": get_crop_terrain_compatibility_count(),
		"agricultural_potential": get_agricultural_potential(),
		"crop_resilience": get_crop_resilience(),
		"farming_viability_pct": get_farming_viability_pct(),
		"soil_quality_index": get_soil_quality_index(),
		"crop_diversity_potential": get_crop_diversity_potential(),
		"harvest_reliability": get_harvest_reliability(),
		"land_productivity_index": get_land_productivity_index(),
		"terrain_crop_synergy": get_terrain_crop_synergy(),
		"food_sovereignty_pct": get_food_sovereignty_pct(),
		"agricultural_ecosystem_health": get_agricultural_ecosystem_health(),
		"farming_governance": get_farming_governance(),
		"agrarian_maturity_index": get_agrarian_maturity_index(),
	}

func get_land_productivity_index() -> float:
	var avg_fert := get_avg_fertility()
	var compatible := get_crop_terrain_compatibility_count()
	return snapped(avg_fert * float(compatible) / maxf(float(TERRAIN_FERTILITY.size()), 1.0), 0.01)

func get_terrain_crop_synergy() -> String:
	var compatibility := get_crop_terrain_compatibility_count()
	var total := TERRAIN_FERTILITY.size() * CROP_FERTILITY_SENSITIVITY.size()
	if total <= 0:
		return "N/A"
	var ratio := float(compatibility) / float(total)
	if ratio >= 0.5:
		return "Excellent"
	elif ratio >= 0.3:
		return "Good"
	return "Limited"

func get_food_sovereignty_pct() -> float:
	var viable := get_farming_viability_pct()
	var diversity_str: String = get_crop_diversity_potential()
	var diversity_val: float = 1.0 if diversity_str == "High" else (0.6 if diversity_str == "Moderate" else 0.3)
	return snapped(viable * diversity_val / 100.0, 0.1)

func get_soil_quality_index() -> float:
	var avg := get_avg_fertility()
	var high := get_high_fertility_count()
	var total := TERRAIN_FERTILITY.size()
	if total <= 0:
		return 0.0
	return snapped(avg * (float(high) / float(total) + 0.5) * 100.0, 0.1)

func get_crop_diversity_potential() -> String:
	var compatible := get_crop_terrain_compatibility_count()
	var total := CROP_FERTILITY_SENSITIVITY.size() * TERRAIN_FERTILITY.size()
	if total <= 0:
		return "None"
	var ratio := float(compatible) / float(total)
	if ratio >= 0.5:
		return "High"
	elif ratio >= 0.2:
		return "Moderate"
	return "Low"

func get_harvest_reliability() -> String:
	var resilience := get_crop_resilience()
	var viability := get_farming_viability_pct()
	if resilience in ["Resilient", "Hardy"] and viability >= 60.0:
		return "Dependable"
	elif viability >= 30.0:
		return "Variable"
	return "Unreliable"

func get_agricultural_ecosystem_health() -> float:
	var productivity := get_land_productivity_index()
	var sovereignty := get_food_sovereignty_pct()
	var reliability := get_harvest_reliability()
	var r_val: float = 90.0 if reliability == "Dependable" else (60.0 if reliability == "Variable" else 25.0)
	return snapped((minf(productivity * 100.0, 100.0) + sovereignty + r_val) / 3.0, 0.1)

func get_farming_governance() -> String:
	var ecosystem := get_agricultural_ecosystem_health()
	var synergy := get_terrain_crop_synergy()
	var s_val: float = 90.0 if synergy == "High" else (60.0 if synergy == "Moderate" else 25.0)
	var combined := (ecosystem + s_val) / 2.0
	if combined >= 70.0:
		return "Thriving"
	elif combined >= 40.0:
		return "Subsistence"
	elif TERRAIN_FERTILITY.size() > 0:
		return "Struggling"
	return "Barren"

func get_agrarian_maturity_index() -> float:
	var potential := get_agricultural_potential()
	var p_val: float = 90.0 if potential == "Excellent" else (60.0 if potential in ["Good", "Moderate"] else 25.0)
	var resilience := get_crop_resilience()
	var r_val: float = 90.0 if resilience in ["Resilient", "Hardy"] else (60.0 if resilience == "Moderate" else 25.0)
	return snapped((p_val + r_val) / 2.0, 0.1)
