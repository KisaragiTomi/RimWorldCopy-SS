extends Node

const SKIN_COLORS: Array = [
	"#FFE0BD", "#F5C6A5", "#D4A76A", "#C68642", "#8D5524",
	"#6B3A2A", "#4A2511", "#FFDFC4", "#F0C8A0", "#A57150",
]

const HAIR_STYLES: Array = [
	"Bald", "Shaved", "Short", "Medium", "Long", "Ponytail",
	"Braided", "Mohawk", "Afro", "Bob", "Pigtails", "Topknot",
]

const HAIR_COLORS: Array = [
	"#1A1A1A", "#3B2F2F", "#654321", "#8B4513", "#A0522D",
	"#D2691E", "#DAA520", "#F0E68C", "#FFD700", "#B22222",
	"#C0C0C0", "#FFFFFF",
]

var _pawn_appearances: Dictionary = {}


func generate_appearance(pawn_id: int) -> Dictionary:
	var appearance: Dictionary = {
		"skin": SKIN_COLORS[randi() % SKIN_COLORS.size()],
		"hair_style": HAIR_STYLES[randi() % HAIR_STYLES.size()],
		"hair_color": HAIR_COLORS[randi() % HAIR_COLORS.size()],
	}
	_pawn_appearances[pawn_id] = appearance
	return appearance


func get_appearance(pawn_id: int) -> Dictionary:
	if not _pawn_appearances.has(pawn_id):
		return generate_appearance(pawn_id)
	return _pawn_appearances[pawn_id]


func set_hair_style(pawn_id: int, style: String) -> void:
	if not _pawn_appearances.has(pawn_id):
		generate_appearance(pawn_id)
	_pawn_appearances[pawn_id].hair_style = style


func get_hair_style_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pid: int in _pawn_appearances:
		var style: String = String(_pawn_appearances[pid].get("hair_style", ""))
		dist[style] = dist.get(style, 0) + 1
	return dist


func set_skin_color(pawn_id: int, color: String) -> void:
	if not _pawn_appearances.has(pawn_id):
		generate_appearance(pawn_id)
	_pawn_appearances[pawn_id].skin = color


func get_total_combinations() -> int:
	return SKIN_COLORS.size() * HAIR_STYLES.size() * HAIR_COLORS.size()


func get_most_common_hair() -> String:
	var counts: Dictionary = {}
	for pid: int in _pawn_appearances:
		var hair: String = str(_pawn_appearances[pid].get("hair_style", ""))
		counts[hair] = counts.get(hair, 0) + 1
	var best: String = ""
	var best_n: int = 0
	for h: String in counts:
		if counts[h] > best_n:
			best_n = counts[h]
			best = h
	return best


func get_unique_hair_count() -> int:
	var hairs: Dictionary = {}
	for pid: int in _pawn_appearances:
		hairs[str(_pawn_appearances[pid].get("hair_style", ""))] = true
	return hairs.size()


func get_customized_pawn_count() -> int:
	return _pawn_appearances.size()


func get_hair_diversity_pct() -> float:
	if HAIR_STYLES.is_empty():
		return 0.0
	return snappedf(float(get_unique_hair_count()) / float(HAIR_STYLES.size()) * 100.0, 0.1)


func get_unique_skin_count() -> int:
	var skins: Dictionary = {}
	for pid: int in _pawn_appearances:
		skins[str(_pawn_appearances[pid].get("skin", ""))] = true
	return skins.size()


func get_avg_customizations_per_pawn() -> float:
	if _pawn_appearances.is_empty():
		return 0.0
	return 3.0


func get_customization_level() -> String:
	var diversity: float = get_hair_diversity_pct()
	if diversity >= 80.0:
		return "Highly Unique"
	elif diversity >= 50.0:
		return "Diverse"
	elif diversity >= 20.0:
		return "Moderate"
	return "Uniform"

func get_visual_variety_pct() -> float:
	var total_combos: int = get_total_combinations()
	if total_combos == 0:
		return 0.0
	var used: int = _pawn_appearances.size()
	return snappedf(minf(float(used) / float(total_combos), 1.0) * 100.0, 0.1)

func get_ethnic_diversity() -> float:
	if SKIN_COLORS.is_empty():
		return 0.0
	return snappedf(float(get_unique_skin_count()) / float(SKIN_COLORS.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"skin_colors": SKIN_COLORS.size(),
		"hair_styles": HAIR_STYLES.size(),
		"hair_colors": HAIR_COLORS.size(),
		"generated_pawns": _pawn_appearances.size(),
		"total_combinations": get_total_combinations(),
		"most_common_hair": get_most_common_hair(),
		"unique_hairs": get_unique_hair_count(),
		"hair_diversity_pct": get_hair_diversity_pct(),
		"unique_skins": get_unique_skin_count(),
		"customization_level": get_customization_level(),
		"visual_variety_pct": get_visual_variety_pct(),
		"ethnic_diversity_pct": get_ethnic_diversity(),
		"identity_expression": get_identity_expression(),
		"aesthetic_richness": get_aesthetic_richness(),
		"population_distinctiveness": get_population_distinctiveness(),
		"visual_ecosystem_health": get_visual_ecosystem_health(),
		"cultural_expression_index": get_cultural_expression_index(),
		"appearance_governance": get_appearance_governance(),
	}

func get_identity_expression() -> String:
	var customization := get_customization_level()
	var variety := get_visual_variety_pct()
	if customization in ["Highly Unique"] and variety >= 50.0:
		return "Expressive"
	elif customization in ["Diverse", "Highly Unique"]:
		return "Distinctive"
	return "Generic"

func get_aesthetic_richness() -> float:
	var hair_div := get_hair_diversity_pct()
	var ethnic_div := get_ethnic_diversity()
	return snapped((hair_div + ethnic_div) / 2.0, 0.1)

func get_population_distinctiveness() -> String:
	var unique_hairs := get_unique_hair_count()
	var total := _pawn_appearances.size()
	if total <= 0:
		return "N/A"
	if unique_hairs >= total:
		return "All Unique"
	elif float(unique_hairs) / float(total) >= 0.7:
		return "Mostly Unique"
	return "Many Duplicates"

func get_visual_ecosystem_health() -> float:
	var richness := get_aesthetic_richness()
	var diversity := get_visual_variety_pct()
	var expression := get_identity_expression()
	var e_val: float = 90.0 if expression == "Expressive" else (60.0 if expression == "Distinctive" else 30.0)
	return snapped((richness + diversity + e_val) / 3.0, 0.1)

func get_cultural_expression_index() -> float:
	var hair_div := get_hair_diversity_pct()
	var ethnic := get_ethnic_diversity()
	var unique_skins := get_unique_skin_count()
	return snapped((hair_div + ethnic + minf(float(unique_skins) * 20.0, 100.0)) / 3.0, 0.1)

func get_appearance_governance() -> String:
	var health := get_visual_ecosystem_health()
	var expression := get_cultural_expression_index()
	if health >= 60.0 and expression >= 50.0:
		return "Curated"
	elif health >= 30.0 or expression >= 25.0:
		return "Organic"
	return "Neglected"
