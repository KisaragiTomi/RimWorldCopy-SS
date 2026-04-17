class_name Pawn
extends RefCounted

## Core pawn entity. Holds identity, stats, skills, needs, position.

signal position_changed(old_pos: Vector2i, new_pos: Vector2i)
signal need_changed(need_name: String, value: float)
signal job_changed(job_name: String)

var id: int = 0
var pawn_name: String = ""
var age: int = 25
var biological_age: int = 25
var birthday_day: int = 1  # day in quadrum (1-15)
var birthday_quadrum: String = "Aprimay"
var gender: String = "Male"

var grid_pos: Vector2i = Vector2i.ZERO
var facing: int = 2  # 0=N, 1=E, 2=S, 3=W

var drafted: bool = false
var downed: bool = false
var dead: bool = false

var skills: Dictionary = {}
var traits: PackedStringArray = []
var needs: Dictionary = {}
var work_priorities: Dictionary = {}
var schedule: Array[int] = []

var health: PawnHealth = null
var equipment: PawnEquipment = null
var thought_tracker: ThoughtSystem = null
var inventory: PawnInventory = null
var current_job_name: String = ""
var path: Array[Vector2i] = []
var path_index: int = 0

var backstory: Dictionary = {}  # {childhood, adulthood}
var mental_state: String = ""  # "" = sane, "Wander", "BingeEat", "Hide"
var mental_break_ticks_left: int = 0

const MINOR_BREAK_THRESHOLD := 0.15
const MAJOR_BREAK_THRESHOLD := 0.05

static var _next_id: int = 1


func _init() -> void:
	id = _next_id
	_next_id += 1
	health = PawnHealth.new(id)
	health.pawn_downed.connect(_on_downed)
	health.pawn_died.connect(_on_died)
	equipment = PawnEquipment.new()
	thought_tracker = ThoughtSystem.new()
	inventory = PawnInventory.new()
	_init_default_skills()
	_init_default_needs()
	_init_default_work_priorities()
	var rng := RandomNumberGenerator.new()
	rng.seed = id * 31 + 7
	traits = TraitSystem.assign_random_traits(rng, 2)
	age = rng.randi_range(18, 55)
	biological_age = age
	birthday_day = rng.randi_range(1, 15)
	var quadrums := ["Aprimay", "Jugust", "Septober", "Decembary"]
	birthday_quadrum = quadrums[rng.randi_range(0, 3)]
	backstory = BackstorySystem.assign_backstory(self, rng)


func _on_downed(_pid: int) -> void:
	downed = true
	current_job_name = ""

func _on_died(_pid: int) -> void:
	dead = true
	downed = true


func _init_default_skills() -> void:
	var skill_names: PackedStringArray = PackedStringArray([
		"Shooting", "Melee", "Construction", "Mining",
		"Cooking", "Plants", "Animals", "Crafting",
		"Artistic", "Medicine", "Social", "Intellectual"
	])
	for s: String in skill_names:
		skills[s] = {"level": 0, "passion": 0, "xp": 0.0}


var _need_decay_mod: float = 1.0

func _init_default_needs() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = id * 7919 + 31
	_need_decay_mod = rng.randf_range(0.8, 1.2)
	needs = {
		"Food": rng.randf_range(0.7, 1.0),
		"Rest": rng.randf_range(0.7, 1.0),
		"Joy": rng.randf_range(0.3, 0.6),
		"Mood": 0.6,
	}


func _init_default_work_priorities() -> void:
	if not DefDB:
		return
	var work_defs := DefDB.get_all_sorted("WorkTypeDef", "order")
	for wd: Dictionary in work_defs:
		var wname: String = wd.get("defName", "")
		if wd.get("alwaysEnabled", false):
			work_priorities[wname] = 1
		else:
			work_priorities[wname] = 3
	_init_default_schedule()


func _init_default_schedule() -> void:
	schedule.clear()
	for h: int in 24:
		if h >= 22 or h < 6:
			schedule.append(0)
		elif h >= 8 and h < 18:
			schedule.append(2)
		elif h >= 18 and h < 20:
			schedule.append(3)
		else:
			schedule.append(1)


func set_grid_pos(new_pos: Vector2i) -> void:
	var old := grid_pos
	if new_pos != old:
		var delta := new_pos - old
		if absi(delta.y) >= absi(delta.x):
			facing = 0 if delta.y < 0 else 2
		else:
			facing = 1 if delta.x > 0 else 3
	grid_pos = new_pos
	position_changed.emit(old, new_pos)


func get_skill_level(skill_name: String) -> int:
	if skills.has(skill_name):
		return skills[skill_name].get("level", 0)
	return 0


func set_skill_level(skill_name: String, level: int) -> void:
	if not skills.has(skill_name):
		skills[skill_name] = {"level": 0, "passion": 0, "xp": 0.0}
	skills[skill_name]["level"] = clampi(level, 0, 20)


