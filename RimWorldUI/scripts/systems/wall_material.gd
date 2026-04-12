extends Node

## Defines wall material variants with different HP, beauty, and build costs.
## Registered as autoload "WallMaterial".

const MATERIALS: Dictionary = {
	"Wood": {
		"hp": 200,
		"beauty": 0.0,
		"flammability": 1.0,
		"build_work": 100,
		"cost_def": "Wood",
		"cost_amount": 5,
		"color": [0.55, 0.42, 0.28],
	},
	"Granite": {
		"hp": 450,
		"beauty": 0.5,
		"flammability": 0.0,
		"build_work": 200,
		"cost_def": "StoneBrick",
		"cost_amount": 5,
		"color": [0.62, 0.58, 0.55],
	},
	"Limestone": {
		"hp": 390,
		"beauty": 0.3,
		"flammability": 0.0,
		"build_work": 180,
		"cost_def": "StoneBrick",
		"cost_amount": 5,
		"color": [0.72, 0.68, 0.62],
	},
	"Marble": {
		"hp": 300,
		"beauty": 1.5,
		"flammability": 0.0,
		"build_work": 190,
		"cost_def": "StoneBrick",
		"cost_amount": 5,
		"color": [0.85, 0.82, 0.78],
	},
	"Steel": {
		"hp": 500,
		"beauty": -0.2,
		"flammability": 0.0,
		"build_work": 120,
		"cost_def": "Steel",
		"cost_amount": 5,
		"color": [0.60, 0.62, 0.65],
	},
	"Plasteel": {
		"hp": 700,
		"beauty": 0.0,
		"flammability": 0.0,
		"build_work": 150,
		"cost_def": "Plasteel",
		"cost_amount": 4,
		"color": [0.55, 0.65, 0.72],
	},
}

var _wall_materials: Dictionary = {}  # Vector2i -> material_name
var total_walls_built: int = 0


func set_wall_material(pos: Vector2i, material: String) -> bool:
	if not MATERIALS.has(material):
		return false
	if not _wall_materials.has(pos):
		total_walls_built += 1
	_wall_materials[pos] = material
	return true


func get_wall_material(pos: Vector2i) -> String:
	return _wall_materials.get(pos, "Wood")


func get_material_stats(material: String) -> Dictionary:
	return MATERIALS.get(material, MATERIALS["Wood"])


func get_hp(pos: Vector2i) -> int:
	var mat := get_wall_material(pos)
	return int(MATERIALS.get(mat, {}).get("hp", 200))


func get_beauty(pos: Vector2i) -> float:
	var mat := get_wall_material(pos)
	return MATERIALS.get(mat, {}).get("beauty", 0.0)


func get_flammability(pos: Vector2i) -> float:
	var mat := get_wall_material(pos)
	return MATERIALS.get(mat, {}).get("flammability", 0.0)


func get_wall_color(pos: Vector2i) -> Color:
	var mat := get_wall_material(pos)
	var c: Array = MATERIALS.get(mat, {}).get("color", [0.5, 0.5, 0.5])
	return Color(c[0], c[1], c[2])


func get_total_hp() -> int:
	var total: int = 0
	for pos: Vector2i in _wall_materials:
		total += get_hp(pos)
	return total


func get_total_beauty() -> float:
	var total: float = 0.0
	for pos: Vector2i in _wall_materials:
		total += get_beauty(pos)
	return total


func get_flammable_count() -> int:
	var count: int = 0
	for pos: Vector2i in _wall_materials:
		if get_flammability(pos) > 0.0:
			count += 1
	return count


func get_strongest_material() -> String:
	var best: String = ""
	var best_hp: int = 0
	for mat: String in MATERIALS:
		var hp: int = int(MATERIALS[mat].get("hp", 0))
		if hp > best_hp:
			best_hp = hp
			best = mat
	return best


func get_most_beautiful_material() -> String:
	var best: String = ""
	var best_beauty: float = -999.0
	for mat: String in MATERIALS:
		var b: float = MATERIALS[mat].get("beauty", 0.0)
		if b > best_beauty:
			best_beauty = b
			best = mat
	return best


func get_most_used_material() -> String:
	var counts: Dictionary = {}
	for pos: Vector2i in _wall_materials:
		var m: String = _wall_materials[pos]
		counts[m] = counts.get(m, 0) + 1
	var best: String = ""
	var best_n: int = 0
	for m: String in counts:
		if counts[m] > best_n:
			best_n = counts[m]
			best = m
	return best


