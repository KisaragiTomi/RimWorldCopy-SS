extends Node

## Tracks apparel wear over time. Clothing degrades with use and can become
## tattered, affecting mood. Registered as autoload "ApparelDegradation".

const DEGRADE_RATE: float = 0.001
const TATTERED_THRESHOLD: float = 0.3
const DESTROYED_THRESHOLD: float = 0.0

const MATERIAL_DURABILITY: Dictionary = {
	"Cloth": 0.8, "Devilstrand": 1.5, "Leather": 1.0, "Hyperweave": 2.0,
	"Synthread": 1.2, "Steel": 1.8,
}

var _apparel_hp: Dictionary = {}  # "pawn_id_slot" -> {hp, max_hp, tainted, material}
var total_destroyed: int = 0
var total_repaired: int = 0


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func register_apparel(pawn_id: int, slot: String, max_hp: float, material: String = "Cloth") -> void:
	var key := str(pawn_id) + "_" + slot
	var durability: float = MATERIAL_DURABILITY.get(material, 1.0)
	_apparel_hp[key] = {"hp": max_hp * durability, "max_hp": max_hp * durability, "tainted": false, "material": material}


func unregister_apparel(pawn_id: int, slot: String) -> void:
	var key := str(pawn_id) + "_" + slot
	_apparel_hp.erase(key)


func set_tainted(pawn_id: int, slot: String) -> void:
	var key := str(pawn_id) + "_" + slot
	if _apparel_hp.has(key):
		_apparel_hp[key].tainted = true


func get_condition(pawn_id: int, slot: String) -> float:
	var key := str(pawn_id) + "_" + slot
	if not _apparel_hp.has(key):
		return 1.0
	var entry: Dictionary = _apparel_hp[key]
	return entry.hp / maxf(1.0, entry.max_hp)


func is_tattered(pawn_id: int, slot: String) -> bool:
	return get_condition(pawn_id, slot) <= TATTERED_THRESHOLD


func is_tainted(pawn_id: int, slot: String) -> bool:
	var key := str(pawn_id) + "_" + slot
	if not _apparel_hp.has(key):
		return false
	return _apparel_hp[key].tainted


func repair_apparel(pawn_id: int, slot: String, amount: float) -> void:
	var key := str(pawn_id) + "_" + slot
	if not _apparel_hp.has(key):
		return
	_apparel_hp[key].hp = minf(_apparel_hp[key].max_hp, _apparel_hp[key].hp + amount)
	total_repaired += 1


func _on_rare_tick(_tick: int) -> void:
	var destroyed_keys: Array[String] = []

	for key: String in _apparel_hp:
		var entry: Dictionary = _apparel_hp[key]
		entry.hp = maxf(0.0, entry.hp - DEGRADE_RATE * entry.max_hp)

		if entry.hp <= DESTROYED_THRESHOLD:
			destroyed_keys.append(key)

	for key: String in destroyed_keys:
		_on_apparel_destroyed(key)
		_apparel_hp.erase(key)

	_apply_mood_effects()


func _on_apparel_destroyed(key: String) -> void:
	total_destroyed += 1
	var parts := key.split("_")
	if parts.size() < 2:
		return
	var pawn_id := int(parts[0])
	var slot: String = parts[1] if parts.size() > 1 else "unknown"
	if ColonyLog:
		ColonyLog.add_entry("Alert", "Colonist #%d's %s fell apart." % [pawn_id, slot], "warning")


func _apply_mood_effects() -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var has_tattered := false
		var has_tainted := false
		for key: String in _apparel_hp:
			if key.begins_with(str(p.id) + "_"):
				if get_condition(p.id, key.split("_")[1]) <= TATTERED_THRESHOLD:
					has_tattered = true
				if _apparel_hp[key].tainted:
					has_tainted = true
		if has_tattered and p.thought_tracker:
			p.thought_tracker.add_thought("TatteredApparel")
		if has_tainted and p.thought_tracker:
			p.thought_tracker.add_thought("TaintedApparel")


func get_avg_condition() -> float:
	if _apparel_hp.is_empty():
		return 1.0
	var total: float = 0.0
	for key: String in _apparel_hp:
		var entry: Dictionary = _apparel_hp[key]
		total += entry.hp / maxf(1.0, entry.max_hp)
	return snappedf(total / float(_apparel_hp.size()), 0.01)


func get_worst_apparel() -> Dictionary:
	var worst_key: String = ""
	var worst_cond: float = 2.0
	for key: String in _apparel_hp:
		var entry: Dictionary = _apparel_hp[key]
		var cond: float = entry.hp / maxf(1.0, entry.max_hp)
		if cond < worst_cond:
			worst_cond = cond
			worst_key = key
	if worst_key.is_empty():
		return {}
	var parts := worst_key.split("_")
	return {"pawn_id": int(parts[0]), "slot": parts[1] if parts.size() > 1 else "", "condition": worst_cond}


