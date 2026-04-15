extends Control

signal draft_toggled(pawn_id: int, drafted: bool)

var _panel: PanelContainer
var _content_area: Control
var _tab_bar: HBoxContainer
var _colonist_name_label: Label
var _draft_btn: Button
var _current_colonist: Dictionary = {}
var _active_tab := "needs"
var _tab_buttons: Dictionary = {}
var _refresh_timer: float = 0.0
const INSPECT_REFRESH_INTERVAL := 0.8


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_timer += delta
	if _refresh_timer >= INSPECT_REFRESH_INTERVAL:
		_refresh_timer = 0.0
		_sync_pawn_data()


func show_colonist(colonist: Dictionary) -> void:
	if colonist.is_empty():
		visible = false
		return
	_current_colonist = colonist
	var cname: String = str(colonist.get("name", "?"))
	var cage: String = str(colonist.get("age", "?"))
	_colonist_name_label.text = cname + " (" + cage + ")"
	_update_draft_button()
	visible = true
	_refresh_timer = 0.0
	_show_tab(_active_tab)


func _sync_pawn_data() -> void:
	var pid: int = _current_colonist.get("pawn_id", -1)
	if pid < 0 or not PawnManager:
		return
	var pawn: Pawn = null
	for p: Pawn in PawnManager.pawns:
		if p.id == pid:
			pawn = p
			break
	if pawn == null or pawn.dead:
		return

	_current_colonist["mood"] = pawn.get_need("Mood")
	_current_colonist["food"] = pawn.get_need("Food")
	_current_colonist["rest"] = pawn.get_need("Rest")
	_current_colonist["joy"] = pawn.get_need("Joy")
	_current_colonist["drafted"] = pawn.drafted
	_current_colonist["current_job"] = pawn.current_job_name

	if pawn.health:
		_current_colonist["health"] = pawn.health.get_overall_health()

	if pawn.equipment:
		var new_gear: Array[Dictionary] = []
		for slot: String in pawn.equipment.slots:
			var item_name: String = pawn.equipment.slots[slot]
			if not item_name.is_empty():
				new_gear.append({"slot": slot, "name": item_name})
		_current_colonist["gear"] = new_gear
		_current_colonist["armor_sharp"] = pawn.equipment.get_armor_sharp()
		_current_colonist["armor_blunt"] = pawn.equipment.get_armor_blunt()
		_current_colonist["insulation_cold"] = pawn.equipment.get_insulation_cold()
		_current_colonist["insulation_heat"] = pawn.equipment.get_insulation_heat()

	_update_draft_button()
	_show_tab(_active_tab)


func _on_draft_pressed() -> void:
	var pid: int = _current_colonist.get("pawn_id", -1)
	if pid < 0:
		return
	var is_drafted: bool = _current_colonist.get("drafted", false)
	_current_colonist["drafted"] = not is_drafted
	_update_draft_button()
	draft_toggled.emit(pid, not is_drafted)
	if AudioManager:
		AudioManager.play_sfx("draft" if not is_drafted else "undraft")


