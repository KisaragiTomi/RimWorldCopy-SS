extends Node

var _implanted: Dictionary = {}

const ACIDIFIER_STATS: Dictionary = {
	"work_to_install": 2000,
	"skill_required": 8,
	"destruction_radius": 0,
	"items_destroyed_pct": 1.0,
	"mood_penalty_colony": -3,
	"mood_duration_days": 5
}

const EXEMPT_ITEMS: Array = ["AIPersonaCore", "TechPrint", "VanometricCell"]

func install_acidifier(pawn_id: int) -> Dictionary:
	_implanted[pawn_id] = true
	return {"installed": true, "pawn_id": pawn_id}

func has_acidifier(pawn_id: int) -> bool:
	return _implanted.get(pawn_id, false)

func trigger_on_death(pawn_id: int, equipped_items: Array) -> Dictionary:
	if not has_acidifier(pawn_id):
		return {"triggered": false}
	var destroyed: Array = []
	var saved: Array = []
	for item: String in equipped_items:
		if item in EXEMPT_ITEMS:
			saved.append(item)
		else:
			destroyed.append(item)
	_implanted.erase(pawn_id)
	return {
		"triggered": true,
		"destroyed": destroyed,
		"saved": saved,
		"mood_penalty": ACIDIFIER_STATS["mood_penalty_colony"]
	}

func get_implanted_list() -> Array:
	var result: Array = []
	for pid: int in _implanted:
		if bool(_implanted[pid]):
			result.append(pid)
	return result


func is_item_exempt(item: String) -> bool:
	return item in EXEMPT_ITEMS


func get_install_cost() -> Dictionary:
	return {"work": ACIDIFIER_STATS["work_to_install"], "skill": ACIDIFIER_STATS["skill_required"]}


func get_install_work() -> int:
	return int(ACIDIFIER_STATS.get("work_to_install", 0))


func get_colony_mood_penalty() -> int:
	return int(ACIDIFIER_STATS.get("mood_penalty_colony", 0))


func get_implant_rate() -> float:
	return float(_implanted.size())


func get_mood_duration() -> int:
	return int(ACIDIFIER_STATS.get("mood_duration_days", 0))


func get_exempt_item_list() -> Array:
	return EXEMPT_ITEMS.duplicate()


func get_implanted_pct(total_colonists: int) -> float:
	if total_colonists <= 0:
		return 0.0
	return snappedf(float(_implanted.size()) / float(total_colonists) * 100.0, 0.1)


func get_deterrence_level() -> String:
	var implanted: int = _implanted.size()
	if implanted >= 5:
		return "MaxDeterrence"
	if implanted >= 2:
		return "Moderate"
	if implanted >= 1:
		return "Minimal"
	return "None"


func get_colony_morale_impact_pct() -> float:
	var penalty: float = float(get_colony_mood_penalty())
	var duration: int = get_mood_duration()
	return snappedf(absf(penalty) * float(duration) / 100.0, 0.1)


func get_tactical_value() -> String:
	var pct: float = float(ACIDIFIER_STATS.get("items_destroyed_pct", 0))
	if pct >= 80.0:
		return "Strategic"
	if pct >= 50.0:
		return "Useful"
	return "Limited"


func get_summary() -> Dictionary:
	return {
		"implanted_count": _implanted.size(),
		"exempt_items": EXEMPT_ITEMS.size(),
		"destruction_pct": ACIDIFIER_STATS["items_destroyed_pct"],
		"install_skill": ACIDIFIER_STATS["skill_required"],
		"install_work": get_install_work(),
		"mood_penalty": get_colony_mood_penalty(),
		"mood_duration": get_mood_duration(),
		"exempt_list": get_exempt_item_list(),
		"deterrence_level": get_deterrence_level(),
		"colony_morale_impact_pct": get_colony_morale_impact_pct(),
		"tactical_value": get_tactical_value(),
		"implant_coverage": get_implant_coverage(),
		"deterrence_effectiveness": get_deterrence_effectiveness(),
		"psychological_weight": get_psychological_weight(),
		"deterrence_ecosystem_health": get_deterrence_ecosystem_health(),
		"security_governance": get_security_governance(),
		"coercion_maturity_index": get_coercion_maturity_index(),
	}

func get_implant_coverage() -> float:
	var implanted := _implanted.size()
	if implanted <= 0:
		return 0.0
	return snapped(float(implanted) / maxf(float(implanted + 5), 1.0) * 100.0, 0.1)

func get_deterrence_effectiveness() -> String:
	var deterrence := get_deterrence_level()
	var tactical := get_tactical_value()
	if deterrence in ["Maximum", "High"] and tactical in ["Critical", "High"]:
		return "Absolute"
	elif deterrence in ["Moderate", "High"]:
		return "Significant"
	return "Marginal"

func get_psychological_weight() -> String:
	var penalty := get_colony_mood_penalty()
	if penalty >= 10:
		return "Oppressive"
	elif penalty >= 5:
		return "Noticeable"
	return "Negligible"

func get_deterrence_ecosystem_health() -> float:
	var coverage := get_implant_coverage()
	var effectiveness := get_deterrence_effectiveness()
	var e_val: float = 90.0 if effectiveness == "Maximum" else (60.0 if effectiveness == "Significant" else 25.0)
	var morale := get_colony_morale_impact_pct()
	return snapped((coverage + e_val + (100.0 - morale)) / 3.0, 0.1)

func get_security_governance() -> String:
	var ecosystem := get_deterrence_ecosystem_health()
	var tactical := get_tactical_value()
	var t_val: float = 90.0 if tactical in ["Strategic", "Critical"] else (60.0 if tactical == "Significant" else 25.0)
	var combined := (ecosystem + t_val) / 2.0
	if combined >= 70.0:
		return "Iron Grip"
	elif combined >= 40.0:
		return "Enforced"
	elif _implanted.size() > 0:
		return "Token"
	return "None"

func get_coercion_maturity_index() -> float:
	var weight := get_psychological_weight()
	var w_val: float = 90.0 if weight == "Oppressive" else (60.0 if weight == "Noticeable" else 30.0)
	var deterrence := get_deterrence_level()
	var d_val: float = 90.0 if deterrence in ["MaxDeterrence", "Maximum"] else (60.0 if deterrence == "High" else 25.0)
	return snapped((w_val + d_val) / 2.0, 0.1)
