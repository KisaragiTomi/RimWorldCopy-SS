class_name PawnEquipment
extends RefCounted

## Equipment and apparel component for a Pawn.

signal equipment_changed(slot: String, item_name: String)

enum Layer { SKIN, MIDDLE, SHELL, OVERHEAD }

var slots: Dictionary = {
	"Weapon": "",
	"HeadArmor": "",
	"BodyArmor": "",
	"Pants": "",
	"Shirt": "",
	"Jacket": "",
}

var _armor_sharp: float = 0.0
var _armor_blunt: float = 0.0
var _move_speed_factor: float = 1.0
var _insulation_cold: float = 0.0
var _insulation_heat: float = 0.0

const ARMOR_DATA: Dictionary = {
	"FlakVest": {"sharp": 0.36, "blunt": 0.10, "cold": 5.0, "heat": 2.0, "speed": 1.0},
	"FlakJacket": {"sharp": 0.30, "blunt": 0.08, "cold": 8.0, "heat": 3.0, "speed": 0.97},
	"PlateArmor": {"sharp": 0.50, "blunt": 0.20, "cold": 3.0, "heat": -5.0, "speed": 0.85},
	"SimpleHelmet": {"sharp": 0.20, "blunt": 0.08, "cold": 2.0, "heat": 1.0, "speed": 1.0},
	"FlakHelmet": {"sharp": 0.40, "blunt": 0.12, "cold": 3.0, "heat": 1.0, "speed": 1.0},
	"Parka": {"sharp": 0.02, "blunt": 0.0, "cold": 20.0, "heat": -8.0, "speed": 0.95},
	"Tuque": {"sharp": 0.0, "blunt": 0.0, "cold": 8.0, "heat": -2.0, "speed": 1.0},
	"Duster": {"sharp": 0.05, "blunt": 0.02, "cold": -3.0, "heat": 15.0, "speed": 1.0},
	"TribalWear": {"sharp": 0.0, "blunt": 0.0, "cold": 5.0, "heat": 5.0, "speed": 1.0},
	"PowerArmor": {"sharp": 0.60, "blunt": 0.30, "cold": 10.0, "heat": 5.0, "speed": 0.80},
}

const WEAPON_DAMAGE: Dictionary = {
	"Knife": 8.0, "Longsword": 14.0, "Mace": 12.0, "Spear": 11.0, "Club": 9.0,
	"ShortBow": 7.0, "Revolver": 8.0, "Rifle": 10.0, "SniperRifle": 18.0,
	"MachineGun": 6.0, "ChargeLance": 22.0,
}


func equip(slot: String, item_name: String) -> bool:
	if not slots.has(slot):
		return false
	slots[slot] = item_name
	_recalc_stats()
	equipment_changed.emit(slot, item_name)
	return true


func unequip(slot: String) -> String:
	if not slots.has(slot):
		return ""
	var old: String = slots[slot]
	slots[slot] = ""
	_recalc_stats()
	equipment_changed.emit(slot, "")
	return old


func get_weapon() -> String:
	return slots.get("Weapon", "")


func get_weapon_damage() -> float:
	var w: String = get_weapon()
	return WEAPON_DAMAGE.get(w, 8.0)


func is_ranged_weapon() -> bool:
	var w: String = get_weapon()
	return w in ["ShortBow", "Revolver", "Rifle", "SniperRifle", "MachineGun", "ChargeLance"]


func get_armor_sharp() -> float:
	return _armor_sharp


func get_armor_blunt() -> float:
	return _armor_blunt


func get_move_speed_factor() -> float:
	return _move_speed_factor


func get_insulation_cold() -> float:
	return _insulation_cold


func get_insulation_heat() -> float:
	return _insulation_heat


func get_equipped_count() -> int:
	var count: int = 0
	for slot: String in slots:
		if not slots[slot].is_empty():
			count += 1
	return count


func has_any_armor() -> bool:
	return _armor_sharp > 0.0 or _armor_blunt > 0.0


func _recalc_stats() -> void:
	_armor_sharp = 0.0
	_armor_blunt = 0.0
	_move_speed_factor = 1.0
	_insulation_cold = 0.0
	_insulation_heat = 0.0

	for slot: String in slots:
		var item: String = slots[slot]
		if item.is_empty() or slot == "Weapon":
			continue
		if ARMOR_DATA.has(item):
			var data: Dictionary = ARMOR_DATA[item]
			_armor_sharp += data.get("sharp", 0.0)
			_armor_blunt += data.get("blunt", 0.0)
			_insulation_cold += data.get("cold", 0.0)
			_insulation_heat += data.get("heat", 0.0)
			_move_speed_factor = minf(_move_speed_factor, data.get("speed", 1.0))


