extends Node

var _recruit_progress: Dictionary = {}
var _total_recruited: int = 0
var _total_attempts: int = 0

const BASE_RECRUIT_CHANCE: float = 0.01
const SOCIAL_FACTOR: float = 0.005
const MOOD_FACTOR: float = 0.002
const RESISTANCE_DECAY: float = 0.5


func attempt_recruit(warden_id: int, prisoner_id: int, warden_social_skill: int, prisoner_mood: float) -> Dictionary:
	if not _recruit_progress.has(prisoner_id):
		_recruit_progress[prisoner_id] = {"resistance": 20.0, "attempts": 0}

	var prog: Dictionary = _recruit_progress[prisoner_id]
	prog.attempts = int(prog.get("attempts", 0)) + 1
	_total_attempts += 1

	var resistance: float = float(prog.get("resistance", 20.0))
	var decay: float = RESISTANCE_DECAY + float(warden_social_skill) * 0.1
	resistance = maxf(0.0, resistance - decay)
	prog.resistance = resistance

	if resistance > 0.0:
		return {"recruited": false, "resistance_left": snapped(resistance, 0.1), "attempts": prog.attempts}

	var chance: float = BASE_RECRUIT_CHANCE + float(warden_social_skill) * SOCIAL_FACTOR + prisoner_mood * MOOD_FACTOR
	chance = clampf(chance, 0.01, 0.9)

	if randf() < chance:
		_recruit_progress.erase(prisoner_id)
		_total_recruited += 1
		if ColonyLog and ColonyLog.has_method("add_entry"):
			ColonyLog.add_entry("Prisoner", "Prisoner " + str(prisoner_id) + " recruited!", "info")
		return {"recruited": true, "chance_was": snapped(chance, 0.01)}

	return {"recruited": false, "resistance_left": 0.0, "chance_was": snapped(chance, 0.01), "attempts": prog.attempts}


func get_most_resistant() -> Dictionary:
	var worst_id: int = -1
	var worst_res: float = 0.0
	for pid: int in _recruit_progress:
		var res: float = float(_recruit_progress[pid].get("resistance", 0.0))
		if res > worst_res:
			worst_res = res
			worst_id = pid
	if worst_id < 0:
		return {}
	return {"prisoner_id": worst_id, "resistance": snapped(worst_res, 0.1)}


func get_recruit_rate() -> float:
	if _total_attempts <= 0:
		return 0.0
	return snappedf(float(_total_recruited) / float(_total_attempts) * 100.0, 0.1)


func get_avg_attempts_per_recruit() -> float:
	if _total_recruited == 0:
		return 0.0
	return snappedf(float(_total_attempts) / float(_total_recruited), 0.1)


func get_avg_resistance() -> float:
	if _recruit_progress.is_empty():
		return 0.0
	var total: float = 0.0
	for pid: int in _recruit_progress:
		total += float(_recruit_progress[pid].get("resistance", 0.0))
	return snappedf(total / float(_recruit_progress.size()), 0.1)


func get_ready_to_recruit_count() -> int:
	var count: int = 0
	for pid: int in _recruit_progress:
		if float(_recruit_progress[pid].get("resistance", 1.0)) <= 0.0:
			count += 1
	return count


func get_high_resistance_count() -> int:
	var count: int = 0
	for pid: int in _recruit_progress:
		if float(_recruit_progress[pid].get("resistance", 0.0)) > 10.0:
			count += 1
	return count


func get_avg_attempts_per_prisoner() -> float:
	if _recruit_progress.is_empty():
		return 0.0
	var total: int = 0
	for pid: int in _recruit_progress:
		total += int(_recruit_progress[pid].get("attempts", 0))
	return snappedf(float(total) / float(_recruit_progress.size()), 0.1)


func get_easiest_prisoner() -> Dictionary:
	var best_id: int = -1
	var best_res: float = 999.0
	for pid: int in _recruit_progress:
		var res: float = float(_recruit_progress[pid].get("resistance", 999.0))
		if res < best_res:
			best_res = res
			best_id = pid
	if best_id < 0:
		return {}
	return {"prisoner_id": best_id, "resistance": snapped(best_res, 0.1)}


