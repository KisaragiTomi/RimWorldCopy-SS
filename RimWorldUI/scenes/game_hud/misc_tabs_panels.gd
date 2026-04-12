extends Control

var _assign_panel: PanelContainer
var _animals_panel: PanelContainer
var _wildlife_panel: PanelContainer
var _history_panel: PanelContainer
var _factions_panel: PanelContainer
var _prisoners_panel: PanelContainer
var _overview_panel: PanelContainer
var _alerts_panel: PanelContainer
var _animals_vbox: VBoxContainer
var _wildlife_vbox: VBoxContainer
var _history_vbox: VBoxContainer
var _factions_vbox: VBoxContainer
var _prisoners_vbox: VBoxContainer
var _overview_vbox: VBoxContainer
var _alerts_vbox: VBoxContainer
var _alerts_filter: String = "all"
var _refresh_timer: float = 0.0

const ASSIGN_OUTFITS := ["Anything", "Worker", "Soldier", "Nudist"]
const ASSIGN_DRUGS := ["No drugs", "Social only", "Medical only", "Unrestricted"]
const ASSIGN_MEALS := ["Anything", "Lavish only", "Fine only", "Simple only"]


func _ready() -> void:
	_build_assign_panel()
	_build_animals_panel()
	_build_wildlife_panel()
	_build_history_panel()
	_build_factions_panel()
	_build_prisoners_panel()
	_build_overview_panel()
	_build_alerts_panel()


func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= 2.0:
		_refresh_timer = 0.0
		if _animals_panel and _animals_panel.visible:
			_refresh_animals()
		if _wildlife_panel and _wildlife_panel.visible:
			_refresh_wildlife()
		if _history_panel and _history_panel.visible:
			_refresh_history()
		if _factions_panel and _factions_panel.visible:
			_refresh_factions()
		if _prisoners_panel and _prisoners_panel.visible:
			_refresh_prisoners()
		if _overview_panel and _overview_panel.visible:
			_refresh_overview()
		if _alerts_panel and _alerts_panel.visible:
			_refresh_alerts()


func _hide_all_tabs() -> void:
	if _assign_panel:
		_assign_panel.visible = false
	if _animals_panel:
		_animals_panel.visible = false
	if _wildlife_panel:
		_wildlife_panel.visible = false
	if _history_panel:
		_history_panel.visible = false
	if _factions_panel:
		_factions_panel.visible = false
	if _prisoners_panel:
		_prisoners_panel.visible = false
	if _overview_panel:
		_overview_panel.visible = false
	if _alerts_panel:
		_alerts_panel.visible = false


func show_assign() -> void:
	visible = true
	_hide_all_tabs()
	_assign_panel.visible = true


func show_animals() -> void:
	visible = true
	_hide_all_tabs()
	_animals_panel.visible = true
	_refresh_animals()


func show_wildlife() -> void:
	visible = true
	_hide_all_tabs()
	_wildlife_panel.visible = true
	_refresh_wildlife()


func show_history() -> void:
	visible = true
	_hide_all_tabs()
	_history_panel.visible = true
	_refresh_history()


func show_factions() -> void:
	visible = true
	_hide_all_tabs()
	_factions_panel.visible = true
	_refresh_factions()


func show_prisoners() -> void:
	visible = true
	_hide_all_tabs()
	_prisoners_panel.visible = true
	_refresh_prisoners()


func show_overview() -> void:
	visible = true
	_hide_all_tabs()
	_overview_panel.visible = true
	_refresh_overview()


func show_alerts() -> void:
	visible = true
	_hide_all_tabs()
	_alerts_panel.visible = true
	_refresh_alerts()


func hide_all() -> void:
	visible = false
	_hide_all_tabs()


func _panel_style() -> StyleBoxFlat:
	var style := RWTheme.make_stylebox_flat(
		Color(0.13, 0.125, 0.11, 0.96), RWTheme.BORDER_COLOR, 1
	)
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style


