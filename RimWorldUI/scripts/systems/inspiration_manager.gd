extends Node

## Positive mental states that boost pawn performance temporarily.
## Counterpart to mental breaks. Registered as autoload "InspirationManager".

const INSPIRATION_DEFS: Dictionary = {
	"InspiredCreativity": {
		"label": "Inspired Creativity",
		"duration_ticks": 6000,
		"skill_boost": "Crafting",
		"work_bonus": 1.5,
		"mood_bonus": 0.08,
		"trigger_mood_min": 0.65,
	},
	"InspiredRecruitment": {
		"label": "Inspired Recruitment",
		"duration_ticks": 6000,
		"skill_boost": "Social",
		"work_bonus": 2.0,
		"mood_bonus": 0.05,
		"trigger_mood_min": 0.70,
	},
	"InspiredSurgery": {
		"label": "Inspired Surgery",
		"duration_ticks": 6000,
		"skill_boost": "Medical",
		"work_bonus": 1.8,
		"mood_bonus": 0.06,
		"trigger_mood_min": 0.70,
	},
	"InspiredTrade": {
		"label": "Inspired Trade",
		"duration_ticks": 6000,
		"skill_boost": "Social",
		"work_bonus": 1.6,
		"mood_bonus": 0.05,
		"trigger_mood_min": 0.65,
	},
	"ShootingFrenzy": {
		"label": "Shooting Frenzy",
		"duration_ticks": 5000,
		"skill_boost": "Shooting",
		"work_bonus": 1.7,
		"mood_bonus": 0.05,
		"trigger_mood_min": 0.60,
	},
}

const INSPIRATION_CHANCE: float = 0.008

var _active: Dictionary = {}  # pawn_id -> {type, ticks_left}
var _rng := RandomNumberGenerator.new()
var _total_inspired: int = 0
var _by_type: Dictionary = {}  # type -> count
var _history: Array[Dictionary] = []


func _ready() -> void:
	_rng.seed = 42
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func _on_rare_tick(_tick: int) -> void:
	_tick_active()
	_try_inspire()


func _tick_active() -> void:
	var expired: Array[int] = []
	for pid: int in _active:
		_active[pid].ticks_left -= 1
		if _active[pid].ticks_left <= 0:
			expired.append(pid)

	for pid: int in expired:
		_end_inspiration(pid)


func _try_inspire() -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed or p.is_in_mental_break():
			continue
		if _active.has(p.id):
			continue
		var mood: float = p.get_need("Mood")
		if mood < 0.55:
			continue
		if _rng.randf() > INSPIRATION_CHANCE:
			continue

		var candidates: Array[String] = []
		for itype: String in INSPIRATION_DEFS:
			if mood >= INSPIRATION_DEFS[itype].trigger_mood_min:
				candidates.append(itype)
		if candidates.is_empty():
			continue

		var chosen: String = candidates[_rng.randi_range(0, candidates.size() - 1)]
		_start_inspiration(p, chosen)


func _start_inspiration(pawn: Pawn, itype: String) -> void:
	var def: Dictionary = INSPIRATION_DEFS[itype]
	_active[pawn.id] = {"type": itype, "ticks_left": def.duration_ticks}
	_total_inspired += 1
	_by_type[itype] = _by_type.get(itype, 0) + 1
	_history.append({"pawn_id": pawn.id, "type": itype, "tick": TickManager.current_tick if TickManager else 0})
	if _history.size() > 50:
		_history = _history.slice(_history.size() - 50)

	if pawn.thought_tracker:
		pawn.thought_tracker.add_thought("Inspired")

	if ColonyLog:
		ColonyLog.add_entry("Inspiration", pawn.pawn_name + " gained " + def.label + "!", "positive")


func _end_inspiration(pid: int) -> void:
	if not _active.has(pid):
		return
	var itype: String = _active[pid].type
	_active.erase(pid)

	if ColonyLog:
		var def: Dictionary = INSPIRATION_DEFS.get(itype, {})
		ColonyLog.add_entry("Inspiration", "Inspiration (" + def.get("label", itype) + ") faded.", "info")


func is_inspired(pawn_id: int) -> bool:
	return _active.has(pawn_id)


func get_inspiration(pawn_id: int) -> Dictionary:
	if not _active.has(pawn_id):
		return {}
	var entry: Dictionary = _active[pawn_id]
	return INSPIRATION_DEFS.get(entry.type, {})


func get_work_bonus(pawn_id: int, skill_name: String) -> float:
	if not _active.has(pawn_id):
		return 1.0
	var entry: Dictionary = _active[pawn_id]
	var def: Dictionary = INSPIRATION_DEFS.get(entry.type, {})
	if def.get("skill_boost", "") == skill_name:
		return def.get("work_bonus", 1.0)
	return 1.0


func get_most_common_type() -> String:
	var best: String = ""
	var best_count: int = 0
	for t: String in _by_type:
		if _by_type[t] > best_count:
			best_count = _by_type[t]
			best = t
	return best


func get_pawn_inspiration_count(pawn_id: int) -> int:
	var count: int = 0
	for h: Dictionary in _history:
		if h.get("pawn_id", -1) == pawn_id:
			count += 1
	return count


func get_history(count: int = 10) -> Array[Dictionary]:
	var start: int = maxi(0, _history.size() - count)
	return _history.slice(start) as Array[Dictionary]


