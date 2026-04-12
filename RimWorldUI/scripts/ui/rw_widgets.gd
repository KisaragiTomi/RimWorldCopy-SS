class_name RWWidgets


static func create_label(text: String, font_size: int = RWTheme.FONT_SMALL, color: Color = RWTheme.TEXT_WHITE) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl


static func create_button(text: String, callback: Callable = Callable(), min_width: float = 0.0) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_stylebox_override("normal", RWTheme.make_texture_button_normal())
	btn.add_theme_stylebox_override("hover", RWTheme.make_texture_button_hover())
	btn.add_theme_stylebox_override("pressed", RWTheme.make_texture_button_pressed())
	btn.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	btn.add_theme_color_override("font_hover_color", RWTheme.TEXT_YELLOW)
	btn.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	if min_width > 0:
		btn.custom_minimum_size.x = min_width
	if callback.is_valid():
		btn.pressed.connect(callback)
	return btn


static func create_icon_button(icon: Texture2D, tooltip: String = "", sz: float = 32.0, callback: Callable = Callable()) -> Button:
	var btn := Button.new()
	btn.icon = icon
	btn.tooltip_text = tooltip
	btn.custom_minimum_size = Vector2(sz, sz)
	btn.add_theme_stylebox_override("normal", RWTheme.make_button_normal())
	btn.add_theme_stylebox_override("hover", RWTheme.make_button_hover())
	btn.add_theme_stylebox_override("pressed", RWTheme.make_button_pressed())
	if callback.is_valid():
		btn.pressed.connect(callback)
	return btn


static func create_fillable_bar(value: float, max_value: float, bar_color: Color, w: float = 200.0, h: float = 18.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = max_value
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(w, h)

	var bg_style := RWTheme.make_stylebox_flat(Color(0.1, 0.1, 0.1, 0.8))
	bg_style.content_margin_left = 0
	bg_style.content_margin_right = 0
	bg_style.content_margin_top = 0
	bg_style.content_margin_bottom = 0
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = bar_color
	bar.add_theme_stylebox_override("fill", fill_style)
	return bar


static func create_checkbox(text: String, checked: bool = false, callback: Callable = Callable()) -> CheckBox:
	var cb := CheckBox.new()
	cb.text = text
	cb.button_pressed = checked
	cb.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	cb.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	if callback.is_valid():
		cb.toggled.connect(callback)
	return cb


static func create_slider(value: float, min_val: float, max_val: float, w: float = 200.0, callback: Callable = Callable()) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = value
	slider.custom_minimum_size.x = w
	if callback.is_valid():
		slider.value_changed.connect(callback)
	return slider


static func create_separator(vertical: bool = false) -> Control:
	if vertical:
		var sep := VSeparator.new()
		sep.add_theme_color_override("separator", RWTheme.BORDER_COLOR)
		return sep
	else:
		var sep := HSeparator.new()
		sep.add_theme_color_override("separator", RWTheme.BORDER_COLOR)
		return sep


static func create_scroll_container(content: Control, sz: Vector2 = Vector2(400, 300)) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = sz
	scroll.add_child(content)
	return scroll


static func create_hbox(spacing: int = 4) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", spacing)
	return hbox


static func create_vbox(spacing: int = 2) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", spacing)
	return vbox


static func draw_tooltip(control: Control, text: String) -> void:
	control.tooltip_text = text