func _wrap_scroll(inner: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	scroll.add_child(inner)
	return panel


func _build_assign_panel() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_assign_panel = _wrap_scroll(vbox)
	_assign_panel.visible = false

	var title := Label.new()
	title.text = "Assign \u2014 outfit, drugs, meals"
	title.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	title.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	vbox.add_child(title)
	vbox.add_child(RWWidgets.create_separator())

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)
	for h in ["Colonist", "Outfit", "Drugs", "Meals"]:
		var hl := Label.new()
		hl.text = h
		hl.custom_minimum_size.x = 120 if h == "Colonist" else 100
		hl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
		hl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		header.add_child(hl)

	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.dead:
				continue
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			vbox.add_child(row)
			var n := Label.new()
			n.text = p.pawn_name
			n.custom_minimum_size.x = 120
			n.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
			n.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
			row.add_child(n)
			for key in ["outfit", "drugs", "meals"]:
				var cur_val: String = p.get_meta(key, ASSIGN_OUTFITS[0] if key == "outfit" else (ASSIGN_DRUGS[0] if key == "drugs" else ASSIGN_MEALS[0]))
				var b := RWWidgets.create_button(cur_val, Callable(), 96)
				b.tooltip_text = "Click to cycle policy"
				b.pressed.connect(_cycle_assign_pawn.bind(p, key, b))
				row.add_child(b)
				if key == "drugs":
					var edit_btn := RWWidgets.create_button("...", Callable(), 26)
					edit_btn.tooltip_text = "Edit drug policy"
					edit_btn.pressed.connect(_open_drug_policy_for_pawn.bind(p.id))
					row.add_child(edit_btn)
	else:
		for c in GameState.colonists:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			vbox.add_child(row)
			var n := Label.new()
			n.text = str(c.get("name", "?"))
			n.custom_minimum_size.x = 120
			n.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
			n.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
			row.add_child(n)
			for key in ["outfit", "drugs", "meals"]:
				var b := RWWidgets.create_button(str(c.get(key, "\u2014")), Callable(), 96)
				b.tooltip_text = "Click to cycle policy"
				b.pressed.connect(_cycle_assign.bind(c, key, b))
				row.add_child(b)


func _assign_options_for_key(key: String) -> Array[String]:
	match key:
		"outfit":
			return ASSIGN_OUTFITS
		"drugs":
			return ASSIGN_DRUGS
		"meals":
			return ASSIGN_MEALS
	return []


func _cycle_assign(colonist: Dictionary, key: String, btn: Button) -> void:
	var opts := _assign_options_for_key(key)
	if opts.is_empty():
		return
	var cur: String = str(colonist.get(key, opts[0]))
	var idx: int = opts.find(cur)
	if idx < 0:
		idx = 0
	var nxt: String = opts[(idx + 1) % opts.size()]
	colonist[key] = nxt
	btn.text = nxt
	if AudioManager:
		AudioManager.play_sfx("ui_click")


func _cycle_assign_pawn(p: Pawn, key: String, btn: Button) -> void:
	var opts := _assign_options_for_key(key)
	if opts.is_empty():
		return
	var cur: String = p.get_meta(key, opts[0])
	var idx: int = opts.find(cur)
	if idx < 0:
		idx = 0
	var nxt: String = opts[(idx + 1) % opts.size()]
	p.set_meta(key, nxt)
	btn.text = nxt
	if AudioManager:
		AudioManager.play_sfx("ui_click")


func _open_drug_policy_for_pawn(pawn_id: int) -> void:
	var hud := get_parent()
	if hud and hud.has_method("open_drug_policy"):
		hud.open_drug_policy(pawn_id)


func _build_animals_panel() -> void:
	_animals_vbox = VBoxContainer.new()
	_animals_vbox.add_theme_constant_override("separation", 6)
	_animals_panel = _wrap_scroll(_animals_vbox)
	_animals_panel.visible = false

	var title := Label.new()
	title.text = "Animals \u2014 tamed"
	title.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	title.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	_animals_vbox.add_child(title)
	_animals_vbox.add_child(RWWidgets.create_separator())


