class_name JobGiverConstruct
extends ThinkNode

## Finds blueprint/frame buildings and issues construct or deliver jobs.

func try_issue_job(pawn: Pawn) -> Dictionary:
	if not pawn.is_capable_of("Construction"):
		return {}
	if not ThingManager:
		return {}

	var best_deliver: Building = null
	var best_deliver_dist: int = 9999
	var best_build: Building = null
	var best_build_dist: int = 9999

	for thing: Thing in ThingManager.things:
		if not (thing is Building):
			continue
		var b: Building = thing as Building
		if b.build_state == Building.BuildState.COMPLETE:
			continue
		if b.state == Thing.ThingState.DESTROYED:
			continue
		var dist: int = absi(b.grid_pos.x - pawn.grid_pos.x) + absi(b.grid_pos.y - pawn.grid_pos.y)

		if b.needs_materials():
			if dist < best_deliver_dist:
				best_deliver_dist = dist
				best_deliver = b
		else:
			if dist < best_build_dist:
				best_build_dist = dist
				best_build = b

	if best_deliver and _has_available_materials(best_deliver):
		var j := Job.new("DeliverResources", best_deliver.grid_pos)
		j.target_thing_id = best_deliver.id
		return {"job": j, "source": self}

	if best_build:
		var j := Job.new("Construct", best_build.grid_pos)
		j.target_thing_id = best_build.id
		return {"job": j, "source": self}

	return {}


func _has_available_materials(building: Building) -> bool:
	var missing: Dictionary = building.get_missing_materials()
	if missing.is_empty():
		return false
	for thing: Thing in ThingManager.things:
		if not (thing is Item):
			continue
		var item: Item = thing as Item
		if item.forbidden or item.hauled_by >= 0:
			continue
		if item.state != Thing.ThingState.SPAWNED:
			continue
		if missing.has(item.def_name):
			return true
	return false
