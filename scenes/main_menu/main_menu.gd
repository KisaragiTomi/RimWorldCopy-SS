extends Control

const BG_TEXTURES := [
	"res://assets/textures/ui/MenuBG_Royalty.png",
	"res://assets/textures/ui/MenuBG_Biotech.png",
	"res://assets/textures/ui/MenuBG_Ideology.png",
	"res://assets/textures/ui/MenuBG_Anomaly.png",
	"res://assets/textures/ui/MenuBG_Odyssey.png",
]

const DLC_ICON_PATHS := {
	"Royalty": "res://assets/textures/ui/ExpansionIcon_Royalty.png",
	"Ideology": "res://assets/textures/ui/ExpansionIcon_Ideology.png",
	"Biotech": "res://assets/textures/ui/ExpansionIcon_Biotech.png",
	"Anomaly": "res://assets/textures/ui/ExpansionIcon_Anomaly.png",
	"Odyssey": "res://assets/textures/ui/ExpansionIcon_Odyssey.png",
}

var _bg_texture: TextureRect
var _btn_column: VBoxContainer
var _options_dialog: Control
var _simple_modals: Dictionary = {}


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	_add_background()

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var top_spacer := Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_spacer.size_flags_stretch_ratio = 0.35
	root.add_child(top_spacer)

	_add_title_section(root)

	var mid_spacer := Control.new()
	mid_spacer.custom_minimum_size.y = 50
	root.add_child(mid_spacer)

	_add_menu_buttons(root)

	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_spacer.size_flags_stretch_ratio = 0.5
	root.add_child(bottom_spacer)

	_add_bottom_bar(root)


func _add_background() -> void:
	_bg_texture = TextureRect.new()
	_bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_texture.z_index = -1
	add_child(_bg_texture)

	var chosen: String = BG_TEXTURES[randi() % BG_TEXTURES.size()]
	if ResourceLoader.exists(chosen):
		_bg_texture.texture = load(chosen)
	else:
		_bg_texture.self_modulate = Color(0.08, 0.07, 0.06, 1.0)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.45)
	add_child(overlay)

	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.set_script(preload("res://scenes/main_menu/vignette.gd"))
	add_child(vignette)


func _add_title_section(parent: Control) -> void:
	var title_container := VBoxContainer.new()
	title_container.alignment = BoxContainer.ALIGNMENT_CENTER
	title_container.add_theme_constant_override("separation", 8)
	parent.add_child(title_container)

	var title := Label.new()
	title.text = "RimWorld"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title_container.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "A Sci-Fi Colony Simulator"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.78, 0.7, 0.9))
	title_container.add_child(subtitle)


func _add_menu_buttons(parent: Control) -> void:
	var center_box := CenterContainer.new()
	parent.add_child(center_box)

	_btn_column = VBoxContainer.new()
	_btn_column.add_theme_constant_override("separation", 6)
	center_box.add_child(_btn_column)

	var buttons: Array[Array] = [
		["New Colony", _on_new_colony],
		["Load Game", _on_load_game],
		["Options", _on_options],
		["Mods", _on_mods],
		["Credits", _on_credits],
		["Quit to OS", _on_quit],
	]

	for i in buttons.size():
		var bdata: Array = buttons[i]
		var btn := Button.new()
		btn.text = bdata[0]
		btn.custom_minimum_size = Vector2(300, 44)
		btn.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
		btn.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		btn.add_theme_color_override("font_hover_color", RWTheme.TEXT_YELLOW)
		btn.add_theme_stylebox_override("normal", _make_menu_button_style(false))
		btn.add_theme_stylebox_override("hover", _make_menu_button_style(true))
		btn.add_theme_stylebox_override("pressed", RWTheme.make_button_pressed())
		btn.pressed.connect(bdata[1])
		btn.modulate.a = 0.0
		_btn_column.add_child(btn)

		var tween := create_tween()
		tween.tween_property(btn, "modulate:a", 1.0, 0.3).set_delay(0.1 * i).set_ease(Tween.EASE_OUT)


