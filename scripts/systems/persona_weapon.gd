extends Node

var _bonds: Dictionary = {}

const PERSONA_TRAITS: Dictionary = {
	"Bloodlust": {"kill_mood": 8, "no_kill_mood": -3, "desc": "Wants to kill"},
	"Psychic": {"psychic_bonus": 0.15, "desc": "Enhances psychic abilities"},
	"Kind": {"social_bonus": 0.1, "desc": "Makes wielder more likeable"},
	"Jealous": {"bond_mood": 10, "unbond_mood": -20, "desc": "Hates being put away"},
	"Painless": {"pain_factor": 0.5, "desc": "Numbs pain for wielder"},
	"Tough": {"armor_bonus": 0.1, "desc": "Toughens the wielder"},
	"Nimble": {"dodge_bonus": 0.12, "desc": "Grants agility"},
	"Masterwork": {"damage_mult": 1.2, "desc": "Exceptional craftsmanship"}
}

const WEAPON_TYPES: Dictionary = {
	"PersonaMonosword": {"base_damage": 25, "cooldown": 1.8, "range": 1},
	"PersonaZeushammer": {"base_damage": 22, "cooldown": 2.0, "range": 1, "stun_chance": 0.3},
	"PersonaPlasmasword": {"base_damage": 20, "cooldown": 1.6, "range": 1, "burn_damage": 8}
}

func bond_weapon(pawn_id: int, weapon_type: String, trait_name: String) -> Dictionary:
	if not WEAPON_TYPES.has(weapon_type) or not PERSONA_TRAITS.has(trait_name):
		return {"error": "invalid"}
	_bonds[pawn_id] = {
		"weapon": weapon_type,
		"persona_trait": trait_name,
		"kills": 0,
		"bonded_day": 0
	}
	return {"bonded": true, "weapon": weapon_type, "persona_trait": trait_name}

func record_kill(pawn_id: int) -> int:
	if _bonds.has(pawn_id):
		_bonds[pawn_id]["kills"] += 1
		return _bonds[pawn_id]["kills"]
	return 0

func get_mood_from_bond(pawn_id: int) -> float:
	if not _bonds.has(pawn_id):
		return 0.0
	var info: Dictionary = PERSONA_TRAITS.get(_bonds[pawn_id]["persona_trait"], {})
	return info.get("bond_mood", 5.0)

func get_top_killer() -> Dictionary:
	var best_id: int = -1
	var best_kills: int = 0
	for pid: int in _bonds:
		var k: int = int(_bonds[pid].get("kills", 0))
		if k > best_kills:
			best_kills = k
			best_id = pid
	if best_id < 0:
		return {}
	return {"pawn_id": best_id, "kills": best_kills, "weapon": _bonds[best_id].get("weapon", "")}


func get_total_kills() -> int:
	var total: int = 0
	for pid: int in _bonds:
		total += int(_bonds[pid].get("kills", 0))
	return total


func get_trait_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pid: int in _bonds:
		var t: String = String(_bonds[pid].get("persona_trait", ""))
		dist[t] = int(dist.get(t, 0)) + 1
	return dist


func get_avg_kills_per_bond() -> float:
	if _bonds.is_empty():
		return 0.0
	return float(get_total_kills()) / _bonds.size()


func get_most_common_trait() -> String:
	var dist: Dictionary = get_trait_distribution()
	var best: String = ""
	var best_count: int = 0
	for t: String in dist:
		if int(dist[t]) > best_count:
			best_count = int(dist[t])
			best = t
	return best


func get_most_common_weapon() -> String:
	var counts: Dictionary = {}
	for pid: int in _bonds:
		var w: String = String(_bonds[pid].get("weapon", ""))
		counts[w] = counts.get(w, 0) + 1
	var best: String = ""
	var best_count: int = 0
	for w: String in counts:
		if int(counts[w]) > best_count:
			best_count = int(counts[w])
			best = w
	return best


func get_highest_damage_weapon() -> String:
	var best: String = ""
	var best_d: int = 0
	for w: String in WEAPON_TYPES:
		var d: int = int(WEAPON_TYPES[w].get("base_damage", 0))
		if d > best_d:
			best_d = d
			best = w
	return best


func get_unbonded_weapon_types() -> int:
	var bonded_types: Dictionary = {}
	for pid: int in _bonds:
		bonded_types[String(_bonds[pid].get("weapon", ""))] = true
	return WEAPON_TYPES.size() - bonded_types.size()


