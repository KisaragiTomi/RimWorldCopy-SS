class_name JobDriverEquip
extends JobDriver

## Drives the Equip job: walk to apparel, pick it up, equip it.


func _make_toils() -> Array[Dictionary]:
	return [
		{
			"name": "walk_to_item",
			"complete_mode": "never",
		},
		{
			"name": "equip",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"walk_to_item":
			_start_walk()
		"equip":
			_do_equip()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"walk_to_item":
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


func _do_equip() -> void:
	var item_def: String = job.meta_data.get("item_def", "")
	var slot: String = job.meta_data.get("slot", "")
	if item_def.is_empty() or slot.is_empty():
		return

	var old_item: String = ""
	if pawn.equipment:
		old_item = pawn.equipment.slots.get(slot, "")
		pawn.equipment.equip(slot, item_def)

	if ThingManager:
		for t: Thing in ThingManager.things:
			if t is Item and t.def_name == item_def and t.grid_pos == job.target_pos:
				ThingManager.destroy_thing(t)
				break
		if not old_item.is_empty():
			var dropped := Item.new(old_item, 1)
			dropped.grid_pos = pawn.grid_pos
			ThingManager.spawn_thing(dropped, pawn.grid_pos)

	if ColonyLog:
		var msg: String = "%s equipped %s." % [pawn.pawn_name, item_def]
		if not old_item.is_empty():
			msg = "%s swapped %s for %s." % [pawn.pawn_name, old_item, item_def]
		ColonyLog.add_entry("Equipment", msg, "info")
