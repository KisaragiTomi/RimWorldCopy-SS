extends Node

## Manages prisoners - downed enemies can be captured and recruited.
## Registered as autoload "PrisonerManager".

signal prisoner_captured(pawn: Pawn)
signal prisoner_recruited(pawn: Pawn)
signal prisoner_escaped(pawn: Pawn)

var prisoners: Array[Pawn] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = randi()
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func capture_pawn(p: Pawn) -> void:
	if p.dead:
		return
	p.set_meta("prisoner", true)
	p.set_meta("faction", "prisoner")
	p.set_meta("recruit_difficulty", _calc_recruit_difficulty(p))
	p.set_meta("recruit_progress", 0.0)
	p.set_meta("resistance", 1.0)
	prisoners.append(p)
	total_captured += 1
	prisoner_captured.emit(p)
	if ColonyLog:
		ColonyLog.add_entry("Prisoner", p.pawn_name + " has been captured.", "info")


func attempt_recruit(p: Pawn, warden: Pawn) -> bool:
	if not p.has_meta("prisoner") or p.dead:
		return false

	var resistance: float = p.get_meta("resistance", 1.0) as float
	var social_skill: int = warden.get_skill_level("Social")
	var reduction: float = 0.05 + social_skill * 0.01
	resistance = maxf(0.0, resistance - reduction)
	p.set_meta("resistance", resistance)

	warden.gain_xp("Social", 25.0)

	if resistance <= 0.0:
		var progress: float = p.get_meta("recruit_progress", 0.0) as float
		var diff: float = p.get_meta("recruit_difficulty", 0.5) as float
		progress += 0.15 + social_skill * 0.02
		p.set_meta("recruit_progress", progress)

		if ColonyLog:
			ColonyLog.add_entry("Prisoner", "%s chatted with %s (progress %.0f%%)." % [
				warden.pawn_name, p.pawn_name, (progress / diff) * 100.0
			], "info")

		if progress >= diff:
			_recruit_prisoner(p)
			return true
	else:
		if ColonyLog:
			ColonyLog.add_entry("Prisoner", "%s reduced %s's resistance (%.0f%% left)." % [
				warden.pawn_name, p.pawn_name, resistance * 100.0
			], "info")
	return false


func _recruit_prisoner(p: Pawn) -> void:
	p.remove_meta("prisoner")
	p.set_meta("faction", "colony")
	p.remove_meta("recruit_difficulty")
	p.remove_meta("recruit_progress")
	p.remove_meta("resistance")
	p.downed = false
	prisoners.erase(p)

	if PawnManager:
		if not PawnManager.pawns.has(p):
			PawnManager.add_pawn(p)

	total_recruited += 1
	prisoner_recruited.emit(p)
	if ColonyLog:
		ColonyLog.add_entry("Prisoner", p.pawn_name + " has been recruited to the colony!", "positive")


func _on_rare_tick(_tick: int) -> void:
	var guard_nearby: bool = _any_guard_nearby()
	var i := prisoners.size() - 1
	while i >= 0:
		var p: Pawn = prisoners[i]
		if p.dead:
			prisoners.remove_at(i)
			i -= 1
			continue

		_tick_prisoner_needs(p)

		var escape_chance: float = 0.005
		if guard_nearby:
			escape_chance *= 0.2
		if p.downed:
			escape_chance = 0.0

		if escape_chance > 0.0 and _rng.randf() < escape_chance:
			_prisoner_escapes(p)
			prisoners.remove_at(i)
			i -= 1
			continue

		if p.health:
			p.health.tick_health()
		i -= 1


func _tick_prisoner_needs(p: Pawn) -> void:
	p.set_need("Food", maxf(0.0, p.get_need("Food") - 0.0003))
	p.set_need("Rest", maxf(0.0, p.get_need("Rest") - 0.0001))
	p.set_need("Joy", maxf(0.0, p.get_need("Joy") - 0.0002))

	if p.get_need("Food") <= 0.05 and p.thought_tracker:
		p.thought_tracker.add_thought("Starving")


func _any_guard_nearby() -> bool:
	if not PawnManager:
		return false
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed:
			continue
		if p.has_meta("faction") and p.get_meta("faction") != "colony":
			continue
		for prisoner: Pawn in prisoners:
			var dist: int = absi(p.grid_pos.x - prisoner.grid_pos.x) + absi(p.grid_pos.y - prisoner.grid_pos.y)
			if dist <= 10:
				return true
	return false


var total_captured: int = 0
var total_recruited: int = 0
var total_escaped: int = 0


func _prisoner_escapes(p: Pawn) -> void:
	p.remove_meta("prisoner")
	p.set_meta("faction", "escaped")
	total_escaped += 1
	prisoner_escaped.emit(p)
	if ColonyLog:
		ColonyLog.add_entry("Prisoner", p.pawn_name + " has escaped!", "danger")
	if PawnManager:
		for col: Pawn in PawnManager.pawns:
			if col.dead or (col.has_meta("faction") and col.get_meta("faction") != "colony"):
				continue
			if col.thought_tracker:
				col.thought_tracker.add_thought("PrisonerEscaped")


