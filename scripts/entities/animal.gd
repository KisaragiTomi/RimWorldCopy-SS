class_name Animal
extends RefCounted

## A wild or tamed animal on the map.

signal position_changed(old_pos: Vector2i, new_pos: Vector2i)

var id: int = 0
var species: String = ""
var name_label: String = ""
var grid_pos: Vector2i = Vector2i.ZERO
var age: float = 1.0
var health: float = 1.0
var tamed: bool = false
var tamer_id: int = -1
var tame_progress: float = 0.0  # 0..1, reaches 1 = tamed
var bond_with: int = -1  # pawn id if bonded
var training: Dictionary = {}  # skill_name -> {level: int, progress: float}

var hunger: float = 1.0
var dead: bool = false

var path: Array[Vector2i] = []
var path_index: int = 0

static var _next_id: int = 1

const SPECIES_DATA: Dictionary = {
	"Squirrel": {"hp": 15, "speed": 1.2, "threat": "Harmless", "meat_yield": 10, "color": [0.6, 0.4, 0.2]},
	"Rat": {"hp": 10, "speed": 1.0, "threat": "Harmless", "meat_yield": 8, "color": [0.5, 0.45, 0.4]},
	"Deer": {"hp": 50, "speed": 1.1, "threat": "Harmless", "meat_yield": 40, "color": [0.55, 0.42, 0.28]},
	"Boar": {"hp": 40, "speed": 0.9, "threat": "Retaliates", "meat_yield": 35, "color": [0.45, 0.35, 0.25]},
	"Wolf": {"hp": 60, "speed": 1.3, "threat": "Predator", "meat_yield": 30, "color": [0.5, 0.5, 0.5]},
	"Bear": {"hp": 120, "speed": 0.8, "threat": "Predator", "meat_yield": 60, "color": [0.4, 0.3, 0.2]},
	"Muffalo": {"hp": 80, "speed": 0.7, "threat": "Retaliates", "meat_yield": 70, "color": [0.45, 0.38, 0.32]},
	"Thrumbo": {"hp": 300, "speed": 0.6, "threat": "Extreme", "meat_yield": 120, "color": [0.7, 0.7, 0.75]},
}


func _init(p_species: String = "Squirrel") -> void:
	id = _next_id
	_next_id += 1
	species = p_species
	name_label = p_species + "_" + str(id)
	var data: Dictionary = SPECIES_DATA.get(p_species, {}) as Dictionary
	health = float(data.get("hp", 20))


func set_pos(new_pos: Vector2i) -> void:
	var old := grid_pos
	grid_pos = new_pos
	position_changed.emit(old, new_pos)


func tick(map: MapData, rng: RandomNumberGenerator) -> void:
	if dead:
		return
	hunger -= 0.0002
	if hunger <= 0.0:
		dead = true
		return

	if rng.randf() < 0.03:
		_wander(map, rng)


func _wander(map: MapData, rng: RandomNumberGenerator) -> void:
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var dir: Vector2i = dirs[rng.randi_range(0, 3)]
	var target: Vector2i = grid_pos + dir * rng.randi_range(1, 3)
	target = target.clamp(Vector2i.ZERO, Vector2i(map.width - 1, map.height - 1))
	if map.in_bounds(target.x, target.y):
		var cell := map.get_cell(target.x, target.y)
		if cell and cell.is_passable():
			set_pos(target)


func get_color() -> Array:
	var data: Dictionary = SPECIES_DATA.get(species, {}) as Dictionary
	var c: Array = data.get("color", [0.5, 0.5, 0.5]) as Array
	return c


func attempt_tame(pawn_skill: int, rng: RandomNumberGenerator) -> bool:
	var data: Dictionary = SPECIES_DATA.get(species, {}) as Dictionary
	var threat: String = data.get("threat", "Harmless") as String
	var base_chance: float = 0.15 + pawn_skill * 0.03
	match threat:
		"Harmless":
			base_chance += 0.1
		"Retaliates":
			base_chance -= 0.05
		"Predator":
			base_chance -= 0.1
		"Extreme":
			base_chance -= 0.15
	base_chance = clampf(base_chance, 0.02, 0.7)
	if rng.randf() < base_chance:
		tame_progress += 0.35
		if tame_progress >= 1.0:
			tamed = true
			tame_progress = 1.0
			return true
	return false


func get_tame_difficulty() -> String:
	var data: Dictionary = SPECIES_DATA.get(species, {}) as Dictionary
	return data.get("threat", "Harmless") as String


