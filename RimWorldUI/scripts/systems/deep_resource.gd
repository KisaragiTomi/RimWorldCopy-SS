extends Node

var _deposits: Dictionary = {}
var _scanner_active: bool = false

const DEEP_RESOURCES: Dictionary = {
	"Steel": {"min_yield": 200, "max_yield": 600, "commonality": 0.30},
	"Gold": {"min_yield": 20, "max_yield": 80, "commonality": 0.08},
	"Plasteel": {"min_yield": 30, "max_yield": 100, "commonality": 0.05},
	"Uranium": {"min_yield": 15, "max_yield": 50, "commonality": 0.04},
	"Jade": {"min_yield": 30, "max_yield": 80, "commonality": 0.06},
	"Silver": {"min_yield": 100, "max_yield": 400, "commonality": 0.12},
	"Compacted_Machinery": {"min_yield": 5, "max_yield": 15, "commonality": 0.03},
	"Chemfuel": {"min_yield": 100, "max_yield": 300, "commonality": 0.10}
}

const DRILL_SPEED: float = 0.02
const SCAN_INTERVAL_TICKS: int = 60000

func activate_scanner() -> void:
	_scanner_active = true

func scan_area(center: Vector2i) -> Dictionary:
	if not _scanner_active:
		return {}
	var resources: Array = DEEP_RESOURCES.keys()
	var roll: float = randf()
	var cumulative: float = 0.0
	var selected: String = "Steel"
	for r: String in resources:
		cumulative += DEEP_RESOURCES[r]["commonality"]
		if roll <= cumulative:
			selected = r
			break
	var info: Dictionary = DEEP_RESOURCES[selected]
	var yield_amount: int = randi_range(info["min_yield"], info["max_yield"])
	var deposit: Dictionary = {"resource": selected, "remaining": yield_amount, "position": center}
	_deposits[center] = deposit
	return deposit

func drill(position: Vector2i) -> Dictionary:
	if not _deposits.has(position):
		return {}
	var dep: Dictionary = _deposits[position]
	var extracted: int = maxi(1, int(dep["remaining"] * DRILL_SPEED))
	dep["remaining"] -= extracted
	if dep["remaining"] <= 0:
		_deposits.erase(position)
	return {"resource": dep["resource"], "extracted": extracted, "remaining": dep.get("remaining", 0)}

func get_total_remaining() -> int:
	var total: int = 0
	for pos: Vector2i in _deposits:
		total += int(_deposits[pos].get("remaining", 0))
	return total


func get_rarest_resource() -> String:
	var best: String = ""
	var lowest: float = 999.0
	for r: String in DEEP_RESOURCES:
		var c: float = float(DEEP_RESOURCES[r].get("commonality", 1.0))
		if c < lowest:
			lowest = c
			best = r
	return best


func get_most_common_resource() -> String:
	var best: String = ""
	var highest: float = 0.0
	for r: String in DEEP_RESOURCES:
		var c: float = float(DEEP_RESOURCES[r].get("commonality", 0.0))
		if c > highest:
			highest = c
			best = r
	return best


func get_avg_remaining_per_deposit() -> float:
	if _deposits.is_empty():
		return 0.0
	return float(get_total_remaining()) / _deposits.size()


func get_deposit_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pos: Vector2i in _deposits:
		var r: String = String(_deposits[pos].get("resource", ""))
		dist[r] = dist.get(r, 0) + 1
	return dist


func get_avg_max_yield() -> float:
	var total: float = 0.0
	for r: String in DEEP_RESOURCES:
		total += float(DEEP_RESOURCES[r].get("max_yield", 0))
	return total / maxf(DEEP_RESOURCES.size(), 1)


func get_total_commonality() -> float:
	var total: float = 0.0
	for r: String in DEEP_RESOURCES:
		total += float(DEEP_RESOURCES[r].get("commonality", 0.0))
	return snappedf(total, 0.01)


func get_high_value_count() -> int:
	var count: int = 0
	for r: String in DEEP_RESOURCES:
		if float(DEEP_RESOURCES[r].get("commonality", 1.0)) <= 0.05:
			count += 1
	return count


