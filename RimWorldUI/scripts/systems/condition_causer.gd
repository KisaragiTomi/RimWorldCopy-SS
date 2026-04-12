extends Node

var _active_causers: Dictionary = {}

const CONDITION_CAUSERS: Dictionary = {
	"PsychicSoothe": {"radius": 20, "effect": "mood_bonus", "value": 5, "power": 200},
	"PsychicDrone": {"radius": 999, "effect": "mood_penalty", "value": -12, "power": 0},
	"SunLamp": {"radius": 6, "effect": "light_100", "value": 1.0, "power": 2900},
	"OrbitalBeam": {"radius": 8, "effect": "burn_damage", "value": 50, "power": 0},
	"ToxicSpewer": {"radius": 999, "effect": "toxic_buildup", "value": 0.02, "power": 0},
	"WeatherController": {"radius": 999, "effect": "clear_weather", "value": 1, "power": 500},
	"EMICasher": {"radius": 15, "effect": "disable_mech", "value": 1, "power": 1000},
	"ShieldGenerator": {"radius": 10, "effect": "block_projectile", "value": 1, "power": 300},
	"SmokeGenerator": {"radius": 5, "effect": "miss_chance", "value": 0.5, "power": 75},
	"ColdBox": {"radius": 3, "effect": "temp_offset", "value": -20, "power": 150}
}

func place_causer(causer_id: int, causer_type: String, pos: Vector2i) -> Dictionary:
	if not CONDITION_CAUSERS.has(causer_type):
		return {"error": "unknown_type"}
	_active_causers[causer_id] = {"type": causer_type, "pos": pos, "active": true}
	return {"placed": true, "type": causer_type, "radius": CONDITION_CAUSERS[causer_type]["radius"]}

func toggle_causer(causer_id: int, active: bool) -> bool:
	if _active_causers.has(causer_id):
		_active_causers[causer_id]["active"] = active
		return true
	return false

func get_effects_at(pos: Vector2i) -> Array:
	var effects: Array = []
	for cid: int in _active_causers:
		if not _active_causers[cid]["active"]:
			continue
		var ctype: String = _active_causers[cid]["type"]
		var cpos: Vector2i = _active_causers[cid]["pos"]
		var dist: float = Vector2(pos - cpos).length()
		if dist <= CONDITION_CAUSERS[ctype]["radius"]:
			effects.append({"type": ctype, "effect": CONDITION_CAUSERS[ctype]["effect"], "value": CONDITION_CAUSERS[ctype]["value"]})
	return effects

func get_total_power_draw() -> int:
	var total: int = 0
	for cid: int in _active_causers:
		if bool(_active_causers[cid].get("active", false)):
			var ctype: String = String(_active_causers[cid].get("type", ""))
			total += int(CONDITION_CAUSERS.get(ctype, {}).get("power", 0))
	return total


func get_harmful_causers() -> Array[String]:
	var result: Array[String] = []
	for c: String in CONDITION_CAUSERS:
		var eff: String = String(CONDITION_CAUSERS[c].get("effect", ""))
		if eff.contains("penalty") or eff.contains("damage") or eff.contains("toxic"):
			result.append(c)
	return result


func get_causers_by_type(causer_type: String) -> Array:
	var result: Array = []
	for cid: int in _active_causers:
		if String(_active_causers[cid].get("type", "")) == causer_type:
			result.append(cid)
	return result


func get_inactive_count() -> int:
	var count: int = 0
	for cid: int in _active_causers:
		if not bool(_active_causers[cid].get("active", false)):
			count += 1
	return count


func get_avg_power_per_causer() -> float:
	var active_count: int = 0
	var total_power: float = 0.0
	for cid: int in _active_causers:
		if bool(_active_causers[cid].get("active", false)):
			active_count += 1
			total_power += float(_active_causers[cid].get("power", 0.0))
	if active_count == 0:
		return 0.0
	return total_power / active_count


func get_highest_power_type() -> String:
	var best: String = ""
	var best_power: float = 0.0
	for ct: String in CONDITION_CAUSERS:
		var p: float = float(CONDITION_CAUSERS[ct].get("power_draw", 0.0))
		if p > best_power:
			best_power = p
			best = ct
	return best


func get_zero_power_count() -> int:
	var count: int = 0
	for c: String in CONDITION_CAUSERS:
		if int(CONDITION_CAUSERS[c].get("power", 0)) == 0:
			count += 1
	return count


func get_global_effect_count() -> int:
	var count: int = 0
	for c: String in CONDITION_CAUSERS:
		if int(CONDITION_CAUSERS[c].get("radius", 0)) >= 999:
			count += 1
	return count


