extends Node

var _pawn_xenotypes: Dictionary = {}

const XENOTYPES: Dictionary = {
	"Baseliner": {"genes": [], "metabolic_efficiency": 0, "desc": "Standard human"},
	"Hussar": {"genes": ["QuickFeet", "KeenEyes", "ToughSkin"], "metabolic_efficiency": 3, "desc": "Combat-optimized"},
	"Neanderthal": {"genes": ["StrongBack", "ToughSkin", "SlowHealer"], "metabolic_efficiency": 1, "desc": "Sturdy but slow healing"},
	"Highmate": {"genes": ["PsychicBond", "KeenEyes"], "metabolic_efficiency": 2, "desc": "Psychic companion"},
	"Impid": {"genes": ["FireResist", "Aggression"], "metabolic_efficiency": 0, "desc": "Fire-resistant aggressive"},
	"Dirtmole": {"genes": ["IronStomach", "ToxicResist"], "metabolic_efficiency": 1, "desc": "Underground adapted"},
	"Waster": {"genes": ["ToxicResist", "ToughSkin", "Inbred"], "metabolic_efficiency": -1, "desc": "Pollution adapted"},
	"Sanguophage": {"genes": ["Deathless", "ToughSkin", "QuickFeet"], "metabolic_efficiency": 5, "desc": "Immortal blood-drinker"},
	"Pigskin": {"genes": ["IronStomach", "StrongBack"], "metabolic_efficiency": 1, "desc": "Tough laborer"},
	"Yttakin": {"genes": ["FireResist", "StrongBack", "Aggression"], "metabolic_efficiency": 1, "desc": "Fire-born warrior"}
}

func assign_xenotype(pawn_id: int, xeno: String) -> Dictionary:
	if not XENOTYPES.has(xeno):
		return {"error": "unknown_xenotype"}
	_pawn_xenotypes[pawn_id] = xeno
	return {"assigned": xeno, "genes": XENOTYPES[xeno]["genes"], "metabolic": XENOTYPES[xeno]["metabolic_efficiency"]}

func get_xenotype(pawn_id: int) -> String:
	return _pawn_xenotypes.get(pawn_id, "Baseliner")

func get_xenotype_genes(pawn_id: int) -> Array:
	var xeno: String = get_xenotype(pawn_id)
	return XENOTYPES.get(xeno, {}).get("genes", [])

func get_xenotype_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pid: int in _pawn_xenotypes:
		var x: String = _pawn_xenotypes[pid]
		dist[x] = int(dist.get(x, 0)) + 1
	return dist


func get_highest_metabolism_xenotype() -> String:
	var best: String = ""
	var best_m: int = -999
	for x: String in XENOTYPES:
		var m: int = int(XENOTYPES[x].get("metabolic_efficiency", 0))
		if m > best_m:
			best_m = m
			best = x
	return best


func get_most_gene_rich_xenotype() -> String:
	var best: String = ""
	var best_count: int = 0
	for x: String in XENOTYPES:
		var c: int = XENOTYPES[x].get("genes", []).size()
		if c > best_count:
			best_count = c
			best = x
	return best


func get_lowest_metabolism_xenotype() -> String:
	var worst: String = ""
	var worst_m: int = 999
	for x: String in XENOTYPES:
		var m: int = int(XENOTYPES[x].get("metabolic_efficiency", 999))
		if m < worst_m:
			worst_m = m
			worst = x
	return worst


func get_avg_genes_per_xenotype() -> float:
	if XENOTYPES.is_empty():
		return 0.0
	var total: int = 0
	for x: String in XENOTYPES:
		total += XENOTYPES[x].get("genes", []).size()
	return float(total) / XENOTYPES.size()


func get_xenotype_assignment_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pid: int in _pawn_xenotypes:
		var x: String = String(_pawn_xenotypes[pid])
		dist[x] = dist.get(x, 0) + 1
	return dist


func get_zero_gene_xenotype_count() -> int:
	var count: int = 0
	for x: String in XENOTYPES:
		if XENOTYPES[x].get("genes", []).is_empty():
			count += 1
	return count


func get_avg_metabolic_efficiency() -> float:
	if XENOTYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for x: String in XENOTYPES:
		total += float(XENOTYPES[x].get("metabolic_efficiency", 0))
	return snappedf(total / float(XENOTYPES.size()), 0.1)


