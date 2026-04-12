extends ColorRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://scenes/main_menu/vignette.gdshader")
	material = sm
