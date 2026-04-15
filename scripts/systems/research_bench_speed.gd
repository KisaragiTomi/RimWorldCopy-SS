extends Node

const BENCH_TYPES: Dictionary = {
	"SimpleResearchBench": {"base_speed": 1.0, "power": 0, "tech_level": "Neolithic"},
	"HiTechResearchBench": {"base_speed": 1.0, "power": 250, "tech_level": "Industrial"},
	"MultiAnalyzerBench": {"base_speed": 1.0, "power": 400, "tech_level": "Spacer"}
}

const BENCH_ADDONS: Dictionary = {
	"MultiAnalyzer": {"speed_bonus": 0.10, "required_bench": "HiTechResearchBench", "power": 200},
	"Bookshelf": {"speed_bonus": 0.06, "max_count": 2, "required_bench": "any"},
	"Vitals Monitor": {"speed_bonus": 0.04, "required_bench": "HiTechResearchBench", "power": 80}
}

const SKILL_SPEED_CURVE: Dictionary = {
	0: 0.50, 2: 0.60, 4: 0.75, 6: 0.90, 8: 1.00,
	10: 1.10, 12: 1.25, 14: 1.40, 16: 1.55, 18: 1.70, 20: 2.00
}

func calc_research_speed(bench_type: String, addons: Array, skill_level: int) -> float:
	var bench: Dictionary = BENCH_TYPES.get(bench_type, BENCH_TYPES["SimpleResearchBench"])
	var speed: float = bench["base_speed"]
	for addon: String in addons:
		if BENCH_ADDONS.has(addon):
			speed += BENCH_ADDONS[addon]["speed_bonus"]
	var skill_mult: float = 0.5
	for lvl: int in SKILL_SPEED_CURVE:
		if skill_level >= lvl:
			skill_mult = SKILL_SPEED_CURVE[lvl]
	speed *= skill_mult
	return speed

func get_power_required(bench_type: String, addons: Array) -> int:
	var total: int = BENCH_TYPES.get(bench_type, {}).get("power", 0)
	for addon: String in addons:
		total += BENCH_ADDONS.get(addon, {}).get("power", 0)
	return total

func get_fastest_bench() -> String:
	var best: String = ""
	var best_speed: float = 0.0
	for b: String in BENCH_TYPES:
		var s: float = float(BENCH_TYPES[b].get("base_speed", 0.0))
		if s > best_speed:
			best_speed = s
			best = b
	return best


func get_max_theoretical_speed() -> float:
	var best_base: float = 0.0
	for b: String in BENCH_TYPES:
		best_base = maxf(best_base, float(BENCH_TYPES[b].get("base_speed", 0.0)))
	var addon_total: float = 0.0
	for a: String in BENCH_ADDONS:
		addon_total += float(BENCH_ADDONS[a].get("speed_bonus", 0.0))
	var max_skill: float = float(SKILL_SPEED_CURVE.get(20, 2.0))
	return (best_base + addon_total) * max_skill


func get_addon_total_bonus() -> float:
	var total: float = 0.0
	for a: String in BENCH_ADDONS:
		total += float(BENCH_ADDONS[a].get("speed_bonus", 0.0))
	return total


func get_min_speed() -> float:
	var min_skill: float = float(SKILL_SPEED_CURVE.get(0, 0.5))
	var min_base: float = 999.0
	for b: String in BENCH_TYPES:
		min_base = minf(min_base, float(BENCH_TYPES[b].get("base_speed", 1.0)))
	return min_base * min_skill


func get_total_power_required() -> int:
	var total: int = 0
	for b: String in BENCH_TYPES:
		total += int(BENCH_TYPES[b].get("power", 0))
	for a: String in BENCH_ADDONS:
		total += int(BENCH_ADDONS[a].get("power", 0))
	return total


func get_speed_range() -> Dictionary:
	return {"min": snapped(get_min_speed(), 0.01), "max": snapped(get_max_theoretical_speed(), 0.01)}


func get_speed_spread() -> float:
	return snappedf(get_max_theoretical_speed() - get_min_speed(), 0.01)


func get_bench_with_highest_power() -> String:
	var best: String = ""
	var best_p: int = 0
	for b: String in BENCH_TYPES:
		var p: int = int(BENCH_TYPES[b].get("power", 0))
		if p > best_p:
			best_p = p
			best = b
	return best


