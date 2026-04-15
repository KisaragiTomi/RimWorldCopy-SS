extends Control

signal tab_pressed(tab_key: String)

var _tab_buttons: Dictionary = {}
var _active_tab := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_tabs()


func sync_active_tab(tab_key: String) -> void:
	if _active_tab != "" and _active_tab in _tab_buttons:
		_apply_tab_style(_tab_buttons[_active_tab], false)
	_active_tab = tab_key
	if tab_key != "" and tab_key in _tab_buttons:
		_apply_tab_style(_tab_buttons[tab_key], true)


func _build_tabs() -> void:
	var bg := PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := RWTheme.make_stylebox_flat(Color(0.12, 0.115, 0.10, 0.94))
	style.content_margin_left = 2
	style.content_margin_top = 0
	style.content_margin_right = 2
	style.content_margin_bottom = 0
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bg.add_child(hbox)

	var hotkeys := [
		"F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10",
	]
	var tabs := DefData.get_main_tabs()
	for i in tabs.size():
		var tab: Dictionary = tabs[i]
		var btn := Button.new()
		btn.text = tab.name
		btn.custom_minimum_size = Vector2(88, 36)
		btn.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
		if i < hotkeys.size():
			btn.tooltip_text = "%s (%s)" % [tab.name, hotkeys[i]]
		_apply_tab_style(btn, false)
		btn.pressed.connect(_on_tab_pressed.bind(tab.key))
		hbox.add_child(btn)
		_tab_buttons[tab.key] = btn


func _apply_tab_style(btn: Button, active: bool) -> void:
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


func _on_tab_pressed(tab_key: String) -> void:
	GameState.tab_changed.emit(tab_key)
