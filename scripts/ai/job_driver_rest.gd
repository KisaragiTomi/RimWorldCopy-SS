class_name JobDriverRest
extends JobDriver

## Walk to bed (if available), sleep, restore Rest need with quality modifier.

var _bed: Building = null
var _rest_quality: float = 0.6


func _make_toils() -> Array[Dictionary]:
	_find_bed()
	if _bed:
		return [
			{
				"name": "goto_bed",
				"complete_mode": "never",
			},
			{
				"name": "sleep",
				"complete_mode": "delay",
				"delay_ticks": 600,
			},
			{
				"name": "wake",
				"complete_mode": "instant",
			},
		]
	return [
		{
			"name": "sleep_ground",
			"complete_mode": "delay",
			"delay_ticks": 600,
		},
		{
			"name": "wake",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"goto_bed":
			_start_walk()
		"wake":
			_finish_rest()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"goto_bed":
			_walk_tick()


func _find_bed() -> void:
	if BedManager:
		_bed = BedManager.find_best_bed(pawn)
		if _bed:
			_rest_quality = BedManager.BED_QUALITY.get(_bed.def_name, 0.9)


func _start_walk() -> void:
	if _bed == null:
		_fallback_to_ground()
		return
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		_fallback_to_ground()
		return
	pawn.path = pf.find_path(pawn.grid_pos, _bed.grid_pos)
	pawn.path_index = 0
	if pawn.path.is_empty():
		_fallback_to_ground()


func _fallback_to_ground() -> void:
	_bed = null
	_rest_quality = 0.6
	_toils = [
		{"name": "sleep_ground", "complete_mode": "delay", "delay_ticks": 600},
		{"name": "wake", "complete_mode": "instant"},
	]
	_toil_index = 0
	_toil_ticks = 0


func _walk_tick() -> void:
	if not pawn.has_path():
		_advance_toil()
		return
	var next := pawn.next_path_step()
	pawn.set_grid_pos(next)


func _start_sleep() -> void:
	pass


func _finish_rest() -> void:
	var rest_gain: float = 0.7 * _rest_quality
	pawn.set_need("Rest", minf(1.0, pawn.get_need("Rest") + rest_gain))

	if BedManager:
		BedManager.apply_sleep_thought(pawn)

	if _bed:
		var room_thought: String = _get_bedroom_thought()
		if not room_thought.is_empty() and pawn.thought_tracker:
			pawn.thought_tracker.add_thought(room_thought)

	if ColonyLog:
		if _bed:
			ColonyLog.add_entry("Rest", "%s slept in bed (quality %.0f%%)." % [pawn.pawn_name, _rest_quality * 100.0], "info")
		else:
			ColonyLog.add_entry("Rest", "%s slept on the ground." % pawn.pawn_name, "info")

	end_job(true)


func _get_bedroom_thought() -> String:
	if _bed == null:
		return ""
	var map: MapData = _get_map()
	if map == null:
		return ""
	if RoomService:
		return RoomService.get_room_mood_thought(_bed.grid_pos)
	return ""


func get_expected_rest_gain() -> float:
	return 0.7 * _rest_quality


func is_sleeping_on_ground() -> bool:
	return _bed == null


func get_sleep_quality_label() -> String:
	if _rest_quality >= 0.9:
		return "Excellent"
	elif _rest_quality >= 0.7:
		return "Good"
	elif _rest_quality >= 0.5:
		return "Normal"
	return "Poor"


func get_rest_threshold() -> float:
	return pawn.get_need("Rest") if pawn else 0.0


func get_rest_gain_estimate() -> float:
	return snappedf(0.7 * _rest_quality, 0.01)


func get_sleep_efficiency() -> float:
	var base_gain := get_rest_gain_estimate()
	var quality_mult := _rest_quality
	return snapped(base_gain * quality_mult * 100.0, 0.1)

func get_comfort_deficit() -> float:
	if _bed != null:
		return 0.0
	return snapped((1.0 - _rest_quality) * 100.0, 0.1)

func get_recovery_forecast() -> float:
	var current := get_rest_threshold()
	var gain := get_rest_gain_estimate()
	if gain <= 0.0:
		return 999.0
	var needed := maxf(0.0, 1.0 - current)
	return snapped(needed / gain * 2500.0, 1.0)

func get_rest_summary() -> Dictionary:
	return {
		"has_bed": _bed != null,
		"quality_label": get_sleep_quality_label(),
		"rest_quality": snappedf(_rest_quality, 0.01),
		"expected_gain": get_rest_gain_estimate(),
		"is_ground": is_sleeping_on_ground(),
		"current_rest": get_rest_threshold(),
		"sleep_efficiency": get_sleep_efficiency(),
		"comfort_deficit": get_comfort_deficit(),
		"recovery_forecast": get_recovery_forecast(),
	}


func _get_map() -> MapData:
	if GameState and GameState.has_method("get_map"):
		return GameState.get_map()
	return null
