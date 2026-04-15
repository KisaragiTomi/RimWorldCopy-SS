extends Node


func get_colonist_overview() -> Array:
	var overview: Array = []
	if not PawnManager or not PawnManager.has_method("get_all_pawns"):
		return overview
	var pawns: Array = PawnManager.get_all_pawns()
	for pawn in pawns:
		var p: Dictionary = pawn if pawn is Dictionary else {}
		var entry: Dictionary = {
			"id": p.get("id", -1),
			"name": p.get("name", "Unknown"),
			"health": _get_health_status(p),
			"mood": _get_mood_status(p),
			"best_skill": _get_best_skill(p),
		}
		overview.append(entry)
	return overview


func _get_health_status(pawn: Dictionary) -> String:
	var hp: float = float(pawn.get("hp", 1.0))
	if hp >= 0.8:
		return "Healthy"
	elif hp >= 0.5:
		return "Injured"
	elif hp > 0:
		return "Critical"
	else:
		return "Dead"


func _get_mood_status(pawn: Dictionary) -> String:
	var mood: float = float(pawn.get("mood_level", 0.5))
	if mood >= 0.7:
		return "Happy"
	elif mood >= 0.4:
		return "Neutral"
	elif mood >= 0.2:
		return "Stressed"
	else:
		return "Breaking"


func _get_best_skill(pawn: Dictionary) -> String:
	var skills: Dictionary = pawn.get("skills", {}) if pawn.get("skills", null) is Dictionary else {}
	var best: String = "None"
	var best_val: int = 0
	for sk: String in skills:
		var val: int = int(skills[sk])
		if val > best_val:
			best_val = val
			best = sk
	return best + " " + str(best_val) if best != "None" else "None"


func get_health_distribution() -> Dictionary:
	var dist: Dictionary = {"Healthy": 0, "Injured": 0, "Critical": 0, "Dead": 0}
	var overview: Array = get_colonist_overview()
	for e: Dictionary in overview:
		var h: String = String(e.get("health", "Healthy"))
		dist[h] = dist.get(h, 0) + 1
	return dist


func get_mood_distribution() -> Dictionary:
	var dist: Dictionary = {"Happy": 0, "Neutral": 0, "Stressed": 0, "Breaking": 0}
	var overview: Array = get_colonist_overview()
	for e: Dictionary in overview:
		var m: String = String(e.get("mood", "Neutral"))
		dist[m] = dist.get(m, 0) + 1
	return dist


func get_critical_colonists() -> Array:
	var result: Array = []
	var overview: Array = get_colonist_overview()
	for e: Dictionary in overview:
		if String(e.get("health", "")) == "Critical" or String(e.get("mood", "")) == "Breaking":
			result.append(e)
	return result


func get_healthy_percentage() -> float:
	var dist := get_health_distribution()
	var total: int = 0
	for k: String in dist:
		total += dist[k]
	if total == 0:
		return 0.0
	return snappedf(float(dist.get("Healthy", 0)) / float(total) * 100.0, 0.1)


func get_happy_percentage() -> float:
	var dist := get_mood_distribution()
	var total: int = 0
	for k: String in dist:
		total += dist[k]
	if total == 0:
		return 0.0
	return snappedf(float(dist.get("Happy", 0)) / float(total) * 100.0, 0.1)


func has_critical_situation() -> bool:
	return not get_critical_colonists().is_empty()


func get_colony_wellness() -> String:
	var healthy: float = get_healthy_percentage()
	var happy: float = get_happy_percentage()
	var avg: float = (healthy + happy) / 2.0
	if avg >= 80.0:
		return "Thriving"
	elif avg >= 60.0:
		return "Stable"
	elif avg >= 40.0:
		return "Struggling"
	return "Crisis"

func get_crisis_severity() -> String:
	var critical: int = get_critical_colonists().size()
	if critical == 0:
		return "None"
	elif critical <= 2:
		return "Minor"
	elif critical <= 5:
		return "Serious"
	return "Emergency"

func get_morale_index() -> float:
	var happy: float = get_happy_percentage()
	var healthy: float = get_healthy_percentage()
	return snappedf((happy * 0.6 + healthy * 0.4), 0.1)

func get_summary() -> Dictionary:
	var overview: Array = get_colonist_overview()
	return {
		"colonist_count": overview.size(),
		"health": get_health_distribution(),
		"mood": get_mood_distribution(),
		"critical": get_critical_colonists().size(),
		"healthy_pct": get_healthy_percentage(),
		"happy_pct": get_happy_percentage(),
		"has_critical": has_critical_situation(),
		"colony_wellness": get_colony_wellness(),
		"crisis_severity": get_crisis_severity(),
		"morale_index": get_morale_index(),
		"population_resilience": get_population_resilience(),
		"wellness_trajectory": get_wellness_trajectory(),
		"leadership_readiness": get_leadership_readiness(),
		"colony_vitality_index": get_colony_vitality_index(),
		"demographic_governance": get_demographic_governance(),
		"human_capital_score": get_human_capital_score(),
	}

func get_population_resilience() -> String:
	var morale := get_morale_index()
	var crisis := get_crisis_severity()
	if morale >= 70.0 and crisis == "None":
		return "Strong"
	elif morale >= 40.0:
		return "Adequate"
	return "Fragile"

func get_wellness_trajectory() -> String:
	var healthy := get_healthy_percentage()
	var happy := get_happy_percentage()
	if healthy >= 80.0 and happy >= 70.0:
		return "Thriving"
	elif healthy >= 50.0:
		return "Stable"
	return "Declining"

func get_leadership_readiness() -> float:
	var overview := get_colonist_overview()
	var capable := 0
	for c: Dictionary in overview:
		if c.get("health_pct", 0.0) >= 70.0 and c.get("mood", 0.0) >= 50.0:
			capable += 1
	if overview.is_empty():
		return 0.0
	return snapped(float(capable) / float(overview.size()) * 100.0, 0.1)

func get_colony_vitality_index() -> float:
	var healthy := get_healthy_percentage()
	var happy := get_happy_percentage()
	var leadership := get_leadership_readiness()
	return snapped((healthy + happy + leadership) / 3.0, 0.1)

func get_demographic_governance() -> String:
	var vitality := get_colony_vitality_index()
	var resilience := get_population_resilience()
	if vitality >= 70.0 and resilience in ["Resilient", "Strong"]:
		return "Well Governed"
	elif vitality >= 40.0:
		return "Developing"
	return "Fragile"

func get_human_capital_score() -> float:
	var morale := get_morale_index()
	var crisis := get_crisis_severity()
	var cr_val: float = 90.0 if crisis == "None" else (60.0 if crisis == "Minor" else 20.0)
	return snapped((morale + cr_val) / 2.0, 0.1)
