extends Node

var _relationships: Dictionary = {}
var _romance_log: Array = []

const ROMANCE_STAGES: Array = ["Stranger", "Acquaintance", "Friend", "Crush", "Lover", "Fiance", "Spouse", "ExLover", "ExSpouse"]

const ATTRACTION_FACTORS: Dictionary = {
	"Beautiful": 0.25, "Pretty": 0.15, "Ugly": -0.20, "Staggeringly_Ugly": -0.40,
	"Kind": 0.10, "Psychopath": -0.15, "Age_Gap_Small": 0.0, "Age_Gap_Large": -0.15
}

const ROMANCE_ACTIONS: Dictionary = {
	"Flirt": {"success_base": 0.35, "stage_required": "Acquaintance", "opinion_gain": 5},
	"Propose_Date": {"success_base": 0.50, "stage_required": "Crush", "opinion_gain": 10},
	"Confess": {"success_base": 0.40, "stage_required": "Friend", "opinion_gain": 15},
	"Propose_Marriage": {"success_base": 0.60, "stage_required": "Lover", "opinion_gain": 30},
	"Break_Up": {"success_base": 1.0, "stage_required": "Lover", "opinion_gain": -40}
}

func set_relationship(pawn_a: int, pawn_b: int, stage: String) -> bool:
	if stage not in ROMANCE_STAGES:
		return false
	var key: String = str(mini(pawn_a, pawn_b)) + "_" + str(maxi(pawn_a, pawn_b))
	_relationships[key] = {"stage": stage, "pawn_a": pawn_a, "pawn_b": pawn_b}
	return true

func get_relationship(pawn_a: int, pawn_b: int) -> String:
	var key: String = str(mini(pawn_a, pawn_b)) + "_" + str(maxi(pawn_a, pawn_b))
	return _relationships.get(key, {}).get("stage", "Stranger")

func attempt_romance(initiator: int, target: int, action: String) -> Dictionary:
	if not ROMANCE_ACTIONS.has(action):
		return {"success": false, "reason": "unknown_action"}
	var act: Dictionary = ROMANCE_ACTIONS[action]
	var success: bool = randf() < act["success_base"]
	_romance_log.append({"initiator": initiator, "target": target, "action": action, "success": success})
	return {"success": success, "opinion_change": act["opinion_gain"] if success else -5}

func get_couples() -> Array:
	var result: Array = []
	for key: String in _relationships:
		var rel: Dictionary = _relationships[key]
		if String(rel.get("stage", "")) in ["Lover", "Fiance", "Spouse"]:
			result.append(rel.duplicate())
	return result


func get_success_rate() -> float:
	if _romance_log.is_empty():
		return 0.0
	var successes: int = 0
	for entry: Dictionary in _romance_log:
		if bool(entry.get("success", false)):
			successes += 1
	return float(successes) / float(_romance_log.size())


func get_stage_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for key: String in _relationships:
		var s: String = String(_relationships[key].get("stage", "Stranger"))
		dist[s] = int(dist.get(s, 0)) + 1
	return dist


func get_most_common_action() -> String:
	var counts: Dictionary = {}
	for entry: Dictionary in _romance_log:
		var a: String = String(entry.get("action", ""))
		counts[a] = counts.get(a, 0) + 1
	var best: String = ""
	var best_count: int = 0
	for a: String in counts:
		if int(counts[a]) > best_count:
			best_count = int(counts[a])
			best = a
	return best


func get_ex_count() -> int:
	var count: int = 0
	for key: String in _relationships:
		var stage: String = String(_relationships[key].get("stage", ""))
		if stage == "ExLover" or stage == "ExSpouse":
			count += 1
	return count


func get_rejection_count() -> int:
	var count: int = 0
	for entry: Dictionary in _romance_log:
		if not bool(entry.get("success", false)):
			count += 1
	return count


func get_spouse_count() -> int:
	var count: int = 0
	for key: String in _relationships:
		if String(_relationships[key].get("stage", "")) == "Spouse":
			count += 1
	return count


func get_unique_initiators() -> int:
	var inits: Dictionary = {}
	for entry: Dictionary in _romance_log:
		inits[int(entry.get("initiator", 0))] = true
	return inits.size()


