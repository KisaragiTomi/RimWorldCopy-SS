extends Node

## Random events that occur during caravan travel: ambushes, discoveries,
## and weather hazards. Registered as autoload "CaravanEvents".

const EVENT_DEFS: Dictionary = {
	"Ambush": {
		"label": "Ambush!",
		"chance": 0.12,
		"severity": "danger",
		"min_travel_ticks": 500,
		"description": "A group of bandits ambushes the caravan!",
	},
	"TreasureFind": {
		"label": "Treasure Found",
		"chance": 0.08,
		"severity": "positive",
		"min_travel_ticks": 300,
		"description": "The caravan discovers abandoned supplies on the road.",
	},
	"AnimalAttack": {
		"label": "Animal Attack",
		"chance": 0.06,
		"severity": "warning",
		"min_travel_ticks": 400,
		"description": "Wild predators attack the caravan!",
	},
	"BadWeather": {
		"label": "Severe Weather",
		"chance": 0.10,
		"severity": "warning",
		"min_travel_ticks": 200,
		"description": "A severe storm slows the caravan's progress.",
	},
	"FriendlyTrader": {
		"label": "Friendly Trader",
		"chance": 0.07,
		"severity": "positive",
		"min_travel_ticks": 300,
		"description": "A friendly trader offers goods at a discount.",
	},
	"BrokenWheel": {
		"label": "Broken Equipment",
		"chance": 0.05,
		"severity": "warning",
		"min_travel_ticks": 100,
		"description": "Equipment breaks down, delaying the caravan.",
	},
}

var _event_log: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _total_events: int = 0
var _events_by_type: Dictionary = {}
var _total_silver_gained: int = 0
var _total_items_lost: int = 0


func _ready() -> void:
	_rng.seed = 77
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func _on_rare_tick(_tick: int) -> void:
	if not CaravanManager:
		return
	for caravan: Dictionary in CaravanManager.caravans:
		if caravan.get("state", "") == "Traveling":
			_try_event(caravan)


func _try_event(caravan: Dictionary) -> void:
	for etype: String in EVENT_DEFS:
		var def: Dictionary = EVENT_DEFS[etype]
		if _rng.randf() > def.chance:
			continue
		_fire_event(caravan, etype, def)
		return


func _fire_event(caravan: Dictionary, etype: String, def: Dictionary) -> void:
	var cid: int = caravan.get("id", -1)
	_total_events += 1
	_events_by_type[etype] = _events_by_type.get(etype, 0) + 1

	var result := _resolve_event(caravan, etype)

	var entry := {
		"caravan_id": cid,
		"event_type": etype,
		"label": def.label,
		"description": def.description,
		"outcome": result.get("outcome", ""),
		"tick": TickManager.current_tick if TickManager else 0,
	}
	_event_log.append(entry)
	if _event_log.size() > 100:
		_event_log = _event_log.slice(-50)

	if ColonyLog:
		ColonyLog.add_entry("Caravan", "Caravan #" + str(cid) + ": " + def.label + " - " + result.get("outcome", ""), def.severity)


func _resolve_event(caravan: Dictionary, etype: String) -> Dictionary:
	match etype:
		"Ambush":
			var pawn_count: int = caravan.get("pawns", []).size()
			var survive_chance: float = clampf(pawn_count * 0.25, 0.1, 0.9)
			if _rng.randf() < survive_chance:
				return {"outcome": "Fought off the bandits with minor injuries."}
			else:
				var lost := _lose_items(caravan, 0.4)
				_total_items_lost += lost
				return {"outcome": "Lost %d items to bandits!" % lost}

		"TreasureFind":
			var silver_amount := _rng.randi_range(30, 80)
			_total_silver_gained += silver_amount
			var bonus_items := [{"def": "Silver", "count": silver_amount}]
			var items: Array = caravan.get("items", [])
			for bi: Dictionary in bonus_items:
				var found := false
				for entry: Dictionary in items:
					if entry.get("def", "") == bi.def:
						entry["count"] = entry.get("count", 0) + bi.count
						found = true
						break
				if not found:
					items.append(bi)
			return {"outcome": "Found " + str(bonus_items[0].count) + " Silver!"}

		"AnimalAttack":
			var fight_roll := _rng.randf()
			if fight_roll < 0.7:
				return {"outcome": "Drove off the animals with no losses."}
			return {"outcome": "Minor injuries sustained from animal attack."}

		"BadWeather":
			return {"outcome": "Storm slowed travel, adding delay."}

		"FriendlyTrader":
			var silver_gain := _rng.randi_range(10, 40)
			_total_silver_gained += silver_gain
			var items: Array = caravan.get("items", [])
			for entry: Dictionary in items:
				if entry.get("def", "") == "Silver":
					entry["count"] = entry.get("count", 0) + silver_gain
					return {"outcome": "Traded for " + str(silver_gain) + " extra Silver."}
			items.append({"def": "Silver", "count": silver_gain})
			return {"outcome": "Received " + str(silver_gain) + " Silver from trader."}

		"BrokenWheel":
			return {"outcome": "Repaired equipment, minor delay."}

	return {"outcome": "Event resolved."}


