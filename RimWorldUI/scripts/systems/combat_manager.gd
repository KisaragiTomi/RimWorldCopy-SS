class_name CombatUtil
extends RefCounted

## Static utility for resolving attacks between pawns or against pawns.
## Supports armor reduction, XP gain, kill tracking, and combat logging.

static var _rng := RandomNumberGenerator.new()
static var total_attacks: int = 0
static var total_hits: int = 0
static var total_kills: int = 0

const WEAPON_DATA: Dictionary = {
	"ShortBow": {"damage": 7.0, "range": 18, "type": "Arrow", "skill": "Shooting"},
	"Rifle": {"damage": 10.0, "range": 25, "type": "Bullet", "skill": "Shooting"},
	"Revolver": {"damage": 8.0, "range": 15, "type": "Bullet", "skill": "Shooting"},
	"SniperRifle": {"damage": 18.0, "range": 35, "type": "Bullet", "skill": "Shooting"},
	"MachineGun": {"damage": 6.0, "range": 22, "type": "Bullet", "skill": "Shooting"},
	"Knife": {"damage": 8.0, "range": 0, "type": "Cut", "skill": "Melee"},
	"Longsword": {"damage": 14.0, "range": 0, "type": "Cut", "skill": "Melee"},
	"Mace": {"damage": 12.0, "range": 0, "type": "Blunt", "skill": "Melee"},
	"Spear": {"damage": 11.0, "range": 0, "type": "Stab", "skill": "Melee"},
}


static func _get_weapon_stats(attacker: Pawn) -> Dictionary:
	var weapon_name: String = ""
	if attacker.equipment:
		weapon_name = attacker.equipment.get_weapon()
	if weapon_name.is_empty():
		return {}
	return WEAPON_DATA.get(weapon_name, {})


static func _apply_armor(target: Pawn, raw_damage: float, damage_type: String) -> float:
	if target.equipment == null:
		return raw_damage
	var reduction: float = 0.0
	if damage_type in ["Bullet", "Arrow", "Cut", "Stab"]:
		reduction = target.equipment.get_armor_sharp()
	elif damage_type == "Blunt":
		reduction = target.equipment.get_armor_blunt()
	return maxf(1.0, raw_damage * (1.0 - reduction))


static func _check_kill(target: Pawn, attacker: Pawn) -> bool:
	if target.dead:
		return false
	if target.health and target.health.should_be_dead():
		target.dead = true
		total_kills += 1
		attacker.gain_xp("Shooting", 100.0)
		if ColonyLog:
			ColonyLog.add_entry("Combat", "%s killed %s." % [attacker.pawn_name, target.pawn_name], "danger")
		if target.has_meta("faction") and target.get_meta("faction") == "enemy":
			if attacker.thought_tracker:
				attacker.thought_tracker.add_thought("KilledRaider")
		return true
	if target.health and target.health.should_be_downed():
		target.downed = true
		if ColonyLog:
			ColonyLog.add_entry("Combat", "%s downed %s." % [attacker.pawn_name, target.pawn_name], "warning")
	return false


static func ranged_attack(attacker: Pawn, target: Pawn, weapon_damage: float = 8.0, weapon_range: int = 20) -> Dictionary:
	var wstats := _get_weapon_stats(attacker)
	if not wstats.is_empty():
		weapon_damage = wstats.get("damage", weapon_damage) as float
		weapon_range = wstats.get("range", weapon_range) as int

	var dist := attacker.grid_pos.distance_to(target.grid_pos)
	if dist > weapon_range:
		return {"hit": false, "reason": "out_of_range"}
	total_attacks += 1

	var skill_level: int = attacker.get_skill_level("Shooting")
	var base_hit: float = 0.5 + skill_level * 0.03
	var range_penalty: float = dist * 0.015
	var hit_chance := clampf(base_hit - range_penalty, 0.05, 0.95)

	var cover_bonus: float = _get_cover_bonus(target)
	hit_chance -= cover_bonus

	if _rng.randf() > hit_chance:
		attacker.gain_xp("Shooting", 5.0)
		return {"hit": false, "reason": "missed", "hit_chance": snappedf(hit_chance, 0.01), "cover": cover_bonus > 0}

	var parts := target.health.body_parts.filter(func(bp: Dictionary) -> bool: return not bp.destroyed)
	if parts.is_empty():
		return {"hit": false, "reason": "no_valid_parts"}

	var hit_part: Dictionary = parts[_rng.randi_range(0, parts.size() - 1)]
	var dmg_type: String = wstats.get("type", "Bullet") as String
	var final_damage: float = _apply_armor(target, weapon_damage, dmg_type)

	var crit_result := _roll_crit(attacker, final_damage)
	final_damage = crit_result["damage"]
	var is_crit: bool = crit_result["is_crit"]

	var hediff := target.health.add_injury(hit_part.name, final_damage, dmg_type)
	total_hits += 1
	attacker.gain_xp("Shooting", 20.0)

	var killed := _check_kill(target, attacker)
	return {"hit": true, "part": hit_part.name, "damage": final_damage, "hediff": hediff, "killed": killed, "crit": is_crit}


