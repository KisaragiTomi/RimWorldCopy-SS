extends Node

## Manages pawn-animal bonds. Bonded animals follow their master and
## provide mood bonuses. Loss of a bonded animal causes grief.
## Registered as autoload "BondManager".

signal bond_formed(pawn_id: int, animal_id: int)
signal bond_broken(pawn_id: int, animal_id: int, reason: String)

var bonds: Dictionary = {}  # pawn_id -> animal_id
var _bond_tick: Dictionary = {}  # pawn_id -> tick when bonded
var _rng := RandomNumberGenerator.new()
var total_bonds_formed: int = 0
var total_bonds_broken: int = 0

const BOND_CHANCE_PER_TAME := 0.05
const BONDED_MOOD := 0.04
const BOND_LOST_MOOD := -0.12
const BOND_LOST_DURATION := 20000
const MASTER_SKILL_BONUS := 0.02


func _ready() -> void:
	_rng.seed = randi()
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func try_bond(pawn: Pawn, animal: Animal) -> bool:
	if bonds.has(pawn.id):
		return false
	if animal.bond_with >= 0:
		return false
	if _rng.randf() < BOND_CHANCE_PER_TAME:
		_form_bond(pawn, animal)
		return true
	return false


func _form_bond(pawn: Pawn, animal: Animal) -> void:
	bonds[pawn.id] = animal.id
	_bond_tick[pawn.id] = TickManager.current_tick if TickManager else 0
	animal.bond_with = pawn.id
	total_bonds_formed += 1
	bond_formed.emit(pawn.id, animal.id)

	if pawn.thought_tracker:
		pawn.thought_tracker.add_thought("BondedAnimal")

	if ColonyLog:
		ColonyLog.add_entry("Social", pawn.pawn_name + " bonded with " + animal.name_label + ".", "info")


func break_bond(pawn_id: int, reason: String = "died") -> void:
	if not bonds.has(pawn_id):
		return
	var animal_id: int = bonds[pawn_id]
	bonds.erase(pawn_id)
	_bond_tick.erase(pawn_id)
	total_bonds_broken += 1
	bond_broken.emit(pawn_id, animal_id, reason)

	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.id == pawn_id and p.thought_tracker:
				if reason == "died":
					p.thought_tracker.add_thought("BondedAnimalDied")
				elif reason == "sold":
					p.thought_tracker.add_thought("BondedAnimalSold")
				break

	if ColonyLog:
		ColonyLog.add_entry("Social", "Bond broken (reason: " + reason + ").", "warning")


func get_bonded_animal(pawn_id: int) -> int:
	return bonds.get(pawn_id, -1)


func is_bonded(pawn_id: int) -> bool:
	return bonds.has(pawn_id)


func _on_rare_tick(_tick: int) -> void:
	if not AnimalManager:
		return
	var dead_bonds: Array[int] = []
	for pid: int in bonds:
		var aid: int = bonds[pid]
		var found := false
		for a: Animal in AnimalManager.animals:
			if a.id == aid:
				if a.dead:
					dead_bonds.append(pid)
				found = true
				break
		if not found:
			dead_bonds.append(pid)

	for pid: int in dead_bonds:
		break_bond(pid, "died")

	_apply_bond_moods()


func _apply_bond_moods() -> void:
	if not PawnManager:
		return
	for pid: int in bonds:
		for p: Pawn in PawnManager.pawns:
			if p.id == pid and not p.dead and p.thought_tracker:
				p.thought_tracker.add_thought("BondedAnimal")
				break


func get_pawn_for_animal(animal_id: int) -> int:
	for pid: int in bonds:
		if bonds[pid] == animal_id:
			return pid
	return -1


func get_bond_age(pawn_id: int) -> int:
	if not _bond_tick.has(pawn_id) or not TickManager:
		return 0
	return TickManager.current_tick - _bond_tick[pawn_id]


func get_all_bonds() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for pid: int in bonds:
		result.append({
			"pawn_id": pid,
			"animal_id": bonds[pid],
			"age_ticks": get_bond_age(pid),
		})
	return result


