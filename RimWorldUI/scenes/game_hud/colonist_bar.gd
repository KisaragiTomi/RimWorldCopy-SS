extends Control

var _bar_container: HBoxContainer
var _portrait_buttons: Dictionary = {}
var _portrait_entries: Dictionary = {}
var _selected_name := ""
var _mood_warn_tweens: Dictionary = {}

const PORTRAIT_SIZE := Vector2(50, 62)
const BAR_SPACING := 2
const MOOD_BREAK_THRESHOLD := 0.2
const MOOD_MINOR_THRESHOLD := 0.3

var _refresh_timer: float = 0.0
const REFRESH_INTERVAL := 1.5


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_bar()


func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= REFRESH_INTERVAL:
		_refresh_timer = 0.0
		_sync_from_pawns()


func _sync_from_pawns() -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if p.pawn_name in _portrait_entries:
			var panel: PanelContainer = _portrait_entries[p.pawn_name]
			var mood: float = p.get_need("Mood")
			var mood_color := ColonistData.get_mood_color(mood)
			if p.drafted:
				var ds := StyleBoxFlat.new()
				ds.bg_color = Color(0.45, 0.1, 0.1, 0.85)
				ds.border_color = RWTheme.TEXT_RED
				ds.set_border_width_all(2)
				ds.set_content_margin_all(2)
				panel.add_theme_stylebox_override("panel", ds)
			elif p.pawn_name != _selected_name:
				_apply_entry_panel_style(panel, mood_color, false)

			_update_mood_warning(p.pawn_name, panel, mood)

			var vbox := panel.get_child(0) as VBoxContainer
			if vbox and vbox.get_child_count() >= 2:
				var bar := vbox.get_child(1) as ProgressBar
				if bar:
					bar.value = mood
					var fill := StyleBoxFlat.new()
					fill.bg_color = mood_color
					bar.add_theme_stylebox_override("fill", fill)


func highlight_colonist(cname: String) -> void:
	_clear_highlight()
	_selected_name = cname
	if cname in _portrait_entries:
		var entry_panel: PanelContainer = _portrait_entries[cname]
		var sel_style := StyleBoxFlat.new()
		sel_style.bg_color = Color(0.25, 0.35, 0.25, 0.9)
		sel_style.border_color = RWTheme.TEXT_YELLOW
		sel_style.set_border_width_all(2)
		sel_style.content_margin_left = 2
		sel_style.content_margin_top = 2
		sel_style.content_margin_right = 2
		sel_style.content_margin_bottom = 2
		entry_panel.add_theme_stylebox_override("panel", sel_style)


func clear_selection() -> void:
	_clear_highlight()
	_selected_name = ""


func _clear_highlight() -> void:
	if _selected_name != "" and _selected_name in _portrait_entries:
		var colonist := _find_colonist(_selected_name)
		if not colonist.is_empty():
			_restore_entry_style(colonist)


func _find_colonist(cname: String) -> Dictionary:
	for c in GameState.colonists:
		if str(c.get("name", "")) == cname:
			return c
	return {}


func _build_bar() -> void:
	_bar_container = HBoxContainer.new()
	_bar_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_bar_container.add_theme_constant_override("separation", BAR_SPACING)
	_bar_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_bar_container)

	for colonist in GameState.colonists:
		_add_colonist_entry(colonist)


