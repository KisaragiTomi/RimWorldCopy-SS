extends Node

var _pending_rewards: Array = []

const REWARD_TYPES: Dictionary = {
	"Silver": {"min": 200, "max": 2000, "weight": 30},
	"Gold": {"min": 10, "max": 100, "weight": 10},
	"Components": {"min": 5, "max": 30, "weight": 15},
	"Weapon": {"min": 1, "max": 3, "weight": 10},
	"Apparel": {"min": 1, "max": 5, "weight": 12},
	"Medicine": {"min": 5, "max": 25, "weight": 15},
	"GoodwillBoost": {"min": 10, "max": 40, "weight": 20},
	"PsylinkNeuroformer": {"min": 1, "max": 1, "weight": 3},
	"RoyalFavor": {"min": 1, "max": 8, "weight": 8},
	"TechPrint": {"min": 1, "max": 2, "weight": 5}
}

const QUEST_TIERS: Dictionary = {
	"Trivial": {"reward_mult": 0.3, "max_rewards": 1},
	"Small": {"reward_mult": 0.6, "max_rewards": 2},
	"Medium": {"reward_mult": 1.0, "max_rewards": 3},
	"Large": {"reward_mult": 1.5, "max_rewards": 4},
	"Grand": {"reward_mult": 2.5, "max_rewards": 5}
}

func generate_reward(tier: String) -> Dictionary:
	if not QUEST_TIERS.has(tier):
		return {"error": "unknown_tier"}
	var info: Dictionary = QUEST_TIERS[tier]
	var rewards: Array = []
	var count: int = randi_range(1, info["max_rewards"])
	var keys: Array = REWARD_TYPES.keys()
	for i: int in range(count):
		var rtype: String = keys[randi() % keys.size()]
		var rinfo: Dictionary = REWARD_TYPES[rtype]
		var amount: int = int(randi_range(rinfo["min"], rinfo["max"]) * info["reward_mult"])
		rewards.append({"type": rtype, "amount": maxi(1, amount)})
	var result: Dictionary = {"tier": tier, "rewards": rewards}
	_pending_rewards.append(result)
	return result

func claim_reward(index: int) -> Dictionary:
	if index < 0 or index >= _pending_rewards.size():
		return {"error": "invalid_index"}
	var reward: Dictionary = _pending_rewards[index]
	_pending_rewards.remove_at(index)
	return {"claimed": reward}

func get_rarest_reward() -> String:
	var best: String = ""
	var lowest: int = 9999
	for r: String in REWARD_TYPES:
		var w: int = int(REWARD_TYPES[r].get("weight", 9999))
		if w < lowest:
			lowest = w
			best = r
	return best


func get_most_common_reward() -> String:
	var best: String = ""
	var highest: int = 0
	for r: String in REWARD_TYPES:
		var w: int = int(REWARD_TYPES[r].get("weight", 0))
		if w > highest:
			highest = w
			best = r
	return best


func get_highest_tier() -> String:
	var best: String = ""
	var best_mult: float = 0.0
	for t: String in QUEST_TIERS:
		var m: float = float(QUEST_TIERS[t].get("reward_mult", 0.0))
		if m > best_mult:
			best_mult = m
			best = t
	return best


func get_avg_reward_weight() -> float:
	if REWARD_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for rt: String in REWARD_TYPES:
		total += float(REWARD_TYPES[rt].get("weight", 0))
	return total / REWARD_TYPES.size()


func get_highest_weight_reward() -> String:
	var best: String = ""
	var best_weight: int = 0
	for rt: String in REWARD_TYPES:
		var w: int = int(REWARD_TYPES[rt].get("weight", 0))
		if w > best_weight:
			best_weight = w
			best = rt
	return best


func get_total_pending_value() -> int:
	var total: int = 0
	for r: Dictionary in _pending_rewards:
		total += int(r.get("amount", 0))
	return total


func get_unique_reward_types_pending() -> int:
	var types: Dictionary = {}
	for r: Dictionary in _pending_rewards:
		for rw in r.get("rewards", []):
			if rw is Dictionary:
				types[String(rw.get("type", ""))] = true
	return types.size()


func get_lowest_tier() -> String:
	var best: String = ""
	var best_mult: float = 999.0
	for t: String in QUEST_TIERS:
		var m: float = float(QUEST_TIERS[t].get("reward_mult", 999.0))
		if m < best_mult:
			best_mult = m
			best = t
	return best


