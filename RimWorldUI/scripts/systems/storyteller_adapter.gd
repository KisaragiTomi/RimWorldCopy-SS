extends Node

const STORYTELLERS: Dictionary = {
	"Cassandra": {"event_interval_days": 6, "threat_ramp": 1.0, "max_threats_per_day": 1, "pattern": "steady_rise"},
	"Phoebe": {"event_interval_days": 12, "threat_ramp": 0.6, "max_threats_per_day": 1, "pattern": "peaceful_ramp"},
	"Randy": {"event_interval_days": 4, "threat_ramp": 1.2, "max_threats_per_day": 3, "pattern": "random"}
}

const EVENT_CATEGORIES: Dictionary = {
	"ThreatSmall": {"weight_base": 0.3, "min_day": 5},
	"ThreatBig": {"weight_base": 0.15, "min_day": 20},
	"ThreatMech": {"weight_base": 0.1, "min_day": 40},
	"TraderArrival": {"weight_base": 0.2, "min_day": 2},
	"ResourceDrop": {"weight_base": 0.15, "min_day": 3},
	"WandererJoin": {"weight_base": 0.1, "min_day": 8},
	"Disease": {"weight_base": 0.1, "min_day": 10},
	"Eclipse": {"weight_base": 0.05, "min_day": 15},
	"PsychicDrone": {"weight_base": 0.05, "min_day": 25},
	"Infestation": {"weight_base": 0.08, "min_day": 30}
}

const DIFFICULTY_SCALES: Dictionary = {
	"Peaceful": {"threat_mult": 0.0, "positive_mult": 2.0},
	"Community": {"threat_mult": 0.5, "positive_mult": 1.5},
	"Adventure": {"threat_mult": 0.8, "positive_mult": 1.2},
	"Strive": {"threat_mult": 1.0, "positive_mult": 1.0},
	"Blood": {"threat_mult": 1.3, "positive_mult": 0.8},
	"Losing": {"threat_mult": 1.7, "positive_mult": 0.5}
}

func get_event_weight(storyteller: String, event: String, day: int, difficulty: String) -> float:
	if not STORYTELLERS.has(storyteller) or not EVENT_CATEGORIES.has(event):
		return 0.0
	var ec: Dictionary = EVENT_CATEGORIES[event]
	if day < ec["min_day"]:
		return 0.0
	var base_w: float = ec["weight_base"]
	var is_threat: bool = event.begins_with("Threat") or event in ["Disease", "PsychicDrone", "Infestation"]
	var diff: Dictionary = DIFFICULTY_SCALES.get(difficulty, DIFFICULTY_SCALES["Strive"])
	var mult: float = diff["threat_mult"] if is_threat else diff["positive_mult"]
	return base_w * STORYTELLERS[storyteller]["threat_ramp"] * mult

func get_hardest_difficulty() -> String:
	var best: String = ""
	var best_v: float = 0.0
	for d: String in DIFFICULTY_SCALES:
		if DIFFICULTY_SCALES[d]["threat_mult"] > best_v:
			best_v = DIFFICULTY_SCALES[d]["threat_mult"]
			best = d
	return best

func get_most_aggressive_storyteller() -> String:
	var best: String = ""
	var best_r: float = 0.0
	for s: String in STORYTELLERS:
		if STORYTELLERS[s]["threat_ramp"] > best_r:
			best_r = STORYTELLERS[s]["threat_ramp"]
			best = s
	return best

func get_threat_events() -> Array[String]:
	var result: Array[String] = []
	for e: String in EVENT_CATEGORIES:
		if e.begins_with("Threat") or e in ["Disease", "PsychicDrone", "Infestation"]:
			result.append(e)
	return result

func get_calmest_storyteller() -> String:
	var best: String = ""
	var best_rate: float = 999.0
	for st: String in STORYTELLERS:
		var r: float = float(STORYTELLERS[st].get("threat_rate", 999.0))
		if r < best_rate:
			best_rate = r
			best = st
	return best

func get_avg_threat_rate() -> float:
	if STORYTELLERS.is_empty():
		return 0.0
	var total: float = 0.0
	for st: String in STORYTELLERS:
		total += float(STORYTELLERS[st].get("threat_rate", 0.0))
	return total / STORYTELLERS.size()

func get_positive_event_count() -> int:
	var count: int = 0
	for ec: String in EVENT_CATEGORIES:
		if String(EVENT_CATEGORIES[ec].get("type", "")) == "positive":
			count += 1
	return count

func get_late_game_event_count() -> int:
	var count: int = 0
	for ec: String in EVENT_CATEGORIES:
		if int(EVENT_CATEGORIES[ec].get("min_day", 0)) >= 25:
			count += 1
	return count


func get_highest_weight_event() -> String:
	var best: String = ""
	var best_w: float = 0.0
	for ec: String in EVENT_CATEGORIES:
		var w: float = float(EVENT_CATEGORIES[ec].get("weight_base", 0.0))
		if w > best_w:
			best_w = w
			best = ec
	return best


func get_avg_event_interval() -> float:
	if STORYTELLERS.is_empty():
		return 0.0
	var total: float = 0.0
	for st: String in STORYTELLERS:
		total += float(STORYTELLERS[st].get("event_interval_days", 0))
	return total / STORYTELLERS.size()


func get_summary() -> Dictionary:
	return {
		"storytellers": STORYTELLERS.size(),
		"event_categories": EVENT_CATEGORIES.size(),
		"difficulty_levels": DIFFICULTY_SCALES.size(),
		"hardest_difficulty": get_hardest_difficulty(),
		"most_aggressive": get_most_aggressive_storyteller(),
		"calmest": get_calmest_storyteller(),
		"avg_threat_rate": snapped(get_avg_threat_rate(), 0.01),
		"positive_events": get_positive_event_count(),
		"late_game_events": get_late_game_event_count(),
		"highest_weight_event": get_highest_weight_event(),
		"avg_event_interval": snapped(get_avg_event_interval(), 0.1),
	}
