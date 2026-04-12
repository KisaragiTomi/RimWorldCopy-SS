extends Node

const BACKSTORY_WORK_DISABLED: Dictionary = {
	"Nobleman": ["Manual", "Cleaning", "Hauling"],
	"Sheriff": [],
	"Farmer": [],
	"Scientist": ["Combat"],
	"Medic": [],
	"Pyro": [],
	"Assassin": ["Social", "Caring"],
	"Artist": [],
	"Miner": [],
	"Slave": [],
}

const BACKSTORY_SKILL_BONUS: Dictionary = {
	"Nobleman": {"Social": 4, "Intellectual": 2},
	"Sheriff": {"Shooting": 3, "Melee": 2},
	"Farmer": {"Plants": 4, "Animals": 2, "Cooking": 1},
	"Scientist": {"Intellectual": 5, "Medicine": 2},
	"Medic": {"Medicine": 5, "Intellectual": 1},
	"Pyro": {"Crafting": 2},
	"Assassin": {"Shooting": 4, "Melee": 3},
	"Artist": {"Artistic": 5, "Crafting": 2},
	"Miner": {"Mining": 4, "Construction": 2},
	"Slave": {"Hauling": 2, "Cleaning": 2},
}

const BACKSTORY_TRAIT_TENDENCY: Dictionary = {
	"Nobleman": ["Greedy", "Beautiful"],
	"Pyro": ["Pyromaniac"],
	"Assassin": ["Psychopath", "Bloodlust"],
	"Scientist": ["FastLearner"],
	"Artist": ["CreativeInspiration"],
}


func get_disabled_work(backstory: String) -> Array:
	return BACKSTORY_WORK_DISABLED.get(backstory, [])


func get_skill_bonuses(backstory: String) -> Dictionary:
	return BACKSTORY_SKILL_BONUS.get(backstory, {})


func get_trait_tendencies(backstory: String) -> Array:
	return BACKSTORY_TRAIT_TENDENCY.get(backstory, [])


func can_do_work(backstory: String, work_type: String) -> bool:
	var disabled: Array = get_disabled_work(backstory)
	return not disabled.has(work_type)


func apply_backstory_to_pawn(pawn: Pawn) -> void:
	if not pawn.has_meta("backstory"):
		return
	var backstory: String = str(pawn.get_meta("backstory"))
	var bonuses: Dictionary = get_skill_bonuses(backstory)
	for skill_name: String in bonuses:
		if pawn.skills.has(skill_name):
			var sdata: Dictionary = pawn.skills[skill_name]
			sdata["level"] = int(sdata.get("level", 0)) + int(bonuses[skill_name])


func get_backstory_description(backstory: String) -> String:
	var disabled := get_disabled_work(backstory)
	var bonuses := get_skill_bonuses(backstory)
	var traits := get_trait_tendencies(backstory)
	var parts: PackedStringArray = []
	if bonuses.size() > 0:
		var skill_strs: PackedStringArray = []
		for s: String in bonuses:
			skill_strs.append(s + "+" + str(bonuses[s]))
		parts.append("Skills: " + ", ".join(skill_strs))
	if disabled.size() > 0:
		parts.append("Disabled: " + ", ".join(PackedStringArray(disabled)))
	if traits.size() > 0:
		parts.append("Traits: " + ", ".join(PackedStringArray(traits)))
	return " | ".join(parts) if parts.size() > 0 else "No special effects"


func get_all_backstory_descriptions() -> Dictionary:
	var result: Dictionary = {}
	for backstory: String in BACKSTORY_WORK_DISABLED:
		result[backstory] = get_backstory_description(backstory)
	return result


func get_colony_backstory_distribution() -> Dictionary:
	if not PawnManager:
		return {}
	var dist: Dictionary = {}
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var bs: String = str(p.get_meta("backstory")) if p.has_meta("backstory") else "Unknown"
		dist[bs] = dist.get(bs, 0) + 1
	return dist


func get_most_common_backstory() -> String:
	var dist := get_colony_backstory_distribution()
	var best: String = ""
	var best_n: int = 0
	for bs: String in dist:
		if dist[bs] > best_n:
			best_n = dist[bs]
			best = bs
	return best


