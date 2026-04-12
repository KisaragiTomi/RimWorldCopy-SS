extends Node

enum PassionLevel { NONE, MINOR, MAJOR }

const PASSION_LABELS: Dictionary = {
	0: "None",
	1: "Minor",
	2: "Major",
}

const XP_MULTIPLIER: Dictionary = {
	0: 1.0,
	1: 1.5,
	2: 2.0,
}

const JOY_MULTIPLIER: Dictionary = {
	0: 0.0,
	1: 0.005,
	2: 0.01,
}


func get_passion_label(level: int) -> String:
	return PASSION_LABELS.get(level, "None")


func get_xp_factor(level: int) -> float:
	return XP_MULTIPLIER.get(level, 1.0)


func get_joy_from_work(level: int) -> float:
	return JOY_MULTIPLIER.get(level, 0.0)


func get_pawn_passions(pawn: Pawn) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if pawn.skills == null:
		return result
	for skill_name: String in pawn.skills:
		var sdata: Dictionary = pawn.skills[skill_name]
		var passion: int = int(sdata.get("passion", 0))
		result.append({
			"skill": skill_name,
			"level": int(sdata.get("level", 0)),
			"passion": passion,
			"passion_label": get_passion_label(passion),
			"xp_factor": get_xp_factor(passion),
		})
	return result


func get_colony_passions() -> Dictionary:
	if not PawnManager:
		return {"pawns": []}
	var pawns_data: Array[Dictionary] = []
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var passions: Array[Dictionary] = get_pawn_passions(p)
		var major_count: int = 0
		var minor_count: int = 0
		for pd: Dictionary in passions:
			if pd.passion == PassionLevel.MAJOR:
				major_count += 1
			elif pd.passion == PassionLevel.MINOR:
				minor_count += 1
		pawns_data.append({
			"name": p.pawn_name,
			"major": major_count,
			"minor": minor_count,
		})
	return {"pawns": pawns_data}


func get_skill_coverage() -> Dictionary:
	if not PawnManager:
		return {}
	var coverage: Dictionary = {}
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.skills == null:
			continue
		for skill_name: String in p.skills:
			var sdata: Dictionary = p.skills[skill_name]
			var passion: int = int(sdata.get("passion", 0))
			if passion > 0:
				if not coverage.has(skill_name):
					coverage[skill_name] = {"minor": 0, "major": 0}
				if passion == PassionLevel.MAJOR:
					coverage[skill_name].major += 1
				else:
					coverage[skill_name].minor += 1
	return coverage


func get_best_pawn_for_skill(skill_name: String) -> String:
	if not PawnManager:
		return ""
	var best_name: String = ""
	var best_score: float = -1.0
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.skills == null or not p.skills.has(skill_name):
			continue
		var sdata: Dictionary = p.skills[skill_name]
		var level: float = float(sdata.get("level", 0))
		var passion: int = int(sdata.get("passion", 0))
		var score: float = level + float(passion) * 5.0
		if score > best_score:
			best_score = score
			best_name = p.pawn_name
	return best_name


func get_total_passions() -> Dictionary:
	var totals: Dictionary = {"none": 0, "minor": 0, "major": 0}
	if not PawnManager:
		return totals
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.skills == null:
			continue
		for skill_name: String in p.skills:
			var sdata: Dictionary = p.skills[skill_name]
			var passion: int = int(sdata.get("passion", 0))
			if passion == PassionLevel.MAJOR:
				totals.major += 1
			elif passion == PassionLevel.MINOR:
				totals.minor += 1
			else:
				totals.none += 1
	return totals


func get_summary() -> Dictionary:
	var base: Dictionary = get_colony_passions()
	base["totals"] = get_total_passions()
	base["coverage"] = get_skill_coverage()
	return base
