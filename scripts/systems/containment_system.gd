extends Node

var _containment_cells: Dictionary = {}

const CONTAINMENT_TYPES: Dictionary = {
	"HoldingPlatform": {"base_strength": 50, "power": 200, "size": 1},
	"BioferriteHarness": {"base_strength": 80, "power": 350, "size": 1, "produces": "Bioferrite"},
	"ElectroshockLance": {"base_strength": 30, "power": 100, "size": 0, "addon": true},
	"ContainmentBarrier": {"base_strength": 100, "power": 500, "size": 4}
}

const STABILITY_FACTORS: Dictionary = {
	"power_on": 1.0,
	"power_off": -0.5,
	"study_recent": 0.1,
	"entity_threat_mult": -0.1,
	"bioferrite_reinforced": 0.3
}

func create_cell(cell_id: int, cell_type: String) -> Dictionary:
	if not CONTAINMENT_TYPES.has(cell_type):
		return {"error": "unknown_type"}
	_containment_cells[cell_id] = {"type": cell_type, "entity_id": -1, "stability": 1.0, "powered": true}
	return {"created": true, "type": cell_type, "strength": CONTAINMENT_TYPES[cell_type]["base_strength"]}

func contain_entity(cell_id: int, entity_id: int) -> Dictionary:
	if not _containment_cells.has(cell_id):
		return {"error": "no_cell"}
	_containment_cells[cell_id]["entity_id"] = entity_id
	return {"contained": true, "cell_id": cell_id, "entity_id": entity_id}

func advance_day() -> Dictionary:
	var breaches: Array = []
	for cid: int in _containment_cells:
		if _containment_cells[cid]["entity_id"] < 0:
			continue
		if not _containment_cells[cid]["powered"]:
			_containment_cells[cid]["stability"] -= 0.1
		if _containment_cells[cid]["stability"] <= 0:
			breaches.append(cid)
	return {"checked_cells": _containment_cells.size(), "breaches": breaches}

func get_low_stability_cells() -> Array:
	var result: Array = []
	for cid: int in _containment_cells:
		if float(_containment_cells[cid].get("stability", 1.0)) < 0.3:
			result.append(cid)
	return result


func get_unpowered_cells() -> Array:
	var result: Array = []
	for cid: int in _containment_cells:
		if not bool(_containment_cells[cid].get("powered", true)):
			result.append(cid)
	return result


func get_strongest_containment() -> String:
	var best: String = ""
	var best_s: int = 0
	for c: String in CONTAINMENT_TYPES:
		var s: int = int(CONTAINMENT_TYPES[c].get("base_strength", 0))
		if s > best_s:
			best_s = s
			best = c
	return best


func get_avg_stability() -> float:
	if _containment_cells.is_empty():
		return 1.0
	var total: float = 0.0
	for cid: int in _containment_cells:
		total += float(_containment_cells[cid].get("stability", 1.0))
	return total / _containment_cells.size()


func get_unpowered_count() -> int:
	var count: int = 0
	for cid: int in _containment_cells:
		if not bool(_containment_cells[cid].get("powered", true)):
			count += 1
	return count


func get_empty_cells() -> int:
	var count: int = 0
	for cid: int in _containment_cells:
		if int(_containment_cells[cid].get("entity_id", -1)) < 0:
			count += 1
	return count


func get_total_power_draw() -> int:
	var total: int = 0
	for c: String in CONTAINMENT_TYPES:
		total += int(CONTAINMENT_TYPES[c].get("power", 0))
	return total


func get_addon_count() -> int:
	var count: int = 0
	for c: String in CONTAINMENT_TYPES:
		if bool(CONTAINMENT_TYPES[c].get("addon", false)):
			count += 1
	return count


func get_occupied_pct() -> float:
	if _containment_cells.is_empty():
		return 0.0
	var occ: int = 0
	for cid: int in _containment_cells:
		if int(_containment_cells[cid].get("entity_id", -1)) >= 0:
			occ += 1
	return (float(occ) / _containment_cells.size()) * 100.0


func get_facility_integrity() -> String:
	var low_stab: int = get_low_stability_cells().size()
	var unpowered: int = get_unpowered_count()
	var total: int = _containment_cells.size()
	if total == 0:
		return "NoFacility"
	var problem_ratio: float = float(low_stab + unpowered) / float(total)
	if problem_ratio == 0.0:
		return "Pristine"
	if problem_ratio < 0.3:
		return "Operational"
	return "Compromised"


