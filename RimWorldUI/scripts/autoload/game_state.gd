extends Node

signal time_speed_changed(speed: int)
signal colonist_selected(colonist: Dictionary)
signal tab_changed(tab_name: String)

enum GameScreen { MAIN_MENU, WORLD_MAP, PLAYING }

var current_screen: GameScreen = GameScreen.MAIN_MENU
var time_speed: int = 1
var active_map: MapData
var game_date := {"year": 5500, "quadrum": "Aprimay", "day": 1, "hour": 6}
var temperature := 21.0
var season := "Spring"
var colony_name := "New Arrivals"

var colonists: Array[Dictionary] = []
var resources: Array[Dictionary] = []
var research_projects: Array[Dictionary] = []
var architect_categories: Array[Dictionary] = []
var tamed_animals: Array[Dictionary] = []
var wildlife_species: Array[Dictionary] = []
var history_log: Array[Dictionary] = []


func _ready() -> void:
	_init_mock_colonists()
	_init_mock_resources()
	_init_mock_research()
	_init_mock_architect()
	_init_mock_misc()


func set_time_speed(spd: int) -> void:
	time_speed = clampi(spd, 0, 3)
	time_speed_changed.emit(time_speed)


func get_date_string() -> String:
	return "%d %s, %d" % [game_date.day, game_date.quadrum, game_date.year]


func get_time_string() -> String:
	return "%02d:00" % game_date.hour


signal game_over_triggered(reason: String)

var game_over: bool = false
var game_over_reason: String = ""
var game_over_day: int = 0
var game_over_stats: Dictionary = {}


func get_map() -> MapData:
	return active_map


func check_game_over() -> bool:
	if game_over:
		return true
	if not PawnManager:
		return false

	var alive_colonists: int = 0
	var total_colonists: int = 0
	var downed_colonists: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.has_meta("faction") and p.get_meta("faction") == "enemy":
			continue
		total_colonists += 1
		if p.dead:
			continue
		alive_colonists += 1
		if p.downed:
			downed_colonists += 1

	if alive_colonists == 0 and total_colonists > 0:
		_trigger_game_over("All colonists have perished.")
		return true

	if alive_colonists > 0 and alive_colonists == downed_colonists:
		_trigger_game_over("All remaining colonists are incapacitated.")
		return true

	return false


func _trigger_game_over(reason: String) -> void:
	game_over = true
	game_over_reason = reason
	game_over_day = game_date.get("day", 0)

	var alive_count: int = 0
	var dead_count: int = 0
	var total_kills: int = CombatUtil.total_kills if CombatUtil else 0
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.has_meta("faction") and p.get_meta("faction") == "enemy":
				continue
			if p.dead:
				dead_count += 1
			else:
				alive_count += 1

	game_over_stats = {
		"colony_name": colony_name,
		"year": game_date.get("year", 5500),
		"quadrum": game_date.get("quadrum", "Aprimay"),
		"day": game_date.get("day", 1),
		"wealth": get_colony_wealth(),
		"reason": reason,
		"alive": alive_count,
		"dead": dead_count,
		"total_kills": total_kills,
		"raids_survived": RaidManager.total_raids if RaidManager else 0,
		"research_done": ResearchManager.total_completed if ResearchManager else 0,
	}
	if ColonyLog:
		ColonyLog.add_entry("GameOver", reason, "danger")
		ColonyLog.add_entry("GameOver", "Colony stats: wealth=%d, survived %d raids." % [
			roundi(game_over_stats["wealth"]), game_over_stats["raids_survived"]], "info")
	game_over_triggered.emit(reason)


func get_game_over_summary() -> String:
	if not game_over:
		return ""
	var s := game_over_stats
	return "Colony '%s' fell on Day %d, Year %d.\nReason: %s\nWealth: %d | Raids: %d | Kills: %d" % [
		s.get("colony_name", ""), s.get("day", 0), s.get("year", 0),
		s.get("reason", ""), roundi(s.get("wealth", 0.0)),
		s.get("raids_survived", 0), s.get("total_kills", 0)]


