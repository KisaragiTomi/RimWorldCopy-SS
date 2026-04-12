extends Node

const BIOME_PLANTS: Dictionary = {
	"TemperateForest": ["Oak", "Birch", "Poplar", "Berry Bush", "Healroot", "Grass", "Dandelion", "Wild Rose"],
	"BorealForest": ["Pine", "Spruce", "Birch", "Berry Bush", "Healroot", "Moss"],
	"Tundra": ["Moss", "Arctic Lichen", "Scrub Bush"],
	"IceSheet": [],
	"Desert": ["Cactus", "Agave", "Desert Shrub", "Tumbleweed"],
	"ExtremeDesert": ["Cactus"],
	"AridShrubland": ["Cactus", "Agave", "Scrub Bush", "Dry Grass", "Berry Bush"],
	"TropicalRainforest": ["Palm", "Bamboo", "Teak", "Banana Plant", "Berry Bush", "Healroot", "Fern", "Orchid"],
	"TropicalSwamp": ["Mangrove", "Bamboo", "Water Lily", "Fern", "Healroot"],
	"Swamp": ["Willow", "Moss", "Water Lily", "Cattail", "Healroot"],
	"SeaIce": [],
}

const PLANT_PROPERTIES: Dictionary = {
	"Oak": {"growth_days": 30, "yield": "Wood", "beauty": 1},
	"Pine": {"growth_days": 25, "yield": "Wood", "beauty": 1},
	"Birch": {"growth_days": 20, "yield": "Wood", "beauty": 2},
	"Palm": {"growth_days": 22, "yield": "Wood", "beauty": 2},
	"Bamboo": {"growth_days": 12, "yield": "Wood", "beauty": 1},
	"Cactus": {"growth_days": 35, "yield": "None", "beauty": 0},
	"Berry Bush": {"growth_days": 8, "yield": "Berries", "beauty": 1},
	"Healroot": {"growth_days": 15, "yield": "Herbal Medicine", "beauty": 1},
	"Grass": {"growth_days": 3, "yield": "None", "beauty": 1},
	"Moss": {"growth_days": 5, "yield": "None", "beauty": 0},
}


func get_plants_for_biome(biome: String) -> Array:
	return BIOME_PLANTS.get(biome, [])


func get_plant_info(plant_name: String) -> Dictionary:
	return PLANT_PROPERTIES.get(plant_name, {})


func get_richest_biome() -> String:
	var best: String = ""
	var best_count: int = 0
	for biome: String in BIOME_PLANTS:
		if BIOME_PLANTS[biome].size() > best_count:
			best_count = BIOME_PLANTS[biome].size()
			best = biome
	return best


func get_barren_biomes() -> Array[String]:
	var result: Array[String] = []
	for biome: String in BIOME_PLANTS:
		if BIOME_PLANTS[biome].is_empty():
			result.append(biome)
	return result


func get_plants_yielding(yield_type: String) -> Array[String]:
	var result: Array[String] = []
	for plant: String in PLANT_PROPERTIES:
		if String(PLANT_PROPERTIES[plant].get("yield", "")) == yield_type:
			result.append(plant)
	return result


func get_avg_plants_per_biome() -> float:
	if BIOME_PLANTS.is_empty():
		return 0.0
	var total: int = 0
	for bid: String in BIOME_PLANTS:
		total += BIOME_PLANTS[bid].size()
	return snappedf(float(total) / float(BIOME_PLANTS.size()), 0.1)


func get_most_versatile_plant() -> String:
	var counts: Dictionary = {}
	for bid: String in BIOME_PLANTS:
		for p in BIOME_PLANTS[bid]:
			var pid: String = str(p)
			counts[pid] = counts.get(pid, 0) + 1
	var best: String = ""
	var best_n: int = 0
	for pid: String in counts:
		if counts[pid] > best_n:
			best_n = counts[pid]
			best = pid
	return best


func get_unique_plant_count() -> int:
	var plants: Dictionary = {}
	for bid: String in BIOME_PLANTS:
		for p in BIOME_PLANTS[bid]:
			plants[str(p)] = true
	return plants.size()


func get_food_plant_count() -> int:
	var count: int = 0
	for pid: String in PLANT_PROPERTIES:
		var y: String = String(PLANT_PROPERTIES[pid].get("yield", "None"))
		if y != "None" and y != "Wood" and not y.is_empty():
			count += 1
	return count


