extends Node

var _pawn_abilities: Dictionary = {}

const ABILITIES: Dictionary = {
	"Skip": {"type": "psycast", "level": 1, "cooldown": 120, "range": 25, "description": "Teleport to target"},
	"Stun": {"type": "psycast", "level": 1, "cooldown": 60, "range": 15, "duration": 30},
	"Berserk": {"type": "psycast", "level": 3, "cooldown": 300, "range": 20, "duration": 60},
	"Invisibility": {"type": "psycast", "level": 4, "cooldown": 600, "range": 0, "duration": 45},
	"BerserkPulse": {"type": "psycast", "level": 5, "cooldown": 900, "range": 15, "radius": 8},
	"MassHeal": {"type": "psycast", "level": 6, "cooldown": 1200, "range": 0, "radius": 20},
	"Farskip": {"type": "psycast", "level": 4, "cooldown": 600, "range": 999},
	"WordOfJoy": {"type": "psycast", "level": 2, "cooldown": 180, "range": 20, "mood_bonus": 20},
	"Burden": {"type": "psycast", "level": 1, "cooldown": 60, "range": 20, "slow_factor": 0.5},
	"BlindingPulse": {"type": "psycast", "level": 2, "cooldown": 180, "range": 15, "radius": 6},
	"NeuralHeatDump": {"type": "psycast", "level": 3, "cooldown": 300, "range": 20},
	"Waterskip": {"type": "psycast", "level": 1, "cooldown": 60, "range": 25}
}

func grant_ability(pawn_id: int, ability_name: String) -> bool:
	if not ABILITIES.has(ability_name):
		return false
	if not _pawn_abilities.has(pawn_id):
		_pawn_abilities[pawn_id] = []
	if ability_name in _pawn_abilities[pawn_id]:
		return false
	_pawn_abilities[pawn_id].append(ability_name)
	return true

func get_abilities(pawn_id: int) -> Array:
	return _pawn_abilities.get(pawn_id, [])

func get_ability_info(ability_name: String) -> Dictionary:
	return ABILITIES.get(ability_name, {})

func can_use_ability(pawn_id: int, ability_name: String) -> bool:
	return ability_name in _pawn_abilities.get(pawn_id, [])

func get_abilities_by_level(level: int) -> Array[String]:
	var result: Array[String] = []
	for a: String in ABILITIES:
		if int(ABILITIES[a].get("level", 0)) == level:
			result.append(a)
	return result


func get_most_powerful_pawn() -> Dictionary:
	var best_id: int = -1
	var best_count: int = 0
	for pid: int in _pawn_abilities:
		if _pawn_abilities[pid].size() > best_count:
			best_count = _pawn_abilities[pid].size()
			best_id = pid
	if best_id < 0:
		return {}
	return {"pawn_id": best_id, "ability_count": best_count}


func get_total_abilities_granted() -> int:
	var total: int = 0
	for pid: int in _pawn_abilities:
		total += _pawn_abilities[pid].size()
	return total


func get_avg_abilities_per_pawn() -> float:
	if _pawn_abilities.is_empty():
		return 0.0
	return float(get_total_abilities_granted()) / _pawn_abilities.size()


func get_highest_level_ability() -> String:
	var best: String = ""
	var best_level: int = 0
	for a: String in ABILITIES:
		var lvl: int = int(ABILITIES[a].get("level", 0))
		if lvl > best_level:
			best_level = lvl
			best = a
	return best


func get_ability_coverage() -> float:
	var used: Dictionary = {}
	for pid: int in _pawn_abilities:
		for a in _pawn_abilities[pid]:
			used[String(a)] = true
	if ABILITIES.is_empty():
		return 0.0
	return float(used.size()) / ABILITIES.size()


func get_level_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for a: String in ABILITIES:
		var lvl: int = int(ABILITIES[a].get("level", 0))
		dist[lvl] = dist.get(lvl, 0) + 1
	return dist


func get_avg_cooldown() -> float:
	if ABILITIES.is_empty():
		return 0.0
	var total: float = 0.0
	for a: String in ABILITIES:
		total += float(ABILITIES[a].get("cooldown", 0))
	return snappedf(total / float(ABILITIES.size()), 0.1)