func gain_xp(skill_name: String, amount: float) -> void:
	if not skills.has(skill_name):
		return
	var s: Dictionary = skills[skill_name]
	var passion: int = s.get("passion", 0)
	var multiplier: float = 1.0
	if passion == 1:
		multiplier = 1.5
	elif passion >= 2:
		multiplier = 2.0
	s["xp"] = s.get("xp", 0.0) + amount * multiplier
	var threshold: float = xp_for_level(s.get("level", 0))
	if s["xp"] >= threshold and s.get("level", 0) < 20:
		s["xp"] = s["xp"] - threshold
		s["level"] = s.get("level", 0) + 1


static func xp_for_level(level: int) -> float:
	return 1000.0 + level * 500.0


func get_xp_progress(skill_name: String) -> float:
	if not skills.has(skill_name):
		return 0.0
	var s: Dictionary = skills[skill_name]
	var threshold: float = xp_for_level(s.get("level", 0))
	if threshold <= 0.0:
		return 0.0
	return s.get("xp", 0.0) / threshold


func get_best_skill() -> String:
	var best: String = ""
	var best_lvl: int = -1
	for sk: String in skills:
		var lvl: int = skills[sk].get("level", 0)
		if lvl > best_lvl:
			best_lvl = lvl
			best = sk
	return best


func get_total_skill_levels() -> int:
	var total: int = 0
	for sk: String in skills:
		total += skills[sk].get("level", 0)
	return total


func get_passion_skill_count() -> int:
	var count: int = 0
	for sk: String in skills:
		if skills[sk].get("passion", 0) > 0:
			count += 1
	return count

func get_avg_skill_level() -> float:
	if skills.is_empty():
		return 0.0
	var total: float = 0.0
	for sk: String in skills:
		total += float(skills[sk].get("level", 0))
	return snappedf(total / float(skills.size()), 0.01)

func get_max_xp_skill() -> String:
	var best: String = ""
	var best_xp: float = 0.0
	for sk: String in skills:
		var xp: float = skills[sk].get("xp", 0.0)
		if xp > best_xp:
			best_xp = xp
			best = sk
	return best


func get_highest_skill() -> String:
	var best: String = ""
	var best_lvl: int = 0
	for sk: String in skills:
		var lvl: int = int(skills[sk].get("level", 0))
		if lvl > best_lvl:
			best_lvl = lvl
			best = sk
	return best


func get_skill_versatility() -> float:
	if skills.is_empty():
		return 0.0
	var above_avg := 0
	var avg := get_avg_skill_level()
	for sk: String in skills:
		if float(skills[sk].get("level", 0)) >= avg:
			above_avg += 1
	return snapped(float(above_avg) / float(skills.size()) * 100.0, 0.1)

func get_growth_trajectory() -> String:
	var passions := get_passion_skill_count()
	var avg := get_avg_skill_level()
	if passions >= 3 and avg >= 8.0:
		return "Expert"
	elif passions >= 2 or avg >= 6.0:
		return "Developing"
	elif passions >= 1:
		return "Promising"
	return "Stagnant"

func get_specialization_depth() -> float:
	if skills.is_empty():
		return 0.0
	var highest := 0
	var avg := get_avg_skill_level()
	for sk: String in skills:
		var lvl: int = int(skills[sk].get("level", 0))
		highest = maxi(highest, lvl)
	return snapped(float(highest) - avg, 0.1)

func get_skill_summary() -> Dictionary:
	return {
		"total_skills": skills.size(),
		"total_levels": get_total_skill_levels(),
		"avg_level": get_avg_skill_level(),
		"passion_count": get_passion_skill_count(),
		"highest_skill": get_highest_skill(),
		"max_xp_skill": get_max_xp_skill(),
		"skill_versatility": get_skill_versatility(),
		"growth_trajectory": get_growth_trajectory(),
		"specialization_depth": get_specialization_depth(),
		"skill_ecosystem_health": get_skill_ecosystem_health(),
		"education_governance": get_education_governance(),
		"pawn_maturity_index": get_pawn_maturity_index(),
	}

func get_skill_ecosystem_health() -> float:
	var versatility := get_skill_versatility()
	var traj := get_growth_trajectory()
	var t_val: float = 90.0 if traj == "Expert" else (65.0 if traj == "Developing" else (40.0 if traj == "Promising" else 15.0))
	var depth := get_specialization_depth()
	return snapped((versatility + t_val + minf(depth * 10.0, 100.0)) / 3.0, 0.1)

func get_education_governance() -> String:
	var eco := get_skill_ecosystem_health()
	var mat := get_pawn_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif skills.size() > 0:
		return "Nascent"
	return "Dormant"

