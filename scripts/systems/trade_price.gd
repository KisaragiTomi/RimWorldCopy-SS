extends Node

## Dynamic trade pricing that adjusts based on Social skill, faction goodwill,
## and market conditions. Registered as autoload "TradePrice".

const BASE_PRICES: Dictionary = {
	"Steel": 2.0,
	"Wood": 1.2,
	"Silver": 1.0,
	"Gold": 10.0,
	"Plasteel": 9.0,
	"Components": 32.0,
	"RawFood": 0.5,
	"Meal": 2.0,
	"SimpleMeal": 1.5,
	"Medicine": 18.0,
	"HerbalMed": 8.0,
	"Cloth": 1.5,
	"Leather": 2.1,
	"Beer": 2.0,
	"Smokeleaf": 3.0,
	"GoJuice": 50.0,
	"Yayo": 40.0,
	"Penoxycyline": 18.0,
}

const SELL_FACTOR: float = 0.5
const SKILL_BONUS_PER_LEVEL: float = 0.02
const GOODWILL_BONUS_PER_10: float = 0.01


func get_buy_price(item_def: String, trader_social_skill: int, faction_goodwill: float) -> float:
	var base: float = BASE_PRICES.get(item_def, 5.0)
	var skill_discount: float = clampf(trader_social_skill * SKILL_BONUS_PER_LEVEL, 0.0, 0.3)
	var goodwill_discount: float = clampf(faction_goodwill / 10.0 * GOODWILL_BONUS_PER_10, -0.1, 0.15)
	return snappedf(base * (1.0 - skill_discount - goodwill_discount), 0.01)


func get_sell_price(item_def: String, trader_social_skill: int, faction_goodwill: float) -> float:
	var base: float = BASE_PRICES.get(item_def, 5.0) * SELL_FACTOR
	var skill_bonus: float = clampf(trader_social_skill * SKILL_BONUS_PER_LEVEL, 0.0, 0.3)
	var goodwill_bonus: float = clampf(faction_goodwill / 10.0 * GOODWILL_BONUS_PER_10, -0.1, 0.15)
	return snappedf(base * (1.0 + skill_bonus + goodwill_bonus), 0.01)


func get_price_table(trader_social_skill: int, faction_goodwill: float) -> Dictionary:
	var table: Dictionary = {}
	for item: String in BASE_PRICES:
		table[item] = {
			"buy": get_buy_price(item, trader_social_skill, faction_goodwill),
			"sell": get_sell_price(item, trader_social_skill, faction_goodwill),
			"base": BASE_PRICES[item],
		}
	return table


func get_quality_multiplier(quality_level: int) -> float:
	var multipliers: Array[float] = [0.5, 0.65, 1.0, 1.25, 1.5, 2.0, 5.0]
	if quality_level >= 0 and quality_level < multipliers.size():
		return multipliers[quality_level]
	return 1.0


func get_profit_margin(item_def: String, social_skill: int, goodwill: float) -> float:
	var buy := get_buy_price(item_def, social_skill, goodwill)
	var sell := get_sell_price(item_def, social_skill, goodwill)
	if buy <= 0.0:
		return 0.0
	return snappedf(sell / buy, 0.01)


func get_most_profitable(social_skill: int, goodwill: float) -> String:
	var best: String = ""
	var best_margin: float = 0.0
	for item: String in BASE_PRICES:
		var m := get_profit_margin(item, social_skill, goodwill)
		if m > best_margin:
			best_margin = m
			best = item
	return best


func get_total_market_value(social_skill: int, goodwill: float) -> float:
	var total: float = 0.0
	for item: String in BASE_PRICES:
		total += get_buy_price(item, social_skill, goodwill)
	return snappedf(total, 0.01)


func get_items_by_category() -> Dictionary:
	var cats := {
		"raw_materials": ["Steel", "Wood", "Plasteel", "Cloth", "Leather"],
		"food": ["RawFood", "Meal", "SimpleMeal"],
		"medical": ["Medicine", "HerbalMed", "Penoxycyline"],
		"drugs": ["Beer", "Smokeleaf", "GoJuice", "Yayo"],
		"valuables": ["Silver", "Gold", "Components"],
	}
	return cats


func get_cheapest_item() -> String:
	var best: String = ""
	var best_price: float = 99999.0
	for item: String in BASE_PRICES:
		if BASE_PRICES[item] < best_price:
			best_price = BASE_PRICES[item]
			best = item
	return best


func get_most_expensive_item() -> String:
	var best: String = ""
	var best_price: float = 0.0
	for item: String in BASE_PRICES:
		if BASE_PRICES[item] > best_price:
			best_price = BASE_PRICES[item]
			best = item
	return best


