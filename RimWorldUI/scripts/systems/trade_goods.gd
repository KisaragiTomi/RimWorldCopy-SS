extends Node

const TRADE_GOODS: Dictionary = {
	"Silver": {"base_price": 1.0, "category": "Currency", "rarity": 1.0},
	"Gold": {"base_price": 10.0, "category": "Currency", "rarity": 0.3},
	"Steel": {"base_price": 1.9, "category": "Material", "rarity": 0.9},
	"Plasteel": {"base_price": 9.0, "category": "Material", "rarity": 0.2},
	"Uranium": {"base_price": 6.0, "category": "Material", "rarity": 0.15},
	"ComponentIndustrial": {"base_price": 32.0, "category": "Component", "rarity": 0.5},
	"ComponentSpacer": {"base_price": 200.0, "category": "Component", "rarity": 0.1},
	"MealSimple": {"base_price": 15.0, "category": "Food", "rarity": 0.8},
	"MealFine": {"base_price": 20.0, "category": "Food", "rarity": 0.6},
	"MealLavish": {"base_price": 40.0, "category": "Food", "rarity": 0.3},
	"Pemmican": {"base_price": 16.0, "category": "Food", "rarity": 0.7},
	"MedicineHerbal": {"base_price": 10.0, "category": "Medicine", "rarity": 0.7},
	"MedicineIndustrial": {"base_price": 18.0, "category": "Medicine", "rarity": 0.4},
	"Glitterworld": {"base_price": 50.0, "category": "Medicine", "rarity": 0.08},
	"Devilstrand": {"base_price": 5.5, "category": "Textile", "rarity": 0.25},
	"Hyperweave": {"base_price": 15.0, "category": "Textile", "rarity": 0.05},
	"Synthread": {"base_price": 5.0, "category": "Textile", "rarity": 0.4},
	"Beer": {"base_price": 12.0, "category": "Drug", "rarity": 0.6},
	"Smokeleaf": {"base_price": 11.0, "category": "Drug", "rarity": 0.5},
	"Flake": {"base_price": 14.0, "category": "Drug", "rarity": 0.3}
}

const PRICE_FACTORS: Dictionary = {
	"demand_high": 1.5,
	"demand_low": 0.7,
	"seasonal": 1.2,
	"war_time": 1.8,
	"surplus": 0.5
}

func get_price(item: String, factors: Array) -> float:
	if not TRADE_GOODS.has(item):
		return 0.0
	var price: float = TRADE_GOODS[item]["base_price"]
	for f: String in factors:
		price *= PRICE_FACTORS.get(f, 1.0)
	return snappedf(price, 0.1)

func get_most_valuable_good() -> String:
	var best: String = ""
	var best_p: float = 0.0
	for g: String in TRADE_GOODS:
		if TRADE_GOODS[g]["base_price"] > best_p:
			best_p = TRADE_GOODS[g]["base_price"]
			best = g
	return best

func get_rarest_good() -> String:
	var best: String = ""
	var min_r: float = 999.0
	for g: String in TRADE_GOODS:
		if TRADE_GOODS[g]["rarity"] < min_r:
			min_r = TRADE_GOODS[g]["rarity"]
			best = g
	return best

func get_goods_by_category(category: String) -> Array[String]:
	var result: Array[String] = []
	for g: String in TRADE_GOODS:
		if TRADE_GOODS[g]["category"] == category:
			result.append(g)
	return result

func get_avg_base_price() -> float:
	if TRADE_GOODS.is_empty():
		return 0.0
	var total: float = 0.0
	for g: String in TRADE_GOODS:
		total += float(TRADE_GOODS[g].get("base_price", 0.0))
	return total / TRADE_GOODS.size()

func get_unique_trade_categories() -> int:
	var cats: Dictionary = {}
	for g: String in TRADE_GOODS:
		cats[String(TRADE_GOODS[g].get("category", ""))] = true
	return cats.size()

func get_common_goods_count() -> int:
	var count: int = 0
	for g: String in TRADE_GOODS:
		if float(TRADE_GOODS[g].get("rarity", 0.0)) >= 0.7:
			count += 1
	return count

func get_rare_goods_count() -> int:
	var count: int = 0
	for g: String in TRADE_GOODS:
		if float(TRADE_GOODS[g].get("rarity", 1.0)) <= 0.1:
			count += 1
	return count


func get_cheapest_good() -> String:
	var best: String = ""
	var best_p: float = 999999.0
	for g: String in TRADE_GOODS:
		var p: float = float(TRADE_GOODS[g].get("base_price", 999999.0))
		if p < best_p:
			best_p = p
			best = g
	return best


