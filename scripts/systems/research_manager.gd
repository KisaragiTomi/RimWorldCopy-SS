extends Node

## Manages research projects, progress, and unlocking.
## Registered as autoload "ResearchManager".

signal research_completed(project_name: String)
signal research_progress_changed(project_name: String, progress: float, cost: float)

var _completed: Dictionary = {}
var _progress: Dictionary = {}
var current_project: String = ""


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func get_all_projects() -> Array[Dictionary]:
	if not DefDB:
		return []
	return DefDB.get_all("ResearchProjectDef")


func start_project(project_name: String) -> bool:
	if _completed.has(project_name):
		return false
	var proj := DefDB.get_def("ResearchProjectDef", project_name) if DefDB else {}
	if proj.is_empty():
		return false
	for prereq: String in proj.get("prerequisites", []):
		if not _completed.has(prereq):
			return false
	current_project = project_name
	if not _progress.has(project_name):
		_progress[project_name] = 0.0
	return true


func get_progress(project_name: String) -> float:
	return _progress.get(project_name, 0.0)


func is_completed(project_name: String) -> bool:
	return _completed.has(project_name)


var research_queue: Array[String] = []
var total_completed: int = 0


func queue_project(project_name: String) -> bool:
	if _completed.has(project_name):
		return false
	if project_name in research_queue:
		return false
	research_queue.append(project_name)
	if current_project.is_empty():
		_start_next_queued()
	return true


func _start_next_queued() -> void:
	while not research_queue.is_empty():
		var next: String = research_queue.pop_front()
		if start_project(next):
			return


func _on_rare_tick(_tick: int) -> void:
	if current_project.is_empty():
		_auto_start_cheapest()
		if current_project.is_empty():
			return
	var proj := DefDB.get_def("ResearchProjectDef", current_project) if DefDB else {}
	if proj.is_empty():
		return

	var work_amount: float = _calc_research_speed()
	if work_amount <= 0.0:
		return

	var cost: float = proj.get("baseCost", 1000)
	_progress[current_project] = _progress.get(current_project, 0.0) + work_amount

	research_progress_changed.emit(current_project, _progress[current_project], cost)

	if _progress[current_project] >= cost:
		_complete_project(current_project)


func _calc_research_speed() -> float:
	if not PawnManager:
		return 0.0
	var total_speed: float = 0.0
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed or p.is_in_mental_break():
			continue
		if p.has_meta("faction") and p.get_meta("faction") == "enemy":
			continue
		if not p.is_capable_of("Research"):
			continue
		var skill: int = p.get_skill_level("Intellectual")
		total_speed += 0.5 + float(skill) * 0.08
	return total_speed


func _count_researchers() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed or p.is_in_mental_break():
			continue
		if p.has_meta("faction") and p.get_meta("faction") == "enemy":
			continue
		if p.is_capable_of("Research"):
			count += 1
	return count


func _complete_project(project_name: String) -> void:
	_completed[project_name] = true
	total_completed += 1
	current_project = ""
	research_completed.emit(project_name)
	if ColonyLog:
		ColonyLog.add_entry("Research", "Research complete: %s." % project_name, "positive")
	_start_next_queued()


func get_progress_pct(project_name: String) -> float:
	var proj := DefDB.get_def("ResearchProjectDef", project_name) if DefDB else {}
	if proj.is_empty():
		return 0.0
	var cost: float = proj.get("baseCost", 1000)
	return clampf(_progress.get(project_name, 0.0) / cost, 0.0, 1.0)


func _auto_start_cheapest() -> void:
	if not research_queue.is_empty():
		_start_next_queued()
		return
	var avail := get_available_projects()
	if avail.is_empty():
		_start_repeatable()
		return
	var best_name: String = avail[0]
	var best_cost: float = 999999.0
	for pname: String in avail:
		var proj := DefDB.get_def("ResearchProjectDef", pname) if DefDB else {}
		var cost: float = proj.get("baseCost", 999999.0)
		if cost < best_cost:
			best_cost = cost
			best_name = pname
	start_project(best_name)


