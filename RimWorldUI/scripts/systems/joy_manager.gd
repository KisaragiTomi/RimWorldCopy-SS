extends Node

## Defines joy activity types and tracks per-pawn joy variety needs.
## Registered as autoload "JoyManager".

enum JoyKind { SOCIAL, SOLITARY, GLUTTONOUS, MEDITATIVE, PHYSICAL }

const JOY_ACTIVITIES: Dictionary = {
	"Socializing": {
		"label": "Socializing",
		"kind": JoyKind.SOCIAL,
		"joy_gain": 0.35,
		"duration_ticks": 300,
	},
	"StarGazing": {
		"label": "Star gazing",
		"kind": JoyKind.MEDITATIVE,
		"joy_gain": 0.25,
		"duration_ticks": 400,
	},
	"Walking": {
		"label": "Taking a walk",
		"kind": JoyKind.SOLITARY,
		"joy_gain": 0.20,
		"duration_ticks": 250,
	},
	"Chess": {
		"label": "Playing chess",
		"kind": JoyKind.SOCIAL,
		"joy_gain": 0.40,
		"duration_ticks": 350,
	},
	"Horseshoes": {
		"label": "Horseshoes",
		"kind": JoyKind.PHYSICAL,
		"joy_gain": 0.35,
		"duration_ticks": 300,
	},
	"CloudWatching": {
		"label": "Cloud watching",
		"kind": JoyKind.MEDITATIVE,
		"joy_gain": 0.20,
		"duration_ticks": 350,
	},
	"Eating": {
		"label": "Eating lavishly",
		"kind": JoyKind.GLUTTONOUS,
		"joy_gain": 0.30,
		"duration_ticks": 200,
	},
	"Sculpting": {
		"label": "Sculpting",
		"kind": JoyKind.SOLITARY,
		"joy_gain": 0.30,
		"duration_ticks": 400,
		"skill_bonus": "Artistic",
	},
	"Meditating": {
		"label": "Meditating",
		"kind": JoyKind.MEDITATIVE,
		"joy_gain": 0.25,
		"duration_ticks": 350,
	},
	"Billiards": {
		"label": "Playing billiards",
		"kind": JoyKind.SOCIAL,
		"joy_gain": 0.35,
		"duration_ticks": 300,
	},
}

var _pawn_history: Dictionary = {}
var _activity_counts: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var total_activities: int = 0


func _ready() -> void:
	_rng.seed = randi()


func pick_activity(pawn: Pawn) -> String:
	var history: Array = _pawn_history.get(pawn.id, [])
	var activities := JOY_ACTIVITIES.keys()

	var weighted: Array[Dictionary] = []
	for act: String in activities:
		var weight: float = 1.0
		var recent_count: int = 0
		for h_act in history:
			if h_act == act:
				recent_count += 1
		weight *= pow(0.3, recent_count)
		var def: Dictionary = JOY_ACTIVITIES[act]
		if def.has("skill_bonus"):
			var skill_name: String = def["skill_bonus"]
			var skill_level: int = pawn.get_skill(skill_name) if pawn else 0
			weight *= 1.0 + skill_level * 0.05
		weighted.append({"name": act, "weight": weight})

	var total_weight: float = 0.0
	for w: Dictionary in weighted:
		total_weight += w.get("weight", 1.0)

	var roll: float = _rng.randf() * total_weight
	var cumulative: float = 0.0
	for w: Dictionary in weighted:
		cumulative += w.get("weight", 1.0)
		if roll <= cumulative:
			var picked: String = w.get("name", "Walking")
			record_activity(pawn.id, picked)
			return picked

	return "Walking"


func record_activity(pawn_id: int, activity: String) -> void:
	if not _pawn_history.has(pawn_id):
		_pawn_history[pawn_id] = []
	var h: Array = _pawn_history[pawn_id]
	h.append(activity)
	if h.size() > 7:
		h.pop_front()
	_activity_counts[activity] = _activity_counts.get(activity, 0) + 1
	total_activities += 1


func get_activity_def(activity_name: String) -> Dictionary:
	return JOY_ACTIVITIES.get(activity_name, {})


func get_variety_score(pawn_id: int) -> float:
	var h: Array = _pawn_history.get(pawn_id, [])
	if h.is_empty():
		return 1.0
	var unique: Dictionary = {}
	for act in h:
		unique[act] = true
	return float(unique.size()) / float(h.size())


func get_most_popular() -> String:
	var best: String = ""
	var best_count: int = 0
	for act: String in _activity_counts:
		if _activity_counts[act] > best_count:
			best = act
			best_count = _activity_counts[act]
	return best


func get_least_popular() -> String:
	var worst: String = ""
	var worst_c: int = 999999
	for act: String in _activity_counts:
		if _activity_counts[act] < worst_c:
			worst_c = _activity_counts[act]
			worst = act
	return worst


