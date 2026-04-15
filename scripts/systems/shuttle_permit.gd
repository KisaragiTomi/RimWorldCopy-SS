extends Node

var _permits: Dictionary = {}

const PERMIT_TYPES: Dictionary = {
	"CallMilitaryAid": {"title_req": "Knight", "cooldown_days": 45, "favor_cost": 0, "soldiers": 4},
	"CallTradeCaravan": {"title_req": "Esquire", "cooldown_days": 20, "favor_cost": 0, "goods_value": 2000},
	"AerialBombardment": {"title_req": "Baron", "cooldown_days": 60, "favor_cost": 0, "damage": 200, "radius": 8},
	"ShuttleTransport": {"title_req": "Yeoman", "cooldown_days": 15, "favor_cost": 0, "capacity": 8},
	"CallCataphract": {"title_req": "Count", "cooldown_days": 60, "favor_cost": 0, "soldiers": 2, "elite": true},
	"TradeOrbital": {"title_req": "Baron", "cooldown_days": 30, "favor_cost": 0, "ship_type": "ExoticGoods"},
	"LaborTeam": {"title_req": "Esquire", "cooldown_days": 30, "favor_cost": 0, "workers": 5, "duration_days": 5}
}

func grant_permit(pawn_id: int, permit: String) -> Dictionary:
	if not PERMIT_TYPES.has(permit):
		return {"error": "unknown_permit"}
	if not _permits.has(pawn_id):
		_permits[pawn_id] = {}
	_permits[pawn_id][permit] = {"cooldown_remaining": 0}
	return {"granted": permit, "title_req": PERMIT_TYPES[permit]["title_req"]}

func use_permit(pawn_id: int, permit: String) -> Dictionary:
	if not _permits.has(pawn_id) or not _permits[pawn_id].has(permit):
		return {"error": "no_permit"}
	if _permits[pawn_id][permit]["cooldown_remaining"] > 0:
		return {"error": "on_cooldown", "remaining": _permits[pawn_id][permit]["cooldown_remaining"]}
	_permits[pawn_id][permit]["cooldown_remaining"] = PERMIT_TYPES[permit]["cooldown_days"]
	return {"used": permit, "details": PERMIT_TYPES[permit]}

func get_available_permits(pawn_id: int) -> Array[String]:
	var result: Array[String] = []
	if not _permits.has(pawn_id):
		return result
	for permit: String in _permits[pawn_id]:
		if int(_permits[pawn_id][permit].get("cooldown_remaining", 0)) <= 0:
			result.append(permit)
	return result


func get_on_cooldown_count() -> int:
	var count: int = 0
	for pid: int in _permits:
		for permit: String in _permits[pid]:
			if int(_permits[pid][permit].get("cooldown_remaining", 0)) > 0:
				count += 1
	return count


func get_strongest_permit() -> String:
	var best: String = ""
	var best_cd: int = 0
	for p: String in PERMIT_TYPES:
		var cd: int = int(PERMIT_TYPES[p].get("cooldown_days", 0))
		if cd > best_cd:
			best_cd = cd
			best = p
	return best


func get_available_now_count() -> int:
	var count: int = 0
	for pid: int in _permits:
		for p: String in _permits[pid]:
			if int(_permits[pid][p].get("cooldown_remaining", 0)) <= 0:
				count += 1
	return count


func get_avg_cooldown() -> float:
	if PERMIT_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for p: String in PERMIT_TYPES:
		total += float(PERMIT_TYPES[p].get("cooldown_days", 0))
	return total / PERMIT_TYPES.size()


func get_most_soldiers_permit() -> String:
	var best: String = ""
	var best_soldiers: int = 0
	for p: String in PERMIT_TYPES:
		var s: int = int(PERMIT_TYPES[p].get("soldiers", 0))
		if s > best_soldiers:
			best_soldiers = s
			best = p
	return best


func get_military_permit_count() -> int:
	var count: int = 0
	for p: String in PERMIT_TYPES:
		if PERMIT_TYPES[p].has("soldiers"):
			count += 1
	return count


func get_shortest_cooldown_permit() -> String:
	var best: String = ""
	var best_cd: int = 9999
	for p: String in PERMIT_TYPES:
		var cd: int = int(PERMIT_TYPES[p].get("cooldown_days", 9999))
		if cd < best_cd:
			best_cd = cd
			best = p
	return best


