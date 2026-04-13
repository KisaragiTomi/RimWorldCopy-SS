extends Node

## Manages all pawns: ticks their AI, needs, and jobs.
## Registered as autoload "PawnManager".

signal mental_break_started(pawn: Pawn, break_type: String)
signal mental_break_ended(pawn: Pawn)

var pawns: Array[Pawn] = []
var _drivers: Dictionary = {}  # pawn_id -> JobDriver
var _think_tree: ThinkNodePriority
var _rng := RandomNumberGenerator.new()
var social: SocialManager = SocialManager.new()
var _job_cooldowns: Dictionary = {}
const JOB_RETRY_COOLDOWN := 60
var _pathfinder_cache: Pathfinder
var current_tick_cached: int = 0


func _ready() -> void:
	_build_think_tree()
	if TickManager:
		TickManager.tick.connect(_on_tick)
		TickManager.rare_tick.connect(_on_rare_tick)


func _build_think_tree() -> void:
	_think_tree = ThinkNodePriority.new()
	_think_tree.add_child_node(JobGiverFirefight.new())
	_think_tree.add_child_node(JobGiverFight.new())
	_think_tree.add_child_node(JobGiverDoctor.new())
	_think_tree.add_child_node(JobGiverRest.new())
	_think_tree.add_child_node(JobGiverEat.new())
	_think_tree.add_child_node(JobGiverConstruct.new())
	_think_tree.add_child_node(JobGiverHaul.new())
	_think_tree.add_child_node(JobGiverCook.new())
	_think_tree.add_child_node(JobGiverSow.new())
	_think_tree.add_child_node(JobGiverMine.new())
	_think_tree.add_child_node(JobGiverHunt.new())
	_think_tree.add_child_node(JobGiverChop.new())
	_think_tree.add_child_node(JobGiverCraft.new())
	_think_tree.add_child_node(JobGiverResearch.new())
	_think_tree.add_child_node(JobGiverRepair.new())
	_think_tree.add_child_node(JobGiverClean.new())
	_think_tree.add_child_node(JobGiverTame.new())
	_think_tree.add_child_node(JobGiverJoy.new())
	_think_tree.add_child_node(JobGiverWander.new())


func add_pawn(p: Pawn) -> void:
	pawns.append(p)


func remove_pawn(p: Pawn) -> void:
	pawns.erase(p)
	_drivers.erase(p.id)


func toggle_draft(p: Pawn) -> void:
	p.drafted = not p.drafted
	_drivers.erase(p.id)
	p.current_job_name = "Drafted" if p.drafted else ""
	p.job_changed.emit(p.current_job_name)
	if ColonyLog:
		var action: String = "drafted" if p.drafted else "undrafted"
		ColonyLog.add_entry("Draft", "%s has been %s." % [p.pawn_name, action], "info")


func set_draft(p: Pawn, value: bool) -> void:
	if p.drafted == value:
		return
	toggle_draft(p)


func draft_all() -> void:
	for p: Pawn in pawns:
		if p.dead or p.downed:
			continue
		set_draft(p, true)


func undraft_all() -> void:
	for p: Pawn in pawns:
		set_draft(p, false)


func get_drafted_pawns() -> Array[Pawn]:
	var result: Array[Pawn] = []
	for p: Pawn in pawns:
		if p.drafted and not p.dead and not p.downed:
			result.append(p)
	return result


func move_drafted_to(p: Pawn, target: Vector2i) -> void:
	if not p.drafted or p.dead or p.downed:
		return
	var pf := get_pathfinder()
	if pf == null:
		return
	p.path = pf.find_path(p.grid_pos, target)
	p.path_index = 0


func get_pathfinder() -> Pathfinder:
	var map: MapData = GameState.get_map() if GameState else null
	if map == null:
		return null
	if _pathfinder_cache == null or _pathfinder_cache.map != map:
		_pathfinder_cache = Pathfinder.new(map)
	return _pathfinder_cache


func _on_tick(_tick: int) -> void:
	current_tick_cached = _tick
	for p: Pawn in pawns:
		if p.dead or p.downed:
			continue
		_tick_pawn(p)


func _on_rare_tick(_tick: int) -> void:
	_try_social_interactions()
	_tick_plants()
	_tick_item_decay()


func _try_social_interactions() -> void:
	var colonists: Array[Pawn] = []
	for p: Pawn in pawns:
		if p.dead or p.downed or p.is_in_mental_break():
			continue
		if p.has_meta("faction") and p.get_meta("faction") == "enemy":
			continue
		colonists.append(p)
	if colonists.size() < 2:
		return
	if _rng.randf() > 0.15:
		return
	var actor: Pawn = colonists[_rng.randi_range(0, colonists.size() - 1)]
	var target: Pawn = actor
	while target == actor:
		target = colonists[_rng.randi_range(0, colonists.size() - 1)]
	social.do_random_interaction(actor, target)


