extends Node

var _walls: Dictionary = {}

const WALL_MATERIALS: Dictionary = {
	"Wood": {"base_hp": 200, "flammability": 1.0, "beauty": 0},
	"Stone": {"base_hp": 450, "flammability": 0.0, "beauty": 0},
	"Granite": {"base_hp": 510, "flammability": 0.0, "beauty": 0},
	"Marble": {"base_hp": 360, "flammability": 0.0, "beauty": 1},
	"Limestone": {"base_hp": 390, "flammability": 0.0, "beauty": 0},
	"Sandstone": {"base_hp": 350, "flammability": 0.0, "beauty": 0},
	"Slate": {"base_hp": 380, "flammability": 0.0, "beauty": 0},
	"Steel": {"base_hp": 350, "flammability": 0.4, "beauty": 0},
	"Plasteel": {"base_hp": 560, "flammability": 0.0, "beauty": 0},
	"Gold": {"base_hp": 120, "flammability": 0.4, "beauty": 20},
	"Silver": {"base_hp": 140, "flammability": 0.4, "beauty": 6},
	"Uranium": {"base_hp": 450, "flammability": 0.0, "beauty": -2}
}

func place_wall(wall_id: int, material: String, position: Vector2i) -> bool:
	if not WALL_MATERIALS.has(material):
		return false
	var mat: Dictionary = WALL_MATERIALS[material]
	_walls[wall_id] = {
		"material": material,
		"position": position,
		"hp": mat["base_hp"],
		"max_hp": mat["base_hp"]
	}
	return true

func damage_wall(wall_id: int, damage_amount: float) -> Dictionary:
	if not _walls.has(wall_id):
		return {}
	_walls[wall_id]["hp"] = maxf(0, _walls[wall_id]["hp"] - damage_amount)
	var destroyed: bool = _walls[wall_id]["hp"] <= 0
	if destroyed:
		_walls.erase(wall_id)
	return {"remaining_hp": 0.0 if destroyed else _walls[wall_id]["hp"], "destroyed": destroyed}

func repair_wall(wall_id: int, repair_amount: float) -> bool:
	if not _walls.has(wall_id):
		return false
	_walls[wall_id]["hp"] = minf(_walls[wall_id]["max_hp"], _walls[wall_id]["hp"] + repair_amount)
	return true

func get_wall_health_percent(wall_id: int) -> float:
	if not _walls.has(wall_id):
		return 0.0
	return _walls[wall_id]["hp"] / _walls[wall_id]["max_hp"]

func get_damaged_walls() -> Array[int]:
	var result: Array[int] = []
	for wid: int in _walls:
		if _walls[wid]["hp"] < _walls[wid]["max_hp"]:
			result.append(wid)
	return result


func get_strongest_material() -> String:
	var best: String = ""
	var best_hp: int = 0
	for mat: String in WALL_MATERIALS:
		if int(WALL_MATERIALS[mat].get("base_hp", 0)) > best_hp:
			best_hp = int(WALL_MATERIALS[mat].get("base_hp", 0))
			best = mat
	return best


func get_flammable_wall_count() -> int:
	var count: int = 0
	for wid: int in _walls:
		var mat: String = String(_walls[wid].get("material", ""))
		if float(WALL_MATERIALS.get(mat, {}).get("flammability", 0.0)) > 0.0:
			count += 1
	return count


func get_avg_wall_health_pct() -> float:
	if _walls.is_empty():
		return 0.0
	var total: float = 0.0
	for wid: int in _walls:
		total += float(_walls[wid]["hp"]) / float(_walls[wid]["max_hp"])
	return total / _walls.size()


func get_total_wall_hp() -> float:
	var total: float = 0.0
	for wid: int in _walls:
		total += float(_walls[wid].get("hp", 0.0))
	return total


func get_material_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for wid: int in _walls:
		var mat: String = String(_walls[wid].get("material", ""))
		dist[mat] = dist.get(mat, 0) + 1
	return dist


func get_weakest_material() -> String:
	var worst: String = ""
	var worst_hp: int = 99999
	for mat: String in WALL_MATERIALS:
		var hp: int = int(WALL_MATERIALS[mat].get("base_hp", 0))
		if hp < worst_hp:
			worst_hp = hp
			worst = mat
	return worst


func get_flammable_material_count() -> int:
	var count: int = 0
	for mat: String in WALL_MATERIALS:
		if float(WALL_MATERIALS[mat].get("flammability", 0.0)) > 0.0:
			count += 1
	return count


