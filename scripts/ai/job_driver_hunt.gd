class_name JobDriverHunt
extends JobDriver

## Drives the Hunt job: approach animal, attack, collect meat.

var _target_id: int = -1
var _rng := RandomNumberGenerator.new()


func setup(p: Pawn, j: Job) -> void:
	_rng.seed = randi()
	_target_id = j.meta_data.get("animal_id", -1) as int
	super.setup(p, j)


func _make_toils() -> Array[Dictionary]:
	return [
		{
			"name": "approach",
			"complete_mode": "never",
		},
		{
			"name": "shoot",
			"complete_mode": "delay",
			"delay_ticks": 60,
		},
		{
			"name": "kill_and_butcher",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"approach":
			_start_approach()
		"kill_and_butcher":
			_finish_hunt()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"approach":
			_tick_approach()


func _start_approach() -> void:
	var animal: Animal = _find_animal()
	if animal == null:
		end_job(false)
		return
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf:
		pawn.path = pf.find_path(pawn.grid_pos, animal.grid_pos)
		pawn.path_index = 0


func _tick_approach() -> void:
	if pawn.has_path():
		var next: Vector2i = pawn.next_path_step()
		pawn.set_grid_pos(next)
	else:
		_advance_toil()


func _finish_hunt() -> void:
	var animal: Animal = _find_animal()
	if animal == null:
		end_job(false)
		return

	var shoot_skill: int = pawn.get_skill_level("Shooting")
	var hit_chance: float = 0.5 + shoot_skill * 0.04
	if _rng.randf() < hit_chance:
		animal.dead = true
		var data: Dictionary = Animal.SPECIES_DATA.get(animal.species, {}) as Dictionary
		var meat: int = data.get("meat_yield", 10) as int
		var leather: int = data.get("leather_yield", 5) as int
		meat = maxi(1, roundi(meat * (0.8 + _rng.randf() * 0.4)))
		leather = maxi(1, roundi(leather * (0.7 + _rng.randf() * 0.3)))

		if ThingManager:
			ThingManager.spawn_item_stacks("Meat", meat, animal.grid_pos)
			if leather > 0:
				ThingManager.spawn_item_stacks("Leather", leather, animal.grid_pos)

		pawn.gain_xp("Shooting", 60.0)
		if pawn.thought_tracker:
			pawn.thought_tracker.add_thought("KilledAnimal")
		if ColonyLog:
			ColonyLog.add_entry("Work", "%s hunted a %s (%d meat, %d leather)." % [
				pawn.pawn_name, animal.species, meat, leather
			], "info")
	else:
		pawn.gain_xp("Shooting", 15.0)
		if ColonyLog:
			ColonyLog.add_entry("Work", "%s missed a shot at %s." % [pawn.pawn_name, animal.species], "info")

	end_job(true)


func _find_animal() -> Animal:
	if not AnimalManager:
		return null
	for a: Animal in AnimalManager.animals:
		if a.id == _target_id:
			return a
	return null
