class_name ThoughtSystem
extends RefCounted

## Stack-based mood thoughts with expiry. Each pawn carries their own ThoughtSystem.

var thoughts: Array[Dictionary] = []

const THOUGHT_DEFS: Dictionary = {
	"AteFineMeal": {"label": "Ate fine meal", "mood": 0.05, "duration": 6000, "stacks": false},
	"AteRawFood": {"label": "Ate raw food", "mood": -0.03, "duration": 6000, "stacks": false},
	"SleptInBed": {"label": "Slept in a bed", "mood": 0.03, "duration": 8000, "stacks": false},
	"SleptOnGround": {"label": "Slept on the ground", "mood": -0.04, "duration": 8000, "stacks": false},
	"WitnessedDeath": {"label": "Witnessed a death", "mood": -0.08, "duration": 15000, "stacks": true},
	"ColonistDied": {"label": "A colonist has died", "mood": -0.12, "duration": 20000, "stacks": true},
	"Recruited": {"label": "Recruited someone", "mood": 0.04, "duration": 10000, "stacks": false},
	"WonFight": {"label": "Won a fight", "mood": 0.03, "duration": 8000, "stacks": true},
	"InPain": {"label": "In pain", "mood": -0.06, "duration": 0, "stacks": false},
	"Hypothermia": {"label": "Freezing cold", "mood": -0.05, "duration": 0, "stacks": false},
	"HeatStroke": {"label": "Burning hot", "mood": -0.05, "duration": 0, "stacks": false},
	"NiceRoom": {"label": "Nice room", "mood": 0.04, "duration": 4000, "stacks": false},
	"UglyRoom": {"label": "Ugly room", "mood": -0.03, "duration": 4000, "stacks": false},
	"Outdoors": {"label": "Outdoors", "mood": 0.01, "duration": 2000, "stacks": false},
	"AteWithoutTable": {"label": "Ate without a table", "mood": -0.03, "duration": 6000, "stacks": false},
	"KilledAnimal": {"label": "Hunted an animal", "mood": 0.02, "duration": 5000, "stacks": true},
	"Crafted": {"label": "Made something", "mood": 0.02, "duration": 5000, "stacks": true},
	"Drug_Beer": {"label": "Feeling buzzed", "mood": 0.05, "duration": 6000, "stacks": false},
	"Drug_Smokeleaf": {"label": "Smokeleaf high", "mood": 0.10, "duration": 8000, "stacks": false},
	"Drug_GoJuice": {"label": "Go-juice rush", "mood": 0.05, "duration": 5000, "stacks": false},
	"Drug_Yayo": {"label": "Yayo euphoria", "mood": 0.15, "duration": 4000, "stacks": false},
	"DrugWithdrawal": {"label": "Drug withdrawal", "mood": -0.10, "duration": 0, "stacks": false},
	"BondedAnimalDied": {"label": "My bonded animal died", "mood": -0.12, "duration": 20000, "stacks": false},
	"VisitorArrived": {"label": "Friendly visitors", "mood": 0.03, "duration": 5000, "stacks": false},
	"InDarkness": {"label": "In darkness (no power)", "mood": -0.06, "duration": 2000, "stacks": false},
	"Inspired": {"label": "Feeling inspired", "mood": 0.06, "duration": 6000, "stacks": false},
	"NewLover": {"label": "New love", "mood": 0.10, "duration": 12000, "stacks": false},
	"GotEngaged": {"label": "Got engaged!", "mood": 0.12, "duration": 15000, "stacks": false},
	"GotMarried": {"label": "Just married!", "mood": 0.15, "duration": 20000, "stacks": false},
	"BrokeUp": {"label": "Broke up", "mood": -0.10, "duration": 15000, "stacks": false},
	"WasInsulted": {"label": "Was insulted", "mood": -0.04, "duration": 5000, "stacks": true},
	"TatteredApparel": {"label": "Tattered apparel", "mood": -0.04, "duration": 3000, "stacks": false},
	"TaintedApparel": {"label": "Wearing dead man's clothes", "mood": -0.06, "duration": 3000, "stacks": false},
	"VeryComfortable": {"label": "Very comfortable", "mood": 0.06, "duration": 4000, "stacks": false},
	"Comfortable": {"label": "Comfortable", "mood": 0.03, "duration": 4000, "stacks": false},
	"Uncomfortable": {"label": "Uncomfortable", "mood": -0.02, "duration": 4000, "stacks": false},
	"AttendedParty": {"label": "Attended a party", "mood": 0.08, "duration": 8000, "stacks": false},
	"AttendedWedding": {"label": "Attended a wedding", "mood": 0.10, "duration": 10000, "stacks": false},
	"AttendedFuneral": {"label": "Attended a funeral", "mood": 0.04, "duration": 6000, "stacks": false},
	"AttendedFeast": {"label": "Attended a feast", "mood": 0.10, "duration": 10000, "stacks": false},
	"AuroraDisplay": {"label": "Witnessed aurora borealis", "mood": 0.06, "duration": 5000, "stacks": false},
	"AteNutrientPaste": {"label": "Ate nutrient paste", "mood": -0.04, "duration": 6000, "stacks": false},
	"Starving": {"label": "Starving", "mood": -0.12, "duration": 0, "stacks": false},
	"Exhausted": {"label": "Exhausted", "mood": -0.06, "duration": 0, "stacks": false},
	"CabinFever": {"label": "Cabin fever", "mood": -0.05, "duration": 8000, "stacks": false},
	"GotSomeSleep": {"label": "Got some sleep", "mood": 0.02, "duration": 4000, "stacks": false},
	"ResearchComplete": {"label": "Research breakthrough", "mood": 0.05, "duration": 6000, "stacks": false},
	"ColonyRaid": {"label": "Colony was raided", "mood": -0.06, "duration": 10000, "stacks": true},
	"RaidRepelled": {"label": "Repelled a raid!", "mood": 0.06, "duration": 8000, "stacks": true},
	"AteAtTable": {"label": "Ate at a table", "mood": 0.02, "duration": 6000, "stacks": false},
	"NiceBedroom": {"label": "Nice bedroom", "mood": 0.04, "duration": 8000, "stacks": false},
	"GotMedicine": {"label": "Received medical care", "mood": 0.03, "duration": 5000, "stacks": false},
}


