extends Node

var _faction_goodwill: Dictionary = {}
var _last_interaction: Dictionary = {}

const DECAY_RATE_PER_DAY: float = 0.15
const NEUTRAL_POINT: float = 0.0
const MAX_GOODWILL: float = 100.0
const MIN_GOODWILL: float = -100.0

const DECAY_EXEMPTIONS: Dictionary = {
	"Allied": 75.0,
	"Neutral": 0.0,
	"Hostile": -75.0
}

const INTERACTION_COOLDOWN_DAYS: int = 5

func set_goodwill(faction_id: String, value: float) -> void:
	_faction_goodwill[faction_id] = clampf(value, MIN_GOODWILL, MAX_GOODWILL)

func get_goodwill(faction_id: String) -> float:
	return _faction_goodwill.get(faction_id, 0.0)

func advance_day() -> Dictionary:
	var changes: Dictionary = {}
	for fid: String in _faction_goodwill:
		var current: float = _faction_goodwill[fid]
		if absf(current - NEUTRAL_POINT) < DECAY_RATE_PER_DAY:
			continue
		var direction: float = -1.0 if current > NEUTRAL_POINT else 1.0
		var new_val: float = current + direction * DECAY_RATE_PER_DAY
		_faction_goodwill[fid] = clampf(new_val, MIN_GOODWILL, MAX_GOODWILL)
		changes[fid] = {"old": current, "new": _faction_goodwill[fid]}
	return changes

func get_relation_label(faction_id: String) -> String:
	var gw: float = get_goodwill(faction_id)
	if gw >= 75.0:
		return "Allied"
	elif gw >= 0.0:
		return "Neutral"
	elif gw >= -75.0:
		return "Hostile"
	else:
		return "Permanent Enemy"

func get_allied_factions() -> Array[String]:
	var result: Array[String] = []
	for fid: String in _faction_goodwill:
		if get_relation_label(fid) == "Allied":
			result.append(fid)
	return result


func get_hostile_factions() -> Array[String]:
	var result: Array[String] = []
	for fid: String in _faction_goodwill:
		var label: String = get_relation_label(fid)
		if label == "Hostile" or label == "Permanent Enemy":
			result.append(fid)
	return result


func get_average_goodwill() -> float:
	if _faction_goodwill.is_empty():
		return 0.0
	var total: float = 0.0
	for fid: String in _faction_goodwill:
		total += float(_faction_goodwill[fid])
	return total / float(_faction_goodwill.size())


func get_neutral_count() -> int:
	var count: int = 0
	for fid: String in _faction_goodwill:
		if get_relation_label(fid) == "Neutral":
			count += 1
	return count


func get_most_friendly_faction() -> String:
	var best: String = ""
	var best_gw: float = -999.0
	for fid: String in _faction_goodwill:
		if float(_faction_goodwill[fid]) > best_gw:
			best_gw = float(_faction_goodwill[fid])
			best = fid
	return best


func get_most_hostile_faction() -> String:
	var worst: String = ""
	var worst_gw: float = 999.0
	for fid: String in _faction_goodwill:
		if float(_faction_goodwill[fid]) < worst_gw:
			worst_gw = float(_faction_goodwill[fid])
			worst = fid
	return worst


func get_goodwill_spread() -> float:
	if _faction_goodwill.is_empty():
		return 0.0
	var lo: float = 999.0
	var hi: float = -999.0
	for fid: String in _faction_goodwill:
		var v: float = float(_faction_goodwill[fid])
		if v < lo:
			lo = v
		if v > hi:
			hi = v
	return hi - lo


func get_permanent_enemy_count() -> int:
	var count: int = 0
	for fid: String in _faction_goodwill:
		if get_relation_label(fid) == "Permanent Enemy":
			count += 1
	return count


func get_near_ally_count() -> int:
	var count: int = 0
	for fid: String in _faction_goodwill:
		var gw: float = float(_faction_goodwill[fid])
		if gw >= 60.0 and gw < 75.0:
			count += 1
	return count


func get_geopolitical_climate() -> String:
	var allied: int = get_allied_factions().size()
	var hostile: int = get_hostile_factions().size()
	if allied > hostile * 2:
		return "Peaceful"
	elif allied > hostile:
		return "Favorable"
	elif hostile > allied:
		return "Tense"
	return "Balanced"

