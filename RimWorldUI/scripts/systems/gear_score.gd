extends Node

const SLOT_WEIGHTS: Dictionary = {
	"Head": 2.0,
	"Torso": 3.0,
	"Legs": 1.5,
	"Weapon": 4.0,
	"Shield": 2.5,
	"Utility": 1.0,
}

const BASE_ARMOR_VALUES: Dictionary = {
	"Flak Jacket": 30.0,
	"Flak Vest": 25.0,
	"Power Armor": 60.0,
	"Marine Armor": 70.0,
	"Simple Helmet": 10.0,
	"Flak Helmet": 20.0,
	"Marine Helmet": 40.0,
}

const BASE_WEAPON_VALUES: Dictionary = {
	"Bolt-action rifle": 25.0,
	"Assault rifle": 35.0,
	"Charge rifle": 45.0,
	"Sniper rifle": 40.0,
	"Revolver": 15.0,
	"Knife": 8.0,
	"Longsword": 18.0,
	"Mace": 14.0,
}


func calc_pawn_score(pawn: Pawn) -> float:
	if pawn.equipment == null:
		return 0.0
	var total: float = 0.0
	var equip_data: Dictionary = {}
	if pawn.equipment.has_method("to_dict"):
		equip_data = pawn.equipment.to_dict()
	for slot: String in equip_data:
		var item_name: String = str(equip_data[slot])
		if item_name.is_empty():
			continue
		var base_value: float = BASE_ARMOR_VALUES.get(item_name, 0.0)
		if base_value == 0.0:
			base_value = BASE_WEAPON_VALUES.get(item_name, 5.0)
		var weight: float = SLOT_WEIGHTS.get(slot, 1.0)
		total += base_value * weight
	var shooting: int = 0
	var melee: int = 0
	if pawn.skills.has("Shooting"):
		var sdata: Dictionary = pawn.skills["Shooting"]
		shooting = int(sdata.get("level", 0))
	if pawn.skills.has("Melee"):
		var mdata: Dictionary = pawn.skills["Melee"]
		melee = int(mdata.get("level", 0))
	var skill_bonus: float = maxf(float(shooting), float(melee)) * 2.0
	return snappedf(total + skill_bonus, 0.1)


func get_colony_average() -> float:
	if not PawnManager:
		return 0.0
	var total: float = 0.0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		total += calc_pawn_score(p)
		count += 1
	if count == 0:
		return 0.0
	return snappedf(total / float(count), 0.1)


func get_colony_total() -> float:
	if not PawnManager:
		return 0.0
	var total: float = 0.0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			total += calc_pawn_score(p)
	return snappedf(total, 0.1)