func _refresh_animals() -> void:
	while _animals_vbox.get_child_count() > 2:
		var c: Node = _animals_vbox.get_child(2)
		_animals_vbox.remove_child(c)
		c.queue_free()

	if AnimalManager:
		var tamed: Array[Animal] = AnimalManager.get_tamed_animals()
		if tamed.is_empty():
			var empty_lbl := Label.new()
			empty_lbl.text = "No tamed animals."
			empty_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
			empty_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
			_animals_vbox.add_child(empty_lbl)
			return
		for a: Animal in tamed:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			_animals_vbox.add_child(row)
			var name_lbl := Label.new()
			name_lbl.text = a.name_label if not a.name_label.is_empty() else a.species
			name_lbl.custom_minimum_size.x = 100
			name_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
			name_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
			row.add_child(name_lbl)
			var meta := Label.new()
			var train_text := ""
			if not a.training.is_empty():
				var skills: PackedStringArray = PackedStringArray()
				for sk: String in a.training:
					skills.append(sk)
				train_text = ", ".join(skills)
			meta.text = "%s \u00b7 age %.0f%s" % [a.species, a.age, (" \u00b7 " + train_text) if not train_text.is_empty() else ""]
			meta.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
			meta.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
			meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(meta)
	else:
		for a in GameState.tamed_animals:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			_animals_vbox.add_child(row)
			var name_lbl := Label.new()
			name_lbl.text = str(a.get("name", "?"))
			name_lbl.custom_minimum_size.x = 100
			name_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
			name_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
			row.add_child(name_lbl)
			var meta := Label.new()
			meta.text = "%s \u00b7 age %s \u00b7 %s" % [
				a.get("gender", "?"), str(a.get("age", "?")), a.get("training", ""),
			]
			meta.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
			meta.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
			meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(meta)


func _build_wildlife_panel() -> void:
	_wildlife_vbox = VBoxContainer.new()
	_wildlife_vbox.add_theme_constant_override("separation", 6)
	_wildlife_panel = _wrap_scroll(_wildlife_vbox)
	_wildlife_panel.visible = false

	var title := Label.new()
	title.text = "Wildlife \u2014 map species"
	title.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	title.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	_wildlife_vbox.add_child(title)
	_wildlife_vbox.add_child(RWWidgets.create_separator())


func _refresh_wildlife() -> void:
	while _wildlife_vbox.get_child_count() > 2:
		var c: Node = _wildlife_vbox.get_child(2)
		_wildlife_vbox.remove_child(c)
		c.queue_free()

	if AnimalManager:
		var species_counts: Dictionary = {}
		for a: Animal in AnimalManager.animals:
			if a.tamed or a.dead:
				continue
			var sp: String = a.species
			var prev: int = species_counts.get(sp, 0)
			species_counts[sp] = prev + 1
		if species_counts.is_empty():
			var empty_lbl := Label.new()
			empty_lbl.text = "No wildlife on the map."
			empty_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
			empty_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
			_wildlife_vbox.add_child(empty_lbl)
			return
		for sp: String in species_counts:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			_wildlife_vbox.add_child(row)
			var sp_lbl := Label.new()
			sp_lbl.text = sp
			sp_lbl.custom_minimum_size.x = 120
			sp_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
			sp_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
			row.add_child(sp_lbl)
			var cnt_lbl := Label.new()
			cnt_lbl.text = "\u00d7 %d" % species_counts[sp]
			cnt_lbl.custom_minimum_size.x = 48
			cnt_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
			cnt_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
			row.add_child(cnt_lbl)
	else:
		for w in GameState.wildlife_species:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			_wildlife_vbox.add_child(row)
			var sp := Label.new()
			sp.text = str(w.get("species", "?"))
			sp.custom_minimum_size.x = 120
			sp.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
			sp.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
			row.add_child(sp)
			var cnt := Label.new()
			cnt.text = "\u00d7 %s" % str(w.get("count", 0))
			cnt.custom_minimum_size.x = 48
			cnt.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
			cnt.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
			row.add_child(cnt)


func _build_history_panel() -> void:
	_history_vbox = VBoxContainer.new()
	_history_vbox.add_theme_constant_override("separation", 8)
	_history_panel = _wrap_scroll(_history_vbox)
	_history_panel.visible = false

	var title := Label.new()
	title.text = "History"
	title.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	title.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	_history_vbox.add_child(title)
	_history_vbox.add_child(RWWidgets.create_separator())


