class_name JobDriverButcher
extends JobDriver

## Drives the Butcher job: walk to corpse, butcher it into meat and leather.


func _make_toils() -> Array[Dictionary]:
	return [
		{
			"name": "walk_to_corpse",
			"complete_mode": "never",
		},
		{
			"name": "butchering",
			"complete_mode": "delay",
			"delay_ticks": 150,
		},
		{
			"name": "done",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"walk_to_corpse":
			_start_walk()
		"done":
			_finish_butcher()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"walk_to_corpse":
			_tick_walk()


func _start_walk() -> void:
	var pf: Pathfinder = PawnManager.get_pathfinder() if PawnManager else null
	if pf == null:
		end_job(false)
		return
	pawn.path = pf.find_path(pawn.grid_pos, job.target_pos)
	pawn.path_index = 0


func _tick_walk() -> void:
	if pawn.has_path():
		pawn.set_grid_pos(pawn.next_path_step())
	else:
		_advance_toil()


const CORPSE_YIELDS: Dictionary = {
	"Corpse": {"meat": 30, "leather": 15},
	"AnimalCorpse": {"meat": 40, "leather": 20},
}

func _finish_butcher() -> void:
	if not ThingManager:
		return

	var corpse_type: String = job.meta_data.get("corpse_type", "Corpse")
	var yields: Dictionary = CORPSE_YIELDS.get(corpse_type, {"meat": 30, "leather": 15})

	for t: Thing in ThingManager.things:
		if t is Item and (t.def_name == "Corpse" or t.def_name == "AnimalCorpse") and t.grid_pos == job.target_pos:
			ThingManager.destroy_thing(t)

			var skill: int = pawn.get_skill_level("Cooking") if pawn else 0
			var bonus: float = 1.0 + skill * 0.03
			var meat_count: int = roundi(yields.get("meat", 30) * bonus)
			var leather_count: int = roundi(yields.get("leather", 15) * bonus)

			ThingManager.spawn_item_stacks("Meat", meat_count, job.target_pos)
			ThingManager.spawn_item_stacks("Leather", leather_count, job.target_pos + Vector2i(1, 0))

			pawn.gain_xp("Cooking", 30.0)

			if pawn.thought_tracker and corpse_type == "Corpse":
				pawn.thought_tracker.add_thought("ButcheredHumanlike")

			if ColonyLog:
				ColonyLog.add_entry("Work", "%s butchered a %s (%d meat, %d leather)." % [
					pawn.pawn_name, corpse_type, meat_count, leather_count], "info")
			break
