extends Node

var _blighted_cells: Dictionary = {}
var _blight_events: int = 0

const BLIGHT_SPREAD_CHANCE: float = 0.15
const BLIGHT_KILL_DAYS: int = 5
const BLIGHT_RADIUS: int = 4

const CROP_RESISTANCE: Dictionary = {
	"Potato": 0.7, "Rice": 0.3, "Corn": 0.5, "Strawberry": 0.2,
	"Cotton": 0.4, "HealRoot": 0.6, "Haygrass": 0.5, "Hops": 0.3,
	"Smokeleaf": 0.4, "Psychoid": 0.5, "Devilstrand": 0.8, "Rose": 0.2
}

func start_blight(center: Vector2i) -> Dictionary:
	_blight_events += 1
	var affected: Array = []
	for dx: int in range(-BLIGHT_RADIUS, BLIGHT_RADIUS + 1):
		for dy: int in range(-BLIGHT_RADIUS, BLIGHT_RADIUS + 1):
			var cell: Vector2i = center + Vector2i(dx, dy)
			if Vector2(dx, dy).length() <= BLIGHT_RADIUS:
				if randf() < 0.6:
					_blighted_cells[cell] = {"days": 0, "severity": randf_range(0.3, 1.0)}
					affected.append(cell)
	return {"center": center, "affected_cells": affected.size()}

func advance_day() -> Dictionary:
	var killed: Array = []
	var spread: Array = []
	var to_remove: Array = []
	for cell: Variant in _blighted_cells:
		_blighted_cells[cell]["days"] += 1
		if _blighted_cells[cell]["days"] >= BLIGHT_KILL_DAYS:
			killed.append(cell)
			to_remove.append(cell)
		elif randf() < BLIGHT_SPREAD_CHANCE:
			var dir: Vector2i = Vector2i(randi_range(-1, 1), randi_range(-1, 1))
			var new_cell: Vector2i = cell + dir
			if not _blighted_cells.has(new_cell):
				spread.append(new_cell)
	for cell: Variant in to_remove:
		_blighted_cells.erase(cell)
	for cell: Vector2i in spread:
		_blighted_cells[cell] = {"days": 0, "severity": randf_range(0.2, 0.8)}
	return {"killed": killed.size(), "spread": spread.size(), "remaining": _blighted_cells.size()}

func get_crop_survival_chance(crop: String) -> float:
	return CROP_RESISTANCE.get(crop, 0.5)

func get_most_resistant_crop() -> String:
	var best: String = ""
	var best_res: float = 0.0
	for crop: String in CROP_RESISTANCE:
		if CROP_RESISTANCE[crop] > best_res:
			best_res = CROP_RESISTANCE[crop]
			best = crop
	return best


func get_most_vulnerable_crop() -> String:
	var worst: String = ""
	var worst_res: float = 999.0
	for crop: String in CROP_RESISTANCE:
		if CROP_RESISTANCE[crop] < worst_res:
			worst_res = CROP_RESISTANCE[crop]
			worst = crop
	return worst


func clear_blight() -> int:
	var count: int = _blighted_cells.size()
	_blighted_cells.clear()
	return count


func get_avg_blight_severity() -> float:
	if _blighted_cells.is_empty():
		return 0.0
	var total: float = 0.0
	for cell: Variant in _blighted_cells:
		total += float(_blighted_cells[cell].get("severity", 0.0))
	return total / _blighted_cells.size()


func get_avg_resistance() -> float:
	var total: float = 0.0
	for crop: String in CROP_RESISTANCE:
		total += CROP_RESISTANCE[crop]
	return total / maxf(CROP_RESISTANCE.size(), 1)


func is_blight_active() -> bool:
	return not _blighted_cells.is_empty()


func get_high_resistance_crop_count() -> int:
	var count: int = 0
	for crop: String in CROP_RESISTANCE:
		if CROP_RESISTANCE[crop] >= 0.6:
			count += 1
	return count


func get_resistance_range() -> Dictionary:
	var lo: float = 999.0
	var hi: float = 0.0
	for crop: String in CROP_RESISTANCE:
		if CROP_RESISTANCE[crop] < lo:
			lo = CROP_RESISTANCE[crop]
		if CROP_RESISTANCE[crop] > hi:
			hi = CROP_RESISTANCE[crop]
	return {"min": snapped(lo, 0.01), "max": snapped(hi, 0.01)}


