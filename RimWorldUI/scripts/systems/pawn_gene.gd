extends Node

var _pawn_genes: Dictionary = {}

const GENES: Dictionary = {
	"ToughSkin": {"metabolic_cost": 1, "effects": {"armor": 0.1}, "category": "body"},
	"StrongBack": {"metabolic_cost": 1, "effects": {"carry_capacity": 0.2}, "category": "body"},
	"KeenEyes": {"metabolic_cost": 1, "effects": {"sight": 0.15}, "category": "senses"},
	"QuickFeet": {"metabolic_cost": 2, "effects": {"move_speed": 0.15}, "category": "body"},
	"IronStomach": {"metabolic_cost": 1, "effects": {"food_poison_resist": 0.5}, "category": "body"},
	"Deathless": {"metabolic_cost": 4, "effects": {"age_reversal": true}, "category": "archite"},
	"FireResist": {"metabolic_cost": 1, "effects": {"fire_resist": 0.5}, "category": "body"},
	"ToxicResist": {"metabolic_cost": 2, "effects": {"toxic_resist": 0.5}, "category": "body"},
	"PsychicBond": {"metabolic_cost": 3, "effects": {"psychic_sensitivity": 0.3}, "category": "psychic"},
	"Aggression": {"metabolic_cost": -1, "effects": {"melee_damage": 0.15, "social_penalty": -0.1}, "category": "negative"},
	"SlowHealer": {"metabolic_cost": -2, "effects": {"heal_rate": -0.3}, "category": "negative"},
	"Inbred": {"metabolic_cost": -3, "effects": {"consciousness": -0.1, "learning": -0.2}, "category": "negative"}
}

const MAX_METABOLIC_EFFICIENCY: int = 5

func add_gene(pawn_id: int, gene: String) -> Dictionary:
	if not GENES.has(gene):
		return {"error": "unknown_gene"}
	if not _pawn_genes.has(pawn_id):
		_pawn_genes[pawn_id] = []
	if gene in _pawn_genes[pawn_id]:
		return {"error": "already_has"}
	_pawn_genes[pawn_id].append(gene)
	return {"added": gene, "total_genes": _pawn_genes[pawn_id].size()}

func get_metabolic_cost(pawn_id: int) -> int:
	var total: int = 0
	for gene: String in _pawn_genes.get(pawn_id, []):
		total += GENES.get(gene, {}).get("metabolic_cost", 0)
	return total

func get_gene_effects(pawn_id: int) -> Dictionary:
	var combined: Dictionary = {}
	for gene: String in _pawn_genes.get(pawn_id, []):
		for eff: String in GENES[gene]["effects"]:
			if combined.has(eff):
				combined[eff] += GENES[gene]["effects"][eff]
			else:
				combined[eff] = GENES[gene]["effects"][eff]
	return combined

func get_genes_by_category(cat: String) -> Array[String]:
	var result: Array[String] = []
	for g: String in GENES:
		if String(GENES[g].get("category", "")) == cat:
			result.append(g)
	return result


func get_negative_genes() -> Array[String]:
	return get_genes_by_category("negative")


func get_most_gene_pawn() -> Dictionary:
	var best_id: int = -1
	var best_count: int = 0
	for pid: int in _pawn_genes:
		var c: int = _pawn_genes[pid].size()
		if c > best_count:
			best_count = c
			best_id = pid
	if best_id < 0:
		return {}
	return {"pawn_id": best_id, "gene_count": best_count}


func get_avg_metabolic_cost() -> float:
	if GENES.is_empty():
		return 0.0
	var total: float = 0.0
	for g: String in GENES:
		total += float(GENES[g].get("metabolic_cost", 0))
	return total / GENES.size()


func get_category_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for g: String in GENES:
		var cat: String = String(GENES[g].get("category", ""))
		dist[cat] = dist.get(cat, 0) + 1
	return dist


func get_archite_gene_count() -> int:
	var count: int = 0
	for g: String in GENES:
		if String(GENES[g].get("category", "")) == "archite":
			count += 1
	return count


func get_positive_gene_count() -> int:
	var count: int = 0
	for g: String in GENES:
		if int(GENES[g].get("metabolic_cost", 0)) > 0:
			count += 1
	return count