func get_avg_radius() -> float:
	if CONDITION_CAUSERS.is_empty():
		return 0.0
	var total: float = 0.0
	var n: int = 0
	for c: String in CONDITION_CAUSERS:
		var r: int = int(CONDITION_CAUSERS[c].get("radius", 0))
		if r < 999:
			total += float(r)
			n += 1
	if n == 0:
		return 0.0
	return snappedf(total / float(n), 0.1)


func get_threat_density() -> String:
	var harmful: int = get_harmful_causers().size()
	var total: int = CONDITION_CAUSERS.size()
	if total == 0:
		return "Safe"
	var ratio: float = float(harmful) / float(total)
	if ratio >= 0.5:
		return "Dangerous"
	if ratio >= 0.25:
		return "Moderate"
	return "Safe"


func get_power_efficiency_pct() -> float:
	var zero: int = get_zero_power_count()
	return snappedf(float(zero) / maxf(float(CONDITION_CAUSERS.size()), 1.0) * 100.0, 0.1)


func get_coverage_rating() -> String:
	var global: int = get_global_effect_count()
	var total: int = CONDITION_CAUSERS.size()
	if total == 0:
		return "None"
	var ratio: float = float(global) / float(total)
	if ratio >= 0.5:
		return "Wide"
	if ratio >= 0.2:
		return "Moderate"
	return "Localized"


func get_summary() -> Dictionary:
	var active: int = 0
	for cid: int in _active_causers:
		if _active_causers[cid]["active"]:
			active += 1
	return {
		"causer_types": CONDITION_CAUSERS.size(),
		"active_causers": active,
		"total_power": get_total_power_draw(),
		"inactive": get_inactive_count(),
		"avg_power": snapped(get_avg_power_per_causer(), 0.1),
		"highest_power_type": get_highest_power_type(),
		"zero_power": get_zero_power_count(),
		"global_effects": get_global_effect_count(),
		"avg_local_radius": get_avg_radius(),
		"threat_density": get_threat_density(),
		"power_efficiency_pct": get_power_efficiency_pct(),
		"coverage_rating": get_coverage_rating(),
		"environmental_control": get_environmental_control(),
		"hazard_management_score": get_hazard_management_score(),
		"operational_stability": get_operational_stability(),
		"causer_ecosystem_health": get_causer_ecosystem_health(),
		"condition_governance": get_condition_governance(),
		"environmental_maturity_index": get_environmental_maturity_index(),
	}

func get_environmental_control() -> String:
	var global := get_global_effect_count()
	var coverage := get_coverage_rating()
	if global >= 3 and coverage in ["Full", "Extensive"]:
		return "Dominant"
	elif global >= 1:
		return "Partial"
	return "Minimal"

func get_hazard_management_score() -> float:
	var active := 0
	for cid: int in _active_causers:
		if _active_causers[cid]["active"]:
			active += 1
	var inactive := get_inactive_count()
	var total := active + inactive
	if total <= 0:
		return 0.0
	return snapped(float(active) / float(total) * 100.0, 0.1)

func get_operational_stability() -> String:
	var zero := get_zero_power_count()
	var total := CONDITION_CAUSERS.size()
	if total <= 0:
		return "N/A"
	if float(zero) / float(total) >= 0.5:
		return "Self-Sustaining"
	elif float(zero) / float(total) >= 0.2:
		return "Grid-Dependent"
	return "Power-Hungry"

func get_causer_ecosystem_health() -> float:
	var control := get_environmental_control()
	var c_val: float = 90.0 if control == "Total" else (60.0 if control in ["Partial", "Adequate"] else 25.0)
	var hazard := get_hazard_management_score()
	var stability := get_operational_stability()
	var s_val: float = 90.0 if stability == "Self-Sustaining" else (60.0 if stability == "Grid-Dependent" else 25.0)
	return snapped((c_val + hazard + s_val) / 3.0, 0.1)

func get_condition_governance() -> String:
	var ecosystem := get_causer_ecosystem_health()
	var coverage := get_coverage_rating()
	var cv_val: float = 90.0 if coverage == "Full" else (60.0 if coverage in ["Partial", "Adequate"] else 25.0)
	var combined := (ecosystem + cv_val) / 2.0
	if combined >= 70.0:
		return "Controlled"
	elif combined >= 40.0:
		return "Managed"
	elif _active_causers.size() > 0:
		return "Chaotic"
	return "Dormant"

func get_environmental_maturity_index() -> float:
	var efficiency := get_power_efficiency_pct()
	var threat := get_threat_density()
	var t_val: float = 90.0 if threat == "Low" else (60.0 if threat == "Moderate" else 25.0)
	return snapped((efficiency + t_val) / 2.0, 0.1)