func _update_draft_button() -> void:
	if _draft_btn == null:
		return
	var is_drafted: bool = _current_colonist.get("drafted", false)
	if is_drafted:
		_draft_btn.text = "Undraft"
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.5, 0.15, 0.15, 0.9)
		style.border_color = RWTheme.TEXT_RED
		style.set_border_width_all(1)
		style.set_content_margin_all(4)
		_draft_btn.add_theme_stylebox_override("normal", style)
		_draft_btn.add_theme_color_override("font_color", RWTheme.TEXT_RED)
	else:
		_draft_btn.text = "Draft"
		_draft_btn.add_theme_stylebox_override("normal", RWTheme.make_texture_button_normal())
		_draft_btn.add_theme_stylebox_override("hover", RWTheme.make_texture_button_hover())
		_draft_btn.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		_draft_btn.add_theme_color_override("font_hover_color", RWTheme.TEXT_WHITE)


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := RWTheme.make_stylebox_flat(
		Color(0.13, 0.125, 0.11, 0.96), RWTheme.BORDER_COLOR, 1
	)
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	_panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	vbox.add_child(header)

	_colonist_name_label = Label.new()
	_colonist_name_label.text = "Colonist"
	_colonist_name_label.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	_colonist_name_label.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	_colonist_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_colonist_name_label)

	_draft_btn = Button.new()
	_draft_btn.text = "Draft"
	_draft_btn.custom_minimum_size = Vector2(60, 24)
	_draft_btn.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	_draft_btn.pressed.connect(_on_draft_pressed)
	header.add_child(_draft_btn)
	_update_draft_button()

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(24, 24)
	close_btn.add_theme_stylebox_override("normal", RWTheme.make_texture_button_normal())
	close_btn.add_theme_stylebox_override("hover", RWTheme.make_texture_button_hover())
	close_btn.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	close_btn.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
	close_btn.add_theme_color_override("font_hover_color", RWTheme.TEXT_WHITE)
	close_btn.pressed.connect(func(): GameState.colonist_selected.emit({}))
	header.add_child(close_btn)

	_tab_bar = HBoxContainer.new()
	_tab_bar.add_theme_constant_override("separation", 1)
	vbox.add_child(_tab_bar)

	var tabs := DefData.get_inspect_tabs()
	for tab in tabs:
		var btn := Button.new()
		btn.text = tab.name
		btn.custom_minimum_size = Vector2(70, 26)
		btn.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		btn.pressed.connect(_on_tab_pressed.bind(tab.key))
		_tab_bar.add_child(btn)
		_tab_buttons[tab.key] = btn
	_update_tab_styles()

	_content_area = Control.new()
	_content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_area.custom_minimum_size.y = 200
	vbox.add_child(_content_area)


func _on_tab_pressed(tab_key: String) -> void:
	_active_tab = tab_key
	_update_tab_styles()
	_show_tab(tab_key)


func _update_tab_styles() -> void:
	for key in _tab_buttons:
		var btn: Button = _tab_buttons[key]
		if key == _active_tab:
			btn.add_theme_stylebox_override("normal", RWTheme.make_texture_button_hover())
			btn.add_theme_stylebox_override("hover", RWTheme.make_texture_button_hover())
			btn.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
			btn.add_theme_color_override("font_hover_color", RWTheme.TEXT_YELLOW)
		else:
			btn.add_theme_stylebox_override("normal", RWTheme.make_texture_button_normal())
			btn.add_theme_stylebox_override("hover", RWTheme.make_texture_button_hover())
			btn.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
			btn.add_theme_color_override("font_hover_color", RWTheme.TEXT_WHITE)


func _show_tab(tab_key: String) -> void:
	for child in _content_area.get_children():
		child.queue_free()

	match tab_key:
		"needs":
			_build_needs_tab()
		"health":
			_build_health_tab()
		"skills":
			_build_skills_tab()
		"social":
			_build_social_tab()
		"gear":
			_build_gear_tab()
		"bio":
			_build_bio_tab()
		"log":
			_build_log_tab()
		_:
			_build_placeholder_tab(tab_key)


func _build_needs_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_area.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var c_mood: float = _current_colonist.get("mood", 0.5)
	var c_food: float = _current_colonist.get("food", 0.5)
	var c_rest: float = _current_colonist.get("rest", 0.5)
	var c_joy: float = _current_colonist.get("joy", 0.5)
	var needs := [
		{"name": "Mood", "value": c_mood, "color": ColonistData.get_mood_color(c_mood)},
		{"name": "Food", "value": c_food, "color": RWTheme.BAR_FOOD},
		{"name": "Rest", "value": c_rest, "color": RWTheme.BAR_REST},
		{"name": "Joy", "value": c_joy, "color": RWTheme.BAR_JOY},
	]

	for need in needs:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		vbox.add_child(row)

		var header := HBoxContainer.new()
		row.add_child(header)

		var name_lbl := Label.new()
		name_lbl.text = need.name
		name_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
		name_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		name_lbl.custom_minimum_size.x = 60
		header.add_child(name_lbl)

		var pct_lbl := Label.new()
		pct_lbl.text = "%d%%" % int(need.value * 100)
		pct_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		pct_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		header.add_child(pct_lbl)

		var bar := _create_need_bar(need.value, need.color)
		row.add_child(bar)

	vbox.add_child(RWWidgets.create_separator())

	var mood_header := Label.new()
	mood_header.text = "Mood: " + ColonistData.get_mood_label(c_mood)
	mood_header.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	mood_header.add_theme_color_override("font_color", ColonistData.get_mood_color(c_mood))
	vbox.add_child(mood_header)

	var thoughts: Array = _current_colonist.get("thoughts", [])
	if thoughts.is_empty():
		thoughts = [
			{"text": "Ate without table", "value": -3},
			{"text": "Slept in a bed", "value": 4},
			{"text": "Impressive dining room", "value": 5},
		]

	for thought in thoughts:
		var t_row := HBoxContainer.new()
		t_row.add_theme_constant_override("separation", 4)
		vbox.add_child(t_row)
		var t_lbl := Label.new()
		t_lbl.text = thought.text
		t_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		t_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		t_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t_row.add_child(t_lbl)
		var v_lbl := Label.new()
		v_lbl.text = "%+d" % thought.value
		v_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		v_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GREEN if thought.value > 0 else RWTheme.TEXT_RED)
		v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v_lbl.custom_minimum_size.x = 30
		t_row.add_child(v_lbl)


