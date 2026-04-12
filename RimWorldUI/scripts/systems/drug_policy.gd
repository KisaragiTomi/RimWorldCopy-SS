extends Node

const POLICIES: Dictionary = {
	"NoDrugs": {"allowed": [], "desc": "No drug use allowed"},
	"SocialOnly": {"allowed": ["Beer", "SmokeleafJoint"], "desc": "Social drugs only"},
	"MedicalOnly": {"allowed": ["Penoxycyline", "GoJuice", "WakeUp"], "desc": "Medical/combat drugs only"},
	"Unrestricted": {"allowed": ["Beer", "SmokeleafJoint", "Penoxycyline", "GoJuice", "WakeUp", "Flake", "Yayo"], "desc": "All drugs allowed"},
}

const DRUG_SCHEDULE: Dictionary = {
	"Beer": {"mood_threshold": 0.3, "frequency_hours": 24, "max_per_day": 2},
	"SmokeleafJoint": {"mood_threshold": 0.25, "frequency_hours": 48, "max_per_day": 1},
	"Penoxycyline": {"mood_threshold": -1.0, "frequency_hours": 120, "max_per_day": 1},
	"GoJuice": {"mood_threshold": -1.0, "frequency_hours": 0, "max_per_day": 0},
	"WakeUp": {"mood_threshold": -1.0, "frequency_hours": 0, "max_per_day": 0},
	"Flake": {"mood_threshold": 0.2, "frequency_hours": 24, "max_per_day": 1},
	"Yayo": {"mood_threshold": 0.2, "frequency_hours": 48, "max_per_day": 1},
}

var _pawn_policies: Dictionary = {}


func assign_policy(pawn_id: int, policy_name: String) -> bool:
	if not POLICIES.has(policy_name):
		return false
	_pawn_policies[pawn_id] = policy_name
	return true


func get_policy(pawn_id: int) -> String:
	return _pawn_policies.get(pawn_id, "SocialOnly")


func can_take_drug(pawn_id: int, drug_id: String) -> Dictionary:
	var policy_name: String = get_policy(pawn_id)
	var policy: Dictionary = POLICIES.get(policy_name, {})
	var allowed: Array = policy.get("allowed", [])
	if not allowed.has(drug_id):
		return {"allowed": false, "reason": "Policy " + policy_name + " forbids " + drug_id}
	var schedule: Dictionary = DRUG_SCHEDULE.get(drug_id, {})
	var mood_thresh: float = float(schedule.get("mood_threshold", -1.0))
	return {"allowed": true, "mood_threshold": mood_thresh}


func get_policy_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pid: int in _pawn_policies:
		var p: String = _pawn_policies[pid]
		dist[p] = dist.get(p, 0) + 1
	return dist


func get_allowed_drugs_for(pawn_id: int) -> Array:
	var policy_name: String = get_policy(pawn_id)
	var policy: Dictionary = POLICIES.get(policy_name, {})
	return policy.get("allowed", [])


func batch_assign_policy(pawn_ids: Array, policy_name: String) -> int:
	var count: int = 0
	for pid in pawn_ids:
		if assign_policy(int(pid), policy_name):
			count += 1
	return count


func get_most_common_policy() -> String:
	var dist := get_policy_distribution()
	var best: String = ""
	var best_n: int = 0
	for p: String in dist:
		if dist[p] > best_n:
			best_n = dist[p]
			best = p
	return best


func get_unassigned_count() -> int:
	if not PawnManager:
		return 0
	var total: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead and not _pawn_policies.has(p.pawn_id if "pawn_id" in p else 0):
			total += 1
	return total


func get_restrictive_policy_count() -> int:
	var count: int = 0
	for pname: String in POLICIES:
		var allowed: Array = POLICIES[pname].get("allowed", [])
		if allowed.size() <= 1:
			count += 1
	return count


func get_control_level() -> String:
	var restrictive_pct: float = float(get_restrictive_policy_count()) / maxf(float(POLICIES.size()), 1.0) * 100.0
	if restrictive_pct >= 60.0:
		return "Strict"
	elif restrictive_pct >= 30.0:
		return "Moderate"
	elif restrictive_pct > 0.0:
		return "Permissive"
	return "Unregulated"

func get_compliance_pct() -> float:
	var total: int = _pawn_policies.size() + get_unassigned_count()
	if total <= 0:
		return 0.0
	return snappedf(float(_pawn_policies.size()) / float(total) * 100.0, 0.1)

func get_policy_health() -> String:
	var unassigned: int = get_unassigned_count()
	if unassigned == 0:
		return "Complete"
	elif unassigned <= 2:
		return "Good"
	return "Gaps"

func get_summary() -> Dictionary:
	return {
		"policy_count": POLICIES.size(),
		"drug_count": DRUG_SCHEDULE.size(),
		"assigned_pawns": _pawn_policies.size(),
		"distribution": get_policy_distribution(),
		"most_common": get_most_common_policy(),
		"unassigned": get_unassigned_count(),
		"restrictive_policies": get_restrictive_policy_count(),
		"assigned_pct": snappedf(float(_pawn_policies.size()) / maxf(float(_pawn_policies.size() + get_unassigned_count()), 1.0) * 100.0, 0.1),
		"restrictive_pct": snappedf(float(get_restrictive_policy_count()) / maxf(float(POLICIES.size()), 1.0) * 100.0, 0.1),
		"control_level": get_control_level(),
		"compliance_pct": get_compliance_pct(),
		"policy_health": get_policy_health(),
		"substance_governance": get_substance_governance(),
		"colony_sobriety_index": get_colony_sobriety_index(),
		"pharmaceutical_strategy": get_pharmaceutical_strategy(),
		"regulatory_ecosystem_health": get_regulatory_ecosystem_health(),
		"harm_reduction_index": get_harm_reduction_index(),
		"pharmacological_maturity": get_pharmacological_maturity(),
	}

func get_regulatory_ecosystem_health() -> float:
	var compliance := get_compliance_pct()
	var restrictive := float(get_restrictive_policy_count())
	var total := float(POLICIES.size())
	if total <= 0.0:
		return 0.0
	return snapped(compliance * (restrictive / total + 0.5), 0.1)

func get_harm_reduction_index() -> float:
	var sobriety := get_colony_sobriety_index()
	return snapped(sobriety, 0.1)

func get_pharmacological_maturity() -> String:
	var governance := get_substance_governance()
	var strategy := get_pharmaceutical_strategy()
	if governance == "Strict" and strategy in ["Conservative", "Balanced"]:
		return "Mature"
	elif governance == "Lax":
		return "Undeveloped"
	return "Developing"

func get_substance_governance() -> String:
	var control := get_control_level()
	var restrictive := get_restrictive_policy_count()
	if control in ["Strict", "High"] and restrictive >= 2:
		return "Well Governed"
	elif control in ["Moderate"]:
		return "Moderate Control"
	return "Lax"

func get_colony_sobriety_index() -> float:
	var compliance := get_compliance_pct()
	return snapped(compliance, 0.1)

func get_pharmaceutical_strategy() -> String:
	var restrictive := get_restrictive_policy_count()
	var total := POLICIES.size()
	if total <= 0:
		return "No Policy"
	if float(restrictive) / float(total) >= 0.5:
		return "Medical-Focused"
	return "Mixed Use"
