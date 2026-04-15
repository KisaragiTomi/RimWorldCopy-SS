extends Node

var _pawn_titles: Dictionary = {}

const TITLES: Dictionary = {
	"Freeholder": {"level": 0, "favor_cost": 0, "psylink_level": 0, "apparel_req": [], "room_req": 0},
	"Yeoman": {"level": 1, "favor_cost": 8, "psylink_level": 1, "apparel_req": ["FormalShirt"], "room_req": 24},
	"Esquire": {"level": 2, "favor_cost": 12, "psylink_level": 2, "apparel_req": ["FormalShirt", "FormalVest"], "room_req": 40},
	"Knight": {"level": 3, "favor_cost": 16, "psylink_level": 3, "apparel_req": ["RoyalArmor"], "room_req": 60},
	"Praetor": {"level": 4, "favor_cost": 22, "psylink_level": 4, "apparel_req": ["RoyalArmor", "Crown"], "room_req": 80},
	"Baron": {"level": 5, "favor_cost": 30, "psylink_level": 5, "apparel_req": ["RoyalArmor", "Crown"], "room_req": 100, "throne": true},
	"Count": {"level": 6, "favor_cost": 40, "psylink_level": 6, "apparel_req": ["PrestigeArmor", "Crown"], "room_req": 130, "throne": true},
	"Duke": {"level": 7, "favor_cost": 50, "psylink_level": 6, "apparel_req": ["PrestigeArmor", "Crown"], "room_req": 170, "throne": true},
	"Stellarch": {"level": 8, "favor_cost": 60, "psylink_level": 6, "apparel_req": ["PrestigeArmor", "Crown"], "room_req": 220, "throne": true}
}

func grant_title(pawn_id: int, title: String) -> Dictionary:
	if not TITLES.has(title):
		return {"error": "unknown_title"}
	_pawn_titles[pawn_id] = title
	return {"granted": title, "level": TITLES[title]["level"], "psylink": TITLES[title]["psylink_level"]}

func get_title(pawn_id: int) -> String:
	return _pawn_titles.get(pawn_id, "Freeholder")

func get_requirements(title: String) -> Dictionary:
	return TITLES.get(title, {})

func get_highest_title_holder() -> Dictionary:
	var best_id: int = -1
	var best_level: int = -1
	for pid: int in _pawn_titles:
		var t: String = _pawn_titles[pid]
		var lvl: int = int(TITLES.get(t, {}).get("level", 0))
		if lvl > best_level:
			best_level = lvl
			best_id = pid
	if best_id < 0:
		return {}
	return {"pawn_id": best_id, "title": _pawn_titles[best_id], "level": best_level}


func get_throne_required_count() -> int:
	var count: int = 0
	for pid: int in _pawn_titles:
		var t: String = _pawn_titles[pid]
		if bool(TITLES.get(t, {}).get("throne", false)):
			count += 1
	return count


func get_title_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pid: int in _pawn_titles:
		var t: String = _pawn_titles[pid]
		dist[t] = int(dist.get(t, 0)) + 1
	return dist


func get_avg_favor_cost() -> float:
	if TITLES.is_empty():
		return 0.0
	var total: float = 0.0
	for t: String in TITLES:
		total += float(TITLES[t].get("favor_cost", 0))
	return total / TITLES.size()


func get_title_level_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for pid: int in _pawn_titles:
		var t: String = String(_pawn_titles[pid])
		dist[t] = dist.get(t, 0) + 1
	return dist


func get_total_psylink_levels() -> int:
	var total: int = 0
	for pid: int in _pawn_titles:
		var t: String = String(_pawn_titles[pid])
		total += int(TITLES.get(t, {}).get("psylink_level", 0))
	return total


func get_max_room_req() -> int:
	var best: int = 0
	for t: String in TITLES:
		var r: int = int(TITLES[t].get("room_req", 0))
		if r > best:
			best = r
	return best


func get_total_favor_cost() -> int:
	var total: int = 0
	for t: String in TITLES:
		total += int(TITLES[t].get("favor_cost", 0))
	return total