func get_pawn_apparel_status(pawn_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key: String in _apparel_hp:
		if key.begins_with(str(pawn_id) + "_"):
			var entry: Dictionary = _apparel_hp[key]
			var slot: String = key.split("_")[1] if key.split("_").size() > 1 else ""
			result.append({
				"slot": slot,
				"condition": snappedf(entry.hp / maxf(1.0, entry.max_hp), 0.01),
				"material": entry.get("material", "Cloth"),
				"tainted": entry.tainted,
			})
	return result


func get_most_durable_material() -> String:
	var best: String = ""
	var best_dur: float = 0.0
	for mat: String in MATERIAL_DURABILITY:
		if MATERIAL_DURABILITY[mat] > best_dur:
			best_dur = MATERIAL_DURABILITY[mat]
			best = mat
	return best


func get_near_breaking_count() -> int:
	var count: int = 0
	for key: String in _apparel_hp:
		var entry: Dictionary = _apparel_hp[key]
		var cond: float = entry.hp / maxf(1.0, entry.max_hp)
		if cond > DESTROYED_THRESHOLD and cond <= TATTERED_THRESHOLD:
			count += 1
	return count


func get_material_distribution() -> Dictionary:
	var counts: Dictionary = {}
	for key: String in _apparel_hp:
		var mat: String = _apparel_hp[key].get("material", "Cloth")
		counts[mat] = counts.get(mat, 0) + 1
	return counts


func get_condition_rating() -> String:
	var avg: float = get_avg_condition()
	if avg >= 0.8:
		return "Excellent"
	elif avg >= 0.5:
		return "Good"
	elif avg >= 0.3:
		return "Worn"
	return "Tattered"

func get_destruction_rate() -> float:
	var total: int = total_destroyed + total_repaired
	if total <= 0:
		return 0.0
	return snappedf(float(total_destroyed) / float(total) * 100.0, 0.1)

func get_maintenance_need() -> String:
	var near: int = get_near_breaking_count()
	if near == 0:
		return "None"
	elif near <= 2:
		return "Low"
	elif near <= 5:
		return "Moderate"
	return "Urgent"

func get_wardrobe_sustainability() -> String:
	var destruction := get_destruction_rate()
	var condition := get_condition_rating()
	if destruction < 10.0 and condition != "Tattered":
		return "Sustainable"
	elif destruction > 50.0:
		return "Critical"
	return "Declining"

func get_replacement_urgency() -> float:
	var near := get_near_breaking_count()
	var total := _apparel_hp.size()
	if total <= 0:
		return 0.0
	return snapped(float(near) / float(total) * 100.0, 0.1)

func get_material_resilience() -> String:
	var avg := get_avg_condition()
	if avg >= 0.8:
		return "Durable"
	elif avg >= 0.5:
		return "Worn"
	return "Fragile"

func get_summary() -> Dictionary:
	var total := _apparel_hp.size()
	var tattered := 0
	var tainted := 0
	for key: String in _apparel_hp:
		var entry: Dictionary = _apparel_hp[key]
		if entry.hp / maxf(1.0, entry.max_hp) <= TATTERED_THRESHOLD:
			tattered += 1
		if entry.tainted:
			tainted += 1
	return {
		"tracked_apparel": total,
		"tattered": tattered,
		"tainted": tainted,
		"total_destroyed": total_destroyed,
		"total_repaired": total_repaired,
		"avg_condition": get_avg_condition(),
		"near_breaking": get_near_breaking_count(),
		"material_dist": get_material_distribution(),
		"tattered_pct": snappedf(float(tattered) / maxf(float(total), 1.0) * 100.0, 0.1),
		"repair_rate": snappedf(float(total_repaired) / maxf(float(total_destroyed + total_repaired), 1.0) * 100.0, 0.1),
		"condition_rating": get_condition_rating(),
		"destruction_rate": get_destruction_rate(),
		"maintenance_need": get_maintenance_need(),
		"wardrobe_sustainability": get_wardrobe_sustainability(),
		"replacement_urgency_pct": get_replacement_urgency(),
		"material_resilience": get_material_resilience(),
		"textile_lifecycle_health": get_textile_lifecycle_health(),
		"clothing_security_index": get_clothing_security_index(),
		"wardrobe_investment_score": get_wardrobe_investment_score(),
	}

func get_textile_lifecycle_health() -> String:
	var sustainability: String = get_wardrobe_sustainability()
	var condition: String = get_condition_rating()
	if sustainability in ["Sustainable", "Good"] and condition in ["Excellent", "Good"]:
		return "Excellent"
	if condition != "Poor":
		return "Fair"
	return "Deteriorating"

func get_clothing_security_index() -> float:
	var urgency: float = get_replacement_urgency()
	var near: int = get_near_breaking_count()
	var total: int = _apparel_hp.size()
	var break_ratio: float = float(near) / maxf(float(total), 1.0) * 100.0
	return snappedf(clampf(100.0 - urgency - break_ratio, 0.0, 100.0), 0.1)

func get_wardrobe_investment_score() -> float:
	var avg_cond: float = get_avg_condition()
	var resilience: String = get_material_resilience()
	var bonus: float = 20.0 if resilience == "Durable" else (10.0 if resilience == "Moderate" else 0.0)
	return snappedf(clampf(avg_cond * 0.8 + bonus, 0.0, 100.0), 0.1)
