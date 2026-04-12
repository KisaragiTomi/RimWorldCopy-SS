class_name Noise2D
extends RefCounted

## GDScript Perlin noise for terrain generation.
## Port of the Python prototype's PerlinNoise class.

var _perm: PackedInt32Array
var _grad_x: PackedFloat32Array
var _grad_y: PackedFloat32Array


func _init(seed: int = 0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var perm: Array[int] = []
	perm.resize(256)
	for i: int in 256:
		perm[i] = i
	for i: int in range(255, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = perm[i]
		perm[i] = perm[j]
		perm[j] = tmp

	_perm = PackedInt32Array()
	_perm.resize(512)
	for i: int in 512:
		_perm[i] = perm[i & 255]

	_grad_x = PackedFloat32Array()
	_grad_y = PackedFloat32Array()
	_grad_x.resize(256)
	_grad_y.resize(256)
	for i: int in 256:
		var angle: float = rng.randf() * TAU
		_grad_x[i] = cos(angle)
		_grad_y[i] = sin(angle)


func sample(x: float, y: float) -> float:
	var xi: int = int(floor(x))
	var yi: int = int(floor(y))
	var xf: float = x - xi
	var yf: float = y - yi

	var u: float = xf * xf * xf * (xf * (xf * 6.0 - 15.0) + 10.0)
	var v: float = yf * yf * yf * (yf * (yf * 6.0 - 15.0) + 10.0)

	var aa: int = _perm[(_perm[xi & 255] + yi) & 255] & 255
	var ab: int = _perm[(_perm[xi & 255] + yi + 1) & 255] & 255
	var ba: int = _perm[(_perm[(xi + 1) & 255] + yi) & 255] & 255
	var bb: int = _perm[(_perm[(xi + 1) & 255] + yi + 1) & 255] & 255

	var d_aa: float = _grad_x[aa] * xf + _grad_y[aa] * yf
	var d_ab: float = _grad_x[ab] * xf + _grad_y[ab] * (yf - 1.0)
	var d_ba: float = _grad_x[ba] * (xf - 1.0) + _grad_y[ba] * yf
	var d_bb: float = _grad_x[bb] * (xf - 1.0) + _grad_y[bb] * (yf - 1.0)

	var x1: float = d_aa + u * (d_ba - d_aa)
	var x2: float = d_ab + u * (d_bb - d_ab)

	return x1 + v * (x2 - x1)


func fbm(x: float, y: float, octaves: int = 6,
		lacunarity: float = 2.0, persistence: float = 0.5) -> float:
	var result: float = 0.0
	var amplitude: float = 1.0
	var frequency: float = 1.0
	var max_val: float = 0.0

	for _i: int in octaves:
		result += amplitude * sample(x * frequency, y * frequency)
		max_val += amplitude
		amplitude *= persistence
		frequency *= lacunarity

	return result / max_val if max_val > 0.0 else 0.0