func get_avg_blight_age() -> float:
	if _blighted_cells.is_empty():
		return 0.0
	var total: float = 0.0
	for cell: Variant in _blighted_cells:
		total += float(_blighted_cells[cell].get("days", 0))
	return snappedf(total / float(_blighted_cells.size()), 0.1)


func get_crop_security() -> String:
	var high_res: int = get_high_resistance_crop_count()
	if CROP_RESISTANCE.is_empty():
		return "N/A"
	var pct: float = float(high_res) / float(CROP_RESISTANCE.size())
	if pct >= 0.7:
		return "Secure"
	elif pct >= 0.4:
		return "Moderate"
	elif pct >= 0.15:
		return "Vulnerable"
	return "Critical"

func get_outbreak_trend() -> String:
	if _blight_events == 0:
		return "None"
	elif _blight_events <= 2:
		return "Rare"
	elif _blight_events <= 5:
		return "Recurring"
	return "Epidemic"

func get_damage_severity_pct() -> float:
	var avg_sev: float = get_avg_blight_severity()
	return snappedf(clampf(avg_sev * 100.0, 0.0, 100.0), 0.1)

func get_summary() -> Dictionary:
	return {
		"blighted_cells": _blighted_cells.size(),
		"blight_events": _blight_events,
		"crop_types": CROP_RESISTANCE.size(),
		"most_resistant": get_most_resistant_crop(),
		"most_vulnerable": get_most_vulnerable_crop(),
		"avg_severity": snapped(get_avg_blight_severity(), 0.01),
		"avg_resistance": snapped(get_avg_resistance(), 0.01),
		"active": is_blight_active(),
		"high_resistance_crops": get_high_resistance_crop_count(),
		"resistance_range": get_resistance_range(),
		"avg_blight_age": get_avg_blight_age(),
		"crop_security": get_crop_security(),
		"outbreak_trend": get_outbreak_trend(),
		"damage_severity_pct": get_damage_severity_pct(),
		"blight_containment": get_blight_containment(),
		"agricultural_resilience": get_agricultural_resilience(),
		"harvest_risk_index": get_harvest_risk_index(),
		"blight_ecosystem_health": get_blight_ecosystem_health(),
		"agricultural_governance": get_agricultural_governance(),
		"crop_resilience_index": get_crop_resilience_index(),
	}

func get_blight_containment() -> String:
	var active := is_blight_active()
	var cells := _blighted_cells.size()
	if not active:
		return "Contained"
	elif cells <= 5:
		return "Manageable"
	return "Spreading"

func get_agricultural_resilience() -> String:
	var high_resist := get_high_resistance_crop_count()
	var total := CROP_RESISTANCE.size()
	if total <= 0:
		return "N/A"
	if float(high_resist) / float(total) >= 0.6:
		return "Hardy"
	elif float(high_resist) / float(total) >= 0.3:
		return "Moderate"
	return "Vulnerable"

func get_harvest_risk_index() -> float:
	var severity := get_avg_blight_severity()
	var damage := get_damage_severity_pct()
	return snapped((severity * 50.0 + damage) / 2.0, 0.1)

func get_blight_ecosystem_health() -> float:
	var containment := get_blight_containment()
	var con_val: float = 90.0 if containment in ["Contained", "Clear"] else (60.0 if containment in ["Monitoring", "Partial"] else 30.0)
	var resilience := get_agricultural_resilience()
	var res_val: float = 90.0 if resilience == "Hardy" else (60.0 if resilience == "Moderate" else 30.0)
	var risk := get_harvest_risk_index()
	var r_val: float = maxf(100.0 - risk, 0.0)
	return snapped((con_val + res_val + r_val) / 3.0, 0.1)

func get_crop_resilience_index() -> float:
	var security := get_crop_security()
	var s_val: float = 90.0 if security in ["Secure", "Safe"] else (60.0 if security in ["Guarded", "Moderate"] else 30.0)
	var trend := get_outbreak_trend()
	var t_val: float = 90.0 if trend in ["Declining", "None"] else (60.0 if trend in ["Stable", "Low"] else 30.0)
	var damage := get_damage_severity_pct()
	var d_val: float = maxf(100.0 - damage, 0.0)
	return snapped((s_val + t_val + d_val) / 3.0, 0.1)

func get_agricultural_governance() -> String:
	var ecosystem := get_blight_ecosystem_health()
	var maturity := get_crop_resilience_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _blight_events > 0:
		return "Nascent"
	return "Dormant"
