extends Node

var _gestators: Dictionary = {}
var _next_id: int = 0

const GESTATABLE_MECHS: Dictionary = {
	"Militor": {"gestation_days": 3, "resources": {"steel": 50, "component": 2}, "combat_power": 40},
	"Lifter": {"gestation_days": 2, "resources": {"steel": 30, "component": 1}, "combat_power": 10},
	"Constructoid": {"gestation_days": 3, "resources": {"steel": 60, "component": 2}, "combat_power": 15},
	"Agrihand": {"gestation_days": 2, "resources": {"steel": 25, "component": 1}, "combat_power": 5},
	"Cleansweeper": {"gestation_days": 1, "resources": {"steel": 20, "component": 1}, "combat_power": 5},
	"Fabricor": {"gestation_days": 4, "resources": {"steel": 80, "component": 3}, "combat_power": 10},
	"Centurion": {"gestation_days": 6, "resources": {"steel": 150, "plasteel": 30, "component": 5}, "combat_power": 120},
	"Tesseron": {"gestation_days": 5, "resources": {"steel": 120, "plasteel": 20, "component": 4}, "combat_power": 80}
}

func start_gestation(mech_type: String) -> Dictionary:
	if not GESTATABLE_MECHS.has(mech_type):
		return {"error": "unknown_mech"}
	var gid: int = _next_id
	_next_id += 1
	var info: Dictionary = GESTATABLE_MECHS[mech_type]
	_gestators[gid] = {"type": mech_type, "days_remaining": info["gestation_days"], "complete": false}
	return {"gestator_id": gid, "type": mech_type, "days": info["gestation_days"]}

func advance_day() -> Array:
	var completed: Array = []
	for gid: int in _gestators:
		if _gestators[gid]["complete"]:
			continue
		_gestators[gid]["days_remaining"] -= 1
		if _gestators[gid]["days_remaining"] <= 0:
			_gestators[gid]["complete"] = true
			completed.append({"gestator_id": gid, "type": _gestators[gid]["type"]})
	return completed

func get_strongest_mech() -> String:
	var best: String = ""
	var best_cp: int = 0
	for m: String in GESTATABLE_MECHS:
		var cp: int = int(GESTATABLE_MECHS[m].get("combat_power", 0))
		if cp > best_cp:
			best_cp = cp
			best = m
	return best


func get_quickest_mech() -> String:
	var best: String = ""
	var best_days: int = 999
	for m: String in GESTATABLE_MECHS:
		var d: int = int(GESTATABLE_MECHS[m].get("gestation_days", 999))
		if d < best_days:
			best_days = d
			best = m
	return best


func get_completed_count() -> int:
	var count: int = 0
	for gid: int in _gestators:
		if bool(_gestators[gid].get("complete", false)):
			count += 1
	return count


func get_avg_gestation_days() -> float:
	if GESTATABLE_MECHS.is_empty():
		return 0.0
	var total: float = 0.0
	for m: String in GESTATABLE_MECHS:
		total += float(GESTATABLE_MECHS[m].get("gestation_days", 0))
	return total / GESTATABLE_MECHS.size()


func get_total_combat_power() -> float:
	var total: float = 0.0
	for m: String in GESTATABLE_MECHS:
		total += float(GESTATABLE_MECHS[m].get("combat_power", 0))
	return total


func get_most_expensive_mech() -> String:
	var best: String = ""
	var best_cost: int = 0
	for m: String in GESTATABLE_MECHS:
		var res: Dictionary = GESTATABLE_MECHS[m].get("resources", {})
		var cost: int = 0
		for r: String in res:
			cost += int(res[r])
		if cost > best_cost:
			best_cost = cost
			best = m
	return best


func get_slowest_mech() -> String:
	var worst: String = ""
	var worst_days: int = 0
	for m: String in GESTATABLE_MECHS:
		var d: int = int(GESTATABLE_MECHS[m].get("gestation_days", 0))
		if d > worst_days:
			worst_days = d
			worst = m
	return worst


func get_non_combat_mech_count() -> int:
	var count: int = 0
	for m: String in GESTATABLE_MECHS:
		if int(GESTATABLE_MECHS[m].get("combat_power", 0)) <= 15:
			count += 1
	return count


