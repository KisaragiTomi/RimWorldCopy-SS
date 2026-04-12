extends Node

enum Priority { CRITICAL, HIGH, NORMAL, LOW }

var _queue: Array[Dictionary] = []
var _total_completed: int = 0
var _total_cancelled: int = 0

func add_blueprint(bp_id: int, pos: Vector2i, def_id: String, priority: int = Priority.NORMAL) -> void:
	_queue.append({
		"bp_id": bp_id,
		"pos": pos,
		"def_id": def_id,
		"priority": priority,
		"added_tick": TickManager.current_tick if TickManager else 0,
	})
	_sort_queue()


func remove_blueprint(bp_id: int, completed: bool = false) -> void:
	for i: int in range(_queue.size() - 1, -1, -1):
		if _queue[i].bp_id == bp_id:
			_queue.remove_at(i)
			if completed:
				_total_completed += 1
			else:
				_total_cancelled += 1
			return


func set_priority(bp_id: int, priority: int) -> void:
	for entry: Dictionary in _queue:
		if entry.bp_id == bp_id:
			entry.priority = priority
			break
	_sort_queue()


func get_next_blueprint() -> Dictionary:
	if _queue.is_empty():
		return {}
	return _queue[0]


func _sort_queue() -> void:
	_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.priority != b.priority:
			return a.priority < b.priority
		return a.added_tick < b.added_tick
	)


func get_queue_size() -> int:
	return _queue.size()


func get_priority_label(priority: int) -> String:
	var labels: Array[String] = ["Critical", "High", "Normal", "Low"]
	if priority >= 0 and priority < labels.size():
		return labels[priority]
	return "Unknown"


func get_queue_by_def() -> Dictionary:
	var result: Dictionary = {}
	for entry: Dictionary in _queue:
		result[entry.def_id] = result.get(entry.def_id, 0) + 1
	return result


func get_oldest_blueprint() -> Dictionary:
	if _queue.is_empty():
		return {}
	return _queue[-1]


func promote_to_critical(bp_id: int) -> void:
	set_priority(bp_id, Priority.CRITICAL)


func get_critical_count() -> int:
	var count: int = 0
	for entry: Dictionary in _queue:
		if entry.priority == Priority.CRITICAL:
			count += 1
	return count


func get_completion_rate() -> float:
	var total: int = _total_completed + _total_cancelled
	if total == 0:
		return 0.0
	return snappedf(float(_total_completed) / float(total), 0.01)


func get_most_queued_def() -> String:
	var by_def := get_queue_by_def()
	var best: String = ""
	var best_n: int = 0
	for d: String in by_def:
		if by_def[d] > best_n:
			best_n = by_def[d]
			best = d
	return best


func has_pending_work() -> bool:
	return not _queue.is_empty()


func get_workload_rating() -> String:
	if _queue.is_empty():
		return "Clear"
	elif _queue.size() <= 5:
		return "Light"
	elif _queue.size() <= 15:
		return "Moderate"
	return "Heavy"

func get_efficiency_score() -> float:
	var total: int = _total_completed + _total_cancelled
	if total <= 0:
		return 0.0
	return snappedf(float(_total_completed) / float(total) * 100.0, 0.1)

func get_urgency_pct() -> float:
	if _queue.is_empty():
		return 0.0
	return snappedf(float(get_critical_count()) / float(_queue.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	var by_priority: Dictionary = {}
	for entry: Dictionary in _queue:
		var label: String = get_priority_label(entry.priority)
		by_priority[label] = by_priority.get(label, 0) + 1
	return {
		"queue_size": _queue.size(),
		"by_priority": by_priority,
		"by_def": get_queue_by_def(),
		"total_completed": _total_completed,
		"total_cancelled": _total_cancelled,
		"critical_count": get_critical_count(),
		"completion_rate": get_completion_rate(),
		"most_queued": get_most_queued_def(),
		"has_work": has_pending_work(),
		"cancel_rate": snappedf(float(_total_cancelled) / maxf(float(_total_completed + _total_cancelled), 1.0) * 100.0, 0.1),
		"avg_queue_per_def": snappedf(float(_queue.size()) / maxf(float(get_queue_by_def().size()), 1.0), 0.1),
		"workload_rating": get_workload_rating(),
		"efficiency_score": get_efficiency_score(),
		"urgency_pct": get_urgency_pct(),
		"construction_throughput": get_construction_throughput(),
		"project_health": get_project_health(),
		"resource_pipeline_rating": get_resource_pipeline_rating(),
		"build_program_maturity": get_build_program_maturity(),
		"infrastructure_momentum": get_infrastructure_momentum(),
		"construction_governance": get_construction_governance(),
	}

func get_build_program_maturity() -> float:
	var efficiency := get_efficiency_score()
	var total: int = _total_completed + _total_cancelled
	if total <= 0:
		return 0.0
	return snapped(efficiency * float(_total_completed) / maxf(float(total), 1.0), 0.1)

func get_infrastructure_momentum() -> String:
	var throughput := get_construction_throughput()
	var health := get_project_health()
	if throughput == "High" and health == "Healthy":
		return "Accelerating"
	elif throughput == "None" or health == "Backlogged":
		return "Stalled"
	return "Steady"

func get_construction_governance() -> float:
	var urgency := get_urgency_pct()
	var efficiency := get_efficiency_score()
	return snapped(clampf(efficiency - urgency * 0.5, 0.0, 100.0), 0.1)

func get_construction_throughput() -> String:
	var rate := get_completion_rate()
	if rate >= 80.0:
		return "High"
	elif rate >= 50.0:
		return "Moderate"
	elif rate > 0.0:
		return "Low"
	return "None"

func get_project_health() -> String:
	var urgency := get_urgency_pct()
	var efficiency := get_efficiency_score()
	if urgency < 20.0 and efficiency >= 70.0:
		return "Healthy"
	elif urgency < 50.0:
		return "Strained"
	return "Backlogged"

func get_resource_pipeline_rating() -> String:
	var cancel_rate := float(_total_cancelled) / maxf(float(_total_completed + _total_cancelled), 1.0) * 100.0
	if cancel_rate < 10.0:
		return "Smooth"
	elif cancel_rate < 30.0:
		return "Intermittent"
	return "Bottlenecked"