func get_oldest_bond() -> Dictionary:
	var oldest_pid: int = -1
	var oldest_age: int = 0
	for pid: int in bonds:
		var age: int = get_bond_age(pid)
		if age > oldest_age:
			oldest_age = age
			oldest_pid = pid
	if oldest_pid < 0:
		return {}
	return {"pawn_id": oldest_pid, "animal_id": bonds[oldest_pid], "age_ticks": oldest_age}


func has_bond(pawn_id: int) -> bool:
	return bonds.has(pawn_id)


func get_bonded_pawn_count() -> int:
	return bonds.size()


func get_bond_retention_rate() -> float:
	if total_bonds_formed == 0:
		return 0.0
	return float(bonds.size()) / float(total_bonds_formed) * 100.0


func get_avg_bond_age() -> float:
	if bonds.is_empty():
		return 0.0
	var total: float = 0.0
	for pid: int in bonds:
		total += float(get_bond_age(pid))
	return total / float(bonds.size())


func get_break_rate() -> float:
	if total_bonds_formed == 0:
		return 0.0
	return float(total_bonds_broken) / float(total_bonds_formed)


func get_bond_stability() -> String:
	var rate: float = get_break_rate()
	if rate <= 0.0:
		return "Perfect"
	elif rate < 0.2:
		return "Stable"
	elif rate < 0.5:
		return "Moderate"
	return "Fragile"

func get_unbonded_pawn_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead and not bonds.has(p.id):
			count += 1
	return count

func get_bond_density() -> float:
	if not PawnManager or PawnManager.pawns.is_empty():
		return 0.0
	var alive: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			alive += 1
	if alive <= 0:
		return 0.0
	return snappedf(float(bonds.size()) / float(alive) * 100.0, 0.1)

func get_emotional_anchor_score() -> float:
	var active := float(bonds.size())
	var retention := get_bond_retention_rate()
	var avg_age := get_avg_bond_age()
	return snapped((active * 10.0 + retention * 0.5 + minf(avg_age, 100.0) * 0.2), 0.1)

func get_bond_health() -> String:
	var stability := get_bond_stability()
	var retention := get_bond_retention_rate()
	if stability == "Strong" and retention > 80.0:
		return "Flourishing"
	elif stability == "Strong" or retention > 60.0:
		return "Healthy"
	elif retention > 30.0:
		return "Fragile"
	return "Deteriorating"

func get_companionship_gap() -> float:
	var unbonded := float(get_unbonded_pawn_count())
	var total := unbonded + float(bonds.size())
	if total <= 0.0:
		return 0.0
	return snapped(unbonded / total * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"active_bonds": bonds.size(),
		"total_formed": total_bonds_formed,
		"total_broken": total_bonds_broken,
		"bonds": get_all_bonds(),
		"retention_rate": snappedf(get_bond_retention_rate(), 0.1),
		"avg_age": snappedf(get_avg_bond_age(), 0.1),
		"break_rate": snappedf(get_break_rate(), 0.01),
		"stability": get_bond_stability(),
		"unbonded_pawns": get_unbonded_pawn_count(),
		"bond_density_pct": get_bond_density(),
		"emotional_anchor_score": get_emotional_anchor_score(),
		"bond_health": get_bond_health(),
		"companionship_gap_pct": get_companionship_gap(),
		"bond_ecosystem_vitality": get_bond_ecosystem_vitality(),
		"emotional_resilience_score": get_emotional_resilience_score(),
		"companion_network_depth": get_companion_network_depth(),
	}

func get_bond_ecosystem_vitality() -> String:
	var active: int = bonds.size()
	var retention: float = get_bond_retention_rate()
	if active >= 5 and retention >= 80.0:
		return "Thriving"
	if active >= 3 and retention >= 50.0:
		return "Healthy"
	if active >= 1:
		return "Developing"
	return "Absent"

func get_emotional_resilience_score() -> float:
	var anchor: float = get_emotional_anchor_score()
	var gap: float = get_companionship_gap()
	var score: float = anchor * 0.7 + (100.0 - gap) * 0.3
	return snappedf(clampf(score, 0.0, 100.0), 0.1)

func get_companion_network_depth() -> String:
	var active: int = bonds.size()
	var unbonded: int = get_unbonded_pawn_count()
	if active >= 8 and unbonded <= 1:
		return "Dense"
	if active >= 4:
		return "Moderate"
	if active >= 1:
		return "Sparse"
	return "None"