func _add_colonist_entry(colonist: Dictionary) -> void:
	var cname: String = str(colonist.get("name", "?"))
	var c_mood: float = colonist.get("mood", 0.5)
	var entry_panel := PanelContainer.new()
	var mood_color := ColonistData.get_mood_color(c_mood)
	_apply_entry_panel_style(entry_panel, mood_color, false)
	_bar_container.add_child(entry_panel)
	_portrait_entries[cname] = entry_panel

	var entry := VBoxContainer.new()
	entry.add_theme_constant_override("separation", 0)
	entry_panel.add_child(entry)

	var portrait_area := Control.new()
	portrait_area.custom_minimum_size = PORTRAIT_SIZE
	entry.add_child(portrait_area)

	var head_tex_path: String = colonist.get("head_texture", "")
	if head_tex_path != "" and ResourceLoader.exists(head_tex_path):
		var tex: Texture2D = load(head_tex_path)
		var head_rect := TextureRect.new()
		head_rect.texture = tex
		head_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		head_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		head_rect.modulate = Color(0.85, 0.75, 0.65, 1.0)
		head_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_area.add_child(head_rect)

	var portrait_btn := Button.new()
	portrait_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait_btn.flat = true
	portrait_btn.tooltip_text = "%s (Age %s)\nMood: %s (%d%%)\nFood: %d%%  Rest: %d%%  Joy: %d%%\nMain Skill: %s\n\nClick to inspect" % [
		cname, str(colonist.get("age", "?")),
		ColonistData.get_mood_label(c_mood), int(c_mood * 100),
		int(colonist.get("food", 0.5) * 100), int(colonist.get("rest", 0.5) * 100),
		int(colonist.get("joy", 0.5) * 100), str(colonist.get("main_skill", "?")),
	]
	var transparent_sb := StyleBoxFlat.new()
	transparent_sb.bg_color = Color(0, 0, 0, 0)
	portrait_btn.add_theme_stylebox_override("normal", transparent_sb)
	var hover_sb := StyleBoxFlat.new()
	hover_sb.bg_color = Color(1.0, 1.0, 1.0, 0.08)
	portrait_btn.add_theme_stylebox_override("hover", hover_sb)
	portrait_btn.pressed.connect(_select_colonist.bind(colonist))
	portrait_area.add_child(portrait_btn)
	_portrait_buttons[cname] = portrait_btn

	var mood_bar := ProgressBar.new()
	mood_bar.min_value = 0.0
	mood_bar.max_value = 1.0
	mood_bar.value = c_mood
	mood_bar.show_percentage = false
	mood_bar.custom_minimum_size = Vector2(PORTRAIT_SIZE.x, 5)
	mood_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.08, 0.08, 0.08, 0.95)
	bar_bg.content_margin_left = 0
	bar_bg.content_margin_right = 0
	bar_bg.content_margin_top = 0
	bar_bg.content_margin_bottom = 0
	mood_bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = mood_color
	mood_bar.add_theme_stylebox_override("fill", bar_fill)
	entry.add_child(mood_bar)

	var name_lbl := Label.new()
	name_lbl.text = cname
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	name_lbl.custom_minimum_size.x = PORTRAIT_SIZE.x
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_child(name_lbl)


func _apply_entry_panel_style(panel: PanelContainer, mood_color: Color, selected: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = mood_color.darkened(0.65) if not selected else Color(0.25, 0.35, 0.25, 0.9)
	s.border_color = mood_color.darkened(0.3) if not selected else RWTheme.TEXT_YELLOW
	s.set_border_width_all(1 if not selected else 2)
	s.content_margin_left = 2
	s.content_margin_top = 2
	s.content_margin_right = 2
	s.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", s)


func _restore_entry_style(colonist: Dictionary) -> void:
	var cname: String = str(colonist.get("name", ""))
	if cname in _portrait_entries:
		var panel: PanelContainer = _portrait_entries[cname]
		var mood_color := ColonistData.get_mood_color(colonist.get("mood", 0.5))
		if colonist.get("drafted", false):
			var ds := StyleBoxFlat.new()
			ds.bg_color = Color(0.45, 0.1, 0.1, 0.85)
			ds.border_color = RWTheme.TEXT_RED
			ds.set_border_width_all(2)
			ds.content_margin_left = 2
			ds.content_margin_top = 2
			ds.content_margin_right = 2
			ds.content_margin_bottom = 2
			panel.add_theme_stylebox_override("panel", ds)
		else:
			_apply_entry_panel_style(panel, mood_color, false)


func _update_mood_warning(pawn_name: String, panel: PanelContainer, mood: float) -> void:
	var has_tween: bool = _mood_warn_tweens.has(pawn_name)
	if mood <= MOOD_BREAK_THRESHOLD:
		if not has_tween:
			var tw := panel.create_tween()
			tw.set_loops()
			tw.tween_property(panel, "modulate", Color(1.0, 0.4, 0.4, 1.0), 0.5)
			tw.tween_property(panel, "modulate", Color.WHITE, 0.5)
			_mood_warn_tweens[pawn_name] = tw
	elif mood <= MOOD_MINOR_THRESHOLD:
		if has_tween:
			_mood_warn_tweens[pawn_name].kill()
			_mood_warn_tweens.erase(pawn_name)
			panel.modulate = Color.WHITE
	else:
		if has_tween:
			_mood_warn_tweens[pawn_name].kill()
			_mood_warn_tweens.erase(pawn_name)
			panel.modulate = Color.WHITE


func _select_colonist(colonist: Dictionary) -> void:
	GameState.colonist_selected.emit(colonist)
