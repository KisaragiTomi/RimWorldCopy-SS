extends Node

## Manages romantic relationships: dating, marriage, breakups, mood effects.
## Registered as autoload "RelationshipManager".

enum RelType { NONE, DATING, ENGAGED, MARRIED, EX }

var _relations: Dictionary = {}  # "pid1_pid2" -> {type, start_tick, affection}
var _rng := RandomNumberGenerator.new()
var _total_marriages: int = 0
var _total_breakups: int = 0
var _total_proposals: int = 0
var _romance_history: Array[Dictionary] = []


func _ready() -> void:
	_rng.seed = 53
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func _key(a: int, b: int) -> String:
	var lo := mini(a, b)
	var hi := maxi(a, b)
	return str(lo) + "_" + str(hi)


func get_relation(a_id: int, b_id: int) -> int:
	var key := _key(a_id, b_id)
	if not _relations.has(key):
		return RelType.NONE
	return int(_relations[key].get("type", RelType.NONE))


func start_dating(a: Pawn, b: Pawn) -> void:
	var key := _key(a.id, b.id)
	_relations[key] = {
		"type": RelType.DATING,
		"start_tick": TickManager.current_tick if TickManager else 0,
		"affection": 50.0,
		"pawn_a": a.id,
		"pawn_b": b.id,
	}
	_add_thought(a, "NewLover")
	_add_thought(b, "NewLover")
	_record_event("dating", a.id, b.id)
	if ColonyLog:
		ColonyLog.add_entry("Social", a.pawn_name + " and " + b.pawn_name + " are now dating.", "positive")


func propose(a: Pawn, b: Pawn) -> bool:
	var key := _key(a.id, b.id)
	if not _relations.has(key) or _relations[key].type != RelType.DATING:
		return false
	if _relations[key].affection < 70.0:
		return false
	_relations[key].type = RelType.ENGAGED
	_total_proposals += 1
	_add_thought(a, "GotEngaged")
	_add_thought(b, "GotEngaged")
	_record_event("engaged", a.id, b.id)
	if ColonyLog:
		ColonyLog.add_entry("Social", a.pawn_name + " proposed to " + b.pawn_name + "!", "positive")
	return true


func marry(a: Pawn, b: Pawn) -> bool:
	var key := _key(a.id, b.id)
	if not _relations.has(key) or _relations[key].type != RelType.ENGAGED:
		return false
	_relations[key].type = RelType.MARRIED
	_total_marriages += 1
	_add_thought(a, "GotMarried")
	_add_thought(b, "GotMarried")
	_record_event("married", a.id, b.id)
	if ColonyLog:
		ColonyLog.add_entry("Social", a.pawn_name + " and " + b.pawn_name + " got married!", "positive")
	return true


func break_up(a_id: int, b_id: int) -> void:
	var key := _key(a_id, b_id)
	if not _relations.has(key):
		return
	var old_type: int = _relations[key].type
	_relations[key].type = RelType.EX
	_total_breakups += 1

	var a := _find_pawn(a_id)
	var b := _find_pawn(b_id)
	if a:
		_add_thought(a, "BrokeUp")
	if b:
		_add_thought(b, "BrokeUp")

	var label := "broke up" if old_type == RelType.DATING else "divorced"
	if ColonyLog and a and b:
		ColonyLog.add_entry("Social", a.pawn_name + " and " + b.pawn_name + " " + label + ".", "warning")


func _on_rare_tick(_tick: int) -> void:
	_tick_affection()
	_try_romance()


func _tick_affection() -> void:
	for key: String in _relations:
		var rel: Dictionary = _relations[key]
		if rel.type == RelType.EX or rel.type == RelType.NONE:
			continue
		var a := _find_pawn(rel.pawn_a)
		var b := _find_pawn(rel.pawn_b)
		if a == null or b == null or a.dead or b.dead:
			if rel.type != RelType.EX:
				rel.type = RelType.EX
			continue

		var dist: float = a.grid_pos.distance_to(b.grid_pos)
		if dist < 5.0:
			rel.affection = minf(100.0, rel.get("affection", 50.0) + 0.3)
		else:
			rel.affection = maxf(0.0, rel.get("affection", 50.0) - 0.05)

		if rel.type == RelType.DATING and rel.affection >= 80.0 and _rng.randf() < 0.02:
			propose(a, b)
		elif rel.type == RelType.ENGAGED and rel.affection >= 85.0 and _rng.randf() < 0.03:
			marry(a, b)

		if rel.affection <= 10.0 and _rng.randf() < 0.05:
			break_up(rel.pawn_a, rel.pawn_b)


