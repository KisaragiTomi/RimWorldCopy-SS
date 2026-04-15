extends Node

var _social_memory: Dictionary = {}

const INTERACTION_TYPES: Dictionary = {
	"Chat": {"opinion_per": 2, "max_stacks": 5, "decay_days": 5},
	"DeepTalk": {"opinion_per": 5, "max_stacks": 3, "decay_days": 10},
	"Insult": {"opinion_per": -8, "max_stacks": 5, "decay_days": 15},
	"SlightArgument": {"opinion_per": -3, "max_stacks": 5, "decay_days": 7},
	"HeavyArgument": {"opinion_per": -10, "max_stacks": 3, "decay_days": 20},
	"KindWords": {"opinion_per": 6, "max_stacks": 3, "decay_days": 8},
	"GaveMedicine": {"opinion_per": 10, "max_stacks": 2, "decay_days": 30},
	"SharedMeal": {"opinion_per": 3, "max_stacks": 4, "decay_days": 5},
	"RescuedMe": {"opinion_per": 15, "max_stacks": 2, "decay_days": 60},
	"Backstab": {"opinion_per": -25, "max_stacks": 1, "decay_days": 120}
}

func record_interaction(pawn_a: int, pawn_b: int, interaction: String) -> Dictionary:
	if not INTERACTION_TYPES.has(interaction):
		return {"error": "unknown_interaction"}
	var key: String = "%d_%d" % [pawn_a, pawn_b]
	if not _social_memory.has(key):
		_social_memory[key] = {}
	var current: int = _social_memory[key].get(interaction, 0)
	var limit: int = INTERACTION_TYPES[interaction]["max_stacks"]
	if current < limit:
		_social_memory[key][interaction] = current + 1
	return {"interaction": interaction, "stacks": _social_memory[key][interaction], "max": limit}

func get_opinion_from_memory(pawn_a: int, pawn_b: int) -> float:
	var key: String = "%d_%d" % [pawn_a, pawn_b]
	var total: float = 0.0
	for interaction: String in _social_memory.get(key, {}):
		var stacks: int = _social_memory[key][interaction]
		total += stacks * INTERACTION_TYPES.get(interaction, {}).get("opinion_per", 0)
	return total

func get_positive_interactions() -> Array[String]:
	var result: Array[String] = []
	for it: String in INTERACTION_TYPES:
		if int(INTERACTION_TYPES[it].get("opinion_per", 0)) > 0:
			result.append(it)
	return result


func get_negative_interactions() -> Array[String]:
	var result: Array[String] = []
	for it: String in INTERACTION_TYPES:
		if int(INTERACTION_TYPES[it].get("opinion_per", 0)) < 0:
			result.append(it)
	return result


func get_longest_lasting_interaction() -> String:
	var best: String = ""
	var best_days: int = 0
	for it: String in INTERACTION_TYPES:
		var d: int = int(INTERACTION_TYPES[it].get("decay_days", 0))
		if d > best_days:
			best_days = d
			best = it
	return best


func get_avg_opinion_impact() -> float:
	if INTERACTION_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for it: String in INTERACTION_TYPES:
		total += float(INTERACTION_TYPES[it].get("opinion", 0.0))
	return total / INTERACTION_TYPES.size()


func get_neutral_interactions() -> Array:
	var result: Array = []
	for it: String in INTERACTION_TYPES:
		var op: float = float(INTERACTION_TYPES[it].get("opinion", 0.0))
		if op == 0.0:
			result.append(it)
	return result


func get_unique_pair_count() -> int:
	var pairs: Dictionary = {}
	for key: String in _social_memory:
		pairs[key] = true
	return pairs.size()


func get_strongest_positive_opinion() -> String:
	var best: String = ""
	var best_op: int = 0
	for it: String in INTERACTION_TYPES:
		var op: int = int(INTERACTION_TYPES[it].get("opinion_per", 0))
		if op > best_op:
			best_op = op
			best = it
	return best


func get_strongest_negative_opinion() -> String:
	var worst: String = ""
	var worst_op: int = 0
	for it: String in INTERACTION_TYPES:
		var op: int = int(INTERACTION_TYPES[it].get("opinion_per", 0))
		if op < worst_op:
			worst_op = op
			worst = it
	return worst


