extends Node

var enabled: bool = false

const SELL_EXCESS_THRESHOLD: Dictionary = {
	"Steel": 200,
	"Wood": 300,
	"Silver": 0,
	"Cloth": 100,
	"Leather": 80,
	"Beer": 20,
	"Smokeleaf": 10,
}

const BUY_SHORTFALL: Dictionary = {
	"Medicine": {"min_stock": 10, "buy_amount": 5},
	"Component": {"min_stock": 5, "buy_amount": 3},
	"Steel": {"min_stock": 50, "buy_amount": 30},
	"RawFood": {"min_stock": 100, "buy_amount": 50},
}

var _total_sold: int = 0
var _total_bought: int = 0
var _total_profit: float = 0.0
var _trade_rounds: int = 0
var _trade_history: Array[Dictionary] = []
const MAX_HISTORY: int = 20


func toggle_auto_trade() -> bool:
	enabled = not enabled
	return enabled


func try_auto_trade(trader_social_skill: int, faction_goodwill: float) -> Dictionary:
	if not enabled:
		return {"message": "Auto-trade is disabled."}
	if not ResourceCounter or not TradeManager or not TradePrice:
		return {"message": "Required managers not available."}
	var sold_items: Array[Dictionary] = []
	var bought_items: Array[Dictionary] = []
	for item_def: String in SELL_EXCESS_THRESHOLD:
		var threshold: int = SELL_EXCESS_THRESHOLD[item_def]
		var current: int = ResourceCounter.get_resource_count(item_def)
		if current > threshold:
			var sell_amount: int = current - threshold
			var price: float = TradePrice.get_sell_price(item_def, trader_social_skill, faction_goodwill)
			var revenue: float = price * float(sell_amount)
			TradeManager.colony_silver += int(revenue)
			_total_sold += sell_amount
			_total_profit += revenue
			sold_items.append({"def": item_def, "amount": sell_amount, "revenue": snappedf(revenue, 0.01)})
	for item_def: String in BUY_SHORTFALL:
		var policy: Dictionary = BUY_SHORTFALL[item_def]
		var current: int = ResourceCounter.get_resource_count(item_def)
		if current < policy.min_stock:
			var buy_amount: int = policy.buy_amount
			var price: float = TradePrice.get_buy_price(item_def, trader_social_skill, faction_goodwill)
			var cost: float = price * float(buy_amount)
			if float(TradeManager.colony_silver) >= cost:
				TradeManager.colony_silver -= int(cost)
				_total_bought += buy_amount
				_total_profit -= cost
				bought_items.append({"def": item_def, "amount": buy_amount, "cost": snappedf(cost, 0.01)})
	if sold_items.size() > 0 or bought_items.size() > 0:
		_trade_rounds += 1
		var round_profit: float = 0.0
		for s: Dictionary in sold_items:
			round_profit += s.revenue
		for b: Dictionary in bought_items:
			round_profit -= b.cost
		_trade_history.append({"round": _trade_rounds, "sold": sold_items.size(), "bought": bought_items.size(), "profit": snappedf(round_profit, 0.01)})
		if _trade_history.size() > MAX_HISTORY:
			_trade_history.pop_front()
		if ColonyLog and ColonyLog.has_method("add_entry"):
			ColonyLog.add_entry("Trade", "Auto-trade #" + str(_trade_rounds) + ": sold " + str(sold_items.size()) + " types, bought " + str(bought_items.size()) + " types.", "info")
	return {
		"sold": sold_items,
		"bought": bought_items,
		"net_profit": snappedf(_total_profit, 0.01),
	}


func get_shortfall_items() -> Array[String]:
	var result: Array[String] = []
	if not ResourceCounter:
		return result
	for item_def: String in BUY_SHORTFALL:
		var policy: Dictionary = BUY_SHORTFALL[item_def]
		var current: int = ResourceCounter.get_resource_count(item_def)
		if current < policy.min_stock:
			result.append(item_def)
	return result


