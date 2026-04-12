extends Node

var _caravans: Dictionary = {}

const SUPPLY_RATES: Dictionary = {
	"food_per_pawn_per_day": 1.6,
	"food_per_animal_per_day": 0.8,
	"medicine_per_injury": 1.0,
	"silver_per_trade_stop": 0.0
}

const PACK_ANIMALS: Dictionary = {
	"Muffalo": {"carry_mass": 73.5, "speed": 4.6, "food_type": "Herbivore"},
	"Dromedary": {"carry_mass": 70.0, "speed": 4.8, "food_type": "Herbivore"},
	"Elephant": {"carry_mass": 140.0, "speed": 4.0, "food_type": "Herbivore"},
	"Horse": {"carry_mass": 70.0, "speed": 5.4, "food_type": "Herbivore"},
	"Donkey": {"carry_mass": 50.0, "speed": 4.5, "food_type": "Herbivore"},
	"Alpaca": {"carry_mass": 35.0, "speed": 4.6, "food_type": "Herbivore"},
	"Yak": {"carry_mass": 60.0, "speed": 4.0, "food_type": "Herbivore"},
	"Thrumbo": {"carry_mass": 200.0, "speed": 4.2, "food_type": "Dendrovore"}
}

const TERRAIN_SPEED_MULT: Dictionary = {
	"Road": 1.4,
	"Flat": 1.0,
	"Hills": 0.7,
	"Mountains": 0.5,
	"Swamp": 0.6,
	"Desert": 0.8,
	"Ice": 0.5
}

func create_caravan(caravan_id: String, pawns: int, animals: Dictionary) -> Dictionary:
	var total_carry: float = 0.0
	for atype: String in animals:
		if PACK_ANIMALS.has(atype):
			total_carry += PACK_ANIMALS[atype]["carry_mass"] * animals[atype]
	_caravans[caravan_id] = {"pawns": pawns, "animals": animals, "carry_capacity": total_carry, "days_out": 0, "food_remaining": 0.0}
	return {"created": caravan_id, "carry_capacity": total_carry}

func advance_day(caravan_id: String, terrain: String) -> Dictionary:
	if not _caravans.has(caravan_id):
		return {"error": "unknown_caravan"}
	var c: Dictionary = _caravans[caravan_id]
	c["days_out"] += 1
	var animal_count: int = 0
	for atype: String in c["animals"]:
		animal_count += c["animals"][atype]
	var food_consumed: float = c["pawns"] * SUPPLY_RATES["food_per_pawn_per_day"] + animal_count * SUPPLY_RATES["food_per_animal_per_day"]
	c["food_remaining"] -= food_consumed
	var speed_mult: float = TERRAIN_SPEED_MULT.get(terrain, 1.0)
	return {"day": c["days_out"], "food_consumed": food_consumed, "food_remaining": c["food_remaining"], "speed_mult": speed_mult}

func get_best_pack_animal() -> String:
	var best: String = ""
	var best_carry: float = 0.0
	for a: String in PACK_ANIMALS:
		if PACK_ANIMALS[a]["carry_mass"] > best_carry:
			best_carry = PACK_ANIMALS[a]["carry_mass"]
			best = a
	return best

func get_fastest_animal() -> String:
	var best: String = ""
	var best_spd: float = 0.0
	for a: String in PACK_ANIMALS:
		if PACK_ANIMALS[a]["speed"] > best_spd:
			best_spd = PACK_ANIMALS[a]["speed"]
			best = a
	return best

func get_starving_caravans() -> Array[String]:
	var result: Array[String] = []
	for cid: String in _caravans:
		if _caravans[cid]["food_remaining"] <= 0.0:
			result.append(cid)
	return result

func get_avg_carry_capacity() -> float:
	if PACK_ANIMALS.is_empty():
		return 0.0
	var total: float = 0.0
	for a: String in PACK_ANIMALS:
		total += float(PACK_ANIMALS[a].get("carry_capacity", 0))
	return total / PACK_ANIMALS.size()


func get_starving_caravan_count() -> int:
	var count: int = 0
	for cid: int in _caravans:
		if float(_caravans[cid].get("food_days", 999.0)) <= 0.0:
			count += 1
	return count


func get_slowest_terrain() -> String:
	var worst: String = ""
	var worst_mult: float = 999.0
	for t: String in TERRAIN_SPEED_MULT:
		var m: float = float(TERRAIN_SPEED_MULT[t])
		if m < worst_mult:
			worst_mult = m
			worst = t
	return worst


func get_dendrovore_animal_count() -> int:
	var count: int = 0
	for a: String in PACK_ANIMALS:
		if String(PACK_ANIMALS[a].get("food_type", "")) == "Dendrovore":
			count += 1
	return count


func get_fastest_terrain() -> String:
	var best: String = ""
	var best_m: float = 0.0
	for t: String in TERRAIN_SPEED_MULT:
		var m: float = float(TERRAIN_SPEED_MULT[t])
		if m > best_m:
			best_m = m
			best = t
	return best


