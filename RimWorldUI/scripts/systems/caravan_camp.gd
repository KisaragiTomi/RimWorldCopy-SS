extends Node

var _camps: Array = []

const CAMP_ACTIVITIES: Dictionary = {
	"Rest": {"rest_rate": 0.08, "duration_hours": 8, "food_cost": 0.5},
	"Forage": {"food_gain": 3.0, "duration_hours": 4, "skill": "Plants"},
	"Trade": {"requires_settlement": true, "duration_hours": 6},
	"Hunt": {"food_gain": 5.0, "duration_hours": 6, "skill": "Shooting", "danger": 0.1},
	"Heal": {"tend_quality": 0.5, "duration_hours": 4, "skill": "Medicine"},
	"Scout": {"reveal_radius": 3, "duration_hours": 3, "skill": "Intellectual"}
}

const CAMP_COMFORT: Dictionary = {
	"OpenField": {"rest_mult": 0.8, "mood": -3},
	"Forest": {"rest_mult": 1.0, "mood": 0, "forage_bonus": 1.5},
	"Ruins": {"rest_mult": 1.1, "mood": -1, "cover": true},
	"Riverside": {"rest_mult": 1.0, "mood": 2, "water": true}
}

func setup_camp(caravan_id: int, location: Vector2i, terrain: String) -> Dictionary:
	var comfort: Dictionary = CAMP_COMFORT.get(terrain, CAMP_COMFORT["OpenField"])
	var camp: Dictionary = {
		"id": _camps.size(),
		"caravan_id": caravan_id,
		"location": location,
		"terrain": terrain,
		"comfort": comfort,
		"hours_camped": 0,
		"activities_done": []
	}
	_camps.append(camp)
	return camp

func do_activity(camp_id: int, activity: String) -> Dictionary:
	if camp_id < 0 or camp_id >= _camps.size():
		return {}
	if not CAMP_ACTIVITIES.has(activity):
		return {}
	var act: Dictionary = CAMP_ACTIVITIES[activity]
	_camps[camp_id]["hours_camped"] += act.get("duration_hours", 4)
	_camps[camp_id]["activities_done"].append(activity)
	return {"activity": activity, "hours": act.get("duration_hours", 4)}

func break_camp(camp_id: int) -> bool:
	if camp_id < 0 or camp_id >= _camps.size():
		return false
	_camps.remove_at(camp_id)
	return true

func get_best_terrain_for_rest() -> String:
	var best: String = ""
	var best_mult: float = 0.0
	for t: String in CAMP_COMFORT:
		if float(CAMP_COMFORT[t].get("rest_mult", 0.0)) > best_mult:
			best_mult = float(CAMP_COMFORT[t].get("rest_mult", 0.0))
			best = t
	return best


func get_total_hours_camped() -> int:
	var total: int = 0
	for camp: Dictionary in _camps:
		total += int(camp.get("hours_camped", 0))
	return total


func get_activity_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for camp: Dictionary in _camps:
		for act in camp.get("activities_done", []):
			var a: String = String(act)
			dist[a] = dist.get(a, 0) + 1
	return dist


func get_most_popular_activity() -> String:
	var dist: Dictionary = get_activity_distribution()
	var best: String = ""
	var best_count: int = 0
	for act: String in dist:
		if int(dist[act]) > best_count:
			best_count = int(dist[act])
			best = act
	return best


func get_avg_hours_per_camp() -> float:
	if _camps.is_empty():
		return 0.0
	return float(get_total_hours_camped()) / _camps.size()


func get_camp_with_most_activities() -> int:
	var best_id: int = -1
	var best_count: int = 0
	for i: int in range(_camps.size()):
		var c: int = _camps[i].get("activities_done", []).size()
		if c > best_count:
			best_count = c
			best_id = int(_camps[i].get("id", i))
	return best_id


func get_unique_terrain_used() -> int:
	var terrains: Dictionary = {}
	for camp: Dictionary in _camps:
		terrains[String(camp.get("terrain", ""))] = true
	return terrains.size()


func get_total_activities_performed() -> int:
	var total: int = 0
	for camp: Dictionary in _camps:
		total += camp.get("activities_done", []).size()
	return total


