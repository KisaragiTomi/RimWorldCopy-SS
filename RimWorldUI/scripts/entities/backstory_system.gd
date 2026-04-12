class_name BackstorySystem
extends RefCounted

## Backstory definitions for pawns. Each pawn gets a childhood + adulthood backstory.

const CHILDHOOD_STORIES: Array = [
	{
		"id": "FarmChild",
		"label": "Farm child",
		"desc": "Grew up working on a farm.",
		"skill_bonuses": {"Plants": 3, "Animals": 2},
		"incapable": [],
	},
	{
		"id": "UrbanChild",
		"label": "Urban child",
		"desc": "Raised in a crowded city.",
		"skill_bonuses": {"Social": 2, "Intellectual": 2},
		"incapable": ["Plants"],
	},
	{
		"id": "MilitaryBrat",
		"label": "Military brat",
		"desc": "Parents served in the military.",
		"skill_bonuses": {"Shooting": 2, "Melee": 2},
		"incapable": [],
	},
	{
		"id": "PrivilegedChild",
		"label": "Privileged child",
		"desc": "Born into wealth and comfort.",
		"skill_bonuses": {"Social": 3, "Intellectual": 1},
		"incapable": ["Mining", "Cleaning"],
	},
	{
		"id": "OrphanChild",
		"label": "Orphan",
		"desc": "Grew up without parents, learned to survive.",
		"skill_bonuses": {"Melee": 2, "Cooking": 2},
		"incapable": [],
	},
	{
		"id": "ScientistChild",
		"label": "Lab assistant",
		"desc": "Helped in a research lab as a youth.",
		"skill_bonuses": {"Intellectual": 4},
		"incapable": ["Melee"],
	},
]

const ADULTHOOD_STORIES: Array = [
	{
		"id": "Soldier",
		"label": "Soldier",
		"desc": "Served in a planetary militia.",
		"skill_bonuses": {"Shooting": 4, "Melee": 2},
		"incapable": [],
	},
	{
		"id": "Doctor",
		"label": "Field medic",
		"desc": "Treated wounded in conflict zones.",
		"skill_bonuses": {"Medicine": 5, "Intellectual": 2},
		"incapable": [],
	},
	{
		"id": "Researcher",
		"label": "Researcher",
		"desc": "Dedicated years to scientific discovery.",
		"skill_bonuses": {"Intellectual": 5, "Crafting": 1},
		"incapable": ["Melee"],
	},
	{
		"id": "Farmer",
		"label": "Farmer",
		"desc": "Worked the land for decades.",
		"skill_bonuses": {"Plants": 5, "Animals": 3},
		"incapable": [],
	},
	{
		"id": "Trader",
		"label": "Caravan trader",
		"desc": "Traveled between settlements selling goods.",
		"skill_bonuses": {"Social": 4, "Shooting": 1},
		"incapable": [],
	},
	{
		"id": "Artist",
		"label": "Artist",
		"desc": "Created beauty in a harsh world.",
		"skill_bonuses": {"Crafting": 4, "Construction": 2},
		"incapable": ["Mining"],
	},
	{
		"id": "Miner",
		"label": "Deep miner",
		"desc": "Spent years in underground mining operations.",
		"skill_bonuses": {"Mining": 5, "Construction": 2},
		"incapable": [],
	},
	{
		"id": "Cook",
		"label": "Colony cook",
		"desc": "Fed hundreds of hungry colonists.",
		"skill_bonuses": {"Cooking": 5, "Plants": 1},
		"incapable": [],
	},
]


static func assign_backstory(pawn: Pawn, rng: RandomNumberGenerator) -> Dictionary:
	var childhood: Dictionary = CHILDHOOD_STORIES[rng.randi_range(0, CHILDHOOD_STORIES.size() - 1)]
	var adulthood: Dictionary = ADULTHOOD_STORIES[rng.randi_range(0, ADULTHOOD_STORIES.size() - 1)]

	for skill: String in childhood.get("skill_bonuses", {}):
		var bonus: int = childhood["skill_bonuses"][skill]
		if pawn.skills.has(skill):
			pawn.skills[skill]["level"] = pawn.skills[skill].get("level", 0) + bonus

	for skill: String in adulthood.get("skill_bonuses", {}):
		var bonus: int = adulthood["skill_bonuses"][skill]
		if pawn.skills.has(skill):
			pawn.skills[skill]["level"] = pawn.skills[skill].get("level", 0) + bonus

	return {
		"childhood": childhood.get("id", ""),
		"childhood_label": childhood.get("label", ""),
		"adulthood": adulthood.get("id", ""),
		"adulthood_label": adulthood.get("label", ""),
	}


static func get_childhood_by_id(story_id: String) -> Dictionary:
	for s: Dictionary in CHILDHOOD_STORIES:
		if s.get("id", "") == story_id:
			return s
	return {}


static func get_adulthood_by_id(story_id: String) -> Dictionary:
	for s: Dictionary in ADULTHOOD_STORIES:
		if s.get("id", "") == story_id:
			return s
	return {}