func _make_menu_button_style(hover: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if hover:
		sb.bg_color = Color(0.35, 0.33, 0.28, 0.85)
		sb.border_color = RWTheme.BORDER_HIGHLIGHT
	else:
		sb.bg_color = Color(0.22, 0.21, 0.19, 0.8)
		sb.border_color = Color(0.45, 0.42, 0.35, 0.6)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.content_margin_left = 20
	sb.content_margin_top = 8
	sb.content_margin_right = 20
	sb.content_margin_bottom = 8
	return sb


func _add_bottom_bar(parent: Control) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	bar.custom_minimum_size.y = 56
	parent.add_child(bar)

	var left_margin := Control.new()
	left_margin.custom_minimum_size.x = 20
	bar.add_child(left_margin)

	var version := Label.new()
	version.text = "Version 1.6.4633 rev1260"
	version.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
	version.add_theme_color_override("font_color", Color(0.5, 0.48, 0.4, 0.7))
	bar.add_child(version)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	_add_dlc_icons(bar)

	var right_margin := Control.new()
	right_margin.custom_minimum_size.x = 20
	bar.add_child(right_margin)


func _add_dlc_icons(parent: Control) -> void:
	for dlc_name in DLC_ICON_PATHS:
		var icon_path: String = DLC_ICON_PATHS[dlc_name]
		var dlc_btn := Button.new()
		dlc_btn.tooltip_text = dlc_name
		dlc_btn.custom_minimum_size = Vector2(40, 40)

		if ResourceLoader.exists(icon_path):
			dlc_btn.icon = load(icon_path)
			dlc_btn.expand_icon = true
			dlc_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		else:
			dlc_btn.text = dlc_name[0]
			dlc_btn.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
			dlc_btn.add_theme_color_override("font_color", Color(0.85, 0.78, 0.55, 1.0))

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.14, 0.12, 0.5)
		style.border_color = Color(0.5, 0.45, 0.35, 0.4)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		dlc_btn.add_theme_stylebox_override("normal", style)
		var hover_style: StyleBoxFlat = style.duplicate()
		hover_style.border_color = RWTheme.BORDER_HIGHLIGHT
		hover_style.bg_color = Color(0.25, 0.23, 0.18, 0.7)
		dlc_btn.add_theme_stylebox_override("hover", hover_style)
		parent.add_child(dlc_btn)


func _on_new_colony() -> void:
	var main_node := get_tree().root.get_node("Main")
	if main_node and main_node.has_method("switch_to_game"):
		main_node.switch_to_game()


func _on_load_game() -> void:
	_toggle_simple_modal(
		"load",
		func() -> Control:
			return SimpleMessageModal.create(
				"Load Game",
				"No save files in this UI mock. Wire your save/load layer here or load a .rwsave resource when you add persistence."
			)
	)


func _on_options() -> void:
	if _options_dialog and is_instance_valid(_options_dialog):
		UIManager.close_window(_options_dialog)
		_options_dialog = null
		return

	_options_dialog = preload("res://scenes/main_menu/options_dialog.tscn").instantiate()
	UIManager.open_window(_options_dialog)


func _on_mods() -> void:
	_toggle_simple_modal(
		"mods",
		func() -> Control:
			return SimpleMessageModal.create(
				"Mods",
				"Mod list and load order would appear here (Harmony, assemblies, defs). This clone only mirrors main-menu layout."
			)
	)


func _on_credits() -> void:
	_toggle_simple_modal(
		"credits",
		func() -> Control:
			return SimpleMessageModal.create(
				"Credits",
				"RimWorld is by Ludeon Studios. This project is a UI/layout study in Godot — not affiliated or a substitute for the game."
			)
	)


func _on_quit() -> void:
	get_tree().quit()


func _toggle_simple_modal(key: String, factory: Callable) -> void:
	var existing: Variant = _simple_modals.get(key, null)
	if existing is Control and is_instance_valid(existing):
		UIManager.close_window(existing)
		_simple_modals.erase(key)
		return

	_simple_modals.erase(key)
	var dlg: Control = factory.call() as Control
	_simple_modals[key] = dlg
	UIManager.open_window(dlg)