func get_colony_wealth() -> float:
	var wealth: float = 0.0
	if ThingManager:
		for t: Thing in ThingManager.things:
			if t is Item:
				wealth += (t as Item).get_market_value()
			elif t is Building:
				wealth += _building_wealth(t as Building)
	if TradeManager:
		wealth += TradeManager.colony_silver
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.dead:
				continue
			wealth += _pawn_gear_wealth(p)
	return wealth


const BUILDING_WEALTH: Dictionary = {
	"Wall": 10.0, "Door": 15.0, "Bed": 50.0, "DoubleBed": 100.0,
	"Table": 30.0, "DiningChair": 15.0, "Armchair": 50.0,
	"Campfire": 10.0, "WoodFiredGenerator": 200.0, "SolarGenerator": 350.0,
	"Battery": 150.0, "MiniTurret": 250.0, "CookingStove": 180.0,
	"HiTechResearchBench": 300.0, "Shelf": 25.0, "StandingLamp": 20.0,
}


func _building_wealth(b: Building) -> float:
	if b.build_state != Building.BuildState.COMPLETE:
		return 0.0
	return BUILDING_WEALTH.get(b.def_name, 20.0)


func _pawn_gear_wealth(p: Pawn) -> float:
	var w: float = 0.0
	if p.equipment:
		if p.equipment.weapon != "":
			w += p.equipment.get_weapon_damage() * 8.0
		w += p.equipment.sharp_armor * 200.0
		w += p.equipment.blunt_armor * 150.0
	if p.inventory:
		for entry: Dictionary in p.inventory.items:
			w += float(entry.get("count", 0)) * 1.0
	return w


func get_wealth_breakdown() -> Dictionary:
	var building_w: float = 0.0
	var item_w: float = 0.0
	var silver_w: float = 0.0
	var gear_w: float = 0.0
	if ThingManager:
		for t: Thing in ThingManager.things:
			if t is Item:
				var v := (t as Item).get_market_value()
				if t.def_name == "Silver":
					silver_w += v
				else:
					item_w += v
			elif t is Building:
				building_w += _building_wealth(t as Building)
	if TradeManager:
		silver_w += TradeManager.colony_silver
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if not p.dead:
				gear_w += _pawn_gear_wealth(p)
	var total := building_w + item_w + silver_w + gear_w
	return {
		"building": snappedf(building_w, 0.1),
		"items": snappedf(item_w, 0.1),
		"silver": snappedf(silver_w, 0.1),
		"gear": snappedf(gear_w, 0.1),
		"total": snappedf(total, 0.1),
	}


func get_wealth_trend(days: int = 5) -> String:
	var current: float = get_colony_wealth()
	if current > 10000.0:
		return "Prosperous"
	elif current > 5000.0:
		return "Stable"
	elif current > 1000.0:
		return "Growing"
	return "Struggling"


func get_most_valuable_category() -> String:
	var bd: Dictionary = get_wealth_breakdown()
	var best: String = "items"
	var best_v: float = 0.0
	for key: String in ["building", "items", "silver", "gear"]:
		if bd.get(key, 0.0) > best_v:
			best_v = bd.get(key, 0.0)
			best = key
	return best


func get_survival_days() -> int:
	return game_date.get("day", 1)

func get_wealth_per_colonist() -> float:
	if colonists.is_empty():
		return 0.0
	return snappedf(get_colony_wealth() / float(colonists.size()), 0.1)

func get_alive_colonist_count() -> int:
	var count: int = 0
	for c: Dictionary in colonists:
		if c.get("health", 0.0) > 0.0:
			count += 1
	return count

func get_avg_colonist_mood() -> float:
	if colonists.is_empty():
		return 0.0
	var total: float = 0.0
	for c: Dictionary in colonists:
		total += c.get("mood", 0.0)
	return snappedf(total / float(colonists.size()), 0.01)

func get_current_year() -> int:
	return game_date.get("year", 5500)


func get_wealth_growth_rate() -> float:
	var current: float = get_colony_wealth()
	var days: int = get_survival_days()
	if days <= 0:
		return 0.0
	return snappedf(current / float(days), 0.1)


func get_wealth_category_count() -> int:
	var bd: Dictionary = get_wealth_breakdown()
	var count: int = 0
	for k: String in bd:
		if k != "total" and bd[k] > 0.0:
			count += 1
	return count


