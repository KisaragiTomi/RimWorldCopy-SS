class_name JobGiverEquip
extends ThinkNode

## Issues an Equip job when there are unequipped apparel items available.
## Scores items by armor value and distance, preferring upgrades.

const APPAREL_SLOTS: Dictionary = {
	"SimpleHelmet": "HeadArmor",
	"FlakHelmet": "HeadArmor",
	"Parka": "Jacket",
	"FlakVest": "BodyArmor",
	"FlakJacket": "Jacket",
	"PlateArmor": "BodyArmor",
	"Tuque": "HeadArmor",
	"Shirt": "Shirt",
	"Pants": "Pants",
	"SimpleClothes": "Shirt",
	"PowerArmor": "BodyArmor",
	"Duster": "Jacket",
}

const APPAREL_VALUE: Dictionary = {
	"SimpleHelmet": 10, "FlakHelmet": 25, "Tuque": 5,
	"Parka": 15, "FlakVest": 30, "FlakJacket": 25,
	"PlateArmor": 40, "PowerArmor": 60, "Duster": 12,
	"Shirt": 5, "Pants": 5, "SimpleClothes": 5,
}


func get_available_apparel_count() -> int:
	if not ThingManager:
		return 0
	var cnt: int = 0
	for t: Thing in ThingManager.things:
		if t is Item and t.state == Thing.ThingState.SPAWNED:
			if APPAREL_SLOTS.has(t.def_name):
				cnt += 1
	return cnt


func get_best_available_armor() -> Dictionary:
	if not ThingManager:
		return {}
	var best: Item = null
	var best_val: int = 0
	for t: Thing in ThingManager.things:
		if t is Item and t.state == Thing.ThingState.SPAWNED:
			var v: int = APPAREL_VALUE.get(t.def_name, 0)
			if v > best_val:
				best_val = v
				best = t as Item
	if best == null:
		return {}
	return {"def_name": best.def_name, "value": best_val}


func get_poorly_equipped_pawns() -> Array[String]:
	var result: Array[String] = []
	if not PawnManager:
		return result
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.equipment == null:
			continue
		var total_val: int = 0
		for slot: String in p.equipment.slots:
			total_val += APPAREL_VALUE.get(p.equipment.slots[slot], 0)
		if total_val < 20:
			result.append(p.pawn_name)
	return result


func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.drafted or pawn.dead or pawn.downed:
		return {}
	if pawn.equipment == null:
		return {}
	if not ThingManager:
		return {}

	var best_item: Item = null
	var best_score: float = -999.0
	var best_slot: String = ""

	for t: Thing in ThingManager.things:
		if not (t is Item):
			continue
		var item := t as Item
		if item.state != Thing.ThingState.SPAWNED:
			continue
		var slot: String = APPAREL_SLOTS.get(item.def_name, "")
		if slot.is_empty():
			continue

		var current: String = pawn.equipment.slots.get(slot, "")
		var current_val: int = APPAREL_VALUE.get(current, 0)
		var new_val: int = APPAREL_VALUE.get(item.def_name, 5)
		if new_val <= current_val:
			continue

		var dist: float = float(absi(item.grid_pos.x - pawn.grid_pos.x) + absi(item.grid_pos.y - pawn.grid_pos.y))
		var score: float = float(new_val - current_val) * 2.0 - dist * 0.5
		if score > best_score:
			best_score = score
			best_item = item
			best_slot = slot

	if best_item == null:
		return {}

	if pawn.equipment.slots.get(best_slot, "") != "":
		var old_name: String = pawn.equipment.slots[best_slot]
		if ColonyLog:
			ColonyLog.add_entry("Equip", "%s swaps %s for %s." % [pawn.pawn_name, old_name, best_item.def_name], "info")

	var job := Job.new()
	job.job_def = "Equip"
	job.target_pos = best_item.grid_pos
	job.meta_data = {"item_def": best_item.def_name, "slot": best_slot}
	return {"job": job}


