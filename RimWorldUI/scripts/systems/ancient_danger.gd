extends Node

var _dangers: Array = []

const DANGER_CONTENTS: Dictionary = {
	"Mechanoids": {"threat": "high", "enemies": ["Centipede", "Lancer", "Scyther"], "loot_quality": "excellent"},
	"CryptosleepCaskets": {"threat": "medium", "caskets": 4, "pawn_chance": 0.6, "loot_quality": "good"},
	"InsectHive": {"threat": "high", "enemies": ["Megaspider", "Spelopede", "Megascarab"], "loot_quality": "normal"},
	"TreasureRoom": {"threat": "low", "loot_quality": "masterwork", "silver_range": [500, 2000]},
	"AncientSoldiers": {"threat": "medium", "enemies": ["AncientSoldier"], "count_range": [3, 6], "loot_quality": "good"}
}

const LOOT_TABLES: Dictionary = {
	"normal": ["Silver", "Steel", "ComponentIndustrial"],
	"good": ["Silver", "Gold", "ComponentIndustrial", "MedicineIndustrial"],
	"excellent": ["Silver", "Gold", "Plasteel", "ComponentSpacer", "GlitterworldMedicine"],
	"masterwork": ["Gold", "Plasteel", "ComponentSpacer", "GlitterworldMedicine", "ArchotechArm"]
}

func spawn_danger(position: Vector2i, size: Vector2i) -> Dictionary:
	var content_type: String = DANGER_CONTENTS.keys()[randi() % DANGER_CONTENTS.size()]
	var danger: Dictionary = {
		"id": _dangers.size(),
		"position": position,
		"size": size,
		"content": content_type,
		"opened": false,
		"cleared": false
	}
	_dangers.append(danger)
	return danger

func open_danger(danger_id: int) -> Dictionary:
	if danger_id < 0 or danger_id >= _dangers.size():
		return {}
	var danger: Dictionary = _dangers[danger_id]
	danger["opened"] = true
	var content: Dictionary = DANGER_CONTENTS[danger["content"]]
	var loot: Array = LOOT_TABLES.get(content.get("loot_quality", "normal"), [])
	return {
		"content": danger["content"],
		"threat": content.get("threat", "medium"),
		"loot_types": loot
	}

func clear_danger(danger_id: int) -> bool:
	if danger_id < 0 or danger_id >= _dangers.size():
		return false
	_dangers[danger_id]["cleared"] = true
	return true

func get_unopened_count() -> int:
	var count: int = 0
	for d: Dictionary in _dangers:
		if not bool(d.get("opened", false)):
			count += 1
	return count


func get_cleared_count() -> int:
	var count: int = 0
	for d: Dictionary in _dangers:
		if bool(d.get("cleared", false)):
			count += 1
	return count


func get_high_threat_count() -> int:
	var count: int = 0
	for d: Dictionary in _dangers:
		var content: Dictionary = DANGER_CONTENTS.get(String(d.get("content", "")), {})
		if String(content.get("threat", "")) == "high":
			count += 1
	return count


func get_opened_uncleared_count() -> int:
	var count: int = 0
	for d: Dictionary in _dangers:
		if bool(d.get("opened", false)) and not bool(d.get("cleared", false)):
			count += 1
	return count


func get_most_common_content() -> String:
	var counts: Dictionary = {}
	for d: Dictionary in _dangers:
		var c: String = String(d.get("content", ""))
		counts[c] = counts.get(c, 0) + 1
	var best: String = ""
	var best_count: int = 0
	for c: String in counts:
		if int(counts[c]) > best_count:
			best_count = int(counts[c])
			best = c
	return best


func get_low_threat_count() -> int:
	var count: int = 0
	for d: Dictionary in _dangers:
		var content: Dictionary = DANGER_CONTENTS.get(String(d.get("content", "")), {})
		if String(content.get("threat", "")) == "low":
			count += 1
	return count


func get_high_threat_pct() -> float:
	if _dangers.is_empty():
		return 0.0
	return snappedf(float(get_high_threat_count()) / float(_dangers.size()) * 100.0, 0.1)


func get_clearance_rate() -> float:
	if _dangers.is_empty():
		return 0.0
	return snappedf(float(get_cleared_count()) / float(_dangers.size()) * 100.0, 0.1)


