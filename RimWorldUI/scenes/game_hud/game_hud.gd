extends Control

var _mouseover_panel: Control
var _mo_terrain_lbl: Label
var _mo_value_labels: Dictionary = {}
var _mo_things_lbl: Label
var _selected_colonist: Dictionary = {}
var _active_tab := ""
var _map_viewport: Node
var _minimap: TextureRect
var _minimap_image: Image
var _minimap_texture: ImageTexture
const MINIMAP_SIZE := 160

var _letter_stack: VBoxContainer
var _letter_detail_popup: PanelContainer
var _active_letters: Array[Dictionary] = []
const MAX_LETTERS := 8

var _trade_dialog: PanelContainer
var _trade_goods_vbox: VBoxContainer
var _trade_silver_lbl: Label
var _trade_title_lbl: Label
var _toast_container: VBoxContainer

var _craft_dialog: PanelContainer
var _craft_queue_vbox: VBoxContainer
var _craft_recipe_vbox: VBoxContainer
var _craft_bench_label: Label

var _drug_policy_dialog: PanelContainer
var _drug_policy_vbox: VBoxContainer
var _drug_policy_pawn_id: int = -1

var _caravan_dialog: PanelContainer
var _caravan_members_vbox: VBoxContainer
var _caravan_items_vbox: VBoxContainer
var _caravan_food_lbl: Label
var _caravan_selected_pawns: Array[int] = []
var _caravan_selected_items: Dictionary = {}

const LETTER_COLORS: Dictionary = {
	"positive": Color(0.2, 0.7, 0.3),
	"negative": Color(0.8, 0.2, 0.15),
	"neutral": Color(0.5, 0.5, 0.6),
	"threat": Color(0.9, 0.15, 0.1),
}

const INCIDENT_LETTER_CONFIG: Dictionary = {
	"WandererJoin": {"title": "Wanderer Joins", "type": "positive"},
	"ResourceDrop": {"title": "Cargo Pods", "type": "positive"},
	"ColdSnap": {"title": "Cold Snap", "type": "negative"},
	"HeatWave": {"title": "Heat Wave", "type": "negative"},
	"Disease": {"title": "Disease", "type": "threat"},
	"Eclipse": {"title": "Eclipse", "type": "neutral"},
	"Blight": {"title": "negative", "type": "negative"},
	"AnimalHerd": {"title": "Animal Herd", "type": "neutral"},
	"PsychicDrone": {"title": "Psychic Drone", "type": "threat"},
	"ManInBlack": {"title": "Man in Black", "type": "positive"},
	"Raid": {"title": "Raid!", "type": "threat"},
	"TraderArrived": {"title": "Trader Arrived", "type": "positive"},
}

@onready var _colonist_bar: Control = $ColonistBar
@onready var _resource_readout: Control = $ResourceReadout
@onready var _global_controls: Control = $GlobalControls
@onready var _alerts_panel: Control = $AlertsPanel
@onready var _bottom_tabs: Control = $BottomTabs
@onready var _architect_menu: Control = $ArchitectMenu
@onready var _work_restrict: Control = $WorkRestrictPanels
@onready var _inspect_panel: Control = $InspectPanel
@onready var _research_tree: Control = $ResearchTree
@onready var _misc_tabs: Control = $MiscTabPanels
@onready var _ingame_menu: Control = $IngameMenu


func _ready() -> void:
	_draw_game_viewport_bg()
	_build_mouseover_readout()
	_build_minimap()
	_build_letter_stack()
	_build_trade_dialog()
	_setup_zorder()
	_setup_mouse_filters()

	GameState.tab_changed.connect(_on_tab_changed)
	GameState.colonist_selected.connect(_on_colonist_selected)
	_inspect_panel.draft_toggled.connect(_on_draft_toggled)

	if IncidentManager:
		IncidentManager.incident_fired.connect(_on_incident_fired)
	if TradeManager:
		TradeManager.trader_arrived.connect(_on_trader_arrived)
		TradeManager.trader_left.connect(_on_trader_left)

	_hide_all_tab_panels()
	_inspect_panel.visible = false

	var notif := NotificationOverlay.new()
	add_child(notif)

	_build_toast_container()
	_build_craft_dialog()
	_build_caravan_dialog()
	_build_drug_policy_dialog()


func _setup_zorder() -> void:
	_resource_readout.z_index = 1
	_mouseover_panel.z_index = 1
	_architect_menu.z_index = 2
	_work_restrict.z_index = 2
	_misc_tabs.z_index = 2
	_research_tree.z_index = 3
	_inspect_panel.z_index = 4
	_colonist_bar.z_index = 5
	_global_controls.z_index = 5
	_alerts_panel.z_index = 5
	_bottom_tabs.z_index = 6
	_ingame_menu.z_index = 8


func _setup_mouse_filters() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_colonist_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_resource_readout.mouse_filter = Control.MOUSE_FILTER_STOP
	_global_controls.mouse_filter = Control.MOUSE_FILTER_STOP
	_alerts_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_bottom_tabs.mouse_filter = Control.MOUSE_FILTER_STOP
	_architect_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	_work_restrict.mouse_filter = Control.MOUSE_FILTER_STOP
	_inspect_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_research_tree.mouse_filter = Control.MOUSE_FILTER_STOP
	_misc_tabs.mouse_filter = Control.MOUSE_FILTER_STOP
	_ingame_menu.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_tab_changed(tab_key: String) -> void:
	if tab_key == "world":
		_open_world_map()
		return

	if tab_key == _active_tab and tab_key != "":
		if tab_key == "menu":
			_ingame_menu.hide_menu()
		_active_tab = ""
		_hide_all_tab_panels()
		_bottom_tabs.sync_active_tab("")
		_update_mouseover_visibility()
		return

	_active_tab = tab_key
	_hide_all_tab_panels()
	_bottom_tabs.sync_active_tab(tab_key)

	match tab_key:
		"architect":
			_architect_menu.show_panel()
		"work":
			_work_restrict.show_work()
		"restrict":
			_work_restrict.show_restrict()
		"research":
			_research_tree.show_panel()
		"assign":
			_misc_tabs.show_assign()
		"animals":
			_misc_tabs.show_animals()
		"wildlife":
			_misc_tabs.show_wildlife()
		"history":
			_misc_tabs.show_history()
		"factions":
			_misc_tabs.show_factions()
		"prisoners":
			_misc_tabs.show_prisoners()
		"overview":
			_misc_tabs.show_overview()
		"alerts":
			_misc_tabs.show_alerts()
		"menu":
			_ingame_menu.show_menu()

	if tab_key in ["research", "assign", "animals", "wildlife", "history", "factions", "prisoners", "overview", "alerts", "menu"]:
		_inspect_panel.visible = false

	_update_mouseover_visibility()


func _on_colonist_selected(colonist: Dictionary) -> void:
	if colonist.is_empty():
		_inspect_panel.visible = false
		_selected_colonist = {}
		_colonist_bar.clear_selection()
		_update_mouseover_visibility()
		return

	if _selected_colonist.get("name", "") == colonist.get("name", ""):
		_inspect_panel.visible = false
		_selected_colonist = {}
		_colonist_bar.clear_selection()
		_update_mouseover_visibility()
		return

	_selected_colonist = colonist
	_inspect_panel.show_colonist(colonist)
	_colonist_bar.highlight_colonist(str(colonist.get("name", "")))

	var pid: int = colonist.get("pawn_id", -1)
	if pid >= 0:
		focus_camera_on_pawn(pid)

	if _active_tab in [
		"architect", "work", "restrict",
		"research", "assign", "animals", "wildlife", "history", "factions", "prisoners", "overview", "alerts", "menu",
	]:
		_active_tab = ""
		_hide_all_tab_panels()
		_bottom_tabs.sync_active_tab("")

	_update_mouseover_visibility()


