extends Node

## Event/incident system with cooldowns, more event types, and storyteller integration.
## Registered as autoload "IncidentManager".

signal incident_fired(incident_name: String, data: Dictionary)

var _rng := RandomNumberGenerator.new()
var _next_incident_tick: int = 0
var _incident_interval_min := 6000
var _incident_interval_max := 18000
var storyteller: Storyteller = Storyteller.new(Storyteller.Type.CASSANDRA)
var _last_day: int = 0
var _cooldowns: Dictionary = {}
var incident_history: Array[Dictionary] = []
var total_incidents: int = 0

const COOLDOWN_TICKS: Dictionary = {
	"Raid": 45000, "Disease": 20000, "WandererJoin": 30000,
	"Eclipse": 15000, "Blight": 10000, "AnimalHerd": 8000,
	"PsychicDrone": 12000, "ManInBlack": 20000,
}

const WANDERER_NAMES := ["Riley", "Jordan", "Quinn", "Blake", "Morgan", "Casey",
	"Avery", "Taylor", "Drew", "Reese", "Parker", "Sage",
	"Logan", "Skyler", "Rowan", "Finley", "Harper", "Ellis",
	"Hayden", "Addison", "Charlie", "Emery", "Dakota", "Kendall",
	"River", "Phoenix", "Oakley", "Lennox", "Marlowe", "Salem",
	"Ash", "Harley", "Remy", "Peyton", "Shiloh", "Zion",
	"Briar", "Indigo", "Wren", "Sawyer", "Kai", "Soren",
	"Cypress", "Lark", "Juniper", "Hollis", "Vale", "Sutton",
	"Sterling", "Haven"]

const DROP_RESOURCES := ["Steel", "Wood", "Components", "Silver", "Gold", "Plasteel"]


func _ready() -> void:
	_rng.seed = randi()
	_schedule_next()
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)
		TickManager.long_tick.connect(_on_long_tick)


func set_storyteller(stype: int) -> void:
	storyteller = Storyteller.new(stype as Storyteller.Type)


func _schedule_next() -> void:
	_next_incident_tick = (TickManager.current_tick if TickManager else 0) + _rng.randi_range(_incident_interval_min, _incident_interval_max)


func _pick_unique_name() -> String:
	var used: Dictionary = {}
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			used[p.pawn_name] = true
	var available: Array = WANDERER_NAMES.filter(func(n: String) -> bool: return not used.has(n))
	if available.is_empty():
		return WANDERER_NAMES[_rng.randi_range(0, WANDERER_NAMES.size() - 1)] + "_" + str(_rng.randi_range(1, 99))
	return available[_rng.randi_range(0, available.size() - 1)]


func _is_on_cooldown(event_name: String) -> bool:
	var last_tick: int = _cooldowns.get(event_name, -999999)
	var cd: int = COOLDOWN_TICKS.get(event_name, 3000)
	var now: int = TickManager.current_tick if TickManager else 0
	return (now - last_tick) < cd


func _record_incident(event_name: String, data: Dictionary) -> void:
	var now: int = TickManager.current_tick if TickManager else 0
	_cooldowns[event_name] = now
	total_incidents += 1
	incident_history.append({"name": event_name, "tick": now, "data": data})
	if incident_history.size() > 50:
		incident_history.pop_front()
	incident_fired.emit(event_name, data)


func _on_rare_tick(current_tick: int) -> void:
	if current_tick >= _next_incident_tick:
		_fire_random_incident()
		_schedule_next()


func _on_long_tick(_tick: int) -> void:
	if not GameState:
		return
	var current_day: int = GameState.game_date.get("day", 0)
	if current_day == _last_day:
		return
	_last_day = current_day
	_ensure_beds()

	var wealth := _calc_colony_wealth()
	var pawn_count: int = 0
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if not p.has_meta("faction") or p.get_meta("faction") != "enemy":
				pawn_count += 1
	var result := storyteller.should_fire_incident(wealth, pawn_count, current_day)
	if result.is_empty():
		return

	var event_name: String = result.get("event", "")
	if _is_on_cooldown(event_name):
		return

	match event_name:
		"Raid":
			if RaidManager:
				var max_raiders := clampi(pawn_count / 3, 2, 6)
				var raider_count := clampi(roundi(result.get("points", 30.0) / 30.0), 1, max_raiders)
				RaidManager.spawn_raid(raider_count)
				_record_incident("Raid", {"count": raider_count})
		"TraderVisit":
			if TradeManager:
				TradeManager.spawn_trader()
				_record_incident("TraderVisit", {})
		"WandererJoin":
			_incident_wanderer_join()
		"ResourceDrop":
			_incident_resource_drop()
		"TemperatureShift":
			_incident_temperature_shift()
		"Disease":
			_incident_disease()
		"Eclipse":
			_incident_eclipse()
		"Blight":
			_incident_blight()
		"AnimalHerd":
			_incident_animal_herd()
		"PsychicDrone":
			_incident_psychic_drone()
		"ManInBlack":
			_incident_man_in_black()


