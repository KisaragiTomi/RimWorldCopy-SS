extends Node

var _thought_stacks: Dictionary = {}

const STACK_LIMITS: Dictionary = {
	"AteWithoutTable": {"max_stack": 1, "base_mood": -3},
	"AteRawFood": {"max_stack": 1, "base_mood": -7},
	"AteFineMeal": {"max_stack": 1, "base_mood": 5},
	"AteLavishMeal": {"max_stack": 1, "base_mood": 12},
	"SleptOnGround": {"max_stack": 1, "base_mood": -4},
	"SleptInCold": {"max_stack": 1, "base_mood": -3},
	"WitnessedDeath": {"max_stack": 5, "base_mood": -5, "stack_decay": 0.8},
	"ColonistDied": {"max_stack": 3, "base_mood": -8, "stack_decay": 0.9},
	"SoldPrisoner": {"max_stack": 5, "base_mood": -3, "stack_decay": 0.7},
	"KilledHumanlike": {"max_stack": 3, "base_mood": -3, "stack_decay": 0.8},
	"Catharsis": {"max_stack": 1, "base_mood": 40},
	"GotMarried": {"max_stack": 1, "base_mood": 25},
	"PartyCatharsis": {"max_stack": 1, "base_mood": 8},
	"NiceRoom": {"max_stack": 1, "base_mood": 5},
	"UglyEnvironment": {"max_stack": 1, "base_mood": -3},
	"Rebuffed": {"max_stack": 3, "base_mood": -5, "stack_decay": 0.75}
}

func add_thought(pawn_id: int, thought: String) -> Dictionary:
	if not STACK_LIMITS.has(thought):
		return {"error": "unknown_thought"}
	if not _thought_stacks.has(pawn_id):
		_thought_stacks[pawn_id] = {}
	var current: int = _thought_stacks[pawn_id].get(thought, 0)
	var limit: int = STACK_LIMITS[thought]["max_stack"]
	if current < limit:
		_thought_stacks[pawn_id][thought] = current + 1
	return {"thought": thought, "stacks": _thought_stacks[pawn_id][thought], "max": limit}

func get_total_mood(pawn_id: int) -> float:
	var total: float = 0.0
	for thought: String in _thought_stacks.get(pawn_id, {}):
		var stacks: int = _thought_stacks[pawn_id][thought]
		var info: Dictionary = STACK_LIMITS.get(thought, {})
		var base: float = info.get("base_mood", 0)
		var decay: float = info.get("stack_decay", 1.0)
		for i: int in range(stacks):
			total += base * pow(decay, i)
	return total

func get_positive_thoughts() -> Array[String]:
	var result: Array[String] = []
	for t: String in STACK_LIMITS:
		if float(STACK_LIMITS[t].get("base_mood", 0)) > 0:
			result.append(t)
	return result


func get_negative_thoughts() -> Array[String]:
	var result: Array[String] = []
	for t: String in STACK_LIMITS:
		if float(STACK_LIMITS[t].get("base_mood", 0)) < 0:
			result.append(t)
	return result


func get_worst_pawn() -> Dictionary:
	var worst_id: int = -1
	var worst_mood: float = 999.0
	for pid: int in _thought_stacks:
		var m: float = get_total_mood(pid)
		if m < worst_mood:
			worst_mood = m
			worst_id = pid
	if worst_id < 0:
		return {}
	return {"pawn_id": worst_id, "total_mood": worst_mood}


func get_avg_mood_per_pawn() -> float:
	if _thought_stacks.is_empty():
		return 0.0
	var total: float = 0.0
	for pid: int in _thought_stacks:
		total += get_total_mood(pid)
	return total / _thought_stacks.size()


func get_stackable_thought_count() -> int:
	var count: int = 0
	for t: String in STACK_LIMITS:
		if int(STACK_LIMITS[t].get("max_stack", 1)) > 1:
			count += 1
	return count


func get_total_active_stacks() -> int:
	var total: int = 0
	for pid: int in _thought_stacks:
		for t: String in _thought_stacks[pid]:
			total += int(_thought_stacks[pid][t])
	return total


func get_max_possible_negative_mood() -> float:
	var total: float = 0.0
	for t: String in STACK_LIMITS:
		var mood: float = float(STACK_LIMITS[t].get("base_mood", 0))
		if mood < 0:
			total += mood * float(STACK_LIMITS[t].get("max_stack", 1))
	return total


