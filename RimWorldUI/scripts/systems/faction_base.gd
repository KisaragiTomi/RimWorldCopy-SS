extends Node

var _bases: Dictionary = {}

const DEFAULT_FACTIONS: Dictionary = {
	"Outlanders": {"bases": 3, "population": 50, "wealth": 5000, "tech_level": "Industrial", "hostile": false},
	"Pirates": {"bases": 5, "population": 80, "wealth": 8000, "tech_level": "Industrial", "hostile": true},
	"Tribals": {"bases": 4, "population": 40, "wealth": 2000, "tech_level": "Neolithic", "hostile": false},
	"Mechanoids": {"bases": 2, "population": 0, "wealth": 15000, "tech_level": "Spacer", "hostile": true},
	"Empire": {"bases": 2, "population": 100, "wealth": 20000, "tech_level": "Spacer", "hostile": false},
}


func _ready() -> void:
	_initialize_bases()


func _initialize_bases() -> void:
	for faction: String in DEFAULT_FACTIONS:
		var data: Dictionary = DEFAULT_FACTIONS[faction]
		var base_count: int = int(data.get("bases", 1))
		for i: int in range(base_count):
			var bid: String = faction + "_" + str(i)
			_bases[bid] = {
				"faction": faction,
				"population": int(data.population) / base_count,
				"wealth": float(data.wealth) / float(base_count),
				"position": Vector2i(randi_range(0, 99), randi_range(0, 59)),
			}


func get_bases_for_faction(faction: String) -> Array:
	var result: Array = []
	for bid: String in _bases:
		var base: Dictionary = _bases[bid]
		if String(base.get("faction", "")) == faction:
			result.append(base)
	return result


func get_nearest_base(pos: Vector2i, faction: String) -> Dictionary:
	var closest: Dictionary = {}
	var min_dist: float = 99999.0
	for bid: String in _bases:
		var base: Dictionary = _bases[bid]
		if String(base.get("faction", "")) == faction:
			var bp: Vector2i = base.get("position", Vector2i.ZERO) if base.get("position", null) is Vector2i else Vector2i.ZERO
			var d: float = float(pos.distance_to(bp))
			if d < min_dist:
				min_dist = d
				closest = base
	return closest


func get_hostile_factions() -> Array[String]:
	var result: Array[String] = []
	for f: String in DEFAULT_FACTIONS:
		if bool(DEFAULT_FACTIONS[f].get("hostile", false)):
			result.append(f)
	return result


func get_wealthiest_faction() -> String:
	var best: String = ""
	var best_wealth: float = 0.0
	for f: String in DEFAULT_FACTIONS:
		var w: float = float(DEFAULT_FACTIONS[f].get("wealth", 0))
		if w > best_wealth:
			best_wealth = w
			best = f
	return best


func get_total_population() -> int:
	var total: int = 0
	for f: String in DEFAULT_FACTIONS:
		total += int(DEFAULT_FACTIONS[f].get("population", 0))
	return total


func get_avg_population() -> float:
	if _bases.is_empty():
		return 0.0
	return snappedf(float(get_total_population()) / float(_bases.size()), 0.1)


func get_friendly_count() -> int:
	return DEFAULT_FACTIONS.size() - get_hostile_factions().size()


func get_avg_wealth_per_faction() -> float:
	if DEFAULT_FACTIONS.is_empty():
		return 0.0
	var total: float = 0.0
	for f: String in DEFAULT_FACTIONS:
		total += float(DEFAULT_FACTIONS[f].get("wealth", 0))
	return snappedf(total / float(DEFAULT_FACTIONS.size()), 0.1)


func get_highest_tech_faction() -> String:
	var tech_order: Dictionary = {"Neolithic": 0, "Medieval": 1, "Industrial": 2, "Spacer": 3, "Ultra": 4, "Archotech": 5}
	var best: String = ""
	var best_lvl: int = -1
	for f: String in DEFAULT_FACTIONS:
		var t: String = String(DEFAULT_FACTIONS[f].get("tech_level", ""))
		var lvl: int = int(tech_order.get(t, 0))
		if lvl > best_lvl:
			best_lvl = lvl
			best = f
	return best


