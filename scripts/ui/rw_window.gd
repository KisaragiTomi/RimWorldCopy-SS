class_name RWWindow
extends PanelContainer

signal window_closed

@export var window_title: String = ""
@export var show_close_x: bool = true
@export var show_close_button: bool = false
@export var absorb_input: bool = true
@export var force_pause: bool = false
@export var draggable: bool = true

var _dragging := false
var _drag_offset := Vector2.ZERO

const CLOSE_ICON_PATH := "res://assets/textures/ui/CloseX.png"


func _ready() -> void:
	_apply_style()
	if show_close_x:
		_add_close_x()
	_animate_open()


func _apply_style() -> void:
	var panel := RWTheme.make_window_panel()
	panel.content_margin_left = RWTheme.MARGIN_WINDOW
	panel.content_margin_top = RWTheme.MARGIN_WINDOW
	panel.content_margin_right = RWTheme.MARGIN_WINDOW
	panel.content_margin_bottom = RWTheme.MARGIN_WINDOW
	add_theme_stylebox_override("panel", panel)


func _add_close_x() -> void:
	var btn := Button.new()
	btn.flat = true
	btn.pressed.connect(_on_close)
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.position = Vector2(-30, 4)
	btn.size = Vector2(26, 26)
	btn.tooltip_text = "Close"

	if ResourceLoader.exists(CLOSE_ICON_PATH):
		btn.icon = load(CLOSE_ICON_PATH)
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		btn.text = "X"
		btn.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
		btn.add_theme_color_override("font_hover_color", RWTheme.TEXT_WHITE)
		btn.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)

	add_child(btn)


func _animate_open() -> void:
	modulate.a = 0.0
	scale = Vector2(0.95, 0.95)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)


func _on_close() -> void:
	window_closed.emit()
	close()


func close() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.1)
	tween.chain().tween_callback(func(): UIManager.close_window(self))


func _gui_input(event: InputEvent) -> void:
	if not draggable:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_drag_offset = event.position
			else:
				_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		position += event.relative
