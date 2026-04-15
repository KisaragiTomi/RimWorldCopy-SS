extends Node

## Expands mental break types beyond the base 3 (Wander/BingeEat/Hide).
## Adds Berserk, Tantrum, InsultingSpree, SadWander, RunWild.
## Registered as autoload "MentalBreakExpanded".

const BREAK_DEFS: Dictionary = {
	"Berserk": {
		"label": "Berserk rage",
		"severity": "major",
		"duration_range": [2500, 6000],
		"mood_max": 0.05,
		"description": "Attacks anyone nearby in blind rage.",
	},
	"Tantrum": {
		"label": "Tantrum",
		"severity": "major",
		"duration_range": [1500, 4000],
		"mood_max": 0.10,
		"description": "Destroys nearby items and furniture.",
	},
	"InsultingSpree": {
		"label": "Insulting spree",
		"severity": "minor",
		"duration_range": [2000, 5000],
		"mood_max": 0.15,
		"description": "Insults every colonist they encounter.",
	},
	"SadWander": {
		"label": "Sad wandering",
		"severity": "minor",
		"duration_range": [3000, 7000],
		"mood_max": 0.12,
		"description": "Wanders the colony in a daze of sadness.",
	},
	"RunWild": {
		"label": "Run wild",
		"severity": "major",
		"duration_range": [4000, 10000],
		"mood_max": 0.05,
		"description": "Runs off into the wilderness.",
	},
}

var _rng := RandomNumberGenerator.new()
var _active_breaks: Dictionary = {}  # pawn_id -> {type, ticks_left, data}
var _total_breaks: int = 0
var _breaks_by_type: Dictionary = {}
var _break_history: Array[Dictionary] = []


func _ready() -> void:
	_rng.seed = 61
	if TickManager:
		TickManager.tick.connect(_on_tick)
		TickManager.rare_tick.connect(_on_rare_tick)


func _on_rare_tick(_tick: int) -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed or p.is_in_mental_break():
			continue
		if _active_breaks.has(p.id):
			continue
		_try_trigger(p)


func _try_trigger(pawn: Pawn) -> void:
	var mood: float = pawn.get_need("Mood")
	if mood > 0.15:
		return

	var candidates: Array[String] = []
	for btype: String in BREAK_DEFS:
		var def: Dictionary = BREAK_DEFS[btype]
		if mood <= def.mood_max:
			candidates.append(btype)

	if candidates.is_empty():
		return

	var break_mod: float = TraitSystem.get_mental_break_modifier(pawn.traits) if TraitSystem else 1.0
	if _rng.randf() > 0.02 * break_mod:
		return

	var chosen: String = candidates[_rng.randi_range(0, candidates.size() - 1)]
	_start_break(pawn, chosen)


func _start_break(pawn: Pawn, btype: String) -> void:
	var def: Dictionary = BREAK_DEFS[btype]
	var duration: int = _rng.randi_range(def.duration_range[0], def.duration_range[1])

	_active_breaks[pawn.id] = {
		"type": btype,
		"ticks_left": duration,
		"targets_hit": 0,
	}
	_total_breaks += 1
	_breaks_by_type[btype] = _breaks_by_type.get(btype, 0) + 1
	_break_history.append({"pawn_id": pawn.id, "type": btype, "tick": TickManager.current_tick if TickManager else 0})
	if _break_history.size() > 50:
		_break_history = _break_history.slice(_break_history.size() - 50)

	if pawn.thought_tracker:
		pawn.thought_tracker.add_thought("MentalBreak")

	if ColonyLog:
		ColonyLog.add_entry("MentalBreak", pawn.pawn_name + ": " + def.label + "!", "danger")


func _on_tick(_tick: int) -> void:
	var ended_pids: Array[int] = []
	for pid: int in _active_breaks:
		var entry: Dictionary = _active_breaks[pid]
		entry.ticks_left -= 1
		if entry.ticks_left <= 0:
			ended_pids.append(pid)
			continue
		_tick_break_behavior(pid, entry)

	for pid: int in ended_pids:
		_end_break(pid)


func _tick_break_behavior(pid: int, entry: Dictionary) -> void:
	var pawn := _find_pawn(pid)
	if pawn == null or pawn.dead:
		_active_breaks.erase(pid)
		return

	match entry.type:
		"Berserk":
			if entry.ticks_left % 60 == 0:
				_attack_nearby(pawn)
		"Tantrum":
			if entry.ticks_left % 80 == 0:
				_destroy_nearby_item(pawn)
		"InsultingSpree":
			if entry.ticks_left % 100 == 0:
				_insult_nearby(pawn)
		"SadWander", "RunWild":
			pass


func _attack_nearby(pawn: Pawn) -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.id == pawn.id or p.dead:
			continue
		if pawn.grid_pos.distance_to(p.grid_pos) < 3.0:
			var dmg := _rng.randi_range(3, 10)
			var parts := ["Torso", "Head", "LeftArm", "RightArm"]
			var target_part: String = parts[_rng.randi_range(0, parts.size() - 1)]
			p.health.add_injury(target_part, float(dmg), "Blunt")
			_active_breaks[pawn.id].targets_hit += 1
			return