func get_capacity_headroom_pct() -> float:
	var empty: int = get_empty_cells()
	var total: int = _containment_cells.size()
	if total == 0:
		return 0.0
	return snappedf(float(empty) / float(total) * 100.0, 0.1)


func get_power_resilience() -> String:
	var unpowered: int = get_unpowered_count()
	var total: int = _containment_cells.size()
	if total == 0:
		return "NoData"
	var ratio: float = float(unpowered) / float(total)
	if ratio == 0.0:
		return "FullyPowered"
	if ratio < 0.2:
		return "MostlyPowered"
	return "PowerVulnerable"


func get_summary() -> Dictionary:
	var occupied: int = 0
	for cid: int in _containment_cells:
		if _containment_cells[cid]["entity_id"] >= 0:
			occupied += 1
	return {
		"containment_types": CONTAINMENT_TYPES.size(),
		"stability_factors": STABILITY_FACTORS.size(),
		"total_cells": _containment_cells.size(),
		"occupied": occupied,
		"low_stability": get_low_stability_cells().size(),
		"strongest": get_strongest_containment(),
		"avg_stability": snapped(get_avg_stability(), 0.01),
		"unpowered": get_unpowered_count(),
		"empty": get_empty_cells(),
		"total_power_draw": get_total_power_draw(),
		"addon_types": get_addon_count(),
		"occupied_pct": snapped(get_occupied_pct(), 0.1),
		"facility_integrity": get_facility_integrity(),
		"capacity_headroom_pct": get_capacity_headroom_pct(),
		"power_resilience": get_power_resilience(),
		"containment_protocol_level": get_containment_protocol_level(),
		"escape_probability": get_escape_probability(),
		"security_redundancy": get_security_redundancy(),
		"containment_ecosystem_health": get_containment_ecosystem_health(),
		"security_governance": get_security_governance(),
		"facility_maturity_index": get_facility_maturity_index(),
	}

func get_containment_protocol_level() -> String:
	var integrity := get_facility_integrity()
	var resilience := get_power_resilience()
	if integrity in ["Maximum", "High"] and resilience in ["Robust", "Fortified"]:
		return "Maximum Security"
	elif integrity in ["Moderate", "High"]:
		return "Standard"
	return "Minimal"

func get_escape_probability() -> String:
	var low_stab := get_low_stability_cells().size()
	var total := _containment_cells.size()
	if total <= 0:
		return "N/A"
	var ratio := float(low_stab) / float(total)
	if ratio >= 0.3:
		return "High"
	elif ratio >= 0.1:
		return "Moderate"
	return "Low"

func get_security_redundancy() -> float:
	var empty := get_empty_cells()
	var total := _containment_cells.size()
	if total <= 0:
		return 0.0
	return snapped(float(empty) / float(total) * 100.0, 0.1)

func get_containment_ecosystem_health() -> float:
	var integrity := get_facility_integrity()
	var i_val: float = 90.0 if integrity in ["Pristine", "Excellent"] else (60.0 if integrity in ["Good", "Adequate"] else 30.0)
	var resilience := get_power_resilience()
	var r_val: float = 90.0 if resilience in ["Robust", "Strong"] else (60.0 if resilience in ["Moderate", "Adequate"] else 30.0)
	var protocol := get_containment_protocol_level()
	var p_val: float = 90.0 if protocol in ["Maximum", "High"] else (60.0 if protocol in ["Standard", "Moderate"] else 30.0)
	return snapped((i_val + r_val + p_val) / 3.0, 0.1)

func get_facility_maturity_index() -> float:
	var escape := get_escape_probability()
	var e_val: float = 90.0 if escape == "Low" else (60.0 if escape == "Moderate" else 30.0)
	var redundancy := get_security_redundancy()
	var headroom := get_capacity_headroom_pct()
	return snapped((e_val + redundancy + headroom) / 3.0, 0.1)

func get_security_governance() -> String:
	var ecosystem := get_containment_ecosystem_health()
	var maturity := get_facility_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _containment_cells.size() > 0:
		return "Nascent"
	return "Dormant"
