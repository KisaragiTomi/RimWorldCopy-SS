extends Node

var _reactor_state: Dictionary = {}

const SHIP_PARTS: Dictionary = {
	"ShipReactor": {"work": 8000, "steel": 350, "plasteel": 70, "uranium": 70, "component_spacer": 6},
	"ShipEngine": {"work": 5000, "steel": 200, "plasteel": 50, "component_spacer": 4},
	"ShipCryptosleep": {"work": 3000, "steel": 100, "plasteel": 30, "component_spacer": 2},
	"ShipComputer": {"work": 4000, "steel": 150, "plasteel": 40, "component_spacer": 3, "ai_core": 1},
	"ShipSensor": {"work": 2000, "steel": 100, "plasteel": 20, "component_spacer": 2},
	"ShipBeam": {"work": 1000, "steel": 80, "component_industrial": 4}
}

const STARTUP_DURATION_DAYS: int = 15
const RAID_INTERVAL_HOURS: int = 24

func build_part(part_type: String) -> bool:
	if not SHIP_PARTS.has(part_type):
		return false
	if not _reactor_state.has("parts_built"):
		_reactor_state["parts_built"] = []
	_reactor_state["parts_built"].append(part_type)
	return true

func start_reactor() -> Dictionary:
	if not _reactor_state.get("parts_built", []).has("ShipReactor"):
		return {"error": "no_reactor"}
	_reactor_state["startup_active"] = true
	_reactor_state["days_remaining"] = STARTUP_DURATION_DAYS
	_reactor_state["raids_survived"] = 0
	return {"started": true, "days": STARTUP_DURATION_DAYS}

func advance_day() -> Dictionary:
	if not _reactor_state.get("startup_active", false):
		return {}
	_reactor_state["days_remaining"] -= 1
	var raid_today: bool = _reactor_state["days_remaining"] % 2 == 0
	if raid_today:
		_reactor_state["raids_survived"] += 1
	var complete: bool = _reactor_state["days_remaining"] <= 0
	return {
		"days_remaining": _reactor_state["days_remaining"],
		"raid_today": raid_today,
		"launch_ready": complete
	}

func get_total_material_cost() -> Dictionary:
	var totals: Dictionary = {"steel": 0, "plasteel": 0, "uranium": 0, "work": 0}
	for part: String in SHIP_PARTS:
		var p: Dictionary = SHIP_PARTS[part]
		totals["steel"] += int(p.get("steel", 0))
		totals["plasteel"] += int(p.get("plasteel", 0))
		totals["uranium"] += int(p.get("uranium", 0))
		totals["work"] += int(p.get("work", 0))
	return totals


func get_missing_parts() -> Array[String]:
	var built: Array = _reactor_state.get("parts_built", [])
	var result: Array[String] = []
	for part: String in SHIP_PARTS:
		if part not in built:
			result.append(part)
	return result


func is_launch_ready() -> bool:
	return _reactor_state.get("startup_active", false) and int(_reactor_state.get("days_remaining", 99)) <= 0


func get_build_progress() -> float:
	var built: int = _reactor_state.get("parts_built", []).size()
	if SHIP_PARTS.is_empty():
		return 0.0
	return float(built) / SHIP_PARTS.size()


func get_total_work_remaining() -> int:
	var total: int = 0
	var built: Array = _reactor_state.get("parts_built", [])
	for part: String in SHIP_PARTS:
		if part not in built:
			total += int(SHIP_PARTS[part].get("work", 0))
	return total


func get_days_remaining() -> int:
	return int(_reactor_state.get("days_remaining", 0))


func get_raids_survived() -> int:
	return int(_reactor_state.get("raids_survived", 0))


func get_most_expensive_part() -> String:
	var best: String = ""
	var best_cost: int = 0
	for part: String in SHIP_PARTS:
		var cost: int = int(SHIP_PARTS[part].get("work", 0))
		if cost > best_cost:
			best_cost = cost
			best = part
	return best


func get_total_plasteel_cost() -> int:
	var total: int = 0
	for part: String in SHIP_PARTS:
		total += int(SHIP_PARTS[part].get("plasteel", 0))
	return total


