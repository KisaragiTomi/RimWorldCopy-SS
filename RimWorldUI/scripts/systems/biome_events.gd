extends Node

## Triggers events specific to the colony's biome: volcanic eruptions,
## sandstorms, toxic fallout, cold snaps, etc.
## Registered as autoload "BiomeEvents".

const BIOME_EVENT_DEFS: Dictionary = {
	"ToxicFallout": {
		"label": "Toxic Fallout",
		"biomes": ["Temperate", "Boreal", "Tundra"],
		"chance": 0.003,
		"duration_ticks": 8000,
		"severity": "danger",
		"effects": {"outdoor_penalty": -0.08, "crop_damage": 0.5},
	},
	"VolcanicWinter": {
		"label": "Volcanic Winter",
		"biomes": ["Temperate", "Tropical", "Boreal"],
		"chance": 0.002,
		"duration_ticks": 15000,
		"severity": "danger",
		"effects": {"temp_offset": -12.0, "growth_penalty": 0.3},
	},
	"ColdSnap": {
		"label": "Cold Snap",
		"biomes": ["Temperate", "Boreal", "Tundra"],
		"chance": 0.005,
		"duration_ticks": 5000,
		"severity": "warning",
		"effects": {"temp_offset": -20.0},
	},
	"HeatWave": {
		"label": "Heat Wave",
		"biomes": ["Temperate", "Tropical", "Desert", "Arid"],
		"chance": 0.005,
		"duration_ticks": 5000,
		"severity": "warning",
		"effects": {"temp_offset": 15.0},
	},
	"Blight": {
		"label": "Crop Blight",
		"biomes": ["Temperate", "Tropical", "Boreal"],
		"chance": 0.004,
		"duration_ticks": 1,
		"severity": "warning",
		"effects": {"crop_destroy_chance": 0.5},
	},
	"AuroraDisplay": {
		"label": "Aurora Borealis",
		"biomes": ["Boreal", "Tundra", "IceSheet"],
		"chance": 0.008,
		"duration_ticks": 3000,
		"severity": "positive",
		"effects": {"mood_bonus": 0.06},
	},
}

var _active_events: Dictionary = {}  # event_type -> {ticks_left, effects}
var _current_biome: String = "Temperate"
var _total_events: int = 0
var _events_by_type: Dictionary = {}
var _event_history: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
const MAX_HISTORY: int = 30


func _ready() -> void:
	_rng.seed = 108
	if TickManager:
		TickManager.tick.connect(_on_tick)
		TickManager.rare_tick.connect(_on_rare_tick)


func set_biome(biome: String) -> void:
	_current_biome = biome


func _on_tick(_tick: int) -> void:
	var ended: Array[String] = []
	for etype: String in _active_events:
		_active_events[etype].ticks_left -= 1
		if _active_events[etype].ticks_left <= 0:
			ended.append(etype)
	for etype: String in ended:
		_end_event(etype)


func _on_rare_tick(_tick: int) -> void:
	_try_trigger_event()


func _try_trigger_event() -> void:
	for etype: String in BIOME_EVENT_DEFS:
		if _active_events.has(etype):
			continue
		var def: Dictionary = BIOME_EVENT_DEFS[etype]
		var biomes: Array = def.get("biomes", [])
		if not _current_biome in biomes:
			continue
		if _rng.randf() > def.chance:
			continue

		_start_event(etype, def)
		return


func _start_event(etype: String, def: Dictionary) -> void:
	_active_events[etype] = {
		"ticks_left": def.duration_ticks,
		"effects": def.effects,
	}
	_total_events += 1
	_events_by_type[etype] = _events_by_type.get(etype, 0) + 1
	_event_history.append({"type": etype, "tick": TickManager.current_tick if TickManager else 0})
	if _event_history.size() > MAX_HISTORY:
		_event_history.pop_front()

	if ColonyLog:
		ColonyLog.add_entry("BiomeEvent", def.label + " has begun!", def.severity)

	if etype == "AuroraDisplay" and PawnManager:
		for p: Pawn in PawnManager.pawns:
			if not p.dead and p.thought_tracker:
				p.thought_tracker.add_thought("AuroraDisplay")


func _end_event(etype: String) -> void:
	_active_events.erase(etype)
	var def: Dictionary = BIOME_EVENT_DEFS.get(etype, {})
	if ColonyLog:
		ColonyLog.add_entry("BiomeEvent", def.get("label", etype) + " has ended.", "info")


func get_temp_modifier() -> float:
	var total: float = 0.0
	for etype: String in _active_events:
		total += _active_events[etype].effects.get("temp_offset", 0.0)
	return total


func is_toxic_fallout_active() -> bool:
	return _active_events.has("ToxicFallout")


func get_active_events() -> Array[String]:
	var events: Array[String] = []
	for etype: String in _active_events:
		events.append(etype)
	return events


func get_most_common_event() -> String:
	var best: String = ""
	var best_count: int = 0
	for etype: String in _events_by_type:
		if _events_by_type[etype] > best_count:
			best_count = _events_by_type[etype]
			best = etype
	return best


