class_name FactionManager
extends RefCounted

## Manages world factions, goodwill, and settlements on the world map.

signal goodwill_changed(faction_name: String, new_goodwill: int)
signal settlement_placed(faction_name: String, x: int, y: int)

var factions: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = randi()


func load_factions() -> void:
	if not DefDB:
		return
	var defs := DefDB.get_all("FactionDef")
	for fd: Dictionary in defs:
		var fname: String = fd.get("defName", "")
		factions[fname] = {
			"def": fd,
			"goodwill": fd.get("startGoodwill", 0),
			"settlements": [],
			"leader": _generate_leader_name(),
		}


func get_goodwill(faction_name: String) -> int:
	if factions.has(faction_name):
		return factions[faction_name].goodwill
	return 0


func change_goodwill(faction_name: String, delta: int) -> int:
	if not factions.has(faction_name):
		return 0
	var f: Dictionary = factions[faction_name]
	var max_gw: int = f.def.get("naturalGoodwillMax", 100)
	f["goodwill"] = clampi(f.goodwill + delta, -100, max_gw)
	goodwill_changed.emit(faction_name, f.goodwill)
	return f.goodwill


func is_hostile(faction_name: String) -> bool:
	if not factions.has(faction_name):
		return false
	var f: Dictionary = factions[faction_name]
	if f.def.get("permanentEnemy", false):
		return true
	return f.goodwill < -75


func place_settlements(world: WorldGrid, settlements_per_faction: int = 3) -> void:
	var land := world.get_land_tiles()
	if land.is_empty():
		return

	for fname: String in factions:
		var f: Dictionary = factions[fname]
		if f.def.get("isPlayer", false):
			continue
		for i: int in settlements_per_faction:
			var attempts := 0
			while attempts < 50:
				var tile: Dictionary = land[_rng.randi_range(0, land.size() - 1)]
				if tile.settlement.is_empty():
					tile["settlement"] = fname
					tile["faction"] = fname
					f["settlements"].append(Vector2i(tile.x, tile.y))
					settlement_placed.emit(fname, tile.x, tile.y)
					break
				attempts += 1


func get_faction_summary() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for fname: String in factions:
		var f: Dictionary = factions[fname]
		result.append({
			"name": fname,
			"label": f.def.get("label", fname),
			"goodwill": f.goodwill,
			"hostile": is_hostile(fname),
			"settlements": f.settlements.size(),
			"leader": f.leader,
		})
	return result


func get_allied_factions() -> Array[String]:
	var result: Array[String] = []
	for fname: String in factions:
		if factions[fname].goodwill >= 75 and not factions[fname].def.get("isPlayer", false):
			result.append(fname)
	return result


func get_hostile_factions() -> Array[String]:
	var result: Array[String] = []
	for fname: String in factions:
		if is_hostile(fname):
			result.append(fname)
	return result


func get_strongest_faction() -> String:
	var best: String = ""
	var best_s: int = 0
	for fname: String in factions:
		var cnt: int = factions[fname].settlements.size()
		if cnt > best_s:
			best_s = cnt
			best = fname
	return best


func get_avg_goodwill() -> float:
	if factions.is_empty():
		return 0.0
	var total: float = 0.0
	for fname: String in factions:
		total += float(factions[fname].goodwill)
	return snappedf(total / float(factions.size()), 0.01)

func get_total_settlements() -> int:
	var total: int = 0
	for fname: String in factions:
		total += factions[fname].settlements.size()
	return total

func get_neutral_faction_count() -> int:
	var count: int = 0
	for fname: String in factions:
		var gw: int = factions[fname].goodwill
		if gw > -75 and gw < 75:
			count += 1
	return count

func get_permanent_enemy_count() -> int:
	var count: int = 0
	for fname: String in factions:
		if factions[fname].def.get("permanentEnemy", false):
			count += 1
	return count

func get_highest_goodwill_faction() -> String:
	var best: String = ""
	var best_gw: int = -101
	for fname: String in factions:
		if factions[fname].def.get("isPlayer", false):
			continue
		if factions[fname].goodwill > best_gw:
			best_gw = factions[fname].goodwill
			best = fname
	return best

func get_avg_settlements_per_faction() -> float:
	if factions.is_empty():
		return 0.0
	var total: int = get_total_settlements()
	return snappedf(float(total) / float(factions.size()), 0.01)

func get_diplomatic_stability() -> float:
	if factions.is_empty():
		return 0.0
	var friendly := get_allied_factions().size() + get_neutral_faction_count()
	return snapped(float(friendly) / float(factions.size()) * 100.0, 0.1)

func get_power_concentration_pct() -> float:
	if factions.is_empty():
		return 0.0
	var total_s := get_total_settlements()
	var max_s := 0
	for f in factions.values():
		var s: int = f.get("settlements", []).size()
		max_s = maxi(max_s, s)
	return snapped(float(max_s) / maxf(total_s, 1.0) * 100.0, 0.1)

func get_territorial_density() -> float:
	if factions.is_empty():
		return 0.0
	return snapped(float(get_total_settlements()) / float(factions.size()), 0.01)

func get_stats() -> Dictionary:
	return {
		"total_factions": factions.size(),
		"allied": get_allied_factions().size(),
		"hostile": get_hostile_factions().size(),
		"neutral": get_neutral_faction_count(),
		"strongest": get_strongest_faction(),
		"avg_goodwill": get_avg_goodwill(),
		"total_settlements": get_total_settlements(),
		"permanent_enemies": get_permanent_enemy_count(),
		"highest_goodwill_faction": get_highest_goodwill_faction(),
		"avg_settlements_per_faction": get_avg_settlements_per_faction(),
		"diplomatic_stability": get_diplomatic_stability(),
		"power_concentration_pct": get_power_concentration_pct(),
		"territorial_density": get_territorial_density(),
		"faction_ecosystem_health": get_faction_ecosystem_health(),
		"diplomatic_governance": get_diplomatic_governance(),
		"geopolitical_maturity_index": get_geopolitical_maturity_index(),
	}

func get_faction_ecosystem_health() -> float:
	var stability := get_diplomatic_stability()
	var concentration := get_power_concentration_pct()
	var conc_inv := maxf(100.0 - concentration, 0.0)
	var density := minf(get_territorial_density() * 10.0, 100.0)
	return snapped((stability + conc_inv + density) / 3.0, 0.1)

func get_diplomatic_governance() -> String:
	var eco := get_faction_ecosystem_health()
	var mat := get_geopolitical_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif factions.size() > 0:
		return "Nascent"
	return "Dormant"

func get_geopolitical_maturity_index() -> float:
	var allied := minf(float(get_allied_factions().size()) * 25.0, 100.0)
	var avg_good := maxf(get_avg_goodwill() + 100.0, 0.0) / 2.0
	var settlements := minf(float(get_total_settlements()) * 5.0, 100.0)
	return snapped((allied + avg_good + settlements) / 3.0, 0.1)

func _generate_leader_name() -> String:
	var names := ["Aldric", "Mira", "Talon", "Sable", "Orion", "Kestrel", "Vex", "Nara"]
	return names[_rng.randi_range(0, names.size() - 1)]
