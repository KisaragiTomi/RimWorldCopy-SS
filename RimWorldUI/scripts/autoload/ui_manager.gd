extends Node

var _window_stack: Array[Control] = []
var _ui_layer: CanvasLayer


func _ready() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 10
	add_child(_ui_layer)


func open_window(window: Control) -> void:
	if window in _window_stack:
		bring_to_front(window)
		return
	_window_stack.append(window)
	_ui_layer.add_child(window)


func close_window(window: Control) -> void:
	if window in _window_stack:
		_window_stack.erase(window)
	if window.get_parent() == _ui_layer:
		_ui_layer.remove_child(window)
		window.queue_free()


func close_all() -> void:
	for w in _window_stack.duplicate():
		close_window(w)


func bring_to_front(window: Control) -> void:
	if window.get_parent() == _ui_layer:
		_ui_layer.move_child(window, _ui_layer.get_child_count() - 1)


func is_window_open(window: Control) -> bool:
	return window in _window_stack


func has_open_windows() -> bool:
	return _window_stack.size() > 0


func get_top_window() -> Control:
	if _window_stack.is_empty():
		return null
	return _window_stack.back()


func get_open_window_count() -> int:
	return _window_stack.size()


func get_window_names() -> Array[String]:
	var result: Array[String] = []
	for w: Control in _window_stack:
		result.append(w.name)
	return result


func close_by_name(window_name: String) -> bool:
	for w: Control in _window_stack:
		if w.name == window_name:
			close_window(w)
			return true
	return false


func toggle_window(window: Control) -> void:
	if is_window_open(window):
		close_window(window)
	else:
		open_window(window)


func get_window_index(window: Control) -> int:
	return _window_stack.find(window)


func get_window_stack_depth() -> int:
	return _window_stack.size()

func get_layer_index() -> int:
	if _ui_layer == null:
		return -1
	return _ui_layer.layer

func get_has_top_window() -> bool:
	return not _window_stack.is_empty()

func get_ui_complexity() -> int:
	var depth := get_window_stack_depth()
	var count := get_open_window_count()
	return depth + count

func get_responsiveness_score() -> float:
	var open := get_open_window_count()
	if open == 0:
		return 100.0
	return snapped(100.0 / float(open), 0.1)

func get_navigation_depth_pct() -> float:
	var depth := get_window_stack_depth()
	var max_depth := 10
	return snapped(float(depth) / float(max_depth) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"open_count": get_open_window_count(),
		"window_names": get_window_names(),
		"has_open": has_open_windows(),
		"stack_depth": get_window_stack_depth(),
		"layer_index": get_layer_index(),
		"has_top": get_has_top_window(),
		"ui_complexity": get_ui_complexity(),
		"responsiveness_score": get_responsiveness_score(),
		"navigation_depth_pct": get_navigation_depth_pct(),
	}
