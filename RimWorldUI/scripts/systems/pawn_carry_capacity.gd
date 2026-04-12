extends Node

const BASE_CARRY: float = 35.0

const BODY_TYPE_MULT: Dictionary = {
	"Thin": 0.85, "Average": 1.0, "Hulk": 1.30, "Fat": 1.10
}

const MANIPULATION_FACTOR: float = 0.5

const GEAR_CARRY_BONUS: Dictionary = {
	"Backpack": 20.0, "PowerArmor": -10.0, "UtilityBelt": 8.0,
	"CarryHarness": 15.0, "MechanoidFrame": 25.0
}

func get_capacity(body_type: String, manipulation: float, gear: Array) -> float:
	var base: float = BASE_CARRY
	base *= BODY_TYPE_MULT.get(body_type, 1.0)
	base *= (1.0 + (manipulation - 1.0) * MANIPULATION_FACTOR)
	for g: String in gear:
		base += GEAR_CARRY_BONUS.get(g, 0.0)
	return maxf(base, 5.0)

func get_carry_speed_factor(current_weight: float, max_capacity: float) -> float:
	if max_capacity <= 0:
		return 0.5
	var ratio: float = current_weight / max_capacity
	if ratio <= 0.5:
		return 1.0
	elif ratio <= 0.8:
		return 1.0 - (ratio - 0.5) * 0.5
	elif ratio <= 1.0:
		return 0.75 - (ratio - 0.8) * 1.25
	else:
		return 0.5

func get_best_body_type() -> String:
	var best: String = ""
	var best_mult: float = 0.0
	for bt: String in BODY_TYPE_MULT:
		if BODY_TYPE_MULT[bt] > best_mult:
			best_mult = BODY_TYPE_MULT[bt]
			best = bt
	return best


func get_best_gear_bonus() -> String:
	var best: String = ""
	var best_bonus: float = 0.0
	for g: String in GEAR_CARRY_BONUS:
		if GEAR_CARRY_BONUS[g] > best_bonus:
			best_bonus = GEAR_CARRY_BONUS[g]
			best = g
	return best


func get_max_possible_capacity() -> float:
	var max_body: float = 0.0
	for bt: String in BODY_TYPE_MULT:
		max_body = maxf(max_body, BODY_TYPE_MULT[bt])
	var gear_total: float = 0.0
	for g: String in GEAR_CARRY_BONUS:
		if GEAR_CARRY_BONUS[g] > 0:
			gear_total += GEAR_CARRY_BONUS[g]
	return BASE_CARRY * max_body + gear_total


func get_avg_body_mult() -> float:
	var total: float = 0.0
	for bt: String in BODY_TYPE_MULT:
		total += BODY_TYPE_MULT[bt]
	return total / maxf(BODY_TYPE_MULT.size(), 1)


func get_penalty_gear_count() -> int:
	var count: int = 0
	for g: String in GEAR_CARRY_BONUS:
		if GEAR_CARRY_BONUS[g] < 0:
			count += 1
	return count


func get_min_capacity() -> float:
	var min_body: float = 999.0
	for bt: String in BODY_TYPE_MULT:
		min_body = minf(min_body, BODY_TYPE_MULT[bt])
	return maxf(BASE_CARRY * min_body, 5.0)


func get_total_positive_gear_bonus() -> float:
	var total: float = 0.0
	for g: String in GEAR_CARRY_BONUS:
		if GEAR_CARRY_BONUS[g] > 0:
			total += GEAR_CARRY_BONUS[g]
	return total


func get_worst_body_type() -> String:
	var worst: String = ""
	var worst_mult: float = 99.0
	for bt: String in BODY_TYPE_MULT:
		if BODY_TYPE_MULT[bt] < worst_mult:
			worst_mult = BODY_TYPE_MULT[bt]
			worst = bt
	return worst


func get_capacity_range() -> Dictionary:
	return {"min": snapped(get_min_capacity(), 0.1), "max": snapped(get_max_possible_capacity(), 0.1)}


func get_body_type_spread() -> float:
	var mn: float = 99.0
	var mx: float = 0.0
	for bt: String in BODY_TYPE_MULT:
		mn = minf(mn, BODY_TYPE_MULT[bt])
		mx = maxf(mx, BODY_TYPE_MULT[bt])
	return snappedf(mx - mn, 0.01)

func get_avg_gear_bonus() -> float:
	var total: float = 0.0
	var cnt: int = 0
	for g: String in GEAR_CARRY_BONUS:
		if GEAR_CARRY_BONUS[g] > 0:
			total += GEAR_CARRY_BONUS[g]
			cnt += 1
	if cnt == 0:
		return 0.0
	return snappedf(total / float(cnt), 0.01)

