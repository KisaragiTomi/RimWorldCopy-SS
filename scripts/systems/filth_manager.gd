extends Node

## Tracks and manages filth (blood, dirt, vomit) on map cells.
## Registered as autoload "FilthManager".

var filth_cells: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var total_cleaned: int = 0
var total_spawned: int = 0

const FILTH_BEAUTY: Dictionary = {
	"Dirt": -2, "Blood": -5, "Vomit": -8, "BloodFilth": -5,
	"Rubble": -3, "Ash": -2,
}
const HOME_AREA_PRIORITY: float = 2.0


func _ready() -> void:
	_rng.seed = randi()
	if TickManager:
		TickManager.long_tick.connect(_on_long_tick)


func add_filth(pos: Vector2i, filth_type: String = "Dirt", amount: int = 1) -> void:
	if filth_cells.has(pos):
		filth_cells[pos]["amount"] = filth_cells[pos].get("amount", 0) + amount
	else:
		filth_cells[pos] = {"type": filth_type, "amount": amount}
	total_spawned += 1


func clean(pos: Vector2i) -> bool:
	if filth_cells.has(pos):
		filth_cells.erase(pos)
		total_cleaned += 1
		return true
	return false


func get_nearest_filth(from: Vector2i, max_dist: int = 30) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_score: float = -999999.0
	for pos: Vector2i in filth_cells:
		var dist: int = absi(pos.x - from.x) + absi(pos.y - from.y)
		if dist > max_dist:
			continue
		var score: float = -float(dist)
		var ftype: String = filth_cells[pos].get("type", "Dirt")
		score -= FILTH_BEAUTY.get(ftype, -2) * 3.0
		score += filth_cells[pos].get("amount", 1) * 2.0
		if score > best_score:
			best_score = score
			best = pos
	return best


func get_filth_at(pos: Vector2i) -> Dictionary:
	return filth_cells.get(pos, {})


func get_beauty_penalty(pos: Vector2i) -> int:
	if not filth_cells.has(pos):
		return 0
	var ftype: String = filth_cells[pos].get("type", "Dirt")
	return FILTH_BEAUTY.get(ftype, -2) * filth_cells[pos].get("amount", 1)


func get_filth_count_by_type(filth_type: String) -> int:
	var count: int = 0
	for pos: Vector2i in filth_cells:
		if filth_cells[pos].get("type", "") == filth_type:
			count += 1
	return count


func _on_long_tick(_tick: int) -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if p.health and p.health.is_bleeding():
			add_filth(p.grid_pos, "Blood")

	if _rng.randf() < 0.05:
		_spawn_random_dirt()

	if _rng.randf() < 0.02:
		_spawn_vomit()


func _spawn_random_dirt() -> void:
	if not PawnManager or PawnManager.pawns.is_empty():
		return
	var p: Pawn = PawnManager.pawns[_rng.randi_range(0, PawnManager.pawns.size() - 1)]
	if not p.dead:
		add_filth(p.grid_pos, "Dirt")


func _spawn_vomit() -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if p.get_need("Food") < 0.1 or (p.health and p.health.has_hediff("FoodPoisoning")):
			add_filth(p.grid_pos, "Vomit")
			break


func get_worst_filth_type() -> String:
	var counts: Dictionary = {}
	for pos: Vector2i in filth_cells:
		var t: String = filth_cells[pos].get("type", "Dirt")
		counts[t] = counts.get(t, 0) + 1
	var best: String = "Dirt"
	var best_c: int = 0
	for t: String in counts:
		if counts[t] > best_c:
			best_c = counts[t]
			best = t
	return best


func get_total_beauty_penalty() -> int:
	var total: int = 0
	for pos: Vector2i in filth_cells:
		total += get_beauty_penalty(pos)
	return total


func get_clean_rate() -> float:
	if total_spawned == 0:
		return 0.0
	return float(total_cleaned) / float(total_spawned)


func get_filth_type_count() -> int:
	var types: Dictionary = {}
	for pos: Vector2i in filth_cells:
		types[filth_cells[pos].get("type", "Unknown")] = true
	return types.size()


