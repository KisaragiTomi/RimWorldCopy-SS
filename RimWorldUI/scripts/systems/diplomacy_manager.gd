extends Node

## Diplomatic actions between player colony and factions.
## Registered as autoload "DiplomacyManager".

signal diplomacy_event(faction: String, action: String, result: String)

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = randi()


func send_gift(faction_name: String, value: float) -> Dictionary:
	var fm: FactionManager = _get_faction_manager()
	if fm == null:
		return {"error": "No faction manager"}
	if not fm.factions.has(faction_name):
		return {"error": "Unknown faction"}

	var goodwill_gain: int = roundi(value / 50.0)
	goodwill_gain = clampi(goodwill_gain, 1, 50)
	var new_gw: int = fm.change_goodwill(faction_name, goodwill_gain)

	if ColonyLog:
		ColonyLog.add_entry("Diplomacy", "Sent gift to " + faction_name + " (+" + str(goodwill_gain) + " goodwill).", "info")
	diplomacy_event.emit(faction_name, "gift", "+" + str(goodwill_gain))

	total_gifts += 1
	_record_event(faction_name, "gift", "+" + str(goodwill_gain))
	return {"goodwill_gained": goodwill_gain, "new_goodwill": new_gw}


func demand_tribute(faction_name: String) -> Dictionary:
	var fm: FactionManager = _get_faction_manager()
	if fm == null:
		return {"error": "No faction manager"}
	if not fm.factions.has(faction_name):
		return {"error": "Unknown faction"}

	var gw: int = fm.get_goodwill(faction_name)
	var success_chance: float = 0.3 + gw * 0.003
	success_chance = clampf(success_chance, 0.05, 0.80)

	var result: Dictionary
	if _rng.randf() < success_chance:
		var silver: int = _rng.randi_range(50, 300)
		fm.change_goodwill(faction_name, -15)
		result = {"success": true, "silver": silver, "goodwill_lost": 15}
		if ColonyLog:
			ColonyLog.add_entry("Diplomacy", faction_name + " paid tribute: " + str(silver) + " silver.", "info")
	else:
		fm.change_goodwill(faction_name, -30)
		result = {"success": false, "goodwill_lost": 30}
		if ColonyLog:
			ColonyLog.add_entry("Diplomacy", faction_name + " refused tribute demand! (-30 goodwill)", "warning")

	total_tributes += 1
	_record_event(faction_name, "tribute", "success" if result.get("success", false) else "refused")
	diplomacy_event.emit(faction_name, "tribute", "success" if result.get("success", false) else "refused")
	return result


func declare_war(faction_name: String) -> Dictionary:
	var fm: FactionManager = _get_faction_manager()
	if fm == null:
		return {"error": "No faction manager"}
	if not fm.factions.has(faction_name):
		return {"error": "Unknown faction"}

	fm.change_goodwill(faction_name, -200)

	if ColonyLog:
		ColonyLog.add_entry("Diplomacy", "Declared war on " + faction_name + "!", "danger")
	diplomacy_event.emit(faction_name, "war", "declared")

	total_wars += 1
	_record_event(faction_name, "war", "declared")
	return {"at_war": true, "faction": faction_name}


func offer_peace(faction_name: String) -> Dictionary:
	var fm: FactionManager = _get_faction_manager()
	if fm == null:
		return {"error": "No faction manager"}
	if not fm.factions.has(faction_name):
		return {"error": "Unknown faction"}

	var gw: int = fm.get_goodwill(faction_name)
	if gw > -50:
		fm.change_goodwill(faction_name, 30)
		if ColonyLog:
			ColonyLog.add_entry("Diplomacy", "Peace offer accepted by " + faction_name + ".", "info")
		diplomacy_event.emit(faction_name, "peace", "accepted")
		return {"accepted": true}
	else:
		fm.change_goodwill(faction_name, 5)
		if ColonyLog:
			ColonyLog.add_entry("Diplomacy", faction_name + " rejected peace offer.", "warning")
		diplomacy_event.emit(faction_name, "peace", "rejected")
		return {"accepted": false}


