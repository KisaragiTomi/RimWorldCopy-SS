class_name JobDriverJoy
extends JobDriver

## Walk to joy facility or wander, perform activity, gain joy.

var _activity_name: String = "Walking"
var _joy_gain: float = 0.30
var _has_facility: bool = false


func _make_toils() -> Array[Dictionary]:
	_pick_activity()
	_has_facility = job.target_thing_id >= 0
	if _has_facility:
		return [
			{
				"name": "goto_facility",
				"complete_mode": "never",
			},
			{
				"name": "enjoy",
				"complete_mode": "delay",
				"delay_ticks": _get_duration(),
			},
			{
				"name": "finish_joy",
				"complete_mode": "instant",
			},
		]
	return [
		{
			"name": "wander_joy",
			"complete_mode": "never",
		},
		{
			"name": "enjoy",
			"complete_mode": "delay",
			"delay_ticks": _get_duration(),
		},
		{
			"name": "finish_joy",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"goto_facility":
			_start_walk_facility()
		"wander_joy":
			_start_wander()
		"finish_joy":
			_finish_joy()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"goto_facility", "wander_joy":
			_walk_tick()


func _pick_activity() -> void:
	if JoyManager:
		_activity_name = JoyManager.pick_activity(pawn)
		var def: Dictionary = JoyManager.get_activity_def(_activity_name)
		_joy_gain = def.get("joy_gain", 0.30)


func _get_duration() -> int:
	if JoyManager:
		var def: Dictionary = JoyManager.get_activity_def(_activity_name)
		return def.get("duration_ticks", 300)
	return 300


func _start_walk_facility() -> void:
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		end_job(false)
		return
	pawn.path = pf.find_path(pawn.grid_pos, job.target_pos)
	pawn.path_index = 0
	if pawn.path.is_empty():
		end_job(false)


func _start_wander() -> void:
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		end_job(false)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = randi()
	var target := Vector2i(
		pawn.grid_pos.x + rng.randi_range(-5, 5),
		pawn.grid_pos.y + rng.randi_range(-5, 5))
	target = target.clamp(Vector2i.ZERO, Vector2i(pf.map.width - 1, pf.map.height - 1))
	pawn.path = pf.find_path(pawn.grid_pos, target)
	pawn.path_index = 0


func _walk_tick() -> void:
	if not pawn.has_path():
		_advance_toil()
		return
	var next := pawn.next_path_step()
	pawn.set_grid_pos(next)


func _finish_joy() -> void:
	var gain: float = _joy_gain
	if _has_facility:
		gain *= 1.25

	var nearby_social: bool = _has_nearby_colonist()
	if nearby_social:
		gain *= 1.1
		if pawn.thought_tracker:
			pawn.thought_tracker.add_thought("HadGoodTime")

	pawn.set_need("Joy", minf(1.0, pawn.get_need("Joy") + gain))

	if JoyManager:
		JoyManager.record_activity(pawn.id, _activity_name)

	if ColonyLog:
		var suffix: String = " (social)" if nearby_social else ""
		ColonyLog.add_entry("Joy", "%s enjoyed %s%s." % [pawn.pawn_name, _activity_name, suffix], "info")

	end_job(true)


func _has_nearby_colonist() -> bool:
	if not PawnManager:
		return false
	for p: Pawn in PawnManager.pawns:
		if p == pawn or p.dead or p.downed:
			continue
		if p.has_meta("faction") and p.get_meta("faction") == "enemy":
			continue
		var dist: int = absi(p.grid_pos.x - pawn.grid_pos.x) + absi(p.grid_pos.y - pawn.grid_pos.y)
		if dist <= 4:
			return true
	return false


func get_expected_joy_gain() -> float:
	var gain: float = _joy_gain
	if _has_facility:
		gain *= 1.25
	return gain


func get_activity_name() -> String:
	return _activity_name


func is_social_activity() -> bool:
	return _has_nearby_colonist()


func _get_map() -> MapData:
	if GameState and GameState.has_method("get_map"):
		return GameState.get_map()
	return null