func get_avg_beauty_penalty() -> float:
	if filth_cells.is_empty():
		return 0.0
	return float(get_total_beauty_penalty()) / float(filth_cells.size())


func get_pending_clean_count() -> int:
	return maxi(0, int(total_spawned) - int(total_cleaned))


func get_cleanliness_score() -> String:
	var pending: int = get_pending_clean_count()
	if pending == 0:
		return "Pristine"
	elif pending < 5:
		return "Clean"
	elif pending < 15:
		return "Dirty"
	return "Filthy"


func get_spawn_rate() -> float:
	if total_cleaned <= 0:
		return 0.0
	return snappedf(float(total_spawned) / float(total_cleaned), 0.01)


func get_clean_efficiency() -> float:
	if total_spawned <= 0:
		return 100.0
	return snappedf(float(total_cleaned) / float(total_spawned) * 100.0, 0.1)


func get_hygiene_pressure() -> String:
	var pending := get_pending_clean_count()
	var rate := get_spawn_rate()
	if rate > 1.5 and pending > 20:
		return "Overwhelming"
	elif rate > 1.0 or pending > 15:
		return "High"
	elif pending > 5:
		return "Moderate"
	return "Low"

func get_contamination_risk_pct() -> float:
	var total := filth_cells.size()
	if total <= 0:
		return 0.0
	var bio_count := 0
	for pos: Vector2i in filth_cells:
		var t: String = filth_cells[pos].get("type", "")
		if t in ["Blood", "Vomit", "Corpse_Bile"]:
			bio_count += 1
	return snapped(float(bio_count) / float(total) * 100.0, 0.1)

func get_maintenance_demand() -> String:
	var eff := get_clean_efficiency()
	if eff >= 90.0:
		return "Self-Sustaining"
	elif eff >= 60.0:
		return "Manageable"
	elif eff >= 30.0:
		return "Needs Help"
	return "Overrun"

func get_summary() -> Dictionary:
	var by_type: Dictionary = {}
	for pos: Vector2i in filth_cells:
		var t: String = filth_cells[pos].get("type", "Unknown")
		by_type[t] = by_type.get(t, 0) + 1
	return {
		"total": filth_cells.size(),
		"by_type": by_type,
		"total_cleaned": total_cleaned,
		"total_spawned": total_spawned,
		"worst_type": get_worst_filth_type(),
		"beauty_penalty": get_total_beauty_penalty(),
		"clean_rate": snappedf(get_clean_rate(), 0.01),
		"filth_types": get_filth_type_count(),
		"avg_beauty_penalty": snappedf(get_avg_beauty_penalty(), 0.01),
		"pending": get_pending_clean_count(),
		"cleanliness": get_cleanliness_score(),
		"spawn_rate": get_spawn_rate(),
		"efficiency_pct": get_clean_efficiency(),
		"hygiene_pressure": get_hygiene_pressure(),
		"contamination_risk_pct": get_contamination_risk_pct(),
		"maintenance_demand": get_maintenance_demand(),
		"environmental_quality_index": get_environmental_quality_index(),
		"sanitation_sustainability": get_sanitation_sustainability(),
		"health_hazard_score": get_health_hazard_score(),
	}

func get_environmental_quality_index() -> float:
	var cleanliness: float = 100.0 - float(filth_cells.size()) * 2.0
	var penalty: float = get_total_beauty_penalty()
	var score: float = clampf(cleanliness - absf(penalty) * 0.5, 0.0, 100.0)
	return snappedf(score, 0.1)

func get_sanitation_sustainability() -> String:
	var rate: float = get_clean_rate()
	var spawn: float = get_spawn_rate()
	if rate <= 0.0 and spawn <= 0.0:
		return "Neutral"
	if rate >= spawn * 1.5:
		return "Sustainable"
	if rate >= spawn:
		return "Balanced"
	return "Unsustainable"

func get_health_hazard_score() -> float:
	var total: int = filth_cells.size()
	var contam: float = get_contamination_risk_pct()
	var hazard: float = float(total) * 1.5 + contam * 0.5
	return snappedf(clampf(hazard, 0.0, 100.0), 0.1)