func _hide_all_tab_panels() -> void:
	_architect_menu.hide_panel()
	_work_restrict.hide_all()
	_research_tree.hide_panel()
	_misc_tabs.hide_all()
	_ingame_menu.hide_menu()


func _update_mouseover_visibility() -> void:
	var any_panel_open := _active_tab in ["architect", "work", "restrict", "assign", "animals", "wildlife", "history", "factions", "prisoners", "overview", "alerts"]
	_mouseover_panel.visible = not any_panel_open and not _inspect_panel.visible


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _context_popup and is_instance_valid(_context_popup):
			var ctx_rect := _context_popup.get_global_rect()
			if not ctx_rect.has_point(event.global_position):
				_context_popup.queue_free()
				_context_popup = null
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _inspect_panel.visible:
				var ip_rect := _inspect_panel.get_global_rect()
				if not ip_rect.has_point(event.global_position):
					var bar_rect := _colonist_bar.get_global_rect()
					if not bar_rect.has_point(event.global_position):
						GameState.colonist_selected.emit({})


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				if GameState.time_speed == 0:
					GameState.set_time_speed(1)
				else:
					GameState.set_time_speed(0)
			KEY_1:
				GameState.set_time_speed(1)
			KEY_2:
				GameState.set_time_speed(2)
			KEY_3:
				GameState.set_time_speed(3)
			KEY_ESCAPE:
				if _letter_detail_popup and is_instance_valid(_letter_detail_popup):
					_dismiss_letter_detail()
				elif _drug_policy_dialog.visible:
					_close_drug_policy()
				elif _caravan_dialog.visible:
					_close_caravan_dialog()
				elif _craft_dialog.visible:
					_close_craft_dialog()
				elif _trade_dialog.visible:
					_close_trade_dialog()
				elif UIManager.has_open_windows():
					var top := UIManager.get_top_window()
					if top:
						UIManager.close_window(top)
				elif _ingame_menu.visible:
					_ingame_menu.hide_menu()
					_active_tab = ""
					_bottom_tabs.sync_active_tab("")
					_update_mouseover_visibility()
				elif _inspect_panel.visible:
					GameState.colonist_selected.emit({})
				elif _active_tab != "":
					GameState.tab_changed.emit("")
					_update_mouseover_visibility()
			KEY_TAB:
				if _trade_dialog.visible:
					_close_trade_dialog()
				elif TradeManager and TradeManager.has_method("get_trader_goods"):
					var goods: Array[Dictionary] = TradeManager.get_trader_goods()
					if not goods.is_empty():
						_open_trade_dialog("Trader")
			KEY_F1:
				GameState.tab_changed.emit("architect")
			KEY_F2:
				GameState.tab_changed.emit("work")
			KEY_F3:
				GameState.tab_changed.emit("restrict")
			KEY_F4:
				GameState.tab_changed.emit("assign")
			KEY_F5:
				GameState.tab_changed.emit("animals")
			KEY_F6:
				GameState.tab_changed.emit("wildlife")
			KEY_F7:
				GameState.tab_changed.emit("research")
			KEY_F8:
				GameState.tab_changed.emit("world")
			KEY_F9:
				GameState.tab_changed.emit("history")
			KEY_F10:
				GameState.tab_changed.emit("menu")
			KEY_P:
				if _map_viewport and _map_viewport.has_method("toggle_power_overlay"):
					_map_viewport.toggle_power_overlay()
					show_toast("Power overlay " + ("ON" if _map_viewport._power_overlay_visible else "OFF"), 1.5)
			KEY_B:
				if _map_viewport and _map_viewport.has_method("toggle_beauty_overlay"):
					_map_viewport.toggle_beauty_overlay()
					show_toast("Beauty overlay " + ("ON" if _map_viewport._beauty_overlay_visible else "OFF"), 1.5)
			KEY_T:
				if _map_viewport and _map_viewport.has_method("toggle_temp_overlay"):
					_map_viewport.toggle_temp_overlay()
					show_toast("Temp overlay " + ("ON" if _map_viewport._temp_overlay_visible else "OFF"), 1.5)


func _open_world_map() -> void:
	_active_tab = ""
	_hide_all_tab_panels()
	_bottom_tabs.sync_active_tab("")
	var main_node := get_tree().root.get_node_or_null("Main")
	if main_node and main_node.has_method("switch_to_world_map"):
		main_node.switch_to_world_map()


func _draw_game_viewport_bg() -> void:
	var container := SubViewportContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.z_index = -10
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(container)
	move_child(container, 0)

	var sub_vp := SubViewport.new()
	sub_vp.transparent_bg = false
	sub_vp.handle_input_locally = false
	container.add_child(sub_vp)

	var map_scene: PackedScene = preload("res://scenes/game_map/map_viewport.tscn")
	_map_viewport = map_scene.instantiate()
	sub_vp.add_child(_map_viewport)

	if _architect_menu and _map_viewport:
		_architect_menu.designator_selected.connect(_on_designator_selected)
		_architect_menu.designator_cleared.connect(_on_designator_cleared)
	if _map_viewport and _map_viewport.has_signal("pawn_selected"):
		_map_viewport.pawn_selected.connect(_on_map_pawn_selected)
	if _map_viewport and _map_viewport.has_signal("context_menu_requested"):
		_map_viewport.context_menu_requested.connect(_on_context_menu_requested)