func _calc_colony_wealth() -> float:
	var wealth: float = 0.0
	if ThingManager:
		for t: Thing in ThingManager.things:
			if t is Item:
				wealth += (t as Item).get_market_value()
			elif t is Building:
				wealth += 50.0
	if TradeManager:
		wealth += TradeManager.colony_silver
	return wealth


const RANDOM_EVENTS: Array[Dictionary] = [
	{"name": "WandererJoin", "weight": 6, "min_day": 3, "category": "positive"},
	{"name": "ResourceDrop", "weight": 20, "min_day": 0, "category": "positive"},
	{"name": "TemperatureShift", "weight": 15, "min_day": 3, "category": "neutral"},
	{"name": "AnimalHerd", "weight": 10, "min_day": 2, "category": "positive"},
	{"name": "Eclipse", "weight": 5, "min_day": 10, "category": "neutral"},
	{"name": "Disease", "weight": 8, "min_day": 8, "category": "negative"},
	{"name": "Blight", "weight": 6, "min_day": 12, "category": "negative"},
	{"name": "PsychicDrone", "weight": 4, "min_day": 20, "category": "negative"},
]


func _get_total_elapsed_days() -> int:
	if not TickManager:
		return 0
	return TickManager.current_tick / (TickManager.TICKS_PER_HOUR * TickManager.HOURS_PER_DAY)


func _fire_random_incident() -> void:
	var current_day: int = _get_total_elapsed_days()
	var eligible: Array[Dictionary] = []
	var total_weight: float = 0.0
	for ev: Dictionary in RANDOM_EVENTS:
		if current_day >= ev.get("min_day", 0) and not _is_on_cooldown(ev["name"]):
			eligible.append(ev)
			total_weight += float(ev["weight"])

	if eligible.is_empty():
		return

	var roll: float = _rng.randf() * total_weight
	var cumulative: float = 0.0
	var chosen: String = eligible[0]["name"]
	for ev: Dictionary in eligible:
		cumulative += float(ev["weight"])
		if roll <= cumulative:
			chosen = ev["name"]
			break

	match chosen:
		"WandererJoin": _incident_wanderer_join()
		"ResourceDrop": _incident_resource_drop()
		"TemperatureShift": _incident_temperature_shift()
		"AnimalHerd": _incident_animal_herd()
		"Eclipse": _incident_eclipse()
		"Disease": _incident_disease()
		"Blight": _incident_blight()
		"PsychicDrone": _incident_psychic_drone()


const MAX_COLONISTS: int = 6

func _incident_wanderer_join() -> void:
	if not PawnManager or _is_on_cooldown("WandererJoin"):
		return
	var alive_count: int = 0
	for existing: Pawn in PawnManager.pawns:
		if not existing.dead and (not existing.has_meta("faction") or existing.get_meta("faction") != "enemy"):
			alive_count += 1
	if alive_count >= MAX_COLONISTS:
		return
	var p := Pawn.new()
	p.pawn_name = _pick_unique_name()
	p.age = _rng.randi_range(18, 55)
	var map: MapData = GameState.get_map() if GameState else null
	if map:
		var center := Vector2i(map.width / 2, map.height / 2)
		var spawn_pos := center
		for _attempt: int in 20:
			var dx: int = _rng.randi_range(-10, 10)
			var dy: int = _rng.randi_range(-10, 10)
			var candidate := center + Vector2i(dx, dy)
			if map.in_bounds(candidate.x, candidate.y):
				var cell := map.get_cell_v(candidate)
				if cell and cell.is_passable():
					spawn_pos = candidate
					break
		p.set_grid_pos(spawn_pos)
	PawnManager.add_pawn(p)
	_record_incident("WandererJoin", {"pawn_name": p.pawn_name})
	_ensure_beds()


func _ensure_beds() -> void:
	if not ThingManager or not PawnManager:
		return
	var map: MapData = GameState.get_map() if GameState else null
	if not map:
		return
	var bed_count: int = 0
	var bed_center := Vector2i(map.width / 2, map.height / 2)
	for t: Thing in ThingManager._buildings:
		if t.def_name == "Bed":
			bed_count += 1
			bed_center = Vector2i(t.grid_pos.x, t.grid_pos.y)
	var alive: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead and (not p.has_meta("faction") or p.get_meta("faction") != "enemy"):
			alive += 1
	var deficit: int = alive - bed_count + 2
	if deficit <= 0:
		return
	var placed: int = 0
	for ring: int in range(1, 10):
		if placed >= deficit:
			break
		for dx: int in range(-ring, ring + 1):
			for dy: int in range(-ring, ring + 1):
				if abs(dx) != ring and abs(dy) != ring:
					continue
				if placed >= deficit:
					break
				var pos := bed_center + Vector2i(dx, dy)
				if not map.in_bounds(pos.x, pos.y):
					continue
				var cell := map.get_cell_v(pos)
				if cell and cell.is_passable() and not cell.building:
					ThingManager.place_blueprint("Bed", pos)
					placed += 1


