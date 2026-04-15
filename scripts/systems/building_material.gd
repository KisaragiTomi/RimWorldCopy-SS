extends Node

const MATERIALS: Dictionary = {
	"Wood": {"hp_mult": 0.65, "beauty": 1, "flammability": 1.0, "cost_mult": 0.5, "work_mult": 0.7},
	"Stone": {"hp_mult": 1.5, "beauty": 2, "flammability": 0.0, "cost_mult": 1.0, "work_mult": 2.0},
	"Steel": {"hp_mult": 1.0, "beauty": 0, "flammability": 0.0, "cost_mult": 1.2, "work_mult": 1.0},
	"Plasteel": {"hp_mult": 2.5, "beauty": 1, "flammability": 0.0, "cost_mult": 3.0, "work_mult": 1.5},
	"Gold": {"hp_mult": 0.6, "beauty": 10, "flammability": 0.0, "cost_mult": 5.0, "work_mult": 0.8},
	"Silver": {"hp_mult": 0.7, "beauty": 6, "flammability": 0.0, "cost_mult": 3.5, "work_mult": 0.8},
	"Uranium": {"hp_mult": 2.0, "beauty": -2, "flammability": 0.0, "cost_mult": 4.0, "work_mult": 2.5},
	"Jade": {"hp_mult": 0.5, "beauty": 12, "flammability": 0.0, "cost_mult": 4.5, "work_mult": 1.0},
	"Granite": {"hp_mult": 1.7, "beauty": 1, "flammability": 0.0, "cost_mult": 1.0, "work_mult": 2.2},
	"Marble": {"hp_mult": 1.2, "beauty": 4, "flammability": 0.0, "cost_mult": 1.0, "work_mult": 1.8},
	"Sandstone": {"hp_mult": 1.1, "beauty": 2, "flammability": 0.0, "cost_mult": 1.0, "work_mult": 1.5},
	"Slate": {"hp_mult": 1.3, "beauty": 2, "flammability": 0.0, "cost_mult": 1.0, "work_mult": 1.8},
	"Limestone": {"hp_mult": 1.4, "beauty": 1, "flammability": 0.0, "cost_mult": 1.0, "work_mult": 1.9},
}


func get_material(mat_id: String) -> Dictionary:
	return MATERIALS.get(mat_id, {})


func calc_hp(base_hp: float, material: String) -> float:
	var mat: Dictionary = get_material(material)
	return base_hp * float(mat.get("hp_mult", 1.0))


func calc_beauty(base_beauty: int, material: String) -> int:
	var mat: Dictionary = get_material(material)
	return base_beauty + int(mat.get("beauty", 0))


func is_flammable(material: String) -> bool:
	var mat: Dictionary = get_material(material)
	return float(mat.get("flammability", 0.0)) > 0.0


func get_strongest_material() -> String:
	var best: String = ""
	var best_hp: float = 0.0
	for mid: String in MATERIALS:
		if float(MATERIALS[mid].get("hp_mult", 0.0)) > best_hp:
			best_hp = float(MATERIALS[mid].get("hp_mult", 0.0))
			best = mid
	return best


func get_most_beautiful_material() -> String:
	var best: String = ""
	var best_beauty: int = -999
	for mid: String in MATERIALS:
		var b: int = int(MATERIALS[mid].get("beauty", 0))
		if b > best_beauty:
			best_beauty = b
			best = mid
	return best


func get_fireproof_materials() -> Array[String]:
	var result: Array[String] = []
	for mid: String in MATERIALS:
		if not is_flammable(mid):
			result.append(mid)
	return result


func get_cheapest_material() -> String:
	var best: String = ""
	var best_cost: float = 999999.0
	for mid: String in MATERIALS:
		var c: float = float(MATERIALS[mid].get("cost", 999.0))
		if c < best_cost:
			best_cost = c
			best = mid
	return best


func get_flammable_count() -> int:
	return MATERIALS.size() - get_fireproof_materials().size()


func get_avg_hp_mult() -> float:
	if MATERIALS.is_empty():
		return 0.0
	var total: float = 0.0
	for mid: String in MATERIALS:
		total += float(MATERIALS[mid].get("hp_mult", 1.0))
	return snappedf(total / float(MATERIALS.size()), 0.01)


func get_avg_beauty() -> float:
	if MATERIALS.is_empty():
		return 0.0
	var total: float = 0.0
	for mid: String in MATERIALS:
		total += float(MATERIALS[mid].get("beauty", 0))
	return snappedf(total / float(MATERIALS.size()), 0.1)


