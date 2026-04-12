class_name JobDriver
extends RefCounted

## Executes a Job by stepping through toils.
## Subclasses override _make_toils() to define behavior.

var pawn: Pawn
var job: Job
var _toils: Array[Dictionary] = []  # {name, complete_mode, delay_ticks}
var _toil_index: int = -1
var _toil_ticks: int = 0
var ended: bool = false
var succeeded: bool = false


func setup(p: Pawn, j: Job) -> void:
	pawn = p
	job = j
	_toils = _make_toils()
	_advance_toil()


func _make_toils() -> Array[Dictionary]:
	return []


func driver_tick() -> void:
	if ended or _toil_index < 0 or _toil_index >= _toils.size():
		return

	var toil: Dictionary = _toils[_toil_index]
	_toil_ticks += 1

	var toil_name: String = toil.get("name", "")
	_on_toil_tick(toil_name)

	var mode: String = toil.get("complete_mode", "instant")
	match mode:
		"instant":
			_advance_toil()
		"delay":
			if _toil_ticks >= toil.get("delay_ticks", 60):
				_advance_toil()
		"never":
			pass


func _on_toil_tick(_toil_name: String) -> void:
	pass


func _on_toil_init(_toil_name: String) -> void:
	pass


func _advance_toil() -> void:
	_toil_index += 1
	_toil_ticks = 0
	if _toil_index >= _toils.size():
		end_job(true)
		return
	var toil: Dictionary = _toils[_toil_index]
	var toil_name: String = toil.get("name", "")
	_on_toil_init(toil_name)


func end_job(success: bool) -> void:
	ended = true
	succeeded = success
	pawn.current_job_name = ""
	pawn.job_changed.emit("")


func get_toil_count() -> int:
	return _toils.size()


func get_progress_pct() -> float:
	if _toils.is_empty():
		return 100.0
	return snappedf(float(_toil_index + 1) / float(_toils.size()) * 100.0, 0.1)


func get_elapsed_ticks() -> int:
	var total: int = 0
	for i: int in range(_toil_index + 1):
		if i == _toil_index:
			total += _toil_ticks
		else:
			total += _toils[i].get("delay_ticks", 1)
	return total


func get_completion_forecast() -> float:
	if ended or _toils.is_empty() or _toil_index < 0:
		return 0.0
	var elapsed := get_elapsed_ticks()
	var done_toils := _toil_index
	if done_toils <= 0:
		var delay: int = _toils[0].get("delay_ticks", 60)
		return float(delay * _toils.size())
	var avg_ticks_per_toil := float(elapsed) / float(done_toils)
	return snapped(avg_ticks_per_toil * float(_toils.size() - done_toils), 0.1)

func get_efficiency_rating() -> String:
	if _toils.is_empty():
		return "N/A"
	var total_expected := 0.0
	for t: Dictionary in _toils:
		total_expected += float(t.get("delay_ticks", 60))
	var elapsed := float(get_elapsed_ticks())
	if total_expected <= 0.0:
		return "Instant"
	var ratio := elapsed / total_expected
	if ratio <= 0.8:
		return "Fast"
	elif ratio <= 1.2:
		return "Normal"
	elif ratio <= 2.0:
		return "Slow"
	return "Stalled"

func get_bottleneck_toil() -> String:
	if _toils.size() < 2:
		return ""
	var worst_name := ""
	var worst_delay := 0
	for t: Dictionary in _toils:
		var d: int = t.get("delay_ticks", 60)
		if d > worst_delay:
			worst_delay = d
			worst_name = t.get("name", "unnamed")
	return worst_name

func get_driver_summary() -> Dictionary:
	return {
		"job_def": job.job_def if job else "",
		"toil_count": get_toil_count(),
		"current_toil": _toil_index,
		"progress_pct": get_progress_pct(),
		"elapsed_ticks": get_elapsed_ticks(),
		"ended": ended,
		"succeeded": succeeded,
		"completion_forecast": get_completion_forecast(),
		"efficiency_rating": get_efficiency_rating(),
		"bottleneck_toil": get_bottleneck_toil(),
		"driver_ecosystem_health": get_driver_ecosystem_health(),
		"task_governance": get_task_governance(),
		"workflow_maturity_index": get_workflow_maturity_index(),
	}

func get_driver_ecosystem_health() -> float:
	var forecast := minf(get_completion_forecast(), 100.0)
	var rating := get_efficiency_rating()
	var r_val: float = 90.0 if rating == "Excellent" else (70.0 if rating == "Good" else (40.0 if rating == "Average" else 15.0))
	var progress := get_progress_pct()
	return snapped((forecast + r_val + progress) / 3.0, 0.1)

func get_task_governance() -> String:
	var eco := get_driver_ecosystem_health()
	var mat := get_workflow_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif not _toils.is_empty():
		return "Nascent"
	return "Dormant"

func get_workflow_maturity_index() -> float:
	var progress := get_progress_pct()
	var forecast := minf(get_completion_forecast(), 100.0)
	var toil_count := minf(float(get_toil_count()) * 20.0, 100.0)
	return snapped((progress + forecast + toil_count) / 3.0, 0.1)
