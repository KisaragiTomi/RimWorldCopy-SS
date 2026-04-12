extends Node

var _installed: Dictionary = {}

const INSTALLABLE_BUILDINGS: Dictionary = {
	"Bed": {"work_install": 500, "work_uninstall": 300, "skill_required": 4},
	"HospitalBed": {"work_install": 800, "work_uninstall": 500, "skill_required": 6},
	"Turret": {"work_install": 1200, "work_uninstall": 800, "skill_required": 8},
	"Battery": {"work_install": 600, "work_uninstall": 400, "skill_required": 5},
	"SolarPanel": {"work_install": 1000, "work_uninstall": 600, "skill_required": 6},
	"Cooler": {"work_install": 900, "work_uninstall": 500, "skill_required": 7},
	"Heater": {"work_install": 700, "work_uninstall": 400, "skill_required": 5},
	"Workbench": {"work_install": 600, "work_uninstall": 350, "skill_required": 4},
	"CommsConsole": {"work_install": 1500, "work_uninstall": 1000, "skill_required": 10},
	"ShipChunk": {"work_install": 0, "work_uninstall": 2000, "skill_required": 8}
}

func install_building(building_id: int, building_type: String, pos: Vector2i) -> Dictionary:
	if not INSTALLABLE_BUILDINGS.has(building_type):
		return {"error": "not_installable"}
	_installed[building_id] = {"type": building_type, "pos": pos, "installed": true}
	return {"installed": true, "work": INSTALLABLE_BUILDINGS[building_type]["work_install"]}

func uninstall_building(building_id: int) -> Dictionary:
	if not _installed.has(building_id):
		return {"error": "not_found"}
	var info: Dictionary = _installed[building_id]
	var btype: String = info["type"]
	_installed[building_id]["installed"] = false
	return {"uninstalled": true, "type": btype, "work": INSTALLABLE_BUILDINGS[btype]["work_uninstall"]}

func is_installed(building_id: int) -> bool:
	return _installed.get(building_id, {}).get("installed", false)

func get_hardest_to_install() -> String:
	var best: String = ""
	var best_skill: int = 0
	for b: String in INSTALLABLE_BUILDINGS:
		var s: int = int(INSTALLABLE_BUILDINGS[b].get("skill_required", 0))
		if s > best_skill:
			best_skill = s
			best = b
	return best


func get_uninstalled_count() -> int:
	var count: int = 0
	for bid: int in _installed:
		if not bool(_installed[bid].get("installed", false)):
			count += 1
	return count


func get_type_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for bid: int in _installed:
		var t: String = String(_installed[bid].get("type", ""))
		dist[t] = int(dist.get(t, 0)) + 1
	return dist


func get_install_rate() -> float:
	if _installed.is_empty():
		return 0.0
	var active: int = 0
	for bid: int in _installed:
		if _installed[bid]["installed"]:
			active += 1
	return float(active) / _installed.size()


func get_building_type_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for bid: int in _installed:
		var t: String = String(_installed[bid].get("type", ""))
		dist[t] = dist.get(t, 0) + 1
	return dist


func get_easiest_to_install() -> String:
	var best: String = ""
	var best_work: float = 999999.0
	for btype: String in INSTALLABLE_BUILDINGS:
		var w: float = float(INSTALLABLE_BUILDINGS[btype].get("install_work", 999999.0))
		if w < best_work:
			best_work = w
			best = btype
	return best


func get_avg_install_work() -> float:
	if INSTALLABLE_BUILDINGS.is_empty():
		return 0.0
	var total: float = 0.0
	for b: String in INSTALLABLE_BUILDINGS:
		total += float(INSTALLABLE_BUILDINGS[b].get("work_install", 0))
	return snappedf(total / float(INSTALLABLE_BUILDINGS.size()), 0.1)


func get_high_skill_building_count() -> int:
	var count: int = 0
	for b: String in INSTALLABLE_BUILDINGS:
		if int(INSTALLABLE_BUILDINGS[b].get("skill_required", 0)) >= 8:
			count += 1
	return count


func get_total_uninstall_work() -> int:
	var total: int = 0
	for b: String in INSTALLABLE_BUILDINGS:
		total += int(INSTALLABLE_BUILDINGS[b].get("work_uninstall", 0))
	return total