func _lose_items(caravan: Dictionary, fraction: float) -> int:
	var items: Array = caravan.get("items", [])
	var total_lost: int = 0
	for entry: Dictionary in items:
		var loss := int(float(entry.get("count", 0)) * fraction)
		entry["count"] = maxi(0, entry.get("count", 0) - loss)
		total_lost += loss
	caravan["items"] = items.filter(func(e: Dictionary) -> bool: return e.get("count", 0) > 0)
	return total_lost


func get_events_for_caravan(caravan_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for e: Dictionary in _event_log:
		if e.get("caravan_id", -1) == caravan_id:
			result.append(e)
	return result


func get_most_common_event() -> String:
	var best: String = ""
	var best_count: int = 0
	for t: String in _events_by_type:
		if _events_by_type[t] > best_count:
			best_count = _events_by_type[t]
			best = t
	return best


func get_danger_event_count() -> int:
	var count: int = 0
	for t: String in ["Ambush", "AnimalAttack"]:
		count += _events_by_type.get(t, 0)
	return count


func get_survival_rate() -> float:
	var ambush_count: int = _events_by_type.get("Ambush", 0)
	if ambush_count == 0:
		return 1.0
	var losses: int = 0
	for e: Dictionary in _event_log:
		if e.get("event_type", "") == "Ambush" and "Lost" in e.get("outcome", ""):
			losses += 1
	return snappedf(1.0 - float(losses) / float(ambush_count), 0.01)


func get_avg_silver_per_event() -> float:
	if _total_events == 0:
		return 0.0
	return snappedf(float(_total_silver_gained) / float(_total_events), 0.1)


func get_positive_event_count() -> int:
	var count: int = 0
	for etype: String in EVENT_DEFS:
		if EVENT_DEFS[etype].get("severity", "") == "positive":
			count += _events_by_type.get(etype, 0)
	return count


func get_event_type_count() -> int:
	return _events_by_type.size()


func get_net_silver() -> int:
	return _total_silver_gained - _total_items_lost


func get_danger_ratio() -> float:
	if _total_events <= 0:
		return 0.0
	return snappedf(float(get_danger_event_count()) / float(_total_events) * 100.0, 0.1)

func get_profit_per_event() -> float:
	if _total_events <= 0:
		return 0.0
	return snappedf(float(get_net_silver()) / float(_total_events), 0.1)

func get_event_luck() -> String:
	var pos: int = get_positive_event_count()
	var danger: int = get_danger_event_count()
	if pos > danger * 2:
		return "Lucky"
	elif pos > danger:
		return "Favorable"
	elif pos == danger:
		return "Neutral"
	return "Unlucky"

func get_trade_route_value() -> float:
	if _total_events <= 0:
		return 0.0
	return snapped(float(_total_silver_gained) / float(_total_events), 0.1)

func get_expedition_readiness() -> String:
	var survival := get_survival_rate()
	var luck := get_event_luck()
	if survival >= 90.0 and (luck == "Lucky" or luck == "Favorable"):
		return "Well Prepared"
	elif survival >= 70.0:
		return "Adequate"
	return "Risky"

func get_risk_reward_ratio() -> String:
	var profit := get_profit_per_event()
	var danger := get_danger_ratio()
	if profit > 100.0 and danger < 30.0:
		return "Excellent"
	elif profit > 0.0 and danger < 50.0:
		return "Favorable"
	elif profit <= 0.0:
		return "Unprofitable"
	return "High Risk"

func get_summary() -> Dictionary:
	return {
		"total_events": _total_events,
		"by_type": _events_by_type.duplicate(),
		"total_silver_gained": _total_silver_gained,
		"total_items_lost": _total_items_lost,
		"most_common": get_most_common_event(),
		"danger_events": get_danger_event_count(),
		"recent_events": _event_log.slice(-5),
		"survival_rate": get_survival_rate(),
		"avg_silver": get_avg_silver_per_event(),
		"positive_events": get_positive_event_count(),
		"event_types": get_event_type_count(),
		"net_silver": get_net_silver(),
		"danger_ratio_pct": get_danger_ratio(),
		"profit_per_event": get_profit_per_event(),
		"event_luck": get_event_luck(),
		"trade_route_value": get_trade_route_value(),
		"expedition_readiness": get_expedition_readiness(),
		"risk_reward_ratio": get_risk_reward_ratio(),
		"caravan_fortune_index": get_caravan_fortune_index(),
		"trade_network_maturity": get_trade_network_maturity(),
		"expedition_profit_trajectory": get_expedition_profit_trajectory(),
	}

func get_caravan_fortune_index() -> float:
	var luck: String = get_event_luck()
	var survival: float = get_survival_rate()
	var base: float = survival * 0.7
	if luck == "Lucky":
		base += 30.0
	elif luck == "Average":
		base += 15.0
	return snappedf(clampf(base, 0.0, 100.0), 0.1)

func get_trade_network_maturity() -> String:
	var events: int = _total_events
	var types: int = get_event_type_count()
	if events >= 20 and types >= 5:
		return "Established"
	if events >= 8:
		return "Growing"
	if events >= 2:
		return "Nascent"
	return "None"

func get_expedition_profit_trajectory() -> String:
	var net: float = get_net_silver()
	var profit: float = get_profit_per_event()
	if net > 0.0 and profit > 0.0:
		return "Profitable"
	if net >= 0.0:
		return "Breaking Even"
	return "Losing"