func get_category_avg_price() -> Dictionary:
	var cats := get_items_by_category()
	var result: Dictionary = {}
	for cat: String in cats:
		var items: Array = cats[cat]
		var total: float = 0.0
		for item: String in items:
			total += BASE_PRICES.get(item, 0.0)
		result[cat] = snappedf(total / float(items.size()), 0.01) if items.size() > 0 else 0.0
	return result


func get_price_tier() -> String:
	var sum: float = float(BASE_PRICES.values().reduce(func(a: float, b: float) -> float: return a + b, 0.0))
	var avg: float = sum / maxf(float(BASE_PRICES.size()), 1.0)
	if avg >= 80.0:
		return "Premium"
	elif avg >= 40.0:
		return "Standard"
	elif avg > 0.0:
		return "Budget"
	return "None"

func get_high_value_count() -> int:
	var count: int = 0
	for item: String in BASE_PRICES:
		if BASE_PRICES[item] >= 100.0:
			count += 1
	return count

func get_market_diversity() -> float:
	var cats: Dictionary = get_items_by_category()
	if cats.is_empty():
		return 0.0
	var total_items: int = 0
	for c: String in cats:
		total_items += cats[c].size()
	return snappedf(float(total_items) / float(cats.size()), 0.1)

func get_trade_competitiveness() -> String:
	var sum2: float = float(BASE_PRICES.values().reduce(func(a: float, b: float) -> float: return a + b, 0.0))
	var avg2: float = sum2 / maxf(float(BASE_PRICES.size()), 1.0)
	if avg2 >= 80.0:
		return "Premium Market"
	elif avg2 >= 30.0:
		return "Standard"
	return "Budget"

func get_profit_margin_rating() -> String:
	if SELL_FACTOR >= 0.8:
		return "Excellent"
	elif SELL_FACTOR >= 0.5:
		return "Fair"
	return "Poor"

func get_market_maturity() -> String:
	var high := get_high_value_count()
	var diversity := get_market_diversity()
	if high >= 5 and diversity >= 3.0:
		return "Mature"
	elif high >= 2:
		return "Growing"
	return "Nascent"

func get_summary() -> Dictionary:
	return {
		"tracked_items": BASE_PRICES.size(),
		"sell_factor": SELL_FACTOR,
		"skill_bonus_per_level": SKILL_BONUS_PER_LEVEL,
		"categories": get_items_by_category().size(),
		"cheapest": get_cheapest_item(),
		"most_expensive": get_most_expensive_item(),
		"category_avg": get_category_avg_price(),
		"avg_base_price": snappedf(float(BASE_PRICES.values().reduce(func(a: float, b: float) -> float: return a + b, 0.0)) / maxf(float(BASE_PRICES.size()), 1.0), 0.1),
		"price_spread": snappedf(BASE_PRICES.get(get_most_expensive_item(), 0.0) - BASE_PRICES.get(get_cheapest_item(), 0.0), 0.1),
		"price_tier": get_price_tier(),
		"high_value_count": get_high_value_count(),
		"market_diversity": get_market_diversity(),
		"trade_competitiveness": get_trade_competitiveness(),
		"profit_margin_rating": get_profit_margin_rating(),
		"market_maturity": get_market_maturity(),
		"trade_ecosystem_health": get_trade_ecosystem_health(),
		"pricing_sophistication": get_pricing_sophistication(),
		"commercial_viability": get_commercial_viability(),
	}

func get_trade_ecosystem_health() -> float:
	var diversity := get_market_diversity()
	var high_val := float(get_high_value_count())
	var tier_bonus: float = 1.0 if get_price_tier() != "Budget" else 0.5
	return snapped(diversity * high_val * tier_bonus / maxf(float(BASE_PRICES.size()), 1.0) * 100.0, 0.1)

func get_pricing_sophistication() -> float:
	var spread: float = float(BASE_PRICES.get(get_most_expensive_item(), 0.0)) - float(BASE_PRICES.get(get_cheapest_item(), 0.0))
	var avg: float = float(BASE_PRICES.values().reduce(func(a: float, b: float) -> float: return a + b, 0.0)) / maxf(float(BASE_PRICES.size()), 1.0)
	if avg <= 0.0:
		return 0.0
	return snapped(spread / avg * 50.0, 0.1)

func get_commercial_viability() -> String:
	var maturity := get_market_maturity()
	var margin := get_profit_margin_rating()
	if maturity == "Mature" and margin == "Excellent":
		return "Prime"
	elif maturity != "Nascent" and margin != "Poor":
		return "Viable"
	return "Marginal"
