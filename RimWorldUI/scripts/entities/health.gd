class_name PawnHealth
extends RefCounted

## Health component for a Pawn. Tracks body parts, injuries, and conditions.

signal pawn_downed(pawn_id: int)
signal pawn_died(pawn_id: int)

var pawn_id: int = 0

var body_parts: Array[Dictionary] = []
var hediffs: Array[Dictionary] = []
var is_dead: bool = false
var is_downed: bool = false

var _bleed_rate: float = 0.0
var _pain_total: float = 0.0
var _consciousness: float = 1.0


func _init(p_id: int = 0) -> void:
	pawn_id = p_id
	_init_body()


func _init_body() -> void:
	body_parts = [
		_part("Torso", 40, true),
		_part("Head", 25, true),
		_part("LeftArm", 20, false),
		_part("RightArm", 20, false),
		_part("LeftLeg", 20, false),
		_part("RightLeg", 20, false),
		_part("LeftEye", 10, false),
		_part("RightEye", 10, false),
	]


func _part(pname: String, max_hp: int, vital: bool) -> Dictionary:
	return {"name": pname, "hp": max_hp, "max_hp": max_hp, "vital": vital, "destroyed": false}


func get_part(pname: String) -> Dictionary:
	for bp: Dictionary in body_parts:
		if bp.name == pname:
			return bp
	return {}


func add_injury(part_name: String, damage: float, damage_type: String = "Cut") -> Dictionary:
	var part := get_part(part_name)
	if part.is_empty() or part.destroyed:
		return {}

	var actual_dmg := minf(damage, part.hp)
	part["hp"] = part.hp - actual_dmg

	var hediff := {
		"type": "Injury",
		"damage_type": damage_type,
		"part": part_name,
		"severity": actual_dmg,
		"bleed_rate": _calc_bleed(damage_type, actual_dmg),
		"tended": false,
		"immunity": 0.0,
	}
	hediffs.append(hediff)

	if part.hp <= 0:
		part["destroyed"] = true
		if part.vital:
			die("Vital part destroyed: " + part_name)

	_recalc()
	return hediff


func add_disease(disease_name: String, severity: float = 0.2) -> Dictionary:
	var hediff := {
		"type": "Disease",
		"damage_type": disease_name,
		"part": "Torso",
		"severity": severity,
		"bleed_rate": 0.0,
		"tended": false,
		"immunity": 0.0,
	}
	hediffs.append(hediff)
	_recalc()
	return hediff


func tend_injury(hediff_idx: int, quality: float = 0.5) -> void:
	if hediff_idx < 0 or hediff_idx >= hediffs.size():
		return
	var h: Dictionary = hediffs[hediff_idx]
	h["tended"] = true
	h["bleed_rate"] = h.bleed_rate * (1.0 - quality)
	_recalc()


func tick_health() -> void:
	if is_dead:
		return

	if _bleed_rate > 0.0:
		var torso := get_part("Torso")
		if not torso.is_empty():
			torso["hp"] = maxi(0, torso.hp - ceili(_bleed_rate * 0.3))
			if torso.hp <= 0:
				torso["destroyed"] = true
				die("Bled out")
				return

	var i := hediffs.size() - 1
	while i >= 0:
		var h: Dictionary = hediffs[i]
		if h.type == "Injury" and h.tended:
			h["severity"] = maxf(0.0, h.severity - 0.02)
			if h.severity <= 0.0:
				hediffs.remove_at(i)
		elif h.type == "Disease":
			h["immunity"] = minf(1.0, h.immunity + 0.008)
			if not h.tended:
				h["severity"] = minf(1.0, h.severity + 0.005)
			else:
				h["severity"] = maxf(0.0, h.severity - 0.003)
			if h.immunity >= 1.0 or h.severity <= 0.0:
				hediffs.remove_at(i)
			elif h.severity >= 1.0:
				die("Disease: " + h.damage_type)
				return
		i -= 1

	_recalc()
	if _pain_total >= 0.8 and not is_downed:
		is_downed = true
		pawn_downed.emit(pawn_id)


