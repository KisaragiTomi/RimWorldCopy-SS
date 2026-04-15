extends Node

const GROWTH_STAGES: Dictionary = {
	"Sowed": {"progress_range": [0.0, 0.05], "harvestable": false},
	"Sprout": {"progress_range": [0.05, 0.2], "harvestable": false},
	"Growing": {"progress_range": [0.2, 0.6], "harvestable": false},
	"Mature": {"progress_range": [0.6, 0.9], "harvestable": true, "yield_mult": 0.7},
	"FullyGrown": {"progress_range": [0.9, 1.0], "harvestable": true, "yield_mult": 1.0}
}

const PLANT_DISEASES: Dictionary = {
	"Blight": {"spread_chance": 0.3, "damage_per_day": 0.15, "kill_threshold": 0.8, "cure": "Remove"},
	"RootRot": {"spread_chance": 0.1, "damage_per_day": 0.08, "kill_threshold": 0.6, "cure": "Replant"},
	"LeafBurn": {"spread_chance": 0.05, "damage_per_day": 0.05, "kill_threshold": 0.9, "cure": "Shade"},
	"PestInfestation": {"spread_chance": 0.4, "damage_per_day": 0.2, "kill_threshold": 0.7, "cure": "Pesticide"},
	"Wilt": {"spread_chance": 0.0, "damage_per_day": 0.1, "kill_threshold": 0.5, "cure": "Water"}
}

const GROWTH_RATE_FACTORS: Dictionary = {
	"temperature_optimal": {"range": [10.0, 42.0], "mult": 1.0},
	"temperature_slow": {"range": [0.0, 10.0], "mult": 0.5},
	"light_full": {"threshold": 0.5, "mult": 1.0},
	"light_dim": {"threshold": 0.3, "mult": 0.5},
	"fertility_rich": {"threshold": 1.4, "mult": 1.4},
	"fertility_poor": {"threshold": 0.7, "mult": 0.7}
}

func get_stage(progress: float) -> String:
	for stage_name: String in GROWTH_STAGES:
		var r: Array = GROWTH_STAGES[stage_name]["progress_range"]
		if progress >= r[0] and progress < r[1]:
			return stage_name
	return "FullyGrown"

func apply_disease(plant_hp: float, disease: String) -> Dictionary:
	if not PLANT_DISEASES.has(disease):
		return {"error": "unknown_disease"}
	var d: Dictionary = PLANT_DISEASES[disease]
	var new_hp: float = plant_hp - d["damage_per_day"]
	return {"new_hp": maxf(0.0, new_hp), "dead": new_hp <= 0.0, "cure": d["cure"]}

func get_deadliest_disease() -> String:
	var worst: String = ""
	var worst_dmg: float = 0.0
	for d: String in PLANT_DISEASES:
		if PLANT_DISEASES[d]["damage_per_day"] > worst_dmg:
			worst_dmg = PLANT_DISEASES[d]["damage_per_day"]
			worst = d
	return worst

func get_most_contagious() -> String:
	var best: String = ""
	var best_s: float = 0.0
	for d: String in PLANT_DISEASES:
		if PLANT_DISEASES[d]["spread_chance"] > best_s:
			best_s = PLANT_DISEASES[d]["spread_chance"]
			best = d
	return best

func get_harvestable_stages() -> Array[String]:
	var result: Array[String] = []
	for s: String in GROWTH_STAGES:
		if GROWTH_STAGES[s].get("harvestable", false):
			result.append(s)
	return result

func get_avg_disease_severity() -> float:
	if PLANT_DISEASES.is_empty():
		return 0.0
	var total: float = 0.0
	for d: String in PLANT_DISEASES:
		total += float(PLANT_DISEASES[d].get("severity", 0.0))
	return total / PLANT_DISEASES.size()

func get_fast_growth_factor_count() -> int:
	var count: int = 0
	for f: String in GROWTH_RATE_FACTORS:
		if float(GROWTH_RATE_FACTORS[f]) > 1.0:
			count += 1
	return count

func get_total_growth_stages() -> int:
	return GROWTH_STAGES.size()

func get_non_spreadable_disease_count() -> int:
	var count: int = 0
	for d: String in PLANT_DISEASES:
		if float(PLANT_DISEASES[d].get("spread_chance", 0.0)) <= 0.0:
			count += 1
	return count


func get_avg_damage_per_day() -> float:
	if PLANT_DISEASES.is_empty():
		return 0.0
	var total: float = 0.0
	for d: String in PLANT_DISEASES:
		total += float(PLANT_DISEASES[d].get("damage_per_day", 0.0))
	return total / PLANT_DISEASES.size()


