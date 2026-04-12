class_name JobGiverRest
extends ThinkNode

## Issues rest jobs when pawn is exhausted, targeting an available bed if possible.

const REST_THRESHOLD := 0.2

func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.get_need("Rest") > REST_THRESHOLD:
		return {}
	if pawn.drafted:
		return {}

	var bed: Building = null
	if BedManager:
		bed = BedManager.find_best_bed(pawn)

	var target_pos: Vector2i = bed.grid_pos if bed else pawn.grid_pos
	var j := Job.new("Rest", target_pos)
	if bed:
		j.target_thing_id = bed.id
	return {"job": j, "source": self}

func get_rest_threshold() -> float:
	return REST_THRESHOLD

func estimate_rest_gain(quality: float = 1.0) -> float:
	return snappedf(0.05 * quality, 0.001)

func would_sleep_on_ground(pawn: Pawn) -> bool:
	if not BedManager:
		return true
	return BedManager.find_best_bed(pawn) == null

func get_rest_summary() -> Dictionary:
	return {
		"threshold": REST_THRESHOLD,
		"base_rest_gain": estimate_rest_gain(),
		"rest_ecosystem_health": get_rest_ecosystem_health(),
		"sleep_governance": get_sleep_governance(),
		"recovery_maturity_index": get_recovery_maturity_index(),
	}

func get_rest_ecosystem_health() -> float:
	var gain := estimate_rest_gain()
	var gain_score := minf(gain / 0.05 * 100.0, 100.0)
	var threshold_health := maxf((1.0 - REST_THRESHOLD) * 100.0, 0.0)
	return snapped((gain_score + threshold_health) / 2.0, 0.1)

func get_sleep_governance() -> String:
	var eco := get_rest_ecosystem_health()
	var mat := get_recovery_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	return "Nascent"

func get_recovery_maturity_index() -> float:
	var gain := estimate_rest_gain()
	var gain_norm := minf(gain / 0.05 * 100.0, 100.0)
	var bed_available: float = 70.0 if BedManager else 30.0
	return snapped((gain_norm + bed_available) / 2.0, 0.1)