func get_avg_base_hp() -> float:
	if WALL_MATERIALS.is_empty():
		return 0.0
	var total: float = 0.0
	for mat: String in WALL_MATERIALS:
		total += float(WALL_MATERIALS[mat].get("base_hp", 0))
	return snappedf(total / float(WALL_MATERIALS.size()), 0.1)


func get_fortification_grade() -> String:
	var avg_hp: float = get_avg_base_hp()
	if avg_hp >= 400.0:
		return "Fortress"
	elif avg_hp >= 250.0:
		return "Reinforced"
	elif avg_hp >= 120.0:
		return "Standard"
	return "Fragile"

func get_fire_vulnerability_pct() -> float:
	if _walls.is_empty():
		return 0.0
	return snappedf(float(get_flammable_wall_count()) / float(_walls.size()) * 100.0, 0.1)

func get_structural_integrity() -> String:
	var avg_pct: float = get_avg_wall_health_pct()
	if avg_pct >= 0.9:
		return "Pristine"
	elif avg_pct >= 0.7:
		return "Good"
	elif avg_pct >= 0.4:
		return "Weathered"
	return "Crumbling"

func get_summary() -> Dictionary:
	return {
		"wall_materials": WALL_MATERIALS.size(),
		"placed_walls": _walls.size(),
		"damaged": get_damaged_walls().size(),
		"strongest": get_strongest_material(),
		"avg_health_pct": snapped(get_avg_wall_health_pct(), 0.01),
		"total_hp": snapped(get_total_wall_hp(), 0.1),
		"flammable_walls": get_flammable_wall_count(),
		"weakest": get_weakest_material(),
		"flammable_materials": get_flammable_material_count(),
		"avg_base_hp": get_avg_base_hp(),
		"fortification_grade": get_fortification_grade(),
		"fire_vulnerability_pct": get_fire_vulnerability_pct(),
		"structural_integrity": get_structural_integrity(),
		"perimeter_strength": get_perimeter_strength(),
		"material_resilience": get_material_resilience(),
		"breach_resistance": get_breach_resistance(),
		"fortification_ecosystem_health": get_fortification_ecosystem_health(),
		"wall_governance": get_wall_governance(),
		"structural_maturity_index": get_structural_maturity_index(),
	}

func get_perimeter_strength() -> String:
	var grade := get_fortification_grade()
	var integrity := get_structural_integrity()
	if grade in ["Fortress", "Strong"] and integrity in ["Excellent", "Good"]:
		return "Impregnable"
	elif grade in ["Standard", "Strong"]:
		return "Solid"
	return "Weak"

func get_material_resilience() -> float:
	var avg_hp := get_avg_base_hp()
	var flammable := get_flammable_material_count()
	var total := WALL_MATERIALS.size()
	if total <= 0:
		return 0.0
	var fire_safe_ratio := 1.0 - float(flammable) / float(total)
	return snapped(avg_hp * fire_safe_ratio, 0.1)

func get_breach_resistance() -> String:
	var avg_health := get_avg_wall_health_pct()
	if avg_health >= 90.0:
		return "Maximum"
	elif avg_health >= 60.0:
		return "Strong"
	elif avg_health >= 30.0:
		return "Weakening"
	return "Crumbling"

func get_fortification_ecosystem_health() -> float:
	var strength := get_perimeter_strength()
	var s_val: float = 90.0 if strength in ["Impenetrable", "Strong"] else (60.0 if strength in ["Moderate", "Adequate"] else 30.0)
	var resilience := get_material_resilience()
	var resistance := get_breach_resistance()
	var r_val: float = 90.0 if resistance == "Maximum" else (70.0 if resistance == "Strong" else (40.0 if resistance == "Weakening" else 20.0))
	return snapped((s_val + minf(resilience, 100.0) + r_val) / 3.0, 0.1)

func get_structural_maturity_index() -> float:
	var grade := get_fortification_grade()
	var g_val: float = 90.0 if grade in ["Fortress", "Strong"] else (60.0 if grade in ["Moderate", "Adequate"] else 30.0)
	var integrity := get_structural_integrity()
	var i_val: float = 90.0 if integrity in ["Pristine", "Solid"] else (60.0 if integrity in ["Good", "Fair"] else 30.0)
	var fire_vuln := get_fire_vulnerability_pct()
	var f_val: float = maxf(100.0 - fire_vuln, 0.0)
	return snapped((g_val + i_val + f_val) / 3.0, 0.1)

func get_wall_governance() -> String:
	var ecosystem := get_fortification_ecosystem_health()
	var maturity := get_structural_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _walls.size() > 0:
		return "Nascent"
	return "Dormant"
