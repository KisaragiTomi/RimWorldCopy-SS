extends Node

const WEAPONS: Dictionary = {
	"Revolver": {"range": 25, "accuracy_touch": 0.80, "accuracy_short": 0.72, "accuracy_medium": 0.55, "accuracy_long": 0.35, "damage": 12, "cooldown": 1.6},
	"Autopistol": {"range": 25, "accuracy_touch": 0.70, "accuracy_short": 0.65, "accuracy_medium": 0.50, "accuracy_long": 0.30, "damage": 10, "cooldown": 1.2},
	"BoltAction": {"range": 36, "accuracy_touch": 0.50, "accuracy_short": 0.70, "accuracy_medium": 0.82, "accuracy_long": 0.78, "damage": 18, "cooldown": 2.5},
	"AssaultRifle": {"range": 30, "accuracy_touch": 0.60, "accuracy_short": 0.65, "accuracy_medium": 0.55, "accuracy_long": 0.40, "damage": 11, "cooldown": 1.6, "burst": 3},
	"SniperRifle": {"range": 44, "accuracy_touch": 0.30, "accuracy_short": 0.55, "accuracy_medium": 0.80, "accuracy_long": 0.90, "damage": 25, "cooldown": 3.5},
	"Shotgun": {"range": 15, "accuracy_touch": 0.90, "accuracy_short": 0.70, "accuracy_medium": 0.35, "accuracy_long": 0.15, "damage": 22, "cooldown": 2.0},
	"ChargeRifle": {"range": 30, "accuracy_touch": 0.65, "accuracy_short": 0.70, "accuracy_medium": 0.65, "accuracy_long": 0.55, "damage": 15, "cooldown": 1.8, "burst": 3},
	"MiniGun": {"range": 30, "accuracy_touch": 0.35, "accuracy_short": 0.30, "accuracy_medium": 0.20, "accuracy_long": 0.10, "damage": 10, "cooldown": 2.0, "burst": 25},
	"GreatBow": {"range": 32, "accuracy_touch": 0.50, "accuracy_short": 0.65, "accuracy_medium": 0.55, "accuracy_long": 0.40, "damage": 13, "cooldown": 2.3},
	"ChargeLance": {"range": 35, "accuracy_touch": 0.45, "accuracy_short": 0.60, "accuracy_medium": 0.75, "accuracy_long": 0.70, "damage": 30, "cooldown": 3.0}
}

func get_accuracy_at_range(weapon: String, distance: float) -> float:
	if not WEAPONS.has(weapon):
		return 0.0
	var w: Dictionary = WEAPONS[weapon]
	if distance > w["range"]:
		return 0.0
	var ratio: float = distance / w["range"]
	if ratio <= 0.1:
		return w["accuracy_touch"]
	elif ratio <= 0.35:
		return lerpf(w["accuracy_touch"], w["accuracy_short"], (ratio - 0.1) / 0.25)
	elif ratio <= 0.65:
		return lerpf(w["accuracy_short"], w["accuracy_medium"], (ratio - 0.35) / 0.30)
	else:
		return lerpf(w["accuracy_medium"], w["accuracy_long"], (ratio - 0.65) / 0.35)

func get_dps(weapon: String) -> float:
	if not WEAPONS.has(weapon):
		return 0.0
	var w: Dictionary = WEAPONS[weapon]
	var burst: int = w.get("burst", 1)
	return (w["damage"] * burst) / w["cooldown"]

func get_weapon_info(weapon: String) -> Dictionary:
	return WEAPONS.get(weapon, {})

func get_longest_range_weapon() -> String:
	var best: String = ""
	var best_range: int = 0
	for w: String in WEAPONS:
		var r: int = int(WEAPONS[w].get("range", 0))
		if r > best_range:
			best_range = r
			best = w
	return best


func get_highest_dps_weapon() -> String:
	var best: String = ""
	var best_dps: float = 0.0
	for w: String in WEAPONS:
		var d: float = get_dps(w)
		if d > best_dps:
			best_dps = d
			best = w
	return best


func get_burst_weapons() -> Array[String]:
	var result: Array[String] = []
	for w: String in WEAPONS:
		if WEAPONS[w].has("burst"):
			result.append(w)
	return result


func get_avg_dps() -> float:
	var total: float = 0.0
	for w: String in WEAPONS:
		total += get_dps(w)
	return total / maxf(WEAPONS.size(), 1)


func get_avg_range() -> float:
	var total: int = 0
	for w: String in WEAPONS:
		total += int(WEAPONS[w].get("range", 0))
	return float(total) / maxf(WEAPONS.size(), 1)


func get_short_range_count(threshold: int = 20) -> int:
	var count: int = 0
	for w: String in WEAPONS:
		if int(WEAPONS[w].get("range", 0)) <= threshold:
			count += 1
	return count


