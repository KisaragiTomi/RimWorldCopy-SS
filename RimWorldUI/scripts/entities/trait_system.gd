class_name TraitSystem
extends RefCounted

## Personality traits that affect mood, work speed, and capabilities.

const TRAIT_DATA: Dictionary = {
	"Optimist": {"mood": 0.06, "description": "Always sees the bright side.", "work_speed": 0.0, "conflicts": ["Pessimist"]},
	"Pessimist": {"mood": -0.06, "description": "Tends to focus on negatives.", "work_speed": 0.0, "conflicts": ["Optimist"]},
	"Industrious": {"mood": 0.0, "description": "Works faster than most.", "work_speed": 0.35, "conflicts": ["Lazy"]},
	"Lazy": {"mood": 0.0, "description": "Works slower than most.", "work_speed": -0.2, "conflicts": ["Industrious"]},
	"IronWilled": {"mood": 0.0, "description": "Much harder to break.", "mental_break_modifier": 0.5, "conflicts": ["Nervous"]},
	"Nervous": {"mood": -0.02, "description": "Breaks more easily under pressure.", "mental_break_modifier": 1.5, "conflicts": ["IronWilled"]},
	"Bloodlust": {"mood": 0.0, "description": "Enjoys violence.", "combat_bonus": 0.15, "conflicts": ["Kind"]},
	"Kind": {"mood": 0.02, "description": "Naturally caring.", "social_bonus": 0.2, "conflicts": ["Bloodlust"]},
	"NightOwl": {"mood": 0.0, "description": "Prefers working at night.", "conflicts": []},
	"Pyromaniac": {"mood": 0.0, "description": "Fascinated by fire.", "fire_risk": true, "conflicts": []},
	"GreenThumb": {"mood": 0.0, "description": "Naturally talented with plants.", "plant_bonus": 0.3, "conflicts": []},
	"QuickSleeper": {"mood": 0.0, "description": "Needs less sleep.", "rest_rate": 1.3, "conflicts": []},
	"Tough": {"mood": 0.0, "description": "Takes less damage.", "damage_reduction": 0.5, "conflicts": []},
	"Beautiful": {"mood": 0.02, "description": "Attractive appearance.", "social_bonus": 0.15, "conflicts": ["Ugly"]},
	"Ugly": {"mood": -0.02, "description": "Unattractive appearance.", "social_bonus": -0.1, "conflicts": ["Beautiful"]},
}


static func get_trait_data(trait_name: String) -> Dictionary:
	return TRAIT_DATA.get(trait_name, {})


static func get_mood_modifier(traits: PackedStringArray) -> float:
	var total: float = 0.0
	for t: String in traits:
		var data: Dictionary = TRAIT_DATA.get(t, {})
		total += data.get("mood", 0.0) as float
	return total


static func get_work_speed_modifier(traits: PackedStringArray) -> float:
	var total: float = 0.0
	for t: String in traits:
		var data: Dictionary = TRAIT_DATA.get(t, {})
		total += data.get("work_speed", 0.0) as float
	return total


static func get_mental_break_modifier(traits: PackedStringArray) -> float:
	var total: float = 1.0
	for t: String in traits:
		var data: Dictionary = TRAIT_DATA.get(t, {})
		if data.has("mental_break_modifier"):
			total *= data["mental_break_modifier"] as float
	return total


static func has_trait_flag(traits: PackedStringArray, flag: String) -> bool:
	for t: String in traits:
		var data: Dictionary = TRAIT_DATA.get(t, {})
		if data.has(flag):
			return true
	return false


static func get_combat_bonus(traits: PackedStringArray) -> float:
	var total: float = 0.0
	for t: String in traits:
		var data: Dictionary = TRAIT_DATA.get(t, {})
		total += data.get("combat_bonus", 0.0) as float
	return total


static func get_social_bonus(traits: PackedStringArray) -> float:
	var total: float = 0.0
	for t: String in traits:
		var data: Dictionary = TRAIT_DATA.get(t, {})
		total += data.get("social_bonus", 0.0) as float
	return total


static func get_trait_description(trait_name: String) -> String:
	var data: Dictionary = TRAIT_DATA.get(trait_name, {})
	return data.get("description", "") as String


