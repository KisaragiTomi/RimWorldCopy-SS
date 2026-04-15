extends Control

var _canvas: Control
var _info_panel: PanelContainer
var _selected_project: Dictionary = {}
var _project_name_label: Label
var _project_desc_label: Label
var _project_progress_bar: ProgressBar
var _project_progress_label: Label
var _research_btn: Button
var _node_positions: Dictionary = {}

const NODE_W := 180.0
const NODE_H := 60.0
const GRID_SPACING := Vector2(220, 90)
const CENTER_OFFSET := Vector2(500, 400)


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


func show_panel() -> void:
	visible = true
	if _canvas:
		_canvas.queue_redraw()


func hide_panel() -> void:
	visible = false


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.10, 0.10, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.set_script(load("res://scenes/research/research_canvas.gd"))
	add_child(_canvas)

	_build_info_panel()

	var header := PanelContainer.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 36
	var h_style := RWTheme.make_stylebox_flat(Color(0.12, 0.12, 0.12, 0.95))
	h_style.content_margin_left = 12
	h_style.content_margin_top = 4
	h_style.content_margin_right = 12
	h_style.content_margin_bottom = 4
	header.add_theme_stylebox_override("panel", h_style)
	add_child(header)

	var title := Label.new()
	title.text = "Research"
	title.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	title.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	header.add_child(title)


func _build_info_panel() -> void:
	_info_panel = PanelContainer.new()
	_info_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_info_panel.offset_left = -260
	_info_panel.offset_top = 40
	var style := RWTheme.make_stylebox_flat(
		Color(0.14, 0.14, 0.14, 0.95), RWTheme.BORDER_COLOR, 1
	)
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	_info_panel.add_theme_stylebox_override("panel", style)
	add_child(_info_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_info_panel.add_child(vbox)

	_project_name_label = Label.new()
	_project_name_label.text = "Select a project"
	_project_name_label.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	_project_name_label.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	vbox.add_child(_project_name_label)

	vbox.add_child(RWWidgets.create_separator())

	_project_desc_label = Label.new()
	_project_desc_label.text = "Click a research node to view details."
	_project_desc_label.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	_project_desc_label.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
	_project_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_project_desc_label)

	var progress_header := Label.new()
	progress_header.text = "Progress"
	progress_header.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	progress_header.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	vbox.add_child(progress_header)

	_project_progress_bar = RWWidgets.create_fillable_bar(0, 100, RWTheme.BAR_RESEARCH, 220, 20)
	vbox.add_child(_project_progress_bar)

	_project_progress_label = Label.new()
	_project_progress_label.text = "0 / 0"
	_project_progress_label.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
	_project_progress_label.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
	vbox.add_child(_project_progress_label)

	vbox.add_child(RWWidgets.create_separator())

	var prereqs_title := Label.new()
	prereqs_title.text = "Prerequisites"
	prereqs_title.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	prereqs_title.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	vbox.add_child(prereqs_title)

	_research_btn = RWWidgets.create_button("Research", _on_research_clicked, 220)
	_research_btn.custom_minimum_size.y = 36
	vbox.add_child(_research_btn)


func select_project(project: Dictionary) -> void:
	_selected_project = project
	var pname: String = str(project.get("name", ""))
	_project_name_label.text = pname

	var cost: float = float(project.get("cost", 0))
	var progress: float = float(project.get("progress", 0))
	if ResearchManager:
		progress = ResearchManager.get_progress(pname)
		if ResearchManager.is_completed(pname):
			progress = cost

	_project_progress_bar.max_value = cost
	_project_progress_bar.value = progress
	_project_progress_label.text = "%d / %d" % [int(progress), int(cost)]

	var prereqs: Array = project.get("prereqs", [])
	var prereqs_met := true
	if ResearchManager:
		for pr in prereqs:
			if not ResearchManager.is_completed(str(pr)):
				prereqs_met = false
				break

	if progress >= cost:
		_project_desc_label.text = "Research completed."
		_research_btn.text = "Completed"
		_research_btn.disabled = true
	elif not prereqs_met:
		_project_desc_label.text = "Research cost: %d\nPrerequisites not met!" % int(cost)
		_research_btn.text = "Locked"
		_research_btn.disabled = true
	elif ResearchManager and ResearchManager.current_project == pname:
		_project_desc_label.text = "Research cost: %d\nCurrently researching..." % int(cost)
		_research_btn.text = "In Progress"
		_research_btn.disabled = true
	else:
		_project_desc_label.text = "Research cost: %d" % int(cost)
		_research_btn.text = "Start Research"
		_research_btn.disabled = false

	var prereq_text := ""
	if prereqs.is_empty():
		prereq_text = "None"
	else:
		var parts: PackedStringArray = []
		for pr in prereqs:
			var pr_str := str(pr)
			if ResearchManager and ResearchManager.is_completed(pr_str):
				parts.append(pr_str + " ✓")
			else:
				parts.append(pr_str + " ✗")
		prereq_text = ", ".join(parts)
	_project_desc_label.text += "\nPrerequisites: " + prereq_text

	if _canvas and _canvas.has_method("set_selected"):
		_canvas.set_selected(pname)


func _on_research_clicked() -> void:
	if _selected_project.is_empty():
		return
	var pname: String = str(_selected_project.get("name", ""))
	if pname.is_empty():
		return

	if ResearchManager:
		if ResearchManager.is_completed(pname):
			return
		if ResearchManager.start_project(pname):
			if ColonyLog:
				ColonyLog.add_entry("Research", "Started researching %s" % pname, "info")
			if AudioManager:
				AudioManager.play_sfx("ui_click")
			select_project(_selected_project)
			if _canvas:
				_canvas.queue_redraw()
	else:
		for i: int in GameState.research_projects.size():
			if str(GameState.research_projects[i].get("name", "")) == pname:
				var cost: int = GameState.research_projects[i].get("cost", 0)
				var prog: int = GameState.research_projects[i].get("progress", 0)
				var added: int = mini(500, cost - prog)
				GameState.research_projects[i]["progress"] = prog + added
				_selected_project = GameState.research_projects[i]
				select_project(_selected_project)
				if _canvas:
					_canvas.queue_redraw()
				break
