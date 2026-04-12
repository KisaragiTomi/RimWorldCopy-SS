extends Node

## Manages friendly faction visitors who come to the colony.
## Registered as autoload "VisitorManager".

signal visitors_arrived(faction: String, count: int)
signal visitors_departed(faction: String)

var active_visits: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var total_visits: int = 0
var total_visitors: int = 0
var total_gifts_left: int = 0

const GIFT_CHANCE := 0.35
const GIFT_ITEMS: PackedStringArray = ["Silver", "MealSimple", "MedicineHerbal", "Wood", "Steel", "Cloth"]
const GIFT_AMOUNTS: Dictionary = {"Silver": 30, "MealSimple": 5, "MedicineHerbal": 2, "Wood": 20, "Steel": 10, "Cloth": 8}


func _ready() -> void:
	_rng.seed = randi()
	if TickManager:
		TickManager.long_tick.connect(_on_long_tick)


func _on_long_tick(_tick: int) -> void:
	_tick_departures()

	if _rng.randf() < 0.08:
		_try_spawn_visitors()


func _try_spawn_visitors() -> void:
	if not WorldManager or not WorldManager.faction_mgr:
		return

	var fm: FactionManager = WorldManager.faction_mgr
	var friendly: Array[String] = []
	for fname: String in fm.factions:
		var f: Dictionary = fm.factions[fname]
		if f.def.get("isPlayer", false):
			continue
		if f.def.get("permanentEnemy", false):
			continue
		if f.goodwill >= 0:
			friendly.append(fname)

	if friendly.is_empty():
		return

	var faction: String = friendly[_rng.randi_range(0, friendly.size() - 1)]
	var count: int = _rng.randi_range(2, 5)

	var visit := {
		"faction": faction,
		"count": count,
		"ticks_remaining": _rng.randi_range(4000, 8000),
	}
	active_visits.append(visit)
	total_visits += 1
	total_visitors += count
	visitors_arrived.emit(faction, count)

	if ColonyLog:
		ColonyLog.add_entry("Visitors", str(count) + " visitors from " + faction + " arrived.", "info")

	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.dead or p.thought_tracker == null:
				continue
			p.thought_tracker.add_thought("VisitorArrived")


func _tick_departures() -> void:
	var i := active_visits.size() - 1
	while i >= 0:
		var v: Dictionary = active_visits[i]
		v["ticks_remaining"] = v.get("ticks_remaining", 0) - 1000
		if v["ticks_remaining"] <= 0:
			var faction: String = v.get("faction", "Unknown")
			_maybe_leave_gift(faction)
			visitors_departed.emit(faction)
			if ColonyLog:
				ColonyLog.add_entry("Visitors", "Visitors from " + faction + " departed.", "info")
			active_visits.remove_at(i)
		i -= 1


func _maybe_leave_gift(faction: String) -> void:
	if _rng.randf() > GIFT_CHANCE:
		return
	var gift: String = GIFT_ITEMS[_rng.randi_range(0, GIFT_ITEMS.size() - 1)]
	var amount: int = GIFT_AMOUNTS.get(gift, 5)
	total_gifts_left += 1

	if ThingManager and ThingManager.has_method("spawn_item"):
		ThingManager.spawn_item(gift, amount, Vector2i(128, 128))

	if ColonyLog:
		ColonyLog.add_entry("Visitors", "Visitors from %s left a gift: %d %s." % [faction, amount, gift], "positive")


func get_visitors_from_faction(faction_name: String) -> int:
	var count: int = 0
	for v: Dictionary in active_visits:
		if v.get("faction", "") == faction_name:
			count += v.get("count", 0)
	return count


func has_visitors() -> bool:
	return not active_visits.is_empty()


func get_total_visitor_count() -> int:
	var count: int = 0
	for v: Dictionary in active_visits:
		count += v.get("count", 0)
	return count


func get_active_visitor_count() -> int:
	var cnt: int = 0
	for v: Dictionary in active_visits:
		cnt += v.get("count", 0)
	return cnt


func get_gift_rate() -> float:
	if total_visits == 0:
		return 0.0
	return float(total_gifts_left) / float(total_visits)


func get_most_visiting_faction() -> String:
	var counts: Dictionary = {}
	for v: Dictionary in active_visits:
		var f: String = v.get("faction", "")
		counts[f] = counts.get(f, 0) + 1
	var best: String = ""
	var best_c: int = 0
	for f: String in counts:
		if counts[f] > best_c:
			best_c = counts[f]
			best = f
	return best