func get_total_defined_bases() -> int:
	var total: int = 0
	for f: String in DEFAULT_FACTIONS:
		total += int(DEFAULT_FACTIONS[f].get("bases", 0))
	return total


func get_diplomatic_climate() -> String:
	var friendly: int = get_friendly_count()
	var hostile: int = get_hostile_factions().size()
	if friendly > hostile * 2:
		return "Peaceful"
	elif friendly > hostile:
		return "Favorable"
	elif friendly == hostile:
		return "Balanced"
	return "Hostile"

func get_power_index() -> float:
	if DEFAULT_FACTIONS.is_empty():
		return 0.0
	var total_pop: int = get_total_population()
	return snappedf(float(total_pop) / float(DEFAULT_FACTIONS.size()), 0.1)

func get_territorial_density() -> String:
	var bases: int = _bases.size()
	if bases >= 15:
		return "Crowded"
	elif bases >= 8:
		return "Moderate"
	elif bases >= 3:
		return "Sparse"
	return "Empty"

func get_summary() -> Dictionary:
	return {
		"total_bases": _bases.size(),
		"faction_count": DEFAULT_FACTIONS.size(),
		"hostile": get_hostile_factions().size(),
		"friendly": get_friendly_count(),
		"total_population": get_total_population(),
		"wealthiest": get_wealthiest_faction(),
		"avg_population": get_avg_population(),
		"avg_wealth": get_avg_wealth_per_faction(),
		"highest_tech": get_highest_tech_faction(),
		"defined_bases": get_total_defined_bases(),
		"diplomatic_climate": get_diplomatic_climate(),
		"power_index": get_power_index(),
		"territorial_density": get_territorial_density(),
		"geopolitical_stability": get_geopolitical_stability(),
		"alliance_potential": get_alliance_potential(),
		"regional_influence": get_regional_influence(),
		"diplomatic_ecosystem_health": get_diplomatic_ecosystem_health(),
		"geopolitical_governance": get_geopolitical_governance(),
		"alliance_maturity_index": get_alliance_maturity_index(),
	}

func get_geopolitical_stability() -> String:
	var climate := get_diplomatic_climate()
	var hostile := get_hostile_factions().size()
	if climate in ["Friendly", "Warm"] and hostile == 0:
		return "Stable"
	elif hostile <= 1:
		return "Tense"
	return "Volatile"

func get_alliance_potential() -> float:
	var friendly := get_friendly_count()
	var total := DEFAULT_FACTIONS.size()
	if total <= 0:
		return 0.0
	return snapped(float(friendly) / float(total) * 100.0, 0.1)

func get_regional_influence() -> String:
	var power := get_power_index()
	var density := get_territorial_density()
	if power >= 70.0 and density == "Crowded":
		return "Dominant"
	elif power >= 40.0:
		return "Significant"
	return "Minor"

func get_diplomatic_ecosystem_health() -> float:
	var alliance := get_alliance_potential()
	var stability := get_geopolitical_stability()
	var s_val: float = 90.0 if stability in ["Stable", "Peaceful"] else (50.0 if stability == "Tense" else 20.0)
	var influence := get_regional_influence()
	var i_val: float = 90.0 if influence == "Dominant" else (60.0 if influence == "Significant" else 30.0)
	return snapped((alliance + s_val + i_val) / 3.0, 0.1)

func get_geopolitical_governance() -> String:
	var health := get_diplomatic_ecosystem_health()
	var climate := get_diplomatic_climate()
	if health >= 65.0 and climate in ["Friendly", "Neutral"]:
		return "Diplomatic"
	elif health >= 35.0:
		return "Pragmatic"
	return "Isolationist"

func get_alliance_maturity_index() -> float:
	var friendly := get_friendly_count()
	var total := DEFAULT_FACTIONS.size()
	if total <= 0:
		return 0.0
	var power := get_power_index()
	var friend_ratio := float(friendly) / float(total) * 100.0
	return snapped((friend_ratio + power) / 2.0, 0.1)
