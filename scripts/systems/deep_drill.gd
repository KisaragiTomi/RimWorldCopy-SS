extends Node

## Manages deep drilling to extract underground resources. Deep drills must
## be built on valid deposit cells. Mining skill affects speed.
## Registered as autoload "DeepDrill".

const DRILL_DEFS: Dictionary = {
	"DeepDrill_Steel": {"resource": "Steel", "yield_per_cycle": 35, "work_per_cycle": 1200},
	"DeepDrill_Gold": {"resource": "Gold", "yield_per_cycle": 8, "work_per_cycle": 1500},
	"DeepDrill_Plasteel": {"resource": "Plasteel", "yield_per_cycle": 12, "work_per_cycle": 1800},
	"DeepDrill_Uranium": {"resource": "Uranium", "yield_per_cycle": 6, "work_per_cycle": 2000},
	"DeepDrill_Components": {"resource": "Components", "yield_per_cycle": 3, "work_per_cycle": 2500},
}

var _active_drills: Dictionary = {}  # building_id -> {pos, drill_def, work_done, total_extracted}
var _deposits: Dictionary = {}  # Vector2i -> {resource, amount_left}
var _rng := RandomNumberGenerator.new()
var total_extracted_all: Dictionary = {}
var total_cycles: int = 0


func _ready() -> void:
	_rng.seed = 91


func generate_deposits(map_width: int, map_height: int, count: int = 12) -> void:
	var resources: Array[String] = ["Steel", "Gold", "Plasteel", "Uranium", "Components"]
	var weights: Array[float] = [0.4, 0.15, 0.15, 0.1, 0.2]

	for _i: int in range(count):
		var pos := Vector2i(_rng.randi_range(5, map_width - 5), _rng.randi_range(5, map_height - 5))
		if _deposits.has(pos):
			continue
		var resource := _weighted_pick(resources, weights)
		var amount := _rng.randi_range(200, 800)
		_deposits[pos] = {"resource": resource, "amount_left": amount}


