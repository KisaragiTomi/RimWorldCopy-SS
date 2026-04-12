extends Node

const RECREATION_TYPES: Dictionary = {
	"Socializing": {"joy_per_hour": 4.0, "tolerance_decay": 0.005, "category": "Social"},
	"Gaming_Dexterity": {"joy_per_hour": 3.5, "tolerance_decay": 0.008, "category": "HighLife"},
	"Gaming_Cerebral": {"joy_per_hour": 3.0, "tolerance_decay": 0.006, "category": "HighLife"},
	"Viewing": {"joy_per_hour": 2.0, "tolerance_decay": 0.003, "category": "Passive"},
	"Listening": {"joy_per_hour": 2.5, "tolerance_decay": 0.004, "category": "Passive"},
	"Building": {"joy_per_hour": 3.0, "tolerance_decay": 0.006, "category": "Creative"},
	"Music": {"joy_per_hour": 4.0, "tolerance_decay": 0.005, "category": "Creative"},
	"Meditative": {"joy_per_hour": 2.5, "tolerance_decay": 0.002, "category": "Solitary"},
	"Telescope": {"joy_per_hour": 3.5, "tolerance_decay": 0.007, "category": "Solitary"},
	"Chemical": {"joy_per_hour": 5.0, "tolerance_decay": 0.01, "category": "Chemical"},
	"Gluttonous": {"joy_per_hour": 4.5, "tolerance_decay": 0.008, "category": "Gluttony"},
	"Television": {"joy_per_hour": 3.0, "tolerance_decay": 0.005, "category": "Passive"}
}

const FACILITIES: Dictionary = {
	"Horseshoe": {"rec_type": "Gaming_Dexterity", "max_users": 2},
	"ChessTable": {"rec_type": "Gaming_Cerebral", "max_users": 2},
	"Television": {"rec_type": "Television", "max_users": 6},
	"Telescope": {"rec_type": "Telescope", "max_users": 1},
	"Billiards": {"rec_type": "Gaming_Dexterity", "max_users": 2},
	"PokerTable": {"rec_type": "Gaming_Cerebral", "max_users": 4},
	"Piano": {"rec_type": "Music", "max_users": 1},
	"Harp": {"rec_type": "Music", "max_users": 1}
}

func get_joy_gain(rec_type: String, hours: float, tolerance: float) -> float:
	if not RECREATION_TYPES.has(rec_type):
		return 0.0
	var base_joy: float = RECREATION_TYPES[rec_type]["joy_per_hour"] * hours
	return base_joy * maxf(0.1, 1.0 - tolerance)

func get_tolerance_gain(rec_type: String) -> float:
	return RECREATION_TYPES.get(rec_type, {}).get("tolerance_decay", 0.0)

func get_highest_joy_recreation() -> String:
	var best: String = ""
	var best_joy: float = 0.0
	for rt: String in RECREATION_TYPES:
		if RECREATION_TYPES[rt]["joy_per_hour"] > best_joy:
			best_joy = RECREATION_TYPES[rt]["joy_per_hour"]
			best = rt
	return best

func get_lowest_tolerance_decay() -> String:
	var best: String = ""
	var best_d: float = 999.0
	for rt: String in RECREATION_TYPES:
		if RECREATION_TYPES[rt]["tolerance_decay"] < best_d:
			best_d = RECREATION_TYPES[rt]["tolerance_decay"]
			best = rt
	return best

func get_category_types(category: String) -> Array[String]:
	var result: Array[String] = []
	for rt: String in RECREATION_TYPES:
		if RECREATION_TYPES[rt]["category"] == category:
			result.append(rt)
	return result

func get_avg_joy_per_hour() -> float:
	var total: float = 0.0
	for rt: String in RECREATION_TYPES:
		total += float(RECREATION_TYPES[rt].get("joy_per_hour", 0.0))
	return total / maxf(RECREATION_TYPES.size(), 1)


func get_unique_categories() -> int:
	var cats: Dictionary = {}
	for rt: String in RECREATION_TYPES:
		cats[String(RECREATION_TYPES[rt].get("category", ""))] = true
	return cats.size()


func get_dangerous_recreation_count() -> int:
	var count: int = 0
	for rt: String in RECREATION_TYPES:
		if String(RECREATION_TYPES[rt].get("category", "")) == "Chemical":
			count += 1
	return count


func get_highest_tolerance_recreation() -> String:
	var worst: String = ""
	var worst_d: float = 0.0
	for rt: String in RECREATION_TYPES:
		if float(RECREATION_TYPES[rt].get("tolerance_decay", 0.0)) > worst_d:
			worst_d = float(RECREATION_TYPES[rt].get("tolerance_decay", 0.0))
			worst = rt
	return worst


func get_avg_tolerance_decay() -> float:
	if RECREATION_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for rt: String in RECREATION_TYPES:
		total += float(RECREATION_TYPES[rt].get("tolerance_decay", 0.0))
	return snappedf(total / float(RECREATION_TYPES.size()), 0.001)


func get_multi_user_facility_count() -> int:
	var count: int = 0
	for f: String in FACILITIES:
		if int(FACILITIES[f].get("max_users", 1)) > 1:
			count += 1
	return count