func get_danger_event_count() -> int:
	var count: int = 0
	for etype: String in _events_by_type:
		var def: Dictionary = BIOME_EVENT_DEFS.get(etype, {})
		if def.get("severity", "") == "danger":
			count += _events_by_type[etype]
	return count


func get_event_history() -> Array[Dictionary]:
	return _event_history.duplicate()


func is_any_danger_active() -> bool:
	for etype: String in _active_events:
		var def: Dictionary = BIOME_EVENT_DEFS.get(etype, {})
		if def.get("severity", "") == "danger":
			return true
	return false


func get_positive_event_count() -> int:
	var count: int = 0
	for etype: String in _events_by_type:
		var def: Dictionary = BIOME_EVENT_DEFS.get(etype, {})
		if def.get("severity", "") == "positive":
			count += _events_by_type[etype]
	return count


func get_avg_duration_active() -> float:
	if _active_events.is_empty():
		return 0.0
	var total: float = 0.0
	for etype: String in _active_events:
		total += float(_active_events[etype].ticks_left)
	return snappedf(total / float(_active_events.size()), 0.1)


func get_event_frequency() -> float:
	if not TickManager or TickManager.current_tick <= 0:
		return 0.0
	return snappedf(float(_total_events) / float(TickManager.current_tick) * 60000.0, 0.01)


func get_danger_ratio_pct() -> float:
	if _total_events <= 0:
		return 0.0
	return snappedf(float(get_danger_event_count()) / float(_total_events) * 100.0, 0.1)

func get_event_balance() -> String:
	var pos: int = get_positive_event_count()
	var danger: int = get_danger_event_count()
	if pos > danger * 2:
		return "Favorable"
	elif pos > danger:
		return "Balanced"
	elif pos == danger:
		return "Neutral"
	return "Hostile"

func get_biome_severity() -> String:
	var freq: float = get_event_frequency()
	var danger: int = get_danger_event_count()
	if danger == 0 and freq < 0.1:
		return "Calm"
	elif danger <= 2:
		return "Mild"
	elif danger <= 5:
		return "Moderate"
	return "Severe"

func get_environmental_pressure() -> float:
	var danger := get_danger_event_count()
	var total := _total_events
	if total <= 0:
		return 0.0
	return snapped(float(danger) / float(total) * 100.0, 0.1)

func get_adaptation_readiness() -> String:
	var balance := get_event_balance()
	var severity := get_biome_severity()
	if balance == "Balanced" and severity != "Severe":
		return "Well Adapted"
	elif severity == "Severe":
		return "Overwhelmed"
	return "Adapting"

func get_ecological_volatility() -> String:
	var freq := get_event_frequency()
	if freq >= 1.0:
		return "Volatile"
	elif freq >= 0.3:
		return "Dynamic"
	elif freq > 0.0:
		return "Stable"
	return "Dormant"

func get_summary() -> Dictionary:
	var active: Array[Dictionary] = []
	for etype: String in _active_events:
		active.append({
			"type": etype,
			"ticks_left": _active_events[etype].ticks_left,
		})
	return {
		"biome": _current_biome,
		"active_events": active,
		"total_events": _total_events,
		"events_by_type": _events_by_type.duplicate(),
		"most_common": get_most_common_event(),
		"danger_count": get_danger_event_count(),
		"any_danger_active": is_any_danger_active(),
		"positive_events": get_positive_event_count(),
		"event_frequency": get_event_frequency(),
		"unique_event_types": _events_by_type.size(),
		"avg_events_per_type": snappedf(float(_total_events) / maxf(float(_events_by_type.size()), 1.0), 0.1),
		"danger_ratio_pct": get_danger_ratio_pct(),
		"event_balance": get_event_balance(),
		"biome_severity": get_biome_severity(),
		"environmental_pressure": get_environmental_pressure(),
		"adaptation_readiness": get_adaptation_readiness(),
		"ecological_volatility": get_ecological_volatility(),
		"biome_mastery_pct": get_biome_mastery_pct(),
		"disaster_preparedness": get_disaster_preparedness(),
		"ecosystem_health": get_ecosystem_health(),
	}

func get_biome_mastery_pct() -> float:
	var unique: int = _events_by_type.size()
	var total: int = _total_events
	if total <= 0:
		return 0.0
	var survival_rate := 1.0 - float(get_danger_event_count()) / float(total)
	return snapped(survival_rate * float(unique) / maxf(float(unique), 1.0) * 100.0, 0.1)

func get_disaster_preparedness() -> String:
	var pressure := get_environmental_pressure()
	var readiness := get_adaptation_readiness()
	if readiness in ["Ready", "Prepared"] and pressure in ["Low", "Moderate"]:
		return "Well Prepared"
	elif readiness in ["Ready", "Prepared"]:
		return "Adequate"
	return "Vulnerable"

func get_ecosystem_health() -> String:
	var balance := get_event_balance()
	var volatility := get_ecological_volatility()
	if balance in ["Balanced", "Positive"] and volatility in ["Low", "Stable"]:
		return "Thriving"
	elif balance != "Negative":
		return "Stable"
	return "Stressed"
