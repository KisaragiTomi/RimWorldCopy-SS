class_name JobGiverWarden
extends ThinkNode

## Issues a Warden job to chat with/recruit prisoners.


func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.drafted or pawn.dead or pawn.downed:
		return {}
	if not pawn.is_capable_of("Warden"):
		return {}
	if not PrisonerManager:
		return {}
	if PrisonerManager.prisoners.is_empty():
		return {}

	var best_prisoner: Pawn = null
	var best_score: float = -999.0
	for prisoner: Pawn in PrisonerManager.prisoners:
		if prisoner.dead:
			continue
		var resistance: float = prisoner.get_meta("resistance", 1.0) as float
		var progress: float = prisoner.get_meta("recruit_progress", 0.0) as float
		var diff: float = prisoner.get_meta("recruit_difficulty", 0.5) as float
		var score: float = progress / maxf(diff, 0.01) * 10.0
		if resistance <= 0.0:
			score += 5.0
		if score > best_score:
			best_score = score
			best_prisoner = prisoner

	if best_prisoner == null:
		return {}

	var job := Job.new()
	job.job_def = "Warden"
	job.meta_data = {"prisoner_id": best_prisoner.id}
	return {"job": job}


func get_prisoner_count() -> int:
	if not PrisonerManager:
		return 0
	return PrisonerManager.prisoners.size()


func get_best_warden() -> Dictionary:
	if not PawnManager:
		return {}
	var best: Pawn = null
	var best_skill: int = -1
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed or p.drafted:
			continue
		if not p.is_capable_of("Warden"):
			continue
		var lvl: int = p.get_skill_level("Social")
		if lvl > best_skill:
			best_skill = lvl
			best = p
	if best == null:
		return {}
	return {"name": best.pawn_name, "social": best_skill}


func needs_wardens() -> bool:
	return get_prisoner_count() > 0


func get_capable_warden_count() -> int:
	if not PawnManager:
		return 0
	var cnt: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead and not p.downed and not p.drafted and p.is_capable_of("Warden"):
			cnt += 1
	return cnt


func get_warden_to_prisoner_ratio() -> float:
	var prisoners: int = get_prisoner_count()
	if prisoners == 0:
		return 0.0
	return float(get_capable_warden_count()) / float(prisoners)


func is_understaffed() -> bool:
	return get_warden_to_prisoner_ratio() < 1.0 and get_prisoner_count() > 0

func get_avg_social_skill() -> float:
	if not PawnManager:
		return 0.0
	var total: float = 0.0
	var cnt: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead and not p.downed and p.is_capable_of("Warden"):
			total += float(p.get_skill_level("Social"))
			cnt += 1
	if cnt <= 0:
		return 0.0
	return snappedf(total / float(cnt), 0.1)

func get_warden_efficiency() -> String:
	var ratio: float = get_warden_to_prisoner_ratio()
	if ratio >= 2.0:
		return "Excellent"
	elif ratio >= 1.0:
		return "Good"
	elif ratio > 0.0:
		return "Strained"
	return "None"

func get_recruitment_potential() -> float:
	var avg_social := get_avg_social_skill()
	var ratio := get_warden_to_prisoner_ratio()
	if ratio <= 0.0 or avg_social <= 0.0:
		return 0.0
	return snapped(minf(avg_social * ratio * 10.0, 100.0), 0.1)

func get_security_posture() -> String:
	var ratio := get_warden_to_prisoner_ratio()
	if ratio >= 2.0:
		return "Secure"
	elif ratio >= 1.0:
		return "Adequate"
	elif ratio > 0.0:
		return "Vulnerable"
	return "Unguarded"

func get_warden_burnout_risk() -> float:
	var prisoners := get_prisoner_count()
	var wardens := get_capable_warden_count()
	if wardens <= 0:
		return 100.0 if prisoners > 0 else 0.0
	return snapped(float(prisoners) / float(wardens) * 25.0, 0.1)

func get_warden_summary() -> Dictionary:
	return {
		"prisoners": get_prisoner_count(),
		"wardens": get_capable_warden_count(),
		"ratio": snappedf(get_warden_to_prisoner_ratio(), 0.01),
		"best_warden": get_best_warden(),
		"needs_wardens": needs_wardens(),
		"understaffed": is_understaffed(),
		"avg_social": get_avg_social_skill(),
		"efficiency": get_warden_efficiency(),
		"recruitment_potential": get_recruitment_potential(),
		"security_posture": get_security_posture(),
		"burnout_risk_pct": get_warden_burnout_risk(),
		"warden_ecosystem_health": get_warden_ecosystem_health(),
		"custody_governance": get_custody_governance(),
		"prison_maturity_index": get_prison_maturity_index(),
	}

func get_warden_ecosystem_health() -> float:
	var potential := get_recruitment_potential()
	var posture := get_security_posture()
	var p_val: float = 90.0 if posture == "Secure" else (60.0 if posture == "Adequate" else (30.0 if posture == "Stretched" else 10.0))
	var burnout_inv := maxf(100.0 - get_warden_burnout_risk(), 0.0)
	return snapped((minf(potential, 100.0) + p_val + burnout_inv) / 3.0, 0.1)

func get_custody_governance() -> String:
	var eco := get_warden_ecosystem_health()
	var mat := get_prison_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_prisoner_count() > 0:
		return "Nascent"
	return "Dormant"

func get_prison_maturity_index() -> float:
	var ratio := minf(get_warden_to_prisoner_ratio() * 50.0, 100.0)
	var social := minf(get_avg_social_skill() * 10.0, 100.0)
	var eff := get_warden_efficiency()
	var e_val: float = 90.0 if eff == "Excellent" else (65.0 if eff == "Good" else (35.0 if eff == "Adequate" else 15.0))
	return snapped((ratio + social + e_val) / 3.0, 0.1)