func _build_mouseover_readout() -> void:
	_mouseover_panel = PanelContainer.new()
	_mouseover_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_mouseover_panel.offset_left = 0
	_mouseover_panel.offset_top = -180
	_mouseover_panel.offset_right = 240
	_mouseover_panel.offset_bottom = -44
	_mouseover_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := RWTheme.make_stylebox_flat(
		Color(0.13, 0.125, 0.11, 0.94), RWTheme.BORDER_COLOR, 1
	)
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
	_mouseover_panel.add_theme_stylebox_override("panel", style)
	add_child(_mouseover_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	_mouseover_panel.add_child(vbox)

	_mo_terrain_lbl = Label.new()
	_mo_terrain_lbl.text = "Soil"
	_mo_terrain_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	_mo_terrain_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	vbox.add_child(_mo_terrain_lbl)

	var fields: Array[String] = ["Temperature", "Beauty", "Cleanliness", "Fertility", "Light", "Roof", "Zone"]
	for field_name: String in fields:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		vbox.add_child(row)
		var key_lbl := Label.new()
		key_lbl.text = field_name + ":"
		key_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		key_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		key_lbl.custom_minimum_size.x = 100
		row.add_child(key_lbl)
		var val_lbl := Label.new()
		val_lbl.text = "--"
		val_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		val_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		row.add_child(val_lbl)
		_mo_value_labels[field_name] = val_lbl

	_mo_things_lbl = Label.new()
	_mo_things_lbl.text = ""
	_mo_things_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
	_mo_things_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	_mo_things_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_mo_things_lbl.custom_minimum_size.x = 210
	vbox.add_child(_mo_things_lbl)


func _build_minimap() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left = -(MINIMAP_SIZE + 12)
	panel.offset_top = -(MINIMAP_SIZE + 56)
	panel.offset_right = -4
	panel.offset_bottom = -48
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.z_index = 3
	var style := RWTheme.make_stylebox_flat(
		Color(0.08, 0.08, 0.06, 0.92), RWTheme.BORDER_COLOR, 1
	)
	style.set_content_margin_all(2)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	_minimap = TextureRect.new()
	_minimap.custom_minimum_size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	_minimap.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	panel.add_child(_minimap)

	_minimap_image = Image.create(MINIMAP_SIZE, MINIMAP_SIZE, false, Image.FORMAT_RGBA8)
	_minimap_image.fill(Color(0.1, 0.1, 0.1))
	_minimap_texture = ImageTexture.create_from_image(_minimap_image)
	_minimap.texture = _minimap_texture


func _update_minimap() -> void:
	var map: MapData = GameState.get_map() if GameState else null
	if map == null or _minimap_image == null:
		return

	var scale_x: float = float(map.width) / float(MINIMAP_SIZE)
	var scale_y: float = float(map.height) / float(MINIMAP_SIZE)

	for py: int in MINIMAP_SIZE:
		for px: int in MINIMAP_SIZE:
			var mx: int = int(px * scale_x)
			var my: int = int(py * scale_y)
			var cell := map.get_cell(mx, my)
			if cell == null:
				_minimap_image.set_pixel(px, py, Color(0.05, 0.05, 0.05))
				continue
			if cell.is_mountain:
				_minimap_image.set_pixel(px, py, Color(0.35, 0.3, 0.25))
			elif cell.terrain_def in ["Water", "DeepWater", "ShallowWater"]:
				_minimap_image.set_pixel(px, py, Color(0.2, 0.35, 0.55))
			elif cell.terrain_def == "Sand":
				_minimap_image.set_pixel(px, py, Color(0.65, 0.6, 0.4))
			elif cell.terrain_def in ["Marsh", "MarshyTerrain"]:
				_minimap_image.set_pixel(px, py, Color(0.3, 0.4, 0.25))
			elif not cell.things.is_empty():
				_minimap_image.set_pixel(px, py, Color(0.5, 0.45, 0.4))
			elif not cell.zone.is_empty():
				match cell.zone:
					"stockpile":
						_minimap_image.set_pixel(px, py, Color(0.45, 0.35, 0.2))
					"growing":
						_minimap_image.set_pixel(px, py, Color(0.35, 0.5, 0.2))
					_:
						_minimap_image.set_pixel(px, py, Color(0.3, 0.3, 0.35))
			else:
				_minimap_image.set_pixel(px, py, cell.get_color().darkened(0.3))

	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.dead:
				continue
			var px_i: int = clampi(int(p.grid_pos.x / scale_x), 0, MINIMAP_SIZE - 1)
			var py_i: int = clampi(int(p.grid_pos.y / scale_y), 0, MINIMAP_SIZE - 1)
			var col := Color(0.2, 0.8, 0.2) if not p.drafted else Color(0.9, 0.2, 0.2)
			_minimap_image.set_pixel(px_i, py_i, col)
			if px_i + 1 < MINIMAP_SIZE:
				_minimap_image.set_pixel(px_i + 1, py_i, col)
			if py_i + 1 < MINIMAP_SIZE:
				_minimap_image.set_pixel(px_i, py_i + 1, col)

	_minimap_texture.update(_minimap_image)


func _build_letter_stack() -> void:
	_letter_stack = VBoxContainer.new()
	_letter_stack.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_letter_stack.offset_left = -46
	_letter_stack.offset_top = 60
	_letter_stack.offset_right = -4
	_letter_stack.offset_bottom = 400
	_letter_stack.add_theme_constant_override("separation", 4)
	_letter_stack.z_index = 7
	add_child(_letter_stack)


func _add_letter(incident_name: String, data: Dictionary) -> void:
	var config: Dictionary = INCIDENT_LETTER_CONFIG.get(incident_name, {})
	var title: String = config.get("title", incident_name)
	var letter_type: String = config.get("type", "neutral")
	var color: Color = LETTER_COLORS.get(letter_type, LETTER_COLORS["neutral"])

	var body_text := _build_letter_body(incident_name, data)

	var letter_data := {
		"name": incident_name, "title": title, "type": letter_type,
		"body": body_text, "data": data, "timestamp": Time.get_ticks_msec(),
	}
	_active_letters.append(letter_data)
	if _active_letters.size() > MAX_LETTERS:
		_active_letters.pop_front()

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(38, 38)
	btn.text = title.left(1).to_upper()
	btn.tooltip_text = title
	btn.add_theme_font_size_override("font_size", 16)
	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = color
	normal_sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", normal_sb)
	var hover_sb := StyleBoxFlat.new()
	hover_sb.bg_color = color.lightened(0.25)
	hover_sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.pressed.connect(_on_letter_clicked.bind(letter_data, btn))
	_letter_stack.add_child(btn)

	while _letter_stack.get_child_count() > MAX_LETTERS:
		var old: Node = _letter_stack.get_child(0)
		_letter_stack.remove_child(old)
		old.queue_free()

	if AudioManager:
		match letter_type:
			"positive":
				AudioManager.play_sfx("message_arrive")
			"threat":
				AudioManager.play_sfx("threat_big")
			_:
				AudioManager.play_sfx("ui_open")


func _build_letter_body(incident_name: String, data: Dictionary) -> String:
	match incident_name:
		"WandererJoin":
			var pname: String = data.get("pawn_name", "Someone")
			return "%s has decided to join the colony. They wandered in from the edge of the map." % pname
		"ResourceDrop":
			var res: String = data.get("resource", "resources")
			var amt: int = data.get("amount", 0)
			return "A cargo pod has crashed nearby, containing %d %s." % [amt, res]
		"ColdSnap":
			var shift: float = data.get("shift", 0.0)
			return "A cold snap has hit the area. Temperature dropped by %.0f\u00b0C." % absf(shift)
		"HeatWave":
			var shift: float = data.get("shift", 0.0)
			return "A heat wave has arrived. Temperature rose by %.0f\u00b0C." % absf(shift)
		"Disease":
			var pname: String = data.get("pawn", "A colonist")
			var disease: String = data.get("disease", "an illness")
			return "%s has been afflicted with %s. Medical attention is needed." % [pname, disease]
		"Eclipse":
			return "A solar eclipse has begun. Darkness will cover the map for a while."
		"Blight":
			return "A blight has struck your crops! Affected plants will wither unless removed."
		"AnimalHerd":
			return "A herd of animals has arrived on the map."
		"PsychicDrone":
			return "A psychic drone is affecting your colonists, lowering their mood."
		"ManInBlack":
			var pname: String = data.get("pawn_name", "A stranger")
			return "%s, a mysterious figure, has arrived to help your colony in its darkest hour." % pname
		"Raid":
			return "Enemy raiders are attacking! Prepare your defenses!"
	return "An event has occurred: %s" % incident_name


func _on_letter_clicked(letter_data: Dictionary, btn: Button) -> void:
	_show_letter_detail(letter_data)
	btn.queue_free()
	_active_letters.erase(letter_data)


func _show_letter_detail(letter_data: Dictionary) -> void:
	if _letter_detail_popup and is_instance_valid(_letter_detail_popup):
		_letter_detail_popup.queue_free()

	_letter_detail_popup = PanelContainer.new()
	_letter_detail_popup.z_index = 12
	var letter_type: String = letter_data.get("type", "neutral")
	var border_color: Color = LETTER_COLORS.get(letter_type, LETTER_COLORS["neutral"])
	var style := RWTheme.make_stylebox_flat(
		Color(0.12, 0.11, 0.1, 0.97), border_color, 2
	)
	style.content_margin_left = 16
	style.content_margin_top = 12
	style.content_margin_right = 16
	style.content_margin_bottom = 12
	_letter_detail_popup.add_theme_stylebox_override("panel", style)
	add_child(_letter_detail_popup)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_letter_detail_popup.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = letter_data.get("title", "Event")
	title_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	title_lbl.add_theme_color_override("font_color", border_color.lightened(0.3))
	vbox.add_child(title_lbl)

	vbox.add_child(RWWidgets.create_separator())

	var body_lbl := Label.new()
	body_lbl.text = letter_data.get("body", "")
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.custom_minimum_size.x = 320
	body_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	body_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	vbox.add_child(body_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(btn_row)

	var ok_btn := RWWidgets.create_button("OK", Callable(), 80)
	ok_btn.pressed.connect(_dismiss_letter_detail)
	btn_row.add_child(ok_btn)

	var vp_size := get_viewport_rect().size
	_letter_detail_popup.position = Vector2(
		(vp_size.x - 360) / 2.0, (vp_size.y - 200) / 2.0
	)


func _dismiss_letter_detail() -> void:
	if _letter_detail_popup and is_instance_valid(_letter_detail_popup):
		_letter_detail_popup.queue_free()
		_letter_detail_popup = null


func _on_incident_fired(incident_name: String, data: Dictionary) -> void:
	_add_letter(incident_name, data)


func _build_trade_dialog() -> void:
	_trade_dialog = PanelContainer.new()
	_trade_dialog.z_index = 11
	_trade_dialog.visible = false
	var style := RWTheme.make_stylebox_flat(
		Color(0.11, 0.105, 0.09, 0.97), Color(0.6, 0.5, 0.2), 2
	)
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	_trade_dialog.add_theme_stylebox_override("panel", style)
	add_child(_trade_dialog)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	outer.custom_minimum_size = Vector2(500, 360)
	_trade_dialog.add_child(outer)

	_trade_title_lbl = Label.new()
	_trade_title_lbl.text = "Trade"
	_trade_title_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	_trade_title_lbl.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	outer.add_child(_trade_title_lbl)

	_trade_silver_lbl = Label.new()
	_trade_silver_lbl.text = "Silver: 0"
	_trade_silver_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	_trade_silver_lbl.add_theme_color_override("font_color", Color(0.85, 0.8, 0.5))
	outer.add_child(_trade_silver_lbl)

	outer.add_child(RWWidgets.create_separator())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	_trade_goods_vbox = VBoxContainer.new()
	_trade_goods_vbox.add_theme_constant_override("separation", 3)
	scroll.add_child(_trade_goods_vbox)

	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_END
	outer.add_child(close_row)
	var close_btn := RWWidgets.create_button("Close", Callable(), 80)
	close_btn.pressed.connect(_close_trade_dialog)
	close_row.add_child(close_btn)

	var vp_size := get_viewport_rect().size
	_trade_dialog.position = Vector2(
		maxf((vp_size.x - 520) / 2.0, 40),
		maxf((vp_size.y - 400) / 2.0, 40)
	)


func _on_trader_arrived(trader_name: String, _goods: Array) -> void:
	_add_letter("TraderArrived", {"trader_name": trader_name})
	show_toast("%s has arrived. Press T to trade." % trader_name, 5.0, Color(0.9, 0.8, 0.3))


func _on_trader_left(_trader_name: String) -> void:
	_close_trade_dialog()


func _open_trade_dialog(trader_name: String) -> void:
	if not TradeManager:
		return
	_trade_title_lbl.text = "Trade — %s" % trader_name
	_trade_silver_lbl.text = "Colony Silver: %d" % TradeManager.get_trade_balance()
	_refresh_trade_goods()
	_trade_dialog.visible = true
	var vp_size := get_viewport_rect().size
	_trade_dialog.position = Vector2(
		maxf((vp_size.x - 520) / 2.0, 40),
		maxf((vp_size.y - 400) / 2.0, 40)
	)


func _refresh_trade_goods() -> void:
	for c: Node in _trade_goods_vbox.get_children():
		c.queue_free()

	if not TradeManager:
		return

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	_trade_goods_vbox.add_child(header)
	for h_text: String in ["Item", "Price", "Qty", ""]:
		var lbl := Label.new()
		lbl.text = h_text
		lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		if h_text == "Item":
			lbl.custom_minimum_size.x = 160
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		elif h_text == "":
			lbl.custom_minimum_size.x = 60
		else:
			lbl.custom_minimum_size.x = 60
		header.add_child(lbl)

	var goods: Array[Dictionary] = TradeManager.get_trader_goods()
	for good: Dictionary in goods:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		_trade_goods_vbox.add_child(row)

		var name_lbl := Label.new()
		name_lbl.text = str(good.get("name", "?"))
		name_lbl.custom_minimum_size.x = 160
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		name_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		row.add_child(name_lbl)

		var price_lbl := Label.new()
		price_lbl.text = "%d$" % good.get("price", 0)
		price_lbl.custom_minimum_size.x = 60
		price_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		price_lbl.add_theme_color_override("font_color", Color(0.85, 0.8, 0.5))
		row.add_child(price_lbl)

		var qty_lbl := Label.new()
		qty_lbl.text = "x%d" % good.get("quantity", 0)
		qty_lbl.custom_minimum_size.x = 60
		qty_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		qty_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		row.add_child(qty_lbl)

		var buy_btn := Button.new()
		buy_btn.text = "Buy"
		buy_btn.custom_minimum_size = Vector2(56, 22)
		buy_btn.add_theme_font_size_override("font_size", 10)
		var item_name: String = str(good.get("name", ""))
		buy_btn.pressed.connect(_on_buy_pressed.bind(item_name))
		row.add_child(buy_btn)


func _on_buy_pressed(item_name: String) -> void:
	if not TradeManager:
		return
	var result: Dictionary = TradeManager.buy_item(item_name, 1)
	if result.get("success", false):
		_trade_silver_lbl.text = "Colony Silver: %d" % TradeManager.get_trade_balance()
		_refresh_trade_goods()
		if AudioManager:
			AudioManager.play_sfx("ui_click")
		var cost: int = result.get("cost", 0)
		show_toast("Bought %s for %d silver" % [item_name, cost])
		if ColonyLog:
			ColonyLog.add_entry("Trade", "Bought %s for %d silver" % [item_name, cost], "info")
	else:
		show_toast("Cannot afford %s" % item_name, 2.0, Color(0.9, 0.3, 0.3))


func _close_trade_dialog() -> void:
	_trade_dialog.visible = false


var _stockpile_popup: PanelContainer

func _show_stockpile_filter(pos: Vector2i) -> void:
	if _stockpile_popup and is_instance_valid(_stockpile_popup):
		_stockpile_popup.queue_free()

	_stockpile_popup = PanelContainer.new()
	_stockpile_popup.z_index = 11
	var style := RWTheme.make_stylebox_flat(
		Color(0.12, 0.11, 0.1, 0.97), Color(0.5, 0.4, 0.2), 2
	)
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	_stockpile_popup.add_theme_stylebox_override("panel", style)
	add_child(_stockpile_popup)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	outer.custom_minimum_size = Vector2(300, 280)
	_stockpile_popup.add_child(outer)

	var title := Label.new()
	title.text = "Stockpile Settings (%d, %d)" % [pos.x, pos.y]
	title.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	title.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	outer.add_child(title)

	outer.add_child(RWWidgets.create_separator())

	var priority_row := HBoxContainer.new()
	priority_row.add_theme_constant_override("separation", 6)
	outer.add_child(priority_row)
	var pri_lbl := Label.new()
	pri_lbl.text = "Priority:"
	pri_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	pri_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	priority_row.add_child(pri_lbl)
	var priorities := ["Low", "Normal", "Preferred", "Important", "Critical"]
	for pri_name: String in priorities:
		var btn := Button.new()
		btn.text = pri_name
		btn.custom_minimum_size = Vector2(60, 22)
		btn.add_theme_font_size_override("font_size", 10)
		btn.toggle_mode = true
		btn.button_pressed = (pri_name == "Normal")
		priority_row.add_child(btn)

	var filter_lbl := Label.new()
	filter_lbl.text = "Allowed items:"
	filter_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	filter_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	outer.add_child(filter_lbl)

	var categories := ["Raw Materials", "Manufactured", "Food", "Medicine", "Apparel", "Weapons", "Building Materials", "Chunks", "Corpses"]
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var cat_vbox := VBoxContainer.new()
	cat_vbox.add_theme_constant_override("separation", 3)
	scroll.add_child(cat_vbox)

	for cat: String in categories:
		var check := CheckBox.new()
		check.text = cat
		check.button_pressed = true
		check.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		check.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		cat_vbox.add_child(check)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	outer.add_child(btn_row)
	var all_btn := RWWidgets.create_button("All", Callable(), 60)
	all_btn.pressed.connect(func():
		for c: Node in cat_vbox.get_children():
			if c is CheckBox:
				(c as CheckBox).button_pressed = true
	)
	btn_row.add_child(all_btn)
	var none_btn := RWWidgets.create_button("None", Callable(), 60)
	none_btn.pressed.connect(func():
		for c: Node in cat_vbox.get_children():
			if c is CheckBox:
				(c as CheckBox).button_pressed = false
	)
	btn_row.add_child(none_btn)
	var close_btn := RWWidgets.create_button("OK", Callable(), 60)
	close_btn.pressed.connect(func():
		show_toast("Stockpile filter updated")
		if _stockpile_popup and is_instance_valid(_stockpile_popup):
			_stockpile_popup.queue_free()
			_stockpile_popup = null
	)
	btn_row.add_child(close_btn)

	var vp_size := get_viewport_rect().size
	_stockpile_popup.position = Vector2(
		maxf((vp_size.x - 320) / 2.0, 40),
		maxf((vp_size.y - 300) / 2.0, 40)
	)


func _build_craft_dialog() -> void:
	_craft_dialog = PanelContainer.new()
	_craft_dialog.z_index = 11
	var style := RWTheme.make_stylebox_flat(
		Color(0.12, 0.11, 0.1, 0.97), Color(0.45, 0.35, 0.15), 2
	)
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	_craft_dialog.add_theme_stylebox_override("panel", style)
	_craft_dialog.visible = false
	add_child(_craft_dialog)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	outer.custom_minimum_size = Vector2(440, 360)
	_craft_dialog.add_child(outer)

	_craft_bench_label = Label.new()
	_craft_bench_label.text = "Bills"
	_craft_bench_label.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	_craft_bench_label.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	outer.add_child(_craft_bench_label)
	outer.add_child(RWWidgets.create_separator())

	var queue_header := Label.new()
	queue_header.text = "Active Bills"
	queue_header.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	queue_header.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	outer.add_child(queue_header)

	var queue_scroll := ScrollContainer.new()
	queue_scroll.custom_minimum_size.y = 100
	queue_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(queue_scroll)

	_craft_queue_vbox = VBoxContainer.new()
	_craft_queue_vbox.add_theme_constant_override("separation", 3)
	_craft_queue_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	queue_scroll.add_child(_craft_queue_vbox)

	outer.add_child(RWWidgets.create_separator())

	var recipe_header := Label.new()
	recipe_header.text = "Available Recipes"
	recipe_header.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	recipe_header.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	outer.add_child(recipe_header)

	var recipe_scroll := ScrollContainer.new()
	recipe_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	recipe_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(recipe_scroll)

	_craft_recipe_vbox = VBoxContainer.new()
	_craft_recipe_vbox.add_theme_constant_override("separation", 3)
	_craft_recipe_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_scroll.add_child(_craft_recipe_vbox)

	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_END
	outer.add_child(close_row)
	var close_btn := RWWidgets.create_button("Close", Callable(), 70)
	close_btn.pressed.connect(_close_craft_dialog)
	close_row.add_child(close_btn)

	var vp_size := get_viewport_rect().size
	_craft_dialog.position = Vector2(
		maxf((vp_size.x - 460) / 2.0, 40),
		maxf((vp_size.y - 380) / 2.0, 40)
	)


func _open_craft_dialog(bench_name: String) -> void:
	_craft_bench_label.text = "Bills - %s" % bench_name
	_refresh_craft_queue()
	_refresh_craft_recipes()
	_craft_dialog.visible = true
	if AudioManager:
		AudioManager.play_sfx("click")


func _close_craft_dialog() -> void:
	_craft_dialog.visible = false


func _refresh_craft_queue() -> void:
	for c: Node in _craft_queue_vbox.get_children():
		c.queue_free()
	if not CraftingManager:
		return
	if CraftingManager.craft_queue.is_empty():
		var lbl := Label.new()
		lbl.text = "No active bills."
		lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		lbl.add_theme_color_override("font_color", RWTheme.TEXT_DARK)
		_craft_queue_vbox.add_child(lbl)
		return

	var grouped: Dictionary = {}
	for entry: Dictionary in CraftingManager.craft_queue:
		var rn: String = entry.get("recipe", "?")
		grouped[rn] = grouped.get(rn, 0) + 1

	for recipe_name: String in grouped:
		var recipe: Dictionary = CraftingManager.RECIPES.get(recipe_name, {})
		var label_text: String = recipe.get("label", recipe_name)
		var count: int = grouped[recipe_name]

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_craft_queue_vbox.add_child(row)

		var name_lbl := Label.new()
		name_lbl.text = "%s x%d" % [label_text, count]
		name_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		name_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var remove_btn := Button.new()
		remove_btn.text = "X"
		remove_btn.custom_minimum_size = Vector2(22, 22)
		remove_btn.add_theme_font_size_override("font_size", 10)
		remove_btn.add_theme_color_override("font_color", RWTheme.TEXT_RED)
		remove_btn.pressed.connect(_on_remove_bill.bind(recipe_name))
		row.add_child(remove_btn)


func _refresh_craft_recipes() -> void:
	for c: Node in _craft_recipe_vbox.get_children():
		c.queue_free()
	if not CraftingManager:
		return

	for recipe_name: String in CraftingManager.RECIPES:
		var recipe: Dictionary = CraftingManager.RECIPES[recipe_name]
		var label_text: String = recipe.get("label", recipe_name)
		var ingredients: Dictionary = recipe.get("ingredients", {})
		var min_skill: int = recipe.get("min_skill", 0)
		var skill_name: String = recipe.get("skill", "Crafting")
		var has_mats: bool = CraftingManager.has_ingredients(recipe_name)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_craft_recipe_vbox.add_child(row)

		var name_lbl := Label.new()
		name_lbl.text = label_text
		name_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		name_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE if has_mats else RWTheme.TEXT_DARK)
		name_lbl.custom_minimum_size.x = 120
		row.add_child(name_lbl)

		var mat_parts: PackedStringArray = []
		for mat_name: String in ingredients:
			mat_parts.append("%s x%d" % [mat_name, ingredients[mat_name]])
		var mat_lbl := Label.new()
		mat_lbl.text = ", ".join(mat_parts)
		mat_lbl.add_theme_font_size_override("font_size", 10)
		mat_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		mat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(mat_lbl)

		var skill_lbl := Label.new()
		skill_lbl.text = "%s %d+" % [skill_name, min_skill]
		skill_lbl.add_theme_font_size_override("font_size", 10)
		skill_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		skill_lbl.custom_minimum_size.x = 70
		row.add_child(skill_lbl)

		var add_btn := Button.new()
		add_btn.text = "+"
		add_btn.custom_minimum_size = Vector2(22, 22)
		add_btn.add_theme_font_size_override("font_size", 12)
		add_btn.add_theme_color_override("font_color", RWTheme.TEXT_GREEN)
		add_btn.pressed.connect(_on_add_bill.bind(recipe_name))
		row.add_child(add_btn)


func _on_add_bill(recipe_name: String) -> void:
	if not CraftingManager:
		return
	CraftingManager.add_to_queue(recipe_name)
	_refresh_craft_queue()
	show_toast("Bill added: %s" % CraftingManager.RECIPES.get(recipe_name, {}).get("label", recipe_name))
	if AudioManager:
		AudioManager.play_sfx("click")


func _on_remove_bill(recipe_name: String) -> void:
	if not CraftingManager:
		return
	CraftingManager.remove_from_queue(recipe_name)
	_refresh_craft_queue()
	show_toast("Bill removed")
	if AudioManager:
		AudioManager.play_sfx("click")


func _build_caravan_dialog() -> void:
	_caravan_dialog = PanelContainer.new()
	_caravan_dialog.z_index = 11
	var style := RWTheme.make_stylebox_flat(
		Color(0.12, 0.11, 0.1, 0.97), Color(0.35, 0.45, 0.25), 2
	)
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	_caravan_dialog.add_theme_stylebox_override("panel", style)
	_caravan_dialog.visible = false
	add_child(_caravan_dialog)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	outer.custom_minimum_size = Vector2(480, 400)
	_caravan_dialog.add_child(outer)

	var title := Label.new()
	title.text = "Form Caravan"
	title.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	title.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	outer.add_child(title)
	outer.add_child(RWWidgets.create_separator())

	var member_header := Label.new()
	member_header.text = "Select Members"
	member_header.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	member_header.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	outer.add_child(member_header)

	var member_scroll := ScrollContainer.new()
	member_scroll.custom_minimum_size.y = 100
	member_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(member_scroll)

	_caravan_members_vbox = VBoxContainer.new()
	_caravan_members_vbox.add_theme_constant_override("separation", 3)
	_caravan_members_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	member_scroll.add_child(_caravan_members_vbox)

	outer.add_child(RWWidgets.create_separator())

	var items_header := Label.new()
	items_header.text = "Supplies"
	items_header.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	items_header.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	outer.add_child(items_header)

	var items_scroll := ScrollContainer.new()
	items_scroll.custom_minimum_size.y = 80
	items_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(items_scroll)

	_caravan_items_vbox = VBoxContainer.new()
	_caravan_items_vbox.add_theme_constant_override("separation", 3)
	_caravan_items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_scroll.add_child(_caravan_items_vbox)

	_caravan_food_lbl = Label.new()
	_caravan_food_lbl.text = "Est. food: 0 days"
	_caravan_food_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
	_caravan_food_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
	outer.add_child(_caravan_food_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	btn_row.add_theme_constant_override("separation", 8)
	outer.add_child(btn_row)
	var form_btn := RWWidgets.create_button("Form Caravan", Callable(), 120)
	form_btn.pressed.connect(_on_form_caravan)
	btn_row.add_child(form_btn)
	var cancel_btn := RWWidgets.create_button("Cancel", Callable(), 70)
	cancel_btn.pressed.connect(_close_caravan_dialog)
	btn_row.add_child(cancel_btn)

	var vp_size := get_viewport_rect().size
	_caravan_dialog.position = Vector2(
		maxf((vp_size.x - 500) / 2.0, 40),
		maxf((vp_size.y - 420) / 2.0, 40)
	)


func open_caravan_dialog() -> void:
	_caravan_selected_pawns.clear()
	_caravan_selected_items.clear()
	_refresh_caravan_members()
	_refresh_caravan_items()
	_update_caravan_food_estimate()
	_caravan_dialog.visible = true
	if AudioManager:
		AudioManager.play_sfx("click")


func _close_caravan_dialog() -> void:
	_caravan_dialog.visible = false


func _refresh_caravan_members() -> void:
	for c: Node in _caravan_members_vbox.get_children():
		c.queue_free()
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed:
			continue
		var check := CheckBox.new()
		check.text = "%s (Lv%d %s)" % [p.pawn_name, p.get_skill_level(p.get_best_skill()), p.get_best_skill()]
		check.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		check.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		check.button_pressed = p.id in _caravan_selected_pawns
		check.toggled.connect(_on_caravan_member_toggled.bind(p.id))
		_caravan_members_vbox.add_child(check)


func _on_caravan_member_toggled(toggled: bool, pawn_id: int) -> void:
	if toggled:
		if pawn_id not in _caravan_selected_pawns:
			_caravan_selected_pawns.append(pawn_id)
	else:
		_caravan_selected_pawns.erase(pawn_id)
	_update_caravan_food_estimate()


func _refresh_caravan_items() -> void:
	for c: Node in _caravan_items_vbox.get_children():
		c.queue_free()

	var supply_items: Array[String] = ["Pemmican", "SimpleMeal", "FineMeal", "HerbalMedicine", "Medicine", "Silver"]
	for item_name: String in supply_items:
		var available: int = 0
		if ThingManager:
			for t: Thing in ThingManager.things:
				if t is Item and t.def_name == item_name:
					available += (t as Item).stack_count

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_caravan_items_vbox.add_child(row)

		var check := CheckBox.new()
		check.text = "%s (%d available)" % [item_name, available]
		check.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		check.add_theme_color_override("font_color", RWTheme.TEXT_WHITE if available > 0 else RWTheme.TEXT_DARK)
		check.disabled = (available == 0)
		check.button_pressed = _caravan_selected_items.has(item_name)
		check.toggled.connect(_on_caravan_item_toggled.bind(item_name, available))
		row.add_child(check)


func _on_caravan_item_toggled(toggled: bool, item_name: String, available: int) -> void:
	if toggled:
		_caravan_selected_items[item_name] = available
	else:
		_caravan_selected_items.erase(item_name)
	_update_caravan_food_estimate()


func _update_caravan_food_estimate() -> void:
	var food_items: float = 0.0
	for item_name: String in _caravan_selected_items:
		if item_name in ["Pemmican", "SimpleMeal", "FineMeal"]:
			food_items += float(_caravan_selected_items[item_name])
	var members := maxf(float(_caravan_selected_pawns.size()), 1.0)
	var days: float = food_items / (members * 1.5)
	_caravan_food_lbl.text = "Est. food: %.1f days for %d colonists" % [days, _caravan_selected_pawns.size()]


func _on_form_caravan() -> void:
	if _caravan_selected_pawns.is_empty():
		show_toast("Select at least one colonist!", 2.0, Color(0.9, 0.3, 0.2))
		return
	if WorldManager and WorldManager.has_method("create_caravan"):
		var caravan: Caravan = Caravan.new()
		for pid: int in _caravan_selected_pawns:
			caravan.add_member(pid)
		for item_name: String in _caravan_selected_items:
			caravan.add_item(item_name, _caravan_selected_items[item_name])
		WorldManager.add_caravan(caravan)
		show_toast("Caravan formed with %d colonists" % _caravan_selected_pawns.size())
	else:
		show_toast("Caravan formed (simulation)")
	if ColonyLog:
		ColonyLog.add_entry("Caravan", "Caravan formed with %d members." % _caravan_selected_pawns.size(), "info")
	_close_caravan_dialog()


func _build_drug_policy_dialog() -> void:
	_drug_policy_dialog = PanelContainer.new()
	_drug_policy_dialog.z_index = 12
	var style := RWTheme.make_stylebox_flat(
		Color(0.12, 0.11, 0.1, 0.97), Color(0.5, 0.25, 0.25), 2
	)
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	_drug_policy_dialog.add_theme_stylebox_override("panel", style)
	_drug_policy_dialog.visible = false
	add_child(_drug_policy_dialog)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	outer.custom_minimum_size = Vector2(360, 320)
	_drug_policy_dialog.add_child(outer)

	var title := Label.new()
	title.text = "Drug Policy"
	title.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	title.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	outer.add_child(title)
	outer.add_child(RWWidgets.create_separator())

	var tmpl_row := HBoxContainer.new()
	tmpl_row.add_theme_constant_override("separation", 6)
	outer.add_child(tmpl_row)
	var tmpl_lbl := Label.new()
	tmpl_lbl.text = "Templates:"
	tmpl_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
	tmpl_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
	tmpl_row.add_child(tmpl_lbl)
	for tmpl_name: String in ["NoDrugs", "SocialOnly", "Unrestricted"]:
		var btn := Button.new()
		btn.text = tmpl_name
		btn.custom_minimum_size = Vector2(80, 22)
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_on_drug_template.bind(tmpl_name))
		tmpl_row.add_child(btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	_drug_policy_vbox = VBoxContainer.new()
	_drug_policy_vbox.add_theme_constant_override("separation", 4)
	_drug_policy_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_drug_policy_vbox)

	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_END
	outer.add_child(close_row)
	var close_btn := RWWidgets.create_button("Done", Callable(), 70)
	close_btn.pressed.connect(_close_drug_policy)
	close_row.add_child(close_btn)

	var vp_size := get_viewport_rect().size
	_drug_policy_dialog.position = Vector2(
		maxf((vp_size.x - 380) / 2.0, 40),
		maxf((vp_size.y - 340) / 2.0, 40)
	)


func open_drug_policy(pawn_id: int) -> void:
	_drug_policy_pawn_id = pawn_id
	_refresh_drug_policy_list()
	_drug_policy_dialog.visible = true


func _close_drug_policy() -> void:
	_drug_policy_dialog.visible = false


func _refresh_drug_policy_list() -> void:
	for c: Node in _drug_policy_vbox.get_children():
		c.queue_free()
	if not ColonyPolicy:
		return
	var policy: Dictionary = ColonyPolicy.get_drug_policy(_drug_policy_pawn_id)
	for drug_name: String in policy:
		var drug_data: Dictionary = policy[drug_name]
		var allowed: bool = drug_data.get("allowed", false)
		var max_day: int = drug_data.get("max_per_day", 0)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_drug_policy_vbox.add_child(row)

		var check := CheckBox.new()
		check.text = drug_name
		check.button_pressed = allowed
		check.custom_minimum_size.x = 140
		check.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		check.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		check.toggled.connect(_on_drug_toggle.bind(drug_name))
		row.add_child(check)

		var max_lbl := Label.new()
		max_lbl.text = "Max/day:"
		max_lbl.add_theme_font_size_override("font_size", 10)
		max_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		row.add_child(max_lbl)

		var max_btn := Button.new()
		max_btn.text = str(max_day)
		max_btn.custom_minimum_size = Vector2(30, 20)
		max_btn.add_theme_font_size_override("font_size", 10)
		max_btn.pressed.connect(_on_drug_max_cycle.bind(drug_name, max_btn))
		row.add_child(max_btn)


func _on_drug_toggle(toggled: bool, drug_name: String) -> void:
	if not ColonyPolicy:
		return
	var policy: Dictionary = ColonyPolicy.get_drug_policy(_drug_policy_pawn_id)
	if policy.has(drug_name):
		policy[drug_name]["allowed"] = toggled
	ColonyPolicy.set_drug_policy(_drug_policy_pawn_id, policy)


func _on_drug_max_cycle(drug_name: String, btn: Button) -> void:
	if not ColonyPolicy:
		return
	var policy: Dictionary = ColonyPolicy.get_drug_policy(_drug_policy_pawn_id)
	if policy.has(drug_name):
		var current: int = policy[drug_name].get("max_per_day", 0)
		var next: int = (current + 1) % 5
		policy[drug_name]["max_per_day"] = next
		btn.text = str(next)
	ColonyPolicy.set_drug_policy(_drug_policy_pawn_id, policy)


func _on_drug_template(template_name: String) -> void:
	if not ColonyPolicy:
		return
	var templates: Dictionary = ColonyPolicy.DRUG_TEMPLATES
	if templates.has(template_name):
		ColonyPolicy.set_drug_policy(_drug_policy_pawn_id, templates[template_name].duplicate(true))
		_refresh_drug_policy_list()
		show_toast("Applied: %s" % template_name)


var _minimap_timer: float = 0.0
var _mo_update_timer: float = 0.0

func _process(delta: float) -> void:
	_minimap_timer += delta
	if _minimap_timer >= 2.0:
		_minimap_timer = 0.0
		_update_minimap()

	_mo_update_timer += delta
	if _mo_update_timer >= 0.15 and _mouseover_panel.visible:
		_mo_update_timer = 0.0
		_update_mouseover_readout()


func _update_mouseover_readout() -> void:
	if _map_viewport == null or not _map_viewport.has_method("get_camera_center_cell"):
		return
	var map: MapData = GameState.get_map() if GameState else null
	if map == null:
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var cell_pos: Vector2i
	if _map_viewport.has_method("screen_to_cell"):
		cell_pos = _map_viewport.screen_to_cell(mouse_pos)
	else:
		return

	if not map.in_bounds(cell_pos.x, cell_pos.y):
		_mo_terrain_lbl.text = "Out of bounds"
		return

	var cell: Cell = map.get_cell(cell_pos.x, cell_pos.y)
	if cell == null:
		return

	var terrain_name: String = cell.terrain_def
	if cell.is_mountain:
		if cell.ore.is_empty():
			terrain_name = "Mountain"
		else:
			terrain_name = cell.ore + " vein"

	_mo_terrain_lbl.text = terrain_name

	if _mo_value_labels.has("Temperature"):
		var temp: float = TemperatureManager.get_temperature_at(cell_pos) if TemperatureManager else (GameState.temperature if GameState else 21.0)
		_mo_value_labels["Temperature"].text = "%d°C" % int(temp)

	if _mo_value_labels.has("Fertility"):
		_mo_value_labels["Fertility"].text = "%d%%" % int(cell.fertility * 100.0)

	if _mo_value_labels.has("Roof"):
		_mo_value_labels["Roof"].text = "Roofed" if cell.roof else "No roof"

	if _mo_value_labels.has("Zone"):
		_mo_value_labels["Zone"].text = cell.zone if not cell.zone.is_empty() else "--"

	if _mo_value_labels.has("Beauty"):
		var beauty: float = 0.0
		if RoomService and RoomService.has_method("get_room_at"):
			var room: Dictionary = RoomService.get_room_at(cell_pos)
			beauty = room.get("beauty", 0.0)
		_mo_value_labels["Beauty"].text = "%.1f" % beauty

	if _mo_value_labels.has("Cleanliness"):
		var clean: float = 0.0
		if RoomService and RoomService.has_method("get_room_at"):
			var room: Dictionary = RoomService.get_room_at(cell_pos)
			clean = room.get("cleanliness", 0.0)
		_mo_value_labels["Cleanliness"].text = "%.1f" % clean

	if _mo_value_labels.has("Light"):
		var hour: int = GameState.game_date.get("hour", 12) if GameState else 12
		var light: float = 1.0
		if hour >= 22 or hour < 5:
			light = 0.3
		elif hour >= 5 and hour < 7:
			light = 0.6
		elif hour >= 19 and hour < 22:
			light = 0.5
		if cell.roof:
			light = 0.0
		_mo_value_labels["Light"].text = "%d%%" % int(light * 100.0)

	var things_text := ""
	if ThingManager:
		var things_at: Array = ThingManager.get_things_at(cell_pos)
		for thing: Thing in things_at:
			var info: String = thing.def_name
			if thing is Building:
				var bld := thing as Building
				if bld.build_state != Building.BuildState.COMPLETE:
					info += " (%s)" % Building.BuildState.keys()[bld.build_state]
			elif thing is Plant:
				info += " (%.0f%%)" % ((thing as Plant).growth * 100.0)
			things_text += info + "\n"
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.grid_pos == cell_pos and not p.dead:
				var pstate := ""
				if p.drafted:
					pstate = " [Drafted]"
				elif not p.current_job_name.is_empty():
					pstate = " (%s)" % p.current_job_name
				things_text += p.pawn_name + pstate + "\n"
	_mo_things_lbl.text = things_text.strip_edges()


func _build_toast_container() -> void:
	_toast_container = VBoxContainer.new()
	_toast_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_toast_container.offset_left = 200
	_toast_container.offset_top = 8
	_toast_container.offset_right = -200
	_toast_container.offset_bottom = 200
	_toast_container.add_theme_constant_override("separation", 4)
	_toast_container.z_index = 9
	_toast_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_container)


