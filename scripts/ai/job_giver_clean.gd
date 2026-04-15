class_name JobGiverClean
extends ThinkNode

## Issues a Clean job when there's filth nearby.


func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.drafted or pawn.dead or pawn.downed:
		return {}
	if not pawn.is_capable_of("Cleaning"):
		return {}
	if not FilthManager:
		return {}
	if FilthManager.filth_cells.is_empty():
		return {}

	var target := FilthManager.get_nearest_filth(pawn.grid_pos, 30)
	if target.x < 0:
		return {}

	var job := Job.new()
	job.job_def = "Clean"
	job.target_pos = target
	return {"job": job}
