extends Node

var _gift_history: Array = []

const GIFT_VALUES: Dictionary = {
	"Silver": {"value_per": 1.0, "goodwill_per_100": 12},
	"Gold": {"value_per": 10.0, "goodwill_per_100": 12},
	"Plasteel": {"value_per": 9.0, "goodwill_per_100": 12},
	"ComponentIndustrial": {"value_per": 32.0, "goodwill_per_100": 12},
	"MedicineIndustrial": {"value_per": 18.0, "goodwill_per_100": 15},
	"GlitterworldMedicine": {"value_per": 50.0, "goodwill_per_100": 15},
	"Luciferium": {"value_per": 120.0, "goodwill_per_100": 10},
	"Weapon": {"value_per": 100.0, "goodwill_per_100": 10},
	"Apparel": {"value_per": 50.0, "goodwill_per_100": 10}
}

const DIMINISHING_FACTOR: float = 0.8

func send_gift(faction_id: String, item_type: String, quantity: int) -> Dictionary:
	if not GIFT_VALUES.has(item_type):
		return {"error": "unknown_item"}
	var info: Dictionary = GIFT_VALUES[item_type]
	var total_value: float = info["value_per"] * quantity
	var goodwill_gain: float = (total_value / 100.0) * info["goodwill_per_100"]
	var prev_gifts: int = 0
	for g: Dictionary in _gift_history:
		if g["faction"] == faction_id:
			prev_gifts += 1
	goodwill_gain *= pow(DIMINISHING_FACTOR, prev_gifts)
	_gift_history.append({"faction": faction_id, "item": item_type, "quantity": quantity, "goodwill": goodwill_gain})
	return {"goodwill_gain": goodwill_gain, "total_value": total_value}

func get_gift_count(faction_id: String) -> int:
	var count: int = 0
	for g: Dictionary in _gift_history:
		if g["faction"] == faction_id:
			count += 1
	return count

func get_total_goodwill_earned() -> float:
	var total: float = 0.0
	for g: Dictionary in _gift_history:
		total += float(g.get("goodwill", 0.0))
	return total


func get_most_gifted_faction() -> String:
	var counts: Dictionary = {}
	for g: Dictionary in _gift_history:
		var f: String = String(g.get("faction", ""))
		counts[f] = int(counts.get(f, 0)) + 1
	var best: String = ""
	var best_c: int = 0
	for f: String in counts:
		if int(counts[f]) > best_c:
			best_c = int(counts[f])
			best = f
	return best


func get_most_valuable_gift_type() -> String:
	var best: String = ""
	var best_val: float = 0.0
	for item: String in GIFT_VALUES:
		var v: float = float(GIFT_VALUES[item].get("value_per", 0.0))
		if v > best_val:
			best_val = v
			best = item
	return best


func get_avg_goodwill_per_gift() -> float:
	if _gift_history.is_empty():
		return 0.0
	return get_total_goodwill_earned() / _gift_history.size()


func get_unique_faction_count() -> int:
	var factions: Dictionary = {}
	for g: Dictionary in _gift_history:
		factions[String(g.get("faction", ""))] = true
	return factions.size()


func get_most_gifted_item() -> String:
	var counts: Dictionary = {}
	for g: Dictionary in _gift_history:
		var item: String = String(g.get("item", ""))
		counts[item] = counts.get(item, 0) + 1
	var best: String = ""
	var best_count: int = 0
	for item: String in counts:
		if int(counts[item]) > best_count:
			best_count = int(counts[item])
			best = item
	return best


func get_total_quantity_sent() -> int:
	var total: int = 0
	for g: Dictionary in _gift_history:
		total += int(g.get("quantity", 0))
	return total


func get_highest_goodwill_rate_item() -> String:
	var best: String = ""
	var best_rate: int = 0
	for item: String in GIFT_VALUES:
		var r: int = int(GIFT_VALUES[item].get("goodwill_per_100", 0))
		if r > best_rate:
			best_rate = r
			best = item
	return best


