extends Node

var colony_ideology: Dictionary = {}

const PRECEPTS: Dictionary = {
	"Cannibalism": {"desc": "Attitude toward eating human meat", "options": ["Abhorrent", "Acceptable", "Preferred"]},
	"Nudity": {"desc": "Attitude toward wearing clothes", "options": ["Required", "Acceptable", "Preferred"]},
	"SlaveLabor": {"desc": "Attitude toward slavery", "options": ["Forbidden", "Acceptable", "Honorable"]},
	"Darkness": {"desc": "Attitude toward darkness", "options": ["Disliked", "Neutral", "Preferred"]},
	"DrugUse": {"desc": "Attitude toward drug use", "options": ["Forbidden", "Social", "Essential"]},
	"Violence": {"desc": "Attitude toward violence", "options": ["Pacifist", "Defensive", "Raider"]},
}

const ROLES: Dictionary = {
	"Leader": {"max": 1, "bonus_mood": 0.1, "social_bonus": 3},
	"MoralGuide": {"max": 1, "bonus_mood": 0.05, "research_bonus": 2},
	"Specialist": {"max": 3, "bonus_mood": 0.03, "work_bonus": 1.2},
}

const RITUALS: Dictionary = {
	"DanceCeremony": {"interval": 15000, "mood_bonus": 0.12, "duration": 2000},
	"Feast": {"interval": 20000, "mood_bonus": 0.15, "duration": 3000},
	"TreePlanting": {"interval": 25000, "mood_bonus": 0.08, "duration": 1500},
	"Sacrifice": {"interval": 30000, "mood_bonus": 0.20, "duration": 2500},
	"SkullSpikeRitual": {"interval": 40000, "mood_bonus": 0.10, "duration": 1000},
}


func _ready() -> void:
	if colony_ideology.is_empty():
		_generate_default()


func _generate_default() -> void:
	colony_ideology = {
		"name": "The Way",
		"precepts": {
			"Cannibalism": "Abhorrent",
			"Nudity": "Required",
			"SlaveLabor": "Forbidden",
			"Darkness": "Disliked",
			"DrugUse": "Social",
			"Violence": "Defensive",
		},
		"roles": {},
		"rituals_performed": 0,
	}


func assign_role(pawn_id: int, role: String) -> Dictionary:
	if not ROLES.has(role):
		return {"success": false, "reason": "Unknown role"}
	colony_ideology["roles"][pawn_id] = role
	return {"success": true, "role": role}


func get_precept(precept_name: String) -> String:
	var precepts: Dictionary = colony_ideology.get("precepts", {})
	return str(precepts.get(precept_name, "Unknown"))


func perform_ritual(ritual_name: String) -> Dictionary:
	if not RITUALS.has(ritual_name):
		return {"success": false, "reason": "Unknown ritual"}
	colony_ideology["rituals_performed"] = colony_ideology.get("rituals_performed", 0) + 1
	var rit: Dictionary = RITUALS[ritual_name]
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if not p.dead and p.thought_tracker:
				p.thought_tracker.add_thought("RitualBoost")
	if ColonyLog and ColonyLog.has_method("add_entry"):
		ColonyLog.add_entry("Ideology", ritual_name + " performed!", "positive")
	return {"success": true, "mood_bonus": rit.mood_bonus}


func get_role_holder(role: String) -> int:
	var roles: Dictionary = colony_ideology.get("roles", {})
	for pid: int in roles:
		if roles[pid] == role:
			return pid
	return -1


func set_precept(precept_name: String, value: String) -> void:
	if PRECEPTS.has(precept_name):
		var precepts: Dictionary = colony_ideology.get("precepts", {})
		precepts[precept_name] = value


func get_unassigned_role_count() -> int:
	var assigned: Dictionary = colony_ideology.get("roles", {})
	return maxi(ROLES.size() - assigned.size(), 0)


func get_ritual_completion_rate() -> float:
	if RITUALS.is_empty():
		return 0.0
	var performed: int = colony_ideology.get("rituals_performed", 0)
	return snappedf(float(performed) / float(RITUALS.size()), 0.01)


func get_precept_count() -> int:
	return colony_ideology.get("precepts", {}).size()


func get_devotion_rating() -> String:
	var rate: float = get_ritual_completion_rate()
	if rate >= 80.0:
		return "Devout"
	elif rate >= 50.0:
		return "Faithful"
	elif rate > 0.0:
		return "Casual"
	return "Irreligious"

func get_structure_completeness() -> float:
	var roles_filled: float = float(colony_ideology.get("roles", {}).size()) / maxf(float(ROLES.size()), 1.0)
	var precepts_set: float = float(get_precept_count()) / maxf(10.0, 1.0)
	return snappedf((roles_filled + minf(precepts_set, 1.0)) / 2.0 * 100.0, 0.1)

func get_cultural_cohesion() -> String:
	var unassigned: int = get_unassigned_role_count()
	if unassigned == 0:
		return "United"
	elif unassigned <= 2:
		return "MostlyAligned"
	return "Fractured"

func get_role_specialization() -> String:
	var assigned: int = colony_ideology.get("roles", {}).size()
	var total: int = ROLES.size()
	var ratio: float = float(assigned) / maxf(float(total), 1.0)
	if ratio >= 0.9:
		return "Specialized"
	if ratio >= 0.5:
		return "Developing"
	return "Unstructured"


func get_ritual_engagement_pct() -> float:
	var performed: int = colony_ideology.get("rituals_performed", 0)
	var expected: int = RITUALS.size() * 3
	return snappedf(float(performed) / maxf(float(expected), 1.0) * 100.0, 0.1)


func get_ideological_depth() -> String:
	var precepts: int = get_precept_count()
	var roles: int = colony_ideology.get("roles", {}).size()
	var rituals: int = colony_ideology.get("rituals_performed", 0)
	var score: float = float(precepts) * 0.4 + float(roles) * 0.3 + float(rituals) * 0.3
	if score >= 8.0:
		return "Deep"
	if score >= 4.0:
		return "Moderate"
	return "Shallow"


func get_summary() -> Dictionary:
	return {
		"ideology_name": colony_ideology.get("name", "None"),
		"precepts": colony_ideology.get("precepts", {}),
		"roles_assigned": colony_ideology.get("roles", {}).size(),
		"rituals": RITUALS.size(),
		"rituals_performed": colony_ideology.get("rituals_performed", 0),
		"available_roles": ROLES.keys(),
		"unassigned_roles": get_unassigned_role_count(),
		"ritual_rate": get_ritual_completion_rate(),
		"precept_count": get_precept_count(),
		"role_fill_pct": snappedf(float(colony_ideology.get("roles", {}).size()) / maxf(float(ROLES.size()), 1.0) * 100.0, 0.1),
		"rituals_per_type": snappedf(float(colony_ideology.get("rituals_performed", 0)) / maxf(float(RITUALS.size()), 1.0), 0.1),
		"devotion_rating": get_devotion_rating(),
		"structure_completeness": get_structure_completeness(),
		"cultural_cohesion": get_cultural_cohesion(),
		"role_specialization": get_role_specialization(),
		"ritual_engagement_pct": get_ritual_engagement_pct(),
		"ideological_depth": get_ideological_depth(),
	}