func get_wealth_concentration() -> float:
	var bd := get_wealth_breakdown()
	var total: float = bd.get("total", 0.0)
	if total <= 0.0:
		return 0.0
	var vals: Array[float] = []
	for k: String in ["building", "items", "silver", "gear"]:
		vals.append(bd.get(k, 0.0))
	var max_val := 0.0
	for v: float in vals:
		max_val = maxf(max_val, v)
	return snapped(max_val / total * 100.0, 0.1)

func get_economic_resilience() -> String:
	var cats := get_wealth_category_count()
	var growth := get_wealth_growth_rate()
	var per_col := get_wealth_per_colonist()
	var score := float(cats) * 10.0 + minf(growth, 100.0) * 0.3 + minf(per_col, 2000.0) * 0.01
	if score >= 50.0:
		return "Robust"
	elif score >= 30.0:
		return "Stable"
	elif score >= 15.0:
		return "Fragile"
	return "Precarious"

func get_prosperity_index() -> float:
	var wealth := get_colony_wealth()
	var alive := float(get_alive_colonist_count())
	var mood := get_avg_colonist_mood()
	if alive <= 0.0:
		return 0.0
	return snapped((wealth / 1000.0 * alive * maxf(mood, 0.1)) / 100.0, 0.01)

func get_colony_wealth_summary() -> Dictionary:
	return {
		"total_wealth": snappedf(get_colony_wealth(), 0.1),
		"trend": get_wealth_trend(),
		"most_valuable": get_most_valuable_category(),
		"wealth_per_colonist": get_wealth_per_colonist(),
		"growth_rate_per_day": get_wealth_growth_rate(),
		"wealth_categories": get_wealth_category_count(),
		"alive_colonists": get_alive_colonist_count(),
		"avg_mood": get_avg_colonist_mood(),
		"survival_days": get_survival_days(),
		"wealth_concentration": get_wealth_concentration(),
		"economic_resilience": get_economic_resilience(),
		"prosperity_index": get_prosperity_index(),
	}


func get_game_over_death_count() -> int:
	return game_over_stats.get("dead", 0)


func get_game_over_kill_ratio() -> float:
	var kills: int = game_over_stats.get("total_kills", 0)
	var raids: int = game_over_stats.get("raids_survived", 0)
	if raids <= 0:
		return 0.0
	return snappedf(float(kills) / float(raids), 0.01)


func get_survival_efficiency() -> float:
	var days := float(game_over_stats.get("day", 1))
	var alive := float(game_over_stats.get("alive", 0))
	var dead := float(game_over_stats.get("dead", 0))
	if days <= 0.0:
		return 0.0
	return snapped(alive / maxf(alive + dead, 1.0) * minf(days / 30.0, 10.0) * 10.0, 0.1)

func get_combat_performance() -> String:
	var kills: int = int(game_over_stats.get("total_kills", 0))
	var raids: int = int(game_over_stats.get("raids_survived", 0))
	if raids <= 0:
		return "Untested"
	var ratio := float(kills) / float(raids)
	if ratio >= 5.0:
		return "Dominant"
	elif ratio >= 2.0:
		return "Effective"
	elif ratio >= 1.0:
		return "Adequate"
	return "Struggling"

func get_legacy_score() -> float:
	var wealth: float = float(game_over_stats.get("wealth", 0.0))
	var days := float(game_over_stats.get("day", 1))
	var kills := float(game_over_stats.get("total_kills", 0))
	var research := float(game_over_stats.get("research_done", 0))
	return snapped((wealth / 1000.0 + days * 0.5 + kills * 2.0 + research * 10.0), 0.1)

func get_game_over_full_stats() -> Dictionary:
	var base: Dictionary = game_over_stats.duplicate()
	base["death_count"] = get_game_over_death_count()
	base["kill_ratio_per_raid"] = get_game_over_kill_ratio()
	base["survival_efficiency"] = get_survival_efficiency()
	base["combat_performance"] = get_combat_performance()
	base["legacy_score"] = get_legacy_score()
	base["endgame_ecosystem_health"] = get_endgame_ecosystem_health()
	base["legacy_governance"] = get_legacy_governance()
	base["civilization_maturity_index"] = get_civilization_maturity_index()
	return base