func die(cause: String) -> void:
	is_dead = true
	_consciousness = 0.0
	pawn_died.emit(pawn_id)


func _calc_bleed(damage_type: String, severity: float) -> float:
	match damage_type:
		"Cut", "Stab":
			return severity * 0.06
		"Bullet":
			return severity * 0.04
		"Blunt":
			return severity * 0.01
		_:
			return severity * 0.02


func _recalc() -> void:
	_bleed_rate = 0.0
	_pain_total = 0.0
	for h: Dictionary in hediffs:
		_bleed_rate += h.bleed_rate
		_pain_total += h.severity * 0.04

	var leg_count := 0
	var arm_count := 0
	for bp: Dictionary in body_parts:
		if not bp.destroyed:
			if bp.name.ends_with("Leg"):
				leg_count += 1
			elif bp.name.ends_with("Arm"):
				arm_count += 1

	_consciousness = clampf(1.0 - _pain_total, 0.0, 1.0)


func is_bleeding() -> bool:
	return _bleed_rate > 0.0


func should_be_dead() -> bool:
	if is_dead:
		return true
	for bp: Dictionary in body_parts:
		if bp.vital and bp.destroyed:
			return true
	return false


func should_be_downed() -> bool:
	return _pain_total >= 0.8 or _consciousness <= 0.1


func get_overall_health() -> float:
	var total_hp: float = 0.0
	var total_max: float = 0.0
	for bp: Dictionary in body_parts:
		total_hp += float(bp.hp)
		total_max += float(bp.max_hp)
	if total_max <= 0.0:
		return 0.0
	return total_hp / total_max


func get_move_factor() -> float:
	var factor: float = 1.0
	for bp: Dictionary in body_parts:
		if bp.name.ends_with("Leg") and bp.destroyed:
			factor *= 0.4
		elif bp.name.ends_with("Leg"):
			factor *= lerpf(0.6, 1.0, float(bp.hp) / float(bp.max_hp))
	factor *= clampf(1.0 - _pain_total * 0.3, 0.3, 1.0)
	return factor


func get_manipulation() -> float:
	var factor: float = 1.0
	for bp: Dictionary in body_parts:
		if bp.name.ends_with("Arm") and bp.destroyed:
			factor *= 0.3
		elif bp.name.ends_with("Arm"):
			factor *= lerpf(0.5, 1.0, float(bp.hp) / float(bp.max_hp))
	return factor


func count_untended() -> int:
	var count: int = 0
	for h: Dictionary in hediffs:
		if not h.get("tended", false):
			count += 1
	return count


func get_worst_hediff() -> Dictionary:
	var worst: Dictionary = {}
	var worst_sev: float = 0.0
	for h: Dictionary in hediffs:
		if h.get("severity", 0.0) > worst_sev:
			worst_sev = h["severity"]
			worst = h
	return worst


func get_avg_part_health_pct() -> float:
	var total: float = 0.0
	if body_parts.is_empty():
		return 0.0
	for bp: Dictionary in body_parts:
		if bp.get("max_hp", 0) > 0:
			total += float(bp.hp) / float(bp.max_hp)
	return snappedf(total / float(body_parts.size()), 0.01)

func get_disease_count() -> int:
	var count: int = 0
	for h: Dictionary in hediffs:
		if h.get("type", "") == "Disease":
			count += 1
	return count

func get_total_bleed_sources() -> int:
	var count: int = 0
	for h: Dictionary in hediffs:
		if h.get("bleed_rate", 0.0) > 0.0:
			count += 1
	return count

func get_vital_parts_healthy() -> int:
	var count: int = 0
	for bp: Dictionary in body_parts:
		if bp.get("vital", false) and not bp.get("destroyed", false):
			count += 1
	return count

