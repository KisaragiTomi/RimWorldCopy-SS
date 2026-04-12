extends Node

var _encounter_log: Array = []

const ENCOUNTERS: Dictionary = {
	"Ambush": {"chance": 0.15, "threat": "high", "combat": true, "enemy_count_range": [3, 8]},
	"TraderMet": {"chance": 0.10, "threat": "none", "combat": false, "trade_available": true},
	"Breakdown": {"chance": 0.08, "threat": "low", "combat": false, "delay_hours": 6},
	"AnimalAttack": {"chance": 0.12, "threat": "medium", "combat": true, "animal_types": ["Wolf", "Bear", "Cougar"]},
	"BanditDemand": {"chance": 0.10, "threat": "medium", "combat": false, "demand_percent": 0.3},
	"RefugeeMet": {"chance": 0.06, "threat": "none", "combat": false, "recruit_chance": 0.3},
	"RuinsFound": {"chance": 0.05, "threat": "low", "combat": false, "loot_chance": 0.6},
	"WeatherDelay": {"chance": 0.08, "threat": "low", "combat": false, "delay_hours": 12},
	"FriendlyPatrol": {"chance": 0.04, "threat": "none", "combat": false, "goodwill_gain": 5},
	"MechanoidEncounter": {"chance": 0.03, "threat": "extreme", "combat": true, "enemy_count_range": [2, 5]}
}

func roll_encounter(caravan_id: int, biome: String) -> Dictionary:
	var roll: float = randf()
	var cumulative: float = 0.0
	for enc_name: String in ENCOUNTERS:
		var enc: Dictionary = ENCOUNTERS[enc_name]
		cumulative += enc["chance"]
		if roll <= cumulative:
			var result: Dictionary = {"encounter": enc_name, "caravan_id": caravan_id, "biome": biome}
			result.merge(enc)
			_encounter_log.append(result)
			return result
	return {"encounter": "Nothing", "caravan_id": caravan_id}

func get_combat_encounters() -> Array:
	var result: Array = []
	for entry: Dictionary in _encounter_log:
		if bool(entry.get("combat", false)):
			result.append(entry)
	return result


func get_most_common_encounter() -> String:
	var counts: Dictionary = {}
	for entry: Dictionary in _encounter_log:
		var e: String = String(entry.get("encounter", ""))
		counts[e] = int(counts.get(e, 0)) + 1
	var best: String = ""
	var best_c: int = 0
	for e: String in counts:
		if int(counts[e]) > best_c:
			best_c = int(counts[e])
			best = e
	return best


func get_extreme_threat_count() -> int:
	var count: int = 0
	for entry: Dictionary in _encounter_log:
		if String(entry.get("threat", "")) == "extreme":
			count += 1
	return count


func get_peaceful_encounter_count() -> int:
	var count: int = 0
	for entry: Dictionary in _encounter_log:
		if not bool(entry.get("combat", false)):
			count += 1
	return count


func get_combat_rate() -> float:
	if _encounter_log.is_empty():
		return 0.0
	return float(get_combat_encounters().size()) / _encounter_log.size()


func get_unique_encounter_types_seen() -> int:
	var types: Dictionary = {}
	for entry: Dictionary in _encounter_log:
		types[String(entry.get("encounter", ""))] = true
	return types.size()


func get_high_threat_count() -> int:
	var count: int = 0
	for entry: Dictionary in _encounter_log:
		var t: String = String(entry.get("threat", ""))
		if t == "high" or t == "extreme":
			count += 1
	return count


func get_loot_encounter_count() -> int:
	var count: int = 0
	for entry: Dictionary in _encounter_log:
		if bool(entry.get("loot_chance", false)) or bool(entry.get("trade_available", false)):
			count += 1
	return count


func get_never_seen_count() -> int:
	return ENCOUNTERS.size() - get_unique_encounter_types_seen()