func get_unique_cures() -> int:
	var cures: Dictionary = {}
	for d: String in PLANT_DISEASES:
		cures[String(PLANT_DISEASES[d].get("cure", ""))] = true
	return cures.size()


func get_agricultural_risk() -> String:
	var spreadable: int = PLANT_DISEASES.size() - get_non_spreadable_disease_count()
	if PLANT_DISEASES.is_empty():
		return "none"
	var ratio: float = spreadable * 1.0 / PLANT_DISEASES.size()
	if ratio >= 0.6:
		return "high"
	if ratio >= 0.3:
		return "moderate"
	return "low"

func get_harvest_window_pct() -> float:
	var harvestable: int = get_harvestable_stages().size()
	if GROWTH_STAGES.is_empty():
		return 0.0
	return snapped(harvestable * 100.0 / GROWTH_STAGES.size(), 0.1)

func get_disease_manageability() -> String:
	var cures: int = get_unique_cures()
	var diseases: int = PLANT_DISEASES.size()
	if diseases == 0:
		return "no_threats"
	var ratio: float = cures * 1.0 / diseases
	if ratio >= 0.8:
		return "well_managed"
	if ratio >= 0.5:
		return "partial"
	return "vulnerable"

func get_summary() -> Dictionary:
	return {
		"growth_stages": GROWTH_STAGES.size(),
		"diseases": PLANT_DISEASES.size(),
		"growth_factors": GROWTH_RATE_FACTORS.size(),
		"deadliest_disease": get_deadliest_disease(),
		"harvestable_stages": get_harvestable_stages().size(),
		"avg_disease_severity": snapped(get_avg_disease_severity(), 0.01),
		"growth_boosters": get_fast_growth_factor_count(),
		"non_spread_diseases": get_non_spreadable_disease_count(),
		"avg_damage_per_day": snapped(get_avg_damage_per_day(), 0.001),
		"unique_cures": get_unique_cures(),
		"agricultural_risk": get_agricultural_risk(),
		"harvest_window_pct": get_harvest_window_pct(),
		"disease_manageability": get_disease_manageability(),
		"crop_health_index": get_crop_health_index(),
		"yield_optimization": get_yield_optimization(),
		"growing_season_quality": get_growing_season_quality(),
		"agricultural_ecosystem_health": get_agricultural_ecosystem_health(),
		"farming_governance": get_farming_governance(),
		"crop_maturity_index": get_crop_maturity_index(),
	}

func get_crop_health_index() -> float:
	var non_spread := get_non_spreadable_disease_count()
	var total := PLANT_DISEASES.size()
	if total <= 0:
		return 100.0
	return snapped(float(non_spread) / float(total) * 100.0, 0.1)

func get_yield_optimization() -> String:
	var boosters := get_fast_growth_factor_count()
	var harvestable := get_harvestable_stages().size()
	if boosters >= 3 and harvestable >= 2:
		return "Maximized"
	elif boosters >= 1:
		return "Optimized"
	return "Baseline"

func get_growing_season_quality() -> String:
	var risk := get_agricultural_risk()
	var harvest := get_harvest_window_pct()
	if risk in ["Low", "Minimal"] and harvest >= 50.0:
		return "Ideal"
	elif harvest >= 25.0:
		return "Adequate"
	return "Harsh"

func get_agricultural_ecosystem_health() -> float:
	var health := get_crop_health_index()
	var optimization := get_yield_optimization()
	var o_val: float = 90.0 if optimization == "Maximized" else (60.0 if optimization == "Optimized" else 30.0)
	var season := get_growing_season_quality()
	var s_val: float = 90.0 if season == "Ideal" else (60.0 if season == "Adequate" else 30.0)
	return snapped((health + o_val + s_val) / 3.0, 0.1)

func get_crop_maturity_index() -> float:
	var manageability := get_disease_manageability()
	var m_val: float = 90.0 if manageability in ["no_threats", "manageable"] else (60.0 if manageability in ["moderate", "challenging"] else 30.0)
	var risk := get_agricultural_risk()
	var r_val: float = 90.0 if risk in ["none", "Low", "Minimal"] else (50.0 if risk in ["moderate", "Moderate"] else 20.0)
	var harvest := get_harvest_window_pct()
	return snapped((m_val + r_val + harvest) / 3.0, 0.1)

func get_farming_governance() -> String:
	var ecosystem := get_agricultural_ecosystem_health()
	var maturity := get_crop_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif PLANT_DISEASES.size() > 0:
		return "Nascent"
	return "Dormant"