func get_conversion_efficiency() -> String:
	var rate: float = get_recruit_rate()
	if rate >= 50.0:
		return "Excellent"
	elif rate >= 25.0:
		return "Good"
	elif rate > 0.0:
		return "Low"
	return "None"

func get_pipeline_health() -> String:
	var ready: int = get_ready_to_recruit_count()
	var total: int = _recruit_progress.size()
	if total == 0:
		return "Empty"
	var pct: float = float(ready) / float(total) * 100.0
	if pct >= 50.0:
		return "Productive"
	elif pct > 0.0:
		return "Active"
	return "Stalled"

func get_stubbornness_ratio() -> float:
	if _recruit_progress.is_empty():
		return 0.0
	return snappedf(float(get_high_resistance_count()) / float(_recruit_progress.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"prisoners_tracked": _recruit_progress.size(),
		"total_recruited": _total_recruited,
		"total_attempts": _total_attempts,
		"recruit_rate_pct": get_recruit_rate(),
		"most_resistant": get_most_resistant(),
		"avg_attempts": get_avg_attempts_per_recruit(),
		"avg_resistance": get_avg_resistance(),
		"ready_count": get_ready_to_recruit_count(),
		"high_resistance_count": get_high_resistance_count(),
		"avg_attempts_per_prisoner": get_avg_attempts_per_prisoner(),
		"easiest_prisoner": get_easiest_prisoner(),
		"conversion_efficiency": get_conversion_efficiency(),
		"pipeline_health": get_pipeline_health(),
		"stubbornness_ratio_pct": get_stubbornness_ratio(),
		"rehabilitation_throughput": get_rehabilitation_throughput(),
		"persuasion_effectiveness": get_persuasion_effectiveness(),
		"intake_capacity": get_intake_capacity(),
		"rehabilitation_ecosystem_health": get_rehabilitation_ecosystem_health(),
		"conversion_mastery_index": get_conversion_mastery_index(),
		"penal_governance": get_penal_governance(),
	}

func get_rehabilitation_throughput() -> float:
	var recruited := _total_recruited
	var attempts := _total_attempts
	if attempts <= 0:
		return 0.0
	return snapped(float(recruited) / float(attempts) * 100.0, 0.1)

func get_persuasion_effectiveness() -> String:
	var efficiency := get_conversion_efficiency()
	var pipeline := get_pipeline_health()
	if efficiency in ["Excellent", "Good"] and pipeline in ["Productive"]:
		return "Highly Effective"
	elif efficiency in ["Good"]:
		return "Effective"
	return "Struggling"

func get_intake_capacity() -> String:
	var tracked := _recruit_progress.size()
	var ready := get_ready_to_recruit_count()
	if tracked >= 5 and ready >= 2:
		return "Full Pipeline"
	elif tracked >= 2:
		return "Active"
	elif tracked > 0:
		return "Minimal"
	return "Empty"

func get_rehabilitation_ecosystem_health() -> float:
	var throughput := get_rehabilitation_throughput()
	var effectiveness := get_persuasion_effectiveness()
	var e_val: float = 90.0 if effectiveness == "Highly Effective" else (60.0 if effectiveness == "Effective" else 30.0)
	var stubbornness := get_stubbornness_ratio()
	return snapped((throughput + e_val + maxf(100.0 - stubbornness, 0.0)) / 3.0, 0.1)

func get_conversion_mastery_index() -> float:
	var efficiency := get_conversion_efficiency()
	var e_val: float = 90.0 if efficiency in ["Excellent"] else (70.0 if efficiency in ["Good"] else (40.0 if efficiency in ["Fair"] else 20.0))
	var pipeline := get_pipeline_health()
	var p_val: float = 90.0 if pipeline == "Productive" else (50.0 if pipeline == "Active" else 20.0)
	return snapped((e_val + p_val) / 2.0, 0.1)

func get_penal_governance() -> String:
	var health := get_rehabilitation_ecosystem_health()
	var mastery := get_conversion_mastery_index()
	if health >= 65.0 and mastery >= 60.0:
		return "Systematic"
	elif health >= 35.0 or mastery >= 30.0:
		return "Functional"
	return "Ad Hoc"