func get_worst_part_pct() -> float:
	var worst: float = 1.0
	for bp: Dictionary in body_parts:
		if bp.get("destroyed", false):
			continue
		var mx: int = bp.get("max_hp", 1)
		if mx > 0:
			var pct: float = float(bp.get("hp", 0)) / float(mx)
			if pct < worst:
				worst = pct
	return snappedf(worst, 0.01)

func get_tended_ratio() -> float:
	if hediffs.is_empty():
		return 1.0
	var tended: int = 0
	for h: Dictionary in hediffs:
		if h.get("tended", false):
			tended += 1
	return snappedf(float(tended) / float(hediffs.size()), 0.01)

func get_survival_probability() -> float:
	if is_dead:
		return 0.0
	var vital_total := 0
	var vital_ok := 0
	for bp in body_parts:
		if bp["vital"]:
			vital_total += 1
			if not bp["destroyed"] and float(bp["hp"]) / maxf(bp["max_hp"], 1.0) > 0.1:
				vital_ok += 1
	var vital_factor := float(vital_ok) / maxf(vital_total, 1.0)
	var bleed_factor := clampf(1.0 - _bleed_rate * 2.0, 0.0, 1.0)
	var cons_factor := clampf(_consciousness, 0.0, 1.0)
	return snapped(vital_factor * bleed_factor * cons_factor * 100.0, 0.1)

func get_combat_readiness_pct() -> float:
	if is_dead or is_downed:
		return 0.0
	var move := get_move_factor()
	var manip := get_manipulation()
	return snapped((move + manip) / 2.0 * 100.0, 0.1)

func get_medical_urgency() -> float:
	var score := 0.0
	score += _bleed_rate * 30.0
	score += float(count_untended()) * 5.0
	score += _pain_total * 10.0
	if is_downed:
		score += 20.0
	return snapped(clampf(score, 0.0, 100.0), 0.1)

func get_summary() -> Dictionary:
	return {
		"is_dead": is_dead,
		"is_downed": is_downed,
		"bleed_rate": snappedf(_bleed_rate, 0.01),
		"pain": snappedf(_pain_total, 0.01),
		"consciousness": snappedf(_consciousness, 0.01),
		"overall_health": snappedf(get_overall_health(), 0.01),
		"move_factor": snappedf(get_move_factor(), 0.01),
		"manipulation": snappedf(get_manipulation(), 0.01),
		"injuries": hediffs.size(),
		"untended": count_untended(),
		"parts_destroyed": body_parts.filter(func(bp: Dictionary) -> bool: return bp.destroyed).size(),
		"avg_part_health_pct": get_avg_part_health_pct(),
		"disease_count": get_disease_count(),
		"bleed_sources": get_total_bleed_sources(),
		"vital_parts_healthy": get_vital_parts_healthy(),
		"worst_part_pct": get_worst_part_pct(),
		"tended_ratio": get_tended_ratio(),
		"survival_probability": get_survival_probability(),
		"combat_readiness_pct": get_combat_readiness_pct(),
		"medical_urgency": get_medical_urgency(),
		"health_ecosystem": get_health_ecosystem(),
		"medical_governance": get_health_medical_governance(),
		"vitality_maturity_index": get_vitality_maturity_index(),
	}


func get_health_ecosystem() -> float:
	var survival := get_survival_probability()
	var readiness := get_combat_readiness_pct()
	var urgency_inv := maxf(100.0 - get_medical_urgency(), 0.0)
	return snapped((survival + readiness + urgency_inv) / 3.0, 0.1)

func get_health_medical_governance() -> String:
	var eco := get_health_ecosystem()
	var mat := get_vitality_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif not is_dead:
		return "Nascent"
	return "Dormant"

func get_vitality_maturity_index() -> float:
	var health := get_overall_health() * 100.0
	var tended := get_tended_ratio()
	var avg_part := get_avg_part_health_pct()
	return snapped((health + tended + avg_part) / 3.0, 0.1)

func to_dict() -> Dictionary:
	return {
		"body_parts": body_parts.duplicate(true),
		"hediffs": hediffs.duplicate(true),
		"is_dead": is_dead,
		"is_downed": is_downed,
	}