func _create_need_bar(value: float, color: Color) -> Control:
	var bar_container := Control.new()
	bar_container.custom_minimum_size = Vector2(0, 18)
	bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.05, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_container.add_child(bg)

	var fill := ColorRect.new()
	fill.color = color
	fill.anchor_right = value
	fill.anchor_bottom = 1.0
	bar_container.add_child(fill)

	var fill_highlight := ColorRect.new()
	fill_highlight.color = Color(1.0, 1.0, 1.0, 0.08)
	fill_highlight.anchor_right = value
	fill_highlight.anchor_bottom = 0.4
	bar_container.add_child(fill_highlight)

	var thresholds := [0.15, 0.30, 0.50, 0.70]
	for thresh in thresholds:
		var line := ColorRect.new()
		line.color = Color(0.3, 0.28, 0.25, 0.6)
		line.anchor_left = thresh
		line.anchor_right = thresh
		line.anchor_bottom = 1.0
		line.custom_minimum_size.x = 1
		bar_container.add_child(line)

	var border := ReferenceRect.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.border_color = Color(0.35, 0.33, 0.28, 0.7)
	border.border_width = 1.0
	border.editor_only = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_container.add_child(border)

	return bar_container


func _build_health_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_area.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 8)
	vbox.add_child(summary)

	var health_lbl := Label.new()
	health_lbl.text = "Health: %d%%" % int(_current_colonist.get("health", 1.0) * 100)
	health_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	health_lbl.add_theme_color_override("font_color", RWTheme.BAR_HEALTH)
	summary.add_child(health_lbl)

	vbox.add_child(RWWidgets.create_separator())

	var header_row := HBoxContainer.new()
	vbox.add_child(header_row)
	for col_text in ["Body Part", "HP", "Status"]:
		var h := Label.new()
		h.text = col_text
		h.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		h.add_theme_color_override("font_color", RWTheme.TEXT_DARK)
		h.custom_minimum_size.x = 100
		header_row.add_child(h)

	for part in _current_colonist.get("health_parts", []):
		var p_hp: float = part.get("hp", 1.0)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		vbox.add_child(row)

		var part_name := Label.new()
		part_name.text = str(part.get("part", "?"))
		part_name.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		part_name.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		part_name.custom_minimum_size.x = 100
		row.add_child(part_name)

		var hp_bar := _create_need_bar(p_hp, RWTheme.BAR_HEALTH)
		hp_bar.custom_minimum_size = Vector2(80, 12)
		row.add_child(hp_bar)

		var status_lbl := Label.new()
		status_lbl.text = str(part.get("status", "OK"))
		status_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		status_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GREEN if p_hp >= 0.9 else RWTheme.TEXT_YELLOW)
		status_lbl.custom_minimum_size.x = 60
		row.add_child(status_lbl)