func get_avg_combat_power() -> float:
	if GESTATABLE_MECHS.is_empty():
		return 0.0
	return snappedf(get_total_combat_power() / float(GESTATABLE_MECHS.size()), 0.1)


func get_production_readiness() -> String:
	var completed: int = get_completed_count()
	var total: int = _gestators.size()
	if total == 0:
		return "Idle"
	var ratio: float = float(completed) / float(total)
	if ratio >= 0.8:
		return "Operational"
	if ratio >= 0.4:
		return "Ramping"
	return "Starting"


func get_combat_focus_pct() -> float:
	var combat: int = GESTATABLE_MECHS.size() - get_non_combat_mech_count()
	return snappedf(float(combat) / maxf(float(GESTATABLE_MECHS.size()), 1.0) * 100.0, 0.1)


func get_resource_intensity() -> String:
	var avg: float = get_avg_gestation_days()
	if avg >= 10.0:
		return "Heavy"
	if avg >= 5.0:
		return "Moderate"
	return "Light"


func get_summary() -> Dictionary:
	var active: int = 0
	for gid: int in _gestators:
		if not _gestators[gid]["complete"]:
			active += 1
	return {
		"mech_types": GESTATABLE_MECHS.size(),
		"active_gestations": active,
		"completed": get_completed_count(),
		"strongest": get_strongest_mech(),
		"quickest": get_quickest_mech(),
		"avg_gestation": snapped(get_avg_gestation_days(), 0.1),
		"total_combat": get_total_combat_power(),
		"most_expensive": get_most_expensive_mech(),
		"slowest": get_slowest_mech(),
		"non_combat": get_non_combat_mech_count(),
		"avg_combat": get_avg_combat_power(),
		"production_readiness": get_production_readiness(),
		"combat_focus_pct": get_combat_focus_pct(),
		"resource_intensity": get_resource_intensity(),
		"gestation_throughput": get_gestation_throughput(),
		"army_building_pace": get_army_building_pace(),
		"mech_fleet_quality": get_mech_fleet_quality(),
		"production_ecosystem_health": get_production_ecosystem_health(),
		"mechanoid_production_governance": get_mechanoid_production_governance(),
		"industrial_maturity_index": get_industrial_maturity_index(),
	}

func get_gestation_throughput() -> float:
	var completed := get_completed_count()
	var avg_days := get_avg_gestation_days()
	if avg_days <= 0.0:
		return 0.0
	return snapped(float(completed) / avg_days, 0.01)

func get_army_building_pace() -> String:
	var completed := get_completed_count()
	var active := 0
	for gid: int in _gestators:
		if not _gestators[gid]["complete"]:
			active += 1
	if completed >= 5 and active >= 2:
		return "Rapid"
	elif completed >= 2:
		return "Steady"
	return "Slow"

func get_mech_fleet_quality() -> String:
	var avg_combat := get_avg_combat_power()
	if avg_combat >= 200.0:
		return "Elite"
	elif avg_combat >= 100.0:
		return "Standard"
	return "Militia"

func get_production_ecosystem_health() -> float:
	var throughput := get_gestation_throughput()
	var fleet := get_mech_fleet_quality()
	var f_val: float = 90.0 if fleet == "Elite" else (60.0 if fleet == "Standard" else 25.0)
	var readiness := get_production_readiness()
	var r_val: float = 90.0 if readiness == "Active" else (60.0 if readiness in ["Ready", "Partial"] else 25.0)
	return snapped((minf(throughput * 20.0, 100.0) + f_val + r_val) / 3.0, 0.1)

func get_mechanoid_production_governance() -> String:
	var ecosystem := get_production_ecosystem_health()
	var pace := get_army_building_pace()
	var p_val: float = 90.0 if pace == "Rapid" else (60.0 if pace == "Steady" else 25.0)
	var combined := (ecosystem + p_val) / 2.0
	if combined >= 70.0:
		return "War Machine"
	elif combined >= 40.0:
		return "Operational"
	elif _gestators.size() > 0:
		return "Nascent"
	return "Dormant"

func get_industrial_maturity_index() -> float:
	var intensity := get_resource_intensity()
	var i_val: float = 30.0 if intensity == "Heavy" else (60.0 if intensity == "Moderate" else 90.0)
	var combat_focus := get_combat_focus_pct()
	return snapped((i_val + combat_focus) / 2.0, 0.1)
