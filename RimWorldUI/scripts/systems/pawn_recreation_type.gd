extends Node

var _pawn_rec_needs: Dictionary = {}

const REC_TYPES: Dictionary = {
	"Social": {"joy_per_hour": 0.12, "facilities": ["Horseshoe", "ChessTable", "Campfire"]},
	"Relaxing": {"joy_per_hour": 0.10, "facilities": ["ArmChair", "Telescope", "EndTable"]},
	"Gaming": {"joy_per_hour": 0.14, "facilities": ["ChessTable", "PokerTable", "Billiards"]},
	"Physical": {"joy_per_hour": 0.11, "facilities": ["Horseshoe", "PunchingBag", "ExerciseBall"]},
	"Creative": {"joy_per_hour": 0.09, "facilities": ["SculptingBench", "Piano", "Guitar"]},
	"Meditative": {"joy_per_hour": 0.08, "facilities": ["MeditationSpot", "AnimaTree"]},
	"Chemical": {"joy_per_hour": 0.16, "facilities": ["BeerKeg", "SmokeleafJoint"], "risky": true},
	"Gluttonous": {"joy_per_hour": 0.15, "facilities": ["LavishMeal"], "weight_gain": true}
}

const TRAIT_PREFERENCES: Dictionary = {
	"Ascetic": ["Meditative", "Physical"],
	"Gourmand": ["Gluttonous", "Social"],
	"CreativeInspiration": ["Creative", "Relaxing"],
	"Psychopath": ["Gaming", "Physical"],
	"Kind": ["Social", "Creative"]
}

func get_preferred_types(pawn_trait: String) -> Array:
	return TRAIT_PREFERENCES.get(pawn_trait, ["Social", "Relaxing"])

func get_joy_rate(rec_type: String) -> float:
	return REC_TYPES.get(rec_type, {}).get("joy_per_hour", 0.10)

func get_facilities(rec_type: String) -> Array:
	return REC_TYPES.get(rec_type, {}).get("facilities", [])

func get_highest_joy_type() -> String:
	var best: String = ""
	var best_rate: float = 0.0
	for rt: String in REC_TYPES:
		var r: float = float(REC_TYPES[rt].get("joy_per_hour", 0.0))
		if r > best_rate:
			best_rate = r
			best = rt
	return best


func get_risky_types() -> Array[String]:
	var result: Array[String] = []
	for rt: String in REC_TYPES:
		if bool(REC_TYPES[rt].get("risky", false)):
			result.append(rt)
	return result


func get_all_facilities() -> Array[String]:
	var seen: Dictionary = {}
	for rt: String in REC_TYPES:
		for f: Variant in REC_TYPES[rt].get("facilities", []):
			seen[String(f)] = true
	var result: Array[String] = []
	for k: String in seen:
		result.append(k)
	return result


func get_summary() -> Dictionary:
	return {
		"recreation_types": REC_TYPES.size(),
		"trait_preferences": TRAIT_PREFERENCES.size(),
		"highest_joy": get_highest_joy_type(),
		"risky_count": get_risky_types().size(),
		"total_facilities": get_all_facilities().size(),
	}
