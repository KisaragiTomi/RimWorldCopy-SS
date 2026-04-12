class_name EventLogPanel
extends PanelContainer

## UI panel for displaying colony event log entries with filtering and search.

var _log_container: VBoxContainer
var _scroll: ScrollContainer
var _header: HBoxContainer
var _filter_btn: OptionButton
var _search_field: LineEdit
var _clear_btn: Button
var _max_visible: int = 100
var _active_filter: String = "All"
var _search_text: String = ""
var _entries: Array[Dictionary] = []
var total_displayed: int = 0

const SEVERITY_COLORS: Dictionary = {
	"info": Color(0.8, 0.8, 0.8),
	"warning": Color(1.0, 0.8, 0.2),
	"danger": Color(1.0, 0.3, 0.3),
	"positive": Color(0.3, 1.0, 0.3),
}

const SEVERITY_ICONS: Dictionary = {
	"info": "[i] ",
	"warning": "[!] ",
	"danger": "[X] ",
	"positive": "[+] ",
}

const FILTER_CATEGORIES: PackedStringArray = [
	"All", "Combat", "Work", "Social", "Visitors", "Prisoner", "Alert", "Trade",
]


func _ready() -> void:
	_setup_ui()
	if ColonyLog:
		ColonyLog.log_added.connect(_on_log_added)


func _setup_ui() -> void:
	custom_minimum_size = Vector2(380, 300)

	var vbox := VBoxContainer.new()
	add_child(vbox)

	_header = HBoxContainer.new()
	vbox.add_child(_header)

	_filter_btn = OptionButton.new()
	for cat: String in FILTER_CATEGORIES:
		_filter_btn.add_item(cat)
	_filter_btn.item_selected.connect(_on_filter_changed)
	_header.add_child(_filter_btn)

	_search_field = LineEdit.new()
	_search_field.placeholder_text = "Search..."
	_search_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_field.text_changed.connect(_on_search_changed)
	_header.add_child(_search_field)

	_clear_btn = Button.new()
	_clear_btn.text = "Clear"
	_clear_btn.pressed.connect(_clear_log)
	_header.add_child(_clear_btn)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_scroll)

	_log_container = VBoxContainer.new()
	_log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_log_container)


func _on_filter_changed(idx: int) -> void:
	_active_filter = FILTER_CATEGORIES[idx] if idx < FILTER_CATEGORIES.size() else "All"
	_rebuild_display()


func _on_search_changed(text: String) -> void:
	_search_text = text.to_lower()
	_rebuild_display()


func _clear_log() -> void:
	_entries.clear()
	for child: Node in _log_container.get_children():
		child.queue_free()


func _rebuild_display() -> void:
	for child: Node in _log_container.get_children():
		child.queue_free()

	var filtered: Array[Dictionary] = []
	for e: Dictionary in _entries:
		if _passes_filter(e):
			filtered.append(e)

	var start_idx: int = maxi(0, filtered.size() - _max_visible)
	for i: int in range(start_idx, filtered.size()):
		_add_label(filtered[i])


func _passes_filter(entry: Dictionary) -> bool:
	if _active_filter != "All" and entry.get("category", "") != _active_filter:
		return false
	if _search_text != "" and _search_text not in entry.get("message", "").to_lower():
		return false
	return true


func _on_log_added(entry: Dictionary) -> void:
	_entries.append(entry)
	if _entries.size() > 500:
		_entries = _entries.slice(_entries.size() - 500)

	if _passes_filter(entry):
		_add_label(entry)
		total_displayed += 1

		while _log_container.get_child_count() > _max_visible:
			var old: Node = _log_container.get_child(0)
			_log_container.remove_child(old)
			old.queue_free()

		_scroll_to_bottom()


