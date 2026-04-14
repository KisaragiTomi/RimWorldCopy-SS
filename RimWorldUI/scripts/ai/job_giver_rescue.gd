class_name JobGiverRescue
extends ThinkNode

## Rescues downed colonists by carrying them to a bed.

const MAX_RESCUE_RANGE := 120


func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.drafted or pawn.downed or pawn.dead:
		return {}
	if not PawnManager:
		return {}

	var patient := _find_downed_pawn(pawn)
	if patient == null:
		return {}

	var j := Job.new("Rescue", patient.grid_pos)
	j.target_thing_id = patient.id
	return {"job": j, "source": self}


func _find_downed_pawn(rescuer: Pawn) -> Pawn:
	var best: Pawn = null
	var best_dist: int = MAX_RESCUE_RANGE + 1
	for p: Pawn in PawnManager.pawns:
		if p == rescuer or p.dead or not p.downed:
			continue
		if p.has_meta("faction") and p.get_meta("faction") == "enemy":
			continue
		if p.has_meta("being_rescued") and p.get_meta("being_rescued"):
			continue
		var dist: int = absi(p.grid_pos.x - rescuer.grid_pos.x) + absi(p.grid_pos.y - rescuer.grid_pos.y)
		if dist >= best_dist:
			continue
		best_dist = dist
		best = p
	return best
