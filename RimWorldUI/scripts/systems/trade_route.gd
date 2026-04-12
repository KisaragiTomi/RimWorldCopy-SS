extends Node

var _routes: Dictionary = {}
var _next_id: int = 1

const ROUTE_INTERVALS: Dictionary = {
	"Weekly": 7,
	"BiWeekly": 14,
	"Monthly": 30,
	"Seasonal": 60,
}


func create_route(faction: String, interval: String, goods_out: Array, goods_in: Array) -> int:
	var rid: int = _next_id
	_next_id += 1
	_routes[rid] = {
		"faction": faction,
		"interval": interval,
		"interval_days": int(ROUTE_INTERVALS.get(interval, 30)),
		"goods_out": goods_out,
		"goods_in": goods_in,
		"last_trade_day": 0,
		"total_trades": 0,
	}
	return rid


func cancel_route(route_id: int) -> void:
	_routes.erase(route_id)


func check_due_routes(current_day: int) -> Array:
	var due: Array = []
	for rid: int in _routes:
		var route: Dictionary = _routes[rid]
		var last: int = int(route.get("last_trade_day", 0))
		var interval: int = int(route.get("interval_days", 30))
		if current_day - last >= interval:
			due.append(rid)
	return due


func execute_trade(route_id: int, current_day: int) -> Dictionary:
	if not _routes.has(route_id):
		return {"success": false}
	_routes[route_id].last_trade_day = current_day
	_routes[route_id].total_trades = int(_routes[route_id].get("total_trades", 0)) + 1
	return {"success": true, "faction": _routes[route_id].faction}


func get_most_active_route() -> Dictionary:
	var best_id: int = -1
	var best_trades: int = 0
	for rid: int in _routes:
		var t: int = int(_routes[rid].get("total_trades", 0))
		if t > best_trades:
			best_trades = t
			best_id = rid
	if best_id < 0:
		return {}
	return {"id": best_id, "faction": _routes[best_id].faction, "trades": best_trades}


func get_routes_by_faction(faction: String) -> Array[int]:
	var result: Array[int] = []
	for rid: int in _routes:
		if String(_routes[rid].get("faction", "")) == faction:
			result.append(rid)
	return result


func get_total_trades() -> int:
	var total: int = 0
	for rid: int in _routes:
		total += int(_routes[rid].get("total_trades", 0))
	return total


func get_avg_trades_per_route() -> float:
	if _routes.is_empty():
		return 0.0
	return snappedf(float(get_total_trades()) / float(_routes.size()), 0.1)


func get_inactive_route_count() -> int:
	var count: int = 0
	for rid: int in _routes:
		if not _routes[rid].get("active", true):
			count += 1
	return count


func get_unique_faction_count() -> int:
	var factions: Dictionary = {}
	for rid: int in _routes:
		var f: String = String(_routes[rid].get("faction", ""))
		if not f.is_empty():
			factions[f] = true
	return factions.size()


func get_most_common_interval() -> String:
	var counts: Dictionary = {}
	for rid: int in _routes:
		var iv: String = String(_routes[rid].get("interval", ""))
		counts[iv] = counts.get(iv, 0) + 1
	var best: String = ""
	var best_n: int = 0
	for iv: String in counts:
		if int(counts[iv]) > best_n:
			best_n = int(counts[iv])
			best = iv
	return best


func get_zero_trade_count() -> int:
	var count: int = 0
	for rid: int in _routes:
		if int(_routes[rid].get("total_trades", 0)) == 0:
			count += 1
	return count


func get_trade_network_health() -> String:
	var inactive: int = get_inactive_route_count()
	if inactive == 0:
		return "Thriving"
	elif inactive <= 2:
		return "Healthy"
	elif inactive <= _routes.size() / 2:
		return "Declining"
	return "Stagnant"

func get_route_utilization_pct() -> float:
	if _routes.is_empty():
		return 0.0
	var active: int = _routes.size() - get_inactive_route_count()
	return snappedf(float(active) / float(_routes.size()) * 100.0, 0.1)

func get_diplomatic_reach() -> String:
	var factions: int = get_unique_faction_count()
	if factions >= 5:
		return "Wide"
	elif factions >= 3:
		return "Moderate"
	elif factions >= 1:
		return "Narrow"
	return "Isolated"

func get_summary() -> Dictionary:
	return {
		"active_routes": _routes.size(),
		"interval_types": ROUTE_INTERVALS.size(),
		"total_trades": get_total_trades(),
		"most_active": get_most_active_route(),
		"avg_trades": get_avg_trades_per_route(),
		"inactive_routes": get_inactive_route_count(),
		"unique_factions": get_unique_faction_count(),
		"most_common_interval": get_most_common_interval(),
		"zero_trade_routes": get_zero_trade_count(),
		"trade_network_health": get_trade_network_health(),
		"route_utilization_pct": get_route_utilization_pct(),
		"diplomatic_reach": get_diplomatic_reach(),
		"commerce_maturity": get_commerce_maturity(),
		"trade_reliability": get_trade_reliability(),
		"economic_connectivity": get_economic_connectivity(),
		"trade_ecosystem_health": get_trade_ecosystem_health(),
		"commerce_governance": get_commerce_governance(),
		"market_maturity_index": get_market_maturity_index(),
	}

func get_commerce_maturity() -> String:
	var total := get_total_trades()
	var routes := _routes.size()
	if total >= 20 and routes >= 3:
		return "Mature"
	elif total >= 5:
		return "Growing"
	return "Nascent"

func get_trade_reliability() -> float:
	var active := _routes.size() - get_inactive_route_count()
	var total := _routes.size()
	if total <= 0:
		return 0.0
	return snapped(float(active) / float(total) * 100.0, 0.1)

func get_economic_connectivity() -> String:
	var factions := get_unique_faction_count()
	if factions >= 5:
		return "Highly Connected"
	elif factions >= 2:
		return "Connected"
	elif factions > 0:
		return "Isolated"
	return "None"

func get_trade_ecosystem_health() -> float:
	var maturity := get_commerce_maturity()
	var m_val: float = 90.0 if maturity in ["Established", "Thriving"] else (60.0 if maturity in ["Growing", "Developing"] else 30.0)
	var reliability := get_trade_reliability()
	var connectivity := get_economic_connectivity()
	var c_val: float = 90.0 if connectivity == "Highly Connected" else (60.0 if connectivity == "Connected" else 30.0)
	return snapped((m_val + reliability + c_val) / 3.0, 0.1)

func get_market_maturity_index() -> float:
	var health := get_trade_network_health()
	var h_val: float = 90.0 if health == "Thriving" else (70.0 if health == "Healthy" else (40.0 if health == "Struggling" else 20.0))
	var utilization := get_route_utilization_pct()
	var reach := get_diplomatic_reach()
	var r_val: float = 90.0 if reach == "Wide" else (60.0 if reach == "Moderate" else 30.0)
	return snapped((h_val + utilization + r_val) / 3.0, 0.1)

func get_commerce_governance() -> String:
	var ecosystem := get_trade_ecosystem_health()
	var maturity := get_market_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _routes.size() > 0:
		return "Nascent"
	return "Dormant"