func _start_repeatable() -> void:
	for proj: Dictionary in get_all_projects():
		if not proj.get("repeatable", false):
			continue
		var pname: String = proj.get("defName", "")
		if pname.is_empty():
			continue
		_completed.erase(pname)
		_progress[pname] = 0.0
		start_project(pname)
		return


func get_available_projects() -> Array[String]:
	var result: Array[String] = []
	for proj: Dictionary in get_all_projects():
		var pname: String = proj.get("defName", "")
		if _completed.has(pname):
			continue
		var prereqs_met: bool = true
		for prereq: String in proj.get("prerequisites", []):
			if not _completed.has(prereq):
				prereqs_met = false
				break
		if prereqs_met:
			result.append(pname)
	return result


func get_queue_length() -> int:
	return research_queue.size()

func get_completion_percentage() -> float:
	var all_projs := get_all_projects()
	if all_projs.is_empty():
		return 0.0
	return snappedf(float(total_completed) / float(all_projs.size()) * 100.0, 0.1)

func get_in_progress_count() -> int:
	var count: int = 0
	for pname: String in _progress:
		if not _completed.has(pname):
			count += 1
	return count

func get_avg_speed_per_researcher() -> float:
	var researchers: int = _count_researchers()
	if researchers <= 0:
		return 0.0
	return snappedf(_calc_research_speed() / float(researchers), 0.01)

func get_total_progress_accumulated() -> float:
	var total: float = 0.0
	for pname: String in _progress:
		total += _progress[pname]
	return snappedf(total, 0.01)

func get_stalled_project_count() -> int:
	var count: int = 0
	for pname: String in _progress:
		if _completed.has(pname):
			continue
		if pname == current_project:
			continue
		if _progress[pname] > 0.0:
			count += 1
	return count

func get_research_throughput() -> float:
	var speed := _calc_research_speed()
	var researchers := _count_researchers()
	return snapped(speed * maxf(researchers, 1.0), 0.01)

func get_knowledge_coverage_pct() -> float:
	var all_projects := get_all_projects()
	if all_projects.is_empty():
		return 0.0
	return snapped(float(total_completed) / float(all_projects.size()) * 100.0, 0.1)

func get_pipeline_health() -> float:
	var queued := research_queue.size()
	var stalled := get_stalled_project_count()
	var active := 1 if not current_project.is_empty() else 0
	return snapped(float(active + queued) / maxf(active + queued + stalled, 1.0) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"current": current_project,
		"completed": _completed.keys(),
		"completed_count": total_completed,
		"queue": research_queue,
		"progress": _progress.duplicate(),
		"researchers": _count_researchers(),
		"speed": snappedf(_calc_research_speed(), 0.01),
		"available": get_available_projects().size(),
		"queue_length": get_queue_length(),
		"completion_pct": get_completion_percentage(),
		"in_progress": get_in_progress_count(),
		"avg_speed_per_researcher": get_avg_speed_per_researcher(),
		"total_progress_accumulated": get_total_progress_accumulated(),
		"stalled_projects": get_stalled_project_count(),
		"research_throughput": get_research_throughput(),
		"knowledge_coverage_pct": get_knowledge_coverage_pct(),
		"pipeline_health": get_pipeline_health(),
		"research_ecosystem_health": get_research_ecosystem_health(),
		"knowledge_governance": get_knowledge_governance(),
		"academic_maturity_index": get_academic_maturity_index(),
	}

func get_research_ecosystem_health() -> float:
	var throughput := get_research_throughput()
	var coverage := get_knowledge_coverage_pct()
	var pipeline := get_pipeline_health()
	return snapped((minf(throughput * 10.0, 100.0) + coverage + pipeline) / 3.0, 0.1)

func get_academic_maturity_index() -> float:
	var completion := get_completion_percentage()
	var stalled := get_stalled_project_count()
	var s_val: float = maxf(100.0 - float(stalled) * 20.0, 0.0)
	var speed := get_avg_speed_per_researcher()
	return snapped((completion + s_val + minf(speed * 100.0, 100.0)) / 3.0, 0.1)

func get_knowledge_governance() -> String:
	var ecosystem := get_research_ecosystem_health()
	var maturity := get_academic_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif not current_project.is_empty():
		return "Nascent"
	return "Dormant"
