extends Node

var _pregnancies: Dictionary = {}
var _pairs: Dictionary = {}

const GESTATION_DAYS: Dictionary = {
	"Chicken": 3, "Cow": 18, "Horse": 20, "Pig": 12,
	"Dog": 9, "Cat": 8, "Alpaca": 15, "Boomalope": 14,
	"Muffalo": 16, "Hare": 5, "Elephant": 25, "Thrumbo": 30
}

const LITTER_SIZE: Dictionary = {
	"Chicken": {"min": 1, "max": 1}, "Cow": {"min": 1, "max": 1},
	"Horse": {"min": 1, "max": 1}, "Pig": {"min": 3, "max": 6},
	"Dog": {"min": 2, "max": 5}, "Cat": {"min": 2, "max": 4},
	"Alpaca": {"min": 1, "max": 1}, "Boomalope": {"min": 1, "max": 1},
	"Muffalo": {"min": 1, "max": 1}, "Hare": {"min": 2, "max": 6},
	"Elephant": {"min": 1, "max": 1}, "Thrumbo": {"min": 1, "max": 1}
}

func pair_animals(male_id: int, female_id: int, species: String) -> bool:
	if not GESTATION_DAYS.has(species):
		return false
	_pairs[female_id] = {"male": male_id, "species": species}
	return true

func start_pregnancy(female_id: int) -> bool:
	if not _pairs.has(female_id):
		return false
	var info: Dictionary = _pairs[female_id]
	var days: int = GESTATION_DAYS.get(info["species"], 15)
	_pregnancies[female_id] = {
		"species": info["species"],
		"days_remaining": days,
		"total_days": days
	}
	return true

func advance_day() -> Array:
	var births: Array = []
	var to_remove: Array = []
	for fid: int in _pregnancies:
		_pregnancies[fid]["days_remaining"] -= 1
		if _pregnancies[fid]["days_remaining"] <= 0:
			var sp: String = _pregnancies[fid]["species"]
			var ls: Dictionary = LITTER_SIZE.get(sp, {"min": 1, "max": 1})
			var count: int = randi_range(ls["min"], ls["max"])
			births.append({"mother": fid, "species": sp, "offspring": count})
			to_remove.append(fid)
	for fid: int in to_remove:
		_pregnancies.erase(fid)
	return births

func get_pregnant_count() -> int:
	return _pregnancies.size()

func get_fastest_breeder() -> String:
	var best: String = ""
	var best_days: int = 999
	for sp: String in GESTATION_DAYS:
		if GESTATION_DAYS[sp] < best_days:
			best_days = GESTATION_DAYS[sp]
			best = sp
	return best


func get_max_litter_species() -> String:
	var best: String = ""
	var best_max: int = 0
	for sp: String in LITTER_SIZE:
		var mx: int = int(LITTER_SIZE[sp].get("max", 1))
		if mx > best_max:
			best_max = mx
			best = sp
	return best


func get_due_soon(days_threshold: int = 3) -> Array[int]:
	var result: Array[int] = []
	for fid: int in _pregnancies:
		if int(_pregnancies[fid].get("days_remaining", 999)) <= days_threshold:
			result.append(fid)
	return result


func get_avg_gestation() -> float:
	var total: int = 0
	for sp: String in GESTATION_DAYS:
		total += GESTATION_DAYS[sp]
	return float(total) / maxf(GESTATION_DAYS.size(), 1)


func get_total_expected_offspring() -> int:
	var total: int = 0
	for fid: int in _pregnancies:
		var sp: String = String(_pregnancies[fid].get("species", ""))
		var ls: Dictionary = LITTER_SIZE.get(sp, {"min": 1, "max": 1})
		total += int((int(ls["min"]) + int(ls["max"])) / 2.0)
	return total


func get_pregnancy_progress(female_id: int) -> float:
	if not _pregnancies.has(female_id):
		return 0.0
	var p: Dictionary = _pregnancies[female_id]
	var total: int = int(p.get("total_days", 1))
	var remaining: int = int(p.get("days_remaining", 0))
	return 1.0 - (float(remaining) / maxf(total, 1))


func get_slowest_breeder() -> String:
	var worst: String = ""
	var worst_days: int = 0
	for sp: String in GESTATION_DAYS:
		if GESTATION_DAYS[sp] > worst_days:
			worst_days = GESTATION_DAYS[sp]
			worst = sp
	return worst