func get_maintenance_grade() -> String:
	var rate: float = get_install_rate()
	if rate >= 90.0:
		return "Excellent"
	if rate >= 70.0:
		return "Good"
	if rate >= 50.0:
		return "Fair"
	return "Poor"


func get_skill_demand_pct() -> float:
	var high_skill: int = 0
	for b: String in INSTALLABLE_BUILDINGS:
		if int(INSTALLABLE_BUILDINGS[b].get("skill_required", 0)) >= 7:
			high_skill += 1
	return snappedf(float(high_skill) / maxf(float(INSTALLABLE_BUILDINGS.size()), 1.0) * 100.0, 0.1)


func get_work_efficiency() -> float:
	var total_install: int = 0
	var total_uninstall: int = 0
	for b: String in INSTALLABLE_BUILDINGS:
		total_install += int(INSTALLABLE_BUILDINGS[b].get("work_install", 0))
		total_uninstall += int(INSTALLABLE_BUILDINGS[b].get("work_uninstall", 0))
	if total_install == 0:
		return 0.0
	return snappedf(float(total_uninstall) / float(total_install) * 100.0, 0.1)


func get_summary() -> Dictionary:
	var active: int = 0
	for bid: int in _installed:
		if _installed[bid]["installed"]:
			active += 1
	return {
		"installable_types": INSTALLABLE_BUILDINGS.size(),
		"total_tracked": _installed.size(),
		"currently_installed": active,
		"uninstalled": get_uninstalled_count(),
		"hardest": get_hardest_to_install(),
		"install_rate": snapped(get_install_rate(), 0.01),
		"easiest": get_easiest_to_install(),
		"avg_install_work": get_avg_install_work(),
		"high_skill_buildings": get_high_skill_building_count(),
		"total_uninstall_work": get_total_uninstall_work(),
		"maintenance_grade": get_maintenance_grade(),
		"skill_demand_pct": get_skill_demand_pct(),
		"work_efficiency": get_work_efficiency(),
		"relocation_readiness": get_relocation_readiness(),
		"construction_flexibility": get_construction_flexibility(),
		"labor_investment_ratio": get_labor_investment_ratio(),
		"construction_ecosystem_health": get_construction_ecosystem_health(),
		"building_governance": get_building_governance(),
		"structural_maturity_index": get_structural_maturity_index(),
	}

func get_relocation_readiness() -> String:
	var installed := 0
	for bid: int in _installed:
		if _installed[bid]["installed"]:
			installed += 1
	var uninstalled := get_uninstalled_count()
	if uninstalled > installed:
		return "Highly Mobile"
	elif uninstalled > 0:
		return "Partially Ready"
	return "Rooted"

func get_construction_flexibility() -> float:
	var easy := 0
	for type: Dictionary in INSTALLABLE_BUILDINGS:
		if type.get("install_work", 999) <= 200:
			easy += 1
	var total := INSTALLABLE_BUILDINGS.size()
	if total <= 0:
		return 0.0
	return snapped(float(easy) / float(total) * 100.0, 0.1)

func get_labor_investment_ratio() -> String:
	var avg_work := get_avg_install_work()
	if avg_work >= 500.0:
		return "Heavy"
	elif avg_work >= 200.0:
		return "Moderate"
	return "Light"

func get_construction_ecosystem_health() -> float:
	var readiness := get_relocation_readiness()
	var r_val: float = 90.0 if readiness == "Ready" else (60.0 if readiness == "Partial" else 25.0)
	var flexibility := get_construction_flexibility()
	var grade := get_maintenance_grade()
	var g_val: float = 90.0 if grade == "Excellent" else (60.0 if grade == "Good" else 25.0)
	return snapped((r_val + flexibility + g_val) / 3.0, 0.1)

func get_building_governance() -> String:
	var ecosystem := get_construction_ecosystem_health()
	var labor := get_labor_investment_ratio()
	var l_val: float = 90.0 if labor == "Light" else (60.0 if labor == "Moderate" else 30.0)
	var combined := (ecosystem + l_val) / 2.0
	if combined >= 70.0:
		return "Efficient"
	elif combined >= 40.0:
		return "Adequate"
	elif _installed.size() > 0:
		return "Strained"
	return "None"

func get_structural_maturity_index() -> float:
	var efficiency := get_work_efficiency()
	var demand := get_skill_demand_pct()
	return snapped((efficiency + (100.0 - demand)) / 2.0, 0.1)