func get_all_scores() -> Array[Dictionary]:
	if not PawnManager:
		return []
	var result: Array[Dictionary] = []
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		result.append({
			"pawn_id": p.id,
			"pawn_name": p.pawn_name,
			"gear_score": calc_pawn_score(p),
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.gear_score > b.gear_score
	)
	return result


func get_best_equipped() -> Dictionary:
	var scores := get_all_scores()
	if scores.is_empty():
		return {}
	return scores[0]


func get_worst_equipped() -> Dictionary:
	var scores := get_all_scores()
	if scores.is_empty():
		return {}
	return scores[-1]


func get_unarmed_pawns() -> Array[int]:
	var result: Array[int] = []
	if not PawnManager:
		return result
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if p.equipment == null:
			result.append(p.id)
			continue
		var equip_data: Dictionary = {}
		if p.equipment.has_method("to_dict"):
			equip_data = p.equipment.to_dict()
		var has_weapon: bool = false
		for slot: String in equip_data:
			var item_name: String = str(equip_data[slot])
			if BASE_WEAPON_VALUES.has(item_name):
				has_weapon = true
				break
		if not has_weapon:
			result.append(p.id)
	return result


func get_score_distribution() -> Dictionary:
	var dist: Dictionary = {"low": 0, "medium": 0, "high": 0, "elite": 0}
	var scores := get_all_scores()
	for s: Dictionary in scores:
		var v: float = s.gear_score
		if v >= 200.0:
			dist.elite += 1
		elif v >= 100.0:
			dist.high += 1
		elif v >= 40.0:
			dist.medium += 1
		else:
			dist.low += 1
	return dist


func get_combat_readiness() -> String:
	var dist := get_score_distribution()
	var total: int = dist.low + dist.medium + dist.high + dist.elite
	if total == 0:
		return "Unknown"
	var armed_pct: float = float(dist.high + dist.elite) / float(total)
	if armed_pct >= 0.7:
		return "Battle-Ready"
	elif armed_pct >= 0.4:
		return "Adequate"
	elif armed_pct >= 0.2:
		return "Underprepared"
	return "Vulnerable"


func get_gear_gap() -> float:
	var best := get_best_equipped()
	var worst := get_worst_equipped()
	if best.is_empty() or worst.is_empty():
		return 0.0
	return snappedf(best.get("gear_score", 0.0) - worst.get("gear_score", 0.0), 0.1)


func get_elite_count() -> int:
	return get_score_distribution().get("elite", 0)


func get_equipment_health() -> String:
	var readiness: String = get_combat_readiness()
	if readiness == "Battle-Ready":
		return "Excellent"
	elif readiness == "Prepared":
		return "Good"
	elif readiness == "Under-equipped":
		return "Weak"
	return "Critical"

func get_gear_equality() -> float:
	var gap: float = get_gear_gap()
	return snappedf(maxf(0.0, 100.0 - gap), 0.1)

func get_armed_ratio() -> float:
	var all := get_all_scores()
	if all.is_empty():
		return 0.0
	var armed: int = all.size() - get_unarmed_pawns().size()
	return snappedf(float(armed) / float(all.size()) * 100.0, 0.1)

func get_combat_coverage() -> float:
	var armed := get_armed_ratio()
	var equality := get_gear_equality()
	return snapped((armed * 0.6 + equality * 0.4), 0.1)

func get_gear_investment_roi() -> String:
	var avg := get_colony_average()
	var elite := get_elite_count()
	var total := get_all_scores().size()
	if total <= 0:
		return "N/A"
	var elite_ratio := float(elite) / float(total)
	if avg >= 80.0 and elite_ratio >= 0.5:
		return "Excellent"
	elif avg >= 50.0:
		return "Good"
	elif avg > 0.0:
		return "Poor"
	return "None"

func get_equipment_balance() -> String:
	var gap := get_gear_gap()
	var equality := get_gear_equality()
	if gap <= 15.0 and equality >= 80.0:
		return "Well Balanced"
	elif gap <= 40.0:
		return "Moderate"
	return "Imbalanced"

func get_summary() -> Dictionary:
	return {
		"colony_average": get_colony_average(),
		"colony_total": get_colony_total(),
		"pawn_scores": get_all_scores(),
		"best": get_best_equipped(),
		"worst": get_worst_equipped(),
		"unarmed_count": get_unarmed_pawns().size(),
		"distribution": get_score_distribution(),
		"readiness": get_combat_readiness(),
		"gear_gap": get_gear_gap(),
		"elite_count": get_elite_count(),
		"elite_pct": snappedf(float(get_elite_count()) / maxf(float(get_all_scores().size()), 1.0) * 100.0, 0.1),
		"unarmed_pct": snappedf(float(get_unarmed_pawns().size()) / maxf(float(get_all_scores().size()), 1.0) * 100.0, 0.1),
		"equipment_health": get_equipment_health(),
		"gear_equality": get_gear_equality(),
		"armed_ratio_pct": get_armed_ratio(),
		"combat_coverage": get_combat_coverage(),
		"gear_investment_roi": get_gear_investment_roi(),
		"equipment_balance": get_equipment_balance(),
		"armory_readiness_index": get_armory_readiness_index(),
		"tactical_capability": get_tactical_capability(),
		"equipment_lifecycle_health": get_equipment_lifecycle_health(),
	}

func get_armory_readiness_index() -> float:
	var armed := get_armed_ratio()
	var avg := get_colony_average()
	return snapped((armed * 0.5 + avg * 0.5), 0.1)

func get_tactical_capability() -> String:
	var readiness := get_combat_readiness()
	var balance := get_equipment_balance()
	if readiness == "Battle-Ready" and balance == "Well Balanced":
		return "Elite"
	elif readiness in ["Battle-Ready", "Armed"]:
		return "Capable"
	elif readiness == "Unarmed":
		return "Defenseless"
	return "Basic"

func get_equipment_lifecycle_health() -> float:
	var roi := get_gear_investment_roi()
	var equality := get_gear_equality()
	var base: float = equality
	if roi == "Excellent":
		base *= 1.3
	elif roi == "Poor":
		base *= 0.6
	return snapped(clampf(base, 0.0, 100.0), 0.1)
