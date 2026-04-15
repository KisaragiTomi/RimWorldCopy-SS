extends Control

var _info_panel: PanelContainer
var _tile_info_labels: Dictionary = {}
var _toolbar: HBoxContainer
var _map_viewport: Control
var _selected_tile: Vector2i = Vector2i(-1, -1)

const GRID_SIZE := 20
const CELL_SIZE := 36


func _ready() -> void:
	_build_ui()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.14, 0.18, 1.0))


func _build_ui() -> void:
	_build_toolbar()
	_build_map_area()
	_build_info_panel()
	_build_bottom_bar()


func _build_toolbar() -> void:
	var toolbar_bg := PanelContainer.new()
	toolbar_bg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toolbar_bg.offset_bottom = 40
	var style := RWTheme.make_stylebox_flat(Color(0.12, 0.12, 0.12, 0.92))
	style.content_margin_left = 8
	style.content_margin_top = 4
	style.content_margin_right = 8
	style.content_margin_bottom = 4
	toolbar_bg.add_theme_stylebox_override("panel", style)
	add_child(toolbar_bg)

	_toolbar = HBoxContainer.new()
	_toolbar.add_theme_constant_override("separation", 6)
	toolbar_bg.add_child(_toolbar)

	var title := Label.new()
	title.text = "World Map"
	title.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	title.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	_toolbar.add_child(title)

	_toolbar.add_child(RWWidgets.create_separator(true))

	var tools := ["Select Site", "Settle", "Form Caravan", "Back"]
	for tool_name in tools:
		var btn := RWWidgets.create_button(tool_name, Callable(), 100)
		if tool_name == "Back":
			btn.pressed.connect(_on_back)
		_toolbar.add_child(btn)


func _build_map_area() -> void:
	_map_viewport = Control.new()
	_map_viewport.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_viewport.offset_top = 44
	_map_viewport.offset_right = -240
	_map_viewport.offset_bottom = -36
	_map_viewport.set_script(preload("res://scenes/world_map/world_map_canvas.gd"))
	add_child(_map_viewport)

	if _map_viewport.has_signal("tile_clicked"):
		_map_viewport.tile_clicked.connect(_on_tile_clicked)


func _build_info_panel() -> void:
	_info_panel = PanelContainer.new()
	_info_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_info_panel.offset_left = -240
	_info_panel.offset_top = 44
	_info_panel.offset_bottom = -36
	var style := RWTheme.make_stylebox_flat(
		Color(0.14, 0.14, 0.14, 0.95), RWTheme.BORDER_COLOR, 1
	)
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	_info_panel.add_theme_stylebox_override("panel", style)
	add_child(_info_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_info_panel.add_child(vbox)

	var panel_title := Label.new()
	panel_title.text = "Tile Info"
	panel_title.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	panel_title.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	vbox.add_child(panel_title)

	vbox.add_child(RWWidgets.create_separator())

	var info_entries := {
		"biome": ["Biome", "--"],
		"terrain": ["Terrain", "--"],
		"temperature": ["Avg. Temperature", "--"],
		"rainfall": ["Rainfall", "--"],
		"growing": ["Growing Period", "--"],
		"stones": ["Stone Types", "--"],
		"elevation": ["Elevation", "--"],
		"features": ["Features", "--"],
	}

	for key in info_entries:
		var entry: Array = info_entries[key]
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 1)
		vbox.add_child(row)

		var key_lbl := Label.new()
		key_lbl.text = entry[0]
		key_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		key_lbl.add_theme_color_override("font_color", RWTheme.TEXT_DARK)
		row.add_child(key_lbl)

		var val_lbl := Label.new()
		val_lbl.text = entry[1]
		val_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
		val_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		row.add_child(val_lbl)
		_tile_info_labels[key] = val_lbl


func _build_bottom_bar() -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -36
	var style := RWTheme.make_stylebox_flat(Color(0.12, 0.12, 0.12, 0.92))
	style.content_margin_left = 10
	style.content_margin_top = 4
	style.content_margin_right = 10
	style.content_margin_bottom = 4
	bar.add_theme_stylebox_override("panel", style)
	add_child(bar)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	bar.add_child(hbox)

	var coord_lbl := Label.new()
	coord_lbl.name = "CoordLabel"
	coord_lbl.text = "Click a tile to see info"
	coord_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
	coord_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
	hbox.add_child(coord_lbl)

	var seed_lbl := Label.new()
	seed_lbl.text = "Seed: rimworld42"
	seed_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
	seed_lbl.add_theme_color_override("font_color", RWTheme.TEXT_DARK)
	hbox.add_child(seed_lbl)


func _on_tile_clicked(tile_pos: Vector2i, tile_data: Dictionary) -> void:
	_selected_tile = tile_pos
	_update_info_panel(tile_pos, tile_data)

	var bar := get_node_or_null("PanelContainer")
	if bar:
		var coord_lbl := bar.get_node_or_null("HBoxContainer/CoordLabel")
		if coord_lbl:
			coord_lbl.text = "Coordinates: (%d, %d)" % [tile_pos.x, tile_pos.y]


func _update_info_panel(tile_pos: Vector2i, tile_data: Dictionary) -> void:
	if tile_data.is_empty():
		if _tile_info_labels.has("biome"):
			_tile_info_labels["biome"].text = "Ocean"
		return

	if _tile_info_labels.has("biome"):
		_tile_info_labels["biome"].text = str(tile_data.get("biome", "Unknown"))
	if _tile_info_labels.has("terrain"):
		_tile_info_labels["terrain"].text = str(tile_data.get("hilliness", "Flat"))
	if _tile_info_labels.has("temperature"):
		var temp: float = tile_data.get("temperature", 0.0)
		_tile_info_labels["temperature"].text = "%.0f\u00b0C" % temp
	if _tile_info_labels.has("rainfall"):
		var rain: float = tile_data.get("rainfall", 0.0)
		_tile_info_labels["rainfall"].text = "%.0f mm" % rain
	if _tile_info_labels.has("growing"):
		var temp: float = tile_data.get("temperature", 0.0)
		var days: int = 0
		if temp > 0:
			days = clampi(int(temp * 2.5), 0, 60)
		_tile_info_labels["growing"].text = "%d/60 days" % days
	if _tile_info_labels.has("elevation"):
		var elev: float = tile_data.get("elevation", 0.0)
		_tile_info_labels["elevation"].text = "%.0f m" % (elev * 500.0)
	if _tile_info_labels.has("features"):
		var features: PackedStringArray = PackedStringArray()
		var settlement: String = tile_data.get("settlement", "")
		if not settlement.is_empty():
			features.append("Settlement: " + settlement)
		var faction: String = tile_data.get("faction", "")
		if not faction.is_empty():
			features.append("Faction: " + faction)
		_tile_info_labels["features"].text = ", ".join(features) if not features.is_empty() else "--"
	if _tile_info_labels.has("stones"):
		_tile_info_labels["stones"].text = "Granite, Limestone"


func _on_back() -> void:
	var main_node := get_tree().root.get_node("Main")
	if main_node and main_node.has_method("switch_to_game"):
		main_node.switch_to_game()
