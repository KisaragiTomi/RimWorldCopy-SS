extends PanelContainer

var _resolution_btn: OptionButton
var _fullscreen_check: CheckBox
var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _vsync_check: CheckBox
var _autosave_check: CheckBox


func _ready() -> void:
	_apply_style()
	_build_ui()
	_load_current_settings()


func _apply_style() -> void:
	var panel := RWTheme.make_window_panel()
	panel.content_margin_left = 20
	panel.content_margin_top = 16
	panel.content_margin_right = 20
	panel.content_margin_bottom = 16
	add_theme_stylebox_override("panel", panel)


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 0)
	root.add_child(header)

	var title := Label.new()
	title.text = "Options"
	title.add_theme_font_size_override("font_size", RWTheme.FONT_LARGE)
	title.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.flat = true
	close_btn.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
	close_btn.add_theme_color_override("font_hover_color", RWTheme.TEXT_WHITE)
	close_btn.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)

	root.add_child(RWWidgets.create_separator())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var settings := VBoxContainer.new()
	settings.add_theme_constant_override("separation", 10)
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(settings)

	_add_section_header(settings, "Display")

	var res_row := _make_option_row("Resolution")
	_resolution_btn = OptionButton.new()
	_resolution_btn.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	_resolution_btn.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	for res_text in ["1920 x 1080", "2560 x 1440", "3840 x 2160", "1280 x 720"]:
		_resolution_btn.add_item(res_text)
	res_row.add_child(_resolution_btn)
	settings.add_child(res_row)

	_fullscreen_check = CheckBox.new()
	_fullscreen_check.text = "Fullscreen"
	_fullscreen_check.button_pressed = true
	_fullscreen_check.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	_fullscreen_check.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	settings.add_child(_fullscreen_check)

	_vsync_check = CheckBox.new()
	_vsync_check.text = "V-Sync"
	_vsync_check.button_pressed = true
	_vsync_check.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	_vsync_check.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	settings.add_child(_vsync_check)

	settings.add_child(RWWidgets.create_separator())
	_add_section_header(settings, "Audio")

	var master_row := _make_option_row("Master Volume")
	_master_slider = HSlider.new()
	_master_slider.min_value = 0.0
	_master_slider.max_value = 1.0
	_master_slider.value = 0.8
	_master_slider.step = 0.01
	_master_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	master_row.add_child(_master_slider)
	settings.add_child(master_row)

	var music_row := _make_option_row("Music Volume")
	_music_slider = HSlider.new()
	_music_slider.min_value = 0.0
	_music_slider.max_value = 1.0
	_music_slider.value = 0.6
	_music_slider.step = 0.01
	_music_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_row.add_child(_music_slider)
	settings.add_child(music_row)

	var sfx_row := _make_option_row("SFX Volume")
	_sfx_slider = HSlider.new()
	_sfx_slider.min_value = 0.0
	_sfx_slider.max_value = 1.0
	_sfx_slider.value = 0.8
	_sfx_slider.step = 0.01
	_sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_row.add_child(_sfx_slider)
	settings.add_child(sfx_row)

	settings.add_child(RWWidgets.create_separator())
	_add_section_header(settings, "Gameplay")

	_autosave_check = CheckBox.new()
	_autosave_check.text = "Auto-save every season"
	_autosave_check.button_pressed = true
	_autosave_check.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	_autosave_check.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	settings.add_child(_autosave_check)

	var pause_check := CheckBox.new()
	pause_check.text = "Pause on load"
	pause_check.button_pressed = true
	pause_check.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	pause_check.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	settings.add_child(pause_check)

	var edge_check := CheckBox.new()
	edge_check.text = "Edge screen scroll"
	edge_check.button_pressed = true
	edge_check.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	edge_check.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	settings.add_child(edge_check)

	root.add_child(RWWidgets.create_separator())

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(btn_row)

	var apply_btn := RWWidgets.create_button("Apply", _on_apply, 100)
	apply_btn.custom_minimum_size.y = 32
	btn_row.add_child(apply_btn)

	var close_btn2 := RWWidgets.create_button("Close", _on_close, 100)
	close_btn2.custom_minimum_size.y = 32
	btn_row.add_child(close_btn2)


func _make_option_row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
	lbl.custom_minimum_size.x = 140
	row.add_child(lbl)
	return row


func _add_section_header(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	lbl.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	parent.add_child(lbl)


func _load_current_settings() -> void:
	if AudioManager:
		_master_slider.value = AudioManager.master_volume
		_music_slider.value = AudioManager.music_volume
		_sfx_slider.value = AudioManager.sfx_volume
	var mode := DisplayServer.window_get_mode()
	_fullscreen_check.button_pressed = mode == DisplayServer.WINDOW_MODE_FULLSCREEN


func _on_apply() -> void:
	if AudioManager:
		AudioManager.set_master_volume(_master_slider.value)
		AudioManager.set_music_volume(_music_slider.value)
		AudioManager.set_sfx_volume(_sfx_slider.value)
		AudioManager.set_ambient_volume(_master_slider.value * 0.75)

	if _fullscreen_check.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	if _vsync_check.button_pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	var res_idx: int = _resolution_btn.selected
	var resolutions := [Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160), Vector2i(1280, 720)]
	if res_idx >= 0 and res_idx < resolutions.size():
		var target_res: Vector2i = resolutions[res_idx]
		if not _fullscreen_check.button_pressed:
			DisplayServer.window_set_size(target_res)

	if AudioManager:
		AudioManager.play_sfx("ui_click")


func _on_close() -> void:
	UIManager.close_window(self)