func _incident_resource_drop() -> void:
	if not GameState:
		return
	var res_name: String = DROP_RESOURCES[_rng.randi_range(0, DROP_RESOURCES.size() - 1)]
	var amount: int = _rng.randi_range(20, 100)
	if ThingManager:
		var map: MapData = GameState.get_map() if GameState else null
		if map:
			var drop_pos := Vector2i(_rng.randi_range(20, map.width - 20), _rng.randi_range(20, map.height - 20))
			ThingManager.spawn_item_stacks(res_name, amount, drop_pos)
	_record_incident("ResourceDrop", {"resource": res_name, "amount": amount})


var _temp_shift: float = 0.0
var _temp_shift_decay: float = 0.0

func _incident_temperature_shift() -> void:
	if not GameState:
		return
	var shift: float = _rng.randf_range(-10.0, 10.0)
	_temp_shift += shift
	var event_name := "ColdSnap" if shift < 0 else "HeatWave"
	_record_incident(event_name, {"shift": shift})

func get_temp_shift() -> float:
	return _temp_shift

func decay_temp_shift() -> void:
	_temp_shift = lerpf(_temp_shift, 0.0, 0.1)


func _incident_disease() -> void:
	if not PawnManager or _is_on_cooldown("Disease"):
		return
	var colonists: Array[Pawn] = []
	for p: Pawn in PawnManager.pawns:
		if not p.dead and not p.downed and p.health:
			if not (p.has_meta("faction") and p.get_meta("faction") == "enemy"):
				colonists.append(p)
	if colonists.is_empty():
		return
	var diseases := ["Flu", "Plague", "Malaria", "GutWorms", "MuscleParasites", "SleepingSickness"]
	var disease: String = diseases[_rng.randi_range(0, diseases.size() - 1)]
	var victim: Pawn = colonists[_rng.randi_range(0, colonists.size() - 1)]
	victim.health.add_disease(disease, 0.2)
	_record_incident("Disease", {"pawn": victim.pawn_name, "disease": disease})


func _incident_eclipse() -> void:
	if _is_on_cooldown("Eclipse"):
		return
	_record_incident("Eclipse", {"duration_ticks": 5000})


func _incident_blight() -> void:
	if not ThingManager or _is_on_cooldown("Blight"):
		return
	var blighted: int = 0
	for t: Thing in ThingManager.things:
		if t is Plant:
			var plant := t as Plant
			if not plant.blighted and _rng.randf() < 0.4:
				plant.apply_blight()
				blighted += 1
	_record_incident("Blight", {"plants_affected": blighted})


func _incident_animal_herd() -> void:
	if not AnimalManager or _is_on_cooldown("AnimalHerd"):
		return
	var species_list := ["Deer", "Muffalo", "Elk", "Ibex"]
	var species: String = species_list[_rng.randi_range(0, species_list.size() - 1)]
	var count: int = _rng.randi_range(4, 10)
	_record_incident("AnimalHerd", {"species": species, "count": count})


func _incident_psychic_drone() -> void:
	if not PawnManager or _is_on_cooldown("PsychicDrone"):
		return
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.has_meta("faction"):
			continue
		if p.thought_tracker:
			p.thought_tracker.add_thought("PsychicDrone")
	_record_incident("PsychicDrone", {})


func _incident_man_in_black() -> void:
	if not PawnManager or _is_on_cooldown("ManInBlack"):
		return
	var alive: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead and not p.downed and not (p.has_meta("faction") and p.get_meta("faction") == "enemy"):
			alive += 1
	if alive > 1:
		return
	var rescuer := Pawn.new()
	rescuer.pawn_name = "Man in Black"
	rescuer.age = 30
	rescuer.set_skill_level("Shooting", 10)
	rescuer.set_skill_level("Medicine", 8)
	var map: MapData = GameState.get_map() if GameState else null
	if map:
		rescuer.set_grid_pos(Vector2i(3, map.height / 2))
	PawnManager.add_pawn(rescuer)
	_record_incident("ManInBlack", {"pawn_name": "Man in Black"})


func get_recent_events(count: int = 10) -> Array[Dictionary]:
	var start := maxi(0, incident_history.size() - count)
	var result: Array[Dictionary] = []
	for i: int in range(start, incident_history.size()):
		result.append(incident_history[i])
	return result


