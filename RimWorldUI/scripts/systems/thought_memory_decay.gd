extends Node

var _memories: Dictionary = {}

const DECAY_RATES: Dictionary = {
	"Instant": {"half_life_days": 1, "min_strength": 0.0},
	"Short": {"half_life_days": 3, "min_strength": 0.0},
	"Medium": {"half_life_days": 7, "min_strength": 0.1},
	"Long": {"half_life_days": 15, "min_strength": 0.2},
	"Permanent": {"half_life_days": 0, "min_strength": 1.0}
}

const THOUGHT_DECAY_MAP: Dictionary = {
	"AteWithoutTable": "Short",
	"SleptOnGround": "Short",
	"AteRawFood": "Short",
	"WitnessedDeath": "Long",
	"ColonistDied": "Long",
	"BondedAnimalDied": "Long",
	"GotMarried": "Long",
	"Catharsis": "Medium",
	"InspiredCreativity": "Medium",
	"SoldPrisoner": "Medium",
	"AteHumanMeat": "Long",
	"Imprisoned": "Long",
	"RebuffedMe": "Medium",
	"InsultedMe": "Medium",
	"GaveMeFood": "Short",
	"NiceRoom": "Short",
	"PainShock": "Medium",
	"Hypothermia": "Medium",
	"Heatstroke": "Medium",
	"KilledHumanlike": "Long"
}

func add_memory(pawn_id: int, thought: String, mood_effect: float) -> bool:
	if not _memories.has(pawn_id):
		_memories[pawn_id] = []
	var decay_type: String = THOUGHT_DECAY_MAP.get(thought, "Medium")
	_memories[pawn_id].append({
		"thought": thought,
		"mood_base": mood_effect,
		"strength": 1.0,
		"decay_type": decay_type,
		"age_days": 0
	})
	return true

func advance_day() -> void:
	for pawn_id: int in _memories:
		var to_remove: Array = []
		for i: int in range(_memories[pawn_id].size()):
			var mem: Dictionary = _memories[pawn_id][i]
			mem["age_days"] += 1
			var decay_info: Dictionary = DECAY_RATES.get(mem["decay_type"], DECAY_RATES["Medium"])
			if decay_info["half_life_days"] > 0:
				var decay: float = pow(0.5, 1.0 / decay_info["half_life_days"])
				mem["strength"] *= decay
				if mem["strength"] < decay_info["min_strength"]:
					mem["strength"] = decay_info["min_strength"]
				if mem["strength"] < 0.05:
					to_remove.append(i)
		to_remove.reverse()
		for idx: int in to_remove:
			_memories[pawn_id].remove_at(idx)

func get_mood_from_memories(pawn_id: int) -> float:
	var total: float = 0.0
	for mem: Dictionary in _memories.get(pawn_id, []):
		total += mem["mood_base"] * mem["strength"]
	return total

func get_memory_count(pawn_id: int) -> int:
	return _memories.get(pawn_id, []).size()

func get_total_memory_count() -> int:
	var total: int = 0
	for pid: int in _memories:
		total += _memories[pid].size()
	return total


func get_strongest_memory(pawn_id: int) -> Dictionary:
	var best: Dictionary = {}
	var best_effect: float = 0.0
	for mem: Dictionary in _memories.get(pawn_id, []):
		var effect: float = absf(float(mem.get("mood_base", 0.0)) * float(mem.get("strength", 0.0)))
		if effect > best_effect:
			best_effect = effect
			best = mem.duplicate()
	return best


func get_permanent_thoughts() -> Array[String]:
	var result: Array[String] = []
	for thought: String in THOUGHT_DECAY_MAP:
		if THOUGHT_DECAY_MAP[thought] == "Permanent":
			result.append(thought)
	return result


func get_avg_memories_per_pawn() -> float:
	if _memories.is_empty():
		return 0.0
	return float(get_total_memory_count()) / _memories.size()


func get_oldest_memory_age() -> int:
	var oldest: int = 0
	for pid: int in _memories:
		for mem: Dictionary in _memories[pid]:
			var age: int = int(mem.get("age_days", 0))
			if age > oldest:
				oldest = age
	return oldest


func get_positive_memory_ratio() -> float:
	var total: int = 0
	var positive: int = 0
	for pid: int in _memories:
		for mem: Dictionary in _memories[pid]:
			total += 1
			if float(mem.get("mood_base", 0.0)) > 0.0:
				positive += 1
	if total == 0:
		return 0.0
	return float(positive) / total


func get_long_term_memory_count() -> int:
	var count: int = 0
	for pid: int in _memories:
		for mem: Dictionary in _memories[pid]:
			if String(mem.get("decay_type", "")) == "Long" or String(mem.get("decay_type", "")) == "Permanent":
				count += 1
	return count