func get_total_carry_capacity_all_types() -> float:
	var total: float = 0.0
	for a: String in PACK_ANIMALS:
		total += float(PACK_ANIMALS[a].get("carry_mass", 0.0))
	return total


func get_logistics_grade() -> String:
	var avg: float = get_avg_carry_capacity()
	var starving: int = get_starving_caravan_count()
	if _caravans.is_empty():
		return "no_caravans"
	if starving > 0:
		return "critical"
	if avg >= 100.0:
		return "excellent"
	if avg >= 50.0:
		return "adequate"
	return "strained"

func get_mobility_index_pct() -> float:
	var fast_terrain: int = 0
	for t: String in TERRAIN_SPEED_MULT:
		if TERRAIN_SPEED_MULT[t] >= 1.0:
			fast_terrain += 1
	if TERRAIN_SPEED_MULT.is_empty():
		return 0.0
	return snapped(fast_terrain * 100.0 / TERRAIN_SPEED_MULT.size(), 0.1)

func get_supply_resilience() -> String:
	var total_carry: float = get_total_carry_capacity_all_types()
	var animal_count: int = PACK_ANIMALS.size()
	if animal_count == 0:
		return "none"
	var per_type: float = total_carry / animal_count
	if per_type >= 80.0:
		return "robust"
	if per_type >= 40.0:
		return "moderate"
	return "fragile"

func get_summary() -> Dictionary:
	return {
		"pack_animals": PACK_ANIMALS.size(),
		"terrain_types": TERRAIN_SPEED_MULT.size(),
		"active_caravans": _caravans.size(),
		"best_carrier": get_best_pack_animal(),
		"fastest_animal": get_fastest_animal(),
		"avg_carry": snapped(get_avg_carry_capacity(), 0.1),
		"starving": get_starving_caravan_count(),
		"slowest_terrain": get_slowest_terrain(),
		"dendrovore_animals": get_dendrovore_animal_count(),
		"fastest_terrain": get_fastest_terrain(),
		"total_carry_all": get_total_carry_capacity_all_types(),
		"logistics_grade": get_logistics_grade(),
		"mobility_index_pct": get_mobility_index_pct(),
		"supply_resilience": get_supply_resilience(),
		"expedition_readiness": get_expedition_readiness(),
		"terrain_adaptability": get_terrain_adaptability(),
		"caravan_endurance": get_caravan_endurance(),
		"logistics_ecosystem_health": get_logistics_ecosystem_health(),
		"supply_governance": get_supply_governance(),
		"expedition_maturity_index": get_expedition_maturity_index(),
	}

func get_expedition_readiness() -> String:
	var grade := get_logistics_grade()
	var starving := get_starving_caravan_count()
	if grade in ["Excellent", "Superior"] and starving == 0:
		return "Fully Prepared"
	elif starving == 0:
		return "Adequate"
	return "Unprepared"

func get_terrain_adaptability() -> float:
	var fast := 0
	for terrain: String in TERRAIN_SPEED_MULT:
		if TERRAIN_SPEED_MULT[terrain] >= 1.0:
			fast += 1
	var total := TERRAIN_SPEED_MULT.size()
	if total <= 0:
		return 0.0
	return snapped(float(fast) / float(total) * 100.0, 0.1)

func get_caravan_endurance() -> String:
	var resilience := get_supply_resilience()
	var dendro := get_dendrovore_animal_count()
	if resilience in ["High", "Excellent"] and dendro >= 2:
		return "Tireless"
	elif resilience in ["Moderate", "High"]:
		return "Sturdy"
	return "Fragile"

func get_logistics_ecosystem_health() -> float:
	var readiness := get_expedition_readiness()
	var r_val: float = 90.0 if readiness == "Fully Prepared" else (60.0 if readiness == "Adequate" else 30.0)
	var endurance := get_caravan_endurance()
	var e_val: float = 90.0 if endurance == "Tireless" else (60.0 if endurance == "Sturdy" else 30.0)
	var adaptability := get_terrain_adaptability()
	return snapped((r_val + e_val + adaptability) / 3.0, 0.1)

func get_expedition_maturity_index() -> float:
	var grade := get_logistics_grade()
	var g_val: float = 90.0 if grade in ["Excellent", "Superior"] else (60.0 if grade in ["Good", "Adequate"] else 30.0)
	var mobility := get_mobility_index_pct()
	var resilience := get_supply_resilience()
	var res_val: float = 90.0 if resilience in ["High", "Excellent"] else (60.0 if resilience in ["Moderate", "Adequate"] else 30.0)
	return snapped((g_val + mobility + res_val) / 3.0, 0.1)

func get_supply_governance() -> String:
	var ecosystem := get_logistics_ecosystem_health()
	var maturity := get_expedition_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _caravans.size() > 0:
		return "Nascent"
	return "Dormant"
