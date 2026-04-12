extends Node

var _links: Dictionary = {}

const LINKABLE_BUILDINGS: Dictionary = {
	"ToolCabinet": {"bonus_type": "work_speed", "bonus": 0.06, "max_links": 2, "range": 3},
	"Bookshelf": {"bonus_type": "research_speed", "bonus": 0.10, "max_links": 2, "range": 3},
	"DrugLab": {"bonus_type": "drug_speed", "bonus": 0.08, "max_links": 1, "range": 2},
	"Anvil": {"bonus_type": "smithing_speed", "bonus": 0.05, "max_links": 1, "range": 2},
	"MultiAnalyzer": {"bonus_type": "research_speed", "bonus": 0.15, "max_links": 1, "range": 4},
	"VitalsMonitor": {"bonus_type": "surgery_success", "bonus": 0.07, "max_links": 1, "range": 2},
	"EndTable": {"bonus_type": "rest_effectiveness", "bonus": 0.04, "max_links": 1, "range": 1},
	"Dresser": {"bonus_type": "rest_effectiveness", "bonus": 0.04, "max_links": 1, "range": 1}
}

const WORKBENCHES: Array = [
	"TailoringBench", "SmithingBench", "MachineBench", "Stove",
	"ButcherTable", "DrugLab", "ResearchBench", "SculptingBench",
	"StonecutterTable", "BrewingBarrel"
]

func create_link(workbench_id: int, linkable_type: String, linkable_id: int) -> bool:
	if not LINKABLE_BUILDINGS.has(linkable_type):
		return false
	if not _links.has(workbench_id):
		_links[workbench_id] = []
	var max_l: int = LINKABLE_BUILDINGS[linkable_type]["max_links"]
	var count: int = 0
	for link: Dictionary in _links[workbench_id]:
		if link["type"] == linkable_type:
			count += 1
	if count >= max_l:
		return false
	_links[workbench_id].append({"type": linkable_type, "id": linkable_id})
	return true

func get_total_bonus(workbench_id: int, bonus_type: String) -> float:
	var total: float = 0.0
	for link: Dictionary in _links.get(workbench_id, []):
		var info: Dictionary = LINKABLE_BUILDINGS.get(link["type"], {})
		if info.get("bonus_type", "") == bonus_type:
			total += info.get("bonus", 0.0)
	return total

func get_links(workbench_id: int) -> Array:
	return _links.get(workbench_id, [])

func get_unlinked_workbenches(all_bench_ids: Array) -> Array:
	var result: Array = []
	for bid in all_bench_ids:
		if not _links.has(int(bid)) or _links[int(bid)].is_empty():
			result.append(bid)
	return result


func get_total_link_count() -> int:
	var total: int = 0
	for wid: int in _links:
		total += _links[wid].size()
	return total


func get_best_bonus_building() -> String:
	var best: String = ""
	var best_bonus: float = 0.0
	for btype: String in LINKABLE_BUILDINGS:
		if float(LINKABLE_BUILDINGS[btype].get("bonus", 0.0)) > best_bonus:
			best_bonus = float(LINKABLE_BUILDINGS[btype].get("bonus", 0.0))
			best = btype
	return best


func get_avg_links_per_bench() -> float:
	if _links.is_empty():
		return 0.0
	return float(get_total_link_count()) / _links.size()


func get_most_linked_type() -> String:
	var counts: Dictionary = {}
	for wid: int in _links:
		for link: Dictionary in _links[wid]:
			var t: String = String(link.get("type", ""))
			counts[t] = counts.get(t, 0) + 1
	var best: String = ""
	var best_count: int = 0
	for t: String in counts:
		if int(counts[t]) > best_count:
			best_count = int(counts[t])
			best = t
	return best


func get_linked_bench_count() -> int:
	var count: int = 0
	for wid: int in _links:
		if not _links[wid].is_empty():
			count += 1
	return count


func get_unique_bonus_types() -> int:
	var types: Dictionary = {}
	for btype: String in LINKABLE_BUILDINGS:
		var bt: String = String(LINKABLE_BUILDINGS[btype].get("bonus_type", ""))
		if not bt.is_empty():
			types[bt] = true
	return types.size()


func get_avg_bonus() -> float:
	if LINKABLE_BUILDINGS.is_empty():
		return 0.0
	var total: float = 0.0
	for btype: String in LINKABLE_BUILDINGS:
		total += float(LINKABLE_BUILDINGS[btype].get("bonus", 0.0))
	return snappedf(total / float(LINKABLE_BUILDINGS.size()), 0.01)