func get_unique_title_reqs() -> int:
	var titles: Dictionary = {}
	for p: String in PERMIT_TYPES:
		titles[String(PERMIT_TYPES[p].get("title_req", ""))] = true
	return titles.size()


func get_readiness_level() -> String:
	var available: int = get_available_now_count()
	var total: int = _permits.size()
	if total == 0:
		return "NoPermits"
	var ratio: float = float(available) / float(total)
	if ratio >= 0.7:
		return "Ready"
	if ratio >= 0.3:
		return "Partial"
	return "Cooldown"


func get_military_focus_pct() -> float:
	var mil: int = get_military_permit_count()
	return snappedf(float(mil) / maxf(float(PERMIT_TYPES.size()), 1.0) * 100.0, 0.1)


func get_response_agility() -> String:
	var avg_cd: float = get_avg_cooldown()
	if avg_cd <= 30.0:
		return "Rapid"
	if avg_cd <= 60.0:
		return "Moderate"
	return "Sluggish"


func get_summary() -> Dictionary:
	return {
		"permit_types": PERMIT_TYPES.size(),
		"pawns_with_permits": _permits.size(),
		"on_cooldown": get_on_cooldown_count(),
		"available_now": get_available_now_count(),
		"avg_cooldown": snapped(get_avg_cooldown(), 0.1),
		"strongest": get_most_soldiers_permit(),
		"military_permits": get_military_permit_count(),
		"shortest_cooldown": get_shortest_cooldown_permit(),
		"unique_title_reqs": get_unique_title_reqs(),
		"readiness_level": get_readiness_level(),
		"military_focus_pct": get_military_focus_pct(),
		"response_agility": get_response_agility(),
		"permit_utilization": get_permit_utilization(),
		"tactical_flexibility": get_tactical_flexibility(),
		"imperial_favor_efficiency": get_imperial_favor_efficiency(),
		"logistics_ecosystem_health": get_logistics_ecosystem_health(),
		"permit_governance": get_permit_governance(),
		"shuttle_maturity_index": get_shuttle_maturity_index(),
	}

func get_permit_utilization() -> float:
	var available := get_available_now_count()
	var total := _permits.size()
	if total <= 0:
		return 0.0
	return snapped(float(total - available) / float(total) * 100.0, 0.1)

func get_tactical_flexibility() -> String:
	var military := get_military_permit_count()
	var types := PERMIT_TYPES.size()
	if types <= 0:
		return "None"
	var ratio := float(military) / float(types)
	if ratio >= 0.6:
		return "Combat-Focused"
	elif ratio >= 0.3:
		return "Versatile"
	return "Support-Oriented"

func get_imperial_favor_efficiency() -> String:
	var readiness := get_readiness_level()
	var agility := get_response_agility()
	if readiness in ["Ready", "Alert"] and agility in ["Swift", "Instant"]:
		return "Optimal"
	elif readiness in ["Standby", "Ready"]:
		return "Adequate"
	return "Wasteful"

func get_logistics_ecosystem_health() -> float:
	var utilization := get_permit_utilization()
	var flexibility := get_tactical_flexibility()
	var f_val: float = 90.0 if flexibility == "Combat-Focused" else (60.0 if flexibility == "Versatile" else 30.0)
	var efficiency := get_imperial_favor_efficiency()
	var e_val: float = 90.0 if efficiency == "Optimal" else (60.0 if efficiency == "Adequate" else 30.0)
	return snapped((minf(utilization, 100.0) + f_val + e_val) / 3.0, 0.1)

func get_shuttle_maturity_index() -> float:
	var readiness := get_readiness_level()
	var r_val: float = 90.0 if readiness in ["Ready", "Alert"] else (60.0 if readiness == "Standby" else 30.0)
	var agility := get_response_agility()
	var a_val: float = 90.0 if agility in ["Swift", "Instant"] else (60.0 if agility == "Moderate" else 30.0)
	var military := get_military_focus_pct()
	return snapped((r_val + a_val + military) / 3.0, 0.1)

func get_permit_governance() -> String:
	var ecosystem := get_logistics_ecosystem_health()
	var maturity := get_shuttle_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _permits.size() > 0:
		return "Nascent"
	return "Dormant"
