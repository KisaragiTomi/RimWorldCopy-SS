extends Node

## Handles predator animal behavior - wolves/bears hunting colonists.
## Registered as autoload "PredatorAI".

var _rng := RandomNumberGenerator.new()
var total_attacks: int = 0
var total_kills: int = 0
var total_manhunts: int = 0

const HUNT_CHANCE := 0.005
const ATTACK_RANGE := 2
const MANHUNT_REVENGE_CHANCE := 0.25

const PREDATOR_STATS: Dictionary = {
	"Wolf": {"damage": 10, "speed": 1.2, "pack_size": 3},
	"Bear": {"damage": 18, "speed": 0.8, "pack_size": 1},
	"Cougar": {"damage": 14, "speed": 1.4, "pack_size": 1},
	"Warg": {"damage": 16, "speed": 1.1, "pack_size": 2},
	"Megasloth": {"damage": 22, "speed": 0.5, "pack_size": 1},
}


func _ready() -> void:
	_rng.seed = randi()
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func _on_rare_tick(_tick: int) -> void:
	if not AnimalManager or not PawnManager:
		return

	for a: Animal in AnimalManager.animals:
		if a.dead or a.tamed:
			continue
		var data: Dictionary = Animal.SPECIES_DATA.get(a.species, {})
		var threat: String = data.get("threat", "Harmless")
		if threat != "Predator":
			continue

		if _rng.randf() > HUNT_CHANCE:
			continue

		var target: Pawn = _find_nearest_pawn(a)
		if target == null:
			continue

		_attack_pawn(a, target)


func _find_nearest_pawn(animal: Animal) -> Pawn:
	var best_pawn: Pawn = null
	var best_dist: int = ATTACK_RANGE + 1

	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed:
			continue
		var dist: int = absi(p.grid_pos.x - animal.grid_pos.x) + absi(p.grid_pos.y - animal.grid_pos.y)
		if dist <= ATTACK_RANGE and dist < best_dist:
			best_dist = dist
			best_pawn = p

	return best_pawn


func _attack_pawn(animal: Animal, target: Pawn) -> void:
	if target.health == null:
		return

	var stats: Dictionary = PREDATOR_STATS.get(animal.species, {"damage": 8, "speed": 1.0, "pack_size": 1})
	var dmg: int = stats.get("damage", 8)

	var parts := ["LeftArm", "RightArm", "LeftLeg", "RightLeg", "Torso", "Head"]
	var part: String = parts[_rng.randi_range(0, parts.size() - 1)]
	var injury_type: String = "Bite" if _rng.randf() < 0.6 else "Scratch"
	target.health.add_injury(part, dmg, injury_type)
	total_attacks += 1

	if ColonyLog:
		ColonyLog.add_entry("Combat", "A %s %s %s on %s (%d dmg)!" % [animal.species, injury_type.to_lower(), part, target.pawn_name, dmg], "danger")

	if target.health.is_dead:
		total_kills += 1
		if ColonyLog:
			ColonyLog.add_entry("Combat", "%s was killed by a %s!" % [target.pawn_name, animal.species], "danger")


func trigger_manhunt(animal: Animal) -> void:
	if not PawnManager or animal.dead:
		return
	total_manhunts += 1
	var target: Pawn = _find_nearest_pawn(animal)
	if target:
		_attack_pawn(animal, target)
		if ColonyLog:
			ColonyLog.add_entry("Combat", "A %s went manhunter!" % animal.species, "danger")


func on_animal_harmed(animal: Animal) -> void:
	if animal.tamed or animal.dead:
		return
	if _rng.randf() < MANHUNT_REVENGE_CHANCE:
		trigger_manhunt(animal)


func get_nearby_predators(pos: Vector2i, radius: int = 15) -> Array[Animal]:
	var result: Array[Animal] = []
	if not AnimalManager:
		return result
	for a: Animal in AnimalManager.animals:
		if a.dead or a.tamed:
			continue
		var data: Dictionary = Animal.SPECIES_DATA.get(a.species, {})
		if data.get("threat", "") != "Predator":
			continue
		var dist: int = absi(a.grid_pos.x - pos.x) + absi(a.grid_pos.y - pos.y)
		if dist <= radius:
			result.append(a)
	return result


func get_predator_count() -> int:
	if not AnimalManager:
		return 0
	var count: int = 0
	for a: Animal in AnimalManager.animals:
		if a.dead or a.tamed:
			continue
		var data: Dictionary = Animal.SPECIES_DATA.get(a.species, {})
		if data.get("threat", "") == "Predator":
			count += 1
	return count


func get_most_dangerous_species() -> String:
	if not AnimalManager:
		return ""
	var species_attacks: Dictionary = {}
	for a: Animal in AnimalManager.animals:
		if a.dead or a.tamed:
			continue
		if a.has_meta("manhunter") and a.get_meta("manhunter"):
			species_attacks[a.species] = species_attacks.get(a.species, 0) + 1
	var best: String = ""
	var best_c: int = 0
	for sp: String in species_attacks:
		if species_attacks[sp] > best_c:
			best_c = species_attacks[sp]
			best = sp
	return best