func _build_skills_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_area.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var skills: Dictionary = _current_colonist.get("skills", {})
	for skill_name in skills:
		var level: int = skills[skill_name]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)

		var name_lbl := Label.new()
		name_lbl.text = skill_name
		name_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		name_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		name_lbl.custom_minimum_size.x = 90
		row.add_child(name_lbl)

		var bar := _create_skill_bar(level)
		row.add_child(bar)

		var lvl_lbl := Label.new()
		lvl_lbl.text = str(level)
		lvl_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		lvl_lbl.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW if level >= 10 else RWTheme.TEXT_GRAY)
		lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lvl_lbl.custom_minimum_size.x = 24
		row.add_child(lvl_lbl)


func _create_skill_bar(level: int) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(160, 14)

	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.1, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(bg)

	var fill := ColorRect.new()
	fill.color = Color(0.3, 0.5, 0.7, 0.8) if level < 10 else Color(0.7, 0.6, 0.2, 0.9)
	fill.anchor_right = clampf(float(level) / 20.0, 0.0, 1.0)
	fill.anchor_bottom = 1.0
	container.add_child(fill)

	return container


func _build_social_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_area.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var my_id: int = _current_colonist.get("id", -1)
	var my_name: String = str(_current_colonist.get("name", ""))

	var rel_types: Dictionary = {}
	if PawnRelationExt:
		rel_types = PawnRelationExt.RELATION_TYPES

	var other_pawns: Array[Dictionary] = []
	if PawnManager:
		for p: Pawn in PawnManager.colonists:
			if p.id != my_id and not p.dead:
				var rel_name: String = "Acquaintance"
				var base_op: int = 0
				var seed_hash: int = (my_id * 37 + p.id * 53) % rel_types.size()
				var idx: int = 0
				for rt: String in rel_types:
					if idx == absi(seed_hash):
						rel_name = rt
						base_op = int(rel_types[rt].get("opinion", 0))
						break
					idx += 1
				var op_jitter: int = ((my_id + p.id * 7) % 21) - 10
				var opinion: int = base_op + op_jitter
				other_pawns.append({
					"name": p.pawn_name,
					"mood": p.needs.get("mood", 0.5),
					"relation": rel_name,
					"opinion": opinion,
					"category": rel_types.get(rel_name, {}).get("category", "Social"),
				})
	else:
		for c: Dictionary in GameState.colonists:
			if str(c.get("name", "")) != my_name:
				other_pawns.append({
					"name": str(c.get("name", "?")),
					"mood": c.get("mood", 0.5),
					"relation": "Acquaintance",
					"opinion": 0,
					"category": "Social",
				})

	if other_pawns.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No social interactions yet."
		empty_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
		empty_lbl.add_theme_color_override("font_color", RWTheme.TEXT_DARK)
		vbox.add_child(empty_lbl)
		return

	var fabric_lbl := Label.new()
	if PawnRelationExt:
		fabric_lbl.text = "Social fabric: %s  |  Conflict: %s" % [
			PawnRelationExt.get_social_fabric(),
			PawnRelationExt.get_conflict_potential()
		]
	else:
		fabric_lbl.text = "Social fabric: Unknown"
	fabric_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
	fabric_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
	vbox.add_child(fabric_lbl)
	vbox.add_child(RWWidgets.create_separator())

	for entry: Dictionary in other_pawns:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)

		var portrait := Button.new()
		portrait.custom_minimum_size = Vector2(28, 28)
		var c_name_str: String = str(entry.get("name", "?"))
		var c_mood_val: float = entry.get("mood", 0.5)
		portrait.text = c_name_str[0] if not c_name_str.is_empty() else "?"
		portrait.add_theme_font_size_override("font_size", 14)
		portrait.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		portrait.flat = true
		var pstyle := StyleBoxFlat.new()
		pstyle.bg_color = ColonistData.get_mood_color(c_mood_val).darkened(0.5)
		pstyle.border_color = ColonistData.get_mood_color(c_mood_val).darkened(0.2)
		pstyle.set_border_width_all(1)
		portrait.add_theme_stylebox_override("normal", pstyle)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(portrait)

		var info_col := VBoxContainer.new()
		info_col.add_theme_constant_override("separation", 1)
		info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info_col)

		var name_lbl := Label.new()
		name_lbl.text = c_name_str
		name_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
		name_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		info_col.add_child(name_lbl)

		var rel_name: String = entry.get("relation", "Acquaintance")
		var category: String = entry.get("category", "Social")
		var rel_lbl := Label.new()
		rel_lbl.text = "%s (%s)" % [rel_name, category]
		rel_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		var rel_color: Color
		match category:
			"Romantic":
				rel_color = Color(0.9, 0.4, 0.6, 1.0)
			"Family":
				rel_color = Color(0.6, 0.8, 1.0, 1.0)
			"Social":
				if rel_name == "Friend":
					rel_color = RWTheme.TEXT_GREEN
				elif rel_name == "Rival":
					rel_color = RWTheme.TEXT_RED
				else:
					rel_color = RWTheme.TEXT_GRAY
			_:
				rel_color = RWTheme.TEXT_GRAY
		rel_lbl.add_theme_color_override("font_color", rel_color)
		info_col.add_child(rel_lbl)

		var op: int = entry.get("opinion", 0)
		var opinion_lbl := Label.new()
		opinion_lbl.text = "Opinion: %+d" % op
		opinion_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		opinion_lbl.add_theme_color_override(
			"font_color", RWTheme.TEXT_GREEN if op > 0 else (RWTheme.TEXT_RED if op < 0 else RWTheme.TEXT_GRAY)
		)
		opinion_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		opinion_lbl.custom_minimum_size.x = 80
		row.add_child(opinion_lbl)


