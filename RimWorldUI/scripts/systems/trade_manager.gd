extends Node

## Trade system: trader visits, inventory, buy/sell.
## Registered as autoload "TradeManager".

signal trader_arrived(trader_name: String, goods: Array)
signal trader_left(trader_name: String)
signal trade_completed(item: String, quantity: int, silver_change: int)

var active_trader: Dictionary = {}
var colony_silver: int = 200
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = randi()
	if IncidentManager:
		IncidentManager.incident_fired.connect(_on_incident)


func _on_incident(incident_name: String, _data: Dictionary) -> void:
	if incident_name == "ResourceDrop" and _rng.randf() < 0.3:
		spawn_trader()


func spawn_trader() -> void:
	if not active_trader.is_empty():
		return
	var names := ["Silver Caravan", "Tribal Merchants", "Outlander Traders", "Pirate Smugglers"]
	var goods: Array[Dictionary] = _generate_goods()
	active_trader = {
		"name": names[_rng.randi_range(0, names.size() - 1)],
		"goods": goods,
		"leave_tick": (TickManager.current_tick if TickManager else 0) + _rng.randi_range(10000, 25000),
	}
	trader_arrived.emit(active_trader.name, goods)


const GOODS_TEMPLATES: Array[Dictionary] = [
	{"item": "Steel", "price": 2, "min_qty": 50, "max_qty": 200, "chance": 0.7},
	{"item": "Wood", "price": 1, "min_qty": 100, "max_qty": 300, "chance": 0.7},
	{"item": "Components", "price": 25, "min_qty": 5, "max_qty": 20, "chance": 0.5},
	{"item": "Medicine", "price": 18, "min_qty": 5, "max_qty": 15, "chance": 0.4},
	{"item": "Food", "price": 1, "min_qty": 50, "max_qty": 150, "chance": 0.8},
	{"item": "Silver", "price": 1, "min_qty": 100, "max_qty": 500, "chance": 0.3},
	{"item": "AdvancedComponents", "price": 60, "min_qty": 1, "max_qty": 5, "chance": 0.2},
	{"item": "Gold", "price": 10, "min_qty": 5, "max_qty": 30, "chance": 0.25},
	{"item": "Plasteel", "price": 9, "min_qty": 10, "max_qty": 50, "chance": 0.2},
	{"item": "Cloth", "price": 2, "min_qty": 30, "max_qty": 100, "chance": 0.5},
	{"item": "Leather", "price": 3, "min_qty": 20, "max_qty": 80, "chance": 0.4},
	{"item": "HerbalMedicine", "price": 8, "min_qty": 10, "max_qty": 30, "chance": 0.5},
	{"item": "Revolver", "price": 45, "min_qty": 1, "max_qty": 3, "chance": 0.15},
	{"item": "Rifle", "price": 80, "min_qty": 1, "max_qty": 2, "chance": 0.1},
	{"item": "FlakVest", "price": 120, "min_qty": 1, "max_qty": 2, "chance": 0.1},
]

func _generate_goods() -> Array[Dictionary]:
	var goods: Array[Dictionary] = []
	for t: Dictionary in GOODS_TEMPLATES:
		if _rng.randf() < t.get("chance", 0.5):
			goods.append({
				"item": t.item,
				"price": t.price,
				"quantity": _rng.randi_range(t.min_qty, t.max_qty),
			})
	return goods


func get_trader_goods() -> Array[Dictionary]:
	if active_trader.is_empty():
		return []
	return active_trader.get("goods", []) as Array[Dictionary]


func get_trade_balance() -> int:
	var spent: int = 0
	var earned: int = 0
	for t: Dictionary in trade_history:
		if t["action"] == "buy":
			spent += t["silver"]
		else:
			earned += t["silver"]
	return earned - spent


var trade_history: Array[Dictionary] = []
var total_bought: int = 0
var total_sold: int = 0


func _get_price_factor() -> float:
	if not PawnManager:
		return 1.0
	var best_social: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed:
			continue
		if p.has_meta("faction") and p.get_meta("faction") == "enemy":
			continue
		var skill: int = p.get_skill_level("Social")
		if skill > best_social:
			best_social = skill
	return maxf(0.8, 1.0 - best_social * 0.02)


func buy_item(item_name: String, quantity: int) -> Dictionary:
	if active_trader.is_empty():
		return {"success": false, "reason": "no_trader"}

	var goods: Array = active_trader.goods
	var price_factor: float = _get_price_factor()
	for g: Dictionary in goods:
		if g.item == item_name:
			var available: int = mini(quantity, g.quantity)
			var unit_cost: int = maxi(1, roundi(float(g.price) * price_factor))
			var cost: int = available * unit_cost
			if cost > colony_silver:
				available = colony_silver / unit_cost
				cost = available * unit_cost
			if available <= 0:
				return {"success": false, "reason": "no_silver"}
			g["quantity"] = g.quantity - available
			colony_silver -= cost
			total_bought += available

			if ThingManager:
				var map: MapData = GameState.get_map() if GameState else null
				if map:
					var drop := Vector2i(map.width / 2, map.height / 2)
					var item := Item.new(item_name)
					item.stack_count = available
					item.grid_pos = drop
					ThingManager.spawn_thing(item, drop)

			_log_trade("buy", item_name, available, cost)
			trade_completed.emit(item_name, available, -cost)
			return {"success": true, "bought": available, "cost": cost, "silver_left": colony_silver}

	return {"success": false, "reason": "item_not_found"}


