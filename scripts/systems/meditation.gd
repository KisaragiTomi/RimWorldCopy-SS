extends Node

var _meditation_state: Dictionary = {}
var _psylink_levels: Dictionary = {}

const FOCUS_TYPES: Dictionary = {
	"NaturalGrass": {"focus_strength": 0.22, "requires": "outdoor"},
	"Grave": {"focus_strength": 0.18, "requires": "grave"},
	"AnimalBond": {"focus_strength": 0.12, "requires": "bonded_animal"},
	"AncientDanger": {"focus_strength": 0.30, "requires": "ruin_nearby"},
	"Sculpture": {"focus_strength": 0.15, "requires": "art_nearby"},
	"Throne": {"focus_strength": 0.25, "requires": "throne"},
	"AnimaTree": {"focus_strength": 0.35, "requires": "anima_tree"},
	"Flame": {"focus_strength": 0.20, "requires": "campfire"}
}

const PSYLINK_XP_PER_LEVEL: Array = [0, 100, 250, 500, 800, 1200, 1800]

func start_meditation(pawn_id: int, focus_type: String) -> bool:
	if not FOCUS_TYPES.has(focus_type):
		return false
	_meditation_state[pawn_id] = {"focus": focus_type, "ticks": 0, "xp_gained": 0.0}
	return true

func tick_meditation(pawn_id: int) -> Dictionary:
	if not _meditation_state.has(pawn_id):
		return {}
	var state: Dictionary = _meditation_state[pawn_id]
	state["ticks"] += 1
	var focus_str: float = FOCUS_TYPES[state["focus"]]["focus_strength"]
	var xp: float = focus_str * 0.5
	state["xp_gained"] += xp
	if not _psylink_levels.has(pawn_id):
		_psylink_levels[pawn_id] = {"level": 0, "xp": 0.0}
	_psylink_levels[pawn_id]["xp"] += xp
	_check_level_up(pawn_id)
	return {"xp_gained": xp, "total_xp": _psylink_levels[pawn_id]["xp"], "level": _psylink_levels[pawn_id]["level"]}

func _check_level_up(pawn_id: int) -> void:
	var data: Dictionary = _psylink_levels[pawn_id]
	while data["level"] < PSYLINK_XP_PER_LEVEL.size() - 1:
		var needed: float = PSYLINK_XP_PER_LEVEL[data["level"] + 1]
		if data["xp"] >= needed:
			data["level"] += 1
			data["xp"] -= needed
		else:
			break

func stop_meditation(pawn_id: int) -> void:
	_meditation_state.erase(pawn_id)

func get_psylink_level(pawn_id: int) -> int:
	return _psylink_levels.get(pawn_id, {}).get("level", 0)

func get_best_focus() -> String:
	var best: String = ""
	var best_str: float = 0.0
	for f: String in FOCUS_TYPES:
		if float(FOCUS_TYPES[f].get("focus_strength", 0.0)) > best_str:
			best_str = float(FOCUS_TYPES[f].get("focus_strength", 0.0))
			best = f
	return best


func get_highest_psylink_pawn() -> Dictionary:
	var best_id: int = -1
	var best_level: int = 0
	for pid: int in _psylink_levels:
		var lvl: int = int(_psylink_levels[pid].get("level", 0))
		if lvl > best_level:
			best_level = lvl
			best_id = pid
	if best_id < 0:
		return {}
	return {"pawn_id": best_id, "level": best_level}


func get_psycaster_count() -> int:
	var count: int = 0
	for pid: int in _psylink_levels:
		if int(_psylink_levels[pid].get("level", 0)) > 0:
			count += 1
	return count


func get_avg_psylink_level() -> float:
	if _psylink_levels.is_empty():
		return 0.0
	var total: int = 0
	for pid: int in _psylink_levels:
		total += int(_psylink_levels[pid].get("level", 0))
	return float(total) / _psylink_levels.size()


func get_weakest_focus() -> String:
	var worst: String = ""
	var worst_str: float = 999.0
	for f: String in FOCUS_TYPES:
		var s: float = float(FOCUS_TYPES[f].get("focus_strength", 0.0))
		if s < worst_str:
			worst_str = s
			worst = f
	return worst


func get_meditation_coverage() -> float:
	if _psylink_levels.is_empty():
		return 0.0
	return float(_meditation_state.size()) / _psylink_levels.size()


func get_focus_strength_range() -> Dictionary:
	var lo: float = 999.0
	var hi: float = 0.0
	for f: String in FOCUS_TYPES:
		var s: float = float(FOCUS_TYPES[f].get("focus_strength", 0.0))
		if s < lo:
			lo = s
		if s > hi:
			hi = s
	return {"min": snapped(lo, 0.01), "max": snapped(hi, 0.01)}


