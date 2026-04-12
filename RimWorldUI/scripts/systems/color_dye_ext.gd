extends Node

const DYES: Dictionary = {
	"Red": {"hex": "FF0000", "ingredient": "Psychoid", "cost": 3},
	"Blue": {"hex": "0000FF", "ingredient": "Devilstrand", "cost": 4},
	"Green": {"hex": "00FF00", "ingredient": "Haygrass", "cost": 2},
	"Yellow": {"hex": "FFFF00", "ingredient": "Healroot", "cost": 3},
	"Purple": {"hex": "800080", "ingredient": "Smokeleaf", "cost": 3},
	"Orange": {"hex": "FFA500", "ingredient": "Corn", "cost": 2},
	"Pink": {"hex": "FF69B4", "ingredient": "Rose", "cost": 4},
	"White": {"hex": "FFFFFF", "ingredient": "Cotton", "cost": 2},
	"Black": {"hex": "000000", "ingredient": "Coal", "cost": 3},
	"Brown": {"hex": "8B4513", "ingredient": "Wood", "cost": 1},
	"Cyan": {"hex": "00FFFF", "ingredient": "Berries", "cost": 2},
	"Magenta": {"hex": "FF00FF", "ingredient": "Ambrosia", "cost": 5},
	"Gold": {"hex": "FFD700", "ingredient": "Gold", "cost": 6},
	"Silver": {"hex": "C0C0C0", "ingredient": "Silver", "cost": 4}
}

const MIX_RECIPES: Dictionary = {
	"Red+Blue": "Purple",
	"Red+Yellow": "Orange",
	"Blue+Yellow": "Green",
	"Red+White": "Pink",
	"Blue+Green": "Cyan"
}

func get_dye_info(color: String) -> Dictionary:
	return DYES.get(color, {})

func mix_colors(color_a: String, color_b: String) -> String:
	var key1: String = "%s+%s" % [color_a, color_b]
	var key2: String = "%s+%s" % [color_b, color_a]
	if MIX_RECIPES.has(key1):
		return MIX_RECIPES[key1]
	if MIX_RECIPES.has(key2):
		return MIX_RECIPES[key2]
	return ""

func get_cheapest_dye() -> String:
	var best: String = ""
	var min_cost: int = 999
	for c: String in DYES:
		if DYES[c]["cost"] < min_cost:
			min_cost = DYES[c]["cost"]
			best = c
	return best

func get_most_expensive_dye() -> String:
	var best: String = ""
	var max_cost: int = 0
	for c: String in DYES:
		if DYES[c]["cost"] > max_cost:
			max_cost = DYES[c]["cost"]
			best = c
	return best

func get_dyes_by_ingredient(ingredient: String) -> Array[String]:
	var result: Array[String] = []
	for c: String in DYES:
		if DYES[c]["ingredient"] == ingredient:
			result.append(c)
	return result

func get_avg_dye_cost() -> float:
	if DYES.is_empty():
		return 0.0
	var total: float = 0.0
	for d: String in DYES:
		total += float(DYES[d].get("cost", 0))
	return total / DYES.size()


func get_unique_ingredients() -> int:
	var ings: Dictionary = {}
	for d: String in DYES:
		ings[String(DYES[d].get("ingredient", ""))] = true
	return ings.size()


func get_premium_dye_count() -> int:
	var count: int = 0
	for d: String in DYES:
		if int(DYES[d].get("cost", 0)) >= 5:
			count += 1
	return count


func get_mixable_dye_count() -> int:
	var mixed: Dictionary = {}
	for key: String in MIX_RECIPES:
		var parts: PackedStringArray = key.split("+")
		for p: String in parts:
			mixed[p] = true
	return mixed.size()


func get_cost_spread() -> int:
	var lo: int = 999
	var hi: int = 0
	for d: String in DYES:
		var c: int = int(DYES[d].get("cost", 0))
		if c < lo:
			lo = c
		if c > hi:
			hi = c
	if lo > hi:
		return 0
	return hi - lo


func get_budget_dye_count() -> int:
	var count: int = 0
	for d: String in DYES:
		if int(DYES[d].get("cost", 0)) <= 2:
			count += 1
	return count


func get_summary() -> Dictionary:
	return {
		"dye_colors": DYES.size(),
		"mix_recipes": MIX_RECIPES.size(),
		"cheapest": get_cheapest_dye(),
		"most_expensive": get_most_expensive_dye(),
		"avg_cost": snapped(get_avg_dye_cost(), 0.1),
		"unique_ingredients": get_unique_ingredients(),
		"premium_count": get_premium_dye_count(),
		"mixable_dyes": get_mixable_dye_count(),
		"cost_spread": get_cost_spread(),
		"budget_dyes": get_budget_dye_count(),
		"aesthetic_coherence": get_aesthetic_coherence(),
		"material_waste_ratio": get_material_waste_ratio(),
		"trend_direction": get_trend_direction(),
		"color_palette_richness": get_color_palette_richness(),
		"dye_affordability_index": get_dye_affordability_index(),
		"fashion_versatility": get_fashion_versatility(),
	}

func get_color_palette_richness() -> float:
	var mixable := get_mixable_dye_count()
	var total := DYES.size()
	if total <= 0:
		return 0.0
	return snapped(float(mixable) / float(total) * 100.0, 0.1)

func get_dye_affordability_index() -> String:
	var budget := get_budget_dye_count()
	var total := DYES.size()
	if total <= 0:
		return "None"
	var ratio := float(budget) / float(total)
	if ratio >= 0.5:
		return "Affordable"
	elif ratio >= 0.2:
		return "Mixed"
	return "Expensive"

func get_fashion_versatility() -> String:
	var ingredients := get_unique_ingredients()
	var recipes := MIX_RECIPES.size()
	if ingredients >= 5 and recipes >= 3:
		return "Haute Couture"
	elif ingredients >= 3:
		return "Versatile"
	return "Basic"

func get_aesthetic_coherence() -> String:
	var unique := get_unique_ingredients()
	if unique <= 3:
		return "Unified"
	elif unique <= 6:
		return "Varied"
	return "Eclectic"

func get_material_waste_ratio() -> float:
	var premium := get_premium_dye_count()
	var budget := get_budget_dye_count()
	var total := DYES.size()
	if total <= 0:
		return 0.0
	return snapped(float(premium) / float(total) * 100.0, 0.1)

func get_trend_direction() -> String:
	var mixable := get_mixable_dye_count()
	if mixable >= 3:
		return "Innovative"
	elif mixable >= 1:
		return "Emerging"
	return "Traditional"