func get_unpowered_bench_count() -> int:
	var count: int = 0
	for b: String in BENCH_TYPES:
		if int(BENCH_TYPES[b].get("power", 0)) == 0:
			count += 1
	return count


func get_research_capability() -> String:
	var max_spd: float = get_max_theoretical_speed()
	if max_spd >= 3.0:
		return "Advanced"
	elif max_spd >= 2.0:
		return "Standard"
	elif max_spd >= 1.0:
		return "Basic"
	return "Primitive"

func get_power_efficiency() -> String:
	var total_pwr: int = get_total_power_required()
	if total_pwr == 0:
		return "Self-Powered"
	elif total_pwr <= 500:
		return "Efficient"
	elif total_pwr <= 1200:
		return "Moderate"
	return "Heavy"

func get_upgrade_potential_pct() -> float:
	if BENCH_ADDONS.is_empty():
		return 0.0
	var bonus: float = get_addon_total_bonus()
	var max_spd: float = get_max_theoretical_speed()
	if max_spd <= 0.0:
		return 0.0
	return snappedf(clampf(bonus / max_spd * 100.0, 0.0, 100.0), 0.1)

func get_summary() -> Dictionary:
	return {
		"bench_types": BENCH_TYPES.size(),
		"addon_types": BENCH_ADDONS.size(),
		"skill_levels": SKILL_SPEED_CURVE.size(),
		"max_speed": get_max_theoretical_speed(),
		"addon_bonus": get_addon_total_bonus(),
		"min_speed": snapped(get_min_speed(), 0.01),
		"total_power": get_total_power_required(),
		"speed_spread": get_speed_spread(),
		"highest_power_bench": get_bench_with_highest_power(),
		"unpowered_benches": get_unpowered_bench_count(),
		"research_capability": get_research_capability(),
		"power_efficiency": get_power_efficiency(),
		"upgrade_potential_pct": get_upgrade_potential_pct(),
		"research_throughput": get_research_throughput(),
		"bench_optimization": get_bench_optimization(),
		"tech_advancement_pace": get_tech_advancement_pace(),
		"research_ecosystem_health": get_research_ecosystem_health(),
		"scientific_governance": get_scientific_governance(),
		"knowledge_infrastructure_index": get_knowledge_infrastructure_index(),
	}

func get_research_throughput() -> float:
	var max_spd := get_max_theoretical_speed()
	var addon := get_addon_total_bonus()
	return snapped(max_spd + addon, 0.01)

func get_bench_optimization() -> String:
	var unpowered := get_unpowered_bench_count()
	var total := BENCH_TYPES.size()
	if total <= 0:
		return "No Benches"
	var powered_pct := float(total - unpowered) / float(total) * 100.0
	if powered_pct >= 90.0:
		return "Optimal"
	elif powered_pct >= 60.0:
		return "Partial"
	return "Underutilized"

func get_tech_advancement_pace() -> String:
	var capability := get_research_capability()
	var efficiency := get_power_efficiency()
	if capability in ["Advanced", "Superior"] and efficiency in ["Efficient", "Excellent"]:
		return "Rapid"
	elif capability in ["Standard", "Advanced"]:
		return "Steady"
	return "Slow"

func get_research_ecosystem_health() -> float:
	var throughput := get_research_throughput()
	var optimization := get_bench_optimization()
	var o_val: float = 90.0 if optimization == "Maximized" else (60.0 if optimization == "Optimized" else 30.0)
	var potential := get_upgrade_potential_pct()
	return snapped((throughput + o_val + (100.0 - potential)) / 3.0, 0.1)

func get_scientific_governance() -> String:
	var ecosystem := get_research_ecosystem_health()
	var pace := get_tech_advancement_pace()
	var p_val: float = 90.0 if pace == "Rapid" else (60.0 if pace == "Steady" else 20.0)
	var combined := (ecosystem + p_val) / 2.0
	if combined >= 70.0:
		return "Cutting Edge"
	elif combined >= 40.0:
		return "Progressive"
	elif BENCH_TYPES.size() > 0:
		return "Foundational"
	return "None"

func get_knowledge_infrastructure_index() -> float:
	var capability := get_research_capability()
	var c_val: float = 90.0 if capability in ["Advanced", "Superior"] else (60.0 if capability == "Standard" else 25.0)
	var efficiency := get_power_efficiency()
	var e_val: float = 90.0 if efficiency in ["Efficient", "Excellent"] else (60.0 if efficiency == "Moderate" else 25.0)
	return snapped((c_val + e_val) / 2.0, 0.1)