func get_unique_discovered() -> int:
	var types: Dictionary = {}
	for pos: Vector2i in _deposits:
		types[String(_deposits[pos].get("resource", ""))] = true
	return types.size()


func get_mining_outlook() -> String:
	if _deposits.is_empty():
		return "Uncharted"
	var avg: float = get_avg_remaining_per_deposit()
	if avg >= 100.0:
		return "Rich"
	elif avg >= 50.0:
		return "Viable"
	elif avg >= 20.0:
		return "Thinning"
	return "Depleted"

func get_prospecting_coverage_pct() -> float:
	if DEEP_RESOURCES.is_empty():
		return 0.0
	return snappedf(float(get_unique_discovered()) / float(DEEP_RESOURCES.size()) * 100.0, 0.1)

func get_strategic_value() -> String:
	var high_val: int = get_high_value_count()
	if high_val >= 4:
		return "Exceptional"
	elif high_val >= 2:
		return "Significant"
	elif high_val >= 1:
		return "Moderate"
	return "Low"

func get_summary() -> Dictionary:
	return {
		"resource_types": DEEP_RESOURCES.size(),
		"known_deposits": _deposits.size(),
		"scanner_active": _scanner_active,
		"total_remaining": get_total_remaining(),
		"rarest": get_rarest_resource(),
		"avg_remaining": snapped(get_avg_remaining_per_deposit(), 0.1),
		"avg_max_yield": snapped(get_avg_max_yield(), 0.1),
		"total_commonality": get_total_commonality(),
		"high_value_types": get_high_value_count(),
		"unique_discovered": get_unique_discovered(),
		"mining_outlook": get_mining_outlook(),
		"prospecting_coverage_pct": get_prospecting_coverage_pct(),
		"strategic_value": get_strategic_value(),
		"extraction_sustainability": get_extraction_sustainability(),
		"mineral_wealth_index": get_mineral_wealth_index(),
		"resource_depletion_risk": get_resource_depletion_risk(),
		"mining_ecosystem_health": get_mining_ecosystem_health(),
		"resource_governance": get_resource_governance(),
		"geological_maturity_index": get_geological_maturity_index(),
	}

func get_extraction_sustainability() -> String:
	var remaining := get_total_remaining()
	var deposits := _deposits.size()
	if deposits <= 0:
		return "No Deposits"
	if float(remaining) / float(deposits) >= 50.0:
		return "Sustainable"
	elif remaining > 0:
		return "Depleting"
	return "Exhausted"

func get_mineral_wealth_index() -> float:
	var high_value := get_high_value_count()
	var total := DEEP_RESOURCES.size()
	if total <= 0:
		return 0.0
	return snapped(float(high_value) / float(total) * 100.0, 0.1)

func get_resource_depletion_risk() -> String:
	var avg := get_avg_remaining_per_deposit()
	if avg >= 80.0:
		return "Low"
	elif avg >= 30.0:
		return "Moderate"
	return "High"

func get_mining_ecosystem_health() -> float:
	var sustainability := get_extraction_sustainability()
	var s_val: float = 90.0 if sustainability in ["Sustainable", "Abundant"] else (60.0 if sustainability in ["Moderate", "Adequate"] else 30.0)
	var wealth := get_mineral_wealth_index()
	var depletion := get_resource_depletion_risk()
	var d_val: float = 90.0 if depletion == "Low" else (50.0 if depletion == "Moderate" else 20.0)
	return snapped((s_val + wealth + d_val) / 3.0, 0.1)

func get_geological_maturity_index() -> float:
	var outlook := get_mining_outlook()
	var o_val: float = 90.0 if outlook in ["Rich", "Promising"] else (60.0 if outlook in ["Moderate", "Viable"] else 30.0)
	var coverage := get_prospecting_coverage_pct()
	var value := get_strategic_value()
	var v_val: float = 90.0 if value in ["Critical", "High"] else (60.0 if value in ["Moderate", "Some"] else 30.0)
	return snapped((o_val + coverage + v_val) / 3.0, 0.1)

func get_resource_governance() -> String:
	var ecosystem := get_mining_ecosystem_health()
	var maturity := get_geological_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _deposits.size() > 0:
		return "Nascent"
	return "Dormant"
