class_name JobGiverHaul
extends ThinkNode

## Issues haul jobs to move items to stockpile zones.

func try_issue_job(pawn: Pawn) -> Dictionary:
	if not pawn.is_capable_of("Hauling"):
		return {}
	if pawn.drafted:
		return {}

	if not ThingManager:
		return {}

	var best_item: Thing = null
	var best_dist: float = INF

	for t: Thing in ThingManager.things:
		if not (t is Item):
			continue
		var item := t as Item
		if item.forbidden or item.hauled_by >= 0:
			continue
		if not _needs_hauling(item):
			continue
		var d := pawn.grid_pos.distance_to(item.grid_pos) as float
		if d < best_dist:
			best_dist = d
			best_item = t

	if best_item == null:
		return {}

	var j := Job.new("Haul", best_item.grid_pos)
	j.target_thing_id = best_item.id
	return {"job": j, "source": self}


func _needs_hauling(item: Item) -> bool:
	if not GameState:
		return false
	var map: MapData = GameState.get_map()
	if map == null:
		return false
	var cell := map.get_cell(item.grid_pos.x, item.grid_pos.y)
	if cell and cell.zone == "Stockpile":
		return false
	return true