func get_bonus_gear_count() -> int:
	var count: int = 0
	for g: String in GEAR_CARRY_BONUS:
		if GEAR_CARRY_BONUS[g] > 0:
			count += 1
	return count

func get_hauling_tier() -> String:
	var avg: float = get_avg_body_mult()
	if avg >= 1.2:
		return "Heavy"
	elif avg >= 0.9:
		return "Standard"
	elif avg >= 0.6:
		return "Light"
	return "Minimal"

func get_gear_impact_pct() -> float:
	var bonus: int = get_bonus_gear_count()
	var penalty: int = get_penalty_gear_count()
	var total: int = GEAR_CARRY_BONUS.size()
	if total == 0:
		return 0.0
	return snappedf(float(bonus) / float(total) * 100.0, 0.1)

func get_capacity_balance() -> String:
	var spread: float = get_body_type_spread()
	if spread <= 0.1:
		return "Uniform"
	elif spread <= 0.3:
		return "Balanced"
	elif spread <= 0.5:
		return "Varied"
	return "Extreme"

func get_summary() -> Dictionary:
	return {
		"body_types": BODY_TYPE_MULT.size(),
		"gear_bonuses": GEAR_CARRY_BONUS.size(),
		"base_carry": BASE_CARRY,
		"max_possible": snapped(get_max_possible_capacity(), 0.1),
		"avg_body_mult": snapped(get_avg_body_mult(), 0.01),
		"penalty_gear": get_penalty_gear_count(),
		"min_capacity": snapped(get_min_capacity(), 0.1),
		"total_positive_bonus": get_total_positive_gear_bonus(),
		"worst_body_type": get_worst_body_type(),
		"capacity_range": get_capacity_range(),
		"body_type_spread": get_body_type_spread(),
		"avg_gear_bonus": get_avg_gear_bonus(),
		"bonus_gear_count": get_bonus_gear_count(),
		"hauling_tier": get_hauling_tier(),
		"gear_impact_pct": get_gear_impact_pct(),
		"capacity_balance": get_capacity_balance(),
		"load_bearing_efficiency": get_load_bearing_efficiency(),
		"gear_optimization_score": get_gear_optimization_score(),
		"hauling_sustainability": get_hauling_sustainability(),
		"hauling_ecosystem_health": get_hauling_ecosystem_health(),
		"cargo_governance": get_cargo_governance(),
		"logistics_maturity_index": get_logistics_maturity_index(),
	}

func get_load_bearing_efficiency() -> float:
	var avg_mult := get_avg_body_mult()
	var avg_bonus := get_avg_gear_bonus()
	return snapped((avg_mult + avg_bonus) * 50.0, 0.1)

func get_gear_optimization_score() -> String:
	var bonus := get_bonus_gear_count()
	var penalty := get_penalty_gear_count()
	if bonus > penalty * 2:
		return "Optimized"
	elif bonus >= penalty:
		return "Balanced"
	return "Suboptimal"

func get_hauling_sustainability() -> String:
	var tier := get_hauling_tier()
	var balance := get_capacity_balance()
	if tier in ["Heavy", "Excellent"] and balance in ["Balanced", "Optimal"]:
		return "Sustainable"
	elif tier in ["Medium", "Heavy"]:
		return "Adequate"
	return "Strained"

func get_hauling_ecosystem_health() -> float:
	var sustainability := get_hauling_sustainability()
	var s_val: float = 90.0 if sustainability == "Sustainable" else (60.0 if sustainability == "Adequate" else 30.0)
	var optimization := get_gear_optimization_score()
	var o_val: float = 90.0 if optimization == "Optimized" else (60.0 if optimization == "Balanced" else 30.0)
	var efficiency := get_load_bearing_efficiency()
	return snapped((s_val + o_val + minf(efficiency, 100.0)) / 3.0, 0.1)

func get_logistics_maturity_index() -> float:
	var tier := get_hauling_tier()
	var t_val: float = 90.0 if tier in ["Heavy", "Excellent"] else (60.0 if tier in ["Medium"] else 30.0)
	var impact := get_gear_impact_pct()
	var balance := get_capacity_balance()
	var b_val: float = 90.0 if balance in ["Balanced", "Optimal"] else (60.0 if balance == "Adequate" else 30.0)
	return snapped((t_val + impact + b_val) / 3.0, 0.1)

func get_cargo_governance() -> String:
	var ecosystem := get_hauling_ecosystem_health()
	var maturity := get_logistics_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif GEAR_CARRY_BONUS.size() > 0:
		return "Nascent"
	return "Dormant"
