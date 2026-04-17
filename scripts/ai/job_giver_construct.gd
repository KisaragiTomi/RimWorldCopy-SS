class_name JobGiverConstruct
extends ThinkNode

## Finds blueprint/frame buildings and issues construct or deliver jobs.

func try_issue_job(pawn: Pawn) -> Dictionary:
	if not pawn.is_capable_of("Construction"):
		return {}
	if not ThingManager:
		return {}

	var reserved := _get_reserved_build_ids()
	var candidates_deliver: Array[Array] = []
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
		if reserved.has(b.id):
			continue
		var dist: int = absi(b.grid_pos.x - pawn.grid_pos.x) + absi(b.grid_pos.y - pawn.grid_pos.y)

		if b.needs_materials():
			candidates_deliver.append([dist, b])
		else:
			if dist < best_build_dist:
				best_build_dist = dist
				best_build = b

	candidates_deliver.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for entry: Array in candidates_deliver:
		var b: Building = entry[1] as Building
		if _has_available_materials(b):
			var j := Job.new("DeliverResources", b.grid_pos)
			j.target_thing_id = b.id
			return {"job": j, "source": self}

	if best_build:
		var j := Job.new("Construct", best_build.grid_pos)
		j.target_thing_id = best_build.id
		return {"job": j, "source": self}

	return {}


func _get_reserved_build_ids() -> Dictionary:
	var reserved := {}
	if not PawnManager:
		return reserved
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed:
			continue
		if (p.current_job_name == "Construct" or p.current_job_name == "DeliverResources") and PawnManager._drivers.has(p.id):
			var driver = PawnManager._drivers[p.id]
			if driver and driver.job:
				reserved[driver.job.target_thing_id] = true
	return reserved


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
