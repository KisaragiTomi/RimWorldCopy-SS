extends Control

var _options_instance: Control


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_as_relative = false
	_build_ui()


func show_menu() -> void:
	visible = true
	move_to_front()


func hide_menu() -> void:
	visible = false
	if _options_instance and is_instance_valid(_options_instance):
		UIManager.close_window(_options_instance)
		_options_instance = null


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 280)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := RWTheme.make_stylebox_flat(
		Color(0.12, 0.12, 0.12, 0.98), RWTheme.BORDER_COLOR, 1
	)
	style.content_margin_left = 16
	style.content_margin_top = 14
	style.content_margin_right = 16
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Menu"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", RWTheme.FONT_LARGE)
	title.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	vbox.add_child(title)

	vbox.add_child(RWWidgets.create_separator())

	var buttons: Array[Array] = [
		["Resume", _on_resume],
		["Save game", _on_save_stub],
		["Load game", _on_load_stub],
		["Options", _on_options],
		["Quit to main menu", _on_quit_menu],
	]

	for bdata in buttons:
		var btn := RWWidgets.create_button(bdata[0], bdata[1])
		btn.custom_minimum_size.y = 36
		vbox.add_child(btn)


func _on_resume() -> void:
	hide_menu()
	GameState.tab_changed.emit("")


func _on_save_stub() -> void:
	var map: MapData = GameState.get_map()
	if map == null:
		_show_msg("Save Failed", "No active map to save.")
		return
	var save_name: String = "colony_%s" % Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var err: Error = SaveLoad.save_game(save_name, map)
	if err == OK:
		_show_msg("Game Saved", "Saved as: %s\nPawns: %d | Things: %d" % [
			save_name, PawnManager.pawns.size() if PawnManager else 0,
			ThingManager.things.size() if ThingManager else 0])
	else:
		_show_msg("Save Failed", "Error code: %d" % err)


func _on_load_stub() -> void:
	var saves: PackedStringArray = SaveLoad.list_saves()
	if saves.is_empty():
		_show_msg("No Saves", "No save files found.")
		return
	_show_load_dialog(saves)


func _show_msg(title: String, msg: String) -> void:
	var dlg: Control = SimpleMessageModal.create(title, msg)
	UIManager.open_window(dlg)


func _show_load_dialog(saves: PackedStringArray) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 300)
	var style := RWTheme.make_stylebox_flat(
		Color(0.12, 0.12, 0.12, 0.98), RWTheme.BORDER_COLOR, 1
	)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Load Game"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	title.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	vbox.add_child(title)

	vbox.add_child(RWWidgets.create_separator())

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 180
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for save_name: String in saves:
		var btn := RWWidgets.create_button(save_name, _make_load_callback(save_name, panel))
		btn.custom_minimum_size.y = 30
		list.add_child(btn)

	var cancel_btn := RWWidgets.create_button("Cancel", func(): UIManager.close_window(panel))
	cancel_btn.custom_minimum_size.y = 30
	vbox.add_child(cancel_btn)

	UIManager.open_window(panel)


func _make_load_callback(save_name: String, dialog: Control) -> Callable:
	return func():
		UIManager.close_window(dialog)
		_do_load(save_name)


func _do_load(save_name: String) -> void:
	var map: MapData = SaveLoad.load_map(save_name)
	if map == null:
		_show_msg("Load Failed", "Could not parse save: %s" % save_name)
		return
	GameState.active_map = map
	hide_menu()
	GameState.tab_changed.emit("")
	_show_msg("Game Loaded", "Loaded: %s\nMap: %dx%d" % [save_name, map.width, map.height])


func _on_options() -> void:
	if _options_instance and is_instance_valid(_options_instance):
		UIManager.close_window(_options_instance)
		_options_instance = null
		return
	_options_instance = preload("res://scenes/main_menu/options_dialog.tscn").instantiate()
	UIManager.open_window(_options_instance)


func _on_quit_menu() -> void:
	hide_menu()
	var main_node := get_tree().root.get_node_or_null("Main")
	if main_node and main_node.has_method("switch_to_main_menu"):
		main_node.switch_to_main_menu()