static func get_total_unique_skills() -> int:
	var skills: Dictionary = {}
	for s: Dictionary in CHILDHOOD_STORIES:
		for sk: String in s.get("skill_bonuses", {}):
			skills[sk] = true
	for s: Dictionary in ADULTHOOD_STORIES:
		for sk: String in s.get("skill_bonuses", {}):
			skills[sk] = true
	return skills.size()

static func get_highest_single_bonus() -> int:
	var best: int = 0
	for s: Dictionary in CHILDHOOD_STORIES:
		for sk: String in s.get("skill_bonuses", {}):
			if s["skill_bonuses"][sk] > best:
				best = s["skill_bonuses"][sk]
	for s: Dictionary in ADULTHOOD_STORIES:
		for sk: String in s.get("skill_bonuses", {}):
			if s["skill_bonuses"][sk] > best:
				best = s["skill_bonuses"][sk]
	return best

static func get_no_incapable_adulthood_count() -> int:
	var count: int = 0
	for s: Dictionary in ADULTHOOD_STORIES:
		if s.get("incapable", []).is_empty():
			count += 1
	return count

static func get_avg_bonus_per_story() -> float:
	var total: int = 0
	var count: int = 0
	for s: Dictionary in CHILDHOOD_STORIES:
		for sk: String in s.get("skill_bonuses", {}):
			total += int(s["skill_bonuses"][sk])
		count += 1
	for s: Dictionary in ADULTHOOD_STORIES:
		for sk: String in s.get("skill_bonuses", {}):
			total += int(s["skill_bonuses"][sk])
		count += 1
	if count <= 0:
		return 0.0
	return snappedf(float(total) / float(count), 0.1)

static func get_incapable_childhood_count() -> int:
	var cnt: int = 0
	for s: Dictionary in CHILDHOOD_STORIES:
		if not s.get("incapable", []).is_empty():
			cnt += 1
	return cnt

static func get_total_story_count() -> int:
	return CHILDHOOD_STORIES.size() + ADULTHOOD_STORIES.size()

static func get_narrative_depth() -> float:
	var total := float(get_total_story_count())
	var skills := float(get_total_unique_skills())
	if total <= 0.0:
		return 0.0
	return snapped(skills / total * 50.0 + minf(total / 20.0, 1.0) * 50.0, 0.1)

static func get_workforce_flexibility_from_stories() -> float:
	var no_incapable := float(get_no_incapable_adulthood_count())
	var total := float(ADULTHOOD_STORIES.size())
	if total <= 0.0:
		return 0.0
	return snapped(no_incapable / total * 100.0, 0.1)

static func get_skill_ceiling() -> String:
	var highest := get_highest_single_bonus()
	if highest >= 6:
		return "Elite"
	elif highest >= 4:
		return "High"
	elif highest >= 2:
		return "Moderate"
	return "Low"

static func get_summary() -> Dictionary:
	return {
		"childhood_count": CHILDHOOD_STORIES.size(),
		"adulthood_count": ADULTHOOD_STORIES.size(),
		"unique_skills": get_total_unique_skills(),
		"highest_single_bonus": get_highest_single_bonus(),
		"no_incapable_adulthood": get_no_incapable_adulthood_count(),
		"avg_bonus_per_story": get_avg_bonus_per_story(),
		"incapable_childhoods": get_incapable_childhood_count(),
		"total_stories": get_total_story_count(),
		"narrative_depth": get_narrative_depth(),
		"workforce_flexibility_pct": get_workforce_flexibility_from_stories(),
		"skill_ceiling": get_skill_ceiling(),
		"talent_pool_quality": get_talent_pool_quality(),
		"role_versatility_index": get_role_versatility_index(),
		"background_synergy_score": get_background_synergy_score(),
	}

static func get_talent_pool_quality() -> String:
	var avg_bonus: float = get_avg_bonus_per_story()
	var no_incap: int = get_no_incapable_adulthood_count()
	var total: int = ADULTHOOD_STORIES.size()
	if avg_bonus >= 3.0 and float(no_incap) / float(maxi(total, 1)) >= 0.5:
		return "Exceptional"
	if avg_bonus >= 2.0:
		return "Good"
	return "Average"

static func get_role_versatility_index() -> float:
	var unique_skills: int = get_total_unique_skills()
	var total: int = get_total_story_count()
	if total == 0:
		return 0.0
	return snappedf(float(unique_skills) / float(total) * 50.0, 0.1)

static func get_background_synergy_score() -> float:
	var highest: int = get_highest_single_bonus()
	var flexibility: float = get_workforce_flexibility_from_stories()
	var score: float = float(highest) * 10.0 + flexibility * 0.5
	return snappedf(clampf(score, 0.0, 100.0), 0.1)

static func get_all_skill_bonuses(childhood_id: String, adulthood_id: String) -> Dictionary:
	var result: Dictionary = {}
	var c: Dictionary = get_childhood_by_id(childhood_id)
	for sk: String in c.get("skill_bonuses", {}):
		result[sk] = result.get(sk, 0) + c["skill_bonuses"][sk]
	var a: Dictionary = get_adulthood_by_id(adulthood_id)
	for sk: String in a.get("skill_bonuses", {}):
		result[sk] = result.get(sk, 0) + a["skill_bonuses"][sk]
	return result
