extends Node

var _focus_levels: Dictionary = {}

const FOCUS_STATES: Dictionary = {
	"Unfocused": {"speed_mult": 0.8, "quality_mult": 0.85, "threshold": 0.0},
	"Normal": {"speed_mult": 1.0, "quality_mult": 1.0, "threshold": 0.3},
	"Focused": {"speed_mult": 1.1, "quality_mult": 1.1, "threshold": 0.6},
	"DeepFocus": {"speed_mult": 1.25, "quality_mult": 1.2, "threshold": 0.85}
}

const FOCUS_FACTORS: Dictionary = {
	"Passion": {"none": 0.0, "minor": 0.15, "major": 0.3},
	"Mood": {"happy": 0.1, "content": 0.0, "stressed": -0.15, "broken": -0.3},
	"Comfort": {"high": 0.05, "normal": 0.0, "low": -0.1},
	"Uninterrupted": {"long": 0.2, "medium": 0.1, "short": 0.0}
}

func set_focus(pawn_id: int, level: float) -> void:
	_focus_levels[pawn_id] = clampf(level, 0.0, 1.0)

func get_focus(pawn_id: int) -> float:
	return _focus_levels.get(pawn_id, 0.5)

func get_focus_state(pawn_id: int) -> String:
	var level: float = get_focus(pawn_id)
	var result: String = "Unfocused"
	for state: String in FOCUS_STATES:
		if level >= FOCUS_STATES[state]["threshold"]:
			result = state
	return result

func get_speed_multiplier(pawn_id: int) -> float:
	var state: String = get_focus_state(pawn_id)
	return FOCUS_STATES.get(state, {}).get("speed_mult", 1.0)

func get_quality_multiplier(pawn_id: int) -> float:
	var state: String = get_focus_state(pawn_id)
	return FOCUS_STATES.get(state, {}).get("quality_mult", 1.0)

func get_deep_focus_count() -> int:
	var count: int = 0
	for pid: int in _focus_levels:
		if get_focus_state(pid) == "DeepFocus":
			count += 1
	return count


func get_unfocused_count() -> int:
	var count: int = 0
	for pid: int in _focus_levels:
		if get_focus_state(pid) == "Unfocused":
			count += 1
	return count


func get_focus_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pid: int in _focus_levels:
		var s: String = get_focus_state(pid)
		dist[s] = int(dist.get(s, 0)) + 1
	return dist


func get_avg_focus_level() -> float:
	if _focus_levels.is_empty():
		return 0.5
	var total: float = 0.0
	for pid: int in _focus_levels:
		total += float(_focus_levels[pid])
	return total / _focus_levels.size()


func get_focus_state_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pid: int in _focus_levels:
		var state: String = get_focus_state(pid)
		dist[state] = dist.get(state, 0) + 1
	return dist


func get_normal_focus_count() -> int:
	var count: int = 0
	for pid: int in _focus_levels:
		if get_focus_state(pid) == "Normal":
			count += 1
	return count


func get_focused_count() -> int:
	var count: int = 0
	for pid: int in _focus_levels:
		if get_focus_state(pid) == "Focused":
			count += 1
	return count


func get_max_speed_bonus() -> float:
	var best: float = 0.0
	for state: String in FOCUS_STATES:
		var m: float = float(FOCUS_STATES[state].get("speed_mult", 1.0))
		if m > best:
			best = m
	return best


func get_focus_factor_count() -> int:
	var total: int = 0
	for cat: String in FOCUS_FACTORS:
		total += FOCUS_FACTORS[cat].size()
	return total


func get_productivity_rating() -> String:
	var deep: int = get_deep_focus_count()
	var total: int = _focus_levels.size()
	if total == 0:
		return "NoData"
	var ratio: float = float(deep) / float(total)
	if ratio >= 0.5:
		return "HighOutput"
	if ratio >= 0.2:
		return "Productive"
	return "Distracted"


