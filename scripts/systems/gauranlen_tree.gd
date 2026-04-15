extends Node

var _connections: Dictionary = {}
var _dryads: Dictionary = {}
var _next_dryad: int = 0

const DRYAD_TYPES: Dictionary = {
	"Gaumaker": {"work_type": "none", "combat_power": 0, "product": "GauranlenSeed"},
	"Barkskin": {"work_type": "combat", "combat_power": 30, "armor": 0.3},
	"Woodmaker": {"work_type": "produce", "combat_power": 0, "product": "WoodLog", "yield_per_day": 5},
	"Medicinemaker": {"work_type": "produce", "combat_power": 0, "product": "HerbalMedicine", "yield_per_day": 1},
	"Berrymaker": {"work_type": "produce", "combat_power": 0, "product": "Berries", "yield_per_day": 8},
	"Clawer": {"work_type": "combat", "combat_power": 45, "melee_damage": 15}
}

const MAX_DRYADS_PER_TREE: int = 4
const CONNECTION_STRENGTH_DECAY: float = 0.02

func connect_pawn(pawn_id: int, tree_id: int) -> Dictionary:
	_connections[pawn_id] = {"tree_id": tree_id, "strength": 0.5, "dryad_count": 0}
	return {"connected": true, "pawn_id": pawn_id, "tree_id": tree_id}

func spawn_dryad(pawn_id: int, dryad_type: String) -> Dictionary:
	if not _connections.has(pawn_id):
		return {"error": "no_connection"}
	if not DRYAD_TYPES.has(dryad_type):
		return {"error": "unknown_type"}
	if _connections[pawn_id]["dryad_count"] >= MAX_DRYADS_PER_TREE:
		return {"error": "max_dryads"}
	var did: int = _next_dryad
	_next_dryad += 1
	_dryads[did] = {"owner": pawn_id, "type": dryad_type}
	_connections[pawn_id]["dryad_count"] += 1
	return {"dryad_id": did, "type": dryad_type}

func get_combat_dryads() -> Array:
	var result: Array = []
	for did: int in _dryads:
		var dtype: String = String(_dryads[did].get("type", ""))
		if String(DRYAD_TYPES.get(dtype, {}).get("work_type", "")) == "combat":
			result.append(did)
	return result


func get_producer_dryads() -> Array:
	var result: Array = []
	for did: int in _dryads:
		var dtype: String = String(_dryads[did].get("type", ""))
		if String(DRYAD_TYPES.get(dtype, {}).get("work_type", "")) == "produce":
			result.append(did)
	return result


func get_dryad_type_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for did: int in _dryads:
		var t: String = String(_dryads[did].get("type", ""))
		dist[t] = int(dist.get(t, 0)) + 1
	return dist


func get_avg_connection_strength() -> float:
	if _connections.is_empty():
		return 0.0
	var total: float = 0.0
	for pid: int in _connections:
		total += float(_connections[pid].get("strength", 0.0))
	return total / _connections.size()


func get_total_daily_yield() -> float:
	var total: float = 0.0
	for did: int in _dryads:
		var dtype: String = String(_dryads[did].get("type", ""))
		if DRYAD_TYPES.has(dtype):
			total += float(DRYAD_TYPES[dtype].get("yield_per_day", 0))
	return total


func get_active_dryad_type_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for did: int in _dryads:
		var t: String = String(_dryads[did].get("type", ""))
		dist[t] = dist.get(t, 0) + 1
	return dist


func get_max_dryad_capacity() -> int:
	return _connections.size() * MAX_DRYADS_PER_TREE


func get_dryad_fill_rate() -> float:
	var cap: int = get_max_dryad_capacity()
	if cap == 0:
		return 0.0
	return snappedf(float(_dryads.size()) / float(cap) * 100.0, 0.1)


func get_unique_dryad_types_active() -> int:
	var types: Dictionary = {}
	for did: int in _dryads:
		types[String(_dryads[did].get("type", ""))] = true
	return types.size()


