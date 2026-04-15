extends Node

var _cooldowns: Dictionary = {}

const ABILITY_CATEGORIES: Dictionary = {
	"Psycast": {"base_cooldown_mult": 1.0, "neural_heat_factor": true},
	"Permit": {"base_cooldown_mult": 1.0, "neural_heat_factor": false},
	"Gene": {"base_cooldown_mult": 0.8, "neural_heat_factor": false},
	"Anomaly": {"base_cooldown_mult": 1.2, "neural_heat_factor": false},
	"Item": {"base_cooldown_mult": 1.0, "neural_heat_factor": false}
}

func start_cooldown(pawn_id: int, ability: String, base_seconds: float, category: String) -> Dictionary:
	var mult: float = ABILITY_CATEGORIES.get(category, {}).get("base_cooldown_mult", 1.0)
	var actual: float = base_seconds * mult
	var key: String = "%d_%s" % [pawn_id, ability]
	_cooldowns[key] = {"remaining": actual, "total": actual, "category": category}
	return {"ability": ability, "cooldown": actual}

func advance_time(delta_seconds: float) -> int:
	var expired: int = 0
	var to_remove: Array = []
	for key: String in _cooldowns:
		_cooldowns[key]["remaining"] -= delta_seconds
		if _cooldowns[key]["remaining"] <= 0:
			to_remove.append(key)
			expired += 1
	for key: String in to_remove:
		_cooldowns.erase(key)
	return expired

func is_on_cooldown(pawn_id: int, ability: String) -> bool:
	var key: String = "%d_%s" % [pawn_id, ability]
	return _cooldowns.has(key) and _cooldowns[key]["remaining"] > 0

func get_remaining(pawn_id: int, ability: String) -> float:
	var key: String = "%d_%s" % [pawn_id, ability]
	if _cooldowns.has(key):
		return maxf(0.0, _cooldowns[key]["remaining"])
	return 0.0

func get_longest_cooldown() -> Dictionary:
	var best_key: String = ""
	var best_rem: float = 0.0
	for key: String in _cooldowns:
		if _cooldowns[key]["remaining"] > best_rem:
			best_rem = _cooldowns[key]["remaining"]
			best_key = key
	if best_key == "":
		return {}
	return {"key": best_key, "remaining": best_rem, "category": _cooldowns[best_key]["category"]}

func get_category_count() -> Dictionary:
	var counts: Dictionary = {}
	for key: String in _cooldowns:
		var cat: String = _cooldowns[key]["category"]
		counts[cat] = counts.get(cat, 0) + 1
	return counts

func get_total_remaining_time() -> float:
	var total: float = 0.0
	for key: String in _cooldowns:
		total += maxf(0.0, _cooldowns[key]["remaining"])
	return total

func get_shortest_cooldown() -> String:
	var best: String = ""
	var best_time: float = 999999.0
	for key: String in _cooldowns:
		var r: float = float(_cooldowns[key].get("remaining", 999999.0))
		if r > 0 and r < best_time:
			best_time = r
			best = key
	return best


func get_neural_heat_categories() -> int:
	var count: int = 0
	for cat: String in ABILITY_CATEGORIES:
		if bool(ABILITY_CATEGORIES[cat].get("neural_heat_factor", false)):
			count += 1
	return count


func get_avg_remaining() -> float:
	if _cooldowns.is_empty():
		return 0.0
	var total: float = 0.0
	for key: String in _cooldowns:
		total += float(_cooldowns[key].get("remaining", 0.0))
	return total / _cooldowns.size()


func get_highest_mult_category() -> String:
	var best: String = ""
	var best_m: float = 0.0
	for cat: String in ABILITY_CATEGORIES:
		var m: float = float(ABILITY_CATEGORIES[cat].get("base_cooldown_mult", 0.0))
		if m > best_m:
			best_m = m
			best = cat
	return best


func get_unique_pawn_count() -> int:
	var pawns: Dictionary = {}
	for key: String in _cooldowns:
		var parts: PackedStringArray = key.split("_", true, 1)
		if parts.size() > 0:
			pawns[parts[0]] = true
	return pawns.size()


func get_avg_total_cooldown() -> float:
	if _cooldowns.is_empty():
		return 0.0
	var total: float = 0.0
	for key: String in _cooldowns:
		total += float(_cooldowns[key].get("total", 0.0))
	return total / _cooldowns.size()


func get_readiness_level() -> String:
	if _cooldowns.is_empty():
		return "fully_ready"
	var ready: int = 0
	var total: int = 0
	for key: String in _cooldowns:
		total += 1
		if _cooldowns[key]["remaining"] <= 0:
			ready += 1
	if total == 0:
		return "fully_ready"
	var ratio: float = ready * 1.0 / total
	if ratio >= 0.8:
		return "mostly_ready"
	if ratio >= 0.4:
		return "partial"
	return "recovering"