func _calc_recruit_difficulty(p: Pawn) -> float:
	var base: float = 0.5
	var social: int = p.get_skill_level("Social")
	base += social * 0.03
	if p.get_skill_level("Melee") > 10 or p.get_skill_level("Shooting") > 10:
		base += 0.2
	return clampf(base, 0.3, 2.0)


func get_closest_to_recruit() -> Pawn:
	var best: Pawn = null
	var best_ratio: float = 0.0
	for p: Pawn in prisoners:
		if p.dead:
			continue
		var resistance: float = p.get_meta("resistance", 1.0) as float
		var progress: float = p.get_meta("recruit_progress", 0.0) as float
		var diff: float = p.get_meta("recruit_difficulty", 0.5) as float
		var ratio: float = progress / maxf(diff, 0.01)
		if resistance <= 0.0:
			ratio += 1.0
		if ratio > best_ratio:
			best_ratio = ratio
			best = p
	return best


func get_average_resistance() -> float:
	if prisoners.is_empty():
		return 0.0
	var total: float = 0.0
	for p: Pawn in prisoners:
		total += p.get_meta("resistance", 1.0) as float
	return total / float(prisoners.size())


func get_recruit_success_rate() -> float:
	if total_captured == 0:
		return 0.0
	return float(total_recruited) / float(total_captured)


func get_starving_prisoners() -> Array[Pawn]:
	var result: Array[Pawn] = []
	for p: Pawn in prisoners:
		if p.get_need("Food") <= 0.1:
			result.append(p)
	return result


func get_summary() -> Dictionary:
	var result: Array[Dictionary] = []
	for p: Pawn in prisoners:
		var diff: float = p.get_meta("recruit_difficulty", 0.5) as float
		var prog: float = p.get_meta("recruit_progress", 0.0) as float
		result.append({
			"name": p.pawn_name,
			"resistance": snappedf(p.get_meta("resistance", 1.0) as float, 0.01),
			"recruit_progress": snappedf(prog, 0.01),
			"recruit_pct": snappedf(prog / maxf(diff, 0.01) * 100.0, 0.1),
			"downed": p.downed,
		})
	var downed_count: int = 0
	for pi: Pawn in prisoners:
		if pi.downed:
			downed_count += 1
	var low_resist: int = 0
	for pi2: Pawn in prisoners:
		if (pi2.get_meta("resistance", 1.0) as float) < 0.3:
			low_resist += 1
	return {
		"count": prisoners.size(),
		"prisoners": result,
		"total_captured": total_captured,
		"total_recruited": total_recruited,
		"total_escaped": total_escaped,
		"avg_resistance": snappedf(get_average_resistance(), 0.01),
		"recruit_rate": snappedf(get_recruit_success_rate(), 0.01),
		"starving": get_starving_prisoners().size(),
		"downed_prisoners": downed_count,
		"retention_rate": snappedf(1.0 - float(total_escaped) / maxf(1.0, float(total_captured)), 0.01),
		"low_resistance_count": low_resist,
		"escape_rate": snappedf(float(total_escaped) / maxf(1.0, float(total_captured)), 0.01),
		"recruit_per_capture": snappedf(float(total_recruited) / maxf(1.0, float(total_captured)), 0.01),
		"conversion_pipeline": get_conversion_pipeline(),
		"security_rating": get_security_rating(),
		"warden_workload": get_warden_workload(),
		"detention_efficiency": get_detention_efficiency(),
		"recruitment_velocity": get_recruitment_velocity(),
		"prison_capacity_health": get_prison_capacity_health(),
	}

func get_conversion_pipeline() -> float:
	if prisoners.is_empty():
		return 0.0
	var near_recruit := 0
	for p: Pawn in prisoners:
		var resist: float = p.get_meta("resistance", 1.0) as float
		if resist < 0.3:
			near_recruit += 1
	return snapped(float(near_recruit) / float(prisoners.size()) * 100.0, 0.1)

func get_security_rating() -> String:
	var escape_rate := float(total_escaped) / maxf(1.0, float(total_captured))
	var starving := get_starving_prisoners().size()
	if escape_rate <= 0.05 and starving == 0:
		return "Maximum"
	elif escape_rate <= 0.15:
		return "Adequate"
	elif escape_rate <= 0.3:
		return "Compromised"
	return "Critical"

func get_warden_workload() -> float:
	return snapped(float(prisoners.size()) * 2.5, 0.1)

func get_detention_efficiency() -> float:
	var retention := 1.0 - float(total_escaped) / maxf(1.0, float(total_captured))
	var pipeline := get_conversion_pipeline()
	return snapped(retention * 50.0 + pipeline * 0.5, 0.1)

func get_recruitment_velocity() -> String:
	if total_captured <= 0:
		return "N/A"
	var rate := float(total_recruited) / float(total_captured)
	if rate >= 0.5:
		return "Rapid"
	elif rate >= 0.2:
		return "Steady"
	elif rate > 0.0:
		return "Slow"
	return "Stalled"

func get_prison_capacity_health() -> String:
	var count := prisoners.size()
	var starving := get_starving_prisoners().size()
	if count == 0:
		return "Empty"
	if starving == 0 and count <= 5:
		return "Healthy"
	elif starving <= 1:
		return "Strained"
	return "Overcrowded"