func _add_label(entry: Dictionary) -> void:
	var label := Label.new()
	var severity: String = entry.get("severity", "info")
	var color: Color = SEVERITY_COLORS.get(severity, Color.WHITE)
	var icon: String = SEVERITY_ICONS.get(severity, "")
	var hour: int = entry.get("hour", 0)
	var day: int = entry.get("day", 0)
	var message: String = entry.get("message", "")

	label.text = "%sD%d %02dh %s" % [icon, day, hour, message]
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_container.add_child(label)


func get_displayed_count() -> int:
	return _log_container.get_child_count() if _log_container else 0


func get_active_filters() -> Array[String]:
	var result: Array[String] = []
	if has_meta("active_filters"):
		var filters: Array = get_meta("active_filters") as Array
		for f: String in filters:
			result.append(f)
	return result


func get_filter_count() -> int:
	return get_active_filters().size()


func is_at_capacity() -> bool:
	return get_displayed_count() >= _max_visible


func get_entry_count() -> int:
	return _entries.size()

func get_severity_breakdown() -> Dictionary:
	var result: Dictionary = {}
	for e: Dictionary in _entries:
		var sev: String = e.get("severity", "info")
		result[sev] = result.get(sev, 0) + 1
	return result

func get_danger_ratio() -> float:
	if _entries.is_empty():
		return 0.0
	var danger: int = 0
	for e: Dictionary in _entries:
		if e.get("severity", "") == "danger":
			danger += 1
	return snappedf(float(danger) / float(_entries.size()) * 100.0, 0.1)

func get_information_overload() -> String:
	var total := get_entry_count()
	var danger := get_danger_ratio()
	if total > _max_visible * 2 and danger > 30.0:
		return "Critical"
	elif is_at_capacity():
		return "High"
	elif total > _max_visible / 2:
		return "Moderate"
	return "Low"

func get_event_velocity() -> float:
	if _entries.is_empty():
		return 0.0
	return snapped(float(_entries.size()) / maxf(float(_max_visible), 1.0) * 100.0, 0.1)

func get_narrative_clarity() -> String:
	var filters := get_filter_count()
	var danger := get_danger_ratio()
	if filters > 0 and danger < 20.0:
		return "Clear"
	elif danger < 40.0:
		return "Readable"
	return "Noisy"

func get_panel_status() -> Dictionary:
	return {
		"displayed": get_displayed_count(),
		"max_visible": _max_visible,
		"visible": visible,
		"active_filter_count": get_filter_count(),
		"at_capacity": is_at_capacity(),
		"total_entries": get_entry_count(),
		"severity_breakdown": get_severity_breakdown(),
		"danger_ratio_pct": get_danger_ratio(),
		"information_overload": get_information_overload(),
		"event_velocity": get_event_velocity(),
		"narrative_clarity": get_narrative_clarity(),
		"log_ecosystem_health": get_log_ecosystem_health(),
		"information_governance": get_information_governance(),
		"observability_maturity_index": get_observability_maturity_index(),
	}


func get_log_ecosystem_health() -> float:
	var overload := get_information_overload()
	var o_val: float = 90.0 if overload == "Low" else (60.0 if overload == "Moderate" else 25.0)
	var velocity := minf(get_event_velocity(), 100.0)
	var clarity := get_narrative_clarity()
	var c_val: float = 90.0 if clarity == "Clear" else (60.0 if clarity == "Readable" else 25.0)
	return snapped((o_val + velocity + c_val) / 3.0, 0.1)

func get_information_governance() -> String:
	var eco := get_log_ecosystem_health()
	var mat := get_observability_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_entry_count() > 0:
		return "Nascent"
	return "Dormant"

func get_observability_maturity_index() -> float:
	var filters := minf(float(get_filter_count()) * 25.0, 100.0)
	var danger_inv := maxf(100.0 - get_danger_ratio(), 0.0)
	var entries := minf(float(get_entry_count()) / maxf(_max_visible, 1.0) * 100.0, 100.0)
	return snapped((filters + danger_inv + entries) / 3.0, 0.1)

func _scroll_to_bottom() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	_scroll.scroll_vertical = 99999
