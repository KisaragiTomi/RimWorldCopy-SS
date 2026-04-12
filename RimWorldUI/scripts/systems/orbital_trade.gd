extends Node

var _trade_ships: Array = []
var _beacons: Array = []

const SHIP_TYPES: Dictionary = {
	"BulkGoods": {"category": "raw", "silver_range": [800, 3000], "items": ["Steel", "Wood", "Cloth", "Leather", "Silver"]},
	"ExoticGoods": {"category": "exotic", "silver_range": [1500, 5000], "items": ["Gold", "Plasteel", "Jade", "Luciferium", "GlitterworldMedicine"]},
	"CombatSupplier": {"category": "combat", "silver_range": [1000, 4000], "items": ["ChargeRifle", "SniperRifle", "FlakVest", "PowerArmor"]},
	"SlaveTrader": {"category": "slave", "silver_range": [500, 2000], "items": ["Prisoner"]},
	"PirateMerchant": {"category": "pirate", "silver_range": [600, 2500], "items": ["Smokeleaf", "Psychite", "Beer", "Weapons"]}
}

const BEACON_RANGE: int = 7

func place_beacon(position: Vector2i) -> int:
	var beacon: Dictionary = {"id": _beacons.size(), "position": position, "powered": true}
	_beacons.append(beacon)
	return beacon["id"]

func arrive_ship(ship_type: String) -> Dictionary:
	if not SHIP_TYPES.has(ship_type):
		return {}
	var ship: Dictionary = {
		"id": _trade_ships.size(),
		"type": ship_type,
		"departure_tick": 0,
		"traded": false
	}
	_trade_ships.append(ship)
	return ship

func can_trade() -> bool:
	for b: Dictionary in _beacons:
		if b["powered"]:
			return true
	return false

func execute_trade(ship_id: int, sell_items: Array, buy_items: Array) -> Dictionary:
	if ship_id < 0 or ship_id >= _trade_ships.size():
		return {}
	if not can_trade():
		return {"error": "no_powered_beacon"}
	_trade_ships[ship_id]["traded"] = true
	return {"sold": sell_items.size(), "bought": buy_items.size()}

func get_powered_beacon_count() -> int:
	var count: int = 0
	for b: Dictionary in _beacons:
		if bool(b.get("powered", false)):
			count += 1
	return count


func get_traded_count() -> int:
	var count: int = 0
	for s: Dictionary in _trade_ships:
		if bool(s.get("traded", false)):
			count += 1
	return count


func get_available_ships() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for s: Dictionary in _trade_ships:
		if not bool(s.get("traded", false)):
			result.append(s)
	return result


func get_trade_rate() -> float:
	if _trade_ships.is_empty():
		return 0.0
	return float(get_traded_count()) / _trade_ships.size()


func get_most_common_ship_type() -> String:
	var counts: Dictionary = {}
	for s: Dictionary in _trade_ships:
		var t: String = String(s.get("type", ""))
		counts[t] = counts.get(t, 0) + 1
	var best: String = ""
	var best_count: int = 0
	for t: String in counts:
		if int(counts[t]) > best_count:
			best_count = int(counts[t])
			best = t
	return best


func get_unpowered_beacon_count() -> int:
	var count: int = 0
	for b: Dictionary in _beacons:
		if not bool(b.get("powered", false)):
			count += 1
	return count


func get_unique_visited_types() -> int:
	var types: Dictionary = {}
	for s: Dictionary in _trade_ships:
		types[String(s.get("type", ""))] = true
	return types.size()


func get_untraded_count() -> int:
	return _trade_ships.size() - get_traded_count()


func get_beacon_power_rate() -> float:
	if _beacons.is_empty():
		return 0.0
	return snappedf(float(get_powered_beacon_count()) / float(_beacons.size()) * 100.0, 0.1)