func get_pawn_maturity_index() -> float:
	var avg := get_avg_skill_level()
	var passions := float(get_passion_skill_count())
	var depth := get_specialization_depth()
	return snapped((avg * 5.0 + passions * 15.0 + depth * 10.0) / 3.0, 0.1)


func get_need(need_name: String) -> float:
	return needs.get(need_name, 0.0)


func set_need(need_name: String, value: float) -> void:
	needs[need_name] = clampf(value, 0.0, 1.0)
	need_changed.emit(need_name, value)


func tick_needs() -> void:
	set_need("Food", get_need("Food") - 0.02 * _need_decay_mod)
	set_need("Rest", get_need("Rest") - 0.03 * _need_decay_mod)
	set_need("Joy", get_need("Joy") - 0.015 * _need_decay_mod)
	if thought_tracker:
		thought_tracker.tick()
	_recalc_mood()


func _recalc_mood() -> void:
	var base: float = 0.5
	var food := get_need("Food")
	var rest := get_need("Rest")
	var joy := get_need("Joy")

	var food_bonus: float = food * 0.15
	var rest_bonus: float = rest * 0.15
	var joy_bonus: float = joy * 0.1

	var food_penalty: float = 0.0
	if food < 0.25:
		food_penalty = (0.25 - food) * 1.2
	var rest_penalty: float = 0.0
	if rest < 0.25:
		rest_penalty = (0.25 - rest) * 0.8
	var joy_penalty: float = 0.0
	if joy < 0.2:
		joy_penalty = (0.2 - joy) * 0.4

	var temp_penalty: float = 0.0
	if GameState:
		var t: float = GameState.temperature
		if t < -10.0:
			temp_penalty = minf((-10.0 - t) * 0.01, 0.15)
		elif t > 40.0:
			temp_penalty = minf((t - 40.0) * 0.01, 0.15)

	var weather_penalty: float = 0.0
	if WeatherManager:
		weather_penalty = absf(minf(0.0, WeatherManager.get_mood_effect()))

	var trait_mood: float = TraitSystem.get_mood_modifier(traits)
	var thought_mood: float = thought_tracker.get_total_mood() if thought_tracker else 0.0

	var mood := base + food_bonus + rest_bonus + joy_bonus + trait_mood + thought_mood - food_penalty - rest_penalty - joy_penalty - temp_penalty - weather_penalty
	set_need("Mood", mood)


func check_mental_break(rng: RandomNumberGenerator) -> void:
	var mood := get_need("Mood")
	if not mental_state.is_empty():
		return
	var break_mod: float = TraitSystem.get_mental_break_modifier(traits)
	if mood < MAJOR_BREAK_THRESHOLD and rng.randf() < 0.04 * break_mod:
		_start_mental_break(rng, true)
	elif mood < MINOR_BREAK_THRESHOLD and rng.randf() < 0.015 * break_mod:
		_start_mental_break(rng, false)


func _start_mental_break(rng: RandomNumberGenerator, major: bool) -> void:
	var options: PackedStringArray
	if major:
		options = PackedStringArray(["Wander", "BingeEat", "Hide", "Berserk", "Tantrum"])
	else:
		options = PackedStringArray(["Wander", "Hide", "SadWander", "InsultingSpree"])
	mental_state = options[rng.randi_range(0, options.size() - 1)]
	mental_break_ticks_left = rng.randi_range(1800, 5400)
	if thought_tracker:
		thought_tracker.add_thought("MentalBreak")


func end_mental_break() -> void:
	mental_state = ""
	mental_break_ticks_left = 0
	if thought_tracker:
		thought_tracker.add_thought("Catharsis")


func tick_mental_break() -> void:
	if mental_state.is_empty():
		return
	mental_break_ticks_left -= 1
	if mental_break_ticks_left <= 0:
		end_mental_break()


func is_in_mental_break() -> bool:
	return not mental_state.is_empty()


func is_capable_of(work_type: String) -> bool:
	if work_priorities.get(work_type, 0) == 0:
		return false
	var wd := DefDB.get_def("WorkTypeDef", work_type) if DefDB else {}
	var needed_skill: String = wd.get("skillNeeded", "")
	if needed_skill.is_empty():
		return true
	return skills.has(needed_skill)


func get_work_priority(work_type: String) -> int:
	return work_priorities.get(work_type, 0)


func has_path() -> bool:
	return path.size() > 0 and path_index < path.size()


func next_path_step() -> Vector2i:
	if not has_path():
		return grid_pos
	var step := path[path_index]
	path_index += 1
	return step


func clear_path() -> void:
	path.clear()
	path_index = 0


func to_dict() -> Dictionary:
	return {
		"id": id, "name": pawn_name, "age": age, "gender": gender,
		"pos_x": grid_pos.x, "pos_y": grid_pos.y, "facing": facing,
		"drafted": drafted, "skills": skills,
		"needs": needs, "work_priorities": work_priorities,
		"traits": Array(traits),
	}