func get_isolation_risk_pct() -> float:
	if _faction_goodwill.is_empty():
		return 100.0
	var enemies: int = get_hostile_factions().size() + get_permanent_enemy_count()
	return snappedf(float(enemies) / float(_faction_goodwill.size()) * 100.0, 0.1)

func get_alliance_momentum() -> String:
	var near: int = get_near_ally_count()
	if near >= 3:
		return "Strong"
	elif near >= 2:
		return "Growing"
	elif near >= 1:
		return "Emerging"
	return "Stagnant"

func get_summary() -> Dictionary:
	return {
		"tracked_factions": _faction_goodwill.size(),
		"decay_rate": DECAY_RATE_PER_DAY,
		"goodwill_range": [MIN_GOODWILL, MAX_GOODWILL],
		"allied": get_allied_factions().size(),
		"hostile": get_hostile_factions().size(),
		"avg_goodwill": get_average_goodwill(),
		"neutral": get_neutral_count(),
		"most_friendly": get_most_friendly_faction(),
		"most_hostile": get_most_hostile_faction(),
		"goodwill_spread": get_goodwill_spread(),
		"permanent_enemies": get_permanent_enemy_count(),
		"near_ally": get_near_ally_count(),
		"geopolitical_climate": get_geopolitical_climate(),
		"isolation_risk_pct": get_isolation_risk_pct(),
		"alliance_momentum": get_alliance_momentum(),
		"diplomatic_entropy": get_diplomatic_entropy(),
		"faction_loyalty_depth": get_faction_loyalty_depth(),
		"conflict_escalation_risk": get_conflict_escalation_risk(),
		"geopolitical_ecosystem_health": get_geopolitical_ecosystem_health(),
		"diplomatic_governance": get_diplomatic_governance(),
		"international_stability_index": get_international_stability_index(),
	}

func get_diplomatic_entropy() -> float:
	var spread := get_goodwill_spread()
	var factions := _faction_goodwill.size()
	if factions <= 0:
		return 0.0
	return snapped(float(spread) / float(factions), 0.1)

func get_faction_loyalty_depth() -> String:
	var allies := get_allied_factions().size()
	var total := _faction_goodwill.size()
	if total <= 0:
		return "None"
	var ratio := float(allies) / float(total)
	if ratio >= 0.5:
		return "Deep"
	elif ratio >= 0.2:
		return "Moderate"
	return "Shallow"

func get_conflict_escalation_risk() -> String:
	var hostile := get_hostile_factions().size()
	var enemies := get_permanent_enemy_count()
	if hostile >= 3 or enemies >= 2:
		return "Critical"
	elif hostile >= 1:
		return "Elevated"
	return "Low"

func get_geopolitical_ecosystem_health() -> float:
	var climate := get_geopolitical_climate()
	var c_val: float = 90.0 if climate == "Friendly" else (60.0 if climate == "Neutral" else 25.0)
	var loyalty := get_faction_loyalty_depth()
	var l_val: float = 90.0 if loyalty == "Deep" else (60.0 if loyalty == "Moderate" else 25.0)
	var isolation := get_isolation_risk_pct()
	return snapped((c_val + l_val + (100.0 - isolation)) / 3.0, 0.1)

func get_diplomatic_governance() -> String:
	var ecosystem := get_geopolitical_ecosystem_health()
	var momentum := get_alliance_momentum()
	var m_val: float = 90.0 if momentum == "Strong" else (60.0 if momentum == "Growing" else 25.0)
	var combined := (ecosystem + m_val) / 2.0
	if combined >= 70.0:
		return "Statesman"
	elif combined >= 40.0:
		return "Engaged"
	elif _faction_goodwill.size() > 0:
		return "Isolated"
	return "Unknown"

func get_international_stability_index() -> float:
	var entropy := get_diplomatic_entropy()
	var escalation := get_conflict_escalation_risk()
	var e_val: float = 90.0 if escalation == "Low" else (50.0 if escalation == "Elevated" else 10.0)
	return snapped(((100.0 - minf(entropy, 100.0)) + e_val) / 2.0, 0.1)