func _get_faction_manager() -> FactionManager:
	if WorldManager and WorldManager.faction_mgr:
		return WorldManager.faction_mgr
	return null


var total_gifts: int = 0
var total_tributes: int = 0
var total_wars: int = 0
var total_peace_offers: int = 0
var _event_history: Array[Dictionary] = []


func request_trade_caravan(faction_name: String) -> Dictionary:
	var fm: FactionManager = _get_faction_manager()
	if fm == null:
		return {"error": "No faction manager"}
	if not fm.factions.has(faction_name):
		return {"error": "Unknown faction"}
	var gw: int = fm.get_goodwill(faction_name)
	if gw < 0:
		return {"error": "Goodwill too low"}
	var cost: int = roundi(maxf(50.0, 200.0 - gw * 2.0))
	if ColonyLog:
		ColonyLog.add_entry("Diplomacy", "Requested trade caravan from %s (cost: %d silver)." % [faction_name, cost], "info")
	return {"sent": true, "cost": cost, "faction": faction_name}


func get_faction_stance(faction_name: String) -> String:
	var fm: FactionManager = _get_faction_manager()
	if fm == null:
		return "Unknown"
	var gw: int = fm.get_goodwill(faction_name)
	if gw >= 75:
		return "Allied"
	elif gw >= 25:
		return "Friendly"
	elif gw >= -25:
		return "Neutral"
	elif gw >= -75:
		return "Hostile"
	return "War"


func _record_event(faction: String, action: String, details: String) -> void:
	_event_history.append({
		"faction": faction,
		"action": action,
		"details": details,
		"tick": TickManager.current_tick if TickManager else 0,
	})
	if _event_history.size() > 50:
		_event_history.pop_front()


func get_event_history(count: int = 10) -> Array[Dictionary]:
	var start := maxi(0, _event_history.size() - count)
	var result: Array[Dictionary] = []
	for i: int in range(start, _event_history.size()):
		result.append(_event_history[i])
	return result


func get_hostile_faction_count() -> int:
	var fm: FactionManager = _get_faction_manager()
	if fm == null:
		return 0
	var cnt: int = 0
	for f: Dictionary in fm.factions:
		if f.get("standing", "") in ["Hostile", "War"]:
			cnt += 1
	return cnt


func get_allied_faction_count() -> int:
	var fm: FactionManager = _get_faction_manager()
	if fm == null:
		return 0
	var cnt: int = 0
	for f: Dictionary in fm.factions:
		if f.get("standing", "") in ["Allied", "Friendly"]:
			cnt += 1
	return cnt


func get_diplomatic_status() -> String:
	var hostile: int = get_hostile_faction_count()
	var allied: int = get_allied_faction_count()
	if hostile >= 3:
		return "Besieged"
	elif hostile > allied:
		return "Tense"
	elif allied > hostile:
		return "Stable"
	return "Neutral"


func get_neutral_faction_count() -> int:
	var fm: FactionManager = _get_faction_manager()
	if fm == null:
		return 0
	var cnt: int = 0
	for f: Dictionary in fm.factions:
		if f.get("standing", "") == "Neutral":
			cnt += 1
	return cnt


func get_gift_to_tribute_ratio() -> float:
	if total_tributes == 0:
		if total_gifts > 0:
			return 999.0
		return 0.0
	return float(total_gifts) / float(total_tributes)


func get_war_frequency() -> float:
	if _event_history.is_empty():
		return 0.0
	return float(total_wars) / float(_event_history.size())


func get_peace_ratio() -> float:
	var fm: FactionManager = _get_faction_manager()
	if fm == null or fm.factions.is_empty():
		return 0.0
	var peaceful: int = get_allied_faction_count() + get_neutral_faction_count()
	return snappedf(float(peaceful) / float(fm.factions.size()) * 100.0, 0.1)