func get_total_weight() -> int:
	var total: int = 0
	for rt: String in REWARD_TYPES:
		total += int(REWARD_TYPES[rt].get("weight", 0))
	return total


func get_reward_richness() -> String:
	var unique: int = get_unique_reward_types_pending()
	var total: int = REWARD_TYPES.size()
	if total == 0:
		return "Empty"
	var ratio: float = float(unique) / float(total)
	if ratio >= 0.6:
		return "Abundant"
	if ratio >= 0.3:
		return "Moderate"
	return "Scarce"


func get_value_concentration_pct() -> float:
	var pending: float = float(get_total_pending_value())
	var weight: float = get_total_weight()
	if weight <= 0.0:
		return 0.0
	return snappedf(pending / weight * 10.0, 0.1)


func get_tier_balance() -> String:
	var highest: String = get_highest_tier()
	var lowest: String = get_lowest_tier()
	if highest == lowest:
		return "Uniform"
	var tier_keys: Array = QUEST_TIERS.keys()
	var h_idx: int = tier_keys.find(highest)
	var l_idx: int = tier_keys.find(lowest)
	if absi(h_idx - l_idx) >= 3:
		return "WideRange"
	return "Balanced"


func get_summary() -> Dictionary:
	return {
		"reward_types": REWARD_TYPES.size(),
		"quest_tiers": QUEST_TIERS.size(),
		"pending_rewards": _pending_rewards.size(),
		"rarest": get_rarest_reward(),
		"highest_tier": get_highest_tier(),
		"avg_weight": snapped(get_avg_reward_weight(), 0.1),
		"most_common": get_highest_weight_reward(),
		"pending_value": get_total_pending_value(),
		"unique_pending_types": get_unique_reward_types_pending(),
		"lowest_tier": get_lowest_tier(),
		"total_weight": get_total_weight(),
		"reward_richness": get_reward_richness(),
		"value_concentration_pct": get_value_concentration_pct(),
		"tier_balance": get_tier_balance(),
		"quest_profitability": get_quest_profitability(),
		"reward_diversity_score": get_reward_diversity_score(),
		"loot_expectation": get_loot_expectation(),
		"reward_ecosystem_health": get_reward_ecosystem_health(),
		"quest_governance": get_quest_governance(),
		"bounty_maturity_index": get_bounty_maturity_index(),
	}

func get_quest_profitability() -> String:
	var pending := get_total_pending_value()
	if pending >= 5000:
		return "Lucrative"
	elif pending >= 1000:
		return "Worthwhile"
	elif pending > 0:
		return "Modest"
	return "None Pending"

func get_reward_diversity_score() -> float:
	var unique := get_unique_reward_types_pending()
	var total := REWARD_TYPES.size()
	if total <= 0:
		return 0.0
	return snapped(float(unique) / float(total) * 100.0, 0.1)

func get_loot_expectation() -> String:
	var richness := get_reward_richness()
	var balance := get_tier_balance()
	if richness in ["Bountiful", "Rich"] and balance in ["Balanced", "Even"]:
		return "Excellent"
	elif richness in ["Moderate", "Bountiful"]:
		return "Good"
	return "Sparse"

func get_reward_ecosystem_health() -> float:
	var profitability := get_quest_profitability()
	var p_val: float = 90.0 if profitability == "Lucrative" else (60.0 if profitability == "Profitable" else 25.0)
	var diversity := get_reward_diversity_score()
	var loot := get_loot_expectation()
	var l_val: float = 90.0 if loot == "Excellent" else (60.0 if loot == "Good" else 25.0)
	return snapped((p_val + diversity + l_val) / 3.0, 0.1)

func get_quest_governance() -> String:
	var ecosystem := get_reward_ecosystem_health()
	var balance := get_tier_balance()
	var b_val: float = 90.0 if balance in ["Balanced", "Even"] else (60.0 if balance == "Moderate" else 25.0)
	var combined := (ecosystem + b_val) / 2.0
	if combined >= 70.0:
		return "Bountiful"
	elif combined >= 40.0:
		return "Adequate"
	elif _pending_rewards.size() > 0:
		return "Meager"
	return "Barren"

func get_bounty_maturity_index() -> float:
	var concentration := get_value_concentration_pct()
	var richness := get_reward_richness()
	var r_val: float = 90.0 if richness in ["Bountiful", "Rich"] else (60.0 if richness == "Moderate" else 25.0)
	return snapped(((100.0 - concentration) + r_val) / 2.0, 0.1)