func get_work_disabled_count() -> int:
	var count: int = 0
	for bs: String in BACKSTORY_WORK_DISABLED:
		count += BACKSTORY_WORK_DISABLED[bs].size()
	return count


func get_unique_backstory_count() -> int:
	return get_colony_backstory_distribution().size()


func get_workforce_impact() -> String:
	var disabled: int = get_work_disabled_count()
	if disabled == 0:
		return "None"
	elif disabled <= 3:
		return "Mild"
	elif disabled <= 8:
		return "Moderate"
	return "Severe"

func get_backstory_diversity_pct() -> float:
	if BACKSTORY_WORK_DISABLED.is_empty():
		return 0.0
	return snappedf(float(get_unique_backstory_count()) / float(BACKSTORY_WORK_DISABLED.size()) * 100.0, 0.1)

func get_skill_bonus_coverage() -> int:
	return BACKSTORY_SKILL_BONUS.size()

func get_summary() -> Dictionary:
	return {
		"backstories": BACKSTORY_WORK_DISABLED.size(),
		"skill_bonus_entries": BACKSTORY_SKILL_BONUS.size(),
		"trait_tendencies": BACKSTORY_TRAIT_TENDENCY.size(),
		"colony_distribution": get_colony_backstory_distribution(),
		"most_common": get_most_common_backstory(),
		"total_work_disabled": get_work_disabled_count(),
		"unique_in_colony": get_unique_backstory_count(),
		"disabled_per_backstory": snappedf(float(get_work_disabled_count()) / maxf(float(BACKSTORY_WORK_DISABLED.size()), 1.0), 0.1),
		"trait_tendency_coverage": BACKSTORY_TRAIT_TENDENCY.size(),
		"workforce_impact": get_workforce_impact(),
		"backstory_diversity_pct": get_backstory_diversity_pct(),
		"skill_bonus_coverage": get_skill_bonus_coverage(),
		"labor_versatility": get_labor_versatility(),
		"skill_coverage_rating": get_skill_coverage_rating(),
		"backstory_synergy": get_backstory_synergy(),
		"talent_ecosystem_depth": get_talent_ecosystem_depth(),
		"workforce_composition_index": get_workforce_composition_index(),
		"cultural_legacy": get_cultural_legacy(),
	}

func get_talent_ecosystem_depth() -> float:
	var unique := float(get_unique_backstory_count())
	var bonus_coverage := float(get_skill_bonus_coverage())
	return snapped(unique * bonus_coverage / maxf(float(BACKSTORY_WORK_DISABLED.size()), 1.0) * 10.0, 0.1)

func get_workforce_composition_index() -> float:
	var diversity := get_backstory_diversity_pct()
	var disabled := float(get_work_disabled_count())
	var total := float(BACKSTORY_WORK_DISABLED.size())
	if total <= 0.0:
		return 0.0
	return snapped(diversity * (1.0 - disabled / total / 5.0), 0.1)

func get_cultural_legacy() -> String:
	var synergy := get_backstory_synergy()
	var versatility := get_labor_versatility()
	if synergy == "Strong" and versatility == "Versatile":
		return "Rich Heritage"
	elif synergy == "Weak" or versatility == "Restricted":
		return "Limited"
	return "Growing"

func get_labor_versatility() -> String:
	var disabled := get_work_disabled_count()
	var total := BACKSTORY_WORK_DISABLED.size()
	if total <= 0:
		return "N/A"
	var restriction_ratio := float(disabled) / float(total)
	if restriction_ratio < 0.2:
		return "Versatile"
	elif restriction_ratio < 0.5:
		return "Moderate"
	return "Restricted"

func get_skill_coverage_rating() -> String:
	var coverage := get_skill_bonus_coverage()
	if coverage >= 80.0:
		return "Comprehensive"
	elif coverage >= 50.0:
		return "Adequate"
	return "Gaps Present"

func get_backstory_synergy() -> String:
	var diversity := get_backstory_diversity_pct()
	var workforce := get_workforce_impact()
	if diversity >= 70.0 and workforce in ["Positive", "Balanced"]:
		return "Synergistic"
	elif diversity >= 40.0:
		return "Compatible"
	return "Conflicting"