func count_nearby_predators(pos: Vector2i, radius: int = 20) -> int:
	if not AnimalManager:
		return 0
	var cnt: int = 0
	for a: Animal in AnimalManager.animals:
		if a.dead or a.tamed:
			continue
		if a.has_meta("manhunter") and a.get_meta("manhunter"):
			var d: int = absi(a.grid_pos.x - pos.x) + absi(a.grid_pos.y - pos.y)
			if d <= radius:
				cnt += 1
	return cnt


func is_manhunt_active() -> bool:
	return total_manhunts > 0 and get_predator_count() > 0


func get_kill_per_attack() -> float:
	if total_attacks == 0:
		return 0.0
	return float(total_kills) / float(total_attacks)


func get_unique_predator_species() -> int:
	if not AnimalManager:
		return 0
	var species: Dictionary = {}
	for a: Animal in AnimalManager.animals:
		if not a.dead and not a.tamed and a.get_tame_difficulty() == "Predator":
			species[a.species] = true
	return species.size()


func get_threat_level() -> String:
	var p: int = get_predator_count()
	if p >= 5:
		return "Extreme"
	elif p >= 3:
		return "High"
	elif p >= 1:
		return "Moderate"
	return "None"


func get_lethality_pct() -> float:
	if total_attacks <= 0:
		return 0.0
	return snappedf(float(total_kills) / float(total_attacks) * 100.0, 0.1)

func get_manhunt_frequency() -> float:
	if total_attacks <= 0:
		return 0.0
	return snappedf(float(total_manhunts) / float(total_attacks), 0.01)

func get_strongest_predator() -> String:
	var best: String = ""
	var best_dmg: int = 0
	for sp: String in PREDATOR_STATS:
		var dmg: int = int(PREDATOR_STATS[sp].get("damage", 0))
		if dmg > best_dmg:
			best_dmg = dmg
			best = sp
	return best

func get_ecosystem_danger() -> String:
	var count := get_predator_count()
	var lethality := get_lethality_pct()
	if count >= 5 and lethality > 50.0:
		return "Hostile"
	elif count >= 3 or lethality > 30.0:
		return "Dangerous"
	elif count > 0:
		return "Cautionary"
	return "Safe"

func get_defense_advisory() -> String:
	if is_manhunt_active():
		return "Shelter Now"
	var threat := get_threat_level()
	if threat == "High" or threat == "Critical":
		return "Arm Colonists"
	elif threat == "Medium":
		return "Stay Alert"
	return "Normal Operations"

func get_wildlife_pressure() -> float:
	var count := float(get_predator_count())
	var attacks := float(total_attacks)
	if count <= 0.0:
		return 0.0
	return snapped(minf(attacks / maxf(count, 1.0) * 20.0, 100.0), 0.1)

func get_summary() -> Dictionary:
	return {
		"predators": get_predator_count(),
		"total_attacks": total_attacks,
		"total_kills": total_kills,
		"total_manhunts": total_manhunts,
		"dangerous_species": get_most_dangerous_species(),
		"manhunt_active": is_manhunt_active(),
		"kill_per_attack": snappedf(get_kill_per_attack(), 0.01),
		"unique_species": get_unique_predator_species(),
		"threat_level": get_threat_level(),
		"lethality_pct": get_lethality_pct(),
		"manhunt_frequency": get_manhunt_frequency(),
		"strongest_predator": get_strongest_predator(),
		"ecosystem_danger": get_ecosystem_danger(),
		"defense_advisory": get_defense_advisory(),
		"wildlife_pressure": get_wildlife_pressure(),
		"wildlife_coexistence_index": get_wildlife_coexistence_index(),
		"predation_response_readiness": get_predation_response_readiness(),
		"ecological_risk_trajectory": get_ecological_risk_trajectory(),
	}

func get_wildlife_coexistence_index() -> float:
	var attacks: int = total_attacks
	var kills: int = total_kills
	var predators: int = get_predator_count()
	if predators == 0:
		return 100.0
	var violence: float = float(attacks + kills) / float(predators)
	return snappedf(clampf(100.0 - violence * 10.0, 0.0, 100.0), 0.1)

func get_predation_response_readiness() -> String:
	var lethality: float = get_lethality_pct()
	var advisory: String = get_defense_advisory()
	if lethality >= 60.0 and advisory in ["Fortify", "Armed Patrols"]:
		return "Alert"
	if lethality >= 30.0:
		return "Watchful"
	return "Relaxed"

func get_ecological_risk_trajectory() -> String:
	var manhunts: int = total_manhunts
	var attacks: int = total_attacks
	if manhunts >= 5 or attacks >= 15:
		return "Escalating"
	if manhunts >= 2 or attacks >= 5:
		return "Stable"
	return "Diminishing"
