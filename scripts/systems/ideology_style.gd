extends Node

const STYLES: Dictionary = {
	"Rustic": {"beauty_mult": 0.8, "work_mult": 0.9, "materials": ["Wood", "Stone"], "colors": ["Brown", "Green"]},
	"Morbid": {"beauty_mult": 0.5, "work_mult": 1.0, "materials": ["Stone", "Steel"], "colors": ["Black", "Red"]},
	"Spacer": {"beauty_mult": 1.3, "work_mult": 1.2, "materials": ["Plasteel", "Steel"], "colors": ["White", "Blue"]},
	"Tribal": {"beauty_mult": 0.7, "work_mult": 0.8, "materials": ["Wood", "Cloth"], "colors": ["Brown", "Yellow"]},
	"Animist": {"beauty_mult": 1.0, "work_mult": 0.9, "materials": ["Wood", "Jade"], "colors": ["Green", "Brown"]},
	"Tunneler": {"beauty_mult": 0.6, "work_mult": 0.85, "materials": ["Stone", "Steel"], "colors": ["Grey", "Brown"]},
	"Supremacist": {"beauty_mult": 1.2, "work_mult": 1.1, "materials": ["Gold", "Silver"], "colors": ["Gold", "White"]},
	"Transhumanist": {"beauty_mult": 1.4, "work_mult": 1.3, "materials": ["Plasteel", "Uranium"], "colors": ["Cyan", "Silver"]}
}

const BUILDING_CATEGORIES: Dictionary = {
	"Furniture": {"style_importance": 0.8, "beauty_weight": 1.0},
	"Structure": {"style_importance": 0.6, "beauty_weight": 0.5},
	"Production": {"style_importance": 0.3, "beauty_weight": 0.2},
	"Security": {"style_importance": 0.2, "beauty_weight": 0.1},
	"Recreation": {"style_importance": 0.9, "beauty_weight": 1.2},
	"Ritual": {"style_importance": 1.0, "beauty_weight": 1.5}
}

func get_style_bonus(style: String, category: String) -> Dictionary:
	if not STYLES.has(style) or not BUILDING_CATEGORIES.has(category):
		return {}
	var s: Dictionary = STYLES[style]
	var c: Dictionary = BUILDING_CATEGORIES[category]
	return {"beauty_bonus": s["beauty_mult"] * c["beauty_weight"], "work_cost": s["work_mult"] * c["style_importance"]}

func get_most_beautiful_style() -> String:
	var best: String = ""
	var best_v: float = 0.0
	for s: String in STYLES:
		if STYLES[s]["beauty_mult"] > best_v:
			best_v = STYLES[s]["beauty_mult"]
			best = s
	return best

func get_cheapest_style() -> String:
	var best: String = ""
	var best_v: float = 999.0
	for s: String in STYLES:
		if STYLES[s]["work_mult"] < best_v:
			best_v = STYLES[s]["work_mult"]
			best = s
	return best

func get_style_materials(style: String) -> Array:
	if not STYLES.has(style):
		return []
	return STYLES[style]["materials"]

func get_avg_beauty() -> float:
	if STYLES.is_empty():
		return 0.0
	var total: float = 0.0
	for s: String in STYLES:
		total += float(STYLES[s].get("beauty", 0))
	return total / STYLES.size()

func get_avg_work_mult() -> float:
	if STYLES.is_empty():
		return 1.0
	var total: float = 0.0
	for s: String in STYLES:
		total += float(STYLES[s].get("work_mult", 1.0))
	return total / STYLES.size()

func get_premium_style_count() -> int:
	var count: int = 0
	for s: String in STYLES:
		if float(STYLES[s].get("work_mult", 1.0)) >= 2.0:
			count += 1
	return count

func get_unique_materials_used() -> int:
	var mats: Dictionary = {}
	for s: String in STYLES:
		for m: String in STYLES[s].get("materials", []):
			mats[m] = true
	return mats.size()


func get_ugliest_style() -> String:
	var worst: String = ""
	var worst_v: float = 999.0
	for s: String in STYLES:
		var v: float = float(STYLES[s].get("beauty_mult", 999.0))
		if v < worst_v:
			worst_v = v
			worst = s
	return worst


func get_high_work_style_count() -> int:
	var count: int = 0
	for s: String in STYLES:
		if float(STYLES[s].get("work_mult", 1.0)) >= 1.2:
			count += 1
	return count