const MAX_THOUGHTS := 30
const MAX_STACKS := 5


func add_thought(thought_id: String) -> void:
	var def: Dictionary = THOUGHT_DEFS.get(thought_id, {})
	if def.is_empty():
		return

	if not def.get("stacks", false):
		for i: int in range(thoughts.size() - 1, -1, -1):
			if thoughts[i].get("id", "") == thought_id:
				thoughts[i]["ticks_left"] = def.get("duration", 5000)
				return
	else:
		var stack_count: int = 0
		for t: Dictionary in thoughts:
			if t.get("id", "") == thought_id:
				stack_count += 1
		if stack_count >= MAX_STACKS:
			return

	if thoughts.size() >= MAX_THOUGHTS:
		_evict_weakest()

	thoughts.append({
		"id": thought_id,
		"label": def.get("label", thought_id),
		"mood": def.get("mood", 0.0),
		"ticks_left": def.get("duration", 5000),
		"permanent": def.get("duration", 1) == 0,
	})


func remove_thought(thought_id: String) -> void:
	var i := thoughts.size() - 1
	while i >= 0:
		if thoughts[i].get("id", "") == thought_id:
			thoughts.remove_at(i)
		i -= 1


func has_thought(thought_id: String) -> bool:
	for t: Dictionary in thoughts:
		if t.get("id", "") == thought_id:
			return true
	return false


func get_thought_count(thought_id: String) -> int:
	var count: int = 0
	for t: Dictionary in thoughts:
		if t.get("id", "") == thought_id:
			count += 1
	return count


func tick() -> void:
	var i := thoughts.size() - 1
	while i >= 0:
		var t: Dictionary = thoughts[i]
		if t.get("permanent", false):
			i -= 1
			continue
		t["ticks_left"] = t.get("ticks_left", 0) - 1
		if t["ticks_left"] <= 0:
			thoughts.remove_at(i)
		i -= 1


func get_total_mood() -> float:
	var total: float = 0.0
	for t: Dictionary in thoughts:
		total += t.get("mood", 0.0)
	return total


func get_positive_mood() -> float:
	var total: float = 0.0
	for t: Dictionary in thoughts:
		var m: float = t.get("mood", 0.0)
		if m > 0.0:
			total += m
	return total


func get_negative_mood() -> float:
	var total: float = 0.0
	for t: Dictionary in thoughts:
		var m: float = t.get("mood", 0.0)
		if m < 0.0:
			total += m
	return total


func get_strongest_thought() -> Dictionary:
	var strongest: Dictionary = {}
	var max_abs: float = 0.0
	for t: Dictionary in thoughts:
		var abs_mood: float = absf(t.get("mood", 0.0))
		if abs_mood > max_abs:
			max_abs = abs_mood
			strongest = t
	return strongest