func get_variety_score_all() -> float:
	if _pawn_history.is_empty():
		return 0.0
	var total: float = 0.0
	var cnt: int = 0
	for pid: int in _pawn_history:
		var unique: Dictionary = {}
		for a: String in _pawn_history[pid]:
			unique[a] = true
		total += float(unique.size())
		cnt += 1
	if cnt == 0:
		return 0.0
	return total / float(cnt)


func get_activities_per_pawn(pawn_id: int) -> int:
	if not _pawn_history.has(pawn_id):
		return 0
	return _pawn_history[pawn_id].size()


func get_unused_activity_count() -> int:
	var cnt: int = 0
	for a: String in JOY_ACTIVITIES:
		if _activity_counts.get(a, 0) == 0:
			cnt += 1
	return cnt


func get_avg_activities_per_pawn() -> float:
	if _pawn_history.is_empty():
		return 0.0
	var total: int = 0
	for pid: int in _pawn_history:
		total += _pawn_history[pid].size()
	return float(total) / float(_pawn_history.size())


func get_top_activity_share() -> float:
	if total_activities == 0:
		return 0.0
	var mx: int = 0
	for a: String in _activity_counts:
		if _activity_counts[a] > mx:
			mx = _activity_counts[a]
	return float(mx) / float(total_activities) * 100.0


func get_usage_rate() -> float:
	if JOY_ACTIVITIES.is_empty():
		return 0.0
	var used: int = JOY_ACTIVITIES.size() - get_unused_activity_count()
	return snappedf(float(used) / float(JOY_ACTIVITIES.size()) * 100.0, 0.1)


func get_joy_balance() -> String:
	var variety: float = get_variety_score_all()
	if variety >= 3.0:
		return "Excellent"
	elif variety >= 2.0:
		return "Good"
	elif variety >= 1.0:
		return "Fair"
	return "Poor"


func get_activity_per_pawn_per_day() -> float:
	if _pawn_history.is_empty():
		return 0.0
	return snappedf(float(total_activities) / float(_pawn_history.size()), 0.01)


func get_entertainment_saturation() -> float:
	var used := JOY_ACTIVITIES.size() - get_unused_activity_count()
	if JOY_ACTIVITIES.is_empty():
		return 0.0
	return snapped(float(used) / float(JOY_ACTIVITIES.size()) * 100.0, 0.1)

func get_boredom_risk() -> String:
	var variety := get_variety_score_all()
	var unused := get_unused_activity_count()
	if variety < 1.0 and unused > JOY_ACTIVITIES.size() / 2:
		return "High"
	elif variety < 2.0:
		return "Moderate"
	elif variety < 3.0:
		return "Low"
	return "None"

func get_social_recreation_pct() -> float:
	var social := 0
	for act: String in _activity_counts:
		if act.contains("Social") or act.contains("Party") or act.contains("Games"):
			social += _activity_counts[act]
	if total_activities <= 0:
		return 0.0
	return snapped(float(social) / float(total_activities) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"activity_types": JOY_ACTIVITIES.size(),
		"tracked_pawns": _pawn_history.size(),
		"total_activities": total_activities,
		"most_popular": get_most_popular(),
		"activity_counts": _activity_counts.duplicate(),
		"least_popular": get_least_popular(),
		"avg_variety": snappedf(get_variety_score_all(), 0.1),
		"unused_activities": get_unused_activity_count(),
		"avg_per_pawn": snappedf(get_avg_activities_per_pawn(), 0.1),
		"top_share_pct": snappedf(get_top_activity_share(), 0.1),
		"usage_rate_pct": get_usage_rate(),
		"joy_balance": get_joy_balance(),
		"activity_per_pawn": get_activity_per_pawn_per_day(),
		"entertainment_saturation": get_entertainment_saturation(),
		"boredom_risk": get_boredom_risk(),
		"social_recreation_pct": get_social_recreation_pct(),
		"recreation_ecosystem_health": get_recreation_ecosystem_health(),
		"leisure_infrastructure_score": get_leisure_infrastructure_score(),
		"cultural_vitality_index": get_cultural_vitality_index(),
	}

func get_recreation_ecosystem_health() -> String:
	var usage: float = get_usage_rate()
	var variety: float = get_variety_score_all()
	if usage >= 80.0 and variety >= 4.0:
		return "Thriving"
	if usage >= 50.0 and variety >= 2.5:
		return "Healthy"
	if usage >= 30.0:
		return "Developing"
	return "Deficient"

func get_leisure_infrastructure_score() -> float:
	var types: int = JOY_ACTIVITIES.size()
	var unused: int = get_unused_activity_count()
	var utilization: float = float(types - unused) / float(types) * 100.0 if types > 0 else 0.0
	var social_pct: float = get_social_recreation_pct()
	return snappedf(utilization * 0.7 + social_pct * 0.3, 0.1)

func get_cultural_vitality_index() -> float:
	var avg_per_pawn: float = get_avg_activities_per_pawn()
	var variety: float = get_variety_score_all()
	var score: float = avg_per_pawn * 10.0 + variety * 15.0
	return snappedf(clampf(score, 0.0, 100.0), 0.1)
