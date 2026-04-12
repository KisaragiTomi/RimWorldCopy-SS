extends Control

var _resource_vbox: VBoxContainer
var _expanded_categories := {}
var _category_containers: Dictionary = {}
var _refresh_timer: float = 0.0
const REFRESH_INTERVAL := 1.5

const RESOURCE_CATEGORIES: Dictionary = {
	"Materials": ["Steel", "Wood", "Stone", "Plasteel", "Jade", "Uranium"],
	"Metals": ["Silver", "Gold"],
	"Food": ["MealSimple", "MealFine", "RawFood", "Pemmican", "MealSurvival"],
	"Medicine": ["Medicine", "HerbalMedicine", "Glitterworld Medicine"],
	"Manufactured": ["Components", "AdvancedComponents", "Cloth", "Leather"],
	"Textiles": ["Synthread", "Devilstrand", "Hyperweave"],
}


func _ready() -> void:
	_build_readout()
	_refresh_counts()


func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= REFRESH_INTERVAL:
		_refresh_timer = 0.0
		_refresh_counts()


func _build_readout() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := RWTheme.make_stylebox_flat(Color(0.10, 0.095, 0.08, 0.85), Color(0.35, 0.33, 0.28, 0.5), 1)
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	_resource_vbox = VBoxContainer.new()
	_resource_vbox.add_theme_constant_override("separation", 1)
	scroll.add_child(_resource_vbox)

	var title := Label.new()
	title.text = "Resources"
	title.add_theme_font_size_override("font_size", RWTheme.FONT_SMALL)
	title.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	_resource_vbox.add_child(title)

	_resource_vbox.add_child(RWWidgets.create_separator())

	for cat_name: String in RESOURCE_CATEGORIES:
		_expanded_categories[cat_name] = true
		_add_category(cat_name, RESOURCE_CATEGORIES[cat_name])


func _add_category(cat_name: String, item_defs: Array) -> void:
	var header_btn := Button.new()
	header_btn.text = "\u25bc " + cat_name
	header_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header_btn.flat = true
	header_btn.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
	header_btn.add_theme_color_override("font_color", RWTheme.TEXT_GRAY)
	header_btn.add_theme_color_override("font_hover_color", RWTheme.TEXT_WHITE)
	_resource_vbox.add_child(header_btn)

	var item_container := VBoxContainer.new()
	item_container.add_theme_constant_override("separation", 0)
	item_container.name = cat_name + "_items"
	_resource_vbox.add_child(item_container)
	_category_containers[cat_name] = {"container": item_container, "items": item_defs}

	header_btn.pressed.connect(_toggle_category.bind(cat_name, header_btn, item_container))

	for def_name: String in item_defs:
		_add_resource_row(item_container, def_name, 0)


func _add_resource_row(parent: Control, res_name: String, count: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.custom_minimum_size.y = 20
	row.name = "row_" + res_name
	parent.add_child(row)

	var indent := Control.new()
	indent.custom_minimum_size.x = 12
	row.add_child(indent)

	var name_lbl := Label.new()
	name_lbl.text = res_name
	name_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
	name_lbl.add_theme_color_override("font_color", RWTheme.TEXT_WHITE)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)

	var count_lbl := Label.new()
	count_lbl.text = str(count)
	count_lbl.name = "count"
	count_lbl.add_theme_font_size_override("font_size", RWTheme.FONT_TINY)
	count_lbl.add_theme_color_override("font_color", RWTheme.TEXT_YELLOW)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_lbl.custom_minimum_size.x = 50
	row.add_child(count_lbl)


func _refresh_counts() -> void:
	var counts := _gather_item_counts()
	for cat_name: String in _category_containers:
		var cat_data: Dictionary = _category_containers[cat_name]
		var container: VBoxContainer = cat_data["container"]
		var items: Array = cat_data["items"]
		for def_name in items:
			var row: Node = container.get_node_or_null("row_" + str(def_name))
			if row == null:
				continue
			var count_node: Label = row.get_node_or_null("count") as Label
			if count_node:
				var total: int = counts.get(str(def_name), 0)
				count_node.text = str(total)


func _gather_item_counts() -> Dictionary:
	var counts: Dictionary = {}
	if ThingManager:
		for thing: Thing in ThingManager.things:
			if thing is Item:
				var it := thing as Item
				var key: String = it.def_name
				var prev: int = counts.get(key, 0)
				counts[key] = prev + it.stack_count
	return counts


func _toggle_category(cat_name: String, btn: Button, container: VBoxContainer) -> void:
	_expanded_categories[cat_name] = not _expanded_categories[cat_name]
	container.visible = _expanded_categories[cat_name]
	if _expanded_categories[cat_name]:
		btn.text = "\u25bc " + cat_name
	else:
		btn.text = "\u25b6 " + cat_name