func _tick_plants() -> void:
	if not ThingManager:
		return
	var map: MapData = GameState.get_map() if GameState else null
	for t: Thing in ThingManager.things:
		if t is Plant:
			var p := t as Plant
			var fertility: float = 1.0
			if map:
				var cell := map.get_cell(p.grid_pos.x, p.grid_pos.y)
				if cell:
					fertility = cell.fertility
			p.tick_growth(fertility)


func _tick_item_decay() -> void:
	if not ThingManager:
		return
	var temp: float = GameState.temperature if GameState else 15.0
	if WeatherManager:
		temp += WeatherManager.get_temp_offset()
	var to_destroy: Array[Thing] = []
	for t: Thing in ThingManager.things:
		if t is Item:
			var item := t as Item
			if item.tick_decay(temp):
				to_destroy.append(t)
	for t: Thing in to_destroy:
		if ColonyLog:
			ColonyLog.add_entry("Alert", t.label + " has rotted away.", "warning")
		ThingManager.destroy_thing(t)


func _tick_pawn(p: Pawn) -> void:
	var driver: JobDriver = _drivers.get(p.id)
	if driver and not driver.ended:
		driver.driver_tick()
		if driver.ended:
			_drivers.erase(p.id)
			if not driver.succeeded:
				_job_cooldowns[p.id] = current_tick_cached + JOB_RETRY_COOLDOWN
		return

	if _job_cooldowns.get(p.id, 0) > current_tick_cached:
		return
	_try_start_job(p)


func _try_start_job(p: Pawn) -> void:
	for node: ThinkNode in _think_tree.sub_nodes:
		var result := node.try_issue_job(p)
		if result.is_empty():
			continue
		var j: Job = result.get("job")
		if j == null:
			continue
		var driver := _create_driver(j.job_def)
		if driver == null:
			continue
		p.current_job_name = j.job_def
		p.job_changed.emit(j.job_def)
		driver.setup(p, j)
		if driver.ended:
			_drivers.erase(p.id)
			continue
		_drivers[p.id] = driver
		return
	_job_cooldowns[p.id] = current_tick_cached + JOB_RETRY_COOLDOWN


func _tick_mental_pawn(p: Pawn) -> void:
	match p.mental_state:
		"Wander":
			if not p.has_path():
				var pf := get_pathfinder()
				if pf:
					var target := Vector2i(
						p.grid_pos.x + _rng.randi_range(-15, 15),
						p.grid_pos.y + _rng.randi_range(-15, 15))
					target = target.clamp(Vector2i.ZERO, Vector2i(pf.map.width - 1, pf.map.height - 1))
					p.path = pf.find_path(p.grid_pos, target)
					p.path_index = 0
			elif p.path_index < p.path.size():
				var next_pos := p.next_path_step()
				p.set_grid_pos(next_pos)
		"BingeEat":
			p.set_need("Food", minf(1.0, p.get_need("Food") + 0.002))
		"Hide":
			pass


func _create_driver(job_def: String) -> JobDriver:
	match job_def:
		"Wander":
			return JobDriverWander.new()
		"Construct":
			return JobDriverConstruct.new()
		"DeliverResources":
			return JobDriverDeliverResources.new()
		"Eat":
			return JobDriverEat.new()
		"RangedAttack", "MeleeAttack":
			return JobDriverFight.new()
		"Haul":
			return JobDriverHaul.new()
		"Sow", "Harvest":
			return JobDriverSow.new()
		"TendPatient":
			return JobDriverDoctor.new()
		"Cook":
			return JobDriverCook.new()
		"Rest":
			return JobDriverRest.new()
		"JoyActivity":
			return JobDriverJoy.new()
		"Tame":
			return JobDriverTame.new()
		"Mine":
			return JobDriverMine.new()
		"Hunt":
			return JobDriverHunt.new()
		"Firefight":
			return JobDriverFirefight.new()
		"Craft":
			return JobDriverCraft.new()
		"Research":
			return JobDriverResearch.new()
		"Clean":
			return JobDriverClean.new()
		"Equip":
			return JobDriverEquip.new()
		"Chop":
			return JobDriverChop.new()
		"Repair":
			return JobDriverRepair.new()
		"Butcher":
			return JobDriverButcher.new()
		"Deconstruct":
			return JobDriverDeconstruct.new()
		"Warden":
			return JobDriverWarden.new()
		"Surgery":
			return JobDriverSurgery.new()
	return null