func show_toast(message: String, duration: float = 2.5, color: Color = Color(0.85, 0.8, 0.55)) -> void:
	var lbl := Label.new()
	lbl.text = message
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	lbl.add_theme_color_override("font_color", color)
	lbl.modulate.a = 1.0
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_container.add_child(lbl)

	var tween := create_tween()
	tween.tween_interval(duration)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.6)
	tween.tween_callback(lbl.queue_free)


func _on_map_pawn_selected(pawn_data: Dictionary) -> void:
	if _map_viewport and pawn_data.has("pawn_id"):
		_map_viewport.set_selected_pawn_id(pawn_data.get("pawn_id", -1))
	GameState.colonist_selected.emit(pawn_data)


func focus_camera_on_pawn(pawn_id: int) -> void:
	if not PawnManager or not _map_viewport:
		return
	for p: Pawn in PawnManager.pawns:
		if p.id == pawn_id and not p.dead:
			if _map_viewport.has_method("center_on_cell"):
				_map_viewport.center_on_cell(p.grid_pos)
			break


func _on_draft_toggled(pawn_id: int, drafted: bool) -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.id == pawn_id:
			p.drafted = drafted
			if not drafted:
				p.current_job_name = ""
				p.clear_path()
			if ColonyLog:
				var action: String = "drafted" if drafted else "undrafted"
				ColonyLog.add_entry("Draft", "%s %s." % [p.pawn_name, action], "info")
			break