func get_avg_pawn_armor_value() -> float:
	if not PawnManager:
		return 0.0
	var total: float = 0.0
	var cnt: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.equipment == null:
			continue
		cnt += 1
		for slot: String in p.equipment.slots:
			total += float(APPAREL_VALUE.get(p.equipment.slots[slot], 0))
	if cnt == 0:
		return 0.0
	return total / float(cnt)


func get_equip_rate() -> float:
	if not PawnManager:
		return 0.0
	var total: int = 0
	var equipped: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		total += 1
		if p.equipment and not p.equipment.slots.is_empty():
			equipped += 1
	if total <= 0:
		return 0.0
	return snappedf(float(equipped) / float(total) * 100.0, 0.1)


func get_naked_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if p.equipment == null or p.equipment.slots.is_empty():
			count += 1
	return count


func get_armor_coverage() -> String:
	var avg: float = get_avg_pawn_armor_value()
	if avg >= 3.0:
		return "Heavy"
	elif avg >= 1.5:
		return "Medium"
	elif avg > 0.0:
		return "Light"
	return "None"


func get_equipment_gap() -> String:
	var poorly := get_poorly_equipped_pawns().size()
	var naked := get_naked_count()
	if naked > 0:
		return "Critical"
	elif poorly > 3:
		return "Severe"
	elif poorly > 0:
		return "Moderate"
	return "None"

func get_defensive_posture() -> float:
	var avg := get_avg_pawn_armor_value()
	var rate := get_equip_rate()
	return snapped((avg * 30.0 + rate * 0.7), 0.1)

func get_wardrobe_adequacy() -> String:
	var available := get_available_apparel_count()
	var naked := get_naked_count()
	var poorly := get_poorly_equipped_pawns().size()
	if available <= 0 and naked > 0:
		return "Destitute"
	elif naked > 0 or poorly > 3:
		return "Insufficient"
	elif available < poorly * 2:
		return "Tight"
	return "Sufficient"

func get_equip_summary() -> Dictionary:
	return {
		"available_apparel": get_available_apparel_count(),
		"best_armor": get_best_available_armor(),
		"poorly_equipped": get_poorly_equipped_pawns().size(),
		"avg_armor_value": snappedf(get_avg_pawn_armor_value(), 0.1),
		"equip_rate_pct": get_equip_rate(),
		"naked_count": get_naked_count(),
		"armor_coverage": get_armor_coverage(),
		"equipment_gap": get_equipment_gap(),
		"defensive_posture": get_defensive_posture(),
		"wardrobe_adequacy": get_wardrobe_adequacy(),
		"equip_ecosystem_health": get_equip_ecosystem_health(),
		"armor_governance": get_armor_governance(),
		"outfitting_maturity_index": get_outfitting_maturity_index(),
	}

func get_equip_ecosystem_health() -> float:
	var gap := get_equipment_gap()
	var g_val: float = 90.0 if gap == "None" else (65.0 if gap == "Minor" else (35.0 if gap == "Significant" else 10.0))
	var posture := get_defensive_posture()
	var adequacy := get_wardrobe_adequacy()
	var a_val: float = 90.0 if adequacy == "Surplus" else (65.0 if adequacy == "Adequate" else (35.0 if adequacy == "Short" else 10.0))
	return snapped((g_val + minf(posture, 100.0) + a_val) / 3.0, 0.1)

func get_armor_governance() -> String:
	var eco := get_equip_ecosystem_health()
	var mat := get_outfitting_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_available_apparel_count() > 0:
		return "Nascent"
	return "Dormant"

func get_outfitting_maturity_index() -> float:
	var rate := get_equip_rate()
	var posture := minf(get_defensive_posture(), 100.0)
	var armor := minf(get_avg_pawn_armor_value() * 100.0, 100.0)
	return snapped((rate + posture + armor) / 3.0, 0.1)
