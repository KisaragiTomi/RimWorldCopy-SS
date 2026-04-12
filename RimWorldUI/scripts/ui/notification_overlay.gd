class_name NotificationOverlay
extends CanvasLayer

## Shows recent colony log entries as floating notifications.
## Supports severity-based display duration, sound cue hooks, and pause on danger.

var _container: VBoxContainer
var _max_visible: int = 6
var _paused: bool = false
var total_notifications: int = 0

const SEVERITY_COLORS: Dictionary = {
	"info": Color(0.8, 0.8, 0.8, 0.9),
	"positive": Color(0.3, 0.9, 0.3, 0.9),
	"warning": Color(0.9, 0.8, 0.2, 0.9),
	"danger": Color(0.95, 0.25, 0.2, 0.9),
}

const SEVERITY_DURATION: Dictionary = {
	"info": 6.0,
	"positive": 8.0,
	"warning": 10.0,
	"danger": 14.0,
}

const SEVERITY_FONT_SIZE: Dictionary = {
	"info": 13,
	"positive": 14,
	"warning": 15,
	"danger": 16,
}

const MUTED_CATEGORIES: Array = []

signal danger_notification(message: String)


func _ready() -> void:
	layer = 10
	_container = VBoxContainer.new()
	_container.position = Vector2(20, 80)
	_container.add_theme_constant_override("separation", 4)
	add_child(_container)

	if ColonyLog:
		ColonyLog.log_added.connect(_on_log_added)


func set_paused(paused: bool) -> void:
	_paused = paused


func _on_log_added(entry: Dictionary) -> void:
	var severity: String = entry.get("severity", "info")
	var category: String = entry.get("category", "")
	var message: String = entry.get("message", "")

	if category in MUTED_CATEGORIES:
		return

	total_notifications += 1

	var label := Label.new()
	label.text = "[" + category + "] " + message
	var font_size: int = SEVERITY_FONT_SIZE.get(severity, 14)
	label.add_theme_font_size_override("font_size", font_size)

	var col: Color = SEVERITY_COLORS.get(severity, SEVERITY_COLORS["info"])
	label.add_theme_color_override("font_color", col)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

	label.modulate.a = 0.0
	_container.add_child(label)

	var display_time: float = SEVERITY_DURATION.get(severity, 8.0)
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(display_time)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)

	while _container.get_child_count() > _max_visible:
		var oldest := _container.get_child(0) as Control
		if oldest:
			_container.remove_child(oldest)
			oldest.queue_free()

	if severity == "danger":
		danger_notification.emit(message)


func get_visible_count() -> int:
	return _container.get_child_count() if _container else 0


func clear_all() -> void:
	if _container:
		for child: Node in _container.get_children():
			child.queue_free()


func get_notification_rate() -> float:
	if total_notifications <= 0:
		return 0.0
	return snappedf(float(total_notifications) / maxf(1.0, float(get_visible_count())), 0.01)

func is_at_capacity() -> bool:
	return get_visible_count() >= _max_visible

func get_fill_pct() -> float:
	if _max_visible <= 0:
		return 0.0
	return snappedf(float(get_visible_count()) / float(_max_visible) * 100.0, 0.1)


func get_dismissed_count() -> int:
	return maxi(0, total_notifications - get_visible_count())


func is_quiet() -> bool:
	return get_visible_count() == 0


func get_information_density() -> float:
	if _max_visible <= 0:
		return 0.0
	var visible := float(get_visible_count())
	return snapped(visible / float(_max_visible) * total_notifications / maxf(1.0, float(total_notifications)), 0.1)

func get_attention_demand() -> String:
	var rate := get_notification_rate()
	var fill := get_fill_pct()
	if fill >= 90.0 or rate > 5.0:
		return "Overwhelming"
	elif fill >= 50.0 or rate > 2.0:
		return "High"
	elif fill >= 20.0:
		return "Moderate"
	return "Low"

func get_signal_to_noise() -> float:
	if total_notifications <= 0:
		return 100.0
	var visible := get_visible_count()
	var dismissed := get_dismissed_count()
	if visible + dismissed <= 0:
		return 100.0
	return snapped(float(visible) / float(visible + dismissed) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"total_notifications": total_notifications,
		"visible": get_visible_count(),
		"paused": _paused,
		"max_visible": _max_visible,
		"at_capacity": is_at_capacity(),
		"notification_rate": get_notification_rate(),
		"fill_pct": get_fill_pct(),
		"dismissed": get_dismissed_count(),
		"is_quiet": is_quiet(),
		"information_density": get_information_density(),
		"attention_demand": get_attention_demand(),
		"signal_to_noise": get_signal_to_noise(),
		"notification_governance": get_notification_governance(),
		"user_attention_health": get_user_attention_health(),
		"information_flow_score": get_information_flow_score(),
	}

func get_notification_governance() -> String:
	var stn: float = get_signal_to_noise()
	var capacity: bool = is_at_capacity()
	if stn >= 70.0 and not capacity:
		return "Well-Managed"
	if not capacity:
		return "Adequate"
	return "Overloaded"

func get_user_attention_health() -> float:
	var demand: String = get_attention_demand()
	var density: float = get_information_density()
	var demand_val: float = 80.0 if demand == "High" else (50.0 if demand == "Medium" else 20.0)
	var score: float = 100.0 - demand_val * 0.5 - density * 0.3
	return snappedf(clampf(score, 0.0, 100.0), 0.1)

func get_information_flow_score() -> float:
	var rate: float = get_notification_rate()
	var stn: float = get_signal_to_noise()
	return snappedf(clampf(stn * 0.6 + (100.0 - rate * 10.0) * 0.4, 0.0, 100.0), 0.1)
