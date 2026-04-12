extends Node

var _log_entries: Array = []
var _max_entries: int = 500


func log_attack(attacker: String, defender: String, weapon: String, damage: float, hit: bool) -> void:
	var entry: Dictionary = {
		"tick": TickManager.current_tick if TickManager else 0,
		"type": "attack",
		"attacker": attacker,
		"defender": defender,
		"weapon": weapon,
		"damage": damage,
		"hit": hit,
	}
	_add_entry(entry)


func log_dodge(defender: String, attacker: String) -> void:
	_add_entry({
		"tick": TickManager.current_tick if TickManager else 0,
		"type": "dodge",
		"defender": defender,
		"attacker": attacker,
	})


func log_down(pawn: String, cause: String) -> void:
	_add_entry({
		"tick": TickManager.current_tick if TickManager else 0,
		"type": "downed",
		"pawn": pawn,
		"cause": cause,
	})


func log_kill(killer: String, victim: String, weapon: String) -> void:
	_add_entry({
		"tick": TickManager.current_tick if TickManager else 0,
		"type": "kill",
		"killer": killer,
		"victim": victim,
		"weapon": weapon,
	})


func _add_entry(entry: Dictionary) -> void:
	_log_entries.append(entry)
	if _log_entries.size() > _max_entries:
		_log_entries = _log_entries.slice(_log_entries.size() - _max_entries)


func get_recent(count: int = 10) -> Array:
	var start: int = maxi(0, _log_entries.size() - count)
	return _log_entries.slice(start)


func get_kill_count(killer_name: String) -> int:
	var count: int = 0
	for e: Dictionary in _log_entries:
		if String(e.get("type", "")) == "kill" and String(e.get("killer", "")) == killer_name:
			count += 1
	return count


func get_type_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for e: Dictionary in _log_entries:
		var t: String = String(e.get("type", ""))
		dist[t] = dist.get(t, 0) + 1
	return dist


func get_top_killers(count: int = 5) -> Array[Dictionary]:
	var kills: Dictionary = {}
	for e: Dictionary in _log_entries:
		if String(e.get("type", "")) == "kill":
			var k: String = String(e.get("killer", ""))
			kills[k] = kills.get(k, 0) + 1
	var sorted: Array[Dictionary] = []
	for k: String in kills:
		sorted.append({"name": k, "kills": kills[k]})
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.kills > b.kills)
	return sorted.slice(0, mini(count, sorted.size()))


func get_hit_rate() -> float:
	var hits: int = 0
	var total: int = 0
	for e: Dictionary in _log_entries:
		if String(e.get("type", "")) == "attack":
			total += 1
			if bool(e.get("hit", false)):
				hits += 1
	if total <= 0:
		return 0.0
	return snappedf(float(hits) / float(total) * 100.0, 0.1)


func get_total_kills() -> int:
	var count: int = 0
	for e: Dictionary in _log_entries:
		if String(e.get("type", "")) == "kill":
			count += 1
	return count


func get_top_killer() -> Dictionary:
	var top := get_top_killers(1)
	if top.is_empty():
		return {}
	return top[0]


func get_combat_intensity() -> float:
	if _log_entries.is_empty():
		return 0.0
	return snappedf(float(_log_entries.size()) / float(_max_entries) * 100.0, 0.1)


func get_total_damage_dealt() -> float:
	var total: float = 0.0
	for e: Dictionary in _log_entries:
		if String(e.get("type", "")) == "attack" and bool(e.get("hit", false)):
			total += float(e.get("damage", 0.0))
	return snappedf(total, 0.1)


func get_avg_damage_per_hit() -> float:
	var total: float = 0.0
	var hits: int = 0
	for e: Dictionary in _log_entries:
		if String(e.get("type", "")) == "attack" and bool(e.get("hit", false)):
			total += float(e.get("damage", 0.0))
			hits += 1
	if hits == 0:
		return 0.0
	return snappedf(total / float(hits), 0.1)