func get_negative_metabolism_count() -> int:
	var count: int = 0
	for x: String in XENOTYPES:
		if int(XENOTYPES[x].get("metabolic_efficiency", 0)) < 0:
			count += 1
	return count


func get_diversity_index() -> String:
	var assigned_types: Dictionary = {}
	for pid: int in _pawn_xenotypes:
		assigned_types[_pawn_xenotypes[pid]] = true
	var ratio: float = float(assigned_types.size()) / maxf(float(XENOTYPES.size()), 1.0)
	if ratio >= 0.6:
		return "Cosmopolitan"
	if ratio >= 0.3:
		return "Mixed"
	return "Homogeneous"


func get_metabolic_viability_pct() -> float:
	var viable: int = XENOTYPES.size() - get_negative_metabolism_count()
	return snappedf(float(viable) / maxf(float(XENOTYPES.size()), 1.0) * 100.0, 0.1)


func get_genetic_complexity() -> String:
	var avg: float = get_avg_genes_per_xenotype()
	if avg >= 5.0:
		return "HighlyEngineered"
	if avg >= 3.0:
		return "Modified"
	return "Baseline"


func get_summary() -> Dictionary:
	return {
		"xenotype_count": XENOTYPES.size(),
		"assigned_pawns": _pawn_xenotypes.size(),
		"highest_metabolism": get_highest_metabolism_xenotype(),
		"most_genes": get_most_gene_rich_xenotype(),
		"lowest_metabolism": get_lowest_metabolism_xenotype(),
		"avg_genes": snapped(get_avg_genes_per_xenotype(), 0.1),
		"zero_gene_types": get_zero_gene_xenotype_count(),
		"avg_metabolism": get_avg_metabolic_efficiency(),
		"negative_metabolism": get_negative_metabolism_count(),
		"diversity_index": get_diversity_index(),
		"metabolic_viability_pct": get_metabolic_viability_pct(),
		"genetic_complexity": get_genetic_complexity(),
		"xenotype_dominance": get_xenotype_dominance(),
		"population_gene_density": get_population_gene_density(),
		"evolutionary_potential": get_evolutionary_potential(),
		"xenogenetic_ecosystem_health": get_xenogenetic_ecosystem_health(),
		"species_governance": get_species_governance(),
		"biodiversity_maturity_index": get_biodiversity_maturity_index(),
	}

func get_xenotype_dominance() -> String:
	var assigned := _pawn_xenotypes.size()
	if assigned >= 5:
		return "Dominant"
	elif assigned >= 2:
		return "Present"
	elif assigned > 0:
		return "Rare"
	return "None"

func get_population_gene_density() -> float:
	var avg_genes := get_avg_genes_per_xenotype()
	var types := XENOTYPES.size()
	if types <= 0:
		return 0.0
	return snapped(avg_genes * float(types), 0.1)

func get_evolutionary_potential() -> String:
	var complexity := get_genetic_complexity()
	var diversity := get_diversity_index()
	if complexity in ["Complex", "Advanced"] and diversity == "Cosmopolitan":
		return "High"
	elif complexity in ["Moderate", "Complex"]:
		return "Moderate"
	return "Low"

func get_xenogenetic_ecosystem_health() -> float:
	var dominance := get_xenotype_dominance()
	var d_val: float = 90.0 if dominance == "Dominant" else (60.0 if dominance == "Established" else 25.0)
	var density := get_population_gene_density()
	var viability := get_metabolic_viability_pct()
	return snapped((d_val + minf(density, 100.0) + viability) / 3.0, 0.1)

func get_species_governance() -> String:
	var ecosystem := get_xenogenetic_ecosystem_health()
	var potential := get_evolutionary_potential()
	var p_val: float = 90.0 if potential == "High" else (60.0 if potential == "Moderate" else 25.0)
	var combined := (ecosystem + p_val) / 2.0
	if combined >= 70.0:
		return "Ascendant"
	elif combined >= 40.0:
		return "Diversifying"
	elif _pawn_xenotypes.size() > 0:
		return "Baseline"
	return "Homogeneous"

func get_biodiversity_maturity_index() -> float:
	var complexity := get_genetic_complexity()
	var c_val: float = 90.0 if complexity in ["HighlyEngineered", "Complex"] else (60.0 if complexity == "Moderate" else 25.0)
	var diversity := get_diversity_index()
	var di_val: float = 90.0 if diversity == "Cosmopolitan" else (60.0 if diversity == "Diverse" else 25.0)
	return snapped((c_val + di_val) / 2.0, 0.1)