func _weighted_pick(items: Array[String], weights: Array[float]) -> String:
	var total: float = 0.0
	for w: float in weights:
		total += w
	var roll := _rng.randf() * total
	var cumulative: float = 0.0
	for i: int in range(items.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return items[i]
	return items[items.size() - 1]


func get_deposit(pos: Vector2i) -> Dictionary:
	return _deposits.get(pos, {})


func has_deposit(pos: Vector2i) -> bool:
	return _deposits.has(pos) and _deposits[pos].get("amount_left", 0) > 0


func register_drill(building_id: int, pos: Vector2i) -> bool:
	if not has_deposit(pos):
		return false
	var dep: Dictionary = _deposits[pos]
	var drill_def: String = "DeepDrill_" + dep.resource
	if not DRILL_DEFS.has(drill_def):
		drill_def = "DeepDrill_Steel"
	_active_drills[building_id] = {
		"pos": pos,
		"drill_def": drill_def,
		"work_done": 0.0,
		"total_extracted": 0,
	}
	return true


func unregister_drill(building_id: int) -> void:
	_active_drills.erase(building_id)


func do_drill_work(building_id: int, work_amount: float) -> Dictionary:
	if not _active_drills.has(building_id):
		return {}

	var drill: Dictionary = _active_drills[building_id]
	var def: Dictionary = DRILL_DEFS.get(drill.drill_def, {})
	if def.is_empty():
		return {}

	drill.work_done += work_amount
	if drill.work_done >= def.work_per_cycle:
		drill.work_done -= def.work_per_cycle
		var pos: Vector2i = drill.pos
		var dep: Dictionary = _deposits.get(pos, {})
		var yield_amount: int = mini(def.yield_per_cycle, dep.get("amount_left", 0))
		dep["amount_left"] = dep.get("amount_left", 0) - yield_amount
		drill.total_extracted += yield_amount
		total_extracted_all[def.resource] = total_extracted_all.get(def.resource, 0) + yield_amount
		total_cycles += 1

		if dep.get("amount_left", 0) <= 0:
			_deposits.erase(pos)

		if ColonyLog and yield_amount > 0:
			ColonyLog.add_entry("Mining", "Deep drill extracted " + str(yield_amount) + " " + def.resource + ".", "info")

		return {"resource": def.resource, "amount": yield_amount}

	return {}


func get_drill_progress(building_id: int) -> float:
	if not _active_drills.has(building_id):
		return 0.0
	var drill: Dictionary = _active_drills[building_id]
	var def: Dictionary = DRILL_DEFS.get(drill.drill_def, {})
	if def.is_empty():
		return 0.0
	return snappedf(drill.work_done / float(def.work_per_cycle), 0.01)


func get_richest_deposit() -> Dictionary:
	var best_pos: Vector2i = Vector2i.ZERO
	var best_amount: int = 0
	for pos: Vector2i in _deposits:
		var a: int = _deposits[pos].get("amount_left", 0)
		if a > best_amount:
			best_amount = a
			best_pos = pos
	if best_amount == 0:
		return {}
	return {"pos": best_pos, "resource": _deposits[best_pos].resource, "amount": best_amount}


func get_total_remaining() -> int:
	var total: int = 0
	for pos: Vector2i in _deposits:
		total += _deposits[pos].get("amount_left", 0)
	return total


func get_most_extracted_resource() -> String:
	var best: String = ""
	var best_amt: int = 0
	for r: String in total_extracted_all:
		if total_extracted_all[r] > best_amt:
			best_amt = total_extracted_all[r]
			best = r
	return best


func get_avg_yield_per_cycle() -> float:
	if total_cycles == 0:
		return 0.0
	var total: int = 0
	for r: String in total_extracted_all:
		total += total_extracted_all[r]
	return snappedf(float(total) / float(total_cycles), 0.1)


func get_depleted_count() -> int:
	var active_positions: Array[Vector2i] = []
	for bid: int in _active_drills:
		active_positions.append(_active_drills[bid].pos)
	var depleted: int = 0
	for pos: Vector2i in active_positions:
		if not _deposits.has(pos) or _deposits[pos].get("amount_left", 0) <= 0:
			depleted += 1
	return depleted


func get_drill_efficiency() -> String:
	var avg: float = get_avg_yield_per_cycle()
	if avg >= 20.0:
		return "High"
	elif avg >= 10.0:
		return "Standard"
	elif avg > 0.0:
		return "Low"
	return "None"

func get_resource_diversity() -> int:
	return _count_deposit_resources().size()

func get_sustainability_rating() -> String:
	var depleted: float = float(get_depleted_count())
	var total: float = float(_active_drills.size())
	if total <= 0.0:
		return "N/A"
	var ratio: float = depleted / total
	if ratio == 0.0:
		return "Sustainable"
	elif ratio < 0.3:
		return "Mostly Good"
	elif ratio < 0.6:
		return "Declining"
	return "Exhausted"

func get_extraction_roi() -> float:
	if total_cycles <= 0:
		return 0.0
	var total_val: float = 0.0
	for res: String in total_extracted_all:
		total_val += float(total_extracted_all[res])
	return snapped(total_val / float(total_cycles), 0.1)

func get_resource_security() -> String:
	var remaining := get_total_remaining()
	var depleted := get_depleted_count()
	if remaining > 500 and depleted == 0:
		return "Secure"
	elif remaining > 100:
		return "Adequate"
	return "Critical"

func get_mining_outlook() -> String:
	var sustain := get_sustainability_rating()
	var efficiency := get_drill_efficiency()
	if sustain == "Sustainable" and efficiency == "High":
		return "Promising"
	elif sustain == "Exhausted":
		return "Depleted"
	return "Mixed"

func get_summary() -> Dictionary:
	return {
		"active_drills": _active_drills.size(),
		"known_deposits": _deposits.size(),
		"total_remaining": get_total_remaining(),
		"total_cycles": total_cycles,
		"total_extracted": total_extracted_all.duplicate(),
		"deposits_by_resource": _count_deposit_resources(),
		"most_extracted": get_most_extracted_resource(),
		"avg_yield": get_avg_yield_per_cycle(),
		"depleted_drills": get_depleted_count(),
		"depletion_pct": snappedf(float(get_depleted_count()) / maxf(float(_active_drills.size()), 1.0) * 100.0, 0.1),
		"unique_resources": _count_deposit_resources().size(),
		"drill_efficiency": get_drill_efficiency(),
		"resource_diversity": get_resource_diversity(),
		"sustainability": get_sustainability_rating(),
		"extraction_roi": get_extraction_roi(),
		"resource_security": get_resource_security(),
		"mining_outlook": get_mining_outlook(),
		"extraction_lifecycle_health": get_extraction_lifecycle_health(),
		"geological_exploitation": get_geological_exploitation(),
		"drilling_infrastructure_maturity": get_drilling_infrastructure_maturity(),
	}

func get_extraction_lifecycle_health() -> float:
	var remaining := float(get_total_remaining())
	var depleted := float(get_depleted_count())
	var total := float(_active_drills.size())
	if total <= 0.0:
		return 0.0
	var health := (1.0 - depleted / total) * remaining / maxf(remaining + 1.0, 1.0) * 100.0
	return snapped(health, 0.1)

func get_geological_exploitation() -> float:
	var total_val: float = 0.0
	for res: String in total_extracted_all:
		total_val += float(total_extracted_all[res])
	var remaining := float(get_total_remaining())
	return snapped(total_val / maxf(total_val + remaining, 1.0) * 100.0, 0.1)

func get_drilling_infrastructure_maturity() -> String:
	var outlook := get_mining_outlook()
	var security := get_resource_security()
	if outlook == "Promising" and security == "Secure":
		return "Advanced"
	elif outlook != "Depleted" and security != "Critical":
		return "Developing"
	return "Primitive"


func _count_deposit_resources() -> Dictionary:
	var counts: Dictionary = {}
	for pos: Vector2i in _deposits:
		var r: String = _deposits[pos].resource
		counts[r] = counts.get(r, 0) + _deposits[pos].amount_left
	return counts
