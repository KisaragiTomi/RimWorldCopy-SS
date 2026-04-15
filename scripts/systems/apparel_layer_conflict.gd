extends Node

const APPAREL_LAYERS: Dictionary = {
	"OnSkin": {"order": 0, "slots": ["Torso", "Legs"]},
	"Middle": {"order": 1, "slots": ["Torso", "Legs"]},
	"Shell": {"order": 2, "slots": ["Torso"]},
	"Overhead": {"order": 3, "slots": ["Head"]},
	"Belt": {"order": 4, "slots": ["Waist"]},
	"EyeCover": {"order": 5, "slots": ["Eyes"]}
}

const APPAREL_DEF: Dictionary = {
	"TShirt": {"layer": "OnSkin", "covers": ["Torso"]},
	"Pants": {"layer": "OnSkin", "covers": ["Legs"]},
	"ButtonDownShirt": {"layer": "Middle", "covers": ["Torso"]},
	"Parka": {"layer": "Shell", "covers": ["Torso"]},
	"FlakVest": {"layer": "Middle", "covers": ["Torso"]},
	"FlakJacket": {"layer": "Shell", "covers": ["Torso"]},
	"DusterCoat": {"layer": "Shell", "covers": ["Torso", "Legs"]},
	"SimpleHelmet": {"layer": "Overhead", "covers": ["Head"]},
	"FlakHelmet": {"layer": "Overhead", "covers": ["Head"]},
	"PowerArmor": {"layer": "Shell", "covers": ["Torso", "Legs"]},
	"PowerArmorHelmet": {"layer": "Overhead", "covers": ["Head"]},
	"Goggles": {"layer": "EyeCover", "covers": ["Eyes"]},
	"ShieldBelt": {"layer": "Belt", "covers": ["Waist"]},
	"SmokepopBelt": {"layer": "Belt", "covers": ["Waist"]}
}

func can_equip(current_gear: Array, new_apparel: String) -> Dictionary:
	if not APPAREL_DEF.has(new_apparel):
		return {"can_equip": false, "reason": "unknown_apparel"}
	var new_def: Dictionary = APPAREL_DEF[new_apparel]
	var conflicts: Array = []
	for gear: String in current_gear:
		if not APPAREL_DEF.has(gear):
			continue
		var gear_def: Dictionary = APPAREL_DEF[gear]
		if gear_def["layer"] == new_def["layer"]:
			for cover: String in new_def["covers"]:
				if cover in gear_def["covers"]:
					conflicts.append(gear)
					break
	return {"can_equip": conflicts.is_empty(), "conflicts": conflicts}

func get_layer_order(apparel_name: String) -> int:
	if not APPAREL_DEF.has(apparel_name):
		return -1
	var layer: String = APPAREL_DEF[apparel_name]["layer"]
	return APPAREL_LAYERS.get(layer, {}).get("order", -1)

func get_apparel_for_layer(layer: String) -> Array[String]:
	var result: Array[String] = []
	for a: String in APPAREL_DEF:
		if String(APPAREL_DEF[a].get("layer", "")) == layer:
			result.append(a)
	return result


func get_full_body_apparel() -> Array[String]:
	var result: Array[String] = []
	for a: String in APPAREL_DEF:
		if APPAREL_DEF[a].get("covers", []).size() > 1:
			result.append(a)
	return result


func get_avg_apparel_per_layer() -> float:
	if APPAREL_LAYERS.is_empty():
		return 0.0
	return float(APPAREL_DEF.size()) / APPAREL_LAYERS.size()


func get_most_crowded_layer() -> String:
	var counts: Dictionary = {}
	for a: String in APPAREL_DEF:
		var l: String = String(APPAREL_DEF[a].get("layer", ""))
		counts[l] = counts.get(l, 0) + 1
	var best: String = ""
	var best_count: int = 0
	for l: String in counts:
		if int(counts[l]) > best_count:
			best_count = int(counts[l])
			best = l
	return best


func get_empty_layers() -> Array[String]:
	var used: Dictionary = {}
	for a: String in APPAREL_DEF:
		used[String(APPAREL_DEF[a].get("layer", ""))] = true
	var result: Array[String] = []
	for l: String in APPAREL_LAYERS:
		if not used.has(l):
			result.append(l)
	return result


func get_head_cover_count() -> int:
	var count: int = 0
	for a: String in APPAREL_DEF:
		if "Head" in APPAREL_DEF[a].get("covers", []):
			count += 1
	return count


