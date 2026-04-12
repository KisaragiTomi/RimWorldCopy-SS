extends Node

const TERRAIN_GEN: Dictionary = {
	"Mountain": {"noise_threshold": 0.7, "material": "Granite", "mineable": true},
	"Hill": {"noise_threshold": 0.5, "material": "Sandstone", "mineable": true},
	"River": {"width_range": [2, 6], "flow_speed": 1.2, "crossable": true, "fertility_bonus": 0.2},
	"Lake": {"size_range": [4, 12], "depth": 3.0, "fishable": true},
	"Marsh": {"moisture_threshold": 0.6, "movement_penalty": 0.4, "fertility": 0.8},
	"Cave": {"min_mountain_depth": 3, "infestation_risk": 0.05}
}

const MINERAL_VEINS: Dictionary = {
	"Steel": {"frequency": 0.15, "vein_size": [3, 8], "yield_per_tile": 40, "min_depth": 0},
	"Silver": {"frequency": 0.06, "vein_size": [2, 5], "yield_per_tile": 35, "min_depth": 1},
	"Gold": {"frequency": 0.03, "vein_size": [1, 3], "yield_per_tile": 25, "min_depth": 2},
	"Plasteel": {"frequency": 0.02, "vein_size": [1, 3], "yield_per_tile": 20, "min_depth": 3},
	"Uranium": {"frequency": 0.015, "vein_size": [1, 2], "yield_per_tile": 15, "min_depth": 3},
	"Jade": {"frequency": 0.02, "vein_size": [1, 3], "yield_per_tile": 20, "min_depth": 2},
	"ComponentsIndustrial": {"frequency": 0.04, "vein_size": [1, 2], "yield_per_tile": 2, "min_depth": 1}
}

const MAP_SIZES: Dictionary = {
	"Small": {"tiles": Vector2i(200, 200), "mountain_pct": 0.3},
	"Medium": {"tiles": Vector2i(250, 250), "mountain_pct": 0.25},
	"Large": {"tiles": Vector2i(300, 300), "mountain_pct": 0.2},
	"Extreme": {"tiles": Vector2i(350, 350), "mountain_pct": 0.15}
}

func estimate_mineral_yield(mineral: String, map_size: String) -> Dictionary:
	if not MINERAL_VEINS.has(mineral) or not MAP_SIZES.has(map_size):
		return {}
	var m: Dictionary = MINERAL_VEINS[mineral]
	var s: Dictionary = MAP_SIZES[map_size]
	var total_tiles: int = s["tiles"].x * s["tiles"].y
	var mountain_tiles: int = int(total_tiles * s["mountain_pct"])
	var avg_vein: float = (m["vein_size"][0] + m["vein_size"][1]) / 2.0
	var expected_veins: int = int(mountain_tiles * m["frequency"])
	return {"mineral": mineral, "expected_veins": expected_veins, "avg_yield": int(expected_veins * avg_vein * m["yield_per_tile"])}

func get_rarest_mineral() -> String:
	var best: String = ""
	var min_f: float = 999.0
	for m: String in MINERAL_VEINS:
		if MINERAL_VEINS[m]["frequency"] < min_f:
			min_f = MINERAL_VEINS[m]["frequency"]
			best = m
	return best

func get_most_valuable_mineral() -> String:
	var best: String = ""
	var best_y: int = 0
	for m: String in MINERAL_VEINS:
		if MINERAL_VEINS[m]["yield_per_tile"] > best_y:
			best_y = MINERAL_VEINS[m]["yield_per_tile"]
			best = m
	return best

func get_dangerous_terrains() -> Array[String]:
	var result: Array[String] = []
	for t: String in TERRAIN_GEN:
		if TERRAIN_GEN[t].has("infestation_risk") or TERRAIN_GEN[t].get("movement_penalty", 0.0) > 0.3:
			result.append(t)
	return result

func get_highest_value_mineral() -> String:
	var best: String = ""
	var best_val: float = 0.0
	for m: String in MINERAL_VEINS:
		var v: float = float(MINERAL_VEINS[m].get("value", 0.0))
		if v > best_val:
			best_val = v
			best = m
	return best

func get_avg_mineral_rarity() -> float:
	if MINERAL_VEINS.is_empty():
		return 0.0
	var total: float = 0.0
	for m: String in MINERAL_VEINS:
		total += float(MINERAL_VEINS[m].get("rarity", 0.0))
	return total / MINERAL_VEINS.size()

func get_safe_terrain_count() -> int:
	var total: int = TERRAIN_GEN.size()
	return total - get_dangerous_terrains().size()

func get_deep_mineral_count() -> int:
	var count: int = 0
	for m: String in MINERAL_VEINS:
		if int(MINERAL_VEINS[m].get("min_depth", 0)) >= 2:
			count += 1
	return count