func get_unique_items_gifted() -> int:
	var items: Dictionary = {}
	for g: Dictionary in _gift_history:
		items[String(g.get("item", ""))] = true
	return items.size()


func get_diplomacy_effectiveness() -> String:
	var avg: float = get_avg_goodwill_per_gift()
	if avg >= 20.0:
		return "Excellent"
	elif avg >= 10.0:
		return "Good"
	elif avg >= 5.0:
		return "Fair"
	return "Ineffective"

func get_generosity_index() -> String:
	if _gift_history.is_empty():
		return "N/A"
	var qty: int = get_total_quantity_sent()
	if qty >= 50:
		return "Lavish"
	elif qty >= 20:
		return "Generous"
	elif qty >= 5:
		return "Modest"
	return "Frugal"

func get_faction_coverage_pct() -> float:
	var unique: int = get_unique_faction_count()
	if unique == 0:
		return 0.0
	return snappedf(float(get_unique_items_gifted()) / float(GIFT_VALUES.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"gift_item_types": GIFT_VALUES.size(),
		"total_gifts_sent": _gift_history.size(),
		"total_goodwill": get_total_goodwill_earned(),
		"most_gifted_faction": get_most_gifted_faction(),
		"avg_goodwill": snapped(get_avg_goodwill_per_gift(), 0.1),
		"unique_factions": get_unique_faction_count(),
		"most_gifted_item": get_most_gifted_item(),
		"total_quantity": get_total_quantity_sent(),
		"best_goodwill_item": get_highest_goodwill_rate_item(),
		"unique_items_gifted": get_unique_items_gifted(),
		"diplomacy_effectiveness": get_diplomacy_effectiveness(),
		"generosity_index": get_generosity_index(),
		"faction_coverage_pct": get_faction_coverage_pct(),
		"goodwill_roi": get_goodwill_roi(),
		"diplomatic_investment": get_diplomatic_investment(),
		"alliance_building_pace": get_alliance_building_pace(),
		"gift_ecosystem_health": get_gift_ecosystem_health(),
		"diplomatic_maturity_index": get_diplomatic_maturity_index(),
		"goodwill_governance": get_goodwill_governance(),
	}

func get_goodwill_roi() -> float:
	var goodwill := get_total_goodwill_earned()
	var gifts := _gift_history.size()
	if gifts <= 0:
		return 0.0
	return snapped(float(goodwill) / float(gifts), 0.1)

func get_diplomatic_investment() -> String:
	var total := get_total_quantity_sent()
	if total >= 50:
		return "Heavy"
	elif total >= 20:
		return "Moderate"
	elif total > 0:
		return "Light"
	return "None"

func get_alliance_building_pace() -> String:
	var factions := get_unique_faction_count()
	var gifts := _gift_history.size()
	if factions >= 3 and gifts >= 10:
		return "Rapid"
	elif factions > 0:
		return "Steady"
	return "Stagnant"

func get_gift_ecosystem_health() -> float:
	var roi := get_goodwill_roi()
	var coverage := get_faction_coverage_pct()
	var effectiveness := get_diplomacy_effectiveness()
	var e_val: float = 90.0 if effectiveness == "Masterful" else (70.0 if effectiveness == "Effective" else 30.0)
	return snapped((roi + coverage + e_val) / 3.0, 0.1)

func get_diplomatic_maturity_index() -> float:
	var investment := get_diplomatic_investment()
	var pace := get_alliance_building_pace()
	var i_val: float = 90.0 if investment == "Heavy" else (60.0 if investment == "Moderate" else 20.0)
	var p_val: float = 90.0 if pace == "Rapid" else (60.0 if pace == "Steady" else 20.0)
	return snapped((i_val + p_val + get_faction_coverage_pct()) / 3.0, 0.1)

func get_goodwill_governance() -> String:
	var ecosystem := get_gift_ecosystem_health()
	var maturity := get_diplomatic_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _gift_history.size() > 0:
		return "Nascent"
	return "Dormant"
