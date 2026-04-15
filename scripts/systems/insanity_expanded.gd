extends Node

const BREAK_TYPES: Dictionary = {
	"Berserk": {"severity": 4, "duration_hours": 6, "danger": "attack_anyone", "mood_threshold": 0.05},
	"RunWild": {"severity": 2, "duration_hours": 12, "danger": "flee_map", "mood_threshold": 0.1},
	"Catatonic": {"severity": 3, "duration_hours": 48, "danger": "incapacitated", "mood_threshold": 0.15},
	"Tantrum": {"severity": 2, "duration_hours": 4, "danger": "destroy_items", "mood_threshold": 0.2},
	"InsultSpree": {"severity": 1, "duration_hours": 8, "danger": "insult_everyone", "mood_threshold": 0.25},
	"BingeEating": {"severity": 1, "duration_hours": 6, "danger": "consume_food", "mood_threshold": 0.3},
	"BingeDrinking": {"severity": 2, "duration_hours": 12, "danger": "consume_drugs", "mood_threshold": 0.25},
	"Pyromania": {"severity": 3, "duration_hours": 4, "danger": "start_fires", "mood_threshold": 0.15},
	"Murderous": {"severity": 5, "duration_hours": 2, "danger": "kill_specific", "mood_threshold": 0.02},
	"Comatose": {"severity": 3, "duration_hours": 72, "danger": "deep_sleep", "mood_threshold": 0.1},
	"CorpseObsession": {"severity": 2, "duration_hours": 8, "danger": "dig_up_corpses", "mood_threshold": 0.15},
	"Jailbreaker": {"severity": 2, "duration_hours": 4, "danger": "free_prisoners", "mood_threshold": 0.2}
}

func check_for_break(mood_pct: float) -> String:
	for break_type: String in BREAK_TYPES:
		if mood_pct <= BREAK_TYPES[break_type]["mood_threshold"]:
			if randf() < 0.1:
				return break_type
	return ""

func get_break_info(break_type: String) -> Dictionary:
	return BREAK_TYPES.get(break_type, {})

func get_most_severe_breaks(min_severity: int = 4) -> Array[String]:
	var result: Array[String] = []
	for bt: String in BREAK_TYPES:
		if BREAK_TYPES[bt]["severity"] >= min_severity:
			result.append(bt)
	return result

func get_danger_types() -> Array[String]:
	var types: Array[String] = []
	for bt: String in BREAK_TYPES:
		var d: String = BREAK_TYPES[bt]["danger"]
		if not types.has(d):
			types.append(d)
	return types

func get_breaks_below_threshold(mood_pct: float) -> Array[String]:
	var result: Array[String] = []
	for bt: String in BREAK_TYPES:
		if mood_pct <= BREAK_TYPES[bt]["mood_threshold"]:
			result.append(bt)
	return result

func get_avg_duration_hours() -> float:
	if BREAK_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for bt: String in BREAK_TYPES:
		total += float(BREAK_TYPES[bt].get("duration_hours", 0))
	return total / BREAK_TYPES.size()


func get_lowest_threshold_break() -> String:
	var best: String = ""
	var best_th: float = 1.0
	for bt: String in BREAK_TYPES:
		var th: float = float(BREAK_TYPES[bt].get("mood_threshold", 1.0))
		if th < best_th:
			best_th = th
			best = bt
	return best


func get_longest_break() -> String:
	var best: String = ""
	var best_dur: int = 0
	for bt: String in BREAK_TYPES:
		var d: int = int(BREAK_TYPES[bt].get("duration_hours", 0))
		if d > best_dur:
			best_dur = d
			best = bt
	return best


func get_summary() -> Dictionary:
	var severe: Array[String] = get_most_severe_breaks()
	return {
		"break_types": BREAK_TYPES.size(),
		"severe_break_count": severe.size(),
		"danger_type_count": get_danger_types().size(),
		"avg_duration": snapped(get_avg_duration_hours(), 0.1),
		"hardest_trigger": get_lowest_threshold_break(),
		"longest_break": get_longest_break(),
	}