func get_total_diplomatic_events() -> int:
	return _event_history.size()


func get_diplomatic_health() -> String:
	if get_hostile_faction_count() == 0:
		return "Peaceful"
	elif get_allied_faction_count() > get_hostile_faction_count():
		return "Favorable"
	elif get_allied_faction_count() == get_hostile_faction_count():
		return "Balanced"
	return "Tense"


func get_geopolitical_risk() -> String:
	var hostile := get_hostile_faction_count()
	var allied := get_allied_faction_count()
	if hostile > allied * 2:
		return "High"
	elif hostile > allied:
		return "Elevated"
	elif hostile > 0:
		return "Moderate"
	return "Low"

func get_soft_power_score() -> float:
	var allied := float(get_allied_faction_count())
	var neutral := float(get_neutral_faction_count())
	var gifts := float(total_gifts)
	var fm: FactionManager = _get_faction_manager()
	var total := float(fm.factions.size()) if fm else 1.0
	if total <= 0.0:
		return 0.0
	var influence := (allied * 3.0 + neutral * 1.0 + gifts * 0.5) / total
	return snapped(minf(influence * 10.0, 100.0), 0.1)

func get_alliance_network_depth() -> int:
	return get_allied_faction_count()

func get_summary() -> Dictionary:
	var fm: FactionManager = _get_faction_manager()
	if fm == null:
		return {"factions": 0}
	return {
		"factions": fm.factions.size(),
		"faction_list": fm.get_faction_summary(),
		"total_gifts": total_gifts,
		"total_tributes": total_tributes,
		"total_wars": total_wars,
		"recent_events": get_event_history(5),
		"hostile_count": get_hostile_faction_count(),
		"allied_count": get_allied_faction_count(),
		"diplomatic_status": get_diplomatic_status(),
		"neutral_count": get_neutral_faction_count(),
		"gift_tribute_ratio": snappedf(get_gift_to_tribute_ratio(), 0.01),
		"war_frequency": snappedf(get_war_frequency(), 0.01),
		"peace_ratio_pct": get_peace_ratio(),
		"total_events": get_total_diplomatic_events(),
		"diplomatic_health": get_diplomatic_health(),
		"geopolitical_risk": get_geopolitical_risk(),
		"soft_power_score": get_soft_power_score(),
		"alliance_depth": get_alliance_network_depth(),
		"diplomatic_maturity": get_diplomatic_maturity(),
		"international_reputation": get_international_reputation(),
		"diplomatic_leverage": get_diplomatic_leverage(),
	}

func get_diplomatic_maturity() -> String:
	var events: int = get_total_diplomatic_events()
	var allies: int = get_allied_faction_count()
	var wars: int = total_wars
	if events >= 20 and allies >= 3 and wars <= 2:
		return "Seasoned"
	if events >= 10 and allies >= 1:
		return "Developing"
	if events >= 3:
		return "Emerging"
	return "Isolated"

func get_international_reputation() -> String:
	var allies: int = get_allied_faction_count()
	var hostile: int = get_hostile_faction_count()
	var peace_pct: float = get_peace_ratio()
	if allies > hostile and peace_pct >= 70.0:
		return "Respected"
	if allies >= hostile:
		return "Neutral"
	if hostile > allies * 2:
		return "Feared"
	return "Distrusted"

func get_diplomatic_leverage() -> float:
	var allies: int = get_allied_faction_count()
	var gifts: int = total_gifts
	var soft: float = 0.0
	var sp: float = get_soft_power_score()
	if sp >= 7.0:
		soft = 80.0
	elif sp >= 4.0:
		soft = 50.0
	else:
		soft = 20.0
	var score: float = float(allies) * 15.0 + soft * 0.4 + float(gifts) * 2.0
	return snappedf(clampf(score, 0.0, 100.0), 0.1)
