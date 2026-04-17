extends Node

## Manages colony-wide social gatherings: parties, marriage ceremonies, and
## funerals. Participants gain mood bonuses. Registered as autoload "GatheringManager".

const GATHERING_DEFS: Dictionary = {
	"Party": {
		"label": "Party",
		"duration_ticks": 3000,
		"mood_bonus": 0.08,
		"thought": "AttendedParty",
		"min_colonists": 3,
		"cooldown_ticks": 10000,
	},
	"MarriageCeremony": {
		"label": "Marriage Ceremony",
		"duration_ticks": 2000,
		"mood_bonus": 0.10,
		"thought": "AttendedWedding",
		"min_colonists": 2,
		"cooldown_ticks": 0,
	},
	"Funeral": {
		"label": "Funeral",
		"duration_ticks": 1500,
		"mood_bonus": 0.04,
		"thought": "AttendedFuneral",
		"min_colonists": 2,
		"cooldown_ticks": 0,
	},
	"Feast": {
		"label": "Colony Feast",
		"duration_ticks": 4000,
		"mood_bonus": 0.10,
		"thought": "AttendedFeast",
		"min_colonists": 4,
		"cooldown_ticks": 15000,
	},
}

var _active_gathering: Dictionary = {}  # type -> {ticks_left, participants, pos}
var _cooldowns: Dictionary = {}  # type -> last_ended_tick
var _total_gatherings: int = 0
var _gatherings_by_type: Dictionary = {}
var _total_participants: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 99
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func start_gathering(gtype: String, pos: Vector2i, participant_ids: Array[int]) -> bool:
	if not GATHERING_DEFS.has(gtype):
		return false
	if _active_gathering.has(gtype):
		return false

	var def: Dictionary = GATHERING_DEFS[gtype]
	if participant_ids.size() < def.min_colonists:
		return false

	var current_tick: int = TickManager.current_tick if TickManager else 0
	if def.cooldown_ticks > 0:
		var last_ended: int = _cooldowns.get(gtype, 0)
		if current_tick - last_ended < def.cooldown_ticks:
			return false

	_active_gathering[gtype] = {
		"ticks_left": def.duration_ticks,
		"participants": participant_ids,
		"pos": pos,
	}
	_total_gatherings += 1
	_gatherings_by_type[gtype] = _gatherings_by_type.get(gtype, 0) + 1
	_total_participants += participant_ids.size()

	if ColonyLog:
		ColonyLog.add_entry("Social", def.label + " has started with " + str(participant_ids.size()) + " colonists!", "positive")

	return true


func _on_rare_tick(_tick: int) -> void:
	var ended: Array[String] = []
	for gtype: String in _active_gathering:
		_active_gathering[gtype].ticks_left -= 250
		if _active_gathering[gtype].ticks_left <= 0:
			ended.append(gtype)

	for gtype: String in ended:
		_end_gathering(gtype)

	_try_auto_party()


func _try_auto_party() -> void:
	if _active_gathering.has("Party"):
		return
	if _rng.randf() > 0.003:
		return
	if not PawnManager:
		return

	var eligible: Array[int] = []
	for p: Pawn in PawnManager.pawns:
		if not p.dead and not p.downed and not p.is_in_mental_break() and not p.drafted:
			eligible.append(p.id)

	if eligible.size() >= GATHERING_DEFS["Party"].min_colonists:
		var pos := Vector2i(50, 50)
		if PawnManager.pawns.size() > 0:
			pos = PawnManager.pawns[0].grid_pos
		start_gathering("Party", pos, eligible)


func _end_gathering(gtype: String) -> void:
	if not _active_gathering.has(gtype):
		return

	var gathering: Dictionary = _active_gathering[gtype]
	var def: Dictionary = GATHERING_DEFS.get(gtype, {})
	var thought: String = def.get("thought", "")

	for pid: int in gathering.get("participants", []):
		var pawn := _find_pawn(pid)
		if pawn and pawn.thought_tracker and not thought.is_empty():
			pawn.thought_tracker.add_thought(thought)

	_cooldowns[gtype] = TickManager.current_tick if TickManager else 0
	_active_gathering.erase(gtype)

	if ColonyLog:
		ColonyLog.add_entry("Social", def.get("label", gtype) + " has ended.", "info")


func _find_pawn(pid: int) -> Pawn:
	if not PawnManager:
		return null
	for p: Pawn in PawnManager.pawns:
		if p.id == pid:
			return p
	return null


func is_gathering_active(gtype: String = "") -> bool:
	if gtype.is_empty():
		return not _active_gathering.is_empty()
	return _active_gathering.has(gtype)


func get_most_popular() -> String:
	var best: String = ""
	var best_count: int = 0
	for t: String in _gatherings_by_type:
		if _gatherings_by_type[t] > best_count:
			best_count = _gatherings_by_type[t]
			best = t
	return best