func get_avg_strength() -> float:
	var total: float = 0.0
	var n: int = 0
	for pid: int in _memories:
		for mem: Dictionary in _memories[pid]:
			total += float(mem.get("strength", 0.0))
			n += 1
	if n == 0:
		return 0.0
	return snappedf(total / float(n), 0.01)


func get_negative_memory_count() -> int:
	var count: int = 0
	for pid: int in _memories:
		for mem: Dictionary in _memories[pid]:
			if float(mem.get("mood_base", 0.0)) < 0.0:
				count += 1
	return count


func get_emotional_stability() -> String:
	var pos_ratio: float = get_positive_memory_ratio()
	if pos_ratio >= 0.7:
		return "Stable"
	elif pos_ratio >= 0.5:
		return "Balanced"
	elif pos_ratio >= 0.3:
		return "Fragile"
	return "Volatile"

func get_memory_burden_pct() -> float:
	var total: int = get_total_memory_count()
	var negative: int = get_negative_memory_count()
	if total == 0:
		return 0.0
	return snappedf(float(negative) / float(total) * 100.0, 0.1)

func get_resilience_rating() -> String:
	var long_term: int = get_long_term_memory_count()
	var total: int = get_total_memory_count()
	if total == 0:
		return "N/A"
	var lt_ratio: float = float(long_term) / float(total)
	if lt_ratio <= 0.2:
		return "Resilient"
	elif lt_ratio <= 0.4:
		return "Normal"
	elif lt_ratio <= 0.6:
		return "Burdened"
	return "Haunted"

func get_summary() -> Dictionary:
	return {
		"tracked_pawns": _memories.size(),
		"thought_types": THOUGHT_DECAY_MAP.size(),
		"decay_categories": DECAY_RATES.size(),
		"total_memories": get_total_memory_count(),
		"avg_per_pawn": snapped(get_avg_memories_per_pawn(), 0.1),
		"oldest_age_days": get_oldest_memory_age(),
		"positive_ratio": snapped(get_positive_memory_ratio(), 0.01),
		"long_term_count": get_long_term_memory_count(),
		"avg_strength": get_avg_strength(),
		"negative_count": get_negative_memory_count(),
		"emotional_stability": get_emotional_stability(),
		"memory_burden_pct": get_memory_burden_pct(),
		"resilience_rating": get_resilience_rating(),
		"emotional_maturity": get_emotional_maturity(),
		"memory_health": get_memory_health(),
		"psychological_load": get_psychological_load(),
		"memory_ecosystem_health": get_memory_ecosystem_health(),
		"emotional_governance": get_emotional_governance(),
		"psyche_maturity_index": get_psyche_maturity_index(),
	}

func get_emotional_maturity() -> String:
	var stability := get_emotional_stability()
	var resilience := get_resilience_rating()
	if stability in ["Stable", "Very Stable"] and resilience in ["Strong", "Resilient"]:
		return "Mature"
	elif stability in ["Stable"]:
		return "Developing"
	return "Immature"

func get_memory_health() -> float:
	var pos := get_positive_memory_ratio()
	var burden := get_memory_burden_pct()
	return snapped(maxf(pos * 100.0 - burden, 0.0), 0.1)

func get_psychological_load() -> String:
	var neg := get_negative_memory_count()
	var total := get_total_memory_count()
	if total <= 0:
		return "None"
	var pct := float(neg) / float(total) * 100.0
	if pct >= 60.0:
		return "Heavy"
	elif pct >= 30.0:
		return "Moderate"
	return "Light"

func get_memory_ecosystem_health() -> float:
	var maturity := get_emotional_maturity()
	var m_val: float = 90.0 if maturity in ["Seasoned", "Mature"] else (60.0 if maturity in ["Developing", "Growing"] else 30.0)
	var health := get_memory_health()
	var load := get_psychological_load()
	var l_val: float = 90.0 if load in ["Light", "None"] else (50.0 if load == "Moderate" else 20.0)
	return snapped((m_val + minf(health, 100.0) + l_val) / 3.0, 0.1)

func get_psyche_maturity_index() -> float:
	var stability := get_emotional_stability()
	var s_val: float = 90.0 if stability in ["Stable", "Resilient"] else (60.0 if stability in ["Moderate", "Balanced"] else 30.0)
	var resilience := get_resilience_rating()
	var r_val: float = 90.0 if resilience in ["Strong", "Exceptional"] else (60.0 if resilience in ["Moderate", "Average"] else 30.0)
	var burden := get_memory_burden_pct()
	var b_val: float = maxf(100.0 - burden, 0.0)
	return snapped((s_val + r_val + b_val) / 3.0, 0.1)

func get_emotional_governance() -> String:
	var ecosystem := get_memory_ecosystem_health()
	var maturity := get_psyche_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _memories.size() > 0:
		return "Nascent"
	return "Dormant"