static func assign_random_traits(rng: RandomNumberGenerator, count: int = 2) -> PackedStringArray:
	var all_traits: Array = TRAIT_DATA.keys()
	var result: PackedStringArray = PackedStringArray()
	var attempts: int = 0
	while result.size() < count and attempts < 20:
		attempts += 1
		var candidate: String = all_traits[rng.randi_range(0, all_traits.size() - 1)]
		if result.has(candidate):
			continue
		var data: Dictionary = TRAIT_DATA.get(candidate, {})
		var conflicts: Array = data.get("conflicts", []) as Array
		var has_conflict: bool = false
		for c: String in result:
			if conflicts.has(c):
				has_conflict = true
				break
		if not has_conflict:
			result.append(candidate)
	return result


static func get_total_trait_count() -> int:
	return TRAIT_DATA.size()


static func get_conflict_pair_count() -> int:
	var count: int = 0
	for k: String in TRAIT_DATA:
		var conflicts: Array = TRAIT_DATA[k].get("conflicts", []) as Array
		count += conflicts.size()
	return count / 2


static func get_avg_mood_offset() -> float:
	if TRAIT_DATA.is_empty():
		return 0.0
	var total: float = 0.0
	for k: String in TRAIT_DATA:
		total += TRAIT_DATA[k].get("mood_offset", 0.0) as float
	return total / float(TRAIT_DATA.size())


static func get_positive_trait_count() -> int:
	var count: int = 0
	for k: String in TRAIT_DATA:
		if (TRAIT_DATA[k].get("mood_offset", 0.0) as float) > 0.0:
			count += 1
	return count


static func get_negative_trait_count() -> int:
	var count: int = 0
	for k: String in TRAIT_DATA:
		if (TRAIT_DATA[k].get("mood_offset", 0.0) as float) < 0.0:
			count += 1
	return count


static func get_combat_trait_count() -> int:
	var count: int = 0
	for k: String in TRAIT_DATA:
		if TRAIT_DATA[k].has("combat_bonus"):
			count += 1
	return count


static func get_personality_depth() -> float:
	var total := get_total_trait_count()
	var conflicts := get_conflict_pair_count()
	var positive := get_positive_trait_count()
	var negative := get_negative_trait_count()
	if total <= 0:
		return 0.0
	var balance := 1.0 - absf(float(positive - negative)) / float(total)
	var complexity := minf(float(conflicts) / float(total), 1.0)
	return snapped((balance * 0.5 + complexity * 0.5) * 100.0, 0.1)

static func get_trait_balance_ratio() -> float:
	var pos := get_positive_trait_count()
	var neg := get_negative_trait_count()
	if pos + neg <= 0:
		return 50.0
	return snapped(float(pos) / float(pos + neg) * 100.0, 0.1)

static func get_combat_readiness_from_traits() -> String:
	var combat := get_combat_trait_count()
	var total := get_total_trait_count()
	if total <= 0:
		return "None"
	var ratio := float(combat) / float(total)
	if ratio >= 0.3:
		return "Warrior Culture"
	elif ratio >= 0.15:
		return "Balanced"
	elif combat >= 1:
		return "Minimal"
	return "Pacifist"

static func get_trait_catalog_summary() -> Dictionary:
	return {
		"total_traits": get_total_trait_count(),
		"conflict_pairs": get_conflict_pair_count(),
		"avg_mood_offset": snappedf(get_avg_mood_offset(), 0.001),
		"positive_traits": get_positive_trait_count(),
		"negative_traits": get_negative_trait_count(),
		"combat_traits": get_combat_trait_count(),
		"personality_depth": get_personality_depth(),
		"trait_balance_ratio": get_trait_balance_ratio(),
		"combat_readiness": get_combat_readiness_from_traits(),
		"trait_ecosystem_health": get_trait_ecosystem_health(),
		"character_governance": get_character_governance(),
		"identity_maturity_index": get_identity_maturity_index(),
	}

static func get_trait_ecosystem_health() -> float:
	var depth := get_personality_depth()
	var balance := get_trait_balance_ratio()
	var readiness := get_combat_readiness_from_traits()
	var r_val: float = 90.0 if readiness == "Warrior Culture" else (65.0 if readiness == "Capable" else (40.0 if readiness == "Civilian" else 15.0))
	return snapped((minf(depth, 100.0) + balance + r_val) / 3.0, 0.1)

static func get_character_governance() -> String:
	var eco := get_trait_ecosystem_health()
	var mat := get_identity_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_total_trait_count() > 0:
		return "Nascent"
	return "Dormant"

static func get_identity_maturity_index() -> float:
	var total := minf(float(get_total_trait_count()) * 5.0, 100.0)
	var pos := minf(float(get_positive_trait_count()) * 10.0, 100.0)
	var depth := minf(get_personality_depth(), 100.0)
	return snapped((total + pos + depth) / 3.0, 0.1)