func _destroy_nearby_item(pawn: Pawn) -> void:
	if not ThingManager:
		return
	for t: Thing in ThingManager.things:
		if pawn.grid_pos.distance_to(t.grid_pos) < 4.0:
			if t is Item or (t is Building and t.def_name != "Wall"):
				t.take_damage(50)
				_active_breaks[pawn.id].targets_hit += 1
				return


func _insult_nearby(pawn: Pawn) -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.id == pawn.id or p.dead:
			continue
		if pawn.grid_pos.distance_to(p.grid_pos) < 6.0:
			if p.thought_tracker:
				p.thought_tracker.add_thought("WasInsulted")
			_active_breaks[pawn.id].targets_hit += 1
			return


func _end_break(pid: int) -> void:
	if not _active_breaks.has(pid):
		return
	var btype: String = _active_breaks[pid].type
	_active_breaks.erase(pid)
	var pawn := _find_pawn(pid)
	if pawn and pawn.thought_tracker:
		pawn.thought_tracker.add_thought("Catharsis")
	if ColonyLog:
		var name_str: String = pawn.pawn_name if pawn else str(pid)
		ColonyLog.add_entry("MentalBreak", name_str + " recovered from " + btype + ".", "info")


func is_in_expanded_break(pid: int) -> bool:
	return _active_breaks.has(pid)


func get_break_type(pid: int) -> String:
	if not _active_breaks.has(pid):
		return ""
	return _active_breaks[pid].type


func _find_pawn(pid: int) -> Pawn:
	if not PawnManager:
		return null
	for p: Pawn in PawnManager.pawns:
		if p.id == pid:
			return p
	return null


func get_most_common_break() -> String:
	var best: String = ""
	var best_count: int = 0
	for t: String in _breaks_by_type:
		if _breaks_by_type[t] > best_count:
			best_count = _breaks_by_type[t]
			best = t
	return best


func get_break_history(count: int = 10) -> Array[Dictionary]:
	var start: int = maxi(0, _break_history.size() - count)
	return _break_history.slice(start) as Array[Dictionary]


func get_pawn_break_count(pawn_id: int) -> int:
	var count: int = 0
	for h: Dictionary in _break_history:
		if h.get("pawn_id", -1) == pawn_id:
			count += 1
	return count


func get_total_damage_dealt() -> int:
	var total: int = 0
	for pid: int in _active_breaks:
		total += _active_breaks[pid].get("targets_hit", 0)
	return total


func get_avg_break_duration() -> float:
	if _active_breaks.is_empty():
		return 0.0
	var total: float = 0.0
	for pid: int in _active_breaks:
		total += float(_active_breaks[pid].ticks_left)
	return snappedf(total / float(_active_breaks.size()), 0.1)


func get_most_destructive_pawn() -> int:
	var counts: Dictionary = {}
	for h: Dictionary in _break_history:
		var pid: int = h.get("pawn_id", -1)
		counts[pid] = counts.get(pid, 0) + 1
	var best_pid: int = -1
	var best_n: int = 0
	for pid: int in counts:
		if counts[pid] > best_n:
			best_n = counts[pid]
			best_pid = pid
	return best_pid


func get_major_break_count() -> int:
	var count: int = 0
	for btype: String in _breaks_by_type:
		if BREAK_DEFS.get(btype, {}).get("severity", "") == "major":
			count += _breaks_by_type[btype]
	return count


func get_minor_break_type_count() -> int:
	var count: int = 0
	for btype: String in BREAK_DEFS:
		if BREAK_DEFS[btype].get("severity", "") == "minor":
			count += 1
	return count


func get_hardest_trigger_break() -> String:
	var best: String = ""
	var lowest_mood: float = 999.0
	for btype: String in BREAK_DEFS:
		var mm: float = float(BREAK_DEFS[btype].get("mood_max", 999.0))
		if mm < lowest_mood:
			lowest_mood = mm
			best = btype
	return best


func get_avg_mood_max() -> float:
	if BREAK_DEFS.is_empty():
		return 0.0
	var total: float = 0.0
	for btype: String in BREAK_DEFS:
		total += float(BREAK_DEFS[btype].get("mood_max", 0.0))
	return total / BREAK_DEFS.size()


func get_major_ratio_pct() -> float:
	if _total_breaks <= 0:
		return 0.0
	return snappedf(float(get_major_break_count()) / float(_total_breaks) * 100.0, 0.1)

func get_colony_stability() -> String:
	if _active_breaks.is_empty() and _total_breaks == 0:
		return "Stable"
	elif _active_breaks.is_empty():
		return "Recovered"
	elif _active_breaks.size() <= 1:
		return "Stressed"
	return "Crisis"

func get_break_trend() -> String:
	if _total_breaks <= 0:
		return "None"
	elif _active_breaks.size() > _total_breaks * 0.3:
		return "Worsening"
	elif _active_breaks.is_empty():
		return "Improving"
	return "Ongoing"

