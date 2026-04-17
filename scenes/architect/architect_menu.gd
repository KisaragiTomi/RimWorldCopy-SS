extends Control

signal designator_selected(designator_name: String)
signal designator_cleared

var _category_row: HBoxContainer
var _designator_panel: PanelContainer
var _designator_grid: GridContainer
var _active_category := ""
var _selected_designator := ""
var _category_buttons: Dictionary = {}
var _designator_buttons: Dictionary = {}


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()


func show_panel() -> void:
	visible = true


func hide_panel() -> void:
	visible = false
	_clear_category()


func _clear_category() -> void:
	if _active_category != "" and _active_category in _category_buttons:
		_apply_cat_style(_category_buttons[_active_category], false)
	_active_category = ""
	_selected_designator = ""
	if _designator_panel:
		_designator_panel.visible = false


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(spacer)

	_designator_panel = PanelContainer.new()
	_designator_panel.custom_minimum_size.y = 180
	_designator_panel.visible = false
	_designator_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := RWTheme.make_stylebox_flat(
		Color(0.16, 0.16, 0.15, 0.95), RWTheme.BORDER_COLOR, 1
	)
	panel_style.content_margin_left = 10
	panel_style.content_margin_top = 8
	panel_style.content_margin_right = 10
	panel_style.content_margin_bottom = 8
	_designator_panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(_designator_panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_designator_panel.add_child(scroll)

	_designator_grid = GridContainer.new()
	_designator_grid.columns = 7
	_designator_grid.add_theme_constant_override("h_separation", 4)
	_designator_grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(_designator_grid)

	var cat_panel := PanelContainer.new()
	cat_panel.custom_minimum_size.y = 36
	cat_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var cat_style := RWTheme.make_stylebox_flat(Color(0.14, 0.14, 0.14, 0.95))
	cat_style.content_margin_left = 4
	cat_style.content_margin_top = 2
	cat_style.content_margin_right = 4
	cat_style.content_margin_bottom = 2
	cat_panel.add_theme_stylebox_override("panel", cat_style)
	root.add_child(cat_panel)

	_category_row = HBoxContainer.new()
	_category_row.add_theme_constant_override("separation", 2)
	_category_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cat_panel.add_child(_category_row)

	for cat in GameState.architect_categories:
		_add_category_button(cat)


func _add_category_button(cat: Dictionary) -> void:
	var btn := Button.new()
	btn.text = cat.name
	btn.custom_minimum_size = Vector2(80, 28)
	btn.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
	_apply_cat_style(btn, false)
	btn.pressed.connect(_on_category_selected.bind(cat.name))
	_category_row.add_child(btn)
	_category_buttons[cat.name] = btn


func _apply_cat_style(btn: Button, active: bool) -> void:
	if active:
		btn.add_theme_stylebox_override("normal", RWTheme.make_texture_button_hover())
		btn.add_theme_stylebox_override("hover", RWTheme.make_texture_button_hover())
		btn.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
		btn.add_theme_color_override("font_hover_color", RWTheme.TEXT_YELLOW)
	else:
		btn.add_theme_stylebox_override("normal", RWTheme.make_texture_button_normal())
		btn.add_theme_stylebox_override("hover", RWTheme.make_texture_button_hover())
		btn.add_theme_stylebox_override("pressed", RWTheme.make_texture_button_pressed())
		btn.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		btn.add_theme_color_override("font_hover_color", RWTheme.TEXT_WHITE)


func _on_category_selected(cat_name: String) -> void:
	if _active_category == cat_name:
		_clear_category()
		return

	if _active_category != "" and _active_category in _category_buttons:
		_apply_cat_style(_category_buttons[_active_category], false)

	_active_category = cat_name
	_selected_designator = ""
	_apply_cat_style(_category_buttons[cat_name], true)
	_populate_designators(cat_name)
	_designator_panel.visible = true


func _populate_designators(cat_name: String) -> void:
	for child in _designator_grid.get_children():
		child.queue_free()
	_designator_buttons.clear()

	var cat: Dictionary = {}
	for c in GameState.architect_categories:
		if c.name == cat_name:
			cat = c
			break

	if cat.is_empty():
		return

	for item in cat.items:
		_add_designator_button(item)


func _add_designator_button(item: Dictionary) -> void:
	var btn_container := VBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 2)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(64, 64)
	btn.tooltip_text = item.desc
	_apply_designator_style(btn, false)

	var tex := DefData.get_designator_texture(item.name)
	if tex:
		btn.icon = tex
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		btn.text = item.name[0]
		btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(_on_designator_clicked.bind(item.name, btn))
	btn_container.add_child(btn)
	_designator_buttons[item.name] = btn

	var lbl := Label.new()
	lbl.text = item.name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
	lbl.custom_minimum_size.x = 64
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_container.add_child(lbl)

	_designator_grid.add_child(btn_container)


func _apply_designator_style(btn: Button, selected: bool) -> void:
	if selected:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.35, 0.32, 0.22, 0.95)
		s.border_color = RWTheme.BORDER_HIGHLIGHT
		s.border_width_left = 2
		s.border_width_top = 2
		s.border_width_right = 2
		s.border_width_bottom = 2
		btn.add_theme_stylebox_override("normal", s)
		btn.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	else:
		var normal_s := StyleBoxFlat.new()
		normal_s.bg_color = Color(0.22, 0.22, 0.20, 0.9)
		normal_s.border_color = Color(0.4, 0.4, 0.38, 0.6)
		normal_s.border_width_left = 1
		normal_s.border_width_top = 1
		normal_s.border_width_right = 1
		normal_s.border_width_bottom = 1
		btn.add_theme_stylebox_override("normal", normal_s)
		btn.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5, 1.0))

		var hover_s := normal_s.duplicate()
		hover_s.bg_color = Color(0.3, 0.29, 0.24, 0.95)
		hover_s.border_color = RWTheme.BORDER_HIGHLIGHT
		btn.add_theme_stylebox_override("hover", hover_s)
		btn.add_theme_color_override("font_hover_color", RWTheme.TEXT_YELLOW)


func _on_designator_clicked(item_name: String, btn: Button) -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	if _selected_designator != "" and _selected_designator in _designator_buttons:
		_apply_designator_style(_designator_buttons[_selected_designator], false)

	if _selected_designator == item_name:
		_selected_designator = ""
		designator_cleared.emit()
		return

	_selected_designator = item_name
	_apply_designator_style(btn, true)
	designator_selected.emit(item_name)


func get_active_designator() -> String:
	return _selected_designator


func clear_selection() -> void:
	if _selected_designator != "" and _selected_designator in _designator_buttons:
		_apply_designator_style(_designator_buttons[_selected_designator], false)
	_selected_designator = ""
	designator_cleared.emit()