func get_travel_safety() -> String:
	var rate: float = get_combat_rate()
	if rate >= 0.5:
		return "Perilous"
	elif rate >= 0.3:
		return "Risky"
	elif rate >= 0.1:
		return "Cautious"
	return "Safe"

func get_encounter_variety() -> String:
	var seen: int = get_unique_encounter_types_seen()
	if ENCOUNTERS.is_empty():
		return "N/A"
	var pct: float = float(seen) / float(ENCOUNTERS.size())
	if pct >= 0.8:
		return "Diverse"
	elif pct >= 0.5:
		return "Moderate"
	elif pct >= 0.2:
		return "Limited"
	return "Minimal"

func get_reward_frequency_pct() -> float:
	if _encounter_log.is_empty():
		return 0.0
	return snappedf(float(get_loot_encounter_count()) / float(_encounter_log.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"encounter_types": ENCOUNTERS.size(),
		"total_encounters": _encounter_log.size(),
		"combat_count": get_combat_encounters().size(),
		"most_common": get_most_common_encounter(),
		"peaceful_count": get_peaceful_encounter_count(),
		"combat_rate": snapped(get_combat_rate(), 0.01),
		"types_seen": get_unique_encounter_types_seen(),
		"high_threat": get_high_threat_count(),
		"loot_encounters": get_loot_encounter_count(),
		"never_seen": get_never_seen_count(),
		"travel_safety": get_travel_safety(),
		"encounter_variety": get_encounter_variety(),
		"reward_frequency_pct": get_reward_frequency_pct(),
		"route_danger_rating": get_route_danger_rating(),
		"encounter_preparedness": get_encounter_preparedness(),
		"trade_route_viability": get_trade_route_viability(),
		"encounter_ecosystem_health": get_encounter_ecosystem_health(),
		"travel_governance": get_travel_governance(),
		"expedition_readiness_index": get_expedition_readiness_index(),
	}

func get_route_danger_rating() -> String:
	var combat_rate := get_combat_rate()
	if combat_rate >= 0.5:
		return "Deadly"
	elif combat_rate >= 0.25:
		return "Risky"
	elif combat_rate > 0.0:
		return "Mild"
	return "Safe"

func get_encounter_preparedness() -> float:
	var total := _encounter_log.size()
	var combat := get_combat_encounters().size()
	if total <= 0:
		return 100.0
	return snapped(float(total - combat) / float(total) * 100.0, 0.1)

func get_trade_route_viability() -> String:
	var loot := get_loot_encounter_count()
	var high_threat := get_high_threat_count()
	if loot > high_threat * 2:
		return "Profitable"
	elif loot >= high_threat:
		return "Viable"
	return "Hazardous"

func get_encounter_ecosystem_health() -> float:
	var safety := get_travel_safety()
	var s_val: float = 90.0 if safety == "Safe" else (60.0 if safety == "Moderate" else 20.0)
	var preparedness := get_encounter_preparedness()
	var variety := get_encounter_variety()
	var v_val: float = 90.0 if variety == "Diverse" else (60.0 if variety == "Moderate" else 30.0)
	return snapped((s_val + preparedness + v_val) / 3.0, 0.1)

func get_travel_governance() -> String:
	var ecosystem := get_encounter_ecosystem_health()
	var viability := get_trade_route_viability()
	var vi_val: float = 90.0 if viability == "Profitable" else (60.0 if viability == "Viable" else 20.0)
	var combined := (ecosystem + vi_val) / 2.0
	if combined >= 70.0:
		return "Secure"
	elif combined >= 40.0:
		return "Managed"
	elif _encounter_log.size() > 0:
		return "Risky"
	return "Unknown"

func get_expedition_readiness_index() -> float:
	var danger := get_route_danger_rating()
	var d_val: float = 90.0 if danger == "Safe" else (60.0 if danger == "Mild" else 20.0)
	var reward := get_reward_frequency_pct()
	return snapped((d_val + reward) / 2.0, 0.1)
