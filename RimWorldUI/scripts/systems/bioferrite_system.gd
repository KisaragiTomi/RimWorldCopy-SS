extends Node

var _bioferrite_stock: float = 0.0
var _producers: Dictionary = {}

const BIOFERRITE_USES: Dictionary = {
	"SerumCraft": {"cost": 5, "product": "EntitySerum", "desc": "Craft entity serum"},
	"WeaponCoat": {"cost": 3, "bonus": 0.1, "desc": "Coat weapon for bonus damage"},
	"ContainmentReinforce": {"cost": 8, "bonus": 0.3, "desc": "Reinforce containment cell"},
	"ResearchBoost": {"cost": 2, "bonus": 0.15, "desc": "Speed up anomaly research"},
	"FloorTile": {"cost": 1, "beauty": 2, "desc": "Bioferrite floor tile"},
	"WallPanel": {"cost": 4, "hp_bonus": 50, "desc": "Reinforce wall with bioferrite"}
}

const PRODUCTION_SOURCES: Dictionary = {
	"HarnessedEntity": {"per_day": 2.0, "requires_power": true},
	"BioferriteRefinery": {"per_day": 1.0, "requires_power": true, "input": "RawBioferrite"},
	"EntityCorpse": {"one_time": 5.0}
}

func add_bioferrite(amount: float) -> float:
	_bioferrite_stock += amount
	return _bioferrite_stock

func use_bioferrite(use_type: String) -> Dictionary:
	if not BIOFERRITE_USES.has(use_type):
		return {"error": "unknown_use"}
	var cost: float = BIOFERRITE_USES[use_type]["cost"]
	if _bioferrite_stock < cost:
		return {"error": "insufficient", "need": cost, "have": _bioferrite_stock}
	_bioferrite_stock -= cost
	return {"used": use_type, "cost": cost, "remaining": _bioferrite_stock}

func get_most_expensive_use() -> String:
	var best: String = ""
	var best_c: float = 0.0
	for u: String in BIOFERRITE_USES:
		var c: float = float(BIOFERRITE_USES[u].get("cost", 0))
		if c > best_c:
			best_c = c
			best = u
	return best


func get_daily_production() -> float:
	var total: float = 0.0
	for src: String in PRODUCTION_SOURCES:
		total += float(PRODUCTION_SOURCES[src].get("per_day", 0.0))
	return total


func can_afford(use_type: String) -> bool:
	if not BIOFERRITE_USES.has(use_type):
		return false
	return _bioferrite_stock >= float(BIOFERRITE_USES[use_type].get("cost", 999))


func get_cheapest_use() -> String:
	var best: String = ""
	var best_cost: float = 999999.0
	for u: String in BIOFERRITE_USES:
		var c: float = float(BIOFERRITE_USES[u].get("cost", 999999.0))
		if c < best_cost:
			best_cost = c
			best = u
	return best


func get_affordable_use_count() -> int:
	var count: int = 0
	for u: String in BIOFERRITE_USES:
		if float(BIOFERRITE_USES[u].get("cost", 999999.0)) <= _bioferrite_stock:
			count += 1
	return count


func get_active_producer_count() -> int:
	return _producers.size()


func get_avg_use_cost() -> float:
	if BIOFERRITE_USES.is_empty():
		return 0.0
	var total: float = 0.0
	for u: String in BIOFERRITE_USES:
		total += float(BIOFERRITE_USES[u].get("cost", 0))
	return total / BIOFERRITE_USES.size()


func get_power_dependent_source_count() -> int:
	var count: int = 0
	for src: String in PRODUCTION_SOURCES:
		if bool(PRODUCTION_SOURCES[src].get("requires_power", false)):
			count += 1
	return count


func get_total_one_time_yield() -> float:
	var total: float = 0.0
	for src: String in PRODUCTION_SOURCES:
		total += float(PRODUCTION_SOURCES[src].get("one_time", 0.0))
	return total


func get_supply_chain_health() -> String:
	var daily: float = get_daily_production()
	var avg_cost: float = get_avg_use_cost()
	if daily <= 0.0:
		return "offline"
	var ratio: float = daily / maxf(avg_cost, 0.01)
	if ratio >= 2.0:
		return "surplus"
	if ratio >= 0.8:
		return "balanced"
	return "deficit"