func get_max_range_building() -> String:
	var best: String = ""
	var best_r: int = 0
	for btype: String in LINKABLE_BUILDINGS:
		var r: int = int(LINKABLE_BUILDINGS[btype].get("range", 0))
		if r > best_r:
			best_r = r
			best = btype
	return best


func get_network_density() -> String:
	if WORKBENCHES.is_empty():
		return "N/A"
	var ratio: float = float(get_linked_bench_count()) / float(WORKBENCHES.size())
	if ratio >= 0.8:
		return "Dense"
	elif ratio >= 0.5:
		return "Moderate"
	elif ratio >= 0.2:
		return "Sparse"
	return "Minimal"

func get_optimization_potential_pct() -> float:
	if WORKBENCHES.is_empty() or LINKABLE_BUILDINGS.is_empty():
		return 0.0
	var max_possible: int = WORKBENCHES.size() * LINKABLE_BUILDINGS.size()
	if max_possible == 0:
		return 100.0
	return snappedf((1.0 - float(get_total_link_count()) / float(max_possible)) * 100.0, 0.1)

func get_bonus_coverage() -> String:
	var unique: int = get_unique_bonus_types()
	if unique >= 5:
		return "Comprehensive"
	elif unique >= 3:
		return "Good"
	elif unique >= 1:
		return "Partial"
	return "None"

func get_summary() -> Dictionary:
	return {
		"linkable_types": LINKABLE_BUILDINGS.size(),
		"workbench_types": WORKBENCHES.size(),
		"active_links": _links.size(),
		"total_connections": get_total_link_count(),
		"avg_links": snapped(get_avg_links_per_bench(), 0.1),
		"most_linked_type": get_most_linked_type(),
		"linked_benches": get_linked_bench_count(),
		"unique_bonus_types": get_unique_bonus_types(),
		"avg_bonus": get_avg_bonus(),
		"max_range_building": get_max_range_building(),
		"network_density": get_network_density(),
		"optimization_potential_pct": get_optimization_potential_pct(),
		"bonus_coverage": get_bonus_coverage(),
		"production_synergy": get_production_synergy(),
		"infrastructure_integration": get_infrastructure_integration(),
		"workshop_maturity": get_workshop_maturity(),
		"linkage_ecosystem_health": get_linkage_ecosystem_health(),
		"production_governance": get_production_governance(),
		"integration_maturity_index": get_integration_maturity_index(),
	}

func get_production_synergy() -> String:
	var density: String = get_network_density()
	var coverage: String = get_bonus_coverage()
	if density == "Dense" and coverage in ["Comprehensive", "Good"]:
		return "Synergistic"
	elif density in ["Dense", "Moderate"]:
		return "Developing"
	return "Isolated"

func get_infrastructure_integration() -> float:
	var linked := get_linked_bench_count()
	var total := WORKBENCHES.size()
	if total <= 0:
		return 0.0
	return snapped(float(linked) / float(total) * 100.0, 0.1)

func get_workshop_maturity() -> String:
	var unique_bonus := get_unique_bonus_types()
	var avg := get_avg_links_per_bench()
	if unique_bonus >= 4 and avg >= 2.0:
		return "Mature"
	elif unique_bonus >= 2:
		return "Developing"
	return "Basic"

func get_linkage_ecosystem_health() -> float:
	var synergy := get_production_synergy()
	var sy_val: float = 90.0 if synergy in ["Strong", "Excellent"] else (60.0 if synergy in ["Moderate", "Good"] else 30.0)
	var potential := get_optimization_potential_pct()
	var maturity := get_workshop_maturity()
	var m_val: float = 90.0 if maturity == "Mature" else (60.0 if maturity == "Developing" else 30.0)
	return snapped((sy_val + potential + m_val) / 3.0, 0.1)

func get_integration_maturity_index() -> float:
	var density := get_network_density()
	var d_val: float = 90.0 if density in ["Dense", "Saturated"] else (60.0 if density in ["Moderate", "Connected"] else 30.0)
	var coverage := get_bonus_coverage()
	var c_val: float = 90.0 if coverage in ["Full", "Wide"] else (60.0 if coverage in ["Partial", "Moderate"] else 30.0)
	var linked := get_linked_bench_count()
	var total := WORKBENCHES.size()
	var ratio: float = float(linked) / float(total) * 100.0 if total > 0 else 0.0
	return snapped((d_val + c_val + ratio) / 3.0, 0.1)

func get_production_governance() -> String:
	var ecosystem := get_linkage_ecosystem_health()
	var maturity := get_integration_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _links.size() > 0:
		return "Nascent"
	return "Dormant"