func draft_all() -> int:
	var cnt: int = 0
	for c: Dictionary in colonists:
		if not c.get("drafted", false):
			c["drafted"] = true
			cnt += 1
	return cnt


func undraft_all() -> int:
	var cnt: int = 0
	for c: Dictionary in colonists:
		if c.get("drafted", false):
			c["drafted"] = false
			cnt += 1
	return cnt


func get_drafted_count() -> int:
	var cnt: int = 0
	for c: Dictionary in colonists:
		if c.get("drafted", false):
			cnt += 1
	return cnt


func get_draft_pct() -> float:
	if colonists.is_empty():
		return 0.0
	return snappedf(float(get_drafted_count()) / float(colonists.size()) * 100.0, 0.1)

func get_undrafted_combat_capable_count() -> int:
	var cnt: int = 0
	for c: Dictionary in colonists:
		if not c.get("drafted", false):
			var skills: Dictionary = c.get("skills", {})
			if skills.get("Shooting", 0) >= 5 or skills.get("Melee", 0) >= 5:
				cnt += 1
	return cnt

func get_avg_combat_skill() -> float:
	if colonists.is_empty():
		return 0.0
	var total: float = 0.0
	for c: Dictionary in colonists:
		var skills: Dictionary = c.get("skills", {})
		total += maxf(float(skills.get("Shooting", 0)), float(skills.get("Melee", 0)))
	return snappedf(total / float(colonists.size()), 0.1)


func get_combat_ready_pct() -> float:
	if colonists.is_empty():
		return 0.0
	var combat: int = 0
	for c: Dictionary in colonists:
		var skills: Dictionary = c.get("skills", {})
		if skills.get("Shooting", 0) >= 5 or skills.get("Melee", 0) >= 5:
			combat += 1
	return snappedf(float(combat) / float(colonists.size()) * 100.0, 0.1)


func get_military_readiness() -> String:
	var ready_pct := get_combat_ready_pct()
	var draft_pct := get_draft_pct()
	if ready_pct >= 70.0 and draft_pct >= 30.0:
		return "Battle-Ready"
	elif ready_pct >= 40.0:
		return "Prepared"
	elif ready_pct >= 20.0:
		return "Undermanned"
	return "Vulnerable"

func get_force_projection() -> float:
	var drafted := float(get_drafted_count())
	var avg_skill := get_avg_combat_skill()
	return snapped(drafted * avg_skill * 2.0, 0.1)

func get_reserve_depth() -> float:
	var undrafted_capable := float(get_undrafted_combat_capable_count())
	var total := float(colonists.size())
	if total <= 0.0:
		return 0.0
	return snapped(undrafted_capable / total * 100.0, 0.1)

func get_draft_summary() -> Dictionary:
	return {
		"total_colonists": colonists.size(),
		"drafted": get_drafted_count(),
		"undrafted": colonists.size() - get_drafted_count(),
		"draft_pct": get_draft_pct(),
		"undrafted_combat_capable": get_undrafted_combat_capable_count(),
		"avg_combat_skill": get_avg_combat_skill(),
		"combat_ready_pct": get_combat_ready_pct(),
		"military_readiness": get_military_readiness(),
		"force_projection": get_force_projection(),
		"reserve_depth": get_reserve_depth(),
		"draft_ecosystem_health": get_draft_ecosystem_health(),
		"military_governance": get_military_governance(),
		"combat_maturity_index": get_combat_maturity_index(),
	}

func get_endgame_ecosystem_health() -> float:
	var survival := get_survival_efficiency()
	var combat := get_combat_performance()
	var c_val: float = 90.0 if combat == "Dominant" else (70.0 if combat == "Effective" else (40.0 if combat == "Adequate" else 15.0))
	var legacy := minf(get_legacy_score(), 100.0)
	return snapped((minf(survival, 100.0) + c_val + legacy) / 3.0, 0.1)

func get_legacy_governance() -> String:
	var eco := get_endgame_ecosystem_health()
	var mat := get_civilization_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif game_over:
		return "Nascent"
	return "Dormant"

func get_civilization_maturity_index() -> float:
	var days := minf(float(game_over_stats.get("day", 0)) / 60.0 * 100.0, 100.0)
	var survival := minf(get_survival_efficiency(), 100.0)
	var legacy := minf(get_legacy_score(), 100.0)
	return snapped((days + survival + legacy) / 3.0, 0.1)