func get_avg_hp_per_wall() -> float:
	if _wall_materials.is_empty():
		return 0.0
	return snappedf(float(get_total_hp()) / float(_wall_materials.size()), 0.1)


func get_fire_risk_percentage() -> float:
	if _wall_materials.is_empty():
		return 0.0
	return snappedf(float(get_flammable_count()) / float(_wall_materials.size()) * 100.0, 0.1)


func get_fortification_rating() -> String:
	var avg: float = get_avg_hp_per_wall()
	if avg >= 350.0:
		return "Fortress"
	elif avg >= 200.0:
		return "Strong"
	elif avg >= 100.0:
		return "Standard"
	return "Weak"

func get_material_diversity_pct() -> float:
	if _wall_materials.is_empty() or MATERIALS.is_empty():
		return 0.0
	var used: Dictionary = {}
	for pos: Vector2i in _wall_materials:
		used[_wall_materials[pos]] = true
	return snappedf(float(used.size()) / float(MATERIALS.size()) * 100.0, 0.1)

func get_structural_health() -> String:
	var fire: float = get_fire_risk_percentage()
	if fire == 0.0:
		return "Fireproof"
	elif fire < 20.0:
		return "Mostly Safe"
	elif fire < 50.0:
		return "Risky"
	return "Dangerous"

func get_fortification_index() -> float:
	var avg_hp := get_avg_hp_per_wall()
	var fire := get_fire_risk_percentage()
	return snapped(avg_hp * (1.0 - fire / 100.0) / 10.0, 0.1)

func get_aesthetic_value() -> String:
	var beauty := get_total_beauty() / maxf(float(_wall_materials.size()), 1.0)
	if beauty >= 2.0:
		return "Beautiful"
	elif beauty >= 1.0:
		return "Pleasant"
	elif beauty >= 0.0:
		return "Plain"
	return "Ugly"

func get_engineering_maturity() -> String:
	var diversity := get_material_diversity_pct()
	var health := get_structural_health()
	if diversity > 50.0 and (health == "Fireproof" or health == "Mostly Safe"):
		return "Advanced"
	elif diversity > 20.0:
		return "Developing"
	return "Basic"

func get_summary() -> Dictionary:
	var by_material: Dictionary = {}
	for pos: Vector2i in _wall_materials:
		var m: String = _wall_materials[pos]
		by_material[m] = by_material.get(m, 0) + 1
	return {
		"total_walls": _wall_materials.size(),
		"by_material": by_material,
		"available_materials": MATERIALS.size(),
		"total_walls_built": total_walls_built,
		"total_hp": get_total_hp(),
		"total_beauty": snappedf(get_total_beauty(), 0.1),
		"flammable_count": get_flammable_count(),
		"most_used": get_most_used_material(),
		"avg_hp": get_avg_hp_per_wall(),
		"fire_risk_pct": get_fire_risk_percentage(),
		"unique_materials": by_material.size(),
		"beauty_per_wall": snappedf(get_total_beauty() / maxf(float(_wall_materials.size()), 1.0), 0.01),
		"fortification_rating": get_fortification_rating(),
		"material_diversity_pct": get_material_diversity_pct(),
		"structural_health": get_structural_health(),
		"fortification_index": get_fortification_index(),
		"aesthetic_value": get_aesthetic_value(),
		"engineering_maturity": get_engineering_maturity(),
		"structural_investment_score": get_structural_investment_score(),
		"defensive_architecture_rating": get_defensive_architecture_rating(),
		"construction_legacy_index": get_construction_legacy_index(),
	}

func get_structural_investment_score() -> float:
	var avg_hp: float = get_avg_hp_per_wall()
	var beauty: float = get_total_beauty()
	var score: float = avg_hp * 0.3 + beauty * 2.0
	return snappedf(clampf(score, 0.0, 100.0), 0.1)

func get_defensive_architecture_rating() -> String:
	var fort: float = get_fortification_index()
	var fire_risk: float = get_fire_risk_percentage()
	if fort >= 70.0 and fire_risk <= 10.0:
		return "Fortress"
	if fort >= 40.0:
		return "Defensible"
	return "Vulnerable"

func get_construction_legacy_index() -> float:
	var total: int = total_walls_built
	var diversity: float = get_material_diversity_pct()
	var maturity: String = get_engineering_maturity()
	var base: float = minf(float(total) * 0.5, 40.0) + diversity * 0.4
	if maturity == "Advanced":
		base += 20.0
	elif maturity == "Standard":
		base += 10.0
	return snappedf(clampf(base, 0.0, 100.0), 0.1)
