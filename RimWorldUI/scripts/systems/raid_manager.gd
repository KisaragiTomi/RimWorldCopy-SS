extends Node

## Raid generation and enemy AI with equipment, fleeing, and loot.
## Registered as autoload "RaidManager".

signal raid_started(enemy_count: int, edge: String)
signal raid_ended()

var active_raiders: Array[Pawn] = []
var _rng := RandomNumberGenerator.new()
var raid_active: bool = false
var total_raids: int = 0
var _raid_start_count: int = 0

const RAIDER_WEAPONS := ["Knife", "Revolver", "ShortBow", "Rifle", "Mace", "Spear"]
const RAIDER_ARMOR := ["", "", "", "FlakVest", "SimpleHelmet"]
const FLEE_THRESHOLD := 0.4


func _ready() -> void:
	_rng.seed = randi()
	if IncidentManager:
		IncidentManager.incident_fired.connect(_on_incident)
	if TickManager:
		TickManager.tick.connect(_on_tick)


func _on_incident(incident_name: String, _data: Dictionary) -> void:
	pass


func spawn_raid(raider_count: int = 0) -> void:
	if raid_active:
		return
	var map: MapData = GameState.get_map() if GameState else null
	if map == null:
		return

	if raider_count <= 0:
		var colony_strength: int = 3
		if PawnManager:
			colony_strength = 0
			for p: Pawn in PawnManager.pawns:
				if not p.has_meta("faction") or p.get_meta("faction") != "enemy":
					colony_strength += 1
		raider_count = clampi(colony_strength / 4 + _rng.randi_range(0, 3), 2, 30)

	var edges := ["West", "East", "North", "South"]
	var edge_label: String = edges[_rng.randi_range(0, edges.size() - 1)]

	for i: int in raider_count:
		var raider := Pawn.new()
		raider.pawn_name = "Raider_" + str(total_raids * 10 + i + 1)
		raider.age = _rng.randi_range(18, 45)
		raider.set_meta("faction", "enemy")
		raider.set_skill_level("Shooting", _rng.randi_range(2, 10))
		raider.set_skill_level("Melee", _rng.randi_range(2, 10))

		_equip_raider(raider)

		var spawn_pos := _get_edge_pos(map, edge_label)
		raider.set_grid_pos(spawn_pos)
		if PawnManager:
			PawnManager.add_pawn(raider)
		active_raiders.append(raider)

	_raid_start_count = raider_count
	total_raids += 1
	raid_active = true
	raid_started.emit(raider_count, edge_label)


func _equip_raider(raider: Pawn) -> void:
	if raider.equipment == null:
		return
	var weapon: String = RAIDER_WEAPONS[_rng.randi_range(0, RAIDER_WEAPONS.size() - 1)]
	raider.equipment.equip("Weapon", weapon)
	var armor: String = RAIDER_ARMOR[_rng.randi_range(0, RAIDER_ARMOR.size() - 1)]
	if not armor.is_empty():
		raider.equipment.equip("BodyArmor", armor)


func _get_edge_pos(map: MapData, edge: String) -> Vector2i:
	match edge:
		"West":
			return Vector2i(0, _rng.randi_range(20, map.height - 20))
		"East":
			return Vector2i(map.width - 1, _rng.randi_range(20, map.height - 20))
		"North":
			return Vector2i(_rng.randi_range(20, map.width - 20), 0)
		"South":
			return Vector2i(_rng.randi_range(20, map.width - 20), map.height - 1)
	return Vector2i(0, map.height / 2)


func _on_tick(_current_tick: int) -> void:
	if not raid_active:
		return

	var alive := active_raiders.filter(func(r: Pawn) -> bool: return not r.dead and not r.downed)
	if alive.is_empty():
		_end_raid()
		return

	if _should_flee(alive):
		for raider: Pawn in alive:
			_flee(raider)
		return

	for raider: Pawn in alive:
		if raider.current_job_name.is_empty() or raider.current_job_name == "Wander":
			_raider_ai(raider)


func _should_flee(alive: Array) -> bool:
	if _raid_start_count <= 0:
		return true
	return float(alive.size()) / float(_raid_start_count) < FLEE_THRESHOLD


func _flee(raider: Pawn) -> void:
	var map: MapData = GameState.get_map() if GameState else null
	if map == null:
		return
	if raider.has_path() and raider.path_index < raider.path.size():
		var step := raider.next_path_step()
		raider.set_grid_pos(step)
		if raider.grid_pos.x <= 0 or raider.grid_pos.x >= map.width - 1 or \
		   raider.grid_pos.y <= 0 or raider.grid_pos.y >= map.height - 1:
			raider.dead = true
			if PawnManager:
				PawnManager.remove_pawn(raider)
		return
	var flee_pos := Vector2i(0, raider.grid_pos.y)
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		return
	raider.path = pf.find_path(raider.grid_pos, flee_pos)
	raider.path_index = 0


func _raider_ai(raider: Pawn) -> void:
	if not PawnManager:
		return
	var target := _find_closest_colonist(raider)
	if target == null:
		return

	var dist := raider.grid_pos.distance_to(target.grid_pos)
	var weapon: String = raider.equipment.get_weapon() if raider.equipment else ""
	var is_melee := weapon in ["Knife", "Longsword", "Mace", "Spear", ""]

	if is_melee:
		if dist <= 1.5:
			CombatUtil.melee_attack(raider, target)
		else:
			_move_toward(raider, target.grid_pos)
	else:
		if dist <= 1.5:
			CombatUtil.melee_attack(raider, target)
		elif dist <= 20.0:
			CombatUtil.ranged_attack(raider, target)
		else:
			_move_toward(raider, target.grid_pos)