func get_project_status() -> String:
	var progress: float = get_build_progress()
	if progress >= 1.0:
		return "Complete"
	elif progress >= 0.7:
		return "Final-Phase"
	elif progress >= 0.3:
		return "Under-Construction"
	elif progress > 0.0:
		return "Early-Stage"
	return "Not-Started"

func get_endurance_rating() -> String:
	var raids: int = get_raids_survived()
	if raids >= 10:
		return "Battle-Hardened"
	elif raids >= 5:
		return "Resilient"
	elif raids >= 2:
		return "Tested"
	return "Untested"

func get_resource_commitment_pct() -> float:
	var total_cost: int = get_total_plasteel_cost()
	if total_cost == 0:
		return 0.0
	var built: int = _reactor_state.get("parts_built", []).size()
	return snappedf(float(built) / float(SHIP_PARTS.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"ship_parts": SHIP_PARTS.size(),
		"parts_built": _reactor_state.get("parts_built", []).size(),
		"startup_active": _reactor_state.get("startup_active", false),
		"startup_duration": STARTUP_DURATION_DAYS,
		"missing_parts": get_missing_parts().size(),
		"launch_ready": is_launch_ready(),
		"build_progress": snapped(get_build_progress(), 0.01),
		"work_remaining": get_total_work_remaining(),
		"days_left": get_days_remaining(),
		"raids_survived": get_raids_survived(),
		"most_expensive_part": get_most_expensive_part(),
		"total_plasteel": get_total_plasteel_cost(),
		"project_status": get_project_status(),
		"endurance_rating": get_endurance_rating(),
		"resource_commitment_pct": get_resource_commitment_pct(),
		"launch_countdown_status": get_launch_countdown_status(),
		"construction_momentum": get_construction_momentum(),
		"escape_readiness": get_escape_readiness(),
		"launch_ecosystem_health": get_launch_ecosystem_health(),
		"project_governance": get_project_governance(),
		"escape_maturity_index": get_escape_maturity_index(),
	}

func get_launch_countdown_status() -> String:
	if is_launch_ready():
		return "Ready"
	var days := get_days_remaining()
	if days <= 5:
		return "Imminent"
	elif days <= 15:
		return "Approaching"
	return "Distant"

func get_construction_momentum() -> String:
	var progress := get_build_progress()
	if progress >= 80.0:
		return "Final Push"
	elif progress >= 40.0:
		return "Steady"
	elif progress > 0.0:
		return "Early Stage"
	return "Not Started"

func get_escape_readiness() -> float:
	var progress := get_build_progress()
	var endurance := get_endurance_rating()
	var bonus := 10.0 if endurance in ["Strong", "Excellent"] else 0.0
	return snapped(progress + bonus, 0.1)

func get_launch_ecosystem_health() -> float:
	var readiness := get_escape_readiness()
	var momentum := get_construction_momentum()
	var m_val: float = 90.0 if momentum == "Final Push" else (60.0 if momentum == "Steady" else 20.0)
	var commitment := get_resource_commitment_pct()
	return snapped((readiness + m_val + commitment) / 3.0, 0.1)

func get_project_governance() -> String:
	var ecosystem := get_launch_ecosystem_health()
	var status := get_project_status()
	var s_val: float = 90.0 if status == "Complete" else (60.0 if status in ["Final Assembly", "Advanced"] else 25.0)
	var combined := (ecosystem + s_val) / 2.0
	if combined >= 70.0:
		return "On Track"
	elif combined >= 40.0:
		return "In Progress"
	elif get_build_progress() > 0.0:
		return "Stalled"
	return "Not Started"

func get_escape_maturity_index() -> float:
	var countdown := get_launch_countdown_status()
	var c_val: float = 100.0 if countdown == "Ready" else (70.0 if countdown == "Imminent" else (40.0 if countdown == "Approaching" else 10.0))
	var endurance := get_endurance_rating()
	var e_val: float = 90.0 if endurance in ["Strong", "Excellent"] else (60.0 if endurance == "Tested" else 25.0)
	return snapped((c_val + e_val) / 2.0, 0.1)