func get_avg_cost_mult() -> float:
	if MATERIALS.is_empty():
		return 0.0
	var total: float = 0.0
	for mid: String in MATERIALS:
		total += float(MATERIALS[mid].get("cost_mult", 1.0))
	return snappedf(total / float(MATERIALS.size()), 0.01)


func get_fastest_to_work() -> String:
	var best: String = ""
	var best_work: float = 999.0
	for mid: String in MATERIALS:
		var w: float = float(MATERIALS[mid].get("work_mult", 1.0))
		if w < best_work:
			best_work = w
			best = mid
	return best


func get_material_quality() -> String:
	var avg_hp: float = get_avg_hp_mult()
	if avg_hp >= 1.5:
		return "Premium"
	elif avg_hp >= 1.0:
		return "Standard"
	elif avg_hp >= 0.5:
		return "Economy"
	return "Fragile"

func get_fire_safety_pct() -> float:
	if MATERIALS.is_empty():
		return 0.0
	return snappedf(float(get_fireproof_materials().size()) / float(MATERIALS.size()) * 100.0, 0.1)

func get_aesthetic_value() -> String:
	var avg_b: float = get_avg_beauty()
	if avg_b >= 3.0:
		return "Luxurious"
	elif avg_b >= 1.0:
		return "Pleasant"
	elif avg_b >= 0.0:
		return "Plain"
	return "Ugly"

func get_summary() -> Dictionary:
	return {
		"material_count": MATERIALS.size(),
		"strongest": get_strongest_material(),
		"most_beautiful": get_most_beautiful_material(),
		"fireproof_count": get_fireproof_materials().size(),
		"cheapest": get_cheapest_material(),
		"flammable_count": get_flammable_count(),
		"avg_hp_mult": get_avg_hp_mult(),
		"avg_beauty": get_avg_beauty(),
		"avg_cost_mult": get_avg_cost_mult(),
		"fastest_to_work": get_fastest_to_work(),
		"material_quality": get_material_quality(),
		"fire_safety_pct": get_fire_safety_pct(),
		"aesthetic_value": get_aesthetic_value(),
		"structural_resilience": get_structural_resilience(),
		"material_economy": get_material_economy(),
		"construction_versatility": get_construction_versatility(),
		"material_ecosystem_health": get_material_ecosystem_health(),
		"engineering_sophistication": get_engineering_sophistication(),
		"construction_governance": get_construction_governance(),
	}

func get_structural_resilience() -> String:
	var quality := get_material_quality()
	var fire_safe := get_fire_safety_pct()
	if quality in ["Premium"] and fire_safe >= 50.0:
		return "Fortified"
	elif quality in ["Standard", "Premium"]:
		return "Solid"
	return "Weak"

func get_material_economy() -> float:
	var avg_cost := get_avg_cost_mult()
	var avg_hp := get_avg_hp_mult()
	if avg_cost <= 0.0:
		return 0.0
	return snapped(avg_hp / avg_cost * 100.0, 0.1)

func get_construction_versatility() -> String:
	var count := MATERIALS.size()
	if count >= 8:
		return "Extensive"
	elif count >= 4:
		return "Moderate"
	return "Limited"

func get_material_ecosystem_health() -> float:
	var economy := get_material_economy()
	var fire_safety := get_fire_safety_pct()
	var resilience := get_structural_resilience()
	var r_val: float = 90.0 if resilience == "Fortified" else (60.0 if resilience == "Solid" else 30.0)
	return snapped((minf(economy, 100.0) + fire_safety + r_val) / 3.0, 0.1)

func get_engineering_sophistication() -> float:
	var avg_hp := get_avg_hp_mult()
	var avg_beauty := get_avg_beauty()
	var versatility := get_construction_versatility()
	var v_val: float = 90.0 if versatility == "Extensive" else (60.0 if versatility == "Moderate" else 30.0)
	return snapped((minf(avg_hp * 50.0, 100.0) + minf(absf(avg_beauty) * 20.0, 100.0) + v_val) / 3.0, 0.1)

func get_construction_governance() -> String:
	var health := get_material_ecosystem_health()
	var sophistication := get_engineering_sophistication()
	if health >= 65.0 and sophistication >= 55.0:
		return "Mature"
	elif health >= 35.0 or sophistication >= 30.0:
		return "Developing"
	return "Primitive"
