extends Node

## Manages ambient loops and event-driven sound effects.
## Registered as autoload "AudioManager".

signal sfx_played(sfx_name: String)

var _ambient_player: AudioStreamPlayer
var _weather_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer

const SFX_POOL_SIZE := 8
const AMBIENT_BUS := "Ambient"
const SFX_BUS := "SFX"
const MUSIC_BUS := "Music"

var master_volume: float = 1.0
var ambient_volume: float = 0.6
var sfx_volume: float = 0.8
var music_volume: float = 0.5

var _current_ambient := ""
var _current_weather_sfx := ""
var _current_music := ""

var _sfx_defs: Dictionary = {
	"ui_click": {"volume": -6.0, "pitch": 1.0},
	"ui_open": {"volume": -8.0, "pitch": 0.9},
	"ui_close": {"volume": -8.0, "pitch": 1.1},
	"build_place": {"volume": -4.0, "pitch": 1.0},
	"build_complete": {"volume": -2.0, "pitch": 1.2},
	"designate": {"volume": -6.0, "pitch": 1.0},
	"draft": {"volume": -3.0, "pitch": 0.8},
	"undraft": {"volume": -5.0, "pitch": 1.0},
	"damage_hit": {"volume": -4.0, "pitch": 1.0},
	"pawn_down": {"volume": -2.0, "pitch": 0.7},
	"mental_break": {"volume": -1.0, "pitch": 0.6},
	"raid_siren": {"volume": 0.0, "pitch": 1.0},
	"trade_complete": {"volume": -4.0, "pitch": 1.1},
	"research_complete": {"volume": -3.0, "pitch": 1.3},
	"zone_place": {"volume": -6.0, "pitch": 1.0},
	"harvest": {"volume": -5.0, "pitch": 1.1},
	"mine": {"volume": -4.0, "pitch": 0.9},
	"eat": {"volume": -8.0, "pitch": 1.0},
	"door_open": {"volume": -6.0, "pitch": 1.0},
	"fire_ignite": {"volume": -3.0, "pitch": 0.9},
	"notification": {"volume": -5.0, "pitch": 1.0},
}

var _weather_ambient_map: Dictionary = {
	"Clear": "",
	"Rain": "rain_loop",
	"Drizzle": "rain_light_loop",
	"Snow": "wind_light_loop",
	"Thunderstorm": "thunder_loop",
	"Hail": "hail_loop",
	"Fog": "wind_light_loop",
	"HeatWave": "",
	"ColdSnap": "wind_heavy_loop",
}

var _time_ambient_map: Dictionary = {
	"day": "birds_loop",
	"night": "crickets_loop",
	"dawn": "birds_dawn_loop",
	"dusk": "crickets_loop",
}


func _ready() -> void:
	_setup_audio_buses()
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = AMBIENT_BUS
	_ambient_player.volume_db = -10.0
	add_child(_ambient_player)

	_weather_player = AudioStreamPlayer.new()
	_weather_player.bus = AMBIENT_BUS
	_weather_player.volume_db = -8.0
	add_child(_weather_player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	_music_player.volume_db = -12.0
	add_child(_music_player)

	for i: int in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_sfx_pool.append(player)

	if WeatherManager:
		WeatherManager.weather_changed.connect(_on_weather_changed)
	if TickManager:
		TickManager.date_changed.connect(_on_date_changed)
	if ColonyLog:
		ColonyLog.log_added.connect(_on_log_entry)


func _setup_audio_buses() -> void:
	var bus_count := AudioServer.bus_count
	var has_ambient := false
	var has_sfx := false
	var has_music := false
	for i: int in bus_count:
		match AudioServer.get_bus_name(i):
			AMBIENT_BUS: has_ambient = true
			SFX_BUS: has_sfx = true
			MUSIC_BUS: has_music = true

	if not has_ambient:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, AMBIENT_BUS)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	if not has_sfx:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, SFX_BUS)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	if not has_music:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, MUSIC_BUS)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")


func play_sfx(sfx_name: String) -> void:
	var def: Dictionary = _sfx_defs.get(sfx_name, {})
	var stream := _load_sfx_stream(sfx_name)
	if stream == null:
		sfx_played.emit(sfx_name)
		return

	var player := _get_free_sfx_player()
	if player == null:
		return
	player.stream = stream
	player.volume_db = def.get("volume", -6.0) + linear_to_db(sfx_volume)
	player.pitch_scale = def.get("pitch", 1.0) * randf_range(0.95, 1.05)
	player.play()
	sfx_played.emit(sfx_name)


