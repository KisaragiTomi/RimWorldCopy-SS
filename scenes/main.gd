extends Control

const MainMenuScene = preload("res://scenes/main_menu/main_menu.tscn")
const GameHUDScene = preload("res://scenes/game_hud/game_hud.tscn")
const WorldMapScene = preload("res://scenes/world_map/world_map.tscn")

var _current_scene: Control


func _ready() -> void:
	var win := get_window()
	if win:
		win.min_size = Vector2i(1100, 620)
	switch_to_game()


func switch_to_main_menu() -> void:
	_switch_scene(MainMenuScene.instantiate())
	GameState.current_screen = GameState.GameScreen.MAIN_MENU


func switch_to_game() -> void:
	var scene := GameHUDScene.instantiate()
	_switch_scene(scene)
	GameState.current_screen = GameState.GameScreen.PLAYING


func switch_to_world_map() -> void:
	_switch_scene(WorldMapScene.instantiate())
	GameState.current_screen = GameState.GameScreen.WORLD_MAP


func _switch_scene(new_scene: Control) -> void:
	UIManager.close_all()
	if _current_scene:
		_current_scene.queue_free()
	_current_scene = new_scene
	add_child(_current_scene)