func get_throne_title_count() -> int:
	var count: int = 0
	for t: String in TITLES:
		if bool(TITLES[t].get("throne", false)):
			count += 1
	return count


func get_aristocracy_depth() -> String:
	var titled: int = _pawn_titles.size()
	if titled >= 5:
		return "Noble Court"
	if titled >= 2:
		return "Minor Nobility"
	if titled >= 1:
		return "Single Title"
	return "Commoners"


func get_prestige_investment_pct() -> float:
	var throne: int = get_throne_required_count()
	var total: int = _pawn_titles.size()
	if total == 0:
		return 0.0
	return snappedf(float(throne) / float(total) * 100.0, 0.1)


func get_psylink_density() -> String:
	var psylink: int = get_total_psylink_levels()
	var titled: int = _pawn_titles.size()
	if titled == 0:
		return "None"
	var avg: float = float(psylink) / float(titled)
	if avg >= 4.0:
		return "Dense"
	if avg >= 2.0:
		return "Moderate"
	return "Sparse"


func get_summary() -> Dictionary:
	return {
		"title_count": TITLES.size(),
		"titled_pawns": _pawn_titles.size(),
		"highest": get_highest_title_holder(),
		"throne_needed": get_throne_required_count(),
		"avg_favor_cost": snapped(get_avg_favor_cost(), 0.1),
		"total_psylink": get_total_psylink_levels(),
		"max_room_req": get_max_room_req(),
		"total_favor_cost": get_total_favor_cost(),
		"throne_titles": get_throne_title_count(),
		"aristocracy_depth": get_aristocracy_depth(),
		"prestige_investment_pct": get_prestige_investment_pct(),
		"psylink_density": get_psylink_density(),
		"imperial_standing": get_imperial_standing(),
		"court_sophistication": get_court_sophistication(),
		"honor_economy_health": get_honor_economy_health(),
		"imperial_ecosystem_health": get_imperial_ecosystem_health(),
		"title_governance": get_title_governance(),
		"nobility_maturity_index": get_nobility_maturity_index(),
	}

func get_imperial_standing() -> String:
	var depth := get_aristocracy_depth()
	var psylink := get_total_psylink_levels()
	if depth in ["Deep", "Entrenched"] and psylink >= 5:
		return "Distinguished"
	elif depth in ["Moderate", "Deep"]:
		return "Recognized"
	return "Minor"

func get_court_sophistication() -> float:
	var throne := get_throne_title_count()
	var titled := _pawn_titles.size()
	if titled <= 0:
		return 0.0
	return snapped(float(throne) / float(titled) * 100.0, 0.1)

func get_honor_economy_health() -> String:
	var investment := get_prestige_investment_pct()
	if investment >= 70.0:
		return "Overextended"
	elif investment >= 30.0:
		return "Balanced"
	return "Conservative"

func get_imperial_ecosystem_health() -> float:
	var standing := get_imperial_standing()
	var s_val: float = 90.0 if standing in ["Paramount", "Distinguished"] else (60.0 if standing == "Recognized" else 30.0)
	var sophistication := get_court_sophistication()
	var economy := get_honor_economy_health()
	var e_val: float = 80.0 if economy == "Balanced" else (50.0 if economy == "Conservative" else 30.0)
	return snapped((s_val + minf(sophistication, 100.0) + e_val) / 3.0, 0.1)

func get_nobility_maturity_index() -> float:
	var depth := get_aristocracy_depth()
	var d_val: float = 90.0 if depth in ["Noble Court", "Deep"] else (60.0 if depth == "Minor Nobility" else 30.0)
	var psylink := get_psylink_density()
	var p_val: float = 90.0 if psylink in ["Saturated", "High"] else (60.0 if psylink in ["Moderate", "Some"] else 30.0)
	var investment := get_prestige_investment_pct()
	return snapped((d_val + p_val + investment) / 3.0, 0.1)

func get_title_governance() -> String:
	var ecosystem := get_imperial_ecosystem_health()
	var maturity := get_nobility_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _pawn_titles.size() > 0:
		return "Nascent"
	return "Dormant"