func get_highest_single_damage() -> String:
	var best: String = ""
	var best_dmg: int = 0
	for w: String in WEAPONS:
		var d: int = int(WEAPONS[w].get("damage", 0))
		if d > best_dmg:
			best_dmg = d
			best = w
	return best


func get_avg_accuracy_medium() -> float:
	if WEAPONS.is_empty():
		return 0.0
	var total: float = 0.0
	for w: String in WEAPONS:
		total += float(WEAPONS[w].get("accuracy_medium", 0.0))
	return snappedf(total / float(WEAPONS.size()), 0.01)


func get_range_spread() -> Dictionary:
	var lo: int = 999
	var hi: int = 0
	for w: String in WEAPONS:
		var r: int = int(WEAPONS[w].get("range", 0))
		if r < lo:
			lo = r
		if r > hi:
			hi = r
	return {"min": lo, "max": hi}


func get_firepower_tier() -> String:
	var avg: float = get_avg_dps()
	if avg >= 15.0:
		return "Heavy"
	elif avg >= 8.0:
		return "Medium"
	elif avg >= 4.0:
		return "Light"
	return "Minimal"

func get_engagement_range() -> String:
	var avg_r: float = get_avg_range()
	if avg_r >= 35.0:
		return "Long"
	elif avg_r >= 22.0:
		return "Medium"
	elif avg_r >= 12.0:
		return "Close"
	return "Melee"

func get_arsenal_diversity_pct() -> float:
	var burst: int = get_burst_weapons().size()
	var total: int = WEAPONS.size()
	if total == 0:
		return 0.0
	return snappedf(float(burst) / float(total) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"weapon_types": WEAPONS.size(),
		"longest_range": get_longest_range_weapon(),
		"highest_dps": get_highest_dps_weapon(),
		"burst_weapons": get_burst_weapons().size(),
		"avg_dps": snapped(get_avg_dps(), 0.1),
		"avg_range": snapped(get_avg_range(), 0.1),
		"short_range_count": get_short_range_count(),
		"highest_damage": get_highest_single_damage(),
		"avg_accuracy_medium": get_avg_accuracy_medium(),
		"range_spread": get_range_spread(),
		"firepower_tier": get_firepower_tier(),
		"engagement_range": get_engagement_range(),
		"arsenal_diversity_pct": get_arsenal_diversity_pct(),
		"weapons_superiority": get_weapons_superiority(),
		"combat_range_flexibility": get_combat_range_flexibility(),
		"damage_output_rating": get_damage_output_rating(),
		"arsenal_ecosystem_health": get_arsenal_ecosystem_health(),
		"tactical_governance": get_tactical_governance(),
		"firepower_maturity_index": get_firepower_maturity_index(),
	}

func get_weapons_superiority() -> String:
	var tier := get_firepower_tier()
	var diversity := get_arsenal_diversity_pct()
	if tier in ["Heavy", "Superior"] and diversity >= 50.0:
		return "Dominant"
	elif tier in ["Medium", "Heavy"]:
		return "Competitive"
	return "Outmatched"

func get_combat_range_flexibility() -> float:
	var spread_dict: Dictionary = get_range_spread()
	var spread_val: float = float(spread_dict.get("max", 0)) - float(spread_dict.get("min", 0))
	var short := get_short_range_count()
	var total := WEAPONS.size()
	if total <= 0:
		return 0.0
	return snapped((spread_val + float(total - short) / float(total) * 50.0), 0.1)

func get_damage_output_rating() -> String:
	var avg_dps := get_avg_dps()
	if avg_dps >= 15.0:
		return "Devastating"
	elif avg_dps >= 8.0:
		return "Strong"
	elif avg_dps > 0.0:
		return "Moderate"
	return "None"

func get_arsenal_ecosystem_health() -> float:
	var superiority := get_weapons_superiority()
	var s_val: float = 90.0 if superiority in ["Dominant", "Superior"] else (60.0 if superiority in ["Competitive", "Moderate"] else 30.0)
	var output := get_damage_output_rating()
	var o_val: float = 90.0 if output == "Devastating" else (70.0 if output == "Strong" else (40.0 if output == "Moderate" else 20.0))
	var diversity := get_arsenal_diversity_pct()
	return snapped((s_val + o_val + diversity) / 3.0, 0.1)

func get_firepower_maturity_index() -> float:
	var tier := get_firepower_tier()
	var t_val: float = 90.0 if tier in ["Overwhelming", "Superior"] else (60.0 if tier in ["Adequate", "Moderate"] else 30.0)
	var range_val := get_engagement_range()
	var r_val: float = 90.0 if range_val in ["Long", "Extended"] else (60.0 if range_val in ["Medium", "Standard"] else 30.0)
	var flexibility := get_combat_range_flexibility()
	return snapped((t_val + r_val + minf(flexibility, 100.0)) / 3.0, 0.1)

func get_tactical_governance() -> String:
	var ecosystem := get_arsenal_ecosystem_health()
	var maturity := get_firepower_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif WEAPONS.size() > 0:
		return "Nascent"
	return "Dormant"