func get_symbiosis_grade() -> String:
	var strength: float = get_avg_connection_strength()
	if strength >= 0.8:
		return "Flourishing"
	if strength >= 0.5:
		return "Healthy"
	if strength >= 0.2:
		return "Weak"
	return "Dormant"


func get_combat_readiness_pct() -> float:
	var combat: int = get_combat_dryads().size()
	var total: int = _dryads.size()
	if total == 0:
		return 0.0
	return snappedf(float(combat) / float(total) * 100.0, 0.1)


func get_economic_output() -> String:
	var yield_val: float = get_total_daily_yield()
	if yield_val >= 10.0:
		return "Abundant"
	if yield_val >= 5.0:
		return "Productive"
	if yield_val > 0.0:
		return "Modest"
	return "Dormant"


func get_summary() -> Dictionary:
	return {
		"dryad_types": DRYAD_TYPES.size(),
		"active_connections": _connections.size(),
		"total_dryads": _dryads.size(),
		"combat_dryads": get_combat_dryads().size(),
		"producer_dryads": get_producer_dryads().size(),
		"avg_strength": snapped(get_avg_connection_strength(), 0.01),
		"daily_yield": get_total_daily_yield(),
		"max_capacity": get_max_dryad_capacity(),
		"fill_rate": get_dryad_fill_rate(),
		"unique_active_types": get_unique_dryad_types_active(),
		"symbiosis_grade": get_symbiosis_grade(),
		"combat_readiness_pct": get_combat_readiness_pct(),
		"economic_output": get_economic_output(),
		"grove_maturity": get_grove_maturity(),
		"dryad_army_strength": get_dryad_army_strength(),
		"nature_bond_depth": get_nature_bond_depth(),
		"grove_ecosystem_health": get_grove_ecosystem_health(),
		"dryad_governance": get_dryad_governance(),
		"symbiosis_maturity_index": get_symbiosis_maturity_index(),
	}

func get_grove_maturity() -> String:
	var fill := get_dryad_fill_rate()
	var types := get_unique_dryad_types_active()
	if fill >= 80.0 and types >= 3:
		return "Ancient"
	elif fill >= 40.0:
		return "Growing"
	return "Sapling"

func get_dryad_army_strength() -> float:
	var combat := get_combat_dryads().size()
	var total := _dryads.size()
	if total <= 0:
		return 0.0
	return snapped(float(combat) / float(total) * 100.0, 0.1)

func get_nature_bond_depth() -> String:
	var avg_str := get_avg_connection_strength()
	if avg_str >= 0.8:
		return "Profound"
	elif avg_str >= 0.5:
		return "Strong"
	elif avg_str > 0.0:
		return "Tenuous"
	return "None"

func get_grove_ecosystem_health() -> float:
	var grade := get_symbiosis_grade()
	var g_val: float = 90.0 if grade == "Flourishing" else (70.0 if grade == "Healthy" else (40.0 if grade == "Developing" else 20.0))
	var fill := get_dryad_fill_rate()
	var output := get_economic_output()
	var o_val: float = 90.0 if output == "Abundant" else (70.0 if output == "Productive" else (40.0 if output == "Modest" else 20.0))
	return snapped((g_val + fill + o_val) / 3.0, 0.1)

func get_symbiosis_maturity_index() -> float:
	var army := get_dryad_army_strength()
	var bond := get_nature_bond_depth()
	var b_val: float = 90.0 if bond == "Profound" else (70.0 if bond == "Strong" else (40.0 if bond == "Tenuous" else 20.0))
	var maturity := get_grove_maturity()
	var m_val: float = 90.0 if maturity in ["Ancient", "Mature"] else (60.0 if maturity == "Growing" else 30.0)
	return snapped((army + b_val + m_val) / 3.0, 0.1)

func get_dryad_governance() -> String:
	var ecosystem := get_grove_ecosystem_health()
	var maturity := get_symbiosis_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _connections.size() > 0:
		return "Nascent"
	return "Dormant"