func get_events_by_category(category: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for ev: Dictionary in RANDOM_EVENTS:
		if ev.get("category", "") == category:
			result.append(ev)
	return result


func count_recent_negative(ticks_back: int = 10000) -> int:
	var now: int = TickManager.current_tick if TickManager else 0
	var count: int = 0
	for ev: Dictionary in incident_history:
		if now - ev.get("tick", 0) > ticks_back:
			continue
		if ev["name"] in ["Disease", "Blight", "PsychicDrone", "Raid"]:
			count += 1
	return count


func get_avg_event_weight() -> float:
	var total: float = 0.0
	for ev: Dictionary in RANDOM_EVENTS:
		total += float(ev.get("weight", 0))
	if RANDOM_EVENTS.is_empty():
		return 0.0
	return snappedf(total / float(RANDOM_EVENTS.size()), 0.01)

func get_positive_event_count() -> int:
	var count: int = 0
	for ev: Dictionary in RANDOM_EVENTS:
		if ev.get("category", "") == "positive":
			count += 1
	return count

func get_avg_cooldown_ticks() -> float:
	var total: float = 0.0
	if COOLDOWN_TICKS.is_empty():
		return 0.0
	for k: String in COOLDOWN_TICKS:
		total += float(COOLDOWN_TICKS[k])
	return snappedf(total / float(COOLDOWN_TICKS.size()), 0.01)

func get_neutral_event_count() -> int:
	var count: int = 0
	for ev: Dictionary in RANDOM_EVENTS:
		if ev.get("category", "") == "neutral":
			count += 1
	return count


func get_negative_event_count() -> int:
	var count: int = 0
	for ev: Dictionary in RANDOM_EVENTS:
		if ev.get("category", "") == "negative":
			count += 1
	return count


func get_longest_cooldown_event() -> String:
	var best: String = ""
	var best_cd: int = 0
	for k: String in COOLDOWN_TICKS:
		if int(COOLDOWN_TICKS[k]) > best_cd:
			best_cd = int(COOLDOWN_TICKS[k])
			best = k
	return best


func get_event_pressure() -> float:
	var neg := get_negative_event_count()
	var pos := get_positive_event_count()
	return snapped(float(neg) / maxf(pos, 1.0), 0.01)

func get_cooldown_utilization_pct() -> float:
	return snapped(float(_cooldowns.size()) / maxf(COOLDOWN_TICKS.size(), 1.0) * 100.0, 0.1)

func get_incident_tempo() -> float:
	var avg_interval := (_incident_interval_min + _incident_interval_max) / 2.0
	var avg_cd := get_avg_cooldown_ticks()
	return snapped(avg_interval / maxf(avg_cd, 1.0), 0.01)

func get_stats() -> Dictionary:
	return {
		"total_incidents": total_incidents,
		"history_count": incident_history.size(),
		"cooldowns_active": _cooldowns.size(),
		"recent_negative": count_recent_negative(),
		"avg_event_weight": get_avg_event_weight(),
		"positive_events": get_positive_event_count(),
		"avg_cooldown": get_avg_cooldown_ticks(),
		"neutral_events": get_neutral_event_count(),
		"negative_events": get_negative_event_count(),
		"longest_cooldown_event": get_longest_cooldown_event(),
		"event_pressure": get_event_pressure(),
		"cooldown_utilization_pct": get_cooldown_utilization_pct(),
		"incident_tempo": get_incident_tempo(),
		"incident_ecosystem_health": get_incident_ecosystem_health(),
		"narrative_governance": get_narrative_governance(),
		"storytelling_maturity_index": get_storytelling_maturity_index(),
	}

func get_incident_ecosystem_health() -> float:
	var pressure := get_event_pressure()
	var pressure_inv := maxf(100.0 - pressure * 20.0, 0.0)
	var cooldown := get_cooldown_utilization_pct()
	var tempo := minf(get_incident_tempo() * 50.0, 100.0)
	return snapped((pressure_inv + cooldown + tempo) / 3.0, 0.1)

func get_narrative_governance() -> String:
	var eco := get_incident_ecosystem_health()
	var mat := get_storytelling_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif total_incidents > 0:
		return "Nascent"
	return "Dormant"

func get_storytelling_maturity_index() -> float:
	var pos := minf(float(get_positive_event_count()) * 10.0, 100.0)
	var neg := minf(float(get_negative_event_count()) * 10.0, 100.0)
	var balance := 100.0 - absf(pos - neg)
	var avg_w := minf(get_avg_event_weight() * 20.0, 100.0)
	return snapped((balance + get_cooldown_utilization_pct() + avg_w) / 3.0, 0.1)
