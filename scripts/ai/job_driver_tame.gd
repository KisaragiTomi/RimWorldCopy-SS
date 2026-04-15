class_name JobDriverTame
extends JobDriver

## Walk to animal, offer food, attempt taming. Skill affects success rate.

var _target_animal_id: int = -1
var _rng := RandomNumberGenerator.new()
var _consumed_food: bool = false

const TAME_FOOD_DEFS: PackedStringArray = ["RawFood", "Rice", "Corn", "Meat"]


func setup(p: Pawn, j: Job) -> void:
	_rng.seed = randi()
	_target_animal_id = j.meta_data.get("animal_id", -1) as int
	super.setup(p, j)


func _make_toils() -> Array[Dictionary]:
	return [
		{
			"name": "walk_to_animal",
			"complete_mode": "never",
		},
		{
			"name": "offer_food",
			"complete_mode": "instant",
		},
		{
			"name": "tame_attempt",
			"complete_mode": "delay",
			"delay_ticks": 120,
		},
		{
			"name": "finish",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"walk_to_animal":
			_start_walk()
		"offer_food":
			_offer_food()
		"finish":
			_try_tame()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"walk_to_animal":
			_walk_tick()


func _start_walk() -> void:
	var animal: Animal = _find_animal()
	if animal == null:
		end_job(false)
		return
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		end_job(false)
		return
	pawn.path = pf.find_path(pawn.grid_pos, animal.grid_pos)
	pawn.path_index = 0
	if pawn.path.is_empty():
		end_job(false)


func _walk_tick() -> void:
	if not pawn.has_path():
		_advance_toil()
		return
	var next := pawn.next_path_step()
	pawn.set_grid_pos(next)


func _offer_food() -> void:
	_consumed_food = _consume_tame_food()
	_advance_toil()


func _try_tame() -> void:
	var animal: Animal = _find_animal()
	if animal == null or animal.dead:
		end_job(false)
		return

	var skill: int = pawn.get_skill_level("Animals")
	var food_bonus: float = 0.1 if _consumed_food else 0.0

	animal.attempt_tame(skill, _rng)

	pawn.gain_xp("Animals", 80.0)

	if animal.tamed:
		animal.tamer_id = pawn.id
		if ColonyLog:
			ColonyLog.add_entry("Animal", "%s tamed a %s!" % [pawn.pawn_name, animal.species], "positive")
	else:
		if ColonyLog:
			ColonyLog.add_entry("Animal", "%s failed to tame %s." % [pawn.pawn_name, animal.species], "info")

	end_job(true)


func _consume_tame_food() -> bool:
	if not ThingManager:
		return false
	for t: Thing in ThingManager.things:
		if not (t is Item):
			continue
		var item := t as Item
		if item.state != Thing.ThingState.SPAWNED:
			continue
		if not (item.def_name in TAME_FOOD_DEFS):
			continue
		if item.stack_count <= 1:
			ThingManager.remove_thing(item)
		else:
			item.stack_count -= 1
		return true
	return false


func _find_animal() -> Animal:
	if not AnimalManager:
		return null
	for a: Animal in AnimalManager.animals:
		if a.id == _target_animal_id:
			return a
	return null


func _get_map() -> MapData:
	if GameState and GameState.has_method("get_map"):
		return GameState.get_map()
	return null