func _refresh_history() -> void:
	while _history_vbox.get_child_count() > 2:
		var c: Node = _history_vbox.get_child(2)
		_history_vbox.remove_child(c)
		c.queue_free()

	if ColonyLog:
		var recent: Array[Dictionary] = ColonyLog.get_recent(40)
		if recent.is_empty():
			var empty_lbl := Label.new()
			empty_lbl.text = "No events recorded yet."
			empty_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
			empty_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
			_history_vbox.add_child(empty_lbl)
			return
		for entry: Dictionary in recent:
			var block := VBoxContainer.new()
			block.add_theme_constant_override("separation", 2)
			_history_vbox.add_child(block)
			var day_lbl := Label.new()
			var cat: String = entry.get("category", "")
			var day: int = entry.get("day", 0)
			day_lbl.text = "[%s] Day %d" % [cat, day]
			day_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
			var severity: String = entry.get("severity", "info")
			var sev_color := Color(0.8, 0.75, 0.4)
			match severity:
				"danger":
					sev_color = Color(1.0, 0.3, 0.3)
				"warning":
					sev_color = Color(1.0, 0.7, 0.2)
				"positive":
					sev_color = Color(0.3, 0.9, 0.4)
			day_lbl.add_theme_color_override("font_color", sev_color)
			block.add_child(day_lbl)
			var txt := Label.new()
			txt.text = str(entry.get("message", ""))
			txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			txt.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
			txt.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
			block.add_child(txt)
	else:
		for h in GameState.history_log:
			var block := VBoxContainer.new()
			block.add_theme_constant_override("separation", 2)
			_history_vbox.add_child(block)
			var day_lbl := Label.new()
			day_lbl.text = "Day %s" % str(h.get("day", "?"))
			day_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
			day_lbl.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
			block.add_child(day_lbl)
			var txt := Label.new()
			txt.text = str(h.get("text", ""))
			txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			txt.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
			txt.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
			block.add_child(txt)


func _build_factions_panel() -> void:
	_factions_vbox = VBoxContainer.new()
	_factions_vbox.add_theme_constant_override("separation", 8)
	_factions_panel = _wrap_scroll(_factions_vbox)
	_factions_panel.visible = false

	var title := Label.new()
	title.text = "Factions"
	title.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	title.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	_factions_vbox.add_child(title)
	_factions_vbox.add_child(RWWidgets.create_separator())


func _refresh_factions() -> void:
	while _factions_vbox.get_child_count() > 2:
		var c: Node = _factions_vbox.get_child(2)
		_factions_vbox.remove_child(c)
		c.queue_free()

	var faction_data: Array[Dictionary] = []
	if WorldManager and WorldManager.faction_mgr:
		faction_data = WorldManager.faction_mgr.get_faction_summary()

	if faction_data.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No factions discovered yet."
		empty_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
		empty_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		_factions_vbox.add_child(empty_lbl)
		return

	for fd: Dictionary in faction_data:
		var block := VBoxContainer.new()
		block.add_theme_constant_override("separation", 3)
		_factions_vbox.add_child(block)

		var name_row := HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 8)
		block.add_child(name_row)

		var name_lbl := Label.new()
		name_lbl.text = str(fd.get("label", fd.get("name", "?")))
		name_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
		var goodwill: int = fd.get("goodwill", 0)
		var hostile: bool = fd.get("hostile", false)
		if hostile:
			name_lbl.add_theme_color_override("font_color", Color(0.9, 0.25, 0.2))
		elif goodwill >= 75:
			name_lbl.add_theme_color_override("font_color", Color(0.2, 0.8, 0.3))
		elif goodwill > 0:
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		else:
			name_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_row.add_child(name_lbl)

		var gw_lbl := Label.new()
		var relation_str := ""
		if hostile:
			relation_str = "Hostile"
		elif goodwill >= 75:
			relation_str = "Ally"
		elif goodwill > 0:
			relation_str = "Neutral+"
		elif goodwill > -75:
			relation_str = "Neutral"
		else:
			relation_str = "Enemy"
		gw_lbl.text = "%s (%+d)" % [relation_str, goodwill]
		gw_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		gw_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		name_row.add_child(gw_lbl)

		var bar := ProgressBar.new()
		bar.min_value = -100.0
		bar.max_value = 100.0
		bar.value = float(goodwill)
		bar.custom_minimum_size = Vector2(0, 8)
		bar.show_percentage = false
		var bar_style := StyleBoxFlat.new()
		bar_style.bg_color = Color(0.2, 0.2, 0.2, 0.6)
		bar_style.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("background", bar_style)
		var fill_style := StyleBoxFlat.new()
		if hostile:
			fill_style.bg_color = Color(0.8, 0.2, 0.15)
		elif goodwill >= 0:
			fill_style.bg_color = Color(0.2, 0.65, 0.3)
		else:
			fill_style.bg_color = Color(0.7, 0.4, 0.1)
		fill_style.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("fill", fill_style)
		block.add_child(bar)

		var leader: String = fd.get("leader", "")
		var settlements: int = fd.get("settlements", 0)
		if not leader.is_empty() or settlements > 0:
			var detail := Label.new()
			var parts: PackedStringArray = PackedStringArray()
			if not leader.is_empty():
				parts.append("Leader: " + leader)
			if settlements > 0:
				parts.append("Settlements: %d" % settlements)
			detail.text = " | ".join(parts)
			detail.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
			detail.add_theme_color_override("font_color", RWTheme.TEXT_DARK)
			block.add_child(detail)