func get_cultural_richness() -> String:
	var materials: Dictionary = {}
	for s: String in STYLES:
		for m: String in STYLES[s]["materials"]:
			materials[m] = true
	var ratio: float = materials.size() * 1.0 / maxf(STYLES.size(), 1.0)
	if ratio >= 2.0:
		return "diverse"
	if ratio >= 1.5:
		return "moderate"
	return "homogeneous"

func get_efficiency_balance_pct() -> float:
	var efficient: int = 0
	for s: String in STYLES:
		if STYLES[s]["work_mult"] <= 1.0 and STYLES[s]["beauty_mult"] >= 0.8:
			efficient += 1
	if STYLES.is_empty():
		return 0.0
	return snapped(efficient * 100.0 / STYLES.size(), 0.1)

func get_aesthetic_range() -> String:
	var min_b: float = INF
	var max_b: float = -INF
	for s: String in STYLES:
		if STYLES[s]["beauty_mult"] < min_b:
			min_b = STYLES[s]["beauty_mult"]
		if STYLES[s]["beauty_mult"] > max_b:
			max_b = STYLES[s]["beauty_mult"]
	var spread: float = max_b - min_b
	if spread >= 0.8:
		return "wide"
	if spread >= 0.4:
		return "moderate"
	return "narrow"

func get_summary() -> Dictionary:
	return {
		"styles": STYLES.size(),
		"building_categories": BUILDING_CATEGORIES.size(),
		"most_beautiful": get_most_beautiful_style(),
		"cheapest_work": get_cheapest_style(),
		"avg_beauty": snapped(get_avg_beauty(), 0.1),
		"avg_work_mult": snapped(get_avg_work_mult(), 0.01),
		"premium_styles": get_premium_style_count(),
		"unique_materials": get_unique_materials_used(),
		"ugliest_style": get_ugliest_style(),
		"high_work_styles": get_high_work_style_count(),
		"cultural_richness": get_cultural_richness(),
		"efficiency_balance_pct": get_efficiency_balance_pct(),
		"aesthetic_range": get_aesthetic_range(),
		"design_philosophy": get_design_philosophy(),
		"craftsmanship_tier": get_craftsmanship_tier(),
		"style_coherence_index": get_style_coherence_index(),
		"aesthetic_doctrine_index": get_aesthetic_doctrine_index(),
		"stylistic_maturity": get_stylistic_maturity(),
		"cultural_infrastructure_score": get_cultural_infrastructure_score(),
	}

func get_aesthetic_doctrine_index() -> float:
	var richness := get_cultural_richness()
	var balance := get_efficiency_balance_pct()
	return snapped((float(richness) * 10.0 + balance) / 2.0, 0.1)

func get_stylistic_maturity() -> String:
	var philosophy := get_design_philosophy()
	var tier := get_craftsmanship_tier()
	if philosophy == "Perfectionist" and tier in ["Master", "Artisan"]:
		return "Refined"
	elif philosophy == "Utilitarian":
		return "Functional"
	return "Emerging"

func get_cultural_infrastructure_score() -> float:
	var coherence := get_style_coherence_index()
	var premium := float(get_premium_style_count())
	var total := float(STYLES.size())
	if total <= 0.0:
		return 0.0
	return snapped(coherence * (premium / total + 0.5), 0.1)

func get_design_philosophy() -> String:
	var avg_beauty := get_avg_beauty()
	var avg_work := get_avg_work_mult()
	if avg_beauty >= 5.0 and avg_work >= 1.5:
		return "Perfectionist"
	elif avg_beauty >= 3.0:
		return "Aesthetic"
	return "Utilitarian"

func get_craftsmanship_tier() -> String:
	var premium := get_premium_style_count()
	var total := STYLES.size()
	if total <= 0:
		return "None"
	var ratio := float(premium) / float(total)
	if ratio >= 0.5:
		return "Master"
	elif ratio >= 0.2:
		return "Journeyman"
	return "Apprentice"

func get_style_coherence_index() -> float:
	var range_val := get_aesthetic_range()
	var materials := get_unique_materials_used()
	if materials <= 0:
		return 0.0
	var range_penalty: float = 1.0 if range_val == "Wide" else (0.5 if range_val == "Moderate" else 0.2)
	return snapped(100.0 * range_penalty * float(materials) / maxf(float(materials), 1.0), 0.1)
