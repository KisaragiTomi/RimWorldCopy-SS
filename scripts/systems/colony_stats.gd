extends Node

## Aggregates all colony statistics into a single dashboard.
## Registered as autoload "ColonyStats".


func get_full_dashboard() -> Dictionary:
	var r: Dictionary = {}

	r["tick"] = TickManager.current_tick if TickManager else 0
	r["date"] = GameState.game_date.duplicate() if GameState else {}
	r["temperature"] = GameState.temperature if GameState else 15.0
	r["weather"] = WeatherManager.current_weather if WeatherManager else "Clear"
	r["wealth"] = GameState.get_colony_wealth() if GameState else 0.0

	var pawns_info: Array[Dictionary] = []
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.dead:
				continue
			pawns_info.append({
				"name": p.pawn_name,
				"job": p.current_job_name,
				"mood": snappedf(p.get_need("Mood"), 0.01),
				"food": snappedf(p.get_need("Food"), 0.01),
				"rest": snappedf(p.get_need("Rest"), 0.01),
				"joy": snappedf(p.get_need("Joy"), 0.01),
				"drafted": p.drafted,
				"downed": p.downed,
				"traits": Array(p.traits),
			})
	r["colonists"] = pawns_info
	r["colonist_count"] = pawns_info.size()

	r["animals"] = AnimalManager.get_summary() if AnimalManager else {}
	r["fire"] = FireManager.get_summary() if FireManager else {}
	r["alerts"] = AlertManager.get_summary() if AlertManager else {}
	r["prisoners"] = PrisonerManager.get_summary() if PrisonerManager else {}
	r["research"] = _get_research_summary()
	r["recent_logs"] = ColonyLog.get_recent(5) if ColonyLog else []
	r["history"] = HistoryTracker.get_summary() if HistoryTracker else {}

	return r


func get_colony_health_score() -> float:
	var score: float = 50.0
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.dead:
				score -= 5.0
			elif p.downed:
				score -= 3.0
			else:
				score += p.get_need("Mood") * 10.0
	if FireManager and FireManager.fires.size() > 0:
		score -= float(FireManager.fires.size()) * 10.0
	if AlertManager:
		score -= float(AlertManager.get_danger_count()) * 5.0
	return clampf(score, 0.0, 100.0)


func get_quick_status() -> String:
	var score: float = get_colony_health_score()
	if score >= 80.0:
		return "Thriving"
	elif score >= 60.0:
		return "Stable"
	elif score >= 40.0:
		return "Struggling"
	return "Critical"


func get_compact_summary() -> Dictionary:
	return {
		"health_score": snappedf(get_colony_health_score(), 0.1),
		"status": get_quick_status(),
		"colonists": PawnManager.pawns.filter(func(p: Pawn) -> bool: return not p.dead).size() if PawnManager else 0,
		"wealth": snappedf(GameState.get_colony_wealth(), 1.0) if GameState else 0.0,
	}


func get_alive_pawn_count() -> int:
	if not PawnManager:
		return 0
	var cnt: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			cnt += 1
	return cnt


func get_downed_pawn_count() -> int:
	if not PawnManager:
		return 0
	var cnt: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead and p.downed:
			cnt += 1
	return cnt


func get_avg_mood() -> float:
	if not PawnManager:
		return 0.0
	var total: float = 0.0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			total += p.get_need("Mood")
			count += 1
	if count == 0:
		return 0.0
	return snappedf(total / float(count), 0.01)


func get_drafted_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead and p.drafted:
			count += 1
	return count


func is_any_critical() -> bool:
	return get_colony_health_score() < 30.0 or get_downed_pawn_count() > 0


func get_healthy_pawn_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead and not p.downed:
			count += 1
	return count


func get_operational_ratio() -> float:
	var alive: int = get_alive_pawn_count()
	if alive <= 0:
		return 0.0
	return snappedf(float(get_healthy_pawn_count()) / float(alive) * 100.0, 0.1)


func get_mood_risk_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead and p.get_need("Mood") < 0.3:
			count += 1
	return count


func get_health_breakdown() -> Dictionary:
	return {
		"score": snappedf(get_colony_health_score(), 0.1),
		"status": get_quick_status(),
		"alive": get_alive_pawn_count(),
		"downed": get_downed_pawn_count(),
		"avg_mood": get_avg_mood(),
		"drafted": get_drafted_count(),
		"is_critical": is_any_critical(),
		"healthy": get_healthy_pawn_count(),
		"operational_pct": get_operational_ratio(),
		"mood_at_risk": get_mood_risk_count(),
		"colony_resilience": get_colony_resilience(),
		"workforce_readiness": get_workforce_readiness(),
		"crisis_level": get_crisis_level(),
		"colony_ecosystem_health": get_colony_ecosystem_health(),
		"settlement_governance": get_settlement_governance(),
		"colony_maturity_index": get_colony_maturity_index(),
	}


func get_colony_resilience() -> float:
	var alive := get_alive_pawn_count()
	if alive <= 0:
		return 0.0
	var healthy := float(get_healthy_pawn_count())
	var risk := float(get_mood_risk_count())
	var downed := float(get_downed_pawn_count())
	var score := (healthy / float(alive)) * 70.0 + maxf(0.0, (1.0 - risk / float(alive)) * 20.0) + maxf(0.0, (1.0 - downed / float(alive)) * 10.0)
	return snapped(clampf(score, 0.0, 100.0), 0.1)

func get_workforce_readiness() -> String:
	var alive := get_alive_pawn_count()
	var healthy := get_healthy_pawn_count()
	var drafted := get_drafted_count()
	if alive <= 0:
		return "None"
	var available := healthy - drafted
	if available >= alive * 0.7:
		return "Strong"
	elif available >= alive * 0.4:
		return "Adequate"
	elif available > 0:
		return "Thin"
	return "Critical"

func get_crisis_level() -> String:
	var health := get_colony_health_score()
	if health >= 80.0:
		return "Stable"
	elif health >= 60.0:
		return "Cautious"
	elif health >= 40.0:
		return "Alarming"
	return "Emergency"

func get_colony_ecosystem_health() -> float:
	var resilience := get_colony_resilience()
	var readiness := get_workforce_readiness()
	var r_val: float = 90.0 if readiness == "Strong" else (65.0 if readiness == "Adequate" else (35.0 if readiness == "Thin" else 10.0))
	var crisis := get_crisis_level()
	var c_val: float = 90.0 if crisis == "Stable" else (65.0 if crisis == "Cautious" else (35.0 if crisis == "Alarming" else 10.0))
	return snapped((resilience + r_val + c_val) / 3.0, 0.1)

func get_settlement_governance() -> String:
	var eco := get_colony_ecosystem_health()
	var mat := get_colony_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_alive_pawn_count() > 0:
		return "Nascent"
	return "Dormant"

func get_colony_maturity_index() -> float:
	var op := get_operational_ratio()
	var resilience := get_colony_resilience()
	var risk := float(get_mood_risk_count())
	var alive := float(get_alive_pawn_count())
	var risk_inv: float = 100.0 if alive <= 0.0 else maxf(100.0 - risk / alive * 100.0, 0.0)
	return snapped((op + resilience + risk_inv) / 3.0, 0.1)

func _get_research_summary() -> Dictionary:
	if not ResearchManager:
		return {}
	return {
		"current": ResearchManager.current_project if ResearchManager.has_method("get") else "",
		"completed_count": ResearchManager.completed_projects.size() if ResearchManager.get("completed_projects") else 0,
	}