func get_heat_saturation_pct() -> float:
	var heat_count: int = 0
	for key: String in _cooldowns:
		var cat: String = _cooldowns[key]["category"]
		if ABILITY_CATEGORIES.has(cat) and ABILITY_CATEGORIES[cat].get("neural_heat_factor", false):
			heat_count += 1
	if _cooldowns.is_empty():
		return 0.0
	return snapped(heat_count * 100.0 / _cooldowns.size(), 0.1)

func get_cooldown_efficiency() -> String:
	if _cooldowns.is_empty():
		return "idle"
	var avg_pct: float = 0.0
	for key: String in _cooldowns:
		var total: float = _cooldowns[key]["total"]
		var rem: float = _cooldowns[key]["remaining"]
		if total > 0:
			avg_pct += rem / total
	avg_pct /= _cooldowns.size()
	if avg_pct <= 0.2:
		return "near_ready"
	if avg_pct <= 0.6:
		return "progressing"
	return "fresh"

func get_summary() -> Dictionary:
	var longest: Dictionary = get_longest_cooldown()
	return {
		"ability_categories": ABILITY_CATEGORIES.size(),
		"active_cooldowns": _cooldowns.size(),
		"longest_cooldown": longest.get("key", ""),
		"total_remaining": get_total_remaining_time(),
		"shortest_cooldown": get_shortest_cooldown(),
		"neural_heat_cats": get_neural_heat_categories(),
		"avg_remaining": snapped(get_avg_remaining(), 0.1),
		"highest_mult_cat": get_highest_mult_category(),
		"unique_pawns": get_unique_pawn_count(),
		"avg_total_cooldown": snapped(get_avg_total_cooldown(), 0.1),
		"readiness_level": get_readiness_level(),
		"heat_saturation_pct": get_heat_saturation_pct(),
		"cooldown_efficiency": get_cooldown_efficiency(),
		"combat_ability_uptime": get_combat_ability_uptime(),
		"psycast_tempo": get_psycast_tempo(),
		"ability_rotation_health": get_ability_rotation_health(),
		"cooldown_ecosystem_health": get_cooldown_ecosystem_health(),
		"psycaster_governance": get_psycaster_governance(),
		"ability_maturity_index": get_ability_maturity_index(),
	}

func get_combat_ability_uptime() -> float:
	var ready := 0
	for cd: Dictionary in _cooldowns.values():
		if cd.get("remaining", 0.0) <= 0.0:
			ready += 1
	var total := _cooldowns.size()
	if total <= 0:
		return 100.0
	return snapped(float(ready) / float(total) * 100.0, 0.1)

func get_psycast_tempo() -> String:
	var avg := get_avg_remaining()
	if avg <= 5.0:
		return "Rapid"
	elif avg <= 15.0:
		return "Moderate"
	return "Sluggish"

func get_ability_rotation_health() -> String:
	var efficiency := get_cooldown_efficiency()
	var saturation := get_heat_saturation_pct()
	if efficiency in ["Optimal", "High"] and saturation <= 50.0:
		return "Excellent"
	elif efficiency in ["Moderate", "Optimal"]:
		return "Good"
	return "Strained"

func get_cooldown_ecosystem_health() -> float:
	var readiness := get_readiness_level()
	var r_val: float = 90.0 if readiness == "fully_ready" else (70.0 if readiness == "mostly_ready" else (40.0 if readiness == "partial" else 20.0))
	var uptime := get_combat_ability_uptime()
	var rotation := get_ability_rotation_health()
	var rot_val: float = 90.0 if rotation == "Excellent" else (60.0 if rotation == "Good" else 30.0)
	return snapped((r_val + uptime + rot_val) / 3.0, 0.1)

func get_ability_maturity_index() -> float:
	var efficiency := get_cooldown_efficiency()
	var e_val: float = 90.0 if efficiency in ["Optimal", "High"] else (60.0 if efficiency in ["Moderate", "idle"] else 30.0)
	var tempo := get_psycast_tempo()
	var t_val: float = 90.0 if tempo == "Rapid" else (60.0 if tempo == "Moderate" else 30.0)
	var saturation := get_heat_saturation_pct()
	var s_val: float = maxf(100.0 - saturation, 0.0)
	return snapped((e_val + t_val + s_val) / 3.0, 0.1)

func get_psycaster_governance() -> String:
	var ecosystem := get_cooldown_ecosystem_health()
	var maturity := get_ability_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _cooldowns.size() > 0:
		return "Nascent"
	return "Dormant"