func _evict_weakest() -> void:
	if thoughts.is_empty():
		return
	var weakest_idx: int = 0
	var weakest_abs: float = absf(thoughts[0].get("mood", 0.0))
	for i: int in range(1, thoughts.size()):
		if thoughts[i].get("permanent", false):
			continue
		var abs_mood: float = absf(thoughts[i].get("mood", 0.0))
		if abs_mood < weakest_abs:
			weakest_abs = abs_mood
			weakest_idx = i
	thoughts.remove_at(weakest_idx)


func get_expiring_soon(threshold: int = 500) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for t: Dictionary in thoughts:
		if t.get("permanent", false):
			continue
		if t.get("ticks_left", 0) <= threshold:
			result.append(t)
	return result


func get_permanent_thoughts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for t: Dictionary in thoughts:
		if t.get("permanent", false):
			result.append(t)
	return result


func get_mood_label() -> String:
	var total: float = get_total_mood()
	if total >= 0.3:
		return "Elated"
	elif total >= 0.1:
		return "Happy"
	elif total >= -0.05:
		return "Content"
	elif total >= -0.15:
		return "Stressed"
	return "Miserable"


func get_thoughts_summary() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for t: Dictionary in thoughts:
		result.append({
			"id": t.get("id", ""),
			"label": t.get("label", ""),
			"mood": t.get("mood", 0.0),
			"ticks_left": t.get("ticks_left", 0),
		})
	return result

func get_avg_mood_per_thought_def() -> float:
	var total: float = 0.0
	if THOUGHT_DEFS.is_empty():
		return 0.0
	for k: String in THOUGHT_DEFS:
		total += THOUGHT_DEFS[k].get("mood", 0.0)
	return snappedf(total / float(THOUGHT_DEFS.size()), 0.001)

func get_stackable_thought_count() -> int:
	var count: int = 0
	for k: String in THOUGHT_DEFS:
		if THOUGHT_DEFS[k].get("stacks", false):
			count += 1
	return count

func get_permanent_thought_def_count() -> int:
	var count: int = 0
	for k: String in THOUGHT_DEFS:
		if THOUGHT_DEFS[k].get("duration", 1) == 0:
			count += 1
	return count

func get_negative_active_count() -> int:
	var cnt: int = 0
	for t: Dictionary in thoughts:
		if t.get("mood", 0.0) < 0.0:
			cnt += 1
	return cnt


func get_expiring_soon_count(threshold_ticks: int = 500) -> int:
	var cnt: int = 0
	for t: Dictionary in thoughts:
		var left: int = t.get("ticks_left", 0) as int
		if left > 0 and left <= threshold_ticks:
			cnt += 1
	return cnt


func get_drug_thought_def_count() -> int:
	var count: int = 0
	for k: String in THOUGHT_DEFS:
		if k.begins_with("Drug_") or k == "DrugWithdrawal":
			count += 1
	return count

func get_longest_duration_def() -> String:
	var best: String = ""
	var best_dur: int = 0
	for k: String in THOUGHT_DEFS:
		var dur: int = THOUGHT_DEFS[k].get("duration", 0)
		if dur > best_dur:
			best_dur = dur
			best = k
	return best

func get_social_thought_def_count() -> int:
	var social_keys: Array[String] = ["NewLover", "GotEngaged", "GotMarried", "BrokeUp", "WasInsulted", "AttendedWedding", "AttendedParty", "AttendedFuneral", "AttendedFeast", "VisitorArrived", "Recruited"]
	var count: int = 0
	for k: String in THOUGHT_DEFS:
		if k in social_keys:
			count += 1
	return count

func get_positive_active_count() -> int:
	var count: int = 0
	for t: Dictionary in thoughts:
		if t.get("mood", 0.0) > 0.0:
			count += 1
	return count


func get_mood_balance() -> float:
	var pos: int = get_positive_active_count()
	var neg: int = get_negative_active_count()
	if pos + neg <= 0:
		return 0.0
	return snappedf(float(pos - neg) / float(pos + neg), 0.01)


func get_thought_diversity() -> int:
	var types: Dictionary = {}
	for t: Dictionary in thoughts:
		types[t.get("id", "")] = true
	return types.size()


func get_emotional_resilience() -> float:
	var pos_sum := 0.0
	var total_abs := 0.0
	for def in THOUGHT_DEFS.values():
		var m: float = def["mood"]
		total_abs += absf(m)
		if m > 0:
			pos_sum += m
	return snapped(pos_sum / maxf(total_abs, 0.001) * 100.0, 0.1)

