extends Node

const TITLES: Dictionary = {
	"Master Builder": {"skill": "Construction", "min_level": 15},
	"Sharpshooter": {"skill": "Shooting", "min_level": 15},
	"Blade Master": {"skill": "Melee", "min_level": 15},
	"Gourmet Chef": {"skill": "Cooking", "min_level": 15},
	"Healer": {"skill": "Medicine", "min_level": 12},
	"Genius": {"skill": "Intellectual", "min_level": 15},
	"Green Thumb": {"skill": "Plants", "min_level": 12},
	"Beast Whisperer": {"skill": "Animals", "min_level": 12},
	"Master Artisan": {"skill": "Crafting", "min_level": 15},
	"Master Artist": {"skill": "Artistic", "min_level": 15},
	"Deep Miner": {"skill": "Mining", "min_level": 12},
	"Silver Tongue": {"skill": "Social", "min_level": 12},
}

const ACHIEVEMENT_TITLES: Dictionary = {
	"Survivor": {"condition": "survived_50_days"},
	"Veteran": {"condition": "fought_10_battles"},
	"Explorer": {"condition": "revealed_50_percent"},
	"Founder": {"condition": "first_colonist"},
}


func get_pawn_titles(pawn: Pawn) -> Array[String]:
	var result: Array[String] = []
	for title_name: String in TITLES:
		var req: Dictionary = TITLES[title_name]
		var skill_name: String = req.get("skill", "")
		var min_level: int = int(req.get("min_level", 99))
		if pawn.skills.has(skill_name):
			var level: int = int(pawn.skills[skill_name].get("level", 0))
			if level >= min_level:
				result.append(title_name)
	return result


func get_primary_title(pawn: Pawn) -> String:
	var titles: Array[String] = get_pawn_titles(pawn)
	if titles.is_empty():
		return "Colonist"
	return titles[0]


func get_title_holders(pawns: Array) -> Dictionary:
	var holders: Dictionary = {}
	for p: Pawn in pawns:
		var titles: Array[String] = get_pawn_titles(p)
		for t: String in titles:
			if not holders.has(t):
				holders[t] = []
			holders[t].append(p.pawn_id if "pawn_id" in p else 0)
	return holders


func get_untitled_count(pawns: Array) -> int:
	var count: int = 0
	for p: Pawn in pawns:
		if get_pawn_titles(p).is_empty():
			count += 1
	return count


func get_title_requirement(title_name: String) -> Dictionary:
	if TITLES.has(title_name):
		return TITLES[title_name].duplicate()
	if ACHIEVEMENT_TITLES.has(title_name):
		return ACHIEVEMENT_TITLES[title_name].duplicate()
	return {}


func get_most_titled_pawn() -> Dictionary:
	if not PawnManager:
		return {}
	var best_name: String = ""
	var best_count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var count: int = get_pawn_titles(p).size()
		if count > best_count:
			best_count = count
			best_name = p.pawn_name
	if best_name.is_empty():
		return {}
	return {"name": best_name, "titles": best_count}


func get_rarest_title() -> String:
	if not PawnManager:
		return ""
	var title_counts: Dictionary = {}
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		for t: String in get_pawn_titles(p):
			title_counts[t] = title_counts.get(t, 0) + 1
	var rarest: String = ""
	var rarest_n: int = 99999
	for t: String in title_counts:
		if title_counts[t] < rarest_n:
			rarest_n = title_counts[t]
			rarest = t
	return rarest


func get_titled_pawn_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if not get_pawn_titles(p).is_empty():
			count += 1
	return count


func get_prestige_rating() -> String:
	var titled: int = get_titled_pawn_count()
	if titled >= 5:
		return "Distinguished"
	elif titled >= 2:
		return "Notable"
	elif titled > 0:
		return "Modest"
	return "Unknown"

func get_achievement_ratio() -> float:
	var total: int = TITLES.size() + ACHIEVEMENT_TITLES.size()
	if total <= 0:
		return 0.0
	return snappedf(float(ACHIEVEMENT_TITLES.size()) / float(total) * 100.0, 0.1)

func get_title_coverage_pct() -> float:
	var total: int = TITLES.size() + ACHIEVEMENT_TITLES.size()
	if total <= 0:
		return 0.0
	return snappedf(float(get_titled_pawn_count()) / maxf(float(total), 1.0) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"skill_titles": TITLES.size(),
		"achievement_titles": ACHIEVEMENT_TITLES.size(),
		"total_titles": TITLES.size() + ACHIEVEMENT_TITLES.size(),
		"most_titled": get_most_titled_pawn(),
		"rarest_title": get_rarest_title(),
		"titled_pawns": get_titled_pawn_count(),
		"titles_per_pawn": snappedf(float(TITLES.size() + ACHIEVEMENT_TITLES.size()) / maxf(float(get_titled_pawn_count()), 1.0), 0.1),
		"untitled_pct": 100.0 - snappedf(float(get_titled_pawn_count()) / maxf(float(get_titled_pawn_count() + 1), 1.0) * 100.0, 0.1),
		"prestige_rating": get_prestige_rating(),
		"achievement_ratio_pct": get_achievement_ratio(),
		"title_coverage_pct": get_title_coverage_pct(),
		"honor_depth": get_honor_depth(),
		"recognition_maturity": get_recognition_maturity(),
		"merit_distribution": get_merit_distribution(),
		"prestige_ecosystem_health": get_prestige_ecosystem_health(),
		"meritocracy_index": get_meritocracy_index(),
		"legacy_depth": get_legacy_depth(),
	}

func get_prestige_ecosystem_health() -> float:
	var coverage := get_title_coverage_pct()
	var achievement := get_achievement_ratio()
	return snapped((coverage + achievement) / 2.0, 0.1)

func get_meritocracy_index() -> float:
	var titled := float(get_titled_pawn_count())
	var total_titles := float(TITLES.size() + ACHIEVEMENT_TITLES.size())
	if total_titles <= 0.0:
		return 0.0
	return snapped(titled / total_titles * 100.0, 0.1)

func get_legacy_depth() -> String:
	var depth := get_honor_depth()
	var maturity := get_recognition_maturity()
	if depth == "Deep" and maturity in ["Established", "Mature"]:
		return "Legendary"
	elif depth == "Shallow":
		return "Fledgling"
	return "Growing"

func get_honor_depth() -> String:
	var titled := get_titled_pawn_count()
	if titled >= 5:
		return "Deep"
	elif titled >= 2:
		return "Moderate"
	elif titled > 0:
		return "Shallow"
	return "None"

func get_recognition_maturity() -> String:
	var coverage := get_title_coverage_pct()
	var prestige := get_prestige_rating()
	if coverage >= 70.0 and prestige in ["Prestigious", "Distinguished"]:
		return "Mature"
	elif coverage >= 30.0:
		return "Growing"
	return "Nascent"

func get_merit_distribution() -> float:
	var titled := get_titled_pawn_count()
	var total := TITLES.size() + ACHIEVEMENT_TITLES.size()
	if total <= 0:
		return 0.0
	return snapped(float(titled) / float(total) * 100.0, 0.1)
