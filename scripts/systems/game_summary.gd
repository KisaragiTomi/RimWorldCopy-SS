extends Node

func get_project_stats() -> Dictionary:
	var autoload_count: int = 0
	for child: Node in get_tree().root.get_children():
		autoload_count += 1
	return {
		"autoload_count": autoload_count,
		"project": "RimWorld Copy in Godot 4",
		"dlcs_covered": ["Core", "Royalty", "Ideology", "Biotech", "Anomaly"],
		"major_systems": {
			"core": "DefDB, TickManager, GameState, UIManager, ThingManager",
			"pawn": "PawnManager, Skills, Needs, Health, Thoughts, Traits, Genes, Backstories",
			"world": "WorldManager, Biomes, Climate, MapGen, Features, Terrain",
			"combat": "RaidManager, ThreatAssessment, ArmorPenetration, Cover, FireSpread",
			"social": "Relationships, Ideology, Rituals, Precepts, Empire, Diplomacy",
			"economy": "TradeManager, TradeGoods, Crafting, DeepDrill, Resources",
			"ai": "WorkScheduler, Jobs, MentalBreaks, DrugAddiction, Recreation",
			"dlc_royalty": "EmpireTitle, ShuttlePermit, PersonaWeapon, NeuralHeat",
			"dlc_ideology": "Precepts, Rituals, Styles, Slaves, GauranlenTree, Roles",
			"dlc_biotech": "Genes, Xenotypes, MechGestator, BandNode, Children, Hemogen",
			"dlc_anomaly": "AnomalyEntity, Containment, DarkStudy, Bioferrite",
			"endgame": "ShipReactor, EndgameManager, 6 Victory Conditions"
		}
	}

func get_system_count() -> int:
	var stats: Dictionary = get_project_stats()
	return stats["major_systems"].size()

func get_dlc_list() -> Array:
	var stats: Dictionary = get_project_stats()
	return stats["dlcs_covered"]

func get_systems_for_category(category: String) -> String:
	var stats: Dictionary = get_project_stats()
	return stats["major_systems"].get(category, "")

func get_total_system_entries() -> int:
	var stats: Dictionary = get_project_stats()
	var total: int = 0
	for k: String in stats["major_systems"]:
		var val: String = stats["major_systems"][k]
		total += val.split(",").size()
	return total

func get_largest_system_category() -> String:
	var stats: Dictionary = get_project_stats()
	var best: String = ""
	var best_n: int = 0
	for k: String in stats["major_systems"]:
		var n: int = (stats["major_systems"][k] as String).split(",").size()
		if n > best_n:
			best_n = n
			best = k
	return best

func get_dlc_system_count() -> int:
	var stats: Dictionary = get_project_stats()
	var count: int = 0
	for k: String in stats["major_systems"]:
		if (k as String).begins_with("dlc_"):
			count += 1
	return count


func get_smallest_system_category() -> String:
	var stats: Dictionary = get_project_stats()
	var best: String = ""
	var best_n: int = 9999
	for k: String in stats["major_systems"]:
		var n: int = (stats["major_systems"][k] as String).split(",").size()
		if n < best_n:
			best_n = n
			best = k
	return best


func get_avg_entries_per_category() -> float:
	var stats: Dictionary = get_project_stats()
	if stats["major_systems"].is_empty():
		return 0.0
	var total: int = get_total_system_entries()
	return float(total) / stats["major_systems"].size()


func get_completion_depth() -> String:
	var total: int = get_total_system_entries()
	var cats: int = get_project_stats()["major_systems"].size()
	if cats == 0:
		return "empty"
	var avg: float = total * 1.0 / cats
	if avg >= 6.0:
		return "comprehensive"
	if avg >= 3.0:
		return "moderate"
	return "shallow"

func get_category_balance_pct() -> float:
	var stats: Dictionary = get_project_stats()
	var systems: Dictionary = stats["major_systems"]
	if systems.is_empty():
		return 0.0
	var counts: Array[int] = []
	for cat: String in systems:
		counts.append(systems[cat].split(",").size())
	var min_c: int = counts[0]
	var max_c: int = counts[0]
	for c: int in counts:
		if c < min_c:
			min_c = c
		if c > max_c:
			max_c = c
	if max_c == 0:
		return 100.0
	return snapped(min_c * 100.0 / max_c, 0.1)

func get_expansion_readiness() -> String:
	var dlc_count: int = get_dlc_system_count()
	var total: int = get_total_system_entries()
	if total == 0:
		return "no_systems"
	var dlc_ratio: float = dlc_count * 1.0 / total
	if dlc_ratio >= 0.4:
		return "dlc_heavy"
	if dlc_ratio >= 0.2:
		return "balanced"
	return "core_focused"

func get_summary() -> Dictionary:
	var stats: Dictionary = get_project_stats()
	stats["system_count"] = stats["major_systems"].size()
	stats["dlc_count"] = stats["dlcs_covered"].size()
	stats["total_system_entries"] = get_total_system_entries()
	stats["largest_category"] = get_largest_system_category()
	stats["dlc_systems"] = get_dlc_system_count()
	stats["smallest_category"] = get_smallest_system_category()
	stats["avg_entries_per_cat"] = snapped(get_avg_entries_per_category(), 0.1)
	stats["completion_depth"] = get_completion_depth()
	stats["category_balance_pct"] = get_category_balance_pct()
	stats["expansion_readiness"] = get_expansion_readiness()
	stats["project_ecosystem_health"] = get_project_ecosystem_health()
	stats["documentation_governance"] = get_documentation_governance()
	stats["project_maturity_index"] = get_project_maturity_index()
	return stats

func get_project_ecosystem_health() -> float:
	var depth := get_completion_depth()
	var d_val: float = 90.0 if depth in ["comprehensive", "complete"] else (60.0 if depth in ["moderate", "developing"] else 30.0)
	var balance := get_category_balance_pct()
	var readiness := get_expansion_readiness()
	var r_val: float = 90.0 if readiness == "dlc_heavy" else (60.0 if readiness == "balanced" else 30.0)
	return snapped((d_val + balance + r_val) / 3.0, 0.1)

func get_project_maturity_index() -> float:
	var entries := get_total_system_entries()
	var e_val: float = minf(float(entries) * 2.0, 100.0)
	var avg := get_avg_entries_per_category()
	var a_val: float = minf(avg * 10.0, 100.0)
	var dlc := get_dlc_system_count()
	var dlc_val: float = minf(float(dlc) * 10.0, 100.0)
	return snapped((e_val + a_val + dlc_val) / 3.0, 0.1)

func get_documentation_governance() -> String:
	var ecosystem := get_project_ecosystem_health()
	var maturity := get_project_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif get_total_system_entries() > 0:
		return "Nascent"
	return "Dormant"
