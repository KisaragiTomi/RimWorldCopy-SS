extends Node

## Colony-wide policies: drug, outfit, food restrictions per pawn.
## Registered as autoload "ColonyPolicy".

const DEFAULT_DRUG_POLICY: Dictionary = {
	"Beer": {"allowed": true, "max_per_day": 2},
	"Smokeleaf": {"allowed": true, "max_per_day": 1},
	"Penoxycyline": {"allowed": true, "max_per_day": 1},
	"GoJuice": {"allowed": false, "max_per_day": 0},
	"Yayo": {"allowed": false, "max_per_day": 0},
}

const DEFAULT_FOOD_POLICY: Dictionary = {
	"allow_raw": false,
	"allow_human_meat": false,
	"allow_insect_meat": false,
	"prefer_fine_meal": true,
	"nutrient_paste_ok": true,
}

const DEFAULT_OUTFIT_POLICY: Dictionary = {
	"allow_tainted": false,
	"min_quality": 1,  # 0=Awful, 1=Poor, 2=Normal...
	"prefer_armor": false,
}

const DRUG_TEMPLATES: Dictionary = {
	"NoDrugs": {"Beer": {"allowed": false, "max_per_day": 0}, "Smokeleaf": {"allowed": false, "max_per_day": 0}, "Penoxycyline": {"allowed": true, "max_per_day": 1}, "GoJuice": {"allowed": false, "max_per_day": 0}, "Yayo": {"allowed": false, "max_per_day": 0}},
	"SocialOnly": {"Beer": {"allowed": true, "max_per_day": 2}, "Smokeleaf": {"allowed": true, "max_per_day": 1}, "Penoxycyline": {"allowed": true, "max_per_day": 1}, "GoJuice": {"allowed": false, "max_per_day": 0}, "Yayo": {"allowed": false, "max_per_day": 0}},
	"Unrestricted": {"Beer": {"allowed": true, "max_per_day": 4}, "Smokeleaf": {"allowed": true, "max_per_day": 3}, "Penoxycyline": {"allowed": true, "max_per_day": 1}, "GoJuice": {"allowed": true, "max_per_day": 1}, "Yayo": {"allowed": true, "max_per_day": 1}},
}

const OUTFIT_TEMPLATES: Dictionary = {
	"Soldier": {"allow_tainted": false, "min_quality": 2, "prefer_armor": true},
	"Worker": {"allow_tainted": false, "min_quality": 1, "prefer_armor": false},
	"Nudist": {"allow_tainted": true, "min_quality": 0, "prefer_armor": false},
}

var drug_policies: Dictionary = {}   # pawn_id -> drug_policy
var food_policies: Dictionary = {}   # pawn_id -> food_policy
var outfit_policies: Dictionary = {} # pawn_id -> outfit_policy


func set_drug_policy(pawn_id: int, policy: Dictionary) -> void:
	drug_policies[pawn_id] = policy


func get_drug_policy(pawn_id: int) -> Dictionary:
	return drug_policies.get(pawn_id, DEFAULT_DRUG_POLICY.duplicate(true))


func is_drug_allowed(pawn_id: int, drug_name: String) -> bool:
	var policy: Dictionary = get_drug_policy(pawn_id)
	if not policy.has(drug_name):
		return false
	return policy[drug_name].get("allowed", false)


func get_drug_max_per_day(pawn_id: int, drug_name: String) -> int:
	var policy: Dictionary = get_drug_policy(pawn_id)
	if not policy.has(drug_name):
		return 0
	return int(policy[drug_name].get("max_per_day", 0))


func set_food_policy(pawn_id: int, policy: Dictionary) -> void:
	food_policies[pawn_id] = policy


func get_food_policy(pawn_id: int) -> Dictionary:
	return food_policies.get(pawn_id, DEFAULT_FOOD_POLICY.duplicate())


func is_food_allowed(pawn_id: int, food_def: String) -> bool:
	var policy: Dictionary = get_food_policy(pawn_id)
	match food_def:
		"RawFood":
			return policy.get("allow_raw", false)
		"HumanMeat":
			return policy.get("allow_human_meat", false)
		"InsectMeat":
			return policy.get("allow_insect_meat", false)
		"NutrientPaste":
			return policy.get("nutrient_paste_ok", true)
	return true


func set_outfit_policy(pawn_id: int, policy: Dictionary) -> void:
	outfit_policies[pawn_id] = policy


func get_outfit_policy(pawn_id: int) -> Dictionary:
	return outfit_policies.get(pawn_id, DEFAULT_OUTFIT_POLICY.duplicate())


func is_apparel_acceptable(pawn_id: int, quality_level: int, tainted: bool) -> bool:
	var policy: Dictionary = get_outfit_policy(pawn_id)
	if tainted and not policy.get("allow_tainted", false):
		return false
	if quality_level < policy.get("min_quality", 1):
		return false
	return true


func apply_defaults_to_pawn(pawn_id: int) -> void:
	if not drug_policies.has(pawn_id):
		drug_policies[pawn_id] = DEFAULT_DRUG_POLICY.duplicate(true)
	if not food_policies.has(pawn_id):
		food_policies[pawn_id] = DEFAULT_FOOD_POLICY.duplicate()
	if not outfit_policies.has(pawn_id):
		outfit_policies[pawn_id] = DEFAULT_OUTFIT_POLICY.duplicate()


