extends Node

var _roles: Dictionary = {}

const IDEO_ROLES: Dictionary = {
	"Leader": {"max_count": 1, "mood_bonus": 5, "social_bonus": 0.15, "abilities": ["Convert", "Reassure"]},
	"MoralGuide": {"max_count": 1, "mood_bonus": 3, "social_bonus": 0.1, "abilities": ["Convert", "Counsel"]},
	"SpecialistShooter": {"max_count": 2, "shooting_bonus": 0.2, "abilities": ["MarksmanFocus"]},
	"SpecialistMelee": {"max_count": 2, "melee_bonus": 0.2, "abilities": ["BerserkerRage"]},
	"SpecialistMedic": {"max_count": 2, "medical_bonus": 0.2, "abilities": ["AnestheticBliss"]},
	"SpecialistMiner": {"max_count": 2, "mining_bonus": 0.25, "abilities": ["DeepScan"]},
	"SpecialistPlant": {"max_count": 2, "plant_bonus": 0.2, "abilities": ["FarmingFocus"]},
	"SpecialistAnimal": {"max_count": 2, "animal_bonus": 0.2, "abilities": ["AnimalCalm"]}
}

func assign_role(pawn_id: int, role: String) -> Dictionary:
	if not IDEO_ROLES.has(role):
		return {"error": "unknown_role"}
	var count: int = 0
	for pid: int in _roles:
		if _roles[pid] == role:
			count += 1
	if count >= IDEO_ROLES[role]["max_count"]:
		return {"error": "max_reached"}
	_roles[pawn_id] = role
	return {"assigned": true, "role": role, "abilities": IDEO_ROLES[role].get("abilities", [])}

func get_role(pawn_id: int) -> String:
	return _roles.get(pawn_id, "None")

func get_role_bonuses(pawn_id: int) -> Dictionary:
	var role: String = get_role(pawn_id)
	if role == "None":
		return {}
	var info: Dictionary = IDEO_ROLES.get(role, {})
	var bonuses: Dictionary = {}
	for key: String in info:
		if key.ends_with("_bonus"):
			bonuses[key] = info[key]
	return bonuses

func get_unassigned_roles() -> Array[String]:
	var assigned_counts: Dictionary = {}
	for pid: int in _roles:
		var r: String = _roles[pid]
		assigned_counts[r] = int(assigned_counts.get(r, 0)) + 1
	var result: Array[String] = []
	for role: String in IDEO_ROLES:
		var current: int = int(assigned_counts.get(role, 0))
		if current < int(IDEO_ROLES[role].get("max_count", 1)):
			result.append(role)
	return result


func get_role_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pid: int in _roles:
		var r: String = _roles[pid]
		dist[r] = int(dist.get(r, 0)) + 1
	return dist


func get_total_abilities() -> int:
	var total: int = 0
	for role: String in IDEO_ROLES:
		total += IDEO_ROLES[role].get("abilities", []).size()
	return total


func get_role_assignment_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pid: int in _roles:
		var r: String = String(_roles[pid])
		dist[r] = dist.get(r, 0) + 1
	return dist


func get_most_popular_role() -> String:
	var dist: Dictionary = get_role_assignment_distribution()
	var best: String = ""
	var best_count: int = 0
	for r: String in dist:
		if int(dist[r]) > best_count:
			best_count = int(dist[r])
			best = r
	return best


func get_assignment_rate() -> float:
	if IDEO_ROLES.is_empty():
		return 0.0
	return float(_roles.size()) / maxf(IDEO_ROLES.size(), 1)


func get_specialist_count() -> int:
	var count: int = 0
	for role: String in IDEO_ROLES:
		if role.begins_with("Specialist"):
			count += 1
	return count


func get_total_max_slots() -> int:
	var total: int = 0
	for role: String in IDEO_ROLES:
		total += int(IDEO_ROLES[role].get("max_count", 1))
	return total


func get_fill_rate_pct() -> float:
	var max_slots: int = get_total_max_slots()
	if max_slots == 0:
		return 0.0
	return snappedf(float(_roles.size()) / float(max_slots) * 100.0, 0.1)


func get_summary() -> Dictionary:
	return {
		"role_types": IDEO_ROLES.size(),
		"assigned_pawns": _roles.size(),
		"open_slots": get_unassigned_roles().size(),
		"total_abilities": get_total_abilities(),
		"most_popular": get_most_popular_role(),
		"assignment_rate": snapped(get_assignment_rate(), 0.01),
		"specialist_roles": get_specialist_count(),
		"total_max_slots": get_total_max_slots(),
		"fill_rate_pct": get_fill_rate_pct(),
		"role_specialization_depth": get_role_specialization_depth(),
		"ritual_participation_pct": get_ritual_participation_pct(),
		"ideology_depth": get_ideology_depth(),
		"ideological_ecosystem_health": get_ideological_ecosystem_health(),
		"role_governance": get_role_governance(),
		"spiritual_maturity_index": get_spiritual_maturity_index(),
	}

func get_role_specialization_depth() -> String:
	var specialist := get_specialist_count()
	var total := _roles.size()
	if total <= 0:
		return "None"
	var ratio := float(specialist) / float(total)
	if ratio >= 0.5:
		return "Deep"
	elif ratio >= 0.2:
		return "Moderate"
	return "Shallow"

func get_ritual_participation_pct() -> float:
	var assigned := _roles.size()
	var total_slots := get_total_max_slots()
	if total_slots <= 0:
		return 0.0
	return snapped(float(assigned) / float(total_slots) * 100.0, 0.1)

func get_ideology_depth() -> String:
	var fill := get_fill_rate_pct()
	var abilities := get_total_abilities()
	if fill >= 80.0 and abilities >= 5:
		return "Devout"
	elif fill >= 40.0:
		return "Practicing"
	return "Nominal"

func get_ideological_ecosystem_health() -> float:
	var depth := get_ideology_depth()
	var d_val: float = 90.0 if depth == "Devout" else (60.0 if depth == "Practicing" else 25.0)
	var ritual := get_ritual_participation_pct()
	var fill := get_fill_rate_pct()
	return snapped((d_val + ritual + fill) / 3.0, 0.1)

func get_role_governance() -> String:
	var ecosystem := get_ideological_ecosystem_health()
	var specialization := get_role_specialization_depth()
	var s_val: float = 90.0 if specialization == "Deep" else (60.0 if specialization == "Moderate" else 25.0)
	var combined := (ecosystem + s_val) / 2.0
	if combined >= 70.0:
		return "Theocratic"
	elif combined >= 40.0:
		return "Organized"
	elif _roles.size() > 0:
		return "Informal"
	return "Secular"

func get_spiritual_maturity_index() -> float:
	var fill := get_fill_rate_pct()
	var abilities := float(get_total_abilities())
	return snapped((fill + minf(abilities * 10.0, 100.0)) / 2.0, 0.1)