func _find_closest_colonist(raider: Pawn) -> Pawn:
	var best: Pawn = null
	var best_dist: float = INF
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed or p == raider:
			continue
		if p.has_meta("faction") and p.get_meta("faction") == "enemy":
			continue
		var d := raider.grid_pos.distance_to(p.grid_pos) as float
		if d < best_dist:
			best_dist = d
			best = p
	return best


func _move_toward(raider: Pawn, target_pos: Vector2i) -> void:
	if raider.has_path():
		var step := raider.next_path_step()
		raider.set_grid_pos(step)
		return

	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		return
	raider.path = pf.find_path(raider.grid_pos, target_pos)
	raider.path_index = 0


func _end_raid() -> void:
	for r: Pawn in active_raiders:
		if r.dead:
			_drop_loot(r)
			if PawnManager:
				PawnManager.remove_pawn(r)
	active_raiders.clear()
	_raid_start_count = 0
	raid_active = false
	raid_ended.emit()
	if IncidentManager and IncidentManager.storyteller:
		IncidentManager.storyteller.notify_colonist_death()


func get_raid_difficulty() -> float:
	var base: float = 1.0 + float(total_raids) * 0.15
	var wealth := _calc_colony_wealth()
	base += wealth * 0.0001
	return minf(base, 5.0)


func _calc_colony_wealth() -> float:
	var wealth: float = 0.0
	if ThingManager:
		for t: Thing in ThingManager.things:
			if t is Item:
				wealth += (t as Item).get_market_value()
			elif t is Building:
				wealth += 50.0
	return wealth


func get_weapon_variety_count() -> int:
	return RAIDER_WEAPONS.size()

func get_armor_drop_chance() -> float:
	var non_empty: int = 0
	for a: String in RAIDER_ARMOR:
		if not a.is_empty():
			non_empty += 1
	if RAIDER_ARMOR.is_empty():
		return 0.0
	return snappedf(float(non_empty) / float(RAIDER_ARMOR.size()), 0.01)

func get_flee_percentage() -> float:
	return FLEE_THRESHOLD * 100.0

func get_max_difficulty() -> float:
	return 5.0

func get_unique_armor_types() -> int:
	var types: Dictionary = {}
	for a: String in RAIDER_ARMOR:
		if not a.is_empty():
			types[a] = true
	return types.size()

func get_loot_drop_types() -> int:
	var count: int = 0
	if RAIDER_WEAPONS.size() > 0:
		count += 1
	var has_armor: bool = false
	for a: String in RAIDER_ARMOR:
		if not a.is_empty():
			has_armor = true
			break
	if has_armor:
		count += 1
	return count

func get_threat_escalation() -> float:
	if total_raids <= 1:
		return 0.0
	return snapped(get_raid_difficulty() / maxf(total_raids, 1.0), 0.01)

func get_equipment_quality_pct() -> float:
	var armed := 0
	for w in RAIDER_WEAPONS:
		if w != "Knife":
			armed += 1
	var armored := 0
	for a in RAIDER_ARMOR:
		if not a.is_empty():
			armored += 1
	var total := RAIDER_WEAPONS.size() + RAIDER_ARMOR.size()
	return snapped(float(armed + armored) / maxf(total, 1.0) * 100.0, 0.1)

func get_survival_rate() -> float:
	if _raid_start_count == 0:
		return 100.0
	var fled := int(active_raiders.size() * FLEE_THRESHOLD)
	return snapped(float(fled) / maxf(_raid_start_count, 1.0) * 100.0, 0.1)

func get_stats() -> Dictionary:
	return {
		"total_raids": total_raids,
		"raid_active": raid_active,
		"active_raiders": active_raiders.size(),
		"difficulty": snappedf(get_raid_difficulty(), 0.01),
		"weapon_variety": get_weapon_variety_count(),
		"armor_equip_chance": get_armor_drop_chance(),
		"flee_pct": get_flee_percentage(),
		"max_difficulty": get_max_difficulty(),
		"unique_armor_types": get_unique_armor_types(),
		"loot_drop_types": get_loot_drop_types(),
		"threat_escalation": get_threat_escalation(),
		"equipment_quality_pct": get_equipment_quality_pct(),
		"survival_rate": get_survival_rate(),
	}


func _drop_loot(raider: Pawn) -> void:
	if not ThingManager or raider.equipment == null:
		return
	var weapon: String = raider.equipment.get_weapon()
	if not weapon.is_empty() and _rng.randf() < 0.35:
		var loot := Item.new(weapon)
		loot.stack_count = 1
		loot.grid_pos = raider.grid_pos
		ThingManager.spawn_thing(loot, raider.grid_pos)
	var armor: String = raider.equipment.slots.get("BodyArmor", "")
	if not armor.is_empty() and _rng.randf() < 0.2:
		var armor_loot := Item.new(armor)
		armor_loot.stack_count = 1
		armor_loot.grid_pos = raider.grid_pos
		ThingManager.spawn_thing(armor_loot, raider.grid_pos)