func get_draft_ecosystem_health() -> float:
	var readiness := get_military_readiness()
	var r_val: float = 90.0 if readiness == "Battle Ready" else (65.0 if readiness == "Alert" else (35.0 if readiness == "Weak" else 15.0))
	var projection := minf(get_force_projection(), 100.0)
	var depth := minf(get_reserve_depth(), 100.0)
	return snapped((r_val + projection + depth) / 3.0, 0.1)

func get_military_governance() -> String:
	var eco := get_draft_ecosystem_health()
	var mat := get_combat_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif colonists.size() > 0:
		return "Nascent"
	return "Dormant"

func get_combat_maturity_index() -> float:
	var skill := minf(get_avg_combat_skill() * 10.0, 100.0)
	var ready := get_combat_ready_pct()
	var depth := minf(get_reserve_depth(), 100.0)
	return snapped((skill + ready + depth) / 3.0, 0.1)

func _init_mock_colonists() -> void:
	colonists = [
		_make_colonist("Engie", 32, "Construction", 0.72, 0.85, 0.60, 0.45),
		_make_colonist("Doc", 45, "Medicine", 0.55, 0.70, 0.80, 0.65),
		_make_colonist("Hawk", 28, "Shooting", 0.80, 0.90, 0.40, 0.70),
		_make_colonist("Cook", 38, "Cooking", 0.65, 0.75, 0.55, 0.50),
		_make_colonist("Miner", 35, "Mining", 0.58, 0.65, 0.70, 0.40),
		_make_colonist("Crafter", 41, "Crafting", 0.70, 0.80, 0.50, 0.60),
	]


const HEAD_TEXTURES := [
	"res://assets/textures/ui/Male_Narrow_Normal_south.png",
	"res://assets/textures/ui/Male_Narrow_Wide_south.png",
	"res://assets/textures/ui/Male_Narrow_Pointy_south.png",
	"res://assets/textures/ui/Female_Narrow_Normal_south.png",
	"res://assets/textures/ui/Female_Narrow_Wide_south.png",
	"res://assets/textures/ui/Female_Narrow_Pointy_south.png",
]

var _head_index := 0

func _make_colonist(cname: String, age: int, skill: String, mood: float, food: float, rest: float, joy: float) -> Dictionary:
	var head_tex: String = HEAD_TEXTURES[_head_index % HEAD_TEXTURES.size()]
	_head_index += 1
	return {
		"name": cname, "age": age, "main_skill": skill,
		"mood": mood, "food": food, "rest": rest, "joy": joy,
		"head_texture": head_tex,
		"gender": "Male" if _head_index % 2 == 0 else "Female",
		"outfit": ["Worker", "Doctor", "Soldier", "Nudist", "Casual"][randi() % 5],
		"drugs": ["Strict", "Social", "Unrestricted"][randi() % 3],
		"meals": ["Simple", "Fine", "Lavish", "Paste"][randi() % 4],
		"health": randf_range(0.7, 1.0),
		"drafted": false,
		"skills": {
			"Shooting": randi_range(0, 20), "Melee": randi_range(0, 20),
			"Construction": randi_range(0, 20), "Mining": randi_range(0, 20),
			"Cooking": randi_range(0, 20), "Plants": randi_range(0, 20),
			"Animals": randi_range(0, 20), "Crafting": randi_range(0, 20),
			"Artistic": randi_range(0, 20), "Medicine": randi_range(0, 20),
			"Social": randi_range(0, 20), "Intellectual": randi_range(0, 20),
		},
		"health_parts": [
			{"part": "Head", "status": "OK", "hp": 1.0},
			{"part": "Torso", "status": "OK", "hp": 1.0},
			{"part": "Left Arm", "status": "OK", "hp": randf_range(0.5, 1.0)},
			{"part": "Right Arm", "status": "OK", "hp": 1.0},
			{"part": "Left Leg", "status": "OK", "hp": 1.0},
			{"part": "Right Leg", "status": "OK", "hp": randf_range(0.6, 1.0)},
		],
	}


