extends Node

const WEAPON_AP: Dictionary = {
	"Revolver": {"sharp_pen": 0.2, "blunt_pen": 0.1},
	"AssaultRifle": {"sharp_pen": 0.25, "blunt_pen": 0.12},
	"SniperRifle": {"sharp_pen": 0.4, "blunt_pen": 0.15},
	"Shotgun": {"sharp_pen": 0.15, "blunt_pen": 0.25},
	"ChargeRifle": {"sharp_pen": 0.35, "blunt_pen": 0.2},
	"Gladius": {"sharp_pen": 0.2, "blunt_pen": 0.15},
	"Longsword": {"sharp_pen": 0.25, "blunt_pen": 0.18},
	"Mace": {"sharp_pen": 0.05, "blunt_pen": 0.35},
	"Warhammer": {"sharp_pen": 0.08, "blunt_pen": 0.45},
	"PersonaMonosword": {"sharp_pen": 0.5, "blunt_pen": 0.3},
	"ChargeLance": {"sharp_pen": 0.55, "blunt_pen": 0.25},
	"InfernoCannon": {"sharp_pen": 0.3, "blunt_pen": 0.4}
}

const ARMOR_VALUES: Dictionary = {
	"Flak": {"sharp": 0.4, "blunt": 0.15, "heat": 0.2},
	"Marine": {"sharp": 0.7, "blunt": 0.4, "heat": 0.45},
	"Cataphract": {"sharp": 0.85, "blunt": 0.5, "heat": 0.55},
	"Recon": {"sharp": 0.55, "blunt": 0.3, "heat": 0.35},
	"Prestige": {"sharp": 0.75, "blunt": 0.45, "heat": 0.5},
	"Devilstrand": {"sharp": 0.3, "blunt": 0.1, "heat": 0.6},
	"Hyperweave": {"sharp": 0.5, "blunt": 0.2, "heat": 0.45},
	"Cloth": {"sharp": 0.08, "blunt": 0.02, "heat": 0.08}
}

func calc_damage_after_armor(weapon: String, armor: String, base_damage: float, damage_type: String) -> Dictionary:
	var pen: float = WEAPON_AP.get(weapon, {}).get(damage_type + "_pen", 0.0)
	var armor_val: float = ARMOR_VALUES.get(armor, {}).get(damage_type.replace("_pen", ""), 0.0)
	var effective_armor: float = maxf(0.0, armor_val - pen)
	var final_damage: float = base_damage * (1.0 - effective_armor)
	return {"base": base_damage, "armor": armor_val, "penetration": pen, "final_damage": maxf(0.0, final_damage)}

func get_highest_sharp_pen_weapon() -> String:
	var best: String = ""
	var best_v: float = 0.0
	for w: String in WEAPON_AP:
		if WEAPON_AP[w]["sharp_pen"] > best_v:
			best_v = WEAPON_AP[w]["sharp_pen"]
			best = w
	return best

func get_strongest_armor() -> String:
	var best: String = ""
	var best_v: float = 0.0
	for a: String in ARMOR_VALUES:
		var total: float = ARMOR_VALUES[a]["sharp"] + ARMOR_VALUES[a]["blunt"] + ARMOR_VALUES[a]["heat"]
		if total > best_v:
			best_v = total
			best = a
	return best

func get_weapon_effective_against(armor: String) -> String:
	if not ARMOR_VALUES.has(armor):
		return ""
	var armor_sharp: float = ARMOR_VALUES[armor]["sharp"]
	var best: String = ""
	var best_pen: float = 0.0
	for w: String in WEAPON_AP:
		if WEAPON_AP[w]["sharp_pen"] > best_pen:
			best_pen = WEAPON_AP[w]["sharp_pen"]
			best = w
	return best

func get_highest_blunt_pen_weapon() -> String:
	var best: String = ""
	var best_val: float = 0.0
	for w: String in WEAPON_AP:
		var v: float = float(WEAPON_AP[w].get("blunt_pen", 0.0))
		if v > best_val:
			best_val = v
			best = w
	return best


func get_avg_sharp_pen() -> float:
	if WEAPON_AP.is_empty():
		return 0.0
	var total: float = 0.0
	for w: String in WEAPON_AP:
		total += float(WEAPON_AP[w].get("sharp_pen", 0.0))
	return total / WEAPON_AP.size()


func get_heat_resistant_armor_count() -> int:
	var count: int = 0
	for a: String in ARMOR_VALUES:
		if float(ARMOR_VALUES[a].get("heat", 0.0)) >= 0.4:
			count += 1
	return count


func get_weakest_armor() -> String:
	var worst: String = ""
	var worst_v: float = 999.0
	for a: String in ARMOR_VALUES:
		var total: float = float(ARMOR_VALUES[a].get("sharp", 0)) + float(ARMOR_VALUES[a].get("blunt", 0)) + float(ARMOR_VALUES[a].get("heat", 0))
		if total < worst_v:
			worst_v = total
			worst = a
	return worst


func get_avg_blunt_pen() -> float:
	if WEAPON_AP.is_empty():
		return 0.0
	var total: float = 0.0
	for w: String in WEAPON_AP:
		total += float(WEAPON_AP[w].get("blunt_pen", 0.0))
	return total / WEAPON_AP.size()


