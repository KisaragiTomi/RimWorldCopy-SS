extends Node

const THING_BEAUTY: Dictionary = {
	"Table": 1.0,
	"DiningChair": 0.5,
	"Bed": 1.0,
	"RoyalBed": 4.0,
	"Dresser": 2.0,
	"EndTable": 1.5,
	"Armchair": 2.0,
	"PlantPot": 3.0,
	"Sculpture": 8.0,
	"LargeStatue": 12.0,
	"Lamp": 1.0,
	"Torch": -0.5,
	"Campfire": -1.0,
	"SleepingSpot": -2.0,
	"Stool": 0.0,
	"Shelf": 0.5,
	"Rug": 2.0,
	"Vent": -1.0,
	"Heater": -1.0,
	"Cooler": -2.0,
	"Battery": -3.0,
	"Generator": -4.0,
	"Turret": -5.0,
	"Grave": -3.0,
	"Sarcophagus": 2.0,
	"Corpse": -15.0,
}

const QUALITY_MULTIPLIER: Dictionary = {
	"Awful": 0.5,
	"Poor": 0.75,
	"Normal": 1.0,
	"Good": 1.25,
	"Excellent": 1.5,
	"Masterwork": 2.0,
	"Legendary": 3.0,
}

const FILTH_BEAUTY: float = -3.0


func get_thing_beauty(def_id: String, quality: String = "Normal") -> float:
	var base: float = THING_BEAUTY.get(def_id, 0.0)
	var mult: float = QUALITY_MULTIPLIER.get(quality, 1.0)
	return snappedf(base * mult, 0.1)


func calc_room_beauty(things: Array, filth_count: int = 0, floor_beauty: float = 0.0) -> float:
	var total: float = floor_beauty
	for t in things:
		var def_id: String = str(t.get("def_id", ""))
		var quality: String = str(t.get("quality", "Normal"))
		total += get_thing_beauty(def_id, quality)
	total += float(filth_count) * FILTH_BEAUTY
	return snappedf(total, 0.1)


func get_beauty_label(beauty: float) -> String:
	if beauty >= 10.0:
		return "Gorgeous"
	if beauty >= 5.0:
		return "Beautiful"
	if beauty >= 2.0:
		return "Nice"
	if beauty >= -2.0:
		return "Average"
	if beauty >= -5.0:
		return "Ugly"
	return "Hideous"


func get_most_beautiful() -> Dictionary:
	var best_name: String = ""
	var best_val: float = -999.0
	for def_id: String in THING_BEAUTY:
		if THING_BEAUTY[def_id] > best_val:
			best_val = THING_BEAUTY[def_id]
			best_name = def_id
	return {"def_id": best_name, "beauty": best_val}


func get_ugliest() -> Dictionary:
	var worst_name: String = ""
	var worst_val: float = 999.0
	for def_id: String in THING_BEAUTY:
		if THING_BEAUTY[def_id] < worst_val:
			worst_val = THING_BEAUTY[def_id]
			worst_name = def_id
	return {"def_id": worst_name, "beauty": worst_val}


func get_beauty_by_category() -> Dictionary:
	var positive: int = 0
	var negative: int = 0
	var neutral: int = 0
	for def_id: String in THING_BEAUTY:
		var v: float = THING_BEAUTY[def_id]
		if v > 0.0:
			positive += 1
		elif v < 0.0:
			negative += 1
		else:
			neutral += 1
	return {"positive": positive, "negative": negative, "neutral": neutral}


func calc_beauty_at(pos: Vector2i, radius: int = 5) -> float:
	if not ThingManager:
		return 0.0
	var total: float = 0.0
	for t: Thing in ThingManager.things:
		if abs(t.grid_pos.x - pos.x) <= radius and abs(t.grid_pos.y - pos.y) <= radius:
			var quality: String = "Normal"
			if t.has_meta("quality"):
				quality = str(t.get_meta("quality"))
			total += get_thing_beauty(t.def_name, quality)
	return snappedf(total, 0.1)


func get_avg_beauty() -> float:
	if THING_BEAUTY.is_empty():
		return 0.0
	var total: float = 0.0
	for def_id: String in THING_BEAUTY:
		total += THING_BEAUTY[def_id]
	return snappedf(total / float(THING_BEAUTY.size()), 0.01)


