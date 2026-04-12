class_name Job
extends RefCounted

## A task for a pawn to execute. Contains target position and job type.

var job_def: String = ""
var target_pos: Vector2i = Vector2i(-1, -1)
var target_thing_id: int = -1
var max_ticks: int = -1
var started_tick: int = 0
var forced: bool = false
var meta_data: Dictionary = {}

func _init(def: String = "", target: Vector2i = Vector2i(-1, -1)) -> void:
	job_def = def
	target_pos = target