func get_avg_litter_max() -> float:
	if LITTER_SIZE.is_empty():
		return 0.0
	var total: float = 0.0
	for sp: String in LITTER_SIZE:
		total += float(LITTER_SIZE[sp].get("max", 1))
	return snappedf(total / float(LITTER_SIZE.size()), 0.1)


func get_single_birth_species_count() -> int:
	var count: int = 0
	for sp: String in LITTER_SIZE:
		if int(LITTER_SIZE[sp].get("max", 1)) == 1:
			count += 1
	return count


func get_breeding_activity() -> String:
	if _pregnancies.is_empty() and _pairs.is_empty():
		return "None"
	elif _pregnancies.size() >= 5:
		return "Booming"
	elif _pregnancies.size() >= 2:
		return "Active"
	return "Low"

func get_population_growth_outlook() -> String:
	var expected: int = get_total_expected_offspring()
	if expected >= 10:
		return "Explosive"
	elif expected >= 5:
		return "Growing"
	elif expected >= 1:
		return "Stable"
	return "Stagnant"

func get_genetic_diversity_pct() -> float:
	if GESTATION_DAYS.is_empty():
		return 0.0
	var breeding_species: Dictionary = {}
	for pid: int in _pregnancies:
		var p: Dictionary = _pregnancies[pid]
		breeding_species[p.get("species", "")] = true
	return snappedf(float(breeding_species.size()) / float(GESTATION_DAYS.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"species_count": GESTATION_DAYS.size(),
		"pregnant_count": _pregnancies.size(),
		"paired_count": _pairs.size(),
		"due_soon": get_due_soon().size(),
		"avg_gestation": snapped(get_avg_gestation(), 0.1),
		"expected_offspring": get_total_expected_offspring(),
		"slowest_breeder": get_slowest_breeder(),
		"avg_litter_max": get_avg_litter_max(),
		"single_birth_species": get_single_birth_species_count(),
		"breeding_activity": get_breeding_activity(),
		"population_growth": get_population_growth_outlook(),
		"genetic_diversity_pct": get_genetic_diversity_pct(),
		"herd_sustainability": get_herd_sustainability(),
		"reproduction_efficiency": get_reproduction_efficiency(),
		"livestock_outlook": get_livestock_outlook(),
		"breeding_ecosystem_health": get_breeding_ecosystem_health(),
		"husbandry_governance": get_husbandry_governance(),
		"pastoral_maturity_index": get_pastoral_maturity_index(),
	}

func get_herd_sustainability() -> String:
	var growth := get_population_growth_outlook()
	var diversity := get_genetic_diversity_pct()
	if growth in ["Booming", "Growing"] and diversity >= 40.0:
		return "Sustainable"
	elif growth in ["Growing", "Stable"]:
		return "Viable"
	return "At Risk"

func get_reproduction_efficiency() -> float:
	var pregnant := _pregnancies.size()
	var pairs := _pairs.size()
	if pairs <= 0:
		return 0.0
	return snapped(float(pregnant) / float(pairs) * 100.0, 0.1)

func get_livestock_outlook() -> String:
	var expected := get_total_expected_offspring()
	var activity := get_breeding_activity()
	if expected >= 5 and activity in ["High", "Active"]:
		return "Prosperous"
	elif expected > 0:
		return "Modest"
	return "Stagnant"

func get_breeding_ecosystem_health() -> float:
	var sustainability := get_herd_sustainability()
	var s_val: float = 90.0 if sustainability == "Sustainable" else (60.0 if sustainability == "Viable" else 30.0)
	var efficiency := get_reproduction_efficiency()
	var outlook := get_livestock_outlook()
	var o_val: float = 90.0 if outlook == "Prosperous" else (60.0 if outlook == "Modest" else 30.0)
	return snapped((s_val + efficiency + o_val) / 3.0, 0.1)

func get_pastoral_maturity_index() -> float:
	var activity := get_breeding_activity()
	var a_val: float = 90.0 if activity in ["High", "Active"] else (60.0 if activity in ["Moderate", "Low"] else 30.0)
	var diversity := get_genetic_diversity_pct()
	var growth := get_population_growth_outlook()
	var g_val: float = 90.0 if growth in ["Booming", "Thriving"] else (60.0 if growth in ["Growing", "Stable"] else 30.0)
	return snapped((a_val + diversity + g_val) / 3.0, 0.1)

func get_husbandry_governance() -> String:
	var ecosystem := get_breeding_ecosystem_health()
	var maturity := get_pastoral_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _pairs.size() > 0:
		return "Nascent"
	return "Dormant"