func get_unique_content_spawned() -> int:
	var types: Dictionary = {}
	for d: Dictionary in _dangers:
		types[String(d.get("content", ""))] = true
	return types.size()


func get_exploration_status() -> String:
	if _dangers.is_empty():
		return "N/A"
	var rate: float = get_clearance_rate()
	if rate >= 0.8:
		return "Explored"
	elif rate >= 0.5:
		return "Partial"
	elif rate >= 0.2:
		return "Early"
	return "Untouched"

func get_threat_assessment() -> String:
	var high_pct: float = get_high_threat_pct()
	if high_pct >= 60.0:
		return "Lethal"
	elif high_pct >= 35.0:
		return "Dangerous"
	elif high_pct >= 10.0:
		return "Moderate"
	return "Manageable"

func get_loot_potential_pct() -> float:
	if _dangers.is_empty():
		return 0.0
	var unopened: int = get_unopened_count()
	return snappedf(float(unopened) / float(_dangers.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"content_types": DANGER_CONTENTS.size(),
		"loot_tiers": LOOT_TABLES.size(),
		"spawned_count": _dangers.size(),
		"unopened": get_unopened_count(),
		"cleared": get_cleared_count(),
		"opened_uncleared": get_opened_uncleared_count(),
		"most_common": get_most_common_content(),
		"low_threat": get_low_threat_count(),
		"high_threat_pct": get_high_threat_pct(),
		"clearance_rate": get_clearance_rate(),
		"unique_content": get_unique_content_spawned(),
		"exploration_status": get_exploration_status(),
		"threat_assessment": get_threat_assessment(),
		"loot_potential_pct": get_loot_potential_pct(),
		"archaeological_value": get_archaeological_value(),
		"danger_containment": get_danger_containment(),
		"risk_reward_ratio": get_risk_reward_ratio(),
		"archaeological_ecosystem_health": get_archaeological_ecosystem_health(),
		"exploration_governance": get_exploration_governance(),
		"ruin_maturity_index": get_ruin_maturity_index(),
	}

func get_archaeological_value() -> String:
	var unique := get_unique_content_spawned()
	var loot := get_loot_potential_pct()
	if unique >= 3 and loot >= 50.0:
		return "High"
	elif unique >= 1:
		return "Moderate"
	return "Low"

func get_danger_containment() -> String:
	var uncleared := get_opened_uncleared_count()
	if uncleared == 0:
		return "Secure"
	elif uncleared <= 2:
		return "Contained"
	return "Hazardous"

func get_risk_reward_ratio() -> String:
	var threat := get_threat_assessment()
	var loot := get_loot_potential_pct()
	if threat in ["Low", "Minimal"] and loot >= 40.0:
		return "Favorable"
	elif loot >= 20.0:
		return "Balanced"
	return "Risky"

func get_archaeological_ecosystem_health() -> float:
	var value := get_archaeological_value()
	var v_val: float = 90.0 if value in ["Priceless", "High"] else (60.0 if value in ["Moderate", "Some"] else 30.0)
	var containment := get_danger_containment()
	var c_val: float = 90.0 if containment == "Secure" else (60.0 if containment == "Contained" else 30.0)
	var ratio := get_risk_reward_ratio()
	var r_val: float = 90.0 if ratio == "Favorable" else (60.0 if ratio == "Balanced" else 30.0)
	return snapped((v_val + c_val + r_val) / 3.0, 0.1)

func get_ruin_maturity_index() -> float:
	var status := get_exploration_status()
	var s_val: float = 90.0 if status in ["Fully Explored", "Cleared"] else (60.0 if status in ["Partial", "Active"] else 30.0)
	var threat := get_threat_assessment()
	var t_val: float = 90.0 if threat in ["Low", "Minimal", "None"] else (50.0 if threat == "Moderate" else 20.0)
	var loot := get_loot_potential_pct()
	return snapped((s_val + t_val + loot) / 3.0, 0.1)

func get_exploration_governance() -> String:
	var ecosystem := get_archaeological_ecosystem_health()
	var maturity := get_ruin_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _dangers.size() > 0:
		return "Nascent"
	return "Dormant"
