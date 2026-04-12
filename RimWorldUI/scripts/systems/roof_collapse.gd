extends Node

var _supports: Dictionary = {}
var _roofed_cells: Dictionary = {}

const SUPPORT_RADIUS: int = 6
const COLLAPSE_DAMAGE: float = 100.0
const NATURAL_ROOF_RANGE: int = 3

const SUPPORT_TYPES: Dictionary = {
	"Wall": {"radius": 6, "strength": 1.0},
	"Column": {"radius": 6, "strength": 1.0},
	"ThickRoof": {"radius": 3, "strength": 0.5, "natural": true},
	"OverheadMountain": {"radius": 0, "strength": 999.0, "natural": true}
}

func add_support(support_id: int, support_type: String, position: Vector2i) -> bool:
	if not SUPPORT_TYPES.has(support_type):
		return false
	_supports[support_id] = {"type": support_type, "position": position}
	return true

func remove_support(support_id: int) -> Array:
	if not _supports.has(support_id):
		return []
	var pos: Vector2i = _supports[support_id]["position"]
	_supports.erase(support_id)
	return _check_collapse(pos)

func _check_collapse(removed_pos: Vector2i) -> Array:
	var collapsed: Array = []
	for cell: Variant in _roofed_cells:
		var supported: bool = false
		for sid: int in _supports:
			var sup: Dictionary = _supports[sid]
			var stype: Dictionary = SUPPORT_TYPES[sup["type"]]
			var dist: float = Vector2(cell - sup["position"]).length()
			if dist <= stype["radius"]:
				supported = true
				break
		if not supported:
			collapsed.append(cell)
	for cell: Variant in collapsed:
		_roofed_cells.erase(cell)
	return collapsed

func add_roof(cell: Vector2i) -> void:
	_roofed_cells[cell] = true

func get_collapse_damage() -> float:
	return COLLAPSE_DAMAGE

func get_natural_supports() -> int:
	var count: int = 0
	for sid: int in _supports:
		var stype: Dictionary = SUPPORT_TYPES.get(String(_supports[sid].get("type", "")), {})
		if bool(stype.get("natural", false)):
			count += 1
	return count


func get_unsupported_cells() -> Array:
	var unsupported: Array = []
	for cell: Variant in _roofed_cells:
		var supported: bool = false
		for sid: int in _supports:
			var sup: Dictionary = _supports[sid]
			var stype: Dictionary = SUPPORT_TYPES[sup["type"]]
			var dist: float = Vector2(cell - sup["position"]).length()
			if dist <= stype["radius"]:
				supported = true
				break
		if not supported:
			unsupported.append(cell)
	return unsupported


func get_unsupported_count() -> int:
	return get_unsupported_cells().size()


func get_roof_coverage() -> float:
	if _roofed_cells.is_empty():
		return 0.0
	var supported: int = _roofed_cells.size() - get_unsupported_count()
	return float(supported) / _roofed_cells.size()


func get_artificial_support_count() -> int:
	var count: int = 0
	for sid: int in _supports:
		var stype: Dictionary = SUPPORT_TYPES.get(String(_supports[sid].get("type", "")), {})
		if not bool(stype.get("natural", false)):
			count += 1
	return count


func get_support_type_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for sid: int in _supports:
		var t: String = String(_supports[sid].get("type", ""))
		dist[t] = dist.get(t, 0) + 1
	return dist


func get_avg_support_radius() -> float:
	if SUPPORT_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for st: String in SUPPORT_TYPES:
		total += float(SUPPORT_TYPES[st].get("radius", 0))
	return snappedf(total / float(SUPPORT_TYPES.size()), 0.1)


func get_support_to_roof_ratio() -> float:
	if _roofed_cells.is_empty():
		return 0.0
	return snappedf(float(_supports.size()) / float(_roofed_cells.size()), 0.01)