func get_cost_effectiveness_pct() -> float:
	var total_cost: float = 0.0
	var total_bonus: float = 0.0
	for u: String in BIOFERRITE_USES:
		total_cost += BIOFERRITE_USES[u]["cost"]
		if BIOFERRITE_USES[u].has("bonus"):
			total_bonus += BIOFERRITE_USES[u]["bonus"]
	if total_cost <= 0.0:
		return 0.0
	return snapped(total_bonus * 100.0 / total_cost, 0.1)

func get_strategic_reserve() -> String:
	var daily: float = get_daily_production()
	if daily <= 0.0:
		if _bioferrite_stock > 0.0:
			return "depleting"
		return "empty"
	var days_buffer: float = _bioferrite_stock / daily
	if days_buffer >= 10.0:
		return "abundant"
	if days_buffer >= 3.0:
		return "adequate"
	return "low"

func get_summary() -> Dictionary:
	return {
		"bioferrite_uses": BIOFERRITE_USES.size(),
		"production_sources": PRODUCTION_SOURCES.size(),
		"current_stock": _bioferrite_stock,
		"daily_production": get_daily_production(),
		"most_expensive": get_most_expensive_use(),
		"cheapest": get_cheapest_use(),
		"affordable": get_affordable_use_count(),
		"active_producers": get_active_producer_count(),
		"avg_use_cost": snapped(get_avg_use_cost(), 0.01),
		"power_sources": get_power_dependent_source_count(),
		"one_time_yield": get_total_one_time_yield(),
		"supply_chain_health": get_supply_chain_health(),
		"cost_effectiveness_pct": get_cost_effectiveness_pct(),
		"strategic_reserve": get_strategic_reserve(),
		"production_scalability": get_production_scalability(),
		"consumption_headroom": get_consumption_headroom(),
		"bioferrite_economy_rating": get_bioferrite_economy_rating(),
		"bioferrite_ecosystem_health": get_bioferrite_ecosystem_health(),
		"bioferrite_governance": get_bioferrite_governance(),
		"industrial_maturity_index": get_industrial_maturity_index(),
	}

func get_production_scalability() -> String:
	var producers := get_active_producer_count()
	var sources := PRODUCTION_SOURCES.size()
	if sources <= 0:
		return "None"
	var ratio := float(producers) / float(sources)
	if ratio >= 0.7:
		return "Highly Scalable"
	elif ratio >= 0.3:
		return "Expandable"
	return "Limited"

func get_consumption_headroom() -> float:
	var stock := _bioferrite_stock
	var avg_cost := get_avg_use_cost()
	if avg_cost <= 0.0:
		return 100.0
	return snapped(float(stock) / avg_cost * 10.0, 0.1)

func get_bioferrite_economy_rating() -> String:
	var health := get_supply_chain_health()
	var effectiveness := get_cost_effectiveness_pct()
	if health in ["Healthy", "Robust"] and effectiveness >= 60.0:
		return "Flourishing"
	elif effectiveness >= 30.0:
		return "Stable"
	return "Struggling"

func get_bioferrite_ecosystem_health() -> float:
	var chain := get_supply_chain_health()
	var ch_val: float = 90.0 if chain in ["Healthy", "Robust"] else (60.0 if chain in ["Adequate", "Moderate"] else 30.0)
	var economy := get_bioferrite_economy_rating()
	var ec_val: float = 90.0 if economy == "Flourishing" else (60.0 if economy == "Stable" else 30.0)
	var effectiveness := get_cost_effectiveness_pct()
	return snapped((ch_val + ec_val + effectiveness) / 3.0, 0.1)

func get_industrial_maturity_index() -> float:
	var scalability := get_production_scalability()
	var s_val: float = 90.0 if scalability in ["High", "Excellent"] else (60.0 if scalability in ["Moderate", "Adequate"] else 30.0)
	var headroom := get_consumption_headroom()
	var reserve := get_strategic_reserve()
	var r_val: float = 90.0 if reserve in ["Ample", "Strong"] else (60.0 if reserve in ["Moderate", "Some"] else 30.0)
	return snapped((s_val + minf(headroom, 100.0) + r_val) / 3.0, 0.1)

func get_bioferrite_governance() -> String:
	var ecosystem := get_bioferrite_ecosystem_health()
	var maturity := get_industrial_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _bioferrite_stock > 0:
		return "Nascent"
	return "Dormant"