func get_focus_efficiency_pct() -> float:
	var focused: int = get_focused_count() + get_deep_focus_count()
	var total: int = _focus_levels.size()
	if total == 0:
		return 0.0
	return snappedf(float(focused) / float(total) * 100.0, 0.1)


func get_distraction_risk() -> String:
	var unfocused: int = get_unfocused_count()
	var total: int = _focus_levels.size()
	if total == 0:
		return "NoData"
	var ratio: float = float(unfocused) / float(total)
	if ratio >= 0.4:
		return "High"
	if ratio >= 0.2:
		return "Moderate"
	return "Low"


func get_summary() -> Dictionary:
	return {
		"focus_states": FOCUS_STATES.size(),
		"focus_factor_categories": FOCUS_FACTORS.size(),
		"tracked_pawns": _focus_levels.size(),
		"deep_focus": get_deep_focus_count(),
		"unfocused": get_unfocused_count(),
		"avg_focus": snapped(get_avg_focus_level(), 0.01),
		"normal_focus": get_normal_focus_count(),
		"focused_count": get_focused_count(),
		"max_speed_bonus": get_max_speed_bonus(),
		"total_focus_factors": get_focus_factor_count(),
		"productivity_rating": get_productivity_rating(),
		"focus_efficiency_pct": get_focus_efficiency_pct(),
		"distraction_risk": get_distraction_risk(),
		"workflow_optimization": get_workflow_optimization(),
		"deep_work_ratio": get_deep_work_ratio(),
		"cognitive_load_balance": get_cognitive_load_balance(),
		"focus_ecosystem_health": get_focus_ecosystem_health(),
		"productivity_governance": get_productivity_governance(),
		"workflow_maturity_index": get_workflow_maturity_index(),
	}

func get_workflow_optimization() -> String:
	var efficiency := get_focus_efficiency_pct()
	var distraction := get_distraction_risk()
	if efficiency >= 80.0 and distraction in ["Low", "Minimal"]:
		return "Streamlined"
	elif efficiency >= 50.0:
		return "Adequate"
	return "Chaotic"

func get_deep_work_ratio() -> float:
	var deep := get_deep_focus_count()
	var total := _focus_levels.size()
	if total <= 0:
		return 0.0
	return snapped(float(deep) / float(total) * 100.0, 0.1)

func get_cognitive_load_balance() -> String:
	var avg := get_avg_focus_level()
	if avg >= 0.8:
		return "Optimal"
	elif avg >= 0.5:
		return "Manageable"
	return "Overloaded"

func get_focus_ecosystem_health() -> float:
	var optimization := get_workflow_optimization()
	var o_val: float = 90.0 if optimization == "Streamlined" else (60.0 if optimization == "Adequate" else 25.0)
	var deep_ratio := get_deep_work_ratio()
	var efficiency := get_focus_efficiency_pct()
	return snapped((o_val + deep_ratio + efficiency) / 3.0, 0.1)

func get_productivity_governance() -> String:
	var ecosystem := get_focus_ecosystem_health()
	var load := get_cognitive_load_balance()
	var l_val: float = 90.0 if load == "Optimal" else (60.0 if load == "Manageable" else 25.0)
	var combined := (ecosystem + l_val) / 2.0
	if combined >= 70.0:
		return "Peak Performance"
	elif combined >= 40.0:
		return "Functional"
	elif _focus_levels.size() > 0:
		return "Struggling"
	return "Idle"

func get_workflow_maturity_index() -> float:
	var productivity := get_productivity_rating()
	var p_val: float = 90.0 if productivity == "Excellent" else (60.0 if productivity in ["Good", "High"] else 25.0)
	var distraction := get_distraction_risk()
	var d_val: float = 90.0 if distraction in ["Low", "Minimal"] else (60.0 if distraction == "Moderate" else 25.0)
	return snapped((p_val + d_val) / 2.0, 0.1)