func get_strongest_positive_thought() -> String:
	var best: String = ""
	var best_mood: float = 0.0
	for t: String in STACK_LIMITS:
		var m: float = float(STACK_LIMITS[t].get("base_mood", 0))
		if m > best_mood:
			best_mood = m
			best = t
	return best


func get_decay_thought_count() -> int:
	var count: int = 0
	for t: String in STACK_LIMITS:
		if STACK_LIMITS[t].has("stack_decay"):
			count += 1
	return count


func get_emotional_weight() -> String:
	var neg: int = get_negative_thoughts().size()
	var pos: int = get_positive_thoughts().size()
	if pos > neg * 2:
		return "Uplifted"
	elif pos > neg:
		return "Positive"
	elif neg > pos * 2:
		return "Burdened"
	return "Neutral"

func get_mood_volatility() -> String:
	var max_neg: int = get_max_possible_negative_mood()
	if max_neg >= 50:
		return "Extreme"
	elif max_neg >= 30:
		return "High"
	elif max_neg >= 15:
		return "Moderate"
	return "Calm"

func get_thought_saturation_pct() -> float:
	if STACK_LIMITS.is_empty() or _thought_stacks.is_empty():
		return 0.0
	var active: int = get_total_active_stacks()
	var max_stacks: int = STACK_LIMITS.size() * _thought_stacks.size()
	if max_stacks == 0:
		return 0.0
	return snappedf(float(active) / float(max_stacks) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"thought_types": STACK_LIMITS.size(),
		"tracked_pawns": _thought_stacks.size(),
		"positive_count": get_positive_thoughts().size(),
		"negative_count": get_negative_thoughts().size(),
		"avg_mood": snapped(get_avg_mood_per_pawn(), 0.1),
		"stackable": get_stackable_thought_count(),
		"active_stacks": get_total_active_stacks(),
		"max_negative_mood": get_max_possible_negative_mood(),
		"strongest_positive": get_strongest_positive_thought(),
		"decay_thoughts": get_decay_thought_count(),
		"emotional_weight": get_emotional_weight(),
		"mood_volatility": get_mood_volatility(),
		"thought_saturation_pct": get_thought_saturation_pct(),
		"mental_load_index": get_mental_load_index(),
		"emotional_balance": get_emotional_balance(),
		"thought_churn_rate": get_thought_churn_rate(),
		"thought_ecosystem_health": get_thought_ecosystem_health(),
		"psychological_governance": get_psychological_governance(),
		"mental_wellness_index": get_mental_wellness_index(),
	}

func get_mental_load_index() -> float:
	var active := get_total_active_stacks()
	var types := STACK_LIMITS.size()
	if types <= 0:
		return 0.0
	return snapped(float(active) / float(types) * 100.0, 0.1)

func get_emotional_balance() -> String:
	var pos := get_positive_thoughts().size()
	var neg := get_negative_thoughts().size()
	if pos > neg * 2:
		return "Positive"
	elif pos >= neg:
		return "Balanced"
	elif neg > 0:
		return "Negative"
	return "Neutral"

func get_thought_churn_rate() -> float:
	var decay := get_decay_thought_count()
	var total := get_total_active_stacks()
	if total <= 0:
		return 0.0
	return snapped(float(decay) / float(total) * 100.0, 0.1)

func get_thought_ecosystem_health() -> float:
	var balance := get_emotional_balance()
	var b_val: float = 90.0 if balance == "Positive" else (70.0 if balance == "Balanced" else 30.0)
	var volatility := get_mood_volatility()
	var v_val: float = 90.0 if volatility == "Calm" else (60.0 if volatility == "Moderate" else 25.0)
	var saturation := get_thought_saturation_pct()
	return snapped((b_val + v_val + (100.0 - saturation)) / 3.0, 0.1)

func get_psychological_governance() -> String:
	var ecosystem := get_thought_ecosystem_health()
	var weight := get_emotional_weight()
	var w_val: float = 90.0 if weight == "Light" else (60.0 if weight == "Moderate" else 25.0)
	var combined := (ecosystem + w_val) / 2.0
	if combined >= 70.0:
		return "Stable"
	elif combined >= 40.0:
		return "Managing"
	elif _thought_stacks.size() > 0:
		return "Strained"
	return "Dormant"

func get_mental_wellness_index() -> float:
	var load := get_mental_load_index()
	var churn := get_thought_churn_rate()
	return snapped((100.0 - load + 100.0 - churn) / 2.0, 0.1)
