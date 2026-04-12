extends Node

const FLOOR_CONDUCTIVITY: Dictionary = {
	"Soil": 1.0, "Sand": 0.9, "Concrete": 1.5,
	"SteelTile": 2.0, "WoodFloor": 0.6, "StoneTile": 1.3,
	"Carpet": 0.3, "SterileFloor": 1.4, "MarbleTile": 1.2,
	"GoldTile": 2.5, "FlagstoneGranite": 1.1, "FlagstoneLimestone": 1.0,
	"FlagstoneMarble": 1.1, "FlagstoneSandstone": 0.95, "FlagstoneSlate": 1.05
}

const INSULATION_BONUS: Dictionary = {
	"Carpet": 0.15, "WoodFloor": 0.10, "Soil": 0.0,
	"SteelTile": -0.05, "GoldTile": -0.10
}

func get_conductivity(floor_type: String) -> float:
	return FLOOR_CONDUCTIVITY.get(floor_type, 1.0)

func get_insulation(floor_type: String) -> float:
	return INSULATION_BONUS.get(floor_type, 0.0)

func calc_heat_transfer(floor_type: String, temp_diff: float) -> float:
	var conductivity: float = get_conductivity(floor_type)
	return temp_diff * conductivity * 0.1

func get_room_floor_effect(floor_types: Array) -> Dictionary:
	if floor_types.is_empty():
		return {"avg_conductivity": 1.0, "total_insulation": 0.0}
	var total_c: float = 0.0
	var total_i: float = 0.0
	for ft: String in floor_types:
		total_c += get_conductivity(ft)
		total_i += get_insulation(ft)
	return {
		"avg_conductivity": total_c / floor_types.size(),
		"total_insulation": total_i / floor_types.size()
	}

func get_best_insulator() -> String:
	var best: String = ""
	var best_val: float = -999.0
	for ft: String in INSULATION_BONUS:
		if INSULATION_BONUS[ft] > best_val:
			best_val = INSULATION_BONUS[ft]
			best = ft
	return best


func get_most_conductive() -> String:
	var best: String = ""
	var best_val: float = 0.0
	for ft: String in FLOOR_CONDUCTIVITY:
		if FLOOR_CONDUCTIVITY[ft] > best_val:
			best_val = FLOOR_CONDUCTIVITY[ft]
			best = ft
	return best


func get_avg_conductivity() -> float:
	var total: float = 0.0
	for ft: String in FLOOR_CONDUCTIVITY:
		total += FLOOR_CONDUCTIVITY[ft]
	return total / maxf(FLOOR_CONDUCTIVITY.size(), 1)


func get_low_conductivity_count(threshold: float = 0.8) -> int:
	var count: int = 0
	for ft: String in FLOOR_CONDUCTIVITY:
		if FLOOR_CONDUCTIVITY[ft] < threshold:
			count += 1
	return count


func get_worst_insulator() -> String:
	var worst: String = ""
	var worst_val: float = 999.0
	for ft: String in INSULATION_BONUS:
		if INSULATION_BONUS[ft] < worst_val:
			worst_val = INSULATION_BONUS[ft]
			worst = ft
	return worst


func get_conductivity_range() -> Dictionary:
	var lo: float = 999.0
	var hi: float = 0.0
	for ft: String in FLOOR_CONDUCTIVITY:
		var v: float = FLOOR_CONDUCTIVITY[ft]
		if v < lo:
			lo = v
		if v > hi:
			hi = v
	return {"min": snapped(lo, 0.01), "max": snapped(hi, 0.01)}


func get_positive_insulation_count() -> int:
	var count: int = 0
	for ft: String in INSULATION_BONUS:
		if float(INSULATION_BONUS[ft]) > 0.0:
			count += 1
	return count


func get_avg_insulation() -> float:
	if INSULATION_BONUS.is_empty():
		return 0.0
	var total: float = 0.0
	for ft: String in INSULATION_BONUS:
		total += float(INSULATION_BONUS[ft])
	return snappedf(total / float(INSULATION_BONUS.size()), 0.01)