func get_low_level_count() -> int:
	var count: int = 0
	for a: String in ABILITIES:
		if int(ABILITIES[a].get("level", 0)) <= 2:
			count += 1
	return count


func get_psycast_mastery() -> String:
	var coverage: float = get_ability_coverage()
	if coverage >= 0.7:
		return "Adept"
	elif coverage >= 0.4:
		return "Developing"
	elif coverage >= 0.15:
		return "Novice"
	return "Dormant"

func get_power_concentration() -> String:
	var low: int = get_low_level_count()
	var total: int = ABILITIES.size()
	if total == 0:
		return "N/A"
	var low_ratio: float = float(low) / float(total)
	if low_ratio >= 0.7:
		return "Scattered"
	elif low_ratio >= 0.4:
		return "Mixed"
	return "Focused"

func get_tactical_readiness_pct() -> float:
	if _pawn_abilities.is_empty():
		return 0.0
	var avg: float = get_avg_abilities_per_pawn()
	return snappedf(clampf(avg / 5.0 * 100.0, 0.0, 100.0), 0.1)

func get_summary() -> Dictionary:
	return {
		"ability_types": ABILITIES.size(),
		"pawns_with_abilities": _pawn_abilities.size(),
		"total_granted": get_total_abilities_granted(),
		"avg_per_pawn": snapped(get_avg_abilities_per_pawn(), 0.1),
		"highest_level": get_highest_level_ability(),
		"coverage": snapped(get_ability_coverage(), 0.01),
		"level_dist": get_level_distribution(),
		"avg_cooldown": get_avg_cooldown(),
		"low_level_abilities": get_low_level_count(),
		"psycast_mastery": get_psycast_mastery(),
		"power_concentration": get_power_concentration(),
		"tactical_readiness_pct": get_tactical_readiness_pct(),
		"psionic_depth": get_psionic_depth(),
		"ability_versatility": get_ability_versatility(),
		"combat_psych_readiness": get_combat_psych_readiness(),
		"psionic_ecosystem_health": get_psionic_ecosystem_health(),
		"psycast_governance": get_psycast_governance(),
		"psylink_maturity_index": get_psylink_maturity_index(),
	}

func get_psionic_depth() -> String:
	var mastery := get_psycast_mastery()
	var total := get_total_abilities_granted()
	if mastery in ["Master"] and total >= 5:
		return "Profound"
	elif total >= 3:
		return "Moderate"
	return "Shallow"

func get_ability_versatility() -> float:
	var levels := get_level_distribution()
	var unique_levels := levels.size()
	var total := ABILITIES.size()
	if total <= 0:
		return 0.0
	return snapped(float(unique_levels) / float(total) * 100.0, 0.1)

func get_combat_psych_readiness() -> String:
	var tactical := get_tactical_readiness_pct()
	var concentration := get_power_concentration()
	if tactical >= 70.0 and concentration in ["Focused", "Concentrated"]:
		return "Battle Ready"
	elif tactical >= 40.0:
		return "Prepared"
	return "Unready"

func get_psionic_ecosystem_health() -> float:
	var depth := get_psionic_depth()
	var d_val: float = 90.0 if depth in ["Deep", "Profound"] else (60.0 if depth in ["Moderate", "Developing"] else 30.0)
	var readiness := get_combat_psych_readiness()
	var r_val: float = 90.0 if readiness == "Battle Ready" else (60.0 if readiness == "Prepared" else 30.0)
	var tactical := get_tactical_readiness_pct()
	return snapped((d_val + r_val + tactical) / 3.0, 0.1)

func get_psylink_maturity_index() -> float:
	var mastery := get_psycast_mastery()
	var m_val: float = 90.0 if mastery in ["Master", "Adept"] else (60.0 if mastery in ["Competent", "Moderate"] else 30.0)
	var concentration := get_power_concentration()
	var c_val: float = 90.0 if concentration in ["Focused", "Concentrated"] else (60.0 if concentration in ["Spread", "Moderate"] else 30.0)
	var versatility := get_ability_versatility()
	return snapped((m_val + c_val + minf(versatility, 100.0)) / 3.0, 0.1)

func get_psycast_governance() -> String:
	var ecosystem := get_psionic_ecosystem_health()
	var maturity := get_psylink_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _pawn_abilities.size() > 0:
		return "Nascent"
	return "Dormant"
