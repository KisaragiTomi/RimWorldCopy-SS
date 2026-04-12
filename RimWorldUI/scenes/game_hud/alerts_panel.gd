extends Control

var _alert_list: VBoxContainer
var _alerts: Array[Dictionary] = []
var _refresh_timer: float = 0.0
const REFRESH_INTERVAL := 3.0


func _ready() -> void:
	_build_ui()
	_refresh_alerts()


func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= REFRESH_INTERVAL:
		_refresh_timer = 0.0
		_refresh_alerts()


func _refresh_alerts() -> void:
	_alerts.clear()
	_check_low_food()
	_check_downed_colonists()
	_check_mental_breaks()
	_check_low_mood()
	_check_unpowered_buildings()
	_check_idle_colonists()
	_check_temperature()
	_rebuild_ui()


func _check_low_food() -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if p.get_need("Food") < 0.15:
			_alerts.append({"text": "%s is starving" % p.pawn_name, "type": "critical", "age": 0.0})
		elif p.get_need("Food") < 0.3:
			_alerts.append({"text": "%s is hungry" % p.pawn_name, "type": "warning", "age": 0.0})


func _check_downed_colonists() -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.downed and not p.dead:
			_alerts.append({"text": "%s needs rescue" % p.pawn_name, "type": "critical", "age": 0.0})


func _check_mental_breaks() -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.is_in_mental_break():
			_alerts.append({"text": "%s: %s" % [p.pawn_name, p.mental_state], "type": "critical", "age": 0.0})


func _check_low_mood() -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed:
			continue
		var mood := p.get_need("Mood")
		if mood < Pawn.MAJOR_BREAK_THRESHOLD:
			_alerts.append({"text": "%s extreme break risk" % p.pawn_name, "type": "warning", "age": 0.0})
		elif mood < Pawn.MINOR_BREAK_THRESHOLD:
			_alerts.append({"text": "%s minor break risk" % p.pawn_name, "type": "warning", "age": 0.0})


func _check_unpowered_buildings() -> void:
	if not ThingManager:
		return
	var unpowered_count: int = 0
	for t: Thing in ThingManager.things:
		if t is Building:
			var b := t as Building
			if b.build_state == Building.BuildState.COMPLETE and b.needs_power() and not b.is_powered:
				unpowered_count += 1
	if unpowered_count > 0:
		_alerts.append({"text": "%d building(s) unpowered" % unpowered_count, "type": "info", "age": 0.0})


func _check_idle_colonists() -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed or p.drafted:
			continue
		if p.current_job_name.is_empty():
			_alerts.append({"text": "%s is idle" % p.pawn_name, "type": "minor", "age": 0.0})


func _check_temperature() -> void:
	if not GameState:
		return
	var t: float = GameState.temperature
	if t < -15.0:
		_alerts.append({"text": "Extreme cold: %.0f°C" % t, "type": "warning", "age": 0.0})
	elif t > 45.0:
		_alerts.append({"text": "Extreme heat: %.0f°C" % t, "type": "warning", "age": 0.0})


func _rebuild_ui() -> void:
	for child in _alert_list.get_children():
		child.queue_free()
	for alert in _alerts:
		_add_alert_entry(alert)


func _build_ui() -> void:
	_alert_list = VBoxContainer.new()
	_alert_list.set_anchors_preset(Control.PRESET_FULL_RECT)
	_alert_list.add_theme_constant_override("separation", 2)
	_alert_list.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(_alert_list)


func _add_alert_entry(alert: Dictionary) -> void:
	var btn := Button.new()
	btn.text = alert.text
	btn.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	btn.custom_minimum_size = Vector2(240, 26)
	btn.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)

	var bg_color: Color
	var text_color: Color
	match alert.type:
		"critical":
			bg_color = Color(0.52, 0.12, 0.10, 0.88)
			text_color = Color(1.0, 0.82, 0.78, 1.0)
		"warning":
			bg_color = Color(0.48, 0.38, 0.10, 0.82)
			text_color = Color(1.0, 0.92, 0.62, 1.0)
		"info":
			bg_color = Color(0.18, 0.28, 0.38, 0.72)
			text_color = Color(0.82, 0.90, 1.0, 1.0)
		_:
			bg_color = Color(0.22, 0.21, 0.19, 0.62)
			text_color = RWTheme.TEXT_GRAY

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = bg_color.lightened(0.2)
	style.border_width_right = 3
	style.content_margin_left = 8
	style.content_margin_top = 2
	style.content_margin_right = 8
	style.content_margin_bottom = 2
	btn.add_theme_stylebox_override("normal", style)

	var hover_s: StyleBoxFlat = style.duplicate()
	hover_s.bg_color = bg_color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover_s)

	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_color.lightened(0.2))

	btn.tooltip_text = alert.text + "\n(" + "%.1f" % alert.age + " days ago)"
	_alert_list.add_child(btn)