func get_thermal_efficiency() -> String:
	var avg: float = get_avg_insulation()
	if avg >= 5.0:
		return "Excellent"
	elif avg >= 2.0:
		return "Good"
	elif avg >= 0.0:
		return "Adequate"
	return "Poor"

func get_energy_waste_risk() -> float:
	if FLOOR_CONDUCTIVITY.is_empty():
		return 0.0
	var high_cond: int = 0
	for fid: String in FLOOR_CONDUCTIVITY:
		if FLOOR_CONDUCTIVITY[fid] > 1.0:
			high_cond += 1
	return snappedf(float(high_cond) / float(FLOOR_CONDUCTIVITY.size()) * 100.0, 0.1)

func get_climate_readiness() -> String:
	var pos_ins: int = get_positive_insulation_count()
	var total: int = INSULATION_BONUS.size()
	if total == 0:
		return "None"
	var pct: float = float(pos_ins) / float(total) * 100.0
	if pct >= 70.0:
		return "Winter Ready"
	elif pct >= 40.0:
		return "Moderate"
	return "Vulnerable"

func get_summary() -> Dictionary:
	return {
		"floor_types": FLOOR_CONDUCTIVITY.size(),
		"insulation_entries": INSULATION_BONUS.size(),
		"best_insulator": get_best_insulator(),
		"most_conductive": get_most_conductive(),
		"avg_conductivity": snapped(get_avg_conductivity(), 0.01),
		"low_conductivity_floors": get_low_conductivity_count(),
		"worst_insulator": get_worst_insulator(),
		"conductivity_range": get_conductivity_range(),
		"positive_insulation_count": get_positive_insulation_count(),
		"avg_insulation": get_avg_insulation(),
		"thermal_efficiency": get_thermal_efficiency(),
		"energy_waste_risk_pct": get_energy_waste_risk(),
		"climate_readiness": get_climate_readiness(),
		"insulation_coverage": get_insulation_coverage(),
		"thermal_optimization": get_thermal_optimization(),
		"heating_cost_index": get_heating_cost_index(),
		"thermal_ecosystem_health": get_thermal_ecosystem_health(),
		"climate_governance": get_climate_governance(),
		"insulation_maturity_index": get_insulation_maturity_index(),
	}

func get_insulation_coverage() -> float:
	var positive := get_positive_insulation_count()
	var total := INSULATION_BONUS.size()
	if total <= 0:
		return 0.0
	return snapped(float(positive) / float(total) * 100.0, 0.1)

func get_thermal_optimization() -> String:
	var efficiency := get_thermal_efficiency()
	var waste := get_energy_waste_risk()
	if efficiency in ["Excellent"] and waste < 20.0:
		return "Optimized"
	elif efficiency in ["Good", "Excellent"]:
		return "Adequate"
	return "Needs Work"

func get_heating_cost_index() -> float:
	var avg_cond := get_avg_conductivity()
	return snapped(avg_cond * 100.0, 0.1)

func get_thermal_ecosystem_health() -> float:
	var optimization := get_thermal_optimization()
	var opt_val: float = 90.0 if optimization == "Optimized" else (60.0 if optimization == "Adequate" else 30.0)
	var coverage := get_insulation_coverage()
	var cost := get_heating_cost_index()
	var cost_val: float = maxf(100.0 - cost, 0.0)
	return snapped((opt_val + coverage + cost_val) / 3.0, 0.1)

func get_insulation_maturity_index() -> float:
	var efficiency := get_thermal_efficiency()
	var e_val: float = 90.0 if efficiency == "Excellent" else (70.0 if efficiency == "Good" else (40.0 if efficiency == "Average" else 20.0))
	var waste := get_energy_waste_risk()
	var w_val: float = maxf(100.0 - waste, 0.0)
	var readiness := get_climate_readiness()
	var r_val: float = 90.0 if readiness in ["Excellent", "Prepared"] else (60.0 if readiness in ["Moderate", "Adequate"] else 30.0)
	return snapped((e_val + w_val + r_val) / 3.0, 0.1)

func get_climate_governance() -> String:
	var ecosystem := get_thermal_ecosystem_health()
	var maturity := get_insulation_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif FLOOR_CONDUCTIVITY.size() > 0:
		return "Nascent"
	return "Dormant"