func get_collapse_risk() -> String:
	var unsupported: int = get_unsupported_count()
	if _roofed_cells.is_empty():
		return "N/A"
	var risk_pct: float = float(unsupported) / float(_roofed_cells.size())
	if risk_pct >= 0.3:
		return "Critical"
	elif risk_pct >= 0.15:
		return "High"
	elif risk_pct >= 0.05:
		return "Moderate"
	return "Safe"

func get_engineering_quality() -> String:
	var ratio: float = get_support_to_roof_ratio()
	if ratio >= 0.5:
		return "Over-Engineered"
	elif ratio >= 0.25:
		return "Solid"
	elif ratio >= 0.1:
		return "Adequate"
	return "Insufficient"

func get_natural_reliance_pct() -> float:
	if _supports.is_empty():
		return 0.0
	return snappedf(float(get_natural_supports()) / float(_supports.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"support_count": _supports.size(),
		"roofed_cells": _roofed_cells.size(),
		"support_types": SUPPORT_TYPES.size(),
		"collapse_damage": COLLAPSE_DAMAGE,
		"natural_supports": get_natural_supports(),
		"unsupported": get_unsupported_count(),
		"roof_coverage": snapped(get_roof_coverage(), 0.01),
		"artificial_supports": get_artificial_support_count(),
		"support_dist": get_support_type_distribution(),
		"avg_support_radius": get_avg_support_radius(),
		"support_ratio": get_support_to_roof_ratio(),
		"collapse_risk": get_collapse_risk(),
		"engineering_quality": get_engineering_quality(),
		"natural_reliance_pct": get_natural_reliance_pct(),
		"structural_safety_margin": get_structural_safety_margin(),
		"roof_maintenance_need": get_roof_maintenance_need(),
		"support_redundancy": get_support_redundancy(),
		"roof_ecosystem_health": get_roof_ecosystem_health(),
		"structural_governance": get_structural_governance(),
		"roofing_maturity_index": get_roofing_maturity_index(),
	}

func get_structural_safety_margin() -> float:
	var ratio := get_support_to_roof_ratio()
	return snapped(minf(ratio * 100.0, 100.0), 0.1)

func get_roof_maintenance_need() -> String:
	var unsupported := get_unsupported_count()
	var risk := get_collapse_risk()
	if unsupported == 0 and risk in ["None", "Low"]:
		return "None"
	elif unsupported <= 3:
		return "Minor"
	return "Urgent"

func get_support_redundancy() -> String:
	var artificial := get_artificial_support_count()
	var natural := get_natural_supports()
	if artificial >= 3 and natural >= 2:
		return "Redundant"
	elif artificial > 0 or natural > 0:
		return "Adequate"
	return "None"

func get_roof_ecosystem_health() -> float:
	var quality := get_engineering_quality()
	var q_val: float = 90.0 if quality in ["Excellent", "Superior"] else (60.0 if quality in ["Good", "Adequate"] else 30.0)
	var risk := get_collapse_risk()
	var r_val: float = 90.0 if risk in ["None", "Low"] else (50.0 if risk == "Moderate" else 20.0)
	var redundancy := get_support_redundancy()
	var red_val: float = 90.0 if redundancy == "Redundant" else (60.0 if redundancy == "Adequate" else 30.0)
	return snapped((q_val + r_val + red_val) / 3.0, 0.1)

func get_roofing_maturity_index() -> float:
	var maintenance := get_roof_maintenance_need()
	var m_val: float = 90.0 if maintenance == "None" else (60.0 if maintenance == "Minor" else 30.0)
	var reliance := get_natural_reliance_pct()
	var rel_val: float = maxf(100.0 - reliance, 0.0)
	var ratio := get_support_to_roof_ratio()
	return snapped((m_val + rel_val + minf(ratio * 100.0, 100.0)) / 3.0, 0.1)

func get_structural_governance() -> String:
	var ecosystem := get_roof_ecosystem_health()
	var maturity := get_roofing_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _supports.size() > 0:
		return "Nascent"
	return "Dormant"