func _init_mock_resources() -> void:
	resources = [
		{"name": "Silver", "count": 1250, "category": "Items"},
		{"name": "Steel", "count": 340, "category": "Items"},
		{"name": "Wood", "count": 580, "category": "Items"},
		{"name": "Plasteel", "count": 42, "category": "Items"},
		{"name": "Component", "count": 18, "category": "Items"},
		{"name": "Gold", "count": 7, "category": "Items"},
		{"name": "Cloth", "count": 125, "category": "Textiles"},
		{"name": "Medicine", "count": 24, "category": "Medicine"},
		{"name": "Herbal Med.", "count": 15, "category": "Medicine"},
		{"name": "Simple Meal", "count": 32, "category": "Meals"},
		{"name": "Fine Meal", "count": 8, "category": "Meals"},
		{"name": "Rice", "count": 210, "category": "Raw Food"},
		{"name": "Corn", "count": 145, "category": "Raw Food"},
	]


func _init_mock_research() -> void:
	research_projects = [
		{"name": "Microelectronics", "cost": 4000, "progress": 0, "prereqs": [], "pos": Vector2(0, 0)},
		{"name": "Multi-analyzer", "cost": 4000, "progress": 0, "prereqs": ["Microelectronics"], "pos": Vector2(1, 0)},
		{"name": "Fabrication", "cost": 4000, "progress": 0, "prereqs": ["Microelectronics"], "pos": Vector2(1, 1)},
		{"name": "Gun Turrets", "cost": 1000, "progress": 1000, "prereqs": [], "pos": Vector2(0, 1)},
		{"name": "Mortars", "cost": 1500, "progress": 500, "prereqs": ["Gun Turrets"], "pos": Vector2(1, 2)},
		{"name": "Electricity", "cost": 1600, "progress": 1600, "prereqs": [], "pos": Vector2(-1, 0)},
		{"name": "Battery", "cost": 800, "progress": 800, "prereqs": ["Electricity"], "pos": Vector2(0, -1)},
		{"name": "Solar Panels", "cost": 1200, "progress": 1200, "prereqs": ["Electricity"], "pos": Vector2(-1, -1)},
		{"name": "Geothermal", "cost": 3200, "progress": 0, "prereqs": ["Electricity", "Microelectronics"], "pos": Vector2(0, -2)},
		{"name": "Hospital Bed", "cost": 1200, "progress": 1200, "prereqs": [], "pos": Vector2(-1, 1)},
		{"name": "Vitals Monitor", "cost": 2500, "progress": 0, "prereqs": ["Hospital Bed", "Microelectronics"], "pos": Vector2(0, 2)},
		{"name": "Machining", "cost": 2000, "progress": 2000, "prereqs": [], "pos": Vector2(-2, 0)},
		{"name": "Precision Rifling", "cost": 2800, "progress": 1400, "prereqs": ["Machining"], "pos": Vector2(-2, 1)},
		{"name": "Transport Pod", "cost": 2000, "progress": 0, "prereqs": ["Microelectronics"], "pos": Vector2(2, 0)},
		{"name": "Cryptosleep", "cost": 2000, "progress": 0, "prereqs": ["Microelectronics"], "pos": Vector2(2, 1)},
	]