func can_start_gathering(gtype: String) -> bool:
	if not GATHERING_DEFS.has(gtype):
		return false
	if _active_gathering.has(gtype):
		return false
	var def: Dictionary = GATHERING_DEFS[gtype]
	if def.cooldown_ticks > 0:
		var current_tick: int = TickManager.current_tick if TickManager else 0
		var last_ended: int = _cooldowns.get(gtype, 0)
		if current_tick - last_ended < def.cooldown_ticks:
			return false
	return true


func get_avg_participants() -> float:
	if _total_gatherings == 0:
		return 0.0
	return snappedf(float(_total_participants) / float(_total_gatherings), 0.1)


func get_available_gatherings() -> Array[String]:
	var result: Array[String] = []
	for gtype: String in GATHERING_DEFS:
		if can_start_gathering(gtype):
			result.append(gtype)
	return result


func get_gathering_frequency() -> float:
	if not TickManager or TickManager.current_tick <= 0:
		return 0.0
	return snappedf(float(_total_gatherings) / float(TickManager.current_tick) * 60000.0, 0.01)


func get_social_health() -> String:
	var freq: float = get_gathering_frequency()
	if freq >= 1.0:
		return "Vibrant"
	elif freq >= 0.3:
		return "Active"
	elif freq > 0.0:
		return "Sparse"
	return "None"

func get_type_coverage_pct() -> float:
	if GATHERING_DEFS.is_empty():
		return 0.0
	return snappedf(float(_gatherings_by_type.size()) / float(GATHERING_DEFS.size()) * 100.0, 0.1)

func get_engagement_rating() -> String:
	var avg: float = get_avg_participants()
	if avg >= 6.0:
		return "High"
	elif avg >= 3.0:
		return "Moderate"
	elif avg > 0.0:
		return "Low"
	return "None"

func get_community_vitality() -> String:
	var health := get_social_health()
	var engagement := get_engagement_rating()
	if health == "Healthy" and engagement == "High":
		return "Vibrant"
	elif health == "Healthy":
		return "Active"
	elif health == "Declining":
		return "Stagnant"
	return "Dormant"

func get_cultural_richness() -> float:
	var used := _gatherings_by_type.size()
	var available := GATHERING_DEFS.size()
	if available <= 0:
		return 0.0
	return snapped(float(used) / float(available) * 100.0, 0.1)

func get_social_infrastructure() -> String:
	var freq := get_gathering_frequency()
	var types := _gatherings_by_type.size()
	if freq >= 1.0 and types >= 3:
		return "Well Developed"
	elif freq > 0.0:
		return "Emerging"
	return "None"

func get_summary() -> Dictionary:
	var active_list: Array[String] = []
	for gtype: String in _active_gathering:
		active_list.append(gtype)
	return {
		"active": active_list,
		"total_gatherings": _total_gatherings,
		"by_type": _gatherings_by_type.duplicate(),
		"total_participants": _total_participants,
		"most_popular": get_most_popular(),
		"available_types": GATHERING_DEFS.size(),
		"avg_participants": get_avg_participants(),
		"available_now": get_available_gatherings().size(),
		"frequency_per_day": get_gathering_frequency(),
		"used_types": _gatherings_by_type.size(),
		"participation_rate": snappedf(float(_total_participants) / maxf(float(_total_gatherings), 1.0), 0.1),
		"social_health": get_social_health(),
		"type_coverage_pct": get_type_coverage_pct(),
		"engagement_rating": get_engagement_rating(),
		"community_vitality": get_community_vitality(),
		"cultural_richness_pct": get_cultural_richness(),
		"social_infrastructure": get_social_infrastructure(),
		"social_cohesion_index": get_social_cohesion_index(),
		"gathering_ecosystem_health": get_gathering_ecosystem_health(),
		"communal_maturity_score": get_communal_maturity_score(),
	}

func get_social_cohesion_index() -> float:
	var participation: float = float(_total_participants) / maxf(float(_total_gatherings), 1.0)
	var coverage: float = get_type_coverage_pct()
	return snappedf(clampf(participation * 10.0 + coverage * 0.5, 0.0, 100.0), 0.1)

func get_gathering_ecosystem_health() -> String:
	var freq: float = get_gathering_frequency()
	var health: String = get_social_health()
	if freq >= 0.5 and health in ["Thriving", "Healthy"]:
		return "Flourishing"
	if freq >= 0.2:
		return "Active"
	return "Stagnant"

func get_communal_maturity_score() -> float:
	var types_used: int = _gatherings_by_type.size()
	var total: int = _total_gatherings
	var richness: float = get_cultural_richness()
	return snappedf(clampf(float(types_used) * 10.0 + float(total) * 0.5 + richness * 0.3, 0.0, 100.0), 0.1)