func get_avg_visitors_per_visit() -> float:
	if total_visits == 0:
		return 0.0
	return float(total_visitors) / float(total_visits)


func get_unique_visiting_factions() -> int:
	var factions: Dictionary = {}
	for v: Dictionary in active_visits:
		factions[v.get("faction", "")] = true
	return factions.size()


func get_avg_stay_duration() -> float:
	if active_visits.is_empty():
		return 0.0
	var total: float = 0.0
	for v: Dictionary in active_visits:
		total += float(v.get("ticks_remaining", 0))
	return snappedf(total / float(active_visits.size()), 0.1)

func get_gift_efficiency() -> float:
	if total_visitors <= 0:
		return 0.0
	return snappedf(float(total_gifts_left) / float(total_visitors) * 100.0, 0.1)

func get_visitor_load() -> String:
	var current: int = get_total_visitor_count()
	if current == 0:
		return "None"
	elif current <= 3:
		return "Light"
	elif current <= 8:
		return "Moderate"
	return "Heavy"

func get_hospitality_score() -> float:
	var gift_eff := get_gift_efficiency()
	var avg_stay := float(get_avg_stay_duration())
	var visits := float(total_visits)
	if visits <= 0.0:
		return 0.0
	return snapped(gift_eff * 0.5 + minf(avg_stay / 6000.0, 1.0) * 30.0 + minf(visits / 10.0, 1.0) * 20.0, 0.1)

func get_diplomatic_exposure() -> int:
	return get_unique_visiting_factions()

func get_trade_opportunity() -> String:
	var visitors := get_total_visitor_count()
	var factions := get_unique_visiting_factions()
	if visitors > 5 and factions > 2:
		return "High"
	elif visitors > 0:
		return "Available"
	return "None"

func get_summary() -> Dictionary:
	var visits: Array[Dictionary] = []
	for v: Dictionary in active_visits:
		visits.append({
			"faction": v.get("faction", ""),
			"count": v.get("count", 0),
			"ticks_remaining": v.get("ticks_remaining", 0),
		})
	return {
		"active_visits": active_visits.size(),
		"total_visits": total_visits,
		"total_visitors": total_visitors,
		"total_gifts_left": total_gifts_left,
		"current_visitor_count": get_total_visitor_count(),
		"details": visits,
		"gift_rate": snappedf(get_gift_rate(), 0.01),
		"most_visiting": get_most_visiting_faction(),
		"avg_per_visit": snappedf(get_avg_visitors_per_visit(), 0.1),
		"unique_factions": get_unique_visiting_factions(),
		"avg_stay_duration": get_avg_stay_duration(),
		"gift_efficiency_pct": get_gift_efficiency(),
		"visitor_load": get_visitor_load(),
		"hospitality_score": get_hospitality_score(),
		"diplomatic_exposure": get_diplomatic_exposure(),
		"trade_opportunity": get_trade_opportunity(),
		"diplomatic_infrastructure": get_diplomatic_infrastructure(),
		"visitor_satisfaction_index": get_visitor_satisfaction_index(),
		"cultural_exchange_score": get_cultural_exchange_score(),
	}

func get_diplomatic_infrastructure() -> String:
	var unique: int = get_unique_visiting_factions()
	var gift_rate: float = get_gift_rate()
	if unique >= 5 and gift_rate >= 0.3:
		return "Established"
	if unique >= 3:
		return "Developing"
	if unique >= 1:
		return "Basic"
	return "None"

func get_visitor_satisfaction_index() -> float:
	var gift_eff: float = get_gift_efficiency()
	var hospitality: float = 0.0
	var h: float = get_hospitality_score()
	if h >= 80.0:
		hospitality = 90.0
	elif h >= 50.0:
		hospitality = 70.0
	elif h >= 25.0:
		hospitality = 50.0
	else:
		hospitality = 25.0
	return snappedf((gift_eff + hospitality) / 2.0, 0.1)

func get_cultural_exchange_score() -> float:
	var unique: int = get_unique_visiting_factions()
	var total: int = total_visits
	var diversity_bonus: float = float(unique) * 10.0
	var volume_bonus: float = minf(float(total) * 2.0, 50.0)
	return snappedf(clampf(diversity_bonus + volume_bonus, 0.0, 100.0), 0.1)