func force_inspiration(pawn: Pawn, itype: String) -> bool:
	if not INSPIRATION_DEFS.has(itype):
		return false
	if _active.has(pawn.id):
		return false
	_start_inspiration(pawn, itype)
	return true


func get_avg_duration_left() -> float:
	if _active.is_empty():
		return 0.0
	var total: float = 0.0
	for pid: int in _active:
		total += float(_active[pid].ticks_left)
	return snappedf(total / float(_active.size()), 0.1)


func get_most_inspired_pawn() -> int:
	var counts: Dictionary = {}
	for h: Dictionary in _history:
		var pid: int = h.get("pawn_id", -1)
		counts[pid] = counts.get(pid, 0) + 1
	var best_pid: int = -1
	var best_count: int = 0
	for pid: int in counts:
		if counts[pid] > best_count:
			best_count = counts[pid]
			best_pid = pid
	return best_pid


func get_inspiration_rate() -> float:
	if not TickManager or TickManager.current_tick <= 0:
		return 0.0
	return snappedf(float(_total_inspired) / float(TickManager.current_tick) * 60000.0, 0.01)


func get_unique_type_count() -> int:
	return _by_type.size()


func get_pawn_coverage() -> float:
	if not PawnManager:
		return 0.0
	var alive: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			alive += 1
	if alive == 0:
		return 0.0
	return float(_active.size()) / float(alive) * 100.0


func get_avg_work_bonus() -> float:
	if _active.is_empty():
		return 1.0
	var total: float = 0.0
	for pid: int in _active:
		var def: Dictionary = INSPIRATION_DEFS.get(_active[pid].type, {})
		total += def.get("work_bonus", 1.0)
	return snappedf(total / float(_active.size()), 0.01)

func get_rarest_type() -> String:
	if _by_type.is_empty():
		return ""
	var best: String = ""
	var best_c: int = 999999
	for t: String in _by_type:
		if _by_type[t] < best_c:
			best_c = _by_type[t]
			best = t
	return best

func get_inspiration_health() -> String:
	var coverage: float = get_pawn_coverage()
	if coverage >= 30.0:
		return "Thriving"
	elif coverage >= 10.0:
		return "Good"
	elif coverage > 0.0:
		return "Sparse"
	return "None"

func get_inspiration_momentum() -> String:
	var rate := get_inspiration_rate()
	if rate >= 1.0:
		return "Surging"
	elif rate >= 0.3:
		return "Steady"
	elif rate > 0.0:
		return "Slow"
	return "Stalled"

func get_talent_utilization() -> float:
	var unique := get_unique_type_count()
	if _total_inspired <= 0 or unique <= 0:
		return 0.0
	return snapped(float(unique) / float(_total_inspired) * 100.0, 0.1)

func get_creative_potential() -> String:
	var coverage := get_pawn_coverage()
	var bonus := get_avg_work_bonus()
	if coverage >= 20.0 and bonus >= 1.2:
		return "Exceptional"
	elif coverage >= 10.0:
		return "Promising"
	return "Latent"

func get_summary() -> Dictionary:
	var active_list: Array[Dictionary] = []
	for pid: int in _active:
		active_list.append({"pawn_id": pid, "type": _active[pid].type, "ticks_left": _active[pid].ticks_left})
	return {
		"active_inspirations": active_list.size(),
		"total_inspired": _total_inspired,
		"by_type": _by_type.duplicate(),
		"most_common": get_most_common_type(),
		"details": active_list,
		"avg_duration_left": get_avg_duration_left(),
		"most_inspired_pawn": get_most_inspired_pawn(),
		"rate_per_day": get_inspiration_rate(),
		"unique_types": get_unique_type_count(),
		"pawn_coverage_pct": snappedf(get_pawn_coverage(), 0.1),
		"avg_work_bonus": get_avg_work_bonus(),
		"rarest_type": get_rarest_type(),
		"inspiration_health": get_inspiration_health(),
		"inspiration_momentum": get_inspiration_momentum(),
		"talent_utilization_pct": get_talent_utilization(),
		"creative_potential": get_creative_potential(),
		"inspiration_ecosystem_health": get_inspiration_ecosystem_health(),
		"genius_cultivation_score": get_genius_cultivation_score(),
		"peak_performance_index": get_peak_performance_index(),
	}

func get_inspiration_ecosystem_health() -> String:
	var rate: float = get_inspiration_rate()
	var coverage: float = get_pawn_coverage()
	if rate >= 0.5 and coverage >= 30.0:
		return "Flourishing"
	if rate >= 0.2:
		return "Active"
	if _total_inspired > 0:
		return "Dormant"
	return "Inactive"

func get_genius_cultivation_score() -> float:
	var utilization: float = get_talent_utilization()
	var bonus: float = get_avg_work_bonus()
	var score: float = utilization * 0.5 + bonus * 10.0
	return snappedf(clampf(score, 0.0, 100.0), 0.1)

func get_peak_performance_index() -> float:
	var active: int = _active.size()
	var total_pawns: int = maxi(_total_inspired, 1)
	var rate: float = float(active) / float(total_pawns) * 100.0
	var coverage: float = get_pawn_coverage()
	return snappedf(clampf(rate * 0.4 + coverage * 0.6, 0.0, 100.0), 0.1)
