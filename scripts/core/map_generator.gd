class_name MapGenerator
extends RefCounted

## Generates terrain for a MapData instance.
## Replicates RimWorld's GenStep pipeline:
##   elevation noise -> fertility noise -> terrain assignment -> caves -> ores

var map: MapData
var seed: int
var mountain_density: float = 0.35

var _noise_elev: Noise2D
var _noise_fert: Noise2D
var _noise_cave: Noise2D
var _noise_ore: Noise2D
var _noise_detail: Noise2D
var _rng: RandomNumberGenerator

var _elevation: PackedFloat32Array
var _fertility: PackedFloat32Array


func _init(m: MapData, gen_seed: int = 42) -> void:
	map = m
	seed = gen_seed
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed
	_noise_elev = Noise2D.new(seed)
	_noise_fert = Noise2D.new(seed + 1000)
	_noise_cave = Noise2D.new(seed + 2000)
	_noise_ore = Noise2D.new(seed + 3000)
	_noise_detail = Noise2D.new(seed + 4000)
	_elevation = PackedFloat32Array()
	_fertility = PackedFloat32Array()
	_elevation.resize(map.width * map.height)
	_fertility.resize(map.width * map.height)


func generate() -> void:
	_gen_elevation()
	_gen_fertility()
	_assign_terrain()
	_gen_caves()
	_gen_ores()
	map.map_generated.emit()


func _gen_elevation() -> void:
	var w := map.width
	var h := map.height
	var elev_min: float = 999.0
	var elev_max: float = -999.0

	for y: int in h:
		for x: int in w:
			var scale: float = 0.012
			var e: float = _noise_elev.fbm(x * scale, y * scale, 6, 2.0, 0.5)
			var detail: float = _noise_detail.fbm(x * 0.04, y * 0.04, 4, 2.0, 0.45)
			e = e * 0.7 + detail * 0.3
			_elevation[y * w + x] = e
			elev_min = minf(elev_min, e)
			elev_max = maxf(elev_max, e)

	var inv_range: float = 1.0 / maxf(elev_max - elev_min, 0.0001)
	for i: int in _elevation.size():
		var norm: float = (_elevation[i] - elev_min) * inv_range
		norm = pow(norm, 1.2 + mountain_density * 0.3)

		var x: int = i % w
		var y: int = i / w
		var edge_dist: float = float(mini(mini(x, w - 1 - x), mini(y, h - 1 - y)))
		var edge_fade: float = clampf(edge_dist / 15.0, 0.0, 1.0)
		norm *= edge_fade

		_elevation[i] = norm
		map.cells[i].elevation = norm
		map.cells[i].is_mountain = norm >= 0.70


func _gen_fertility() -> void:
	var w := map.width
	var h := map.height
	var fert_min: float = 999.0
	var fert_max: float = -999.0

	for y: int in h:
		for x: int in w:
			var f: float = _noise_fert.fbm(x * 0.018, y * 0.018, 5, 2.0, 0.5)
			_fertility[y * w + x] = f
			fert_min = minf(fert_min, f)
			fert_max = maxf(fert_max, f)

	var inv_range: float = 1.0 / maxf(fert_max - fert_min, 0.0001)
	for i: int in _fertility.size():
		var norm: float = (_fertility[i] - fert_min) * inv_range
		if map.cells[i].is_mountain:
			norm = 0.0
		_fertility[i] = norm
		map.cells[i].fertility = norm


func _assign_terrain() -> void:
	for i: int in map.cells.size():
		var elev: float = _elevation[i]
		var fert: float = _fertility[i]
		var cell: Cell = map.cells[i]

		if elev < 0.03:
			cell.terrain_def = "WaterDeep"
		elif elev < 0.12:
			cell.terrain_def = "WaterShallow"
		elif elev < 0.15:
			cell.terrain_def = "MarshyTerrain"
		elif elev < 0.40:
			if fert < 0.30:
				cell.terrain_def = "Sand"
			elif fert < 0.55:
				cell.terrain_def = "Soil"
			else:
				cell.terrain_def = "SoilRich"
		elif elev < 0.55:
			cell.terrain_def = "Gravel"
		elif elev < 0.70:
			cell.terrain_def = "RoughStone"
		else:
			cell.terrain_def = "RoughStone"
			cell.is_mountain = true
			cell.roof = true


func _gen_caves() -> void:
	for i: int in map.cells.size():
		var cell: Cell = map.cells[i]
		if not cell.is_mountain:
			continue
		var x: int = cell.x
		var y: int = cell.y
		var cave_val: float = _noise_cave.fbm(x * 0.06, y * 0.06, 4, 2.0, 0.5)
		cave_val = (cave_val + 1.0) * 0.5
		if cave_val > 0.62:
			cell.feature = "Cave"
			cell.is_mountain = false
			cell.terrain_def = "RoughStone"
			cell.roof = true


func _gen_ores() -> void:
	var ore_types: PackedStringArray = PackedStringArray(["Steel", "Compacted", "Gold", "Uranium", "Jade"])
	var ore_thresholds: Array[float] = [0.72, 0.76, 0.88, 0.90, 0.92]

	for i: int in map.cells.size():
		var cell: Cell = map.cells[i]
		if not cell.is_mountain:
			continue
		var x: int = cell.x
		var y: int = cell.y
		var ore_val: float = _noise_ore.fbm(x * 0.08, y * 0.08, 3, 2.0, 0.5)
		ore_val = (ore_val + 1.0) * 0.5

		for oi: int in ore_types.size():
			if ore_val >= ore_thresholds[oi]:
				cell.ore = ore_types[oi]
				break
