extends Node

var _total_loot_events: int = 0
var _total_items_looted: int = 0
var _loot_by_faction: Dictionary = {}
var _loot_by_item: Dictionary = {}

const LOOT_TABLES: Dictionary = {
	"Pirate": [
		{"item": "Silver", "min": 50, "max": 200},
		{"item": "Steel", "min": 20, "max": 80},
		{"item": "Components", "min": 1, "max": 5},
		{"item": "Medicine", "min": 1, "max": 3},
		{"item": "Beer", "min": 5, "max": 15},
	],
	"Tribe": [
		{"item": "WoodLog", "min": 30, "max": 100},
		{"item": "Pemmican", "min": 20, "max": 50},
		{"item": "Herbal Medicine", "min": 2, "max": 6},
		{"item": "Leather", "min": 10, "max": 30},
		{"item": "Jade", "min": 1, "max": 5},
	],
	"Mechanoid": [
		{"item": "Plasteel", "min": 10, "max": 40},
		{"item": "Components", "min": 3, "max": 10},
		{"item": "Steel", "min": 50, "max": 150},
	],
	"Empire": [
		{"item": "Silver", "min": 100, "max": 500},
		{"item": "Gold", "min": 5, "max": 20},
		{"item": "Glitterworld Medicine", "min": 1, "max": 3},
		{"item": "Components", "min": 2, "max": 8},
	],
}


func generate_loot(faction_type: String, threat_points: float) -> Array[Dictionary]:
	var table: Array = LOOT_TABLES.get(faction_type, LOOT_TABLES.get("Pirate", []))
	var loot: Array[Dictionary] = []
	var scale: float = clampf(threat_points / 100.0, 0.5, 3.0)
	for entry in table:
		if randf() < 0.7:
			var edict: Dictionary = entry if entry is Dictionary else {}
			var min_val: int = int(edict.get("min", 1))
			var max_val: int = int(edict.get("max", 10))
			var amount: int = int(float(randi_range(min_val, max_val)) * scale)
			if amount > 0:
				loot.append({"item": str(edict.get("item", "")), "amount": amount})
	_total_loot_events += 1
	_loot_by_faction[faction_type] = _loot_by_faction.get(faction_type, 0) + 1
	for l: Dictionary in loot:
		_total_items_looted += l.amount
		_loot_by_item[l.item] = _loot_by_item.get(l.item, 0) + l.amount
	if ColonyLog and ColonyLog.has_method("add_entry"):
		ColonyLog.add_entry("Loot", "Generated %d loot items from %s raid." % [loot.size(), faction_type], "info")
	return loot


func get_most_looted_item() -> String:
	var best: String = ""
	var best_count: int = 0
	for item: String in _loot_by_item:
		if _loot_by_item[item] > best_count:
			best_count = _loot_by_item[item]
			best = item
	return best


func get_most_raided_faction() -> String:
	var best: String = ""
	var best_count: int = 0
	for f: String in _loot_by_faction:
		if _loot_by_faction[f] > best_count:
			best_count = _loot_by_faction[f]
			best = f
	return best


func get_avg_items_per_event() -> float:
	if _total_loot_events == 0:
		return 0.0
	return snappedf(float(_total_items_looted) / float(_total_loot_events), 0.1)


func get_unique_items_looted() -> int:
	return _loot_by_item.size()


func get_faction_count() -> int:
	return _loot_by_faction.size()


func get_loot_quality() -> String:
	var avg: float = get_avg_items_per_event()
	if avg >= 5.0:
		return "Rich"
	elif avg >= 2.0:
		return "Standard"
	elif avg > 0.0:
		return "Meager"
	return "None"

func get_faction_coverage() -> float:
	if LOOT_TABLES.is_empty():
		return 0.0
	return snappedf(float(get_faction_count()) / float(LOOT_TABLES.size()) * 100.0, 0.1)

func get_loot_efficiency() -> float:
	if _total_loot_events <= 0:
		return 0.0
	return snappedf(float(_total_items_looted) / float(_total_loot_events), 0.1)

func get_summary() -> Dictionary:
	return {
		"faction_loot_tables": LOOT_TABLES.size(),
		"total_loot_events": _total_loot_events,
		"total_items_looted": _total_items_looted,
		"loot_by_faction": _loot_by_faction.duplicate(),
		"loot_by_item": _loot_by_item.duplicate(),
		"most_looted_item": get_most_looted_item(),
		"most_raided_faction": get_most_raided_faction(),
		"avg_items_per_event": get_avg_items_per_event(),
		"unique_items": get_unique_items_looted(),
		"active_factions": get_faction_count(),
		"items_per_faction": snappedf(float(_total_items_looted) / maxf(float(get_faction_count()), 1.0), 0.1),
		"loot_diversity": _loot_by_item.size(),
		"loot_quality": get_loot_quality(),
		"faction_coverage_pct": get_faction_coverage(),
		"loot_efficiency": get_loot_efficiency(),
		"expedition_return_rate": get_expedition_return_rate(),
		"loot_value_rating": get_loot_value_rating(),
		"risk_reward_ratio": get_risk_reward_ratio(),
		"plunder_ecosystem_health": get_plunder_ecosystem_health(),
		"acquisition_mastery": get_acquisition_mastery(),
		"fortune_trajectory": get_fortune_trajectory(),
	}

func get_plunder_ecosystem_health() -> float:
	var diversity := float(_loot_by_item.size())
	var coverage := get_faction_coverage()
	return snapped((diversity * 5.0 + coverage) / 2.0, 0.1)

func get_acquisition_mastery() -> String:
	var value := get_loot_value_rating()
	var efficiency := get_loot_efficiency()
	if value in ["Premium", "Valuable"] and efficiency >= 3.0:
		return "Expert"
	elif value == "Junk":
		return "Novice"
	return "Competent"

func get_fortune_trajectory() -> float:
	var return_rate := get_expedition_return_rate()
	var factions := float(get_faction_count())
	return snapped(return_rate * factions / maxf(float(_total_loot_events), 1.0) * 10.0, 0.1)

func get_expedition_return_rate() -> float:
	if _total_loot_events <= 0:
		return 0.0
	return snapped(float(_total_items_looted) / float(_total_loot_events), 0.1)

func get_loot_value_rating() -> String:
	var quality := get_loot_quality()
	var diversity := _loot_by_item.size()
	if quality in ["Excellent", "Good"] and diversity >= 5:
		return "Premium"
	elif quality in ["Excellent", "Good"]:
		return "Valuable"
	elif diversity >= 3:
		return "Standard"
	return "Meager"

func get_risk_reward_ratio() -> String:
	var avg := get_avg_items_per_event()
	var quality := get_loot_quality()
	if avg >= 3.0 and quality in ["Excellent", "Good"]:
		return "Favorable"
	elif avg >= 1.5:
		return "Balanced"
	return "Unfavorable"