func get_vulnerability_index() -> String:
	var major: int = get_major_break_count()
	var total: int = _total_breaks
	if total == 0:
		return "safe"
	var severity: float = major * 2.0 + (total - major)
	var per_break: float = severity / total
	if per_break >= 1.6:
		return "critical"
	if per_break >= 1.2:
		return "elevated"
	return "low"

func get_recidivism_rate_pct() -> float:
	var pawn_counts: Dictionary = {}
	for pid: int in _active_breaks:
		pawn_counts[pid] = pawn_counts.get(pid, 0) + 1
	var repeat_offenders: int = 0
	for pid: int in pawn_counts:
		if pawn_counts[pid] > 1:
			repeat_offenders += 1
	if pawn_counts.is_empty():
		return 0.0
	return snapped(repeat_offenders * 100.0 / pawn_counts.size(), 0.1)

func get_intervention_urgency() -> String:
	var active: int = _active_breaks.size()
	if active == 0:
		return "none"
	var major_active: int = 0
	for pid: int in _active_breaks:
		var btype: String = _active_breaks[pid].type
		if BREAK_DEFS.has(btype) and BREAK_DEFS[btype]["severity"] == "major":
			major_active += 1
	if major_active >= 2:
		return "emergency"
	if active >= 3 or major_active >= 1:
		return "high"
	return "moderate"

func get_emotional_resilience() -> String:
	var stability := get_colony_stability()
	var recid := get_recidivism_rate_pct()
	if stability == "Stable" and recid < 10.0:
		return "Strong"
	elif stability == "Shaky":
		return "Fragile"
	return "Moderate"

func get_crisis_readiness() -> String:
	var urgency := get_intervention_urgency()
	var trend := get_break_trend()
	if urgency == "none" and trend != "Worsening":
		return "Prepared"
	elif urgency == "emergency":
		return "Overwhelmed"
	return "Alert"

func get_break_severity_index() -> float:
	if _total_breaks <= 0:
		return 0.0
	var major := get_major_break_count()
	return snapped(float(major) / float(_total_breaks) * 100.0, 0.1)

func get_summary() -> Dictionary:
	var active_list: Array[Dictionary] = []
	for pid: int in _active_breaks:
		active_list.append({
			"pawn_id": pid,
			"type": _active_breaks[pid].type,
			"ticks_left": _active_breaks[pid].ticks_left,
			"targets_hit": _active_breaks[pid].get("targets_hit", 0),
		})
	return {
		"active_breaks": active_list.size(),
		"total_breaks": _total_breaks,
		"by_type": _breaks_by_type.duplicate(),
		"most_common": get_most_common_break(),
		"details": active_list,
		"avg_duration_left": get_avg_break_duration(),
		"most_destructive_pawn": get_most_destructive_pawn(),
		"major_breaks": get_major_break_count(),
		"unique_break_types": _breaks_by_type.size(),
		"break_frequency": snappedf(float(_total_breaks) / maxf(float(_active_breaks.size() + 1), 1.0), 0.01),
		"minor_types": get_minor_break_type_count(),
		"hardest_trigger": get_hardest_trigger_break(),
		"avg_mood_max": snapped(get_avg_mood_max(), 0.001),
		"major_ratio_pct": get_major_ratio_pct(),
		"colony_stability": get_colony_stability(),
		"break_trend": get_break_trend(),
		"vulnerability_index": get_vulnerability_index(),
		"recidivism_rate_pct": get_recidivism_rate_pct(),
		"intervention_urgency": get_intervention_urgency(),
		"emotional_resilience": get_emotional_resilience(),
		"crisis_readiness": get_crisis_readiness(),
		"break_severity_index": get_break_severity_index(),
		"psychological_safety_net": get_psychological_safety_net(),
		"mental_health_infrastructure": get_mental_health_infrastructure(),
		"colony_sanity_forecast": get_colony_sanity_forecast(),
	}

func get_psychological_safety_net() -> float:
	var resilience: String = get_emotional_resilience()
	var readiness: String = get_crisis_readiness()
	var base: float = 50.0
	if resilience == "Strong":
		base += 30.0
	elif resilience == "Moderate":
		base += 15.0
	if readiness == "Ready":
		base += 20.0
	elif readiness == "Partial":
		base += 10.0
	return snappedf(clampf(base, 0.0, 100.0), 0.1)

func get_mental_health_infrastructure() -> String:
	var stability: String = get_colony_stability()
	var severity: float = get_break_severity_index()
	if stability == "Stable" and severity <= 30.0:
		return "Robust"
	if stability in ["Stable", "Shaky"]:
		return "Adequate"
	return "Insufficient"

func get_colony_sanity_forecast() -> String:
	var trend: String = get_break_trend()
	var major_pct: float = get_major_ratio_pct()
	if trend == "Declining" and major_pct <= 20.0:
		return "Improving"
	if trend == "Stable":
		return "Stable"
	return "Deteriorating"