func _build_prisoners_panel() -> void:
	_prisoners_panel = PanelContainer.new()
	_prisoners_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_prisoners_panel.add_theme_stylebox_override("panel", _panel_style())
	_prisoners_panel.visible = false
	add_child(_prisoners_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_prisoners_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Prisoners"
	title.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	title.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	vbox.add_child(title)
	vbox.add_child(RWWidgets.create_separator())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_prisoners_vbox = VBoxContainer.new()
	_prisoners_vbox.add_theme_constant_override("separation", 6)
	_prisoners_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_prisoners_vbox)


func _refresh_prisoners() -> void:
	for c: Node in _prisoners_vbox.get_children():
		c.queue_free()

	if not PrisonerManager or PrisonerManager.prisoners.is_empty():
		var lbl := Label.new()
		lbl.text = "No prisoners."
		lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
		lbl.add_theme_color_override("font_color", RWTheme.TEXT_DARK)
		_prisoners_vbox.add_child(lbl)
		return

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	_prisoners_vbox.add_child(header)
	for col_text: String in ["Name", "Resistance", "Recruit", "Health", "Mood"]:
		var h := Label.new()
		h.text = col_text
		h.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		h.add_theme_color_override("font_color", RWTheme.TEXT_DARK)
		h.custom_minimum_size.x = 80
		h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(h)

	for prisoner: Pawn in PrisonerManager.prisoners:
		if prisoner.dead:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		_prisoners_vbox.add_child(row)

		var name_lbl := Label.new()
		name_lbl.text = prisoner.pawn_name
		name_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		name_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		name_lbl.custom_minimum_size.x = 80
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var resistance: float = prisoner.get_meta("resistance", 1.0) as float
		var resist_bar := ProgressBar.new()
		resist_bar.min_value = 0.0
		resist_bar.max_value = 1.0
		resist_bar.value = resistance
		resist_bar.custom_minimum_size = Vector2(80, 14)
		resist_bar.show_percentage = false
		var rb_bg := StyleBoxFlat.new()
		rb_bg.bg_color = Color(0.15, 0.15, 0.15, 0.8)
		rb_bg.set_corner_radius_all(2)
		resist_bar.add_theme_stylebox_override("background", rb_bg)
		var rb_fill := StyleBoxFlat.new()
		rb_fill.bg_color = Color(0.8, 0.5, 0.15)
		rb_fill.set_corner_radius_all(2)
		resist_bar.add_theme_stylebox_override("fill", rb_fill)
		resist_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(resist_bar)

		var recruit_diff: float = prisoner.get_meta("recruit_difficulty", 0.5) as float
		var recruit_prog: float = prisoner.get_meta("recruit_progress", 0.0) as float
		var recruit_pct: float = clampf(recruit_prog / maxf(recruit_diff, 0.01), 0.0, 1.0)
		var recruit_bar := ProgressBar.new()
		recruit_bar.min_value = 0.0
		recruit_bar.max_value = 1.0
		recruit_bar.value = recruit_pct
		recruit_bar.custom_minimum_size = Vector2(80, 14)
		recruit_bar.show_percentage = false
		var rp_bg := StyleBoxFlat.new()
		rp_bg.bg_color = Color(0.15, 0.15, 0.15, 0.8)
		rp_bg.set_corner_radius_all(2)
		recruit_bar.add_theme_stylebox_override("background", rp_bg)
		var rp_fill := StyleBoxFlat.new()
		rp_fill.bg_color = Color(0.2, 0.6, 0.8)
		rp_fill.set_corner_radius_all(2)
		recruit_bar.add_theme_stylebox_override("fill", rp_fill)
		recruit_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(recruit_bar)

		var health_val: float = 1.0
		if prisoner.health:
			health_val = prisoner.health.get_overall_health()
		var health_lbl := Label.new()
		health_lbl.text = "%d%%" % int(health_val * 100.0)
		health_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		health_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GREEN if health_val >= 0.7 else RWTheme.TEXT_RED)
		health_lbl.custom_minimum_size.x = 80
		health_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(health_lbl)

		var mood_val: float = prisoner.get_need("Mood")
		var mood_lbl := Label.new()
		mood_lbl.text = "%d%%" % int(mood_val * 100.0)
		mood_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		var mood_color: Color = RWTheme.TEXT_GREEN
		if mood_val < 0.3:
			mood_color = RWTheme.TEXT_RED
		elif mood_val < 0.5:
			mood_color = RWTheme.TEXT_YELLOW
		mood_lbl.add_theme_color_override("font_color", mood_color)
		mood_lbl.custom_minimum_size.x = 80
		mood_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(mood_lbl)