func apply_drug_template(pawn_id: int, template_name: String) -> bool:
	if not DRUG_TEMPLATES.has(template_name):
		return false
	drug_policies[pawn_id] = DRUG_TEMPLATES[template_name].duplicate(true)
	return true


func apply_outfit_template(pawn_id: int, template_name: String) -> bool:
	if not OUTFIT_TEMPLATES.has(template_name):
		return false
	outfit_policies[pawn_id] = OUTFIT_TEMPLATES[template_name].duplicate()
	return true


func batch_apply_drug_template(template_name: String) -> int:
	if not PawnManager or not DRUG_TEMPLATES.has(template_name):
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			apply_drug_template(p.id, template_name)
			count += 1
	return count


func batch_apply_outfit_template(template_name: String) -> int:
	if not PawnManager or not OUTFIT_TEMPLATES.has(template_name):
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			apply_outfit_template(p.id, template_name)
			count += 1
	return count


func get_pawn_policy_summary(pawn_id: int) -> Dictionary:
	return {
		"drug": get_drug_policy(pawn_id),
		"food": get_food_policy(pawn_id),
		"outfit": get_outfit_policy(pawn_id),
	}


func get_restricted_drug_count() -> int:
	var count: int = 0
	for pid: int in drug_policies:
		var policy: Dictionary = drug_policies[pid]
		for drug: String in policy:
			if not policy[drug].get("allowed", false):
				count += 1
				break
	return count


func count_custom_policies() -> Dictionary:
	var custom_drug: int = 0
	var custom_food: int = 0
	var custom_outfit: int = 0
	for pid: int in drug_policies:
		if drug_policies[pid] != DEFAULT_DRUG_POLICY:
			custom_drug += 1
	for pid: int in food_policies:
		if food_policies[pid] != DEFAULT_FOOD_POLICY:
			custom_food += 1
	for pid: int in outfit_policies:
		if outfit_policies[pid] != DEFAULT_OUTFIT_POLICY:
			custom_outfit += 1
	return {"drug": custom_drug, "food": custom_food, "outfit": custom_outfit}


func get_pawns_without_policy() -> Array[int]:
	if not PawnManager:
		return []
	var result: Array[int] = []
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if not drug_policies.has(p.id) and not food_policies.has(p.id) and not outfit_policies.has(p.id):
			result.append(p.id)
	return result


func get_strict_policy_count() -> int:
	var count: int = 0
	for pid: int in drug_policies:
		var policy: Dictionary = drug_policies[pid]
		var all_banned: bool = true
		for drug: String in policy:
			if policy[drug].get("allowed", false):
				all_banned = false
				break
		if all_banned:
			count += 1
	return count

func get_policy_diversity() -> int:
	var unique: Dictionary = {}
	for pid: int in drug_policies:
		var key: String = str(drug_policies[pid])
		unique[key] = true
	return unique.size()

func get_management_rating() -> String:
	var unmanaged: int = get_pawns_without_policy().size()
	if unmanaged == 0:
		return "FullyCovered"
	elif unmanaged <= 2:
		return "MostlyCovered"
	return "Incomplete"

func get_governance_maturity() -> String:
	var rating := get_management_rating()
	var diversity := get_policy_diversity()
	if rating == "FullyCovered" and diversity >= 3:
		return "Advanced"
	elif rating != "Incomplete":
		return "Developing"
	return "Basic"

func get_compliance_score() -> float:
	var total := drug_policies.size() + food_policies.size() + outfit_policies.size()
	var unmanaged := get_pawns_without_policy().size()
	if total + unmanaged <= 0:
		return 0.0
	return snapped(float(total) / float(total + unmanaged) * 100.0, 0.1)

func get_policy_flexibility() -> String:
	var custom: Dictionary = count_custom_policies()
	var total_custom: int = int(custom.get("drug", 0)) + int(custom.get("food", 0)) + int(custom.get("outfit", 0))
	if total_custom >= 5:
		return "Highly Flexible"
	elif total_custom >= 2:
		return "Moderate"
	return "Rigid"

func get_summary() -> Dictionary:
	return {
		"pawns_with_drug_policy": drug_policies.size(),
		"pawns_with_food_policy": food_policies.size(),
		"pawns_with_outfit_policy": outfit_policies.size(),
		"drug_templates": DRUG_TEMPLATES.keys(),
		"outfit_templates": OUTFIT_TEMPLATES.keys(),
		"default_drug_allowed": DEFAULT_DRUG_POLICY.keys().filter(
			func(k: String) -> bool: return DEFAULT_DRUG_POLICY[k].get("allowed", false)
		),
		"restricted_count": get_restricted_drug_count(),
		"custom_policies": count_custom_policies(),
		"unmanaged_pawns": get_pawns_without_policy().size(),
		"total_managed": drug_policies.size() + food_policies.size() + outfit_policies.size(),
		"policy_coverage": snappedf((1.0 - float(get_pawns_without_policy().size()) / maxf(float(drug_policies.size() + food_policies.size() + 1), 1.0)) * 100.0, 0.1),
		"strict_policies": get_strict_policy_count(),
		"policy_diversity": get_policy_diversity(),
		"management_rating": get_management_rating(),
		"governance_maturity": get_governance_maturity(),
		"compliance_score": get_compliance_score(),
		"policy_flexibility": get_policy_flexibility(),
	}