func get_unique_weapon_count() -> int:
	var weapons: Dictionary = {}
	for e: Dictionary in _log_entries:
		var w: String = String(e.get("weapon", ""))
		if not w.is_empty():
			weapons[w] = true
	return weapons.size()


func get_lethality_rating() -> String:
	var kills: int = get_total_kills()
	if kills >= 20:
		return "Devastating"
	elif kills >= 10:
		return "Deadly"
	elif kills >= 3:
		return "Moderate"
	elif kills > 0:
		return "Light"
	return "None"

func get_accuracy_tier() -> String:
	var rate: float = get_hit_rate()
	if rate >= 80.0:
		return "Marksman"
	elif rate >= 60.0:
		return "Skilled"
	elif rate >= 40.0:
		return "Average"
	return "Poor"

func get_combat_readiness() -> float:
	var intensity: float = get_combat_intensity()
	var hit_rate: float = get_hit_rate()
	return snappedf((hit_rate * 0.6 + (100.0 - intensity) * 0.4), 0.1)

func get_summary() -> Dictionary:
	return {
		"total_entries": _log_entries.size(),
		"max_entries": _max_entries,
		"by_type": get_type_distribution(),
		"hit_rate_pct": get_hit_rate(),
		"total_kills": get_total_kills(),
		"top_killer": get_top_killer(),
		"intensity_pct": get_combat_intensity(),
		"total_damage": get_total_damage_dealt(),
		"avg_damage_per_hit": get_avg_damage_per_hit(),
		"unique_weapons": get_unique_weapon_count(),
		"lethality_rating": get_lethality_rating(),
		"accuracy_tier": get_accuracy_tier(),
		"combat_readiness": get_combat_readiness(),
		"tactical_proficiency": get_tactical_proficiency(),
		"firepower_density": get_firepower_density(),
		"combat_experience_rating": get_combat_experience_rating(),
		"military_ecosystem_health": get_military_ecosystem_health(),
		"combat_doctrine_index": get_combat_doctrine_index(),
		"warfare_governance": get_warfare_governance(),
	}

func get_tactical_proficiency() -> String:
	var accuracy := get_accuracy_tier()
	var readiness := get_combat_readiness()
	if accuracy in ["Marksman"] and readiness >= 70.0:
		return "Elite"
	elif accuracy in ["Skilled", "Marksman"]:
		return "Proficient"
	elif accuracy in ["Average"]:
		return "Competent"
	return "Green"

func get_firepower_density() -> float:
	var weapons := get_unique_weapon_count()
	var kills := get_total_kills()
	if weapons <= 0:
		return 0.0
	return snapped(float(kills) / float(weapons), 0.1)

func get_combat_experience_rating() -> String:
	var total := _log_entries.size()
	if total >= 100:
		return "Veteran"
	elif total >= 30:
		return "Experienced"
	elif total > 0:
		return "Novice"
	return "Untested"

func get_military_ecosystem_health() -> float:
	var accuracy := get_hit_rate()
	var proficiency := get_tactical_proficiency()
	var p_val: float = 90.0 if proficiency == "Expert" else (60.0 if proficiency == "Competent" else 30.0)
	var experience := get_combat_experience_rating()
	var e_val: float = 90.0 if experience == "Veteran" else (60.0 if experience == "Experienced" else 30.0)
	return snapped((accuracy + p_val + e_val) / 3.0, 0.1)

func get_combat_doctrine_index() -> float:
	var density := get_firepower_density()
	var intensity := get_combat_intensity()
	var readiness := get_combat_readiness()
	var r_val: float = readiness
	return snapped((minf(density * 20.0, 100.0) + intensity + r_val) / 3.0, 0.1)

func get_warfare_governance() -> String:
	var health := get_military_ecosystem_health()
	var doctrine := get_combat_doctrine_index()
	if health >= 60.0 and doctrine >= 50.0:
		return "Professional"
	elif health >= 30.0 or doctrine >= 25.0:
		return "Militia"
	return "Untrained"
