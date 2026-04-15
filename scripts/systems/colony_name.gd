extends Node

var colony_name: String = ""
var _name_history: Array[String] = []

const PREFIX_POOL: Array[String] = [
	"New", "Fort", "Camp", "Haven", "Last",
	"Iron", "Stone", "Red", "Black", "Silver",
	"Dawn", "Frost", "Storm", "Star", "Moon",
]

const SUFFIX_POOL: Array[String] = [
	"Ridge", "Valley", "Hold", "Falls", "Creek",
	"Watch", "Gate", "Point", "Harbor", "Fields",
	"Peak", "Hollow", "Crossing", "Springs", "Bluff",
]


func _ready() -> void:
	if colony_name.is_empty():
		colony_name = generate_name()


func generate_name() -> String:
	var prefix: String = PREFIX_POOL[randi() % PREFIX_POOL.size()]
	var suffix: String = SUFFIX_POOL[randi() % SUFFIX_POOL.size()]
	return prefix + " " + suffix


func rename_colony(new_name: String) -> void:
	if not colony_name.is_empty():
		_name_history.append(colony_name)
	colony_name = new_name
	if ColonyLog and ColonyLog.has_method("add_entry"):
		ColonyLog.add_entry("Colony", "Colony renamed to: " + new_name, "info")


func get_colony_name() -> String:
	return colony_name


func get_name_history() -> Array[String]:
	return _name_history


func generate_candidates(count: int = 5) -> Array[String]:
	var result: Array[String] = []
	for i: int in range(count):
		result.append(generate_name())
	return result


func get_total_combinations() -> int:
	return PREFIX_POOL.size() * SUFFIX_POOL.size()


func has_been_renamed() -> bool:
	return _name_history.size() > 1


func get_name_length() -> int:
	return colony_name.length()


func get_last_name() -> String:
	if _name_history.size() < 2:
		return ""
	return _name_history[-2]


func get_identity_stability() -> String:
	var changes: int = _name_history.size()
	if changes == 0:
		return "Stable"
	elif changes <= 2:
		return "Settled"
	return "Volatile"

func get_name_uniqueness() -> float:
	if get_total_combinations() <= 0:
		return 0.0
	return snappedf(1.0 / float(get_total_combinations()) * 100.0, 0.001)

func get_branding_score() -> String:
	var length: int = get_name_length()
	if length >= 8 and length <= 16:
		return "Memorable"
	elif length >= 4:
		return "Simple"
	return "Minimal"

func get_summary() -> Dictionary:
	return {
		"name": colony_name,
		"name_changes": _name_history.size(),
		"prefix_pool_size": PREFIX_POOL.size(),
		"suffix_pool_size": SUFFIX_POOL.size(),
		"total_combinations": get_total_combinations(),
		"history": _name_history.duplicate(),
		"renamed": has_been_renamed(),
		"name_length": get_name_length(),
		"previous_name": get_last_name(),
		"avg_name_length": snappedf(float(get_name_length()) / maxf(float(_name_history.size() + 1), 1.0), 0.1),
		"rename_count": _name_history.size(),
		"identity_stability": get_identity_stability(),
		"name_uniqueness_pct": get_name_uniqueness(),
		"branding_score": get_branding_score(),
		"identity_maturity": get_identity_maturity(),
		"brand_strength": get_brand_strength(),
		"naming_creativity": get_naming_creativity(),
		"cultural_identity_index": get_cultural_identity_index(),
		"naming_heritage_depth": get_naming_heritage_depth(),
		"brand_ecosystem_health": get_brand_ecosystem_health(),
	}

func get_cultural_identity_index() -> float:
	var uniqueness := get_name_uniqueness()
	var branding := get_branding_score()
	var brand_val: float = 80.0 if branding == "Memorable" else (50.0 if branding == "Simple" else 20.0)
	return snapped((uniqueness + brand_val) / 2.0, 0.1)

func get_naming_heritage_depth() -> float:
	var history := float(_name_history.size())
	var stability := get_identity_stability()
	var base: float = history * 10.0
	if stability in ["Stable", "Established"]:
		base += 30.0
	return snapped(minf(base, 100.0), 0.1)

func get_brand_ecosystem_health() -> String:
	var maturity := get_identity_maturity()
	var strength := get_brand_strength()
	if maturity == "Established" and strength in ["Strong", "Iconic"]:
		return "Thriving"
	elif maturity == "Unstable":
		return "Chaotic"
	return "Developing"

func get_identity_maturity() -> String:
	var changes := _name_history.size()
	if changes == 0:
		return "Established"
	elif changes <= 2:
		return "Settling"
	return "In Flux"

func get_brand_strength() -> String:
	var score: String = get_branding_score()
	var stability := get_identity_stability()
	if score == "Memorable" and stability == "Stable":
		return "Strong"
	elif score in ["Memorable", "Simple"]:
		return "Growing"
	return "Weak"

func get_naming_creativity() -> float:
	var length := get_name_length()
	var combos := get_total_combinations()
	return snapped(minf(float(length) / 12.0, 1.0) * 100.0, 0.1)