func sell_item(item_name: String, quantity: int, sell_price: int) -> Dictionary:
	if active_trader.is_empty():
		return {"success": false, "reason": "no_trader"}

	var price_factor: float = 2.0 - _get_price_factor()
	var revenue: int = roundi(float(quantity) * maxf(1.0, float(sell_price) / 2.0) * price_factor)
	colony_silver += revenue
	total_sold += quantity
	_log_trade("sell", item_name, quantity, revenue)
	trade_completed.emit(item_name, -quantity, revenue)
	return {"success": true, "sold": quantity, "revenue": revenue, "silver_left": colony_silver}


func _log_trade(action: String, item_name: String, qty: int, silver: int) -> void:
	trade_history.append({
		"action": action, "item": item_name, "quantity": qty, "silver": silver,
		"tick": TickManager.current_tick if TickManager else 0,
	})
	if trade_history.size() > 100:
		trade_history.pop_front()
	if ColonyLog:
		if action == "buy":
			ColonyLog.add_entry("Trade", "Bought %d %s for %d silver." % [qty, item_name, silver], "info")
		else:
			ColonyLog.add_entry("Trade", "Sold %d %s for %d silver." % [qty, item_name, silver], "info")


func check_trader_leave() -> void:
	if active_trader.is_empty():
		return
	var current_tick: int = TickManager.current_tick if TickManager else 0
	if current_tick >= active_trader.get("leave_tick", 0):
		var trader_name: String = active_trader.get("name", "Unknown")
		active_trader = {}
		trader_left.emit(trader_name)


func get_avg_goods_price() -> float:
	var total: float = 0.0
	if GOODS_TEMPLATES.is_empty():
		return 0.0
	for g: Dictionary in GOODS_TEMPLATES:
		total += float(g.get("price", 0))
	return snappedf(total / float(GOODS_TEMPLATES.size()), 0.01)

func get_rare_goods_count() -> int:
	var count: int = 0
	for g: Dictionary in GOODS_TEMPLATES:
		if g.get("chance", 0.0) <= 0.2:
			count += 1
	return count

func get_trade_profit() -> int:
	return get_trade_balance()

func get_most_expensive_good() -> String:
	var best: String = ""
	var best_p: int = 0
	for g: Dictionary in GOODS_TEMPLATES:
		var p: int = g.get("price", 0)
		if p > best_p:
			best_p = p
			best = g.get("item", "")
	return best

func get_cheapest_good_template() -> String:
	var best: String = ""
	var best_p: int = 999999
	for g: Dictionary in GOODS_TEMPLATES:
		var p: int = g.get("price", 999999)
		if p < best_p:
			best_p = p
			best = g.get("item", "")
	return best

func get_weapon_goods_count() -> int:
	var weapons: Array[String] = ["Revolver", "Rifle", "Knife", "Longsword", "Mace", "Spear", "SniperRifle", "MachineGun", "ShortBow"]
	var count: int = 0
	for g: Dictionary in GOODS_TEMPLATES:
		if g.get("item", "") in weapons:
			count += 1
	return count

func get_market_accessibility() -> float:
	var accessible := 0
	for g in GOODS_TEMPLATES:
		if g.get("chance", 0.0) >= 0.4:
			accessible += 1
	return snapped(float(accessible) / maxf(GOODS_TEMPLATES.size(), 1.0) * 100.0, 0.1)

func get_trade_velocity() -> float:
	var total_tx := total_bought + total_sold
	return snapped(float(total_tx) / maxf(trade_history.size(), 1.0), 0.01)

func get_price_spread() -> int:
	var lo := 999999
	var hi := 0
	for g in GOODS_TEMPLATES:
		var p: int = g.get("price", 0)
		lo = mini(lo, p)
		hi = maxi(hi, p)
	return hi - lo

func get_summary() -> Dictionary:
	return {
		"has_trader": not active_trader.is_empty(),
		"trader_name": active_trader.get("name", ""),
		"goods_count": active_trader.get("goods", []).size(),
		"colony_silver": colony_silver,
		"total_bought": total_bought,
		"total_sold": total_sold,
		"trade_history_count": trade_history.size(),
		"avg_goods_price": get_avg_goods_price(),
		"rare_goods": get_rare_goods_count(),
		"trade_balance": get_trade_balance(),
		"most_expensive_good": get_most_expensive_good(),
		"cheapest_good": get_cheapest_good_template(),
		"weapon_goods": get_weapon_goods_count(),
		"market_accessibility": get_market_accessibility(),
		"trade_velocity": get_trade_velocity(),
		"price_spread": get_price_spread(),
		"commerce_ecosystem_health": get_commerce_ecosystem_health(),
		"trade_governance": get_trade_governance(),
		"mercantile_maturity_index": get_mercantile_maturity_index(),
	}

func get_commerce_ecosystem_health() -> float:
	var accessibility := get_market_accessibility()
	var velocity := get_trade_velocity()
	var balance := get_trade_balance()
	var b_val: float = minf(maxf(float(balance) / 100.0, 0.0), 100.0)
	return snapped((accessibility + minf(velocity * 10.0, 100.0) + b_val) / 3.0, 0.1)

func get_mercantile_maturity_index() -> float:
	var rare := get_rare_goods_count()
	var r_val: float = minf(float(rare) * 20.0, 100.0)
	var weapons := get_weapon_goods_count()
	var w_val: float = minf(float(weapons) * 15.0, 100.0)
	var history := trade_history.size()
	var h_val: float = minf(float(history) * 10.0, 100.0)
	return snapped((r_val + w_val + h_val) / 3.0, 0.1)

func get_trade_governance() -> String:
	var ecosystem := get_commerce_ecosystem_health()
	var maturity := get_mercantile_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif not active_trader.is_empty():
		return "Nascent"
	return "Dormant"