func _try_romance() -> void:
	if not PawnManager:
		return
	if _rng.randf() > 0.01:
		return

	var eligible: Array[Pawn] = []
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed or p.is_in_mental_break():
			continue
		if not _has_partner(p.id):
			eligible.append(p)

	if eligible.size() < 2:
		return

	var a: Pawn = eligible[_rng.randi_range(0, eligible.size() - 1)]
	var b: Pawn = a
	for _attempt: int in range(5):
		b = eligible[_rng.randi_range(0, eligible.size() - 1)]
		if b.id != a.id:
			break
	if a.id == b.id:
		return

	if a.grid_pos.distance_to(b.grid_pos) < 8.0:
		var social_a: int = a.skills.get("Social", {}).get("level", 0) if a.skills.has("Social") else 0
		var chance: float = 0.15 + social_a * 0.02
		if _rng.randf() < chance:
			start_dating(a, b)


func _has_partner(pid: int) -> bool:
	for key: String in _relations:
		var rel: Dictionary = _relations[key]
		if rel.type == RelType.NONE or rel.type == RelType.EX:
			continue
		if rel.pawn_a == pid or rel.pawn_b == pid:
			return true
	return false


func _find_pawn(pid: int) -> Pawn:
	if not PawnManager:
		return null
	for p: Pawn in PawnManager.pawns:
		if p.id == pid:
			return p
	return null


func _add_thought(pawn: Pawn, thought_id: String) -> void:
	if pawn and pawn.thought_tracker:
		pawn.thought_tracker.add_thought(thought_id)


func get_partner(pid: int) -> int:
	for key: String in _relations:
		var rel: Dictionary = _relations[key]
		if rel.type == RelType.NONE or rel.type == RelType.EX:
			continue
		if rel.pawn_a == pid:
			return int(rel.pawn_b)
		if rel.pawn_b == pid:
			return int(rel.pawn_a)
	return -1


func _record_event(action: String, a_id: int, b_id: int) -> void:
	_romance_history.append({
		"action": action, "a": a_id, "b": b_id,
		"tick": TickManager.current_tick if TickManager else 0,
	})
	if _romance_history.size() > 50:
		_romance_history = _romance_history.slice(_romance_history.size() - 50)


func get_affection(a_id: int, b_id: int) -> float:
	var key := _key(a_id, b_id)
	if not _relations.has(key):
		return 0.0
	return _relations[key].get("affection", 0.0)


func get_relation_age(a_id: int, b_id: int) -> int:
	var key := _key(a_id, b_id)
	if not _relations.has(key):
		return 0
	var start: int = _relations[key].get("start_tick", 0)
	var now: int = TickManager.current_tick if TickManager else 0
	return now - start


func get_all_couples() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key: String in _relations:
		var rel: Dictionary = _relations[key]
		if rel.type == RelType.DATING or rel.type == RelType.ENGAGED or rel.type == RelType.MARRIED:
			var tname: String = ["None", "Dating", "Engaged", "Married", "Ex"][rel.type]
			result.append({
				"a": rel.pawn_a, "b": rel.pawn_b,
				"type": tname, "affection": rel.get("affection", 0.0),
			})
	return result


func get_romance_history(count: int = 10) -> Array[Dictionary]:
	var start: int = maxi(0, _romance_history.size() - count)
	return _romance_history.slice(start) as Array[Dictionary]


func get_avg_affection() -> float:
	var total: float = 0.0
	var count: int = 0
	for key: String in _relations:
		var rel: Dictionary = _relations[key]
		if rel.type != RelType.NONE and rel.type != RelType.EX:
			total += rel.get("affection", 0.0)
			count += 1
	if count == 0:
		return 0.0
	return snappedf(total / float(count), 0.1)


func get_longest_relationship() -> Dictionary:
	var longest_key: String = ""
	var longest_age: int = 0
	var now: int = TickManager.current_tick if TickManager else 0
	for key: String in _relations:
		var rel: Dictionary = _relations[key]
		if rel.type == RelType.NONE or rel.type == RelType.EX:
			continue
		var age: int = now - rel.get("start_tick", 0)
		if age > longest_age:
			longest_age = age
			longest_key = key
	if longest_key.is_empty():
		return {}
	var rel: Dictionary = _relations[longest_key]
	return {"a": rel.pawn_a, "b": rel.pawn_b, "age_ticks": longest_age}


