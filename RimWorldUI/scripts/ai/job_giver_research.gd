class_name JobGiverResearch
extends ThinkNode

## Issues a Research job when there's an active project and the pawn
## can research. Prefers pawns with higher Intellectual skill.

const MIN_INTELLECTUAL: int = 0


func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.drafted or pawn.dead or pawn.downed:
		return {}
	if not pawn.is_capable_of("Research"):
		return {}
	if not ResearchManager:
		return {}
	if ResearchManager.current_project.is_empty():
		if ResearchManager.has_method("get_available_projects"):
			var avail: Array = ResearchManager.get_available_projects()
			if avail.is_empty():
				return {}
			if ResearchManager.research_queue.is_empty():
				return {}
		else:
			return {}

	var bench_pos := _find_research_bench()
	var job := Job.new()
	job.job_def = "Research"
	if bench_pos != Vector2i(-1, -1):
		job.target_pos = bench_pos
	return {"job": job}


func get_research_bench_count() -> int:
	if not ThingManager:
		return 0
	var cnt: int = 0
	for t: Thing in ThingManager.things:
		if t is Building and t.def_name in ["HiTechResearchBench", "SimpleResearchBench"]:
			if (t as Building).build_state == Building.BuildState.COMPLETE:
				cnt += 1
	return cnt


func has_active_project() -> bool:
	if not ResearchManager:
		return false
	return not ResearchManager.current_project.is_empty()


func get_best_researcher() -> Dictionary:
	if not PawnManager:
		return {}
	var best: Pawn = null
	var best_skill: int = -1
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed or p.drafted:
			continue
		if not p.is_capable_of("Research"):
			continue
		var lvl: int = p.get_skill_level("Intellectual")
		if lvl > best_skill:
			best_skill = lvl
			best = p
	if best == null:
		return {}
	return {"name": best.pawn_name, "skill": best_skill}


func _find_research_bench() -> Vector2i:
	if not ThingManager:
		return Vector2i(-1, -1)
	for t: Thing in ThingManager.things:
		if t is Building and t.def_name == "HiTechResearchBench":
			if (t as Building).build_state == Building.BuildState.COMPLETE:
				return t.grid_pos
	for t: Thing in ThingManager.things:
		if t is Building and t.def_name == "SimpleResearchBench":
			if (t as Building).build_state == Building.BuildState.COMPLETE:
				return t.grid_pos
	return Vector2i(-1, -1)


func get_capable_researcher_count() -> int:
	if not PawnManager:
		return 0
	var cnt: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead and not p.downed and p.is_capable_of("Research"):
			cnt += 1
	return cnt


func get_researcher_to_bench_ratio() -> float:
	var benches: int = get_research_bench_count()
	if benches <= 0:
		return 0.0
	return snappedf(float(get_capable_researcher_count()) / float(benches), 0.01)


func is_research_bottleneck() -> bool:
	return get_research_bench_count() > 0 and get_capable_researcher_count() == 0


func get_research_capacity() -> String:
	var benches: int = get_research_bench_count()
	var researchers: int = get_capable_researcher_count()
	if benches == 0:
		return "None"
	if researchers == 0:
		return "No Researchers"
	if researchers >= benches:
		return "Full"
	return "Partial"


func get_research_throughput() -> float:
	var benches := get_research_bench_count()
	var researchers := get_capable_researcher_count()
	if benches <= 0 or researchers <= 0:
		return 0.0
	return snapped(float(mini(researchers, benches)) / float(benches) * 100.0, 0.1)

func get_knowledge_pipeline() -> String:
	if not has_active_project():
		return "Idle"
	var ratio := get_researcher_to_bench_ratio()
	if ratio >= 1.0:
		return "Saturated"
	elif ratio >= 0.5:
		return "Active"
	return "Understaffed"

func get_infrastructure_adequacy() -> String:
	var benches := get_research_bench_count()
	var researchers := get_capable_researcher_count()
	if benches <= 0:
		return "No Labs"
	if researchers <= 0:
		return "No Scientists"
	if researchers > benches * 2:
		return "Need More Labs"
	if benches > researchers * 2:
		return "Excess Labs"
	return "Balanced"

func get_research_summary() -> Dictionary:
	return {
		"bench_count": get_research_bench_count(),
		"researchers": get_capable_researcher_count(),
		"active_project": has_active_project(),
		"best_researcher": get_best_researcher(),
		"researcher_bench_ratio": get_researcher_to_bench_ratio(),
		"is_bottleneck": is_research_bottleneck(),
		"capacity": get_research_capacity(),
		"throughput_pct": get_research_throughput(),
		"knowledge_pipeline": get_knowledge_pipeline(),
		"infrastructure_adequacy": get_infrastructure_adequacy(),
		"research_ecosystem_health": get_research_ai_ecosystem_health(),
		"academic_governance": get_academic_governance(),
		"scholarship_maturity_index": get_scholarship_maturity_index(),
	}

func get_research_ai_ecosystem_health() -> float:
	var throughput := get_research_throughput()
	var pipeline := get_knowledge_pipeline()
	var p_val: float = 90.0 if pipeline == "Productive" else (65.0 if pipeline == "Active" else (35.0 if pipeline == "Idle" else 15.0))
	var infra := get_infrastructure_adequacy()
	var i_val: float = 90.0 if infra == "Excellent" else (65.0 if infra == "Adequate" else (35.0 if infra == "Limited" else 15.0))
	return snapped((throughput + p_val + i_val) / 3.0, 0.1)

func get_academic_governance() -> String:
	var eco := get_research_ai_ecosystem_health()
	var mat := get_scholarship_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_research_bench_count() > 0:
		return "Nascent"
	return "Dormant"

func get_scholarship_maturity_index() -> float:
	var benches := minf(float(get_research_bench_count()) * 25.0, 100.0)
	var researchers := minf(float(get_capable_researcher_count()) * 20.0, 100.0)
	var throughput := get_research_throughput()
	return snapped((benches + researchers + throughput) / 3.0, 0.1)
