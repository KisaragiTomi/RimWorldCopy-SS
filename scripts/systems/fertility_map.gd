extends Node

const FERTILITY_VALUES: Dictionary = {
	"Soil": 1.0,
	"RichSoil": 1.4,
	"GravelySoil": 0.7,
	"MarshySoil": 1.0,
	"Sand": 0.1,
	"Ice": 0.0,
	"SoftSand": 0.05,
	"PackedDirt": 0.5,
	"Mud": 0.8,
	"Concrete": 0.0,
	"StoneTile": 0.0,
	"WoodPlank": 0.0,
}

const CROP_MIN_FERTILITY: Dictionary = {
	"Rice": 0.5,
	"Corn": 0.6,
	"Potato": 0.4,
	"Strawberry": 0.7,
	"Cotton": 0.5,
	"Healroot": 0.6,
	"Devilstrand": 0.8,
	"Hops": 0.5,
}


func get_fertility(terrain_id: String) -> float:
	return FERTILITY_VALUES.get(terrain_id, 0.0)


func can_grow_crop(terrain_id: String, crop_id: String) -> bool:
	var fertility: float = get_fertility(terrain_id)
	var min_req: float = CROP_MIN_FERTILITY.get(crop_id, 0.5)
	return fertility >= min_req


func get_growable_crops(terrain_id: String) -> Array[String]:
	var fertility: float = get_fertility(terrain_id)
	var result: Array[String] = []
	for crop: String in CROP_MIN_FERTILITY:
		if fertility >= CROP_MIN_FERTILITY[crop]:
			result.append(crop)
	return result


func get_best_terrain_for_crop(crop_id: String) -> String:
	var min_req: float = CROP_MIN_FERTILITY.get(crop_id, 0.5)
	var best: String = ""
	var best_fert: float = -1.0
	for terrain: String in FERTILITY_VALUES:
		var fert: float = FERTILITY_VALUES[terrain]
		if fert >= min_req and fert > best_fert:
			best_fert = fert
			best = terrain
	return best


func get_fertile_terrains() -> Array[String]:
	var result: Array[String] = []
	for terrain: String in FERTILITY_VALUES:
		if FERTILITY_VALUES[terrain] > 0.0:
			result.append(terrain)
	return result


func get_barren_terrains() -> Array[String]:
	var result: Array[String] = []
	for terrain: String in FERTILITY_VALUES:
		if FERTILITY_VALUES[terrain] <= 0.0:
			result.append(terrain)
	return result


func get_avg_fertility() -> float:
	if FERTILITY_VALUES.is_empty():
		return 0.0
	var total: float = 0.0
	for t: String in FERTILITY_VALUES:
		total += FERTILITY_VALUES[t]
	return snappedf(total / float(FERTILITY_VALUES.size()), 0.01)


func get_most_fertile_terrain() -> String:
	var best: String = ""
	var best_val: float = -1.0
	for t: String in FERTILITY_VALUES:
		if FERTILITY_VALUES[t] > best_val:
			best_val = FERTILITY_VALUES[t]
			best = t
	return best


func get_most_demanding_crop() -> String:
	var worst: String = ""
	var worst_req: float = -1.0
	for c: String in CROP_MIN_FERTILITY:
		if CROP_MIN_FERTILITY[c] > worst_req:
			worst_req = CROP_MIN_FERTILITY[c]
			worst = c
	return worst


func get_soil_quality() -> String:
	var avg: float = get_avg_fertility()
	if avg >= 1.2:
		return "Excellent"
	elif avg >= 0.8:
		return "Good"
	elif avg >= 0.5:
		return "Fair"
	return "Poor"

func get_crop_viability_pct() -> float:
	if CROP_MIN_FERTILITY.is_empty():
		return 0.0
	var viable: int = 0
	var avg: float = get_avg_fertility()
	for crop: String in CROP_MIN_FERTILITY:
		if avg >= CROP_MIN_FERTILITY[crop]:
			viable += 1
	return snappedf(float(viable) / float(CROP_MIN_FERTILITY.size()) * 100.0, 0.1)

func get_farming_potential() -> String:
	var fertile_pct: float = float(get_fertile_terrains().size()) / maxf(float(FERTILITY_VALUES.size()), 1.0)
	if fertile_pct >= 0.6:
		return "High"
	elif fertile_pct >= 0.3:
		return "Moderate"
	elif fertile_pct > 0.0:
		return "Low"
	return "None"

func get_summary() -> Dictionary:
	return {
		"terrain_types": FERTILITY_VALUES.size(),
		"crop_types": CROP_MIN_FERTILITY.size(),
		"fertile_count": get_fertile_terrains().size(),
		"barren_count": get_barren_terrains().size(),
		"avg_fertility": get_avg_fertility(),
		"most_fertile": get_most_fertile_terrain(),
		"most_demanding_crop": get_most_demanding_crop(),
		"fertile_pct": snappedf(float(get_fertile_terrains().size()) / maxf(float(FERTILITY_VALUES.size()), 1.0) * 100.0, 0.1),
		"plantable_crops": CROP_MIN_FERTILITY.size(),
		"soil_quality": get_soil_quality(),
		"crop_viability_pct": get_crop_viability_pct(),
		"farming_potential": get_farming_potential(),
		"soil_optimization": get_soil_optimization(),
		"biodiversity_index": get_biodiversity_index(),
		"famine_resilience": get_famine_resilience(),
		"agricultural_mastery": get_agricultural_mastery(),
		"terrain_utilization_index": get_terrain_utilization_index(),
		"crop_security": get_crop_security(),
	}

func get_agricultural_mastery() -> float:
	var viability := get_crop_viability_pct()
	var avg_fert := get_avg_fertility()
	return snapped(viability * avg_fert, 0.1)

func get_terrain_utilization_index() -> float:
	var fertile := float(get_fertile_terrains().size())
	var total := float(FERTILITY_VALUES.size())
	if total <= 0.0:
		return 0.0
	return snapped(fertile / total * 100.0, 0.1)

func get_crop_security() -> String:
	var resilience := get_famine_resilience()
	var optimization := get_soil_optimization()
	if resilience == "Resilient" and optimization in ["Optimal", "Excellent"]:
		return "Secure"
	elif resilience == "Vulnerable":
		return "At Risk"
	return "Moderate"

func get_soil_optimization() -> String:
	var quality := get_soil_quality()
	var viability := get_crop_viability_pct()
	if quality in ["Rich", "Excellent"] and viability >= 70.0:
		return "Optimized"
	elif viability >= 40.0:
		return "Adequate"
	return "Under-utilized"

func get_biodiversity_index() -> float:
	var crops := CROP_MIN_FERTILITY.size()
	var fertile := get_fertile_terrains().size()
	return snapped(float(crops * fertile) / maxf(float(FERTILITY_VALUES.size()), 1.0), 0.1)

func get_famine_resilience() -> String:
	var potential := get_farming_potential()
	var barren := get_barren_terrains().size()
	if potential in ["High", "Excellent"] and barren <= 1:
		return "Resilient"
	elif potential in ["High", "Moderate"]:
		return "Moderate"
	return "Vulnerable"