func get_marriage_rate() -> float:
	var total_rels: int = _total_marriages + _total_proposals + _total_breakups
	if total_rels == 0:
		return 0.0
	return snappedf(float(_total_marriages) / float(total_rels), 0.01)


func get_romance_health() -> String:
	var avg: float = get_avg_affection()
	if avg >= 80.0:
		return "Thriving"
	elif avg >= 50.0:
		return "Healthy"
	elif avg > 0.0:
		return "Struggling"
	return "None"

func get_single_ratio() -> float:
	if not PawnManager:
		return 0.0
	var alive: int = 0
	var in_rel: int = 0
	for p: Pawn in PawnManager.pawns:
		if not p.dead:
			alive += 1
	for key: String in _relations:
		var rel: Dictionary = _relations[key]
		if rel.type == RelType.DATING or rel.type == RelType.ENGAGED or rel.type == RelType.MARRIED:
			in_rel += 2
	if alive <= 0:
		return 0.0
	return snappedf(float(maxi(0, alive - in_rel)) / float(alive) * 100.0, 0.1)

func get_stability_score() -> float:
	if _total_marriages + _total_breakups <= 0:
		return 0.0
	return snappedf(float(_total_marriages) / float(_total_marriages + _total_breakups) * 100.0, 0.1)

func get_social_cohesion() -> String:
	var avg := get_avg_affection()
	var single := get_single_ratio()
	if avg >= 70.0 and single < 30.0:
		return "Tight-Knit"
	elif avg >= 40.0:
		return "Connected"
	elif single > 70.0:
		return "Isolated"
	return "Fragmented"

func get_heartbreak_risk() -> float:
	if _total_proposals <= 0:
		return 0.0
	return snapped(float(_total_breakups) / float(_total_proposals) * 100.0, 0.1)

func get_partnership_health() -> String:
	var stability := get_stability_score()
	var health := get_romance_health()
	if stability >= 80.0 and health == "Thriving":
		return "Flourishing"
	elif stability >= 50.0:
		return "Stable"
	elif _total_breakups > _total_marriages:
		return "Troubled"
	return "Developing"

func get_summary() -> Dictionary:
	var active: int = 0
	var by_type: Dictionary = {}
	for key: String in _relations:
		var rel: Dictionary = _relations[key]
		var t: int = rel.type
		if t != RelType.NONE:
			active += 1
			var tname: String = ["None", "Dating", "Engaged", "Married", "Ex"][t]
			by_type[tname] = by_type.get(tname, 0) + 1
	var breakup_ratio: float = 0.0
	if _total_proposals > 0:
		breakup_ratio = float(_total_breakups) / float(_total_proposals)
	return {
		"active_relations": active,
		"by_type": by_type,
		"total_marriages": _total_marriages,
		"total_proposals": _total_proposals,
		"total_breakups": _total_breakups,
		"couples": get_all_couples(),
		"avg_affection": get_avg_affection(),
		"marriage_rate": get_marriage_rate(),
		"breakup_ratio": snappedf(breakup_ratio, 0.01),
		"relation_types": by_type.size(),
		"romance_health": get_romance_health(),
		"single_ratio_pct": get_single_ratio(),
		"stability_score": get_stability_score(),
		"social_cohesion": get_social_cohesion(),
		"heartbreak_risk_pct": get_heartbreak_risk(),
		"partnership_health": get_partnership_health(),
		"community_bond_strength": get_community_bond_strength(),
		"social_fabric_integrity": get_social_fabric_integrity(),
		"relationship_ecosystem_health": get_relationship_ecosystem_health(),
	}

func get_community_bond_strength() -> float:
	var avg := get_avg_affection()
	var married := float(_total_marriages)
	return snapped(avg * maxf(married, 1.0) / 10.0, 0.1)

func get_social_fabric_integrity() -> String:
	var cohesion := get_social_cohesion()
	var breakup_rate := float(_total_breakups) / maxf(float(_total_proposals), 1.0)
	if cohesion in ["Strong", "Excellent"] and breakup_rate < 0.2:
		return "Robust"
	elif cohesion not in ["Weak", "Fractured"]:
		return "Stable"
	return "Fraying"

func get_relationship_ecosystem_health() -> String:
	var health := get_partnership_health()
	var single := get_single_ratio()
	if health in ["Thriving", "Healthy"] and single < 50.0:
		return "Flourishing"
	elif health not in ["Poor", "Critical"]:
		return "Balanced"
	return "Declining"
