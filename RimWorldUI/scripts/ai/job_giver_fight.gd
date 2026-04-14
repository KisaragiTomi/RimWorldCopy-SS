class_name JobGiverFight
extends ThinkNode

## Issues fight jobs when pawn is drafted and enemies are nearby.

func try_issue_job(pawn: Pawn) -> Dictionary:
	if not pawn.drafted:
		return {}

	var enemies := _find_enemies(pawn)
	if enemies.is_empty():
		return {}

	var closest: Pawn = null
	var closest_dist: float = INF
	for e: Pawn in enemies:
		var d := pawn.grid_pos.distance_to(e.grid_pos) as float
		if d < closest_dist:
			closest_dist = d
			closest = e

	if closest == null:
		return {}

	var has_ranged := false
	if pawn.equipment and pawn.equipment.is_ranged_weapon():
		has_ranged = true

	var job_type: String
	if closest_dist <= 2.0:
		job_type = "MeleeAttack"
	elif has_ranged:
		job_type = "RangedAttack"
	else:
		job_type = "MeleeAttack"

	var j := Job.new(job_type, closest.grid_pos)
	j.target_thing_id = closest.id
	return {"job": j, "source": self}


func _find_enemies(pawn: Pawn) -> Array[Pawn]:
	var result: Array[Pawn] = []
	if not PawnManager:
		return result
	for p: Pawn in PawnManager.pawns:
		if p == pawn or p.dead or p.downed:
			continue
		if p.has_meta("faction") and p.get_meta("faction") == "enemy":
			result.append(p)
	return result