static func melee_attack(attacker: Pawn, target: Pawn, weapon_damage: float = 10.0) -> Dictionary:
	var wstats := _get_weapon_stats(attacker)
	if not wstats.is_empty() and wstats.get("range", 0) == 0:
		weapon_damage = wstats.get("damage", weapon_damage) as float

	var dist := attacker.grid_pos.distance_to(target.grid_pos)
	if dist > 1.5:
		return {"hit": false, "reason": "too_far"}
	total_attacks += 1

	var skill_level: int = attacker.get_skill_level("Melee")
	var hit_chance := clampf(0.6 + skill_level * 0.035, 0.1, 0.95)

	var dodge_skill: int = target.get_skill_level("Melee")
	var dodge_chance := clampf(0.1 + dodge_skill * 0.02, 0.0, 0.5)

	if _rng.randf() > hit_chance:
		attacker.gain_xp("Melee", 5.0)
		return {"hit": false, "reason": "missed"}
	if _rng.randf() < dodge_chance:
		target.gain_xp("Melee", 8.0)
		return {"hit": false, "reason": "dodged"}

	var parts := target.health.body_parts.filter(func(bp: Dictionary) -> bool: return not bp.destroyed)
	if parts.is_empty():
		return {"hit": false, "reason": "no_valid_parts"}

	var hit_part: Dictionary = parts[_rng.randi_range(0, parts.size() - 1)]
	var dmg_type: String = wstats.get("type", "Cut") as String
	var final_damage: float = _apply_armor(target, weapon_damage, dmg_type)
	var hediff := target.health.add_injury(hit_part.name, final_damage, dmg_type)
	total_hits += 1
	attacker.gain_xp("Melee", 25.0)

	var killed := _check_kill(target, attacker)
	return {"hit": true, "part": hit_part.name, "damage": final_damage, "hediff": hediff, "killed": killed}


static var total_crits: int = 0

const COVER_DEFS := ["Wall", "Sandbag", "Barricade", "Chunk"]
const CRIT_CHANCE := 0.08
const CRIT_MULTIPLIER := 1.8


static func _get_cover_bonus(target: Pawn) -> float:
	if not ThingManager:
		return 0.0
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for d: Vector2i in dirs:
		var check := target.grid_pos + d
		for t: Thing in ThingManager.get_things_at(check):
			if t.def_name in COVER_DEFS:
				return 0.2
	return 0.0


static func _roll_crit(attacker: Pawn, damage: float) -> Dictionary:
	var skill: int = attacker.get_skill_level("Shooting") + attacker.get_skill_level("Melee")
	var crit_roll: float = CRIT_CHANCE + float(skill) * 0.005
	if _rng.randf() < crit_roll:
		total_crits += 1
		return {"is_crit": true, "damage": damage * CRIT_MULTIPLIER}
	return {"is_crit": false, "damage": damage}


static func get_avg_weapon_damage() -> float:
	var total: float = 0.0
	if WEAPON_DATA.is_empty():
		return 0.0
	for w: String in WEAPON_DATA:
		total += WEAPON_DATA[w].get("damage", 0.0)
	return snappedf(total / float(WEAPON_DATA.size()), 0.01)

static func get_melee_weapon_count() -> int:
	var count: int = 0
	for w: String in WEAPON_DATA:
		if WEAPON_DATA[w].get("range", 0) == 0:
			count += 1
	return count

static func get_highest_damage_weapon() -> String:
	var best: String = ""
	var best_d: float = 0.0
	for w: String in WEAPON_DATA:
		var d: float = WEAPON_DATA[w].get("damage", 0.0)
		if d > best_d:
			best_d = d
			best = w
	return best

static func get_ranged_weapon_count() -> int:
	var count: int = 0
	for w: String in WEAPON_DATA:
		if WEAPON_DATA[w].get("range", 0) > 0:
			count += 1
	return count

static func get_avg_weapon_range() -> float:
	var total: float = 0.0
	var cnt: int = 0
	for w: String in WEAPON_DATA:
		var r: int = WEAPON_DATA[w].get("range", 0)
		if r > 0:
			total += float(r)
			cnt += 1
	if cnt == 0:
		return 0.0
	return snappedf(total / float(cnt), 0.01)

static func get_damage_type_variety() -> int:
	var types: Dictionary = {}
	for w: String in WEAPON_DATA:
		var t: String = WEAPON_DATA[w].get("type", "")
		if not t.is_empty():
			types[t] = true
	return types.size()

static func get_lethality_index() -> float:
	var max_dmg := 0.0
	for w in WEAPON_DATA.values():
		var d: float = w.get("damage", 0.0)
		if d > max_dmg:
			max_dmg = d
	var avg := get_avg_weapon_damage()
	return snappedf((avg + max_dmg) / 2.0, 0.01)

static func get_engagement_range_pct() -> float:
	var ranged := get_ranged_weapon_count()
	return snappedf(float(ranged) / maxf(WEAPON_DATA.size(), 1.0) * 100.0, 0.1)

static func get_kill_efficiency() -> float:
	return snappedf(float(total_kills) / maxf(float(total_hits), 1.0) * 100.0, 0.1)

static func get_combat_stats() -> Dictionary:
	return {
		"total_attacks": total_attacks,
		"total_hits": total_hits,
		"total_kills": total_kills,
		"total_crits": total_crits,
		"hit_rate": snappedf(float(total_hits) / maxf(1.0, float(total_attacks)), 0.01),
		"avg_weapon_damage": get_avg_weapon_damage(),
		"melee_weapons": get_melee_weapon_count(),
		"strongest_weapon": get_highest_damage_weapon(),
		"ranged_weapons": get_ranged_weapon_count(),
		"avg_weapon_range": get_avg_weapon_range(),
		"damage_type_variety": get_damage_type_variety(),
		"lethality_index": get_lethality_index(),
		"engagement_range_pct": get_engagement_range_pct(),
		"kill_efficiency": get_kill_efficiency(),
	}