func to_dict() -> Dictionary:
	return {
		"slots": slots.duplicate(),
		"armor_sharp": snappedf(_armor_sharp, 0.01),
		"armor_blunt": snappedf(_armor_blunt, 0.01),
		"move_speed": snappedf(_move_speed_factor, 0.01),
		"insulation_cold": snappedf(_insulation_cold, 0.1),
		"insulation_heat": snappedf(_insulation_heat, 0.1),
	}


func get_empty_slots() -> Array[String]:
	var result: Array[String] = []
	for slot: String in slots:
		if slots[slot].is_empty():
			result.append(slot)
	return result

func get_best_armor_piece() -> String:
	var best: String = ""
	var best_v: float = 0.0
	for slot: String in slots:
		var item: String = slots[slot]
		if item.is_empty() or slot == "Weapon":
			continue
		if ARMOR_DATA.has(item):
			var v: float = ARMOR_DATA[item].get("sharp", 0.0)
			if v > best_v:
				best_v = v
				best = item
	return best

func get_total_weight_penalty() -> float:
	return 1.0 - _move_speed_factor

func get_avg_armor_sharp_all() -> float:
	var total: float = 0.0
	if ARMOR_DATA.is_empty():
		return 0.0
	for k: String in ARMOR_DATA:
		total += ARMOR_DATA[k].get("sharp", 0.0)
	return snappedf(total / float(ARMOR_DATA.size()), 0.01)

func get_total_insulation() -> float:
	return snappedf(_insulation_cold + _insulation_heat, 0.1)

func get_heavy_armor_count() -> int:
	var count: int = 0
	for k: String in ARMOR_DATA:
		if ARMOR_DATA[k].get("speed", 1.0) < 0.9:
			count += 1
	return count

func get_total_weapon_types() -> int:
	return WEAPON_DAMAGE.size()

func get_best_cold_armor() -> String:
	var best: String = ""
	var best_v: float = -999.0
	for k: String in ARMOR_DATA:
		var v: float = ARMOR_DATA[k].get("cold", 0.0)
		if v > best_v:
			best_v = v
			best = k
	return best

func get_zero_penalty_armor_count() -> int:
	var count: int = 0
	for k: String in ARMOR_DATA:
		if ARMOR_DATA[k].get("speed", 1.0) >= 1.0:
			count += 1
	return count

func get_protection_score() -> float:
	var sharp := get_armor_sharp()
	var blunt := get_armor_blunt()
	return snapped((sharp + blunt) / 2.0 * 100.0, 0.1)

func get_loadout_efficiency_pct() -> float:
	var equipped := get_equipped_count()
	return snapped(float(equipped) / maxf(slots.size(), 1.0) * 100.0, 0.1)

func get_thermal_balance() -> float:
	var cold := get_insulation_cold()
	var heat := get_insulation_heat()
	return snapped(cold + heat, 0.1)

func get_summary() -> Dictionary:
	var d: Dictionary = to_dict()
	d["empty_slots"] = get_empty_slots().size()
	d["best_armor_piece"] = get_best_armor_piece()
	d["avg_armor_sharp_all"] = get_avg_armor_sharp_all()
	d["total_insulation"] = get_total_insulation()
	d["heavy_armor_types"] = get_heavy_armor_count()
	d["total_weapon_types"] = get_total_weapon_types()
	d["best_cold_armor"] = get_best_cold_armor()
	d["zero_penalty_armor"] = get_zero_penalty_armor_count()
	d["protection_score"] = get_protection_score()
	d["loadout_efficiency_pct"] = get_loadout_efficiency_pct()
	d["thermal_balance"] = get_thermal_balance()
	d["gear_ecosystem_health"] = get_gear_ecosystem_health()
	d["loadout_governance"] = get_loadout_governance()
	d["armament_maturity_index"] = get_armament_maturity_index()
	return d

func get_gear_ecosystem_health() -> float:
	var prot := get_protection_score()
	var eff := get_loadout_efficiency_pct()
	var thermal := minf(absf(get_thermal_balance()), 100.0)
	return snapped((minf(prot, 100.0) + eff + thermal) / 3.0, 0.1)

func get_loadout_governance() -> String:
	var eco := get_gear_ecosystem_health()
	var mat := get_armament_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_equipped_count() > 0:
		return "Nascent"
	return "Dormant"

func get_armament_maturity_index() -> float:
	var eff := get_loadout_efficiency_pct()
	var types := minf(float(get_total_weapon_types()) * 20.0, 100.0)
	var prot := minf(get_protection_score(), 100.0)
	return snapped((eff + types + prot) / 3.0, 0.1)
