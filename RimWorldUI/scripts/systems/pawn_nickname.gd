extends Node

const NICKNAMES: Array = [
	"Ace", "Bear", "Blaze", "Chip", "Dash", "Doc", "Duke", "Fang",
	"Frost", "Ghost", "Hawk", "Iron", "Jazz", "Kit", "Lucky", "Moss",
	"Nova", "Pike", "Red", "Rex", "Sage", "Scar", "Shadow", "Slim",
	"Spark", "Steel", "Storm", "Tank", "Thorn", "Vex", "Wolf", "Zap",
	"Brick", "Cinder", "Crow", "Dusk", "Echo", "Flint", "Grit", "Hex",
]

var _pawn_nicknames: Dictionary = {}


func generate_nickname(pawn_id: int) -> String:
	var nick: String = NICKNAMES[randi() % NICKNAMES.size()]
	_pawn_nicknames[pawn_id] = nick
	return nick


func set_nickname(pawn_id: int, nickname: String) -> void:
	_pawn_nicknames[pawn_id] = nickname


func get_nickname(pawn_id: int) -> String:
	if not _pawn_nicknames.has(pawn_id):
		return generate_nickname(pawn_id)
	return String(_pawn_nicknames[pawn_id])


func get_duplicate_nicknames() -> Dictionary:
	var count: Dictionary = {}
	for pid: int in _pawn_nicknames:
		var n: String = String(_pawn_nicknames[pid])
		count[n] = count.get(n, 0) + 1
	var dupes: Dictionary = {}
	for n: String in count:
		if count[n] > 1:
			dupes[n] = count[n]
	return dupes


func get_unused_nicknames() -> Array[String]:
	var used: Dictionary = {}
	for pid: int in _pawn_nicknames:
		used[String(_pawn_nicknames[pid])] = true
	var unused: Array[String] = []
	for n: String in NICKNAMES:
		if not used.has(n):
			unused.append(n)
	return unused


func clear_nickname(pawn_id: int) -> void:
	_pawn_nicknames.erase(pawn_id)


func get_most_common_nickname() -> String:
	var counts: Dictionary = {}
	for pid: int in _pawn_nicknames:
		var n: String = _pawn_nicknames[pid]
		counts[n] = counts.get(n, 0) + 1
	var best: String = ""
	var best_n: int = 0
	for n: String in counts:
		if counts[n] > best_n:
			best_n = counts[n]
			best = n
	return best


func get_assignment_rate() -> float:
	if not PawnManager:
		return 0.0
	var alive: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			alive += 1
	if alive == 0:
		return 0.0
	return snappedf(float(_pawn_nicknames.size()) / float(alive) * 100.0, 0.1)


func has_duplicates() -> bool:
	return not get_duplicate_nicknames().is_empty()


func get_unique_assigned_count() -> int:
	var unique: Dictionary = {}
	for pid: int in _pawn_nicknames:
		unique[String(_pawn_nicknames[pid])] = true
	return unique.size()


func get_pool_utilization_pct() -> float:
	if NICKNAMES.is_empty():
		return 0.0
	return snappedf(float(get_unique_assigned_count()) / float(NICKNAMES.size()) * 100.0, 0.1)


func get_avg_nickname_length() -> float:
	if _pawn_nicknames.is_empty():
		return 0.0
	var total: int = 0
	for pid: int in _pawn_nicknames:
		total += String(_pawn_nicknames[pid]).length()
	return snappedf(float(total) / float(_pawn_nicknames.size()), 0.1)


func get_identity_strength() -> String:
	var rate: float = get_assignment_rate()
	if rate >= 90.0:
		return "Strong"
	elif rate >= 60.0:
		return "Moderate"
	elif rate >= 30.0:
		return "Weak"
	return "Minimal"

func get_uniqueness_score() -> float:
	if _pawn_nicknames.is_empty():
		return 0.0
	return snappedf(float(get_unique_assigned_count()) / float(_pawn_nicknames.size()) * 100.0, 0.1)

func get_naming_creativity() -> String:
	var util: float = get_pool_utilization_pct()
	if util >= 80.0:
		return "Exhaustive"
	elif util >= 50.0:
		return "Creative"
	elif util >= 20.0:
		return "Standard"
	return "Limited"

func get_summary() -> Dictionary:
	return {
		"nickname_pool": NICKNAMES.size(),
		"assigned": _pawn_nicknames.size(),
		"unused_count": get_unused_nicknames().size(),
		"duplicates": get_duplicate_nicknames().size(),
		"most_common": get_most_common_nickname(),
		"assignment_rate_pct": get_assignment_rate(),
		"has_duplicates": has_duplicates(),
		"unique_assigned": get_unique_assigned_count(),
		"pool_utilization_pct": get_pool_utilization_pct(),
		"avg_name_length": get_avg_nickname_length(),
		"identity_strength": get_identity_strength(),
		"uniqueness_pct": get_uniqueness_score(),
		"naming_creativity": get_naming_creativity(),
		"persona_depth": get_persona_depth(),
		"name_saturation": get_name_saturation(),
		"cultural_richness": get_cultural_richness(),
		"naming_ecosystem_health": get_naming_ecosystem_health(),
		"identity_governance": get_identity_governance(),
		"nomenclature_maturity": get_nomenclature_maturity(),
	}

func get_persona_depth() -> String:
	var strength := get_identity_strength()
	var creativity := get_naming_creativity()
	if strength in ["Strong"] and creativity in ["Creative", "Exhaustive"]:
		return "Deep"
	elif strength in ["Moderate", "Strong"]:
		return "Developing"
	return "Surface"

func get_name_saturation() -> float:
	var pool := NICKNAMES.size()
	var assigned := _pawn_nicknames.size()
	if pool <= 0:
		return 0.0
	return snapped(float(assigned) / float(pool) * 100.0, 0.1)

func get_cultural_richness() -> String:
	var util := get_pool_utilization_pct()
	var unique := get_uniqueness_score()
	if util >= 60.0 and unique >= 80.0:
		return "Rich"
	elif util >= 30.0:
		return "Moderate"
	return "Sparse"

func get_naming_ecosystem_health() -> float:
	var saturation := get_name_saturation()
	var uniqueness := get_uniqueness_score()
	var richness := get_cultural_richness()
	var r_val: float = 90.0 if richness == "Rich" else (60.0 if richness == "Moderate" else 30.0)
	return snapped((saturation + uniqueness + r_val) / 3.0, 0.1)

func get_identity_governance() -> String:
	var health := get_naming_ecosystem_health()
	var depth := get_persona_depth()
	if health >= 65.0 and depth in ["Deep", "Developing"]:
		return "Curated"
	elif health >= 35.0:
		return "Organic"
	return "Random"

func get_nomenclature_maturity() -> float:
	var util := get_pool_utilization_pct()
	var creativity := get_naming_creativity()
	var c_val: float = 90.0 if creativity == "Inventive" else (60.0 if creativity == "Creative" else 30.0)
	return snapped((util + c_val) / 2.0, 0.1)