func get_melee_weapon_count() -> int:
	var melee_names: Array = ["Gladius", "Longsword", "Mace", "Warhammer", "PersonaMonosword"]
	var count: int = 0
	for w: String in WEAPON_AP:
		if w in melee_names:
			count += 1
	return count


func get_arms_race_status() -> String:
	var avg_pen: float = (get_avg_sharp_pen() + get_avg_blunt_pen()) / 2.0
	var avg_armor: float = 0.0
	for a: String in ARMOR_VALUES:
		avg_armor += ARMOR_VALUES[a]["sharp"] + ARMOR_VALUES[a]["blunt"]
	if ARMOR_VALUES.size() > 0:
		avg_armor /= (ARMOR_VALUES.size() * 2.0)
	if avg_pen > avg_armor:
		return "offense_dominant"
	if avg_armor > avg_pen * 1.5:
		return "defense_dominant"
	return "balanced"

func get_vulnerability_coverage_pct() -> float:
	var covered: int = 0
	for a: String in ARMOR_VALUES:
		var has_counter: bool = false
		for w: String in WEAPON_AP:
			if WEAPON_AP[w]["sharp_pen"] > ARMOR_VALUES[a]["sharp"]:
				has_counter = true
				break
		if has_counter:
			covered += 1
	if ARMOR_VALUES.is_empty():
		return 0.0
	return snapped(covered * 100.0 / ARMOR_VALUES.size(), 0.1)

func get_tactical_diversity() -> String:
	var melee: int = get_melee_weapon_count()
	var ranged: int = WEAPON_AP.size() - melee
	if WEAPON_AP.is_empty():
		return "none"
	var ratio: float = minf(melee, ranged) * 1.0 / maxf(melee, ranged)
	if ratio >= 0.6:
		return "well_balanced"
	if ratio >= 0.3:
		return "moderate"
	return "specialized"

func get_summary() -> Dictionary:
	return {
		"weapon_count": WEAPON_AP.size(),
		"armor_count": ARMOR_VALUES.size(),
		"highest_sharp_pen": get_highest_sharp_pen_weapon(),
		"strongest_armor": get_strongest_armor(),
		"highest_blunt_pen": get_highest_blunt_pen_weapon(),
		"avg_sharp_pen": snapped(get_avg_sharp_pen(), 0.01),
		"heat_resistant_armors": get_heat_resistant_armor_count(),
		"weakest_armor": get_weakest_armor(),
		"avg_blunt_pen": snapped(get_avg_blunt_pen(), 0.01),
		"melee_weapons": get_melee_weapon_count(),
		"arms_race_status": get_arms_race_status(),
		"vulnerability_coverage_pct": get_vulnerability_coverage_pct(),
		"tactical_diversity": get_tactical_diversity(),
		"penetration_superiority": get_penetration_superiority(),
		"defense_gap_analysis": get_defense_gap_analysis(),
		"combat_matchup_score": get_combat_matchup_score(),
		"combat_ecosystem_health": get_combat_ecosystem_health(),
		"armament_governance": get_armament_governance(),
		"warfare_maturity_index": get_warfare_maturity_index(),
	}

func get_penetration_superiority() -> String:
	var avg_sharp := get_avg_sharp_pen()
	var avg_blunt := get_avg_blunt_pen()
	var combined := avg_sharp + avg_blunt
	if combined >= 50.0:
		return "Overwhelming"
	elif combined >= 25.0:
		return "Competitive"
	return "Outmatched"

func get_defense_gap_analysis() -> float:
	var heat_resistant := get_heat_resistant_armor_count()
	var total := ARMOR_VALUES.size()
	if total <= 0:
		return 0.0
	return snapped(float(heat_resistant) / float(total) * 100.0, 0.1)

func get_combat_matchup_score() -> String:
	var arms := get_arms_race_status()
	var vuln := get_vulnerability_coverage_pct()
	if arms in ["Dominant", "Superior"] and vuln >= 70.0:
		return "Decisive Advantage"
	elif vuln >= 40.0:
		return "Even Match"
	return "Disadvantaged"

func get_combat_ecosystem_health() -> float:
	var superiority := get_penetration_superiority()
	var s_val: float = 90.0 if superiority == "Overwhelming" else (60.0 if superiority == "Competitive" else 30.0)
	var matchup := get_combat_matchup_score()
	var m_val: float = 90.0 if matchup == "Decisive Advantage" else (60.0 if matchup == "Even Match" else 30.0)
	var gap := get_defense_gap_analysis()
	return snapped((s_val + m_val + gap) / 3.0, 0.1)

func get_warfare_maturity_index() -> float:
	var diversity := get_tactical_diversity()
	var d_val: float = 90.0 if diversity in ["balanced", "diverse"] else (60.0 if diversity in ["moderate", "mixed"] else 30.0)
	var coverage := get_vulnerability_coverage_pct()
	var arms := get_arms_race_status()
	var a_val: float = 90.0 if arms in ["Dominant", "Superior"] else (60.0 if arms in ["Competitive", "Balanced"] else 30.0)
	return snapped((d_val + coverage + a_val) / 3.0, 0.1)

func get_armament_governance() -> String:
	var ecosystem := get_combat_ecosystem_health()
	var maturity := get_warfare_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif WEAPON_AP.size() > 0:
		return "Nascent"
	return "Dormant"