func get_avg_activities_per_camp() -> float:
	if _camps.is_empty():
		return 0.0
	return snappedf(float(get_total_activities_performed()) / float(_camps.size()), 0.1)


func get_camp_quality() -> String:
	var avg_act: float = get_avg_activities_per_camp()
	if avg_act >= 4.0:
		return "Excellent"
	elif avg_act >= 2.0:
		return "Good"
	elif avg_act > 0.0:
		return "Basic"
	return "None"

func get_exploration_depth() -> float:
	if CAMP_COMFORT.is_empty():
		return 0.0
	return snappedf(float(get_unique_terrain_used()) / float(CAMP_COMFORT.size()) * 100.0, 0.1)

func get_nomadic_lifestyle() -> String:
	var total: int = get_total_hours_camped()
	if total >= 100:
		return "Nomadic"
	elif total >= 30:
		return "Semi-Nomadic"
	elif total > 0:
		return "Occasional"
	return "Sedentary"

func get_summary() -> Dictionary:
	return {
		"active_camps": _camps.size(),
		"activity_types": CAMP_ACTIVITIES.size(),
		"terrain_types": CAMP_COMFORT.size(),
		"total_hours": get_total_hours_camped(),
		"most_popular": get_most_popular_activity(),
		"avg_hours": snapped(get_avg_hours_per_camp(), 0.1),
		"unique_terrains_used": get_unique_terrain_used(),
		"total_activities": get_total_activities_performed(),
		"avg_activities_per_camp": get_avg_activities_per_camp(),
		"camp_quality": get_camp_quality(),
		"exploration_depth_pct": get_exploration_depth(),
		"nomadic_lifestyle": get_nomadic_lifestyle(),
		"camp_efficiency": get_camp_efficiency(),
		"wilderness_mastery": get_wilderness_mastery(),
		"expedition_readiness": get_expedition_readiness(),
		"camp_ecosystem_health": get_camp_ecosystem_health(),
		"expedition_governance": get_expedition_governance(),
		"nomadic_maturity_index": get_nomadic_maturity_index(),
	}

func get_camp_efficiency() -> float:
	var total_act := get_total_activities_performed()
	var hours := get_total_hours_camped()
	if hours <= 0.0:
		return 0.0
	return snapped(float(total_act) / hours * 10.0, 0.1)

func get_wilderness_mastery() -> String:
	var terrains := get_unique_terrain_used()
	var quality := get_camp_quality()
	if terrains >= 4 and quality in ["Excellent", "Good"]:
		return "Expert"
	elif terrains >= 2:
		return "Competent"
	return "Novice"

func get_expedition_readiness() -> String:
	var camps := _camps.size()
	var lifestyle := get_nomadic_lifestyle()
	if camps >= 3 and lifestyle in ["Nomadic", "Semi-Nomadic"]:
		return "Ready"
	elif camps > 0:
		return "Preparing"
	return "Settled"

func get_camp_ecosystem_health() -> float:
	var mastery := get_wilderness_mastery()
	var m_val: float = 90.0 if mastery == "Expert" else (60.0 if mastery == "Competent" else 30.0)
	var efficiency := get_camp_efficiency()
	var readiness := get_expedition_readiness()
	var r_val: float = 90.0 if readiness == "Ready" else (60.0 if readiness == "Preparing" else 30.0)
	return snapped((m_val + minf(efficiency, 100.0) + r_val) / 3.0, 0.1)

func get_nomadic_maturity_index() -> float:
	var quality := get_camp_quality()
	var q_val: float = 90.0 if quality in ["Excellent", "Good"] else (60.0 if quality in ["Average", "Decent"] else 30.0)
	var depth := get_exploration_depth()
	var lifestyle := get_nomadic_lifestyle()
	var l_val: float = 90.0 if lifestyle in ["Nomadic", "Semi-Nomadic"] else (60.0 if lifestyle in ["Explorer"] else 30.0)
	return snapped((q_val + minf(depth, 100.0) + l_val) / 3.0, 0.1)

func get_expedition_governance() -> String:
	var ecosystem := get_camp_ecosystem_health()
	var maturity := get_nomadic_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _camps.size() > 0:
		return "Nascent"
	return "Dormant"