func _on_designator_selected(designator_name: String) -> void:
	if _map_viewport and _map_viewport.has_method("set_placement_mode"):
		_map_viewport.set_placement_mode(designator_name)


func _on_designator_cleared() -> void:
	if _map_viewport and _map_viewport.has_method("clear_placement_mode"):
		_map_viewport.clear_placement_mode()


var _context_popup: PanelContainer

func _on_context_menu_requested(_cell_pos: Vector2i, screen_pos: Vector2, options: Array) -> void:
	if _context_popup and is_instance_valid(_context_popup):
		_context_popup.queue_free()
	if options.is_empty():
		return

	_context_popup = PanelContainer.new()
	_context_popup.z_index = 10
	var style := RWTheme.make_stylebox_flat(
		Color(0.14, 0.13, 0.12, 0.96), RWTheme.BORDER_COLOR, 1
	)
	style.content_margin_left = 4
	style.content_margin_top = 4
	style.content_margin_right = 4
	style.content_margin_bottom = 4
	_context_popup.add_theme_stylebox_override("panel", style)
	add_child(_context_popup)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_context_popup.add_child(vbox)

	for opt: Dictionary in options:
		var btn := Button.new()
		btn.text = str(opt.get("label", "?"))
		btn.custom_minimum_size = Vector2(160, 24)
		btn.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var normal_sb := StyleBoxFlat.new()
		normal_sb.bg_color = Color(0.18, 0.17, 0.15, 0.9)
		btn.add_theme_stylebox_override("normal", normal_sb)
		var hover_sb := StyleBoxFlat.new()
		hover_sb.bg_color = Color(0.3, 0.28, 0.2, 0.95)
		btn.add_theme_stylebox_override("hover", hover_sb)
		btn.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		btn.add_theme_color_override("font_hover_color", RWTheme.TEXT_YELLOW)
		btn.pressed.connect(_on_context_action.bind(opt))
		vbox.add_child(btn)

	_context_popup.position = Vector2(
		minf(screen_pos.x, get_viewport_rect().size.x - 180),
		minf(screen_pos.y, get_viewport_rect().size.y - options.size() * 28 - 16)
	)