func get_avg_focus_strength() -> float:
	if FOCUS_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for f: String in FOCUS_TYPES:
		total += float(FOCUS_TYPES[f].get("focus_strength", 0.0))
	return snappedf(total / float(FOCUS_TYPES.size()), 0.01)


func get_max_level_pawn_count() -> int:
	var max_lvl: int = PSYLINK_XP_PER_LEVEL.size() - 1
	var count: int = 0
	for pid: int in _psylink_levels:
		if int(_psylink_levels[pid].get("level", 0)) >= max_lvl:
			count += 1
	return count


func get_spiritual_depth() -> String:
	var avg_level: float = get_avg_psylink_level()
	if avg_level >= 4.0:
		return "Transcendent"
	elif avg_level >= 2.5:
		return "Deep"
	elif avg_level >= 1.0:
		return "Awakening"
	return "Mundane"

func get_focus_quality() -> String:
	var avg: float = get_avg_focus_strength()
	if avg >= 0.8:
		return "Excellent"
	elif avg >= 0.5:
		return "Good"
	elif avg >= 0.25:
		return "Adequate"
	return "Poor"

func get_enlightenment_pct() -> float:
	if _meditation_state.is_empty():
		return 0.0
	var max_level: int = get_max_level_pawn_count()
	return snappedf(float(max_level) / float(_meditation_state.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"focus_types": FOCUS_TYPES.size(),
		"meditating_pawns": _meditation_state.size(),
		"max_psylink_level": PSYLINK_XP_PER_LEVEL.size() - 1,
		"psycasters": get_psycaster_count(),
		"best_focus": get_best_focus(),
		"avg_psylink": snapped(get_avg_psylink_level(), 0.1),
		"weakest_focus": get_weakest_focus(),
		"meditation_coverage": snapped(get_meditation_coverage(), 0.01),
		"focus_range": get_focus_strength_range(),
		"avg_focus": get_avg_focus_strength(),
		"max_level_pawns": get_max_level_pawn_count(),
		"spiritual_depth": get_spiritual_depth(),
		"focus_quality": get_focus_quality(),
		"enlightenment_pct": get_enlightenment_pct(),
		"inner_peace_index": get_inner_peace_index(),
		"psychic_growth_rate": get_psychic_growth_rate(),
		"meditation_discipline": get_meditation_discipline(),
		"spiritual_ecosystem_health": get_spiritual_ecosystem_health(),
		"meditation_governance": get_meditation_governance(),
		"enlightenment_maturity_index": get_enlightenment_maturity_index(),
	}

func get_inner_peace_index() -> float:
	var depth := get_spiritual_depth()
	var quality := get_focus_quality()
	var base := 50.0
	if depth in ["Profound", "Deep"]:
		base = 90.0
	elif depth in ["Moderate"]:
		base = 65.0
	if quality in ["Excellent", "Good"]:
		base += 10.0
	return snapped(minf(base, 100.0), 0.1)

func get_psychic_growth_rate() -> String:
	var coverage := get_meditation_coverage()
	var max_lvl := get_max_level_pawn_count()
	if coverage >= 0.5 and max_lvl >= 2:
		return "Rapid"
	elif coverage >= 0.2:
		return "Steady"
	return "Slow"

func get_meditation_discipline() -> String:
	var meditating := _meditation_state.size()
	var psycasters := get_psycaster_count()
	if psycasters <= 0:
		return "None"
	if float(meditating) / float(psycasters) >= 0.7:
		return "Disciplined"
	elif float(meditating) / float(psycasters) >= 0.3:
		return "Moderate"
	return "Lax"

func get_spiritual_ecosystem_health() -> float:
	var depth := get_spiritual_depth()
	var d_val: float = 90.0 if depth in ["Profound", "Deep"] else (60.0 if depth in ["Moderate", "Growing"] else 30.0)
	var discipline := get_meditation_discipline()
	var disc_val: float = 90.0 if discipline == "Disciplined" else (60.0 if discipline == "Moderate" else 30.0)
	var peace := get_inner_peace_index()
	return snapped((d_val + disc_val + minf(peace, 100.0)) / 3.0, 0.1)

func get_enlightenment_maturity_index() -> float:
	var growth := get_psychic_growth_rate()
	var g_val: float = 90.0 if growth in ["Rapid", "Accelerating"] else (60.0 if growth in ["Steady", "Moderate"] else 30.0)
	var quality := get_focus_quality()
	var q_val: float = 90.0 if quality in ["Excellent", "Superior"] else (60.0 if quality in ["Good", "Adequate"] else 30.0)
	var enlightenment := get_enlightenment_pct()
	return snapped((g_val + q_val + enlightenment) / 3.0, 0.1)

func get_meditation_governance() -> String:
	var ecosystem := get_spiritual_ecosystem_health()
	var maturity := get_enlightenment_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _meditation_state.size() > 0:
		return "Nascent"
	return "Dormant"