func get_excess_items() -> Array[String]:
	var result: Array[String] = []
	if not ResourceCounter:
		return result
	for item_def: String in SELL_EXCESS_THRESHOLD:
		var threshold: int = SELL_EXCESS_THRESHOLD[item_def]
		if threshold == 0:
			continue
		var current: int = ResourceCounter.get_resource_count(item_def)
		if current > threshold:
			result.append(item_def)
	return result


func get_trade_history() -> Array[Dictionary]:
	return _trade_history.duplicate()


func get_avg_profit_per_round() -> float:
	if _trade_rounds == 0:
		return 0.0
	return snappedf(_total_profit / float(_trade_rounds), 0.01)


func get_total_transactions() -> int:
	return _total_sold + _total_bought


func is_profitable() -> bool:
	return _total_profit > 0.0


func get_trade_health() -> String:
	if not enabled:
		return "Disabled"
	if is_profitable():
		return "Profitable"
	elif _trade_rounds > 0:
		return "Losing"
	return "Idle"

func get_trade_volume() -> String:
	var txn: int = get_total_transactions()
	if txn >= 50:
		return "High"
	elif txn >= 20:
		return "Moderate"
	elif txn > 0:
		return "Low"
	return "None"

func get_supply_balance() -> float:
	var shortfall: int = get_shortfall_items().size()
	var excess: int = get_excess_items().size()
	var total: int = shortfall + excess
	if total <= 0:
		return 100.0
	return snappedf(float(excess) / float(total) * 100.0, 0.1)

func get_trade_efficiency() -> float:
	if _trade_rounds <= 0:
		return 0.0
	var profit_ratio := _total_profit / maxf(float(_total_sold + _total_bought), 1.0)
	return snapped(profit_ratio * 100.0, 0.1)

func get_supply_demand_match() -> String:
	var balance := get_supply_balance()
	var shortfall := get_shortfall_items().size()
	if shortfall == 0 and balance >= 80.0:
		return "Well Matched"
	elif shortfall <= 2:
		return "Mostly Matched"
	return "Mismatched"

func get_profit_optimization() -> String:
	var avg := get_avg_profit_per_round()
	var health := get_trade_health()
	if health == "Profitable" and avg >= 50.0:
		return "Optimal"
	elif health == "Profitable":
		return "Adequate"
	elif health == "Losing":
		return "Needs Review"
	return "Inactive"

func get_summary() -> Dictionary:
	return {
		"enabled": enabled,
		"total_sold": _total_sold,
		"total_bought": _total_bought,
		"net_profit": snappedf(_total_profit, 0.01),
		"trade_rounds": _trade_rounds,
		"shortfall_items": get_shortfall_items(),
		"excess_items": get_excess_items(),
		"avg_profit_per_round": get_avg_profit_per_round(),
		"total_transactions": get_total_transactions(),
		"profitable": is_profitable(),
		"items_per_round": snappedf(float(get_total_transactions()) / maxf(float(_trade_rounds), 1.0), 0.1),
		"shortfall_count": get_shortfall_items().size(),
		"trade_health": get_trade_health(),
		"trade_volume": get_trade_volume(),
		"supply_balance_pct": get_supply_balance(),
		"trade_efficiency": get_trade_efficiency(),
		"supply_demand_match": get_supply_demand_match(),
		"profit_optimization": get_profit_optimization(),
		"trade_automation_maturity": get_trade_automation_maturity(),
		"commerce_reliability": get_commerce_reliability(),
		"economic_autopilot_score": get_economic_autopilot_score(),
	}

func get_trade_automation_maturity() -> float:
	if _trade_rounds <= 0:
		return 0.0
	var efficiency := get_trade_efficiency()
	var rounds := float(_trade_rounds)
	return snapped(minf(efficiency * rounds / 10.0, 100.0), 0.1)

func get_commerce_reliability() -> String:
	var health := get_trade_health()
	var match_status := get_supply_demand_match()
	if health == "Profitable" and match_status == "Well Matched":
		return "Dependable"
	elif health == "Losing":
		return "Unreliable"
	return "Moderate"

func get_economic_autopilot_score() -> float:
	var balance := get_supply_balance()
	var efficiency := get_trade_efficiency()
	return snapped((balance * 0.4 + efficiency * 0.6), 0.1)