func set_ambient(ambient_name: String) -> void:
	if ambient_name == _current_ambient:
		return
	_current_ambient = ambient_name
	if ambient_name.is_empty():
		_ambient_player.stop()
		return
	var stream := _load_ambient_stream(ambient_name)
	if stream:
		_ambient_player.stream = stream
		_ambient_player.play()


func set_weather_ambient(weather: String) -> void:
	var ambient: String = _weather_ambient_map.get(weather, "")
	if ambient == _current_weather_sfx:
		return
	_current_weather_sfx = ambient
	if ambient.is_empty():
		_weather_player.stop()
		return
	var stream := _load_ambient_stream(ambient)
	if stream:
		_weather_player.stream = stream
		_weather_player.play()


func play_music(track_name: String) -> void:
	if track_name == _current_music:
		return
	_current_music = track_name
	if track_name.is_empty():
		_music_player.stop()
		return
	var stream := _load_music_stream(track_name)
	if stream:
		_music_player.stream = stream
		_music_player.play()


func stop_all() -> void:
	_ambient_player.stop()
	_weather_player.stop()
	_music_player.stop()
	for p: AudioStreamPlayer in _sfx_pool:
		p.stop()


func _get_free_sfx_player() -> AudioStreamPlayer:
	for p: AudioStreamPlayer in _sfx_pool:
		if not p.playing:
			return p
	return _sfx_pool[0]


func _on_weather_changed(_old: String, new_weather: String) -> void:
	set_weather_ambient(new_weather)
	if new_weather == "Thunderstorm":
		play_sfx("notification")


func _on_date_changed(date: Dictionary) -> void:
	var hour: int = date.get("hour", 12)
	var period := "day"
	if hour >= 21 or hour < 5:
		period = "night"
	elif hour >= 5 and hour < 7:
		period = "dawn"
	elif hour >= 18 and hour < 21:
		period = "dusk"
	var target_ambient: String = str(_time_ambient_map.get(period, ""))
	set_ambient(target_ambient)


func _on_log_entry(entry: Dictionary) -> void:
	var category: String = entry.get("category", "")
	var severity: String = entry.get("severity", "info")
	match category:
		"Build":
			if "complete" in str(entry.get("text", "")).to_lower():
				play_sfx("build_complete")
			else:
				play_sfx("build_place")
		"Draft":
			if "undraft" in str(entry.get("text", "")).to_lower():
				play_sfx("undraft")
			else:
				play_sfx("draft")
		"Zone":
			play_sfx("zone_place")
		"Raid":
			play_sfx("raid_siren")
		"Research":
			play_sfx("research_complete")
		"Trade":
			play_sfx("trade_complete")
		"Combat":
			play_sfx("damage_hit")
		"Health":
			if severity == "critical":
				play_sfx("pawn_down")
		"MentalBreak":
			play_sfx("mental_break")
		"Fire":
			play_sfx("fire_ignite")
		_:
			if severity in ["critical", "warning"]:
				play_sfx("notification")


func _load_sfx_stream(sfx_name: String) -> AudioStream:
	var path := "res://audio/sfx/%s.ogg" % sfx_name
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	path = "res://audio/sfx/%s.wav" % sfx_name
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null


func _load_ambient_stream(ambient_name: String) -> AudioStream:
	var path := "res://audio/ambient/%s.ogg" % ambient_name
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null


func _load_music_stream(track_name: String) -> AudioStream:
	var path := "res://audio/music/%s.ogg" % track_name
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null


func _apply_ambient_volume() -> void:
	if _ambient_player:
		_ambient_player.volume_db = -10.0 + linear_to_db(ambient_volume)
	if _weather_player:
		_weather_player.volume_db = -8.0 + linear_to_db(ambient_volume)


func _apply_music_volume() -> void:
	if _music_player:
		_music_player.volume_db = -12.0 + linear_to_db(music_volume)


func get_sfx_count() -> int:
	return _sfx_defs.size()


func get_active_ambient() -> String:
	return _current_ambient


func get_active_weather_sfx() -> String:
	return _current_weather_sfx


func get_active_music() -> String:
	return _current_music


func is_any_playing() -> bool:
	if _ambient_player.playing:
		return true
	if _weather_player.playing:
		return true
	if _music_player.playing:
		return true
	for p: AudioStreamPlayer in _sfx_pool:
		if p.playing:
			return true
	return false


func get_bus_volume(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))


func set_bus_mute(bus_name: String, muted: bool) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, muted)


func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))


func set_ambient_volume(v: float) -> void:
	ambient_volume = clampf(v, 0.0, 1.0)
	_apply_ambient_volume()


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)


func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply_music_volume()
