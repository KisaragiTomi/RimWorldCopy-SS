extends Control

var _date_label: Label
var _time_label: Label
var _temp_label: Label
var _weather_label: Label
var _speed_buttons: Array[Button] = []
var _update_timer: float = 0.0

const SPEED_ICON_PATHS := [
	"res://assets/textures/ui/TimeSpeedButton_Pause.png",
	"res://assets/textures/ui/TimeSpeedButton_Normal.png",
	"res://assets/textures/ui/TimeSpeedButton_Fast.png",
	"res://assets/textures/ui/TimeSpeedButton_Superfast.png",
]


func _ready() -> void:
	_build_controls()
	GameState.time_speed_changed.connect(_on_speed_changed)


func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= 0.5:
		_update_timer = 0.0
		_sync_from_game()


func _sync_from_game() -> void:
	if GameState:
		_date_label.text = GameState.get_date_string()
		_time_label.text = GameState.get_time_string()
		_temp_label.text = "%.0f\u00b0C" % GameState.temperature

	if WeatherManager and WeatherManager.has_method("get_current_weather"):
		var weather: String = WeatherManager.get_current_weather()
		_weather_label.text = weather.capitalize() if not weather.is_empty() else "Clear"
	elif _weather_label:
		var season: String = GameState.season if GameState else "Spring"
		_weather_label.text = season


func _build_controls() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := RWTheme.make_stylebox_flat(Color(0.10, 0.095, 0.08, 0.90), RWTheme.BORDER_COLOR, 1)
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)

	_date_label = Label.new()
	_date_label.text = GameState.get_date_string()
	_date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_date_label.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	_date_label.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	vbox.add_child(_date_label)

	_time_label = Label.new()
	_time_label.text = GameState.get_time_string()
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_time_label.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
	_time_label.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
	vbox.add_child(_time_label)

	_temp_label = Label.new()
	_temp_label.text = "%.0f\u00b0C" % GameState.temperature
	_temp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_temp_label.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	_temp_label.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	vbox.add_child(_temp_label)

	_weather_label = Label.new()
	_weather_label.text = GameState.season if GameState else "Spring"
	_weather_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_weather_label.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
	_weather_label.add_theme_color_override("font_color", Color(0.6, 0.75, 0.85))
	vbox.add_child(_weather_label)

	vbox.add_child(RWWidgets.create_separator())

	var speed_row := HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 2)
	speed_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(speed_row)

	var speed_labels := ["||", ">", ">>", ">>>"]
	for i in range(4):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(52, 32)

		if ResourceLoader.exists(SPEED_ICON_PATHS[i]):
			btn.icon = load(SPEED_ICON_PATHS[i])
			btn.expand_icon = true
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		else:
			btn.text = speed_labels[i]
			btn.add_theme_font_size_override("font_size", 10)

		btn.pressed.connect(GameState.set_time_speed.bind(i))
		_apply_speed_button_style(btn, i == GameState.time_speed)
		speed_row.add_child(btn)
		_speed_buttons.append(btn)


func _apply_speed_button_style(btn: Button, active: bool) -> void:
	if active:
		btn.add_theme_stylebox_override("normal", RWTheme.make_texture_button_hover())
		btn.add_theme_stylebox_override("hover", RWTheme.make_texture_button_hover())
		btn.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	else:
		btn.add_theme_stylebox_override("normal", RWTheme.make_texture_button_normal())
		btn.add_theme_stylebox_override("hover", RWTheme.make_texture_button_hover())
		btn.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)


func _on_speed_changed(spd: int) -> void:
	for i in range(_speed_buttons.size()):
		_apply_speed_button_style(_speed_buttons[i], i == spd)