func get_unique_cover_slots() -> int:
	var slots: Dictionary = {}
	for a: String in APPAREL_DEF:
		for c in APPAREL_DEF[a].get("covers", []):
			slots[String(c)] = true
	return slots.size()


func get_belt_count() -> int:
	return get_apparel_for_layer("Belt").size()


func get_coverage_rating() -> String:
	var empty: int = get_empty_layers().size()
	if empty == 0:
		return "Full"
	elif empty <= 2:
		return "Good"
	elif empty <= APPAREL_LAYERS.size() / 2:
		return "Partial"
	return "Sparse"

func get_conflict_density() -> float:
	if APPAREL_LAYERS.is_empty():
		return 0.0
	var crowded: int = 0
	for layer: String in APPAREL_LAYERS:
		var count: int = 0
		for aid: String in APPAREL_DEF:
			var a: Dictionary = APPAREL_DEF[aid]
			if a.get("layers", []).has(layer):
				count += 1
		if count > 2:
			crowded += 1
	return snappedf(float(crowded) / float(APPAREL_LAYERS.size()) * 100.0, 0.1)

func get_versatility_score() -> float:
	if APPAREL_DEF.is_empty():
		return 0.0
	var multi: int = 0
	for aid: String in APPAREL_DEF:
		var a: Dictionary = APPAREL_DEF[aid]
		if a.get("layers", []).size() > 1:
			multi += 1
	return snappedf(float(multi) / float(APPAREL_DEF.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"layer_count": APPAREL_LAYERS.size(),
		"apparel_types": APPAREL_DEF.size(),
		"full_body_apparel": get_full_body_apparel().size(),
		"avg_per_layer": snapped(get_avg_apparel_per_layer(), 0.1),
		"most_crowded": get_most_crowded_layer(),
		"empty_layers": get_empty_layers().size(),
		"head_covers": get_head_cover_count(),
		"unique_slots": get_unique_cover_slots(),
		"belt_items": get_belt_count(),
		"coverage_rating": get_coverage_rating(),
		"conflict_density_pct": get_conflict_density(),
		"versatility_pct": get_versatility_score(),
		"outfit_harmony": get_outfit_harmony(),
		"layer_utilization": get_layer_utilization(),
		"wardrobe_flexibility": get_wardrobe_flexibility(),
		"outfit_ecosystem_health": get_outfit_ecosystem_health(),
		"wardrobe_governance": get_wardrobe_governance(),
		"fashion_maturity_index": get_fashion_maturity_index(),
	}

func get_outfit_harmony() -> String:
	var conflict := get_conflict_density()
	if conflict < 10.0:
		return "Harmonious"
	elif conflict < 30.0:
		return "Minor Conflicts"
	return "Conflicted"

func get_layer_utilization() -> float:
	var empty := get_empty_layers().size()
	var total := APPAREL_LAYERS.size()
	if total <= 0:
		return 0.0
	return snapped(float(total - empty) / float(total) * 100.0, 0.1)

func get_wardrobe_flexibility() -> String:
	var versatility := get_versatility_score()
	if versatility >= 70.0:
		return "Highly Flexible"
	elif versatility >= 40.0:
		return "Moderate"
	return "Rigid"

func get_outfit_ecosystem_health() -> float:
	var harmony := get_outfit_harmony()
	var h_val: float = 90.0 if harmony in ["Harmonious", "Perfect"] else (60.0 if harmony in ["Balanced", "Adequate"] else 30.0)
	var utilization := get_layer_utilization()
	var flexibility := get_wardrobe_flexibility()
	var f_val: float = 90.0 if flexibility == "Highly Flexible" else (60.0 if flexibility == "Moderate" else 30.0)
	return snapped((h_val + utilization + f_val) / 3.0, 0.1)

func get_fashion_maturity_index() -> float:
	var rating := get_coverage_rating()
	var r_val: float = 90.0 if rating in ["Full", "Excellent"] else (60.0 if rating in ["Good", "Adequate"] else 30.0)
	var conflict := get_conflict_density()
	var c_val: float = maxf(100.0 - conflict, 0.0)
	var versatility := get_versatility_score()
	return snapped((r_val + c_val + versatility) / 3.0, 0.1)

func get_wardrobe_governance() -> String:
	var ecosystem := get_outfit_ecosystem_health()
	var maturity := get_fashion_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif APPAREL_DEF.size() > 0:
		return "Nascent"
	return "Dormant"