func get_trade_infrastructure() -> String:
	var rate: float = get_beacon_power_rate()
	if rate >= 0.9:
		return "Optimal"
	elif rate >= 0.6:
		return "Functional"
	elif rate >= 0.3:
		return "Degraded"
	return "Offline"

func get_commerce_activity() -> String:
	var trade_rate: float = get_trade_rate()
	if trade_rate >= 0.8:
		return "Thriving"
	elif trade_rate >= 0.5:
		return "Active"
	elif trade_rate >= 0.2:
		return "Slow"
	return "Dormant"

func get_market_diversity_pct() -> float:
	if SHIP_TYPES.is_empty():
		return 0.0
	return snappedf(float(get_unique_visited_types()) / float(SHIP_TYPES.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"ship_types": SHIP_TYPES.size(),
		"beacons": _beacons.size(),
		"powered_beacons": get_powered_beacon_count(),
		"ships_visited": _trade_ships.size(),
		"trades_completed": get_traded_count(),
		"trade_rate": snapped(get_trade_rate(), 0.01),
		"most_common_ship": get_most_common_ship_type(),
		"unpowered_beacons": get_unpowered_beacon_count(),
		"unique_visited_types": get_unique_visited_types(),
		"untraded": get_untraded_count(),
		"beacon_power_rate": get_beacon_power_rate(),
		"trade_infrastructure": get_trade_infrastructure(),
		"commerce_activity": get_commerce_activity(),
		"market_diversity_pct": get_market_diversity_pct(),
		"orbital_readiness": get_orbital_readiness(),
		"trade_throughput": get_trade_throughput(),
		"supply_chain_reliability": get_supply_chain_reliability(),
		"spaceport_ecosystem_health": get_spaceport_ecosystem_health(),
		"orbital_governance": get_orbital_governance(),
		"orbital_maturity_index": get_orbital_maturity_index(),
	}

func get_orbital_readiness() -> String:
	var infra := get_trade_infrastructure()
	var powered := get_powered_beacon_count()
	if infra in ["Advanced", "Established"] and powered >= 2:
		return "Fully Operational"
	elif powered > 0:
		return "Basic"
	return "Offline"

func get_trade_throughput() -> float:
	var traded := get_traded_count()
	var visited := _trade_ships.size()
	if visited <= 0:
		return 0.0
	return snapped(float(traded) / float(visited) * 100.0, 0.1)

func get_supply_chain_reliability() -> String:
	var rate := get_trade_rate()
	var diversity := get_market_diversity_pct()
	if rate >= 0.7 and diversity >= 50.0:
		return "Reliable"
	elif rate >= 0.3:
		return "Inconsistent"
	return "Unreliable"

func get_spaceport_ecosystem_health() -> float:
	var readiness := get_orbital_readiness()
	var r_val: float = 90.0 if readiness in ["Online", "Active"] else (60.0 if readiness in ["Partial", "Standby"] else 30.0)
	var reliability := get_supply_chain_reliability()
	var rel_val: float = 90.0 if reliability == "Reliable" else (60.0 if reliability == "Inconsistent" else 30.0)
	var diversity := get_market_diversity_pct()
	return snapped((r_val + rel_val + diversity) / 3.0, 0.1)

func get_orbital_maturity_index() -> float:
	var infra := get_trade_infrastructure()
	var i_val: float = 90.0 if infra in ["Advanced", "Full"] else (60.0 if infra in ["Basic", "Functional"] else 30.0)
	var activity := get_commerce_activity()
	var a_val: float = 90.0 if activity in ["Bustling", "Active"] else (60.0 if activity in ["Moderate", "Sporadic"] else 30.0)
	var throughput := get_trade_throughput()
	return snapped((i_val + a_val + minf(throughput, 100.0)) / 3.0, 0.1)

func get_orbital_governance() -> String:
	var ecosystem := get_spaceport_ecosystem_health()
	var maturity := get_orbital_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _beacons.size() > 0:
		return "Nascent"
	return "Dormant"