func _build_overview_panel() -> void:
	_overview_panel = PanelContainer.new()
	_overview_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overview_panel.add_theme_stylebox_override("panel", _panel_style())
	_overview_panel.visible = false
	add_child(_overview_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_overview_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Colony Overview"
	title.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	title.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	vbox.add_child(title)
	vbox.add_child(RWWidgets.create_separator())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_overview_vbox = VBoxContainer.new()
	_overview_vbox.add_theme_constant_override("separation", 5)
	_overview_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_overview_vbox)


func _refresh_overview() -> void:
	for c: Node in _overview_vbox.get_children():
		c.queue_free()

	var colonists_alive: int = 0
	var colonists_down: int = 0
	var avg_mood: float = 0.0
	var drafted_count: int = 0
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.dead:
				continue
			colonists_alive += 1
			avg_mood += p.get_need("Mood")
			if p.downed:
				colonists_down += 1
			if p.drafted:
				drafted_count += 1
		if colonists_alive > 0:
			avg_mood /= float(colonists_alive)

	var prisoner_count: int = PrisonerManager.prisoners.size() if PrisonerManager else 0
	var wealth: float = GameState.get_colony_wealth() if GameState else 0.0
	var temperature: float = GameState.temperature if GameState else 15.0
	var weather: String = WeatherManager.current_weather if WeatherManager else "Clear"
	var fire_count: int = FireManager.get_active_fire_count() if FireManager and FireManager.has_method("get_active_fire_count") else 0
	var research_name: String = ""
	if ResearchManager and ResearchManager.has_method("get_current_project_name"):
		research_name = ResearchManager.get_current_project_name()

	var stats: Array[Array] = [
		["Colonists", "%d alive" % colonists_alive, RWTheme.TEXT_WHITE],
		["Downed", "%d" % colonists_down, RWTheme.TEXT_RED if colonists_down > 0 else RWTheme.TEXT_GREEN],
		["Drafted", "%d" % drafted_count, RWTheme.TEXT_YELLOW if drafted_count > 0 else RWTheme.TEXT_GRAY],
		["Avg Mood", "%d%%" % int(avg_mood * 100.0), _mood_stat_color(avg_mood)],
		["Prisoners", "%d" % prisoner_count, RWTheme.TEXT_WHITE],
		["Wealth", "%.0f" % wealth, RWTheme.TEXT_YELLOW],
		["Temperature", "%.0f°C" % temperature, RWTheme.TEXT_WHITE],
		["Weather", weather, RWTheme.TEXT_WHITE],
		["Active Fires", "%d" % fire_count, RWTheme.TEXT_RED if fire_count > 0 else RWTheme.TEXT_GREEN],
		["Research", research_name if not research_name.is_empty() else "None", RWTheme.TEXT_WHITE],
	]

	for entry: Array in stats:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_overview_vbox.add_child(row)

		var key_lbl := Label.new()
		key_lbl.text = str(entry[0])
		key_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
		key_lbl.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		key_lbl.custom_minimum_size.x = 120
		row.add_child(key_lbl)

		var val_lbl := Label.new()
		val_lbl.text = str(entry[1])
		val_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
		val_lbl.add_theme_color_override("font_color", entry[2] as Color)
		val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(val_lbl)

	_overview_vbox.add_child(RWWidgets.create_separator())

	var pawn_header := Label.new()
	pawn_header.text = "Colonist Status"
	pawn_header.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	pawn_header.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	_overview_vbox.add_child(pawn_header)

	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.dead:
				continue
			var prow := HBoxContainer.new()
			prow.add_theme_constant_override("separation", 6)
			_overview_vbox.add_child(prow)

			var pname := Label.new()
			pname.text = p.pawn_name
			pname.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
			pname.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
			pname.custom_minimum_size.x = 80
			prow.add_child(pname)

			var pjob := Label.new()
			var job_text: String = p.current_job_name if not p.current_job_name.is_empty() else "Idle"
			if p.drafted:
				job_text = "Drafted"
			if p.downed:
				job_text = "Downed"
			pjob.text = job_text
			pjob.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
			pjob.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
			pjob.custom_minimum_size.x = 80
			prow.add_child(pjob)

			var pmood: float = p.get_need("Mood")
			var pmood_lbl := Label.new()
			pmood_lbl.text = "Mood %d%%" % int(pmood * 100.0)
			pmood_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
			pmood_lbl.add_theme_color_override("font_color", _mood_stat_color(pmood))
			pmood_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			prow.add_child(pmood_lbl)


