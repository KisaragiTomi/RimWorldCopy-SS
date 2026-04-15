extends Node

const SOCIAL_MEMORIES: Dictionary = {
	"RebuffedMyRomance": {"opinion": -15, "duration_days": 20, "stack_limit": 3},
	"InsultedMe": {"opinion": -10, "duration_days": 15, "stack_limit": 5},
	"HadNiceChat": {"opinion": 10, "duration_days": 10, "stack_limit": 3},
	"HadDeepTalk": {"opinion": 15, "duration_days": 20, "stack_limit": 2},
	"GotGift": {"opinion": 12, "duration_days": 15, "stack_limit": 3},
	"SoldPrisoner": {"opinion": -20, "duration_days": 30, "stack_limit": 5},
	"SocialFight": {"opinion": -25, "duration_days": 25, "stack_limit": 3},
	"SpurnedAdvance": {"opinion": -12, "duration_days": 15, "stack_limit": 3},
	"SharedMeal": {"opinion": 5, "duration_days": 5, "stack_limit": 5},
	"HelpedWhenDown": {"opinion": 20, "duration_days": 30, "stack_limit": 2},
	"GaveComfort": {"opinion": 8, "duration_days": 10, "stack_limit": 3},
	"CaughtStealing": {"opinion": -30, "duration_days": 40, "stack_limit": 2},
}

var _memories: Dictionary = {}


func add_memory(pawn_id: int, target_id: int, memory_type: String) -> Dictionary:
	if not SOCIAL_MEMORIES.has(memory_type):
		return {"success": false}
	var data: Dictionary = SOCIAL_MEMORIES[memory_type]
	var key: String = str(pawn_id) + "_" + str(target_id)
	if not _memories.has(key):
		_memories[key] = []
	var existing_count: int = 0
	for m in _memories[key]:
		var md: Dictionary = m if m is Dictionary else {}
		if String(md.get("type", "")) == memory_type:
			existing_count += 1
	if existing_count >= int(data.get("stack_limit", 99)):
		return {"success": false, "reason": "Stack limit reached"}
	var dur_ticks: int = int(data.get("duration_days", 1)) * 60000
	_memories[key].append({
		"type": memory_type,
		"opinion": data.opinion,
		"expires_tick": (TickManager.current_tick if TickManager else 0) + dur_ticks,
	})
	return {"success": true, "opinion_change": data.opinion}


func get_opinion_from_memories(pawn_id: int, target_id: int) -> float:
	var key: String = str(pawn_id) + "_" + str(target_id)
	var mems: Array = _memories.get(key, [])
	var current: int = TickManager.current_tick if TickManager else 0
	var total: float = 0.0
	for m in mems:
		var md: Dictionary = m if m is Dictionary else {}
		if current <= int(md.get("expires_tick", 0)):
			total += float(md.get("opinion", 0))
	return total


func get_positive_memories() -> Array[String]:
	var result: Array[String] = []
	for m_type: String in SOCIAL_MEMORIES:
		if int(SOCIAL_MEMORIES[m_type].get("opinion", 0)) > 0:
			result.append(m_type)
	return result


func get_negative_memories() -> Array[String]:
	var result: Array[String] = []
	for m_type: String in SOCIAL_MEMORIES:
		if int(SOCIAL_MEMORIES[m_type].get("opinion", 0)) < 0:
			result.append(m_type)
	return result


func get_active_memory_count() -> int:
	var count: int = 0
	var current: int = TickManager.current_tick if TickManager else 0
	for key: String in _memories:
		for m in _memories[key]:
			var md: Dictionary = m if m is Dictionary else {}
			if current <= int(md.get("expires_tick", 0)):
				count += 1
	return count


func get_most_common_memory() -> String:
	var counts: Dictionary = {}
	for key: String in _memories:
		for m in _memories[key]:
			var md: Dictionary = m if m is Dictionary else {}
			var mid: String = str(md.get("id", ""))
			counts[mid] = counts.get(mid, 0) + 1
	var best: String = ""
	var best_n: int = 0
	for mid: String in counts:
		if counts[mid] > best_n:
			best_n = counts[mid]
			best = mid
	return best


func get_avg_memories_per_pair() -> float:
	if _memories.is_empty():
		return 0.0
	return snappedf(float(get_active_memory_count()) / float(_memories.size()), 0.1)


func get_positive_ratio() -> float:
	var total: int = get_positive_memories().size() + get_negative_memories().size()
	if total == 0:
		return 0.0
	return snappedf(float(get_positive_memories().size()) / float(total) * 100.0, 0.1)


func get_unique_pair_count() -> int:
	return _memories.size()


func get_avg_opinion_impact() -> float:
	if SOCIAL_MEMORIES.is_empty():
		return 0.0
	var total: float = 0.0
	for mt: String in SOCIAL_MEMORIES:
		total += float(SOCIAL_MEMORIES[mt].get("opinion", 0))
	return snappedf(total / float(SOCIAL_MEMORIES.size()), 0.1)


func get_strongest_memory_type() -> String:
	var best: String = ""
	var best_val: float = 0.0
	for mt: String in SOCIAL_MEMORIES:
		var v: float = absf(float(SOCIAL_MEMORIES[mt].get("opinion", 0)))
		if v > best_val:
			best_val = v
			best = mt
	return best


func get_summary() -> Dictionary:
	return {
		"memory_types": SOCIAL_MEMORIES.size(),
		"active_pairs": _memories.size(),
		"active_memories": get_active_memory_count(),
		"positive_types": get_positive_memories().size(),
		"negative_types": get_negative_memories().size(),
		"most_common": get_most_common_memory(),
		"avg_per_pair": get_avg_memories_per_pair(),
		"positive_ratio_pct": get_positive_ratio(),
		"unique_pairs": get_unique_pair_count(),
		"avg_opinion_impact": get_avg_opinion_impact(),
		"strongest_type": get_strongest_memory_type(),
		"social_ecosystem_health": get_social_ecosystem_health(),
		"relational_depth_index": get_relational_depth_index(),
		"community_cohesion_score": get_community_cohesion_score(),
	}

func get_social_ecosystem_health() -> float:
	var positive := get_positive_ratio()
	var impact := get_avg_opinion_impact()
	var pairs := get_unique_pair_count()
	return snapped((positive + minf(absf(impact) * 10.0, 100.0) + minf(float(pairs) * 15.0, 100.0)) / 3.0, 0.1)

func get_relational_depth_index() -> float:
	var avg := get_avg_memories_per_pair()
	var types := SOCIAL_MEMORIES.size()
	var active := get_active_memory_count()
	if types <= 0:
		return 0.0
	return snapped((avg * 20.0 + float(active) / float(types) * 100.0) / 2.0, 0.1)

func get_community_cohesion_score() -> String:
	var health := get_social_ecosystem_health()
	var depth := get_relational_depth_index()
	if health >= 60.0 and depth >= 40.0:
		return "Cohesive"
	elif health >= 30.0 or depth >= 20.0:
		return "Developing"
	return "Fragmented"
