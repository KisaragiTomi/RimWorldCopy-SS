extends Control

var _offset := Vector2.ZERO
var _dragging := false
var _node_rects: Dictionary = {}
var _selected_name := ""

const NODE_W := 180.0
const NODE_H := 56.0
const GRID_SPACING := Vector2(230, 85)


func _ready() -> void:
	_offset = size / 2.0 if size.x > 0 else Vector2(500, 400)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_selected(proj_name: String) -> void:
	_selected_name = proj_name
	queue_redraw()


func _draw() -> void:
	_node_rects.clear()

	for project in GameState.research_projects:
		for prereq_name in project.prereqs:
			var prereq := _find_project(prereq_name)
			if prereq.is_empty():
				continue
			var from_pos := _get_node_center(prereq)
			var to_pos := _get_node_center(project)
			var line_color := Color(0.5, 0.5, 0.5, 0.4)
			if project.name == _selected_name or prereq_name == _selected_name:
				line_color = Color(0.7, 0.65, 0.3, 0.7)
			draw_line(from_pos, to_pos, line_color, 2.0)
			_draw_arrow(from_pos, to_pos, line_color)

	for project in GameState.research_projects:
		_draw_node(project)


func _draw_node(project: Dictionary) -> void:
	var pos := _get_node_pos(project)
	var rect := Rect2(pos, Vector2(NODE_W, NODE_H))
	_node_rects[project.name] = rect

	var progress_ratio := 0.0
	if project.cost > 0:
		progress_ratio = float(project.progress) / float(project.cost)
	var completed := progress_ratio >= 1.0
	var is_selected: bool = (project.name == _selected_name)

	var bg_color: Color
	var border_color: Color
	if completed:
		bg_color = Color(0.2, 0.28, 0.22, 0.95)
		border_color = Color(0.4, 0.65, 0.4, 0.8)
	elif progress_ratio > 0:
		bg_color = Color(0.22, 0.25, 0.3, 0.95)
		border_color = Color(0.4, 0.55, 0.7, 0.8)
	else:
		bg_color = Color(0.18, 0.18, 0.18, 0.95)
		border_color = Color(0.4, 0.4, 0.4, 0.6)

	if is_selected:
		bg_color = bg_color.lightened(0.15)
		border_color = RWTheme.BORDER_HIGHLIGHT

	draw_rect(rect, bg_color)
	var border_w := 2.5 if is_selected else 1.5
	draw_rect(rect, border_color, false, border_w)

	if progress_ratio > 0 and not completed:
		var fill_rect := Rect2(pos, Vector2(NODE_W * progress_ratio, 4))
		draw_rect(fill_rect, RWTheme.BAR_RESEARCH)
	elif completed:
		draw_rect(Rect2(pos, Vector2(NODE_W, 4)), Color(0.3, 0.7, 0.3, 0.8))

	var name_color := RWTheme.TEXT_YELLOW if is_selected else RWTheme.TEXT_WHITE
	var name_pos := pos + Vector2(10, 22)
	draw_string(ThemeDB.fallback_font, name_pos, project.name, HORIZONTAL_ALIGNMENT_LEFT, NODE_W - 20, RWTheme.FONT_SMALL, name_color)

	var cost_text := "%d / %d" % [project.progress, project.cost]
	var cost_pos := pos + Vector2(10, 42)
	var cost_color := RWTheme.TEXT_GREEN if completed else RWTheme.TEXT_GRAY
	draw_string(ThemeDB.fallback_font, cost_pos, cost_text, HORIZONTAL_ALIGNMENT_LEFT, NODE_W - 20, RWTheme.FONT_TINY, cost_color)


func _draw_arrow(from: Vector2, to: Vector2, color: Color) -> void:
	var dir := (to - from).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var arrow_pos := to - dir * (NODE_W * 0.5 + 5)
	var arrow_size := 6.0
	var p1 := arrow_pos
	var p2 := arrow_pos - dir * arrow_size + perp * arrow_size * 0.5
	var p3 := arrow_pos - dir * arrow_size - perp * arrow_size * 0.5
	draw_colored_polygon(PackedVector2Array([p1, p2, p3]), color)


func _get_node_pos(project: Dictionary) -> Vector2:
	return Vector2(project.pos.x, project.pos.y) * GRID_SPACING + _offset - Vector2(NODE_W, NODE_H) * 0.5


func _get_node_center(project: Dictionary) -> Vector2:
	return _get_node_pos(project) + Vector2(NODE_W, NODE_H) * 0.5


func _find_project(proj_name: String) -> Dictionary:
	for p in GameState.research_projects:
		if p.name == proj_name:
			return p
	return {}


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var clicked := _get_clicked_node(event.position)
				if clicked.is_empty():
					_dragging = true
				else:
					var tree := get_parent()
					if tree.has_method("select_project"):
						tree.select_project(clicked)
					accept_event()
			else:
				_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		_offset += event.relative
		queue_redraw()
		accept_event()


func _get_clicked_node(pos: Vector2) -> Dictionary:
	for proj_name in _node_rects:
		var rect: Rect2 = _node_rects[proj_name]
		if rect.has_point(pos):
			return _find_project(proj_name)
	return {}