func _build_gear_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_area.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var gear: Array = _current_colonist.get("gear", [])
	if gear.is_empty():
		var pid: int = _current_colonist.get("pawn_id", -1)
		if pid >= 0 and PawnManager:
			for p: Pawn in PawnManager.pawns:
				if p.id == pid and p.equipment:
					for slot: String in p.equipment.slots:
						var item_name: String = p.equipment.slots[slot]
						if not item_name.is_empty():
							gear.append({"slot": slot, "name": item_name})
					break

	if gear.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No equipment."
		empty_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
		empty_lbl.add_theme_color_override("font_color", RWTheme.TEXT_DARK)
		vbox.add_child(empty_lbl)
	else:
		for item: Dictionary in gear:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			vbox.add_child(row)

			var slot_lbl := Label.new()
			slot_lbl.text = str(item.get("slot", "?"))
			slot_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
			slot_lbl.add_theme_color_override("font_color", RWTheme.TEXT_DARK)
			slot_lbl.custom_minimum_size.x = 120
			row.add_child(slot_lbl)

			var name_lbl := Label.new()
			name_lbl.text = str(item.get("name", "?"))
			name_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
			name_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
			row.add_child(name_lbl)

	vbox.add_child(RWWidgets.create_separator())

	var stats_title := Label.new()
	stats_title.text = "Protection"
	stats_title.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	stats_title.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	vbox.add_child(stats_title)

	var armor_sharp: float = _current_colonist.get("armor_sharp", 0.0)
	var armor_blunt: float = _current_colonist.get("armor_blunt", 0.0)
	var cold_ins: float = _current_colonist.get("insulation_cold", 0.0)
	var heat_ins: float = _current_colonist.get("insulation_heat", 0.0)

	var stat_entries := [
		["Sharp armor", "%.0f%%" % (armor_sharp * 100.0)],
		["Blunt armor", "%.0f%%" % (armor_blunt * 100.0)],
		["Cold insulation", "%.0f°C" % cold_ins],
		["Heat insulation", "%.0f°C" % heat_ins],
	]
	for entry: Array in stat_entries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)
		var key_lbl := Label.new()
		key_lbl.text = str(entry[0])
		key_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		key_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		key_lbl.custom_minimum_size.x = 120
		row.add_child(key_lbl)
		var val_lbl := Label.new()
		val_lbl.text = str(entry[1])
		val_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		val_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		row.add_child(val_lbl)