func _on_context_action(opt: Dictionary) -> void:
	var action: String = str(opt.get("action", ""))
	var pos: Vector2i = opt.get("target_pos", Vector2i.ZERO)
	var pid: int = opt.get("pawn_id", -1)

	match action:
		"deconstruct":
			if ThingManager:
				var bld: Building = ThingManager.get_building_at(pos)
				if bld:
					var recovered: Dictionary = bld.deconstruct()
					ThingManager.thing_destroyed.emit(bld)
					show_toast("Deconstructed %s" % bld.def_name)
					if ColonyLog:
						ColonyLog.add_entry("Build", "Deconstructed %s" % bld.def_name, "info")
		"cancel_build":
			if ThingManager:
				var bld: Building = ThingManager.get_building_at(pos)
				if bld:
					bld.cancel_blueprint()
					ThingManager.thing_destroyed.emit(bld)
					show_toast("Cancelled blueprint")
					if ColonyLog:
						ColonyLog.add_entry("Build", "Cancelled %s blueprint" % bld.def_name, "info")
		"draft":
			if PawnManager and pid >= 0:
				for p: Pawn in PawnManager.pawns:
					if p.id == pid:
						p.drafted = true
						show_toast("%s drafted" % p.pawn_name, 1.5)
						if ColonyLog:
							ColonyLog.add_entry("Draft", "%s drafted." % p.pawn_name, "info")
						break
		"undraft":
			if PawnManager and pid >= 0:
				for p: Pawn in PawnManager.pawns:
					if p.id == pid:
						p.drafted = false
						p.current_job_name = ""
						p.clear_path()
						show_toast("%s undrafted" % p.pawn_name, 1.5)
						if ColonyLog:
							ColonyLog.add_entry("Draft", "%s undrafted." % p.pawn_name, "info")
						break
		"remove_zone":
			if ZoneManager:
				ZoneManager.remove_zone(pos)
				show_toast("Zone removed")
		"mine":
			show_toast("Mining designated")
			if ColonyLog:
				ColonyLog.add_entry("Orders", "Mining designated at (%d,%d)" % [pos.x, pos.y], "info")
		"stockpile_config":
			_show_stockpile_filter(pos)
		"workbench_bills":
			var bench_name: String = str(opt.get("bench_name", "Workbench"))
			_open_craft_dialog(bench_name)
		"cut_plant", "harvest", "haul", "repair", "prioritize_build":
			show_toast("%s designated" % action.capitalize())
			if ColonyLog:
				ColonyLog.add_entry("Orders", "%s designated at (%d,%d)" % [action.capitalize(), pos.x, pos.y], "info")

	if _context_popup and is_instance_valid(_context_popup):
		_context_popup.queue_free()
		_context_popup = null
