class_name WorldGrid
extends RefCounted

## Hex-based world grid. Each tile represents a biome region on the world map.

var width: int
var height: int
var tiles: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

const BIOMES: Array[Dictionary] = [
	{"name": "AridShrubland", "color": [0.76, 0.70, 0.40], "temp_min": 15, "temp_max": 45, "rain_max": 600},
	{"name": "Desert", "color": [0.85, 0.78, 0.50], "temp_min": 20, "temp_max": 55, "rain_max": 250},
	{"name": "TemperateForest", "color": [0.30, 0.55, 0.20], "temp_min": -5, "temp_max": 30, "rain_max": 1200},
	{"name": "BorealForest", "color": [0.18, 0.38, 0.22], "temp_min": -20, "temp_max": 15, "rain_max": 800},
	{"name": "Tundra", "color": [0.70, 0.75, 0.78], "temp_min": -40, "temp_max": 5, "rain_max": 400},
	{"name": "IceSheet", "color": [0.90, 0.92, 0.95], "temp_min": -60, "temp_max": -10, "rain_max": 200},
	{"name": "TropicalRainforest", "color": [0.12, 0.42, 0.10], "temp_min": 20, "temp_max": 40, "rain_max": 3000},
	{"name": "Ocean", "color": [0.15, 0.25, 0.55], "temp_min": -50, "temp_max": 50, "rain_max": 0},
	{"name": "SeaIce", "color": [0.80, 0.85, 0.90], "temp_min": -60, "temp_max": -5, "rain_max": 0},
]


func generate(w: int, h: int, seed_val: int = 0) -> void:
	width = w
	height = h
	tiles.clear()
	if seed_val == 0:
		_rng.seed = randi()
	else:
		_rng.seed = seed_val

	var noise_temp := Noise2D.new(_rng.randi())
	var noise_rain := Noise2D.new(_rng.randi())
	var noise_elev := Noise2D.new(_rng.randi())

	for y: int in height:
		for x: int in width:
			var fx: float = x / float(width)
			var fy: float = y / float(height)

			var lat_factor: float = absf(fy - 0.5) * 2.0
			var temperature: float = lerpf(35.0, -50.0, lat_factor) + noise_temp.fbm(fx * 5.0, fy * 5.0, 3) * 15.0
			var rainfall: float = maxf(0.0, (1.0 - lat_factor) * 1500.0 + noise_rain.fbm(fx * 4.0, fy * 4.0, 3) * 500.0)
			var elevation: float = noise_elev.fbm(fx * 3.0, fy * 3.0, 4) * 0.5 + 0.5

			var is_ocean: bool = elevation < 0.35
			var biome := _assign_biome(temperature, rainfall, is_ocean, lat_factor)
			var hilliness := _assign_hilliness(elevation)

			tiles.append({
				"x": x, "y": y,
				"biome": biome,
				"temperature": snappedf(temperature, 0.1),
				"rainfall": snappedf(rainfall, 1.0),
				"elevation": snappedf(elevation, 0.01),
				"hilliness": hilliness,
				"faction": "",
				"settlement": "",
			})


func _assign_biome(temp: float, rain: float, is_ocean: bool, lat: float) -> String:
	if is_ocean:
		return "SeaIce" if temp < -5.0 else "Ocean"
	if temp < -20.0:
		return "IceSheet"
	if temp < 0.0:
		return "Tundra"
	if temp < 12.0:
		return "BorealForest"
	if rain > 1800.0:
		return "TropicalRainforest"
	if rain > 700.0:
		return "TemperateForest"
	if rain < 300.0:
		return "Desert"
	return "AridShrubland"


func _assign_hilliness(elev: float) -> String:
	if elev < 0.35:
		return "Ocean"
	if elev < 0.50:
		return "Flat"
	if elev < 0.65:
		return "SmallHills"
	if elev < 0.80:
		return "LargeHills"
	return "Mountainous"


func get_tile(x: int, y: int) -> Dictionary:
	if x < 0 or x >= width or y < 0 or y >= height:
		return {}
	return tiles[y * width + x]


func get_hex_neighbors(x: int, y: int) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var even_row: bool = y % 2 == 0
	var offsets: Array[Vector2i]
	if even_row:
		offsets = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(0, 1), Vector2i(-1, 1)]
	else:
		offsets = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(0, 1)]
	for o: Vector2i in offsets:
		var nx := x + o.x
		var ny := y + o.y
		if nx >= 0 and nx < width and ny >= 0 and ny < height:
			neighbors.append(Vector2i(nx, ny))
	return neighbors


func get_biome_color(biome_name: String) -> Array:
	for b: Dictionary in BIOMES:
		if b.name == biome_name:
			return b.color
	return [0.5, 0.5, 0.5]


func count_biomes() -> Dictionary:
	var counts: Dictionary = {}
	for t: Dictionary in tiles:
		var b: String = t.biome
		counts[b] = counts.get(b, 0) + 1
	return counts


func get_land_tiles() -> Array[Dictionary]:
	return tiles.filter(func(t: Dictionary) -> bool: return t.biome != "Ocean" and t.biome != "SeaIce")


func get_dominant_biome() -> String:
	var counts: Dictionary = count_biomes()
	var best: String = ""
	var best_c: int = 0
	for b: String in counts:
		if counts[b] > best_c and b != "Ocean" and b != "SeaIce":
			best_c = counts[b]
			best = b
	return best


func get_temperature_range() -> Dictionary:
	var lo: float = 999.0
	var hi: float = -999.0
	for t: Dictionary in tiles:
		if t["temperature"] < lo:
			lo = t["temperature"]
		if t["temperature"] > hi:
			hi = t["temperature"]
	return {"min": lo, "max": hi}


func get_mountainous_count() -> int:
	var cnt: int = 0
	for t: Dictionary in tiles:
		if t["hilliness"] == "Mountainous":
			cnt += 1
	return cnt

func get_avg_temperature() -> float:
	if tiles.is_empty():
		return 0.0
	var total: float = 0.0
	for t: Dictionary in tiles:
		total += t.get("temperature", 0.0)
	return snappedf(total / float(tiles.size()), 0.1)

func get_ocean_percentage() -> float:
	if tiles.is_empty():
		return 0.0
	var ocean_count: int = 0
	for t: Dictionary in tiles:
		if t.get("biome", "") == "Ocean" or t.get("biome", "") == "SeaIce":
			ocean_count += 1
	return snappedf(float(ocean_count) / float(tiles.size()) * 100.0, 0.1)

func get_unique_biome_count() -> int:
	return count_biomes().size()
