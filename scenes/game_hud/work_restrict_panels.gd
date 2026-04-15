extends Control

var _work_panel: Control
var _restrict_panel: Control
var _work_grid: GridContainer
var _work_cells: Dictionary = {}

const WORK_TYPES: Array[String] = [
	"Firefighter", "Patient", "Doctor", "Sleep", "Flick",
	"Warden", "Handle", "Cook", "Hunt", "Construct",
	"Grow", "Mine", "Haul",
]


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_work_panel()
	_build_restrict_panel()
	hide_all()


func show_work() -> void:
	visible = true
	_work_panel.visible = true
	_restrict_panel.visible = false
	_refresh_work_grid()


func show_restrict() -> void:
	visible = true
	_work_panel.visible = false
	_restrict_panel.visible = true
	_refresh_restrict_grid()


func hide_all() -> void:
	visible = false
	if _work_panel:
		_work_panel.visible = false
	if _restrict_panel:
		_restrict_panel.visible = false


func _build_work_panel() -> void:
	_work_panel = PanelContainer.new()
	_work_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_work_panel.visible = false
	_work_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := RWTheme.make_stylebox_flat(
		Color(0.13, 0.125, 0.11, 0.96), RWTheme.BORDER_COLOR, 1
	)
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	_work_panel.add_theme_stylebox_override("panel", style)
	add_child(_work_panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_work_panel.add_child(scroll)

	_work_grid = GridContainer.new()
	_work_grid.columns = WORK_TYPES.size() + 1
	_work_grid.add_theme_constant_override("h_separation", 0)
	_work_grid.add_theme_constant_override("v_separation", 0)
	scroll.add_child(_work_grid)


func _refresh_work_grid() -> void:
	for child in _work_grid.get_children():
		child.queue_free()
	_work_cells.clear()

	var empty_header := Label.new()
	empty_header.text = ""
	empty_header.custom_minimum_size = Vector2(70, 24)
	_work_grid.add_child(empty_header)
	for wt: String in WORK_TYPES:
		var header := Label.new()
		header.text = wt.substr(0, 5)
		header.add_theme_font_size_override("font_size", 9)
		header.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.custom_minimum_size = Vector2(50, 24)
		header.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.tooltip_text = wt
		_work_grid.add_child(header)

	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var name_lbl := Label.new()
		name_lbl.text = p.pawn_name
		name_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		name_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		name_lbl.custom_minimum_size = Vector2(70, 28)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_work_grid.add_child(name_lbl)

		for wt: String in WORK_TYPES:
			var priority: int = p.work_priorities.get(wt, 0)
			var cell := Button.new()
			cell.custom_minimum_size = Vector2(50, 28)
			cell.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
			_style_priority_cell(cell, priority)
			cell.tooltip_text = "%s - %s: Priority %d" % [p.pawn_name, wt, priority]
			cell.pressed.connect(_on_work_cell_clicked.bind(p.id, wt, cell))
			_work_grid.add_child(cell)
			_work_cells["%d_%s" % [p.id, wt]] = cell


func _style_priority_cell(cell: Button, priority: int) -> void:
	cell.text = str(priority) if priority > 0 else ""
	var cell_style := StyleBoxFlat.new()
	cell_style.content_margin_left = 2
	cell_style.content_margin_right = 2
	cell_style.content_margin_top = 2
	cell_style.content_margin_bottom = 2
	cell_style.border_color = Color(0.3, 0.3, 0.3, 0.4)
	cell_style.border_width_left = 1
	cell_style.border_width_top = 1
	cell_style.border_width_right = 1
	cell_style.border_width_bottom = 1

	match priority:
		1:
			cell_style.bg_color = Color(0.2, 0.4, 0.2, 0.6)
			cell.add_theme_color_override("font_color", RWTheme.TEXT_GREEN)
		2:
			cell_style.bg_color = Color(0.3, 0.35, 0.2, 0.4)
			cell.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
		3:
			cell_style.bg_color = Color(0.25, 0.25, 0.2, 0.3)
			cell.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		4:
			cell_style.bg_color = Color(0.2, 0.2, 0.2, 0.2)
			cell.add_theme_color_override("font_color", RWTheme.TEXT_DARK)
		_:
			cell_style.bg_color = Color(0.15, 0.15, 0.15, 0.3)

	cell.add_theme_stylebox_override("normal", cell_style)
	var hover_s: StyleBoxFlat = cell_style.duplicate()
	hover_s.border_color = RWTheme.BORDER_HIGHLIGHT
	cell.add_theme_stylebox_override("hover", hover_s)


func _on_work_cell_clicked(pawn_id: int, work_type: String, cell: Button) -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.id == pawn_id:
			var current: int = p.work_priorities.get(work_type, 0)
			var next: int = (current + 1) % 5
			p.work_priorities[work_type] = next
			_style_priority_cell(cell, next)
			cell.tooltip_text = "%s - %s: Priority %d" % [p.pawn_name, work_type, next]
			if AudioManager:
				AudioManager.play_sfx("ui_click")
			break


var _restrict_vbox: VBoxContainer

const SCHEDULE_NAMES: Array[String] = ["Sleep", "Anything", "Work", "Joy"]
const SCHEDULE_COLORS: Array[Color] = [
	Color(0.2, 0.25, 0.45, 0.7),
	Color(0.3, 0.45, 0.25, 0.6),
	Color(0.35, 0.5, 0.3, 0.7),
	Color(0.45, 0.35, 0.2, 0.7),
]

func _build_restrict_panel() -> void:
	_restrict_panel = PanelContainer.new()
	_restrict_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_restrict_panel.visible = false
	_restrict_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := RWTheme.make_stylebox_flat(
		Color(0.13, 0.125, 0.11, 0.96), RWTheme.BORDER_COLOR, 1
	)
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	_restrict_panel.add_theme_stylebox_override("panel", style)
	add_child(_restrict_panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_restrict_panel.add_child(scroll)

	_restrict_vbox = VBoxContainer.new()
	_restrict_vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(_restrict_vbox)


func _refresh_restrict_grid() -> void:
	for child in _restrict_vbox.get_children():
		child.queue_free()

	var legend_row := HBoxContainer.new()
	legend_row.add_theme_constant_override("separation", 12)
	_restrict_vbox.add_child(legend_row)
	for i: int in SCHEDULE_NAMES.size():
		var swatch := ColorRect.new()
		swatch.color = SCHEDULE_COLORS[i]
		swatch.custom_minimum_size = Vector2(14, 14)
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		legend_row.add_child(swatch)
		var lbl := Label.new()
		lbl.text = SCHEDULE_NAMES[i]
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		legend_row.add_child(lbl)

	var template_row := HBoxContainer.new()
	template_row.add_theme_constant_override("separation", 6)
	_restrict_vbox.add_child(template_row)
	var tmpl_lbl := Label.new()
	tmpl_lbl.text = "Templates:"
	tmpl_lbl.add_theme_font_size_override("font_size", 9)
	tmpl_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
	template_row.add_child(tmpl_lbl)
	for tmpl_name: String in ["Default", "NightOwl", "EarlyBird"]:
		var tmpl_btn := Button.new()
		tmpl_btn.text = tmpl_name
		tmpl_btn.custom_minimum_size = Vector2(70, 20)
		tmpl_btn.add_theme_font_size_override("font_size", 9)
		tmpl_btn.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		tmpl_btn.pressed.connect(_on_template_all.bind(tmpl_name))
		template_row.add_child(tmpl_btn)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 0)
	_restrict_vbox.add_child(header_row)

	var name_header := Label.new()
	name_header.text = "Colonist"
	name_header.custom_minimum_size = Vector2(80, 24)
	name_header.add_theme_font_size_override("font_size", 9)
	name_header.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
	name_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.add_child(name_header)

	for h: int in range(24):
		var hour_lbl := Label.new()
		hour_lbl.text = str(h)
		hour_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hour_lbl.custom_minimum_size = Vector2(28, 24)
		hour_lbl.add_theme_font_size_override("font_size", 8)
		hour_lbl.add_theme_color_override("font_color", RWTheme.TEXT_DARK)
		hour_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header_row.add_child(hour_lbl)

	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		_restrict_vbox.add_child(row)

		var name_lbl := Label.new()
		name_lbl.text = p.pawn_name
		name_lbl.custom_minimum_size = Vector2(80, 22)
		name_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		name_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(name_lbl)

		var schedule: Array[int] = ScheduleManager.get_schedule(p.id) if ScheduleManager else []

		for h: int in range(24):
			var sched_idx: int = 1
			if h < schedule.size():
				sched_idx = clampi(schedule[h], 0, 3)
			var cell_btn := Button.new()
			cell_btn.custom_minimum_size = Vector2(28, 22)
			cell_btn.tooltip_text = "%s - %02d:00 %s" % [p.pawn_name, h, SCHEDULE_NAMES[sched_idx]]
			_style_schedule_cell(cell_btn, sched_idx)
			cell_btn.pressed.connect(_on_schedule_cell_clicked.bind(p.id, h, cell_btn))
			row.add_child(cell_btn)


func _style_schedule_cell(btn: Button, sched_idx: int) -> void:
	var cs := StyleBoxFlat.new()
	cs.bg_color = SCHEDULE_COLORS[sched_idx]
	cs.set_border_width_all(0)
	cs.set_content_margin_all(0)
	btn.add_theme_stylebox_override("normal", cs)
	var hover_cs: StyleBoxFlat = cs.duplicate()
	hover_cs.bg_color = SCHEDULE_COLORS[sched_idx].lightened(0.2)
	hover_cs.border_color = RWTheme.BORDER_HIGHLIGHT
	hover_cs.set_border_width_all(1)
	btn.add_theme_stylebox_override("hover", hover_cs)


func _on_schedule_cell_clicked(pawn_id: int, hour: int, btn: Button) -> void:
	if not ScheduleManager:
		return
	var sched: Array[int] = ScheduleManager.get_schedule(pawn_id)
	var current: int = sched[hour] if hour < sched.size() else 1
	var next: int = (current + 1) % 4
	ScheduleManager.set_hour_activity(pawn_id, hour, next)
	_style_schedule_cell(btn, next)
	var pawn_name: String = ""
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.id == pawn_id:
				pawn_name = p.pawn_name
				break
	btn.tooltip_text = "%s - %02d:00 %s" % [pawn_name, hour, SCHEDULE_NAMES[next]]
	if AudioManager:
		AudioManager.play_sfx("ui_click")


func _on_template_all(template_name: String) -> void:
	if not ScheduleManager or not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		ScheduleManager.apply_template(p.id, template_name)
	_refresh_restrict_grid()
	if AudioManager:
		AudioManager.play_sfx("click")