func get_beauty_range() -> Dictionary:
	var low: float = 999.0
	var high: float = -999.0
	for def_id: String in THING_BEAUTY:
		var v: float = THING_BEAUTY[def_id]
		if v < low:
			low = v
		if v > high:
			high = v
	return {"min": snappedf(low, 0.1), "max": snappedf(high, 0.1)}


func get_positive_beauty_count() -> int:
	var count: int = 0
	for def_id: String in THING_BEAUTY:
		if THING_BEAUTY[def_id] > 0.0:
			count += 1
	return count


func get_aesthetic_rating() -> String:
	var avg: float = get_avg_beauty()
	if avg >= 5.0:
		return "Beautiful"
	elif avg >= 2.0:
		return "Pleasant"
	elif avg >= 0.0:
		return "Neutral"
	return "Ugly"

func get_beauty_spread() -> float:
	var r: Dictionary = get_beauty_range()
	return snappedf(r.get("max", 0.0) - r.get("min", 0.0), 0.1)

func get_category_balance() -> int:
	return get_beauty_by_category().size()

func get_summary() -> Dictionary:
	return {
		"thing_defs": THING_BEAUTY.size(),
		"quality_levels": QUALITY_MULTIPLIER.size(),
		"filth_penalty": FILTH_BEAUTY,
		"most_beautiful": get_most_beautiful(),
		"ugliest": get_ugliest(),
		"by_category": get_beauty_by_category(),
		"avg_beauty": get_avg_beauty(),
		"beauty_range": get_beauty_range(),
		"positive_count": get_positive_beauty_count(),
		"negative_count": THING_BEAUTY.size() - get_positive_beauty_count(),
		"positive_pct": snappedf(float(get_positive_beauty_count()) / maxf(float(THING_BEAUTY.size()), 1.0) * 100.0, 0.1),
		"aesthetic_rating": get_aesthetic_rating(),
		"beauty_spread": get_beauty_spread(),
		"category_balance": get_category_balance(),
		"aesthetic_consistency": get_aesthetic_consistency(),
		"beauty_investment_roi": get_beauty_investment_roi(),
		"visual_diversity": get_visual_diversity(),
		"aesthetic_ecosystem_health": get_aesthetic_ecosystem_health(),
		"design_philosophy_index": get_design_philosophy_index(),
		"beauty_governance": get_beauty_governance(),
	}

func get_aesthetic_ecosystem_health() -> float:
	var avg := get_avg_beauty()
	var positive := float(get_positive_beauty_count())
	var total := float(THING_BEAUTY.size())
	if total <= 0.0:
		return 0.0
	return snapped((positive / total * 50.0) + maxf(avg, 0.0) * 5.0, 0.1)

func get_design_philosophy_index() -> float:
	var consistency := get_aesthetic_consistency()
	var diversity := get_visual_diversity()
	var base: float = float(diversity) * 10.0
	if consistency == "Uniform":
		base *= 1.2
	elif consistency == "Inconsistent":
		base *= 0.7
	return snapped(minf(base, 100.0), 0.1)

func get_beauty_governance() -> String:
	var roi := get_beauty_investment_roi()
	var rating := get_aesthetic_rating()
	if roi == "High" and rating in ["Exquisite", "Beautiful"]:
		return "Masterful"
	elif roi == "Low" or rating in ["Ugly", "Plain"]:
		return "Neglected"
	return "Developing"

func get_aesthetic_consistency() -> String:
	var spread := get_beauty_spread()
	if spread <= 5.0:
		return "Uniform"
	elif spread <= 15.0:
		return "Varied"
	return "Inconsistent"

func get_beauty_investment_roi() -> String:
	var avg := get_avg_beauty()
	var positive := get_positive_beauty_count()
	if avg >= 3.0 and positive >= THING_BEAUTY.size() / 2:
		return "High"
	elif avg > 0.0:
		return "Moderate"
	return "Low"

func get_visual_diversity() -> float:
	var cats := get_beauty_by_category()
	if cats.is_empty():
		return 0.0
	return snapped(float(cats.size()) / maxf(float(THING_BEAUTY.size()), 1.0) * 100.0, 0.1)