func get_entertainment_quality() -> String:
	var avg: float = get_avg_joy_per_hour()
	if avg >= 0.6:
		return "Premium"
	elif avg >= 0.35:
		return "Good"
	elif avg >= 0.15:
		return "Basic"
	return "Sparse"

func get_social_richness() -> String:
	var multi: int = get_multi_user_facility_count()
	if multi >= 5:
		return "Vibrant"
	elif multi >= 3:
		return "Social"
	elif multi >= 1:
		return "Limited"
	return "Isolated"

func get_risk_tolerance_pct() -> float:
	if RECREATION_TYPES.is_empty():
		return 0.0
	return snappedf(float(get_dangerous_recreation_count()) / float(RECREATION_TYPES.size()) * 100.0, 0.1)

func get_variety_score() -> String:
	var cats: int = get_unique_categories()
	var types: int = RECREATION_TYPES.size()
	if types == 0:
		return "none"
	var ratio: float = cats * 1.0 / maxf(types, 1.0)
	if ratio >= 0.5:
		return "highly_varied"
	if ratio >= 0.3:
		return "moderate"
	return "monotonous"

func get_wellbeing_impact_pct() -> float:
	var safe: int = RECREATION_TYPES.size() - get_dangerous_recreation_count()
	if RECREATION_TYPES.is_empty():
		return 0.0
	return snapped(safe * 100.0 / RECREATION_TYPES.size(), 0.1)

func get_facility_density() -> String:
	var multi: int = get_multi_user_facility_count()
	var total: int = FACILITIES.size()
	if total == 0:
		return "none"
	var ratio: float = multi * 1.0 / total
	if ratio >= 0.6:
		return "communal"
	if ratio >= 0.3:
		return "mixed"
	return "individual"

func get_summary() -> Dictionary:
	return {
		"recreation_types": RECREATION_TYPES.size(),
		"facilities": FACILITIES.size(),
		"highest_joy": get_highest_joy_recreation(),
		"lowest_tolerance": get_lowest_tolerance_decay(),
		"avg_joy": snapped(get_avg_joy_per_hour(), 0.1),
		"categories": get_unique_categories(),
		"dangerous": get_dangerous_recreation_count(),
		"highest_tolerance": get_highest_tolerance_recreation(),
		"avg_tolerance_decay": get_avg_tolerance_decay(),
		"multi_user_facilities": get_multi_user_facility_count(),
		"entertainment_quality": get_entertainment_quality(),
		"social_richness": get_social_richness(),
		"risk_tolerance_pct": get_risk_tolerance_pct(),
		"variety_score": get_variety_score(),
		"wellbeing_impact_pct": get_wellbeing_impact_pct(),
		"facility_density": get_facility_density(),
		"recreation_satisfaction": get_recreation_satisfaction(),
		"leisure_infrastructure": get_leisure_infrastructure(),
		"joy_sustainability": get_joy_sustainability(),
		"recreation_ecosystem_health": get_recreation_ecosystem_health(),
		"entertainment_governance": get_entertainment_governance(),
		"leisure_maturity_index": get_leisure_maturity_index(),
	}

func get_recreation_satisfaction() -> String:
	var quality := get_entertainment_quality()
	var variety := get_variety_score()
	if quality in ["Excellent", "Premium"] and variety == "highly_varied":
		return "Thriving"
	elif quality in ["Good", "Excellent"]:
		return "Content"
	return "Lacking"

func get_leisure_infrastructure() -> float:
	var multi := get_multi_user_facility_count()
	var total := FACILITIES.size()
	if total <= 0:
		return 0.0
	return snapped(float(multi) / float(total) * 100.0, 0.1)

func get_joy_sustainability() -> String:
	var avg_decay := get_avg_tolerance_decay()
	var avg_joy := get_avg_joy_per_hour()
	if avg_joy > avg_decay * 2.0:
		return "Self-Sustaining"
	elif avg_joy > avg_decay:
		return "Balanced"
	return "Declining"

func get_recreation_ecosystem_health() -> float:
	var quality := get_entertainment_quality()
	var q_val: float = 90.0 if quality == "Excellent" else (60.0 if quality in ["Good", "Decent"] else 30.0)
	var richness := get_social_richness()
	var r_val: float = 90.0 if richness == "Vibrant" else (60.0 if richness == "Active" else 25.0)
	var infra := get_leisure_infrastructure()
	return snapped((q_val + r_val + infra) / 3.0, 0.1)

func get_entertainment_governance() -> String:
	var ecosystem := get_recreation_ecosystem_health()
	var satisfaction := get_recreation_satisfaction()
	var s_val: float = 90.0 if satisfaction == "Fulfilled" else (60.0 if satisfaction == "Content" else 25.0)
	var combined := (ecosystem + s_val) / 2.0
	if combined >= 70.0:
		return "Flourishing"
	elif combined >= 40.0:
		return "Adequate"
	elif RECREATION_TYPES.size() > 0:
		return "Sparse"
	return "None"

func get_leisure_maturity_index() -> float:
	var variety := get_variety_score()
	var v_val: float = 90.0 if variety == "highly_varied" else (60.0 if variety == "moderate" else 25.0)
	var wellbeing := get_wellbeing_impact_pct()
	var density := get_facility_density()
	var d_val: float = 90.0 if density == "communal" else (60.0 if density == "mixed" else 25.0)
	return snapped((v_val + wellbeing + d_val) / 3.0, 0.1)