func get_unique_categories() -> int:
	var cats: Dictionary = {}
	for g: String in GENES:
		cats[String(GENES[g].get("category", ""))] = true
	return cats.size()


func get_highest_cost_gene() -> String:
	var best: String = ""
	var best_c: int = 0
	for g: String in GENES:
		var c: int = int(GENES[g].get("metabolic_cost", 0))
		if c > best_c:
			best_c = c
			best = g
	return best


func get_genetic_richness() -> String:
	var cats: int = get_unique_categories()
	if cats >= 5:
		return "Diverse"
	if cats >= 3:
		return "Moderate"
	return "Limited"


func get_metabolic_health_pct() -> float:
	var positive: int = get_positive_gene_count()
	var negative: int = get_negative_genes().size()
	var total: int = positive + negative
	if total == 0:
		return 100.0
	return snappedf(float(positive) / float(total) * 100.0, 0.1)


func get_archite_saturation() -> String:
	var archite: int = get_archite_gene_count()
	var total: int = GENES.size()
	if total == 0:
		return "None"
	var ratio: float = float(archite) / float(total)
	if ratio >= 0.3:
		return "Saturated"
	if ratio >= 0.1:
		return "Present"
	return "Rare"


func get_summary() -> Dictionary:
	return {
		"gene_count": GENES.size(),
		"pawns_with_genes": _pawn_genes.size(),
		"negative_genes": get_negative_genes().size(),
		"most_gene_pawn": get_most_gene_pawn(),
		"avg_metabolic": snapped(get_avg_metabolic_cost(), 0.1),
		"archite_genes": get_archite_gene_count(),
		"positive_genes": get_positive_gene_count(),
		"unique_categories": get_unique_categories(),
		"highest_cost_gene": get_highest_cost_gene(),
		"genetic_richness": get_genetic_richness(),
		"metabolic_health_pct": get_metabolic_health_pct(),
		"archite_saturation": get_archite_saturation(),
		"gene_pool_diversity": get_gene_pool_diversity(),
		"mutation_stability": get_mutation_stability(),
		"genetic_optimization_score": get_genetic_optimization_score(),
		"genetic_ecosystem_health": get_genetic_ecosystem_health(),
		"gene_governance": get_gene_governance(),
		"bioengineering_maturity_index": get_bioengineering_maturity_index(),
	}

func get_gene_pool_diversity() -> float:
	var categories := get_unique_categories()
	var total := GENES.size()
	if total <= 0:
		return 0.0
	return snapped(float(categories) / float(total) * 100.0, 0.1)

func get_mutation_stability() -> String:
	var negative := get_negative_genes().size()
	var positive := get_positive_gene_count()
	if positive > negative * 2:
		return "Stable"
	elif positive >= negative:
		return "Balanced"
	return "Unstable"

func get_genetic_optimization_score() -> float:
	var health := get_metabolic_health_pct()
	var richness := get_genetic_richness()
	var bonus := 10.0 if richness in ["Rich", "Abundant"] else 0.0
	return snapped(health + bonus, 0.1)

func get_genetic_ecosystem_health() -> float:
	var diversity := get_gene_pool_diversity()
	var stability := get_mutation_stability()
	var s_val: float = 90.0 if stability == "Stable" else (60.0 if stability == "Balanced" else 25.0)
	var optimization := get_genetic_optimization_score()
	return snapped((diversity + s_val + optimization) / 3.0, 0.1)

func get_gene_governance() -> String:
	var ecosystem := get_genetic_ecosystem_health()
	var health := get_metabolic_health_pct()
	var combined := (ecosystem + health) / 2.0
	if combined >= 70.0:
		return "Optimized"
	elif combined >= 40.0:
		return "Viable"
	elif _pawn_genes.size() > 0:
		return "Unstable"
	return "Baseline"

func get_bioengineering_maturity_index() -> float:
	var archite := get_archite_saturation()
	var a_val: float = 90.0 if archite == "Saturated" else (60.0 if archite == "Moderate" else 25.0)
	var richness := get_genetic_richness()
	var r_val: float = 90.0 if richness in ["Rich", "Abundant"] else (60.0 if richness == "Moderate" else 25.0)
	return snapped((a_val + r_val) / 2.0, 0.1)