func get_avg_growth_days() -> float:
	if PLANT_PROPERTIES.is_empty():
		return 0.0
	var total: float = 0.0
	for pid: String in PLANT_PROPERTIES:
		total += float(PLANT_PROPERTIES[pid].get("growth_days", 0))
	return snappedf(total / float(PLANT_PROPERTIES.size()), 0.1)


func get_fastest_growing_plant() -> String:
	var best: String = ""
	var best_days: int = 99999
	for pid: String in PLANT_PROPERTIES:
		var d: int = int(PLANT_PROPERTIES[pid].get("growth_days", 99999))
		if d < best_days:
			best_days = d
			best = pid
	return best


func get_biodiversity_rating() -> String:
	var unique: int = get_unique_plant_count()
	if unique >= 15:
		return "Rich"
	elif unique >= 8:
		return "Moderate"
	elif unique >= 3:
		return "Sparse"
	return "Barren"

func get_food_security_pct() -> float:
	if PLANT_PROPERTIES.is_empty():
		return 0.0
	return snappedf(float(get_food_plant_count()) / float(PLANT_PROPERTIES.size()) * 100.0, 0.1)

func get_growth_efficiency() -> String:
	var avg: float = get_avg_growth_days()
	if avg <= 5.0:
		return "Rapid"
	elif avg <= 10.0:
		return "Normal"
	elif avg <= 20.0:
		return "Slow"
	return "Very Slow"

func get_summary() -> Dictionary:
	return {
		"biome_count": BIOME_PLANTS.size(),
		"plant_types": PLANT_PROPERTIES.size(),
		"richest_biome": get_richest_biome(),
		"barren_biomes": get_barren_biomes().size(),
		"avg_per_biome": get_avg_plants_per_biome(),
		"most_versatile": get_most_versatile_plant(),
		"unique_plants": get_unique_plant_count(),
		"food_plants": get_food_plant_count(),
		"avg_growth_days": get_avg_growth_days(),
		"fastest_grower": get_fastest_growing_plant(),
		"biodiversity_rating": get_biodiversity_rating(),
		"food_security_pct": get_food_security_pct(),
		"growth_efficiency": get_growth_efficiency(),
		"agricultural_viability": get_agricultural_viability(),
		"ecosystem_richness": get_ecosystem_richness(),
		"harvest_readiness": get_harvest_readiness(),
		"botanical_ecosystem_health": get_botanical_ecosystem_health(),
		"agrarian_governance": get_agrarian_governance(),
		"flora_maturity_index": get_flora_maturity_index(),
	}

func get_agricultural_viability() -> String:
	var food_sec := get_food_security_pct()
	var efficiency := get_growth_efficiency()
	if food_sec >= 40.0 and efficiency in ["Rapid", "Normal"]:
		return "Viable"
	elif food_sec >= 20.0:
		return "Limited"
	return "Non-Viable"

func get_ecosystem_richness() -> float:
	var unique := get_unique_plant_count()
	var biomes := BIOME_PLANTS.size()
	if biomes <= 0:
		return 0.0
	return snapped(float(unique) / float(biomes), 0.1)

func get_harvest_readiness() -> String:
	var food := get_food_plant_count()
	var fastest := get_fastest_growing_plant()
	if food >= 5 and fastest != "":
		return "Ready"
	elif food >= 2:
		return "Partial"
	return "Not Ready"

func get_botanical_ecosystem_health() -> float:
	var biodiversity := get_biodiversity_rating()
	var b_val: float = 90.0 if biodiversity == "Diverse" else (60.0 if biodiversity == "Moderate" else 30.0)
	var food_sec := get_food_security_pct()
	var richness := get_ecosystem_richness()
	return snapped((b_val + food_sec + minf(richness * 20.0, 100.0)) / 3.0, 0.1)

func get_agrarian_governance() -> String:
	var health := get_botanical_ecosystem_health()
	var viability := get_agricultural_viability()
	if health >= 60.0 and viability in ["Viable", "Abundant"]:
		return "Sustainable"
	elif health >= 30.0:
		return "Developing"
	return "Subsistence"

func get_flora_maturity_index() -> float:
	var avg_growth := get_avg_growth_days()
	var harvest := get_harvest_readiness()
	var h_val: float = 90.0 if harvest == "Ready" else (60.0 if harvest == "Partial" else 30.0)
	var growth_score: float = maxf(100.0 - avg_growth * 5.0, 0.0)
	return snapped((growth_score + h_val) / 2.0, 0.1)
