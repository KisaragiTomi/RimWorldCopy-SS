extends Node

## Manages wild and tamed animals on the map.
## Registered as autoload "AnimalManager".

var animals: Array[Animal] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = randi()
	if TickManager:
		TickManager.tick.connect(_on_tick)
		TickManager.long_tick.connect(_on_long_tick)


func spawn_animal(species: String, pos: Vector2i) -> Animal:
	var a := Animal.new(species)
	a.set_pos(pos)
	animals.append(a)
	return a


func spawn_wildlife(map: MapData, count: int = 15) -> void:
	var wildlife := ["Squirrel", "Squirrel", "Rat", "Deer", "Deer", "Boar", "Muffalo", "Wolf"]
	for i: int in count:
		var species: String = wildlife[_rng.randi_range(0, wildlife.size() - 1)]
		var x: int = _rng.randi_range(10, map.width - 10)
		var y: int = _rng.randi_range(10, map.height - 10)
		if map.in_bounds(x, y):
			var cell := map.get_cell(x, y)
			if cell and cell.is_passable():
				spawn_animal(species, Vector2i(x, y))


func _on_tick(_tick: int) -> void:
	var map: MapData = GameState.get_map() if GameState else null
	if map == null:
		return
	for a: Animal in animals:
		a.tick(map, _rng)


func _on_long_tick(_tick: int) -> void:
	var i := animals.size() - 1
	while i >= 0:
		if animals[i].dead:
			animals.remove_at(i)
		i -= 1

	var map: MapData = GameState.get_map() if GameState else null
	if map and animals.size() < 10 and _rng.randf() < 0.2:
		spawn_wildlife(map, _rng.randi_range(2, 5))


func get_hostile_animals() -> Array[Animal]:
	var result: Array[Animal] = []
	for a: Animal in animals:
		if a.has_method("is_hostile") and a.is_hostile():
			result.append(a)
		elif a.has_meta("manhunter") and a.get_meta("manhunter"):
			result.append(a)
	return result


func get_tamed_animals() -> Array[Animal]:
	var result: Array[Animal] = []
	for a: Animal in animals:
		if a.tamed:
			result.append(a)
	return result


func get_dominant_species() -> String:
	var counts: Dictionary = {}
	for a: Animal in animals:
		counts[a.species] = counts.get(a.species, 0) + 1
	var best: String = ""
	var best_c: int = 0
	for sp: String in counts:
		if counts[sp] > best_c:
			best_c = counts[sp]
			best = sp
	return best


func get_unique_species_count() -> int:
	var species: Dictionary = {}
	for a: Animal in animals:
		species[a.species] = true
	return species.size()


func get_wild_animal_count() -> int:
	return animals.size() - get_tamed_animals().size()


func get_tamed_ratio() -> float:
	if animals.is_empty():
		return 0.0
	return snappedf(float(get_tamed_animals().size()) / float(animals.size()) * 100.0, 0.1)


func get_herd_stability() -> String:
	var tamed := get_tamed_animals().size()
	var wild := get_wild_animal_count()
	var ratio := get_tamed_ratio()
	if ratio >= 60.0 and tamed >= 3:
		return "Thriving"
	elif ratio >= 30.0:
		return "Growing"
	elif tamed >= 1:
		return "Fragile"
	return "Wild"

func get_biodiversity_index() -> float:
	if animals.is_empty():
		return 0.0
	var counts: Dictionary = {}
	for a: Animal in animals:
		counts[a.species] = counts.get(a.species, 0) + 1
	var total := float(animals.size())
	var entropy := 0.0
	for sp: String in counts:
		var p := float(counts[sp]) / total
		if p > 0.0:
			entropy -= p * log(p) / log(2.0)
	return snapped(entropy, 0.01)

func get_domestication_potential() -> float:
	var wild := get_wild_animal_count()
	var unique := get_unique_species_count()
	if wild <= 0:
		return 0.0
	return snapped(float(unique) * float(wild) / 10.0, 0.1)

func get_summary() -> Dictionary:
	var by_species: Dictionary = {}
	for a: Animal in animals:
		by_species[a.species] = by_species.get(a.species, 0) + 1
	return {
		"total": animals.size(),
		"by_species": by_species,
		"tamed": get_tamed_animals().size(),
		"dominant_species": get_dominant_species(),
		"unique_species": get_unique_species_count(),
		"wild_count": get_wild_animal_count(),
		"tamed_ratio_pct": get_tamed_ratio(),
		"herd_stability": get_herd_stability(),
		"biodiversity_index": get_biodiversity_index(),
		"domestication_potential": get_domestication_potential(),
		"livestock_value_rating": get_livestock_value_rating(),
		"ecological_balance": get_ecological_balance(),
		"fauna_management_score": get_fauna_management_score(),
	}

func get_livestock_value_rating() -> String:
	var tamed := get_tamed_animals().size()
	var species := get_unique_species_count()
	if tamed >= 10 and species >= 3:
		return "High Value"
	elif tamed >= 5:
		return "Moderate Value"
	elif tamed > 0:
		return "Low Value"
	return "None"

func get_ecological_balance() -> float:
	var wild := get_wild_animal_count()
	var total := animals.size()
	if total <= 0:
		return 0.0
	return snappedf(float(wild) / float(total) * 100.0, 0.1)

func get_fauna_management_score() -> float:
	var ratio := get_tamed_ratio()
	var biodiversity := get_biodiversity_index()
	return snapped(ratio * biodiversity / 100.0, 0.1)
