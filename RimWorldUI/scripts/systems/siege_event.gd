extends Node

var _active_sieges: Array = []

const SIEGE_PHASES: Dictionary = {
	"Setup": {"duration": 120, "description": "Building fortifications"},
	"Bombard": {"duration": 300, "description": "Mortar bombardment"},
	"Assault": {"duration": 0, "description": "Final ground assault"},
	"Retreat": {"duration": 60, "description": "Retreating"}
}

const SIEGE_BUILDINGS: Array = [
	{"type": "Sandbag", "hp": 100, "cover": 0.65},
	{"type": "Mortar", "hp": 200, "damage": 50, "range": 40},
	{"type": "Barricade", "hp": 150, "cover": 0.75},
	{"type": "AmmoDump", "hp": 80, "shells": 20}
]

func start_siege(faction: String, raider_count: int, pos: Vector2i) -> Dictionary:
	var siege: Dictionary = {
		"id": _active_sieges.size(),
		"faction": faction,
		"raiders": raider_count,
		"position": pos,
		"phase": "Setup",
		"phase_tick": 0,
		"buildings_placed": [],
		"shells_remaining": 20
	}
	_active_sieges.append(siege)
	return siege

func advance_phase(siege_id: int) -> String:
	if siege_id < 0 or siege_id >= _active_sieges.size():
		return ""
	var siege: Dictionary = _active_sieges[siege_id]
	var phases: Array = ["Setup", "Bombard", "Assault", "Retreat"]
	var idx: int = phases.find(siege["phase"])
	if idx < phases.size() - 1:
		siege["phase"] = phases[idx + 1]
		siege["phase_tick"] = 0
	return siege["phase"]

func fire_mortar(siege_id: int, target: Vector2i) -> Dictionary:
	if siege_id < 0 or siege_id >= _active_sieges.size():
		return {}
	var siege: Dictionary = _active_sieges[siege_id]
	if siege["shells_remaining"] <= 0:
		return {"hit": false, "reason": "no_ammo"}
	siege["shells_remaining"] -= 1
	var accuracy: float = 0.4
	var hit: bool = randf() < accuracy
	return {"hit": hit, "target": target, "damage": 50 if hit else 0}

func get_active_sieges() -> int:
	return _active_sieges.size()

func get_siege_phase(siege_id: int) -> String:
	if siege_id < 0 or siege_id >= _active_sieges.size():
		return ""
	return String(_active_sieges[siege_id].get("phase", ""))


func get_total_raiders() -> int:
	var total: int = 0
	for siege: Dictionary in _active_sieges:
		total += int(siege.get("raiders", 0))
	return total


func get_ammo_status() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i: int in range(_active_sieges.size()):
		result.append({"id": i, "shells": _active_sieges[i].get("shells_remaining", 0)})
	return result


func get_avg_raiders_per_siege() -> float:
	if _active_sieges.is_empty():
		return 0.0
	return float(get_total_raiders()) / _active_sieges.size()


func get_total_shells_remaining() -> int:
	var total: int = 0
	for siege: Dictionary in _active_sieges:
		total += int(siege.get("shells_remaining", 0))
	return total


func is_any_in_assault() -> bool:
	for siege: Dictionary in _active_sieges:
		if String(siege.get("phase", "")) == "Assault":
			return true
	return false


func get_phase_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for siege: Dictionary in _active_sieges:
		var p: String = String(siege.get("phase", ""))
		dist[p] = dist.get(p, 0) + 1
	return dist


func get_max_cover_building() -> String:
	var best: String = ""
	var best_cover: float = 0.0
	for b in SIEGE_BUILDINGS:
		var bd: Dictionary = b if b is Dictionary else {}
		var c: float = float(bd.get("cover", 0.0))
		if c > best_cover:
			best_cover = c
			best = String(bd.get("type", ""))
	return best


func get_avg_shells_per_siege() -> float:
	if _active_sieges.is_empty():
		return 0.0
	return snappedf(float(get_total_shells_remaining()) / float(_active_sieges.size()), 0.1)