func _mood_stat_color(mood: float) -> Color:
	if mood < 0.3:
		return RWTheme.TEXT_RED
	elif mood < 0.5:
		return RWTheme.TEXT_YELLOW
	return RWTheme.TEXT_GREEN


func _build_alerts_panel() -> void:
	_alerts_panel = PanelContainer.new()
	_alerts_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_alerts_panel.add_theme_stylebox_override("panel", _panel_style())
	_alerts_panel.visible = false
	add_child(_alerts_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_alerts_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Alert Log"
	title.add_theme_font_size_override("font_size", RWTheme.FONT_MEDIUM)
	title.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	vbox.add_child(title)

	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 4)
	vbox.add_child(filter_row)
	for sev: String in ["all", "danger", "warning", "positive", "info"]:
		var btn := Button.new()
		btn.text = sev.capitalize()
		btn.custom_minimum_size = Vector2(65, 22)
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_on_alert_filter.bind(sev))
		filter_row.add_child(btn)

	vbox.add_child(RWWidgets.create_separator())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_alerts_vbox = VBoxContainer.new()
	_alerts_vbox.add_theme_constant_override("separation", 3)
	_alerts_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_alerts_vbox)


func _on_alert_filter(severity: String) -> void:
	_alerts_filter = severity
	_refresh_alerts()


func _refresh_alerts() -> void:
	for c: Node in _alerts_vbox.get_children():
		c.queue_free()
	if not ColonyLog:
		var empty := Label.new()
		empty.text = "No log available."
		empty.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
		empty.add_theme_color_override("font_color", RWTheme.TEXT_DARK)
		_alerts_vbox.add_child(empty)
		return

	var log_entries: Array[Dictionary]
	if _alerts_filter == "all":
		log_entries = ColonyLog.get_recent(50)
	else:
		log_entries = ColonyLog.get_by_severity(_alerts_filter, 50)

	if log_entries.is_empty():
		var empty := Label.new()
		empty.text = "No entries for filter: %s" % _alerts_filter
		empty.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
		empty.add_theme_color_override("font_color", RWTheme.TEXT_DARK)
		_alerts_vbox.add_child(empty)
		return

	var sev_colors := {
		"danger": RWTheme.TEXT_RED,
		"warning": RWTheme.TEXT_YELLOW,
		"positive": RWTheme.TEXT_GREEN,
		"info": RWTheme.TEXT_GRAY,
	}

	var reversed_entries: Array[Dictionary] = []
	for i: int in range(log_entries.size() - 1, -1, -1):
		reversed_entries.append(log_entries[i])

	for entry: Dictionary in reversed_entries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_alerts_vbox.add_child(row)

		var time_lbl := Label.new()
		time_lbl.text = "D%d %02d:00" % [entry.get("day", 0), entry.get("hour", 0)]
		time_lbl.add_theme_font_size_override("font_size", 9)
		time_lbl.add_theme_color_override("font_color", RWTheme.TEXT_DARK)
		time_lbl.custom_minimum_size.x = 60
		row.add_child(time_lbl)

		var sev: String = entry.get("severity", "info")
		var sev_lbl := Label.new()
		sev_lbl.text = "[%s]" % sev.to_upper().left(4)
		sev_lbl.add_theme_font_size_override("font_size", 9)
		sev_lbl.add_theme_color_override("font_color", sev_colors.get(sev, RWTheme.TEXT_GRAY))
		sev_lbl.custom_minimum_size.x = 42
		row.add_child(sev_lbl)

		var msg_lbl := Label.new()
		msg_lbl.text = str(entry.get("message", ""))
		msg_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
		msg_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
		msg_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		row.add_child(msg_lbl)