func _init_mock_architect() -> void:
	architect_categories = [
		{"name": "Orders", "icon": "orders", "items": [
			{"name": "Cancel", "desc": "Cancel a designation"},
			{"name": "Deconstruct", "desc": "Deconstruct a building"},
			{"name": "Mine", "desc": "Designate cells to mine"},
			{"name": "Haul", "desc": "Designate items to haul"},
			{"name": "Hunt", "desc": "Designate animals to hunt"},
			{"name": "Cut Plants", "desc": "Designate plants to cut"},
		]},
		{"name": "Zone", "icon": "zone", "items": [
			{"name": "Stockpile", "desc": "Create a stockpile zone"},
			{"name": "Dumping", "desc": "Create a dumping zone"},
			{"name": "Growing", "desc": "Create a growing zone"},
			{"name": "Home Area", "desc": "Expand or clear home area"},
			{"name": "Animal Area", "desc": "Create an animal area"},
		]},
		{"name": "Structure", "icon": "structure", "items": [
			{"name": "Wall", "desc": "Build a wall"},
			{"name": "Door", "desc": "Build a door"},
			{"name": "Autodoor", "desc": "Build an autodoor"},
			{"name": "Column", "desc": "Build a column"},
			{"name": "Fence", "desc": "Build a fence"},
			{"name": "Barricade", "desc": "Build a barricade"},
		]},
		{"name": "Production", "icon": "production", "items": [
			{"name": "Crafting Spot", "desc": "A spot for crafting"},
			{"name": "Butcher Table", "desc": "For butchering animals"},
			{"name": "Stove", "desc": "Cook meals"},
			{"name": "Tailoring Bench", "desc": "Create apparel"},
			{"name": "Smithy", "desc": "Forge weapons"},
			{"name": "Machining Table", "desc": "Produce components"},
		]},
		{"name": "Furniture", "icon": "furniture", "items": [
			{"name": "Bed", "desc": "A simple bed"},
			{"name": "Double Bed", "desc": "Bed for two"},
			{"name": "Table", "desc": "Colonists eat here"},
			{"name": "Dining Chair", "desc": "Seat for dining"},
			{"name": "Armchair", "desc": "Comfortable seating"},
			{"name": "Shelf", "desc": "Store items"},
		]},
		{"name": "Power", "icon": "power", "items": [
			{"name": "Wood Gen.", "desc": "Wood-fueled generator"},
			{"name": "Chemfuel Gen.", "desc": "Chemfuel generator"},
			{"name": "Solar Gen.", "desc": "Solar power generator"},
			{"name": "Wind Turbine", "desc": "Wind power generator"},
			{"name": "Battery", "desc": "Stores electricity"},
			{"name": "Power Conduit", "desc": "Transmit power"},
		]},
		{"name": "Security", "icon": "security", "items": [
			{"name": "Sandbags", "desc": "Cover for shooters"},
			{"name": "Mini-turret", "desc": "Automated turret"},
			{"name": "Spike Trap", "desc": "A deadly trap"},
			{"name": "IED Trap", "desc": "Explosive trap"},
			{"name": "Embrasure", "desc": "Shoot through wall"},
		]},
		{"name": "Misc", "icon": "misc", "items": [
			{"name": "Campfire", "desc": "A warm campfire"},
			{"name": "Torch Lamp", "desc": "Light from torch"},
			{"name": "Standing Lamp", "desc": "Electric lamp"},
			{"name": "Research Bench", "desc": "For research"},
			{"name": "Comms Console", "desc": "Contact traders"},
			{"name": "Orbital Beacon", "desc": "Trade from orbit"},
		]},
		{"name": "Floors", "icon": "floors", "items": [
			{"name": "Wood Floor", "desc": "Wooden flooring"},
			{"name": "Stone Tile", "desc": "Stone tile floor"},
			{"name": "Carpet", "desc": "Soft carpet"},
			{"name": "Concrete", "desc": "Concrete floor"},
			{"name": "Sterile Tile", "desc": "Clean tile for hospitals"},
		]},
	]


func _init_mock_misc() -> void:
	tamed_animals = [
		{"name": "Husky", "gender": "M", "age": 3, "training": "Obedience, Rescue"},
		{"name": "Boomrat", "gender": "F", "age": 1, "training": "—"},
		{"name": "Muffalo", "gender": "M", "age": 5, "training": "Pack, Milking"},
		{"name": "Cat", "gender": "F", "age": 2, "training": "Nuzzle"},
	]
	wildlife_species = [
		{"species": "Squirrel", "count": 12, "threat": "Harmless"},
		{"species": "Rat", "count": 8, "threat": "Harmless"},
		{"species": "Boomalope", "count": 2, "threat": "Explosive"},
		{"species": "Thrumbo", "count": 1, "threat": "Extreme"},
		{"species": "Warg", "count": 3, "threat": "Hostile"},
	]
	history_log = [
		{"day": 1, "text": "The three crash-landed survivors formed a colony."},
		{"day": 2, "text": "Engie completed the wooden perimeter."},
		{"day": 3, "text": "Raid: 3 tribals repelled at the sandbags."},
		{"day": 5, "text": "Doc treated Hawk for minor bruises."},
		{"day": 7, "text": "Heat wave: crops saved by irrigation."},
		{"day": 10, "text": "Trade caravan departed with surplus cloth."},
	]