func train(skill_name: String, trainer_skill: int, rng: RandomNumberGenerator) -> bool:
	if not tamed:
		return false
	var trainable := _get_trainable_skills()
	if skill_name not in trainable:
		return false

	if not training.has(skill_name):
		training[skill_name] = {"level": 0, "progress": 0.0}

	var t: Dictionary = training[skill_name]
	var chance: float = 0.15 + trainer_skill * 0.03
	if rng.randf() < chance:
		t["progress"] = t.get("progress", 0.0) + 0.25
		if t["progress"] >= 1.0:
			t["level"] = t.get("level", 0) + 1
			t["progress"] = 0.0
			return true
	return false


func has_training(skill_name: String) -> bool:
	return training.has(skill_name) and training[skill_name].get("level", 0) > 0


func _get_trainable_skills() -> Array[String]:
	var data: Dictionary = SPECIES_DATA.get(species, {}) as Dictionary
	var threat: String = data.get("threat", "Harmless") as String
	var skills: Array[String] = ["Obedience", "Release"]
	match threat:
		"Retaliates", "Predator", "Extreme":
			skills.append("Guard")
		"Harmless", "Retaliates":
			skills.append("Haul")
	if int(data.get("hp", 0)) >= 50:
		skills.append("Rescue")
	return skills


var meat_yield: int:
	get:
		return SPECIES_DATA.get(species, {}).get("meat_yield", 10)

var leather_yield: int:
	get:
		return roundi(meat_yield * 0.5)


func get_training_level(skill_name: String) -> int:
	if training.has(skill_name):
		return training[skill_name].get("level", 0)
	return 0


func get_training_progress(skill_name: String) -> float:
	if training.has(skill_name):
		return training[skill_name].get("progress", 0.0)
	return 0.0


func get_max_trainable() -> Array[String]:
	return _get_trainable_skills()


func get_trained_skills() -> Array[String]:
	var result: Array[String] = []
	for skill: String in training:
		if training[skill].get("level", 0) > 0:
			result.append(skill)
	return result


func is_fully_trained() -> bool:
	var trainable := _get_trainable_skills()
	for skill: String in trainable:
		if not has_training(skill):
			return false
	return true


func get_total_yield_value() -> float:
	return snappedf(float(meat_yield) * 1.0 + float(leather_yield) * 1.5, 0.1)

func get_training_completion_pct() -> float:
	var max_skills: Array[String] = get_max_trainable()
	if max_skills.is_empty():
		return 100.0
	return snappedf(float(get_trained_skills().size()) / float(max_skills.size()) * 100.0, 0.1)

func is_starving() -> bool:
	return hunger <= 0.05

func get_utility_score() -> float:
	var train_val := get_training_completion_pct() * 0.4
	var yield_val := minf(get_total_yield_value() / 100.0, 1.0) * 30.0
	var health_val := health * 30.0
	return snapped(train_val + yield_val + health_val, 0.1)

func get_care_demand() -> String:
	if is_starving() and health < 0.5:
		return "Critical"
	elif is_starving() or health < 0.3:
		return "High"
	elif hunger < 0.3 or health < 0.7:
		return "Moderate"
	return "Low"

func get_training_potential() -> String:
	var max_skills := get_max_trainable()
	var trained := get_trained_skills()
	if max_skills.is_empty():
		return "Untrainable"
	var remaining := max_skills.size() - trained.size()
	if remaining <= 0:
		return "Maxed"
	elif remaining <= 1:
		return "Near Complete"
	return "Developing"

func get_summary() -> Dictionary:
	return {
		"id": id,
		"species": species,
		"pos": [grid_pos.x, grid_pos.y],
		"health": snappedf(health, 0.1),
		"hunger": snappedf(hunger, 0.01),
		"tamed": tamed,
		"tame_progress": snappedf(tame_progress, 0.01),
		"training": training.duplicate(true),
		"trained_skills": get_trained_skills(),
		"trainable": get_max_trainable(),
		"fully_trained": is_fully_trained(),
		"dead": dead,
		"meat_yield": meat_yield,
		"leather_yield": leather_yield,
		"total_yield_value": get_total_yield_value(),
		"training_pct": get_training_completion_pct(),
		"starving": is_starving(),
		"utility_score": get_utility_score(),
		"care_demand": get_care_demand(),
		"training_potential": get_training_potential(),
	}