func _build_bio_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_area.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var backstory: Dictionary = _current_colonist.get("backstory", {})
	var childhood: String = backstory.get("childhood", "Unknown")
	var adulthood: String = backstory.get("adulthood", "Unknown")
	var gender_str: String = _current_colonist.get("gender", "")
	var job_str: String = _current_colonist.get("current_job", "Idle")
	var mental_str: String = _current_colonist.get("mental_state", "")

	var bio_entries := [
		["Full Name", str(_current_colonist.get("name", "?"))],
		["Age", str(_current_colonist.get("age", "?"))],
		["Gender", gender_str if not gender_str.is_empty() else "Unknown"],
		["Main Skill", str(_current_colonist.get("main_skill", "?"))],
		["Current Job", job_str if not job_str.is_empty() else "Idle"],
		["Childhood", childhood],
		["Adulthood", adulthood],
	]

	if not mental_str.is_empty():
		bio_entries.append(["Mental State", mental_str])

	for entry in bio_entries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)

		var key_lbl := Label.new()
		key_lbl.text = str(entry[0]) + ":"
		key_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
		key_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		key_lbl.custom_minimum_size.x = 100
		row.add_child(key_lbl)

		var val_lbl := Label.new()
		val_lbl.text = str(entry[1])
		val_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
		val_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		row.add_child(val_lbl)

	vbox.add_child(RWWidgets.create_separator())

	var traits_title := Label.new()
	traits_title.text = "Traits"
	traits_title.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	traits_title.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	vbox.add_child(traits_title)

	var trait_list: Array = _current_colonist.get("traits", [])
	if trait_list.is_empty():
		trait_list = ["(none)"]
	for t in trait_list:
		var t_lbl := Label.new()
		t_lbl.text = "  - " + str(t)
		t_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		t_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		vbox.add_child(t_lbl)


func _build_log_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_area.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var cname: String = str(_current_colonist.get("name", "?"))
	var log_entries := [
		{"hour": "06:00", "type": "work",   "text": "%s started hauling steel to stockpile." % cname},
		{"hour": "07:30", "type": "social",  "text": "%s had a friendly chat with %s." % [cname, _other_name(0)]},
		{"hour": "09:15", "type": "work",   "text": "%s finished construction of wall (x12,y8)." % cname},
		{"hour": "11:00", "type": "combat", "text": "%s shot at raider with bolt-action rifle (hit, 12 dmg)." % cname},
		{"hour": "11:02", "type": "combat", "text": "%s was grazed by raider's knife (3 dmg, left arm)." % cname},
		{"hour": "12:00", "type": "need",   "text": "%s ate a simple meal (at table)." % cname},
		{"hour": "14:30", "type": "work",   "text": "%s sowed rice in growing zone." % cname},
		{"hour": "18:00", "type": "joy",    "text": "%s played horseshoes for joy." % cname},
		{"hour": "21:00", "type": "need",   "text": "%s went to bed in assigned room." % cname},
	]

	for entry in log_entries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)

		var time_lbl := Label.new()
		time_lbl.text = str(entry.get("hour", "??:??"))
		time_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		time_lbl.add_theme_color_override("font_color", RWTheme.TEXT_DARK)
		time_lbl.custom_minimum_size.x = 40
		row.add_child(time_lbl)

		var icon_lbl := Label.new()
		var entry_type: String = str(entry.get("type", ""))
		match entry_type:
			"combat":
				icon_lbl.text = "[!]"
				icon_lbl.add_theme_color_override("font_color", RWTheme.TEXT_RED)
			"social":
				icon_lbl.text = "[S]"
				icon_lbl.add_theme_color_override("font_color", RWTheme.TEXT_BLUE)
			"need":
				icon_lbl.text = "[N]"
				icon_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GREEN)
			"joy":
				icon_lbl.text = "[J]"
				icon_lbl.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
			_:
				icon_lbl.text = "[W]"
				icon_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		icon_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		icon_lbl.custom_minimum_size.x = 24
		row.add_child(icon_lbl)

		var text_lbl := Label.new()
		text_lbl.text = str(entry.get("text", ""))
		text_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		text_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text_lbl)


func _other_name(idx: int) -> String:
	var my_name: String = str(_current_colonist.get("name", ""))
	var others: Array[String] = []
	for c in GameState.colonists:
		if str(c.get("name", "")) != my_name:
			others.append(str(c.get("name", "?")))
	if idx < others.size():
		return others[idx]
	return "someone"


func _build_placeholder_tab(tab_name: String) -> void:
	var lbl := Label.new()
	lbl.text = tab_name + " tab - Coming soon"
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	lbl.add_theme_color_override("font_color", RWTheme.TEXT_DARK)
	_content_area.add_child(lbl)
