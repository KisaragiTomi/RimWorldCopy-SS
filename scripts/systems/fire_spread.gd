extends Node

var _fires: Dictionary = {}

const MATERIAL_FLAMMABILITY: Dictionary = {
	"Wood": {"flammability": 1.0, "burn_rate": 0.06},
	"Steel": {"flammability": 0.0, "burn_rate": 0.0},
	"Stone": {"flammability": 0.0, "burn_rate": 0.0},
	"Cloth": {"flammability": 1.2, "burn_rate": 0.08},
	"Devilstrand": {"flammability": 0.4, "burn_rate": 0.02},
	"Synthread": {"flammability": 0.6, "burn_rate": 0.03},
	"Plasteel": {"flammability": 0.0, "burn_rate": 0.0},
	"Jade": {"flammability": 0.0, "burn_rate": 0.0},
	"Hay": {"flammability": 1.5, "burn_rate": 0.12},
	"Chemfuel": {"flammability": 2.0, "burn_rate": 0.2}
}

const SPREAD_FACTORS: Dictionary = {
	"wind_speed_mult": 1.5,
	"rain_suppress": 0.1,
	"spread_radius": 1.5,
	"base_spread_chance": 0.3,
	"firefighter_efficiency": 0.8
}

func start_fire(tile_id: String, material: String) -> Dictionary:
	if not MATERIAL_FLAMMABILITY.has(material) or MATERIAL_FLAMMABILITY[material]["flammability"] == 0.0:
		return {"error": "not_flammable"}
	_fires[tile_id] = {"material": material, "intensity": 0.5, "ticks": 0}
	return {"fire_started": tile_id, "material": material}

func advance_tick(tick_count: int, raining: bool) -> Dictionary:
	var spread_list: Array[String] = []
	var extinguished: Array[String] = []
	for tile_id: String in _fires.keys():
		var f: Dictionary = _fires[tile_id]
		f["ticks"] += tick_count
		var mat: Dictionary = MATERIAL_FLAMMABILITY[f["material"]]
		f["intensity"] += mat["burn_rate"] * tick_count
		if raining:
			f["intensity"] -= SPREAD_FACTORS["rain_suppress"] * tick_count
		if f["intensity"] <= 0:
			extinguished.append(tile_id)
		elif f["intensity"] > 1.0 and randf() < SPREAD_FACTORS["base_spread_chance"]:
			spread_list.append(tile_id)
	for t: String in extinguished:
		_fires.erase(t)
	return {"active_fires": _fires.size(), "spread_from": spread_list.size(), "extinguished": extinguished.size()}

func extinguish(tile_id: String, firefighter_skill: int) -> Dictionary:
	if not _fires.has(tile_id):
		return {"error": "no_fire"}
	var reduction: float = SPREAD_FACTORS["firefighter_efficiency"] * (firefighter_skill / 10.0)
	_fires[tile_id]["intensity"] -= reduction
	if _fires[tile_id]["intensity"] <= 0:
		_fires.erase(tile_id)
		return {"extinguished": true}
	return {"extinguished": false, "remaining_intensity": _fires[tile_id]["intensity"]}

func get_most_flammable() -> String:
	var best: String = ""
	var best_v: float = 0.0
	for m: String in MATERIAL_FLAMMABILITY:
		if MATERIAL_FLAMMABILITY[m]["flammability"] > best_v:
			best_v = MATERIAL_FLAMMABILITY[m]["flammability"]
			best = m
	return best

func get_fireproof_materials() -> Array[String]:
	var result: Array[String] = []
	for m: String in MATERIAL_FLAMMABILITY:
		if MATERIAL_FLAMMABILITY[m]["flammability"] == 0.0:
			result.append(m)
	return result

func get_hottest_fire() -> String:
	var best: String = ""
	var best_i: float = 0.0
	for tid: String in _fires:
		if _fires[tid]["intensity"] > best_i:
			best_i = _fires[tid]["intensity"]
			best = tid
	return best

func get_avg_flammability() -> float:
	if MATERIAL_FLAMMABILITY.is_empty():
		return 0.0
	var total: float = 0.0
	for m: String in MATERIAL_FLAMMABILITY:
		total += float(MATERIAL_FLAMMABILITY[m])
	return total / MATERIAL_FLAMMABILITY.size()

func get_total_fire_intensity() -> float:
	var total: float = 0.0
	for fid: int in _fires:
		total += float(_fires[fid].get("intensity", 0.0))
	return total

func get_burning_area_count() -> int:
	return _fires.size()

func get_flammable_material_count() -> int:
	var count: int = 0
	for m: String in MATERIAL_FLAMMABILITY:
		if float(MATERIAL_FLAMMABILITY[m].get("flammability", 0.0)) > 0.0:
			count += 1
	return count