func get_siege_threat_level() -> String:
	var raiders: int = get_total_raiders()
	if raiders >= 30:
		return "Overwhelming"
	elif raiders >= 15:
		return "Severe"
	elif raiders >= 5:
		return "Moderate"
	elif raiders > 0:
		return "Minor"
	return "None"

func get_artillery_pressure() -> String:
	var shells: int = get_total_shells_remaining()
	if shells >= 50:
		return "Heavy Bombardment"
	elif shells >= 20:
		return "Active Shelling"
	elif shells > 0:
		return "Light Fire"
	return "Silent"

func get_escalation_risk() -> String:
	if not is_any_in_assault():
		if _active_sieges.is_empty():
			return "None"
		return "Building Up"
	return "Assault Active"

func get_summary() -> Dictionary:
	return {
		"active_sieges": _active_sieges.size(),
		"phase_count": SIEGE_PHASES.size(),
		"building_types": SIEGE_BUILDINGS.size(),
		"total_raiders": get_total_raiders(),
		"avg_raiders": snapped(get_avg_raiders_per_siege(), 0.1),
		"total_shells": get_total_shells_remaining(),
		"any_assaulting": is_any_in_assault(),
		"phase_dist": get_phase_distribution(),
		"best_cover_building": get_max_cover_building(),
		"avg_shells_per_siege": get_avg_shells_per_siege(),
		"siege_threat_level": get_siege_threat_level(),
		"artillery_pressure": get_artillery_pressure(),
		"escalation_risk": get_escalation_risk(),
		"fortification_stress": get_fortification_stress(),
		"defense_sustainability": get_defense_sustainability(),
		"siege_endurance": get_siege_endurance(),
		"siege_ecosystem_health": get_siege_ecosystem_health(),
		"siege_governance": get_siege_governance(),
		"defense_maturity_index": get_defense_maturity_index(),
	}

func get_fortification_stress() -> String:
	var threat := get_siege_threat_level()
	var pressure := get_artillery_pressure()
	if threat in ["Critical", "Severe"] and pressure in ["Heavy", "Intense"]:
		return "Breaking"
	elif threat in ["Moderate", "Severe"]:
		return "Stressed"
	return "Holding"

func get_defense_sustainability() -> float:
	var shells := get_total_shells_remaining()
	var raiders := get_total_raiders()
	if raiders <= 0:
		return 100.0
	return snapped(maxf(100.0 - float(shells) / float(raiders) * 10.0, 0.0), 0.1)

func get_siege_endurance() -> String:
	var active := _active_sieges.size()
	if active == 0:
		return "No Siege"
	elif active <= 1:
		return "Manageable"
	return "Overwhelmed"

func get_siege_ecosystem_health() -> float:
	var stress := get_fortification_stress()
	var st_val: float = 90.0 if stress == "Holding" else (50.0 if stress == "Stressed" else 20.0)
	var sustainability := get_defense_sustainability()
	var endurance := get_siege_endurance()
	var e_val: float = 90.0 if endurance in ["No Siege", "Manageable"] else 30.0
	return snapped((st_val + sustainability + e_val) / 3.0, 0.1)

func get_defense_maturity_index() -> float:
	var threat := get_siege_threat_level()
	var t_val: float = 20.0 if threat in ["Critical", "Extreme"] else (60.0 if threat in ["Moderate", "Severe"] else 90.0)
	var escalation := get_escalation_risk()
	var esc_val: float = 90.0 if escalation == "None" else (50.0 if escalation == "Building Up" else 20.0)
	var pressure := get_artillery_pressure()
	var p_val: float = 90.0 if pressure in ["None", "Light"] else (50.0 if pressure == "Active Shelling" else 20.0)
	return snapped((t_val + esc_val + p_val) / 3.0, 0.1)

func get_siege_governance() -> String:
	var ecosystem := get_siege_ecosystem_health()
	var maturity := get_defense_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _active_sieges.size() > 0:
		return "Nascent"
	return "Dormant"