func get_mood_volatility_pct() -> float:
	var temp := 0
	for def in THOUGHT_DEFS.values():
		if def["duration"] > 0 and def["duration"] <= 5000:
			temp += 1
	return snapped(float(temp) / maxf(THOUGHT_DEFS.size(), 1.0) * 100.0, 0.1)

func get_cognitive_load() -> float:
	return snapped(float(thoughts.size()) / maxf(MAX_THOUGHTS, 1.0) * 100.0, 0.1)

func get_mood_forecast() -> float:
	var expiring_pos := 0.0
	var expiring_neg := 0.0
	for t: Dictionary in thoughts:
		var rem: int = t.get("remaining_ticks", -1)
		if rem > 0 and rem < 5000:
			var m: float = t.get("mood", 0.0)
			if m > 0.0:
				expiring_pos += m
			elif m < 0.0:
				expiring_neg += absf(m)
	return snapped(expiring_neg - expiring_pos, 0.01)

func get_thought_pressure() -> String:
	var neg := get_negative_active_count()
	var pos := get_positive_active_count()
	var total := neg + pos
	if total <= 0:
		return "Neutral"
	var neg_ratio := float(neg) / float(total)
	if neg_ratio >= 0.7:
		return "Crushing"
	elif neg_ratio >= 0.5:
		return "Heavy"
	elif neg_ratio >= 0.3:
		return "Moderate"
	return "Light"

func get_resilience_profile() -> Dictionary:
	var balance := get_mood_balance()
	var volatility := get_mood_volatility_pct()
	var load := get_cognitive_load()
	var stability: String
	if balance > 0.3 and volatility < 40.0:
		stability = "Robust"
	elif balance > 0.0:
		stability = "Stable"
	elif balance > -0.3:
		stability = "Fragile"
	else:
		stability = "Critical"
	return {"stability": stability, "balance": balance, "volatility_pct": volatility, "load_pct": load}

func get_thought_system_summary() -> Dictionary:
	return {
		"defined_thoughts": THOUGHT_DEFS.size(),
		"active_thoughts": thoughts.size(),
		"total_mood": snappedf(get_total_mood(), 0.01),
		"mood_label": get_mood_label(),
		"avg_mood_per_def": get_avg_mood_per_thought_def(),
		"stackable_defs": get_stackable_thought_count(),
		"permanent_defs": get_permanent_thought_def_count(),
		"negative_active": get_negative_active_count(),
		"expiring_soon": get_expiring_soon_count(),
		"strongest": get_strongest_thought().get("id", ""),
		"drug_thought_defs": get_drug_thought_def_count(),
		"longest_duration_def": get_longest_duration_def(),
		"social_thought_defs": get_social_thought_def_count(),
		"positive_active": get_positive_active_count(),
		"mood_balance": get_mood_balance(),
		"thought_diversity": get_thought_diversity(),
		"emotional_resilience": get_emotional_resilience(),
		"mood_volatility_pct": get_mood_volatility_pct(),
		"cognitive_load": get_cognitive_load(),
		"mood_forecast": get_mood_forecast(),
		"thought_pressure": get_thought_pressure(),
		"resilience_profile": get_resilience_profile(),
		"thought_ecosystem_health": get_thought_ecosystem_health(),
		"mental_governance": get_mental_governance(),
		"psyche_maturity_index": get_psyche_maturity_index(),
	}

func get_thought_ecosystem_health() -> float:
	var resilience := get_emotional_resilience()
	var volatility := get_mood_volatility_pct()
	var stability := maxf(100.0 - volatility, 0.0)
	var load := get_cognitive_load()
	var headroom := maxf(100.0 - load, 0.0)
	return snapped((resilience + stability + headroom) / 3.0, 0.1)

func get_mental_governance() -> String:
	var eco := get_thought_ecosystem_health()
	var mat := get_psyche_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif thoughts.size() > 0:
		return "Nascent"
	return "Dormant"

func get_psyche_maturity_index() -> float:
	var diversity := get_thought_diversity()
	var balance := get_mood_balance()
	var balance_score := clampf((balance + 1.0) / 2.0 * 100.0, 0.0, 100.0)
	var pressure := get_thought_pressure()
	var p_val: float = 90.0 if pressure == "Euphoric" else (70.0 if pressure == "Neutral" else (40.0 if pressure == "Strained" else 15.0))
	return snapped((minf(diversity * 10.0, 100.0) + balance_score + p_val) / 3.0, 0.1)