func get_avg_attempts_per_initiator() -> float:
	var unique: int = get_unique_initiators()
	if unique == 0:
		return 0.0
	return snappedf(float(_romance_log.size()) / float(unique), 0.1)


func get_romantic_climate() -> String:
	var rate: float = get_success_rate()
	if rate >= 0.6:
		return "Passionate"
	elif rate >= 0.35:
		return "Warm"
	elif rate >= 0.15:
		return "Reserved"
	return "Cold"

func get_heartbreak_index() -> String:
	var rej: int = get_rejection_count()
	var ex: int = get_ex_count()
	var total: int = _romance_log.size()
	if total == 0:
		return "N/A"
	var pain: float = float(rej + ex) / float(total)
	if pain >= 0.5:
		return "High"
	elif pain >= 0.25:
		return "Moderate"
	return "Low"

func get_commitment_pct() -> float:
	if _relationships.is_empty():
		return 0.0
	return snappedf(float(get_spouse_count()) / float(_relationships.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"relationship_count": _relationships.size(),
		"romance_log_count": _romance_log.size(),
		"stages": ROMANCE_STAGES.size(),
		"actions": ROMANCE_ACTIONS.size(),
		"couples": get_couples().size(),
		"success_rate": get_success_rate(),
		"most_common_action": get_most_common_action(),
		"ex_count": get_ex_count(),
		"rejections": get_rejection_count(),
		"spouses": get_spouse_count(),
		"unique_initiators": get_unique_initiators(),
		"avg_attempts": get_avg_attempts_per_initiator(),
		"romantic_climate": get_romantic_climate(),
		"heartbreak_index": get_heartbreak_index(),
		"commitment_pct": get_commitment_pct(),
		"love_stability": get_love_stability(),
		"partnership_quality": get_partnership_quality(),
		"emotional_bond_depth": get_emotional_bond_depth(),
		"romantic_ecosystem_health": get_romantic_ecosystem_health(),
		"relational_governance": get_relational_governance(),
		"intimacy_maturity_index": get_intimacy_maturity_index(),
	}

func get_love_stability() -> String:
	var spouses := get_spouse_count()
	var exes := get_ex_count()
	if spouses > 0 and exes == 0:
		return "Rock Solid"
	elif spouses > exes:
		return "Stable"
	elif spouses > 0:
		return "Turbulent"
	return "Unformed"

func get_partnership_quality() -> float:
	var success := get_success_rate()
	var heartbreak: String = get_heartbreak_index()
	var penalty: float = 0.5 if heartbreak == "High" else (0.3 if heartbreak == "Moderate" else 0.1)
	return snapped(success * (1.0 - penalty), 0.01)

func get_emotional_bond_depth() -> String:
	var couples := get_couples().size()
	var relationships := _relationships.size()
	if relationships <= 0:
		return "None"
	var ratio := float(couples) / float(relationships)
	if ratio >= 0.6:
		return "Deep"
	elif ratio >= 0.3:
		return "Moderate"
	return "Shallow"

func get_romantic_ecosystem_health() -> float:
	var success := get_success_rate()
	var stability := get_love_stability()
	var s_val: float = 90.0 if stability == "Rock Solid" else (60.0 if stability == "Stable" else 30.0)
	var quality := get_partnership_quality()
	return snapped((success + s_val + quality * 100.0) / 3.0, 0.1)

func get_relational_governance() -> String:
	var ecosystem := get_romantic_ecosystem_health()
	var bond := get_emotional_bond_depth()
	var b_val: float = 90.0 if bond == "Deep" else (60.0 if bond == "Moderate" else 20.0)
	var combined := (ecosystem + b_val) / 2.0
	if combined >= 70.0:
		return "Harmonious"
	elif combined >= 40.0:
		return "Developing"
	elif _romance_log.size() > 0:
		return "Nascent"
	return "Dormant"

func get_intimacy_maturity_index() -> float:
	var commitment := get_commitment_pct()
	var climate := get_romantic_climate()
	var c_val: float = 90.0 if climate == "Passionate" else (60.0 if climate == "Warm" else 25.0)
	return snapped((commitment + c_val) / 2.0, 0.1)