func get_drug_count() -> int:
	var count: int = 0
	for g: String in TRADE_GOODS:
		if String(TRADE_GOODS[g].get("category", "")) == "Drug":
			count += 1
	return count


func get_market_depth() -> String:
	var cats: int = get_unique_trade_categories()
	if cats >= 6:
		return "deep"
	if cats >= 3:
		return "moderate"
	return "shallow"

func get_price_volatility_pct() -> float:
	if TRADE_GOODS.is_empty():
		return 0.0
	var min_p: float = INF
	var max_p: float = 0.0
	for g: String in TRADE_GOODS:
		var p: float = TRADE_GOODS[g]["base_price"]
		if p < min_p:
			min_p = p
		if p > max_p:
			max_p = p
	if max_p <= 0.0:
		return 0.0
	return snapped((max_p - min_p) * 100.0 / max_p, 0.1)

func get_accessibility_rating() -> String:
	var common: int = get_common_goods_count()
	var total: int = TRADE_GOODS.size()
	if total == 0:
		return "none"
	var ratio: float = common * 1.0 / total
	if ratio >= 0.6:
		return "easily_available"
	if ratio >= 0.3:
		return "mixed"
	return "scarce"

func get_summary() -> Dictionary:
	return {
		"goods_count": TRADE_GOODS.size(),
		"price_factors": PRICE_FACTORS.size(),
		"most_valuable": get_most_valuable_good(),
		"rarest": get_rarest_good(),
		"avg_price": snapped(get_avg_base_price(), 0.1),
		"trade_categories": get_unique_trade_categories(),
		"common_goods": get_common_goods_count(),
		"rare_goods": get_rare_goods_count(),
		"cheapest": get_cheapest_good(),
		"drug_count": get_drug_count(),
		"market_depth": get_market_depth(),
		"price_volatility_pct": get_price_volatility_pct(),
		"accessibility_rating": get_accessibility_rating(),
		"trade_profitability": get_trade_profitability(),
		"commodity_diversity_score": get_commodity_diversity_score(),
		"market_health_index": get_market_health_index(),
		"trade_ecosystem_health": get_trade_ecosystem_health(),
		"market_governance": get_market_governance(),
		"commercial_maturity_index": get_commercial_maturity_index(),
	}

func get_trade_profitability() -> String:
	var avg := get_avg_base_price()
	var rare := get_rare_goods_count()
	if avg >= 100.0 and rare >= 3:
		return "Highly Profitable"
	elif avg >= 50.0:
		return "Profitable"
	return "Marginal"

func get_commodity_diversity_score() -> float:
	var categories := get_unique_trade_categories()
	var total := TRADE_GOODS.size()
	if total <= 0:
		return 0.0
	return snapped(float(categories) / float(total) * 100.0, 0.1)

func get_market_health_index() -> String:
	var depth := get_market_depth()
	var volatility := get_price_volatility_pct()
	if depth in ["Deep", "Vast"] and volatility <= 30.0:
		return "Robust"
	elif depth in ["Moderate", "Deep"]:
		return "Healthy"
	return "Fragile"

func get_trade_ecosystem_health() -> float:
	var profitability := get_trade_profitability()
	var p_val: float = 90.0 if profitability == "Highly Profitable" else (60.0 if profitability == "Profitable" else 30.0)
	var health := get_market_health_index()
	var h_val: float = 90.0 if health == "Robust" else (60.0 if health == "Healthy" else 30.0)
	var diversity := get_commodity_diversity_score()
	return snapped((p_val + h_val + diversity) / 3.0, 0.1)

func get_commercial_maturity_index() -> float:
	var depth := get_market_depth()
	var d_val: float = 90.0 if depth in ["deep", "vast"] else (60.0 if depth in ["moderate", "growing"] else 30.0)
	var accessibility := get_accessibility_rating()
	var a_val: float = 90.0 if accessibility in ["open", "accessible"] else (60.0 if accessibility in ["moderate", "limited"] else 30.0)
	var volatility := get_price_volatility_pct()
	var v_val: float = maxf(100.0 - volatility, 0.0)
	return snapped((d_val + a_val + v_val) / 3.0, 0.1)

func get_market_governance() -> String:
	var ecosystem := get_trade_ecosystem_health()
	var maturity := get_commercial_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif TRADE_GOODS.size() > 0:
		return "Nascent"
	return "Dormant"