func get_combat_trait_count() -> int:
	var count: int = 0
	for t: String in PERSONA_TRAITS:
		var info: Dictionary = PERSONA_TRAITS[t]
		if info.has("damage_mult") or info.has("armor_bonus") or info.has("dodge_bonus") or info.has("kill_mood"):
			count += 1
	return count


func get_bond_strength() -> String:
	var avg: float = get_avg_kills_per_bond()
	if avg >= 20.0:
		return "Legendary"
	elif avg >= 10.0:
		return "Veteran"
	elif avg >= 3.0:
		return "Developing"
	return "Fresh"

func get_arsenal_saturation_pct() -> float:
	if WEAPON_TYPES.is_empty():
		return 0.0
	var bonded: int = WEAPON_TYPES.size() - get_unbonded_weapon_types()
	return snappedf(float(bonded) / float(WEAPON_TYPES.size()) * 100.0, 0.1)

func get_combat_orientation() -> String:
	var combat: int = get_combat_trait_count()
	if PERSONA_TRAITS.is_empty():
		return "N/A"
	var pct: float = float(combat) / float(PERSONA_TRAITS.size())
	if pct >= 0.6:
		return "Aggressive"
	elif pct >= 0.3:
		return "Balanced"
	return "Passive"

func get_summary() -> Dictionary:
	return {
		"persona_traits": PERSONA_TRAITS.size(),
		"weapon_types": WEAPON_TYPES.size(),
		"active_bonds": _bonds.size(),
		"total_kills": get_total_kills(),
		"avg_kills": snapped(get_avg_kills_per_bond(), 0.1),
		"common_trait": get_most_common_trait(),
		"common_weapon": get_most_common_weapon(),
		"highest_damage": get_highest_damage_weapon(),
		"unbonded_types": get_unbonded_weapon_types(),
		"combat_traits": get_combat_trait_count(),
		"bond_strength": get_bond_strength(),
		"arsenal_saturation_pct": get_arsenal_saturation_pct(),
		"combat_orientation": get_combat_orientation(),
		"weapon_mastery_depth": get_weapon_mastery_depth(),
		"persona_synergy": get_persona_synergy(),
		"legendary_potential": get_legendary_potential(),
		"weapon_ecosystem_health": get_weapon_ecosystem_health(),
		"arsenal_governance": get_arsenal_governance(),
		"combat_artistry_index": get_combat_artistry_index(),
	}

func get_weapon_mastery_depth() -> String:
	var avg_kills := get_avg_kills_per_bond()
	if avg_kills >= 50.0:
		return "Legendary"
	elif avg_kills >= 20.0:
		return "Veteran"
	elif avg_kills > 0.0:
		return "Novice"
	return "Unblooded"

func get_persona_synergy() -> float:
	var combat := get_combat_trait_count()
	var total := PERSONA_TRAITS.size()
	if total <= 0:
		return 0.0
	return snapped(float(combat) / float(total) * 100.0, 0.1)

func get_legendary_potential() -> String:
	var bonds := _bonds.size()
	var saturation := get_arsenal_saturation_pct()
	if bonds >= 3 and saturation >= 50.0:
		return "Mythic"
	elif bonds >= 1:
		return "Promising"
	return "Dormant"

func get_weapon_ecosystem_health() -> float:
	var mastery := get_weapon_mastery_depth()
	var m_val: float = 90.0 if mastery in ["Legendary", "Master"] else (60.0 if mastery == "Seasoned" else 25.0)
	var synergy := get_persona_synergy()
	var orientation := get_combat_orientation()
	var o_val: float = 90.0 if orientation == "Aggressive" else (60.0 if orientation == "Balanced" else 30.0)
	return snapped((m_val + synergy + o_val) / 3.0, 0.1)

func get_arsenal_governance() -> String:
	var ecosystem := get_weapon_ecosystem_health()
	var legendary := get_legendary_potential()
	var l_val: float = 90.0 if legendary == "Mythic" else (60.0 if legendary == "Promising" else 20.0)
	var combined := (ecosystem + l_val) / 2.0
	if combined >= 70.0:
		return "Legendary Arsenal"
	elif combined >= 40.0:
		return "Growing Arsenal"
	elif _bonds.size() > 0:
		return "Nascent"
	return "Empty"

func get_combat_artistry_index() -> float:
	var bond := get_bond_strength()
	var b_val: float = 90.0 if bond == "Legendary" else (70.0 if bond == "Strong" else (40.0 if bond == "Moderate" else 15.0))
	var saturation := get_arsenal_saturation_pct()
	return snapped((b_val + saturation) / 2.0, 0.1)