func get_avg_decay_days() -> float:
	if INTERACTION_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for it: String in INTERACTION_TYPES:
		total += float(INTERACTION_TYPES[it].get("decay_days", 0))
	return snappedf(total / float(INTERACTION_TYPES.size()), 0.1)


func get_social_climate() -> String:
	var pos: int = get_positive_interactions().size()
	var neg: int = get_negative_interactions().size()
	if pos > neg * 2:
		return "Harmonious"
	elif pos > neg:
		return "Friendly"
	elif pos == neg:
		return "Neutral"
	elif neg > pos * 2:
		return "Hostile"
	return "Tense"

func get_toxicity_pct() -> float:
	var total: int = _social_memory.size()
	if total == 0:
		return 0.0
	return snappedf(float(get_negative_interactions().size()) / float(total) * 100.0, 0.1)

func get_memory_volatility() -> String:
	var avg_decay: float = get_avg_decay_days()
	if avg_decay <= 5.0:
		return "Volatile"
	elif avg_decay <= 15.0:
		return "Moderate"
	elif avg_decay <= 30.0:
		return "Stable"
	return "Persistent"

func get_relationship_depth() -> String:
	var pairs: int = get_unique_pair_count()
	if pairs >= 10:
		return "Complex"
	if pairs >= 5:
		return "Developing"
	return "Shallow"


func get_harmony_index_pct() -> float:
	var pos: int = get_positive_interactions().size()
	var total: int = pos + get_negative_interactions().size() + get_neutral_interactions().size()
	if total == 0:
		return 0.0
	return snappedf(float(pos) / float(total) * 100.0, 0.1)


func get_social_resilience() -> String:
	var vol: String = get_memory_volatility()
	var tox: float = get_toxicity_pct()
	if vol == "Stable" and tox < 20.0:
		return "Resilient"
	if vol == "Volatile" or tox >= 50.0:
		return "Fragile"
	return "Average"


func get_summary() -> Dictionary:
	return {
		"interaction_types": INTERACTION_TYPES.size(),
		"memory_pairs": _social_memory.size(),
		"positive_count": get_positive_interactions().size(),
		"negative_count": get_negative_interactions().size(),
		"avg_opinion": snapped(get_avg_opinion_impact(), 0.1),
		"neutral_count": get_neutral_interactions().size(),
		"unique_pairs": get_unique_pair_count(),
		"strongest_positive": get_strongest_positive_opinion(),
		"strongest_negative": get_strongest_negative_opinion(),
		"avg_decay_days": get_avg_decay_days(),
		"social_climate": get_social_climate(),
		"toxicity_pct": get_toxicity_pct(),
		"memory_volatility": get_memory_volatility(),
		"relationship_depth": get_relationship_depth(),
		"harmony_index_pct": get_harmony_index_pct(),
		"social_resilience": get_social_resilience(),
		"social_ecosystem_health": get_social_ecosystem_health(),
		"community_governance": get_community_governance(),
		"interpersonal_maturity_index": get_interpersonal_maturity_index(),
	}

func get_social_ecosystem_health() -> float:
	var climate := get_social_climate()
	var c_val: float = 90.0 if climate == "Friendly" else (60.0 if climate == "Neutral" else 25.0)
	var harmony := get_harmony_index_pct()
	var resilience := get_social_resilience()
	var r_val: float = 90.0 if resilience == "Resilient" else (60.0 if resilience == "Moderate" else 25.0)
	return snapped((c_val + harmony + r_val) / 3.0, 0.1)

func get_community_governance() -> String:
	var ecosystem := get_social_ecosystem_health()
	var depth := get_relationship_depth()
	var d_val: float = 90.0 if depth == "Complex" else (60.0 if depth == "Moderate" else 25.0)
	var combined := (ecosystem + d_val) / 2.0
	if combined >= 70.0:
		return "Cohesive"
	elif combined >= 40.0:
		return "Functional"
	elif _social_memory.size() > 0:
		return "Fractured"
	return "Isolated"

func get_interpersonal_maturity_index() -> float:
	var toxicity := get_toxicity_pct()
	var harmony := get_harmony_index_pct()
	return snapped(((100.0 - toxicity) + harmony) / 2.0, 0.1)
