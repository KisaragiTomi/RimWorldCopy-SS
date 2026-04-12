extends Node

## Drives all game systems on a fixed tick rate.
## Registered as autoload "TickManager".
##
## Speed mapping:
##   0 = paused
##   1 = normal  (1 tick/frame)
##   2 = fast    (3 ticks/frame)
##   3 = ultra   (6 ticks/frame)

signal tick(current_tick: int)
signal rare_tick(current_tick: int)       # every 250 ticks (~4 sec at 60fps)
signal long_tick(current_tick: int)       # every 2000 ticks (~33 sec)
signal speed_changed(new_speed: int)
signal date_changed(date: Dictionary)

const RARE_INTERVAL := 250
const LONG_INTERVAL := 2000
const TICKS_PER_HOUR := 250
const HOURS_PER_DAY := 24
const DAYS_PER_QUADRUM := 15
const QUADRUMS := ["Aprimay", "Jugust", "Septober", "Decembary"]

var current_tick: int = 0
var speed: int = 1
var paused: bool = false

var year: int = 5500
var quadrum_index: int = 0
var day: int = 1
var hour: int = 6

var _ticks_per_frame := [0, 1, 3, 6]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if paused or speed == 0:
		return
	var count: int = _ticks_per_frame[clampi(speed, 0, 3)]
	for i: int in count:
		_do_tick()


func set_speed(spd: int) -> void:
	speed = clampi(spd, 0, 3)
	paused = speed == 0
	speed_changed.emit(speed)
	if GameState:
		GameState.time_speed = speed
		GameState.time_speed_changed.emit(speed)


func toggle_pause() -> void:
	if paused:
		set_speed(1)
	else:
		set_speed(0)


func get_date() -> Dictionary:
	return {
		"year": year,
		"quadrum": QUADRUMS[quadrum_index],
		"day": day,
		"hour": hour,
	}


func get_date_string() -> String:
	return "%d %s, %d" % [day, QUADRUMS[quadrum_index], year]


func get_time_string() -> String:
	return "%02d:00" % hour


func _do_tick() -> void:
	current_tick += 1
	tick.emit(current_tick)

	if current_tick % TICKS_PER_HOUR == 0:
		_advance_hour()

	if current_tick % RARE_INTERVAL == 0:
		rare_tick.emit(current_tick)

	if current_tick % LONG_INTERVAL == 0:
		long_tick.emit(current_tick)

func _advance_hour() -> void:
	hour += 1
	if hour >= HOURS_PER_DAY:
		hour = 0
		_advance_day()
	_sync_game_state()
	date_changed.emit(get_date())


func _advance_day() -> void:
	day += 1
	if day > DAYS_PER_QUADRUM:
		day = 1
		quadrum_index += 1
		if quadrum_index >= QUADRUMS.size():
			quadrum_index = 0
			year += 1


func _sync_game_state() -> void:
	if GameState:
		GameState.game_date = get_date()
