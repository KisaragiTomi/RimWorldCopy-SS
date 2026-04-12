extends Node

const MATERIAL_RATES: Dictionary = {
	"Wood": 1.5,
	"Steel": 0.5,
	"Stone": 0.1,
	"Plasteel": 0.05,
	"Gold": 0.02,
	"Silver": 0.1,
	"Uranium": 0.01,
	"Cloth": 2.0,
	"Leather": 1.2,
	"Meat": 5.0,
	"Vegetable": 4.0,
	"Medicine": 0.3,
}

const ENVIRONMENT_MULT: Dictionary = {
	"Indoor_Roofed": 0.0,
	"Indoor_Unroofed": 0.5,
	"Outdoor_Clear": 1.0,
	"Outdoor_Rain": 2.0,
	"Outdoor_Snow": 1.5,
	"Outdoor_ToxicFallout": 3.0,
}


func get_deterioration_rate(material: String, environment: String) -> float:
	var base: float = float(MATERIAL_RATES.get(material, 1.0))
	var env_mult: float = float(ENVIRONMENT_MULT.get(environment, 1.0))
	return base * env_mult


func get_days_until_destroyed(hp: float, material: String, environment: String) -> float:
	var rate: float = get_deterioration_rate(material, environment)
	if rate <= 0.0:
		return 9999.0
	return hp / rate


func get_most_durable_material() -> String:
	var best: String = ""
	var best_rate: float = 999.0
	for mid: String in MATERIAL_RATES:
		if MATERIAL_RATES[mid] < best_rate:
			best_rate = MATERIAL_RATES[mid]
			best = mid
	return best


func get_most_fragile_material() -> String:
	var worst: String = ""
	var worst_rate: float = 0.0
	for mid: String in MATERIAL_RATES:
		if MATERIAL_RATES[mid] > worst_rate:
			worst_rate = MATERIAL_RATES[mid]
			worst = mid
	return worst


func get_safe_environments() -> Array[String]:
	var result: Array[String] = []
	for env: String in ENVIRONMENT_MULT:
		if ENVIRONMENT_MULT[env] <= 0.0:
			result.append(env)
	return result


func get_avg_deterioration_rate() -> float:
	if MATERIAL_RATES.is_empty():
		return 0.0
	var total: float = 0.0
	for mid: String in MATERIAL_RATES:
		total += MATERIAL_RATES[mid]
	return snappedf(total / float(MATERIAL_RATES.size()), 0.001)


func get_worst_environment() -> String:
	var worst: String = ""
	var worst_mult: float = 0.0
	for env: String in ENVIRONMENT_MULT:
		if ENVIRONMENT_MULT[env] > worst_mult:
			worst_mult = ENVIRONMENT_MULT[env]
			worst = env
	return worst


func get_safe_environment_count() -> int:
	return get_safe_environments().size()


func get_organic_material_count() -> int:
	var count: int = 0
	for mid: String in MATERIAL_RATES:
		if MATERIAL_RATES[mid] >= 3.0:
			count += 1
	return count

func get_rate_range() -> float:
	var mn: float = 999.0
	var mx: float = 0.0
	for mid: String in MATERIAL_RATES:
		mn = minf(mn, MATERIAL_RATES[mid])
		mx = maxf(mx, MATERIAL_RATES[mid])
	return snappedf(mx - mn, 0.01)

func get_moderate_env_count() -> int:
	var count: int = 0
	for env: String in ENVIRONMENT_MULT:
		var v: float = ENVIRONMENT_MULT[env]
		if v > 0.0 and v <= 2.0:
			count += 1
	return count

func get_preservation_rating() -> String:
	var safe: int = get_safe_environment_count()
	var total: int = ENVIRONMENT_MULT.size()
	if total <= 0:
		return "Unknown"
	var ratio: float = float(safe) / float(total)
	if ratio >= 0.7:
		return "Well Preserved"
	elif ratio >= 0.4:
		return "Moderate"
	return "At Risk"

func get_durability_score() -> float:
	var avg: float = get_avg_deterioration_rate()
	return snappedf(maxf(0.0, 100.0 - avg * 100.0), 0.1)

func get_organic_risk_pct() -> float:
	if MATERIAL_RATES.is_empty():
		return 0.0
	return snappedf(float(get_organic_material_count()) / float(MATERIAL_RATES.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"material_types": MATERIAL_RATES.size(),
		"environment_types": ENVIRONMENT_MULT.size(),
		"most_durable": get_most_durable_material(),
		"most_fragile": get_most_fragile_material(),
		"avg_rate": get_avg_deterioration_rate(),
		"worst_environment": get_worst_environment(),
		"safe_environments": get_safe_environment_count(),
		"dangerous_env_count": ENVIRONMENT_MULT.size() - get_safe_environment_count(),
		"organic_materials": get_organic_material_count(),
		"rate_range": get_rate_range(),
		"moderate_env": get_moderate_env_count(),
		"preservation_rating": get_preservation_rating(),
		"durability_score": get_durability_score(),
		"organic_risk_pct": get_organic_risk_pct(),
		"storage_climate_index": get_storage_climate_index(),
		"material_lifespan_outlook": get_material_lifespan_outlook(),
		"entropy_resistance": get_entropy_resistance(),
		"preservation_ecosystem_health": get_preservation_ecosystem_health(),
		"material_governance": get_material_governance(),
		"decay_management_index": get_decay_management_index(),
	}

func get_storage_climate_index() -> float:
	var safe := get_safe_environment_count()
	var total := ENVIRONMENT_MULT.size()
	if total <= 0:
		return 0.0
	return snapped(float(safe) / float(total) * 100.0, 0.1)

func get_material_lifespan_outlook() -> String:
	var durability := get_durability_score()
	var organic_risk := get_organic_risk_pct()
	if durability >= 80.0 and organic_risk < 30.0:
		return "Long-Lasting"
	elif durability >= 50.0:
		return "Moderate"
	return "Short-Lived"

func get_entropy_resistance() -> String:
	var preservation := get_preservation_rating()
	var avg_rate := get_avg_deterioration_rate()
	if preservation in ["Well Preserved"] and avg_rate < 0.3:
		return "High"
	elif preservation in ["Moderate", "Well Preserved"]:
		return "Medium"
	return "Low"

func get_preservation_ecosystem_health() -> float:
	var climate := get_storage_climate_index()
	var lifespan := get_material_lifespan_outlook()
	var l_val: float = 90.0 if lifespan == "Long-Lasting" else (60.0 if lifespan == "Moderate" else 30.0)
	var entropy := get_entropy_resistance()
	var e_val: float = 90.0 if entropy == "High" else (60.0 if entropy == "Medium" else 30.0)
	return snapped((climate + l_val + e_val) / 3.0, 0.1)

func get_material_governance() -> String:
	var health := get_preservation_ecosystem_health()
	var durability := get_durability_score()
	if health >= 65.0 and durability >= 60.0:
		return "Well Managed"
	elif health >= 35.0 or durability >= 35.0:
		return "Partial"
	return "Neglected"

func get_decay_management_index() -> float:
	var safe := get_safe_environment_count()
	var total := ENVIRONMENT_MULT.size()
	var organic_risk := get_organic_risk_pct()
	var safe_ratio := 0.0
	if total > 0:
		safe_ratio = float(safe) / float(total) * 100.0
	return snapped((safe_ratio + maxf(100.0 - organic_risk, 0.0)) / 2.0, 0.1)