func get_avg_frequency() -> float:
	if MINERAL_VEINS.is_empty():
		return 0.0
	var total: float = 0.0
	for m: String in MINERAL_VEINS:
		total += float(MINERAL_VEINS[m].get("frequency", 0.0))
	return total / MINERAL_VEINS.size()


func get_mineable_terrain_count() -> int:
	var count: int = 0
	for t: String in TERRAIN_GEN:
		if bool(TERRAIN_GEN[t].get("mineable", false)):
			count += 1
	return count


func get_resource_density() -> float:
	var total := 0.0
	for m in MINERAL_VEINS.values():
		var avg_vein: float = (m["vein_size"][0] + m["vein_size"][1]) / 2.0
		total += m["frequency"] * avg_vein * m["yield_per_tile"]
	return snapped(total / maxi(MINERAL_VEINS.size(), 1), 0.01)

func get_terrain_diversity_pct() -> float:
	var props := {}
	for t in TERRAIN_GEN.values():
		for k in t.keys():
			props[k] = true
	var max_props := TERRAIN_GEN.size() * 4
	return snapped(float(props.size()) / maxf(max_props, 1.0) * 100.0, 0.1)

func get_exploration_potential() -> float:
	var val_score := 0.0
	for m in MINERAL_VEINS.values():
		val_score += m["yield_per_tile"] * (1.0 / maxf(m["frequency"], 0.001))
	var safe := get_safe_terrain_count()
	return snapped((val_score / maxf(MINERAL_VEINS.size(), 1.0)) * (safe / maxf(float(TERRAIN_GEN.size()), 1.0)), 0.1)

func get_summary() -> Dictionary:
	return {
		"terrain_types": TERRAIN_GEN.size(),
		"mineral_types": MINERAL_VEINS.size(),
		"map_sizes": MAP_SIZES.size(),
		"rarest_mineral": get_rarest_mineral(),
		"dangerous_terrain_count": get_dangerous_terrains().size(),
		"most_valuable_mineral": get_highest_value_mineral(),
		"avg_rarity": snapped(get_avg_mineral_rarity(), 0.01),
		"safe_terrains": get_safe_terrain_count(),
		"deep_minerals": get_deep_mineral_count(),
		"avg_frequency": snapped(get_avg_frequency(), 0.001),
		"mineable_terrains": get_mineable_terrain_count(),
		"resource_density": get_resource_density(),
		"terrain_diversity_pct": get_terrain_diversity_pct(),
		"exploration_potential": get_exploration_potential(),
		"mining_profitability": get_mining_profitability(),
		"map_habitability": get_map_habitability(),
		"geological_richness": get_geological_richness(),
		"map_ecosystem_health": get_map_ecosystem_health(),
		"terrain_governance": get_terrain_governance(),
		"geological_maturity_index": get_geological_maturity_index(),
	}

func get_mining_profitability() -> String:
	var valuable := get_highest_value_mineral()
	var deep := get_deep_mineral_count()
	if valuable != "" and deep >= 3:
		return "Highly Profitable"
	elif deep >= 1:
		return "Profitable"
	return "Barren"

func get_map_habitability() -> float:
	var safe := get_safe_terrain_count()
	var total := TERRAIN_GEN.size()
	if total <= 0:
		return 0.0
	return snapped(float(safe) / float(total) * 100.0, 0.1)

func get_geological_richness() -> String:
	var density := get_resource_density()
	var diversity := get_terrain_diversity_pct()
	if density in ["Rich", "Abundant"] and diversity >= 50.0:
		return "Exceptional"
	elif density in ["Moderate", "Rich"]:
		return "Good"
	return "Poor"

func get_map_ecosystem_health() -> float:
	var profitability := get_mining_profitability()
	var p_val: float = 90.0 if profitability == "Highly Profitable" else (60.0 if profitability == "Profitable" else 30.0)
	var habitability := get_map_habitability()
	var richness := get_geological_richness()
	var r_val: float = 90.0 if richness == "Exceptional" else (60.0 if richness == "Good" else 30.0)
	return snapped((p_val + habitability + r_val) / 3.0, 0.1)

func get_geological_maturity_index() -> float:
	var density := get_resource_density()
	var exploration := get_exploration_potential()
	var diversity := get_terrain_diversity_pct()
	return snapped((minf(density * 10.0, 100.0) + minf(exploration * 10.0, 100.0) + diversity) / 3.0, 0.1)

func get_terrain_governance() -> String:
	var ecosystem := get_map_ecosystem_health()
	var maturity := get_geological_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif MINERAL_VEINS.size() > 0:
		return "Nascent"
	return "Dormant"