func get_highest_burn_rate_material() -> String:
	var best: String = ""
	var best_r: float = 0.0
	for m: String in MATERIAL_FLAMMABILITY:
		var r: float = float(MATERIAL_FLAMMABILITY[m].get("burn_rate", 0.0))
		if r > best_r:
			best_r = r
			best = m
	return best


func get_avg_burn_rate() -> float:
	var count: int = 0
	var total: float = 0.0
	for m: String in MATERIAL_FLAMMABILITY:
		var r: float = float(MATERIAL_FLAMMABILITY[m].get("burn_rate", 0.0))
		if r > 0.0:
			total += r
			count += 1
	if count == 0:
		return 0.0
	return total / count


func get_fire_hazard_level() -> String:
	if _fires.is_empty():
		return "clear"
	var intensity: float = get_total_fire_intensity()
	if intensity >= 5.0:
		return "inferno"
	if intensity >= 2.0:
		return "dangerous"
	return "contained"

func get_material_safety_pct() -> float:
	var fireproof: int = get_fireproof_materials().size()
	if MATERIAL_FLAMMABILITY.is_empty():
		return 0.0
	return snapped(fireproof * 100.0 / MATERIAL_FLAMMABILITY.size(), 0.1)

func get_burn_risk_profile() -> String:
	var flammable: int = get_flammable_material_count()
	var total: int = MATERIAL_FLAMMABILITY.size()
	if total == 0:
		return "unknown"
	var ratio: float = flammable * 1.0 / total
	if ratio >= 0.7:
		return "high_risk"
	if ratio >= 0.4:
		return "moderate"
	return "fire_resistant"

func get_summary() -> Dictionary:
	return {
		"materials": MATERIAL_FLAMMABILITY.size(),
		"active_fires": _fires.size(),
		"most_flammable": get_most_flammable(),
		"fireproof_count": get_fireproof_materials().size(),
		"avg_flammability": snapped(get_avg_flammability(), 0.01),
		"total_intensity": snapped(get_total_fire_intensity(), 0.1),
		"flammable_count": get_flammable_material_count(),
		"fastest_burn": get_highest_burn_rate_material(),
		"avg_burn_rate": snapped(get_avg_burn_rate(), 0.001),
		"fire_hazard_level": get_fire_hazard_level(),
		"material_safety_pct": get_material_safety_pct(),
		"burn_risk_profile": get_burn_risk_profile(),
		"fire_containment_capacity": get_fire_containment_capacity(),
		"infrastructure_fire_risk": get_infrastructure_fire_risk(),
		"suppression_readiness": get_suppression_readiness(),
		"fire_ecosystem_health": get_fire_ecosystem_health(),
		"safety_governance": get_safety_governance(),
		"fire_prevention_maturity_index": get_fire_prevention_maturity_index(),
	}

func get_fire_containment_capacity() -> String:
	var fireproof := get_fireproof_materials().size()
	var total := MATERIAL_FLAMMABILITY.size()
	if total <= 0:
		return "None"
	var ratio := float(fireproof) / float(total)
	if ratio >= 0.4:
		return "Strong"
	elif ratio >= 0.2:
		return "Moderate"
	return "Weak"

func get_infrastructure_fire_risk() -> float:
	var flammable := get_flammable_material_count()
	var total := MATERIAL_FLAMMABILITY.size()
	if total <= 0:
		return 0.0
	return snapped(float(flammable) / float(total) * 100.0, 0.1)

func get_suppression_readiness() -> String:
	var hazard := get_fire_hazard_level()
	var safety := get_material_safety_pct()
	if hazard in ["Low", "Minimal"] and safety >= 60.0:
		return "Prepared"
	elif safety >= 30.0:
		return "Watchful"
	return "Vulnerable"

func get_fire_ecosystem_health() -> float:
	var containment := get_fire_containment_capacity()
	var c_val: float = 90.0 if containment == "Strong" else (60.0 if containment == "Moderate" else 30.0)
	var readiness := get_suppression_readiness()
	var r_val: float = 90.0 if readiness == "Prepared" else (60.0 if readiness == "Watchful" else 30.0)
	var risk := get_infrastructure_fire_risk()
	var ri_val: float = maxf(100.0 - risk, 0.0)
	return snapped((c_val + r_val + ri_val) / 3.0, 0.1)

func get_fire_prevention_maturity_index() -> float:
	var safety := get_material_safety_pct()
	var profile := get_burn_risk_profile()
	var p_val: float = 90.0 if profile in ["safe", "fireproof"] else (60.0 if profile in ["moderate", "low"] else 30.0)
	var hazard := get_fire_hazard_level()
	var h_val: float = 90.0 if hazard in ["clear", "minimal"] else (50.0 if hazard in ["low", "moderate"] else 20.0)
	return snapped((safety + p_val + h_val) / 3.0, 0.1)

func get_safety_governance() -> String:
	var ecosystem := get_fire_ecosystem_health()
	var maturity := get_fire_prevention_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif MATERIAL_FLAMMABILITY.size() > 0:
		return "Nascent"
	return "Dormant"
