extends Node

var _ritual_log: Array = []

const RITUALS: Dictionary = {
	"Wedding": {"participants_min": 2, "duration_hours": 4, "mood_bonus": 25, "duration_days": 10, "desc": "A joyous union"},
	"Funeral": {"participants_min": 1, "duration_hours": 2, "mood_bonus": 5, "duration_days": 5, "desc": "Honoring the departed"},
	"PartyRandom": {"participants_min": 3, "duration_hours": 3, "mood_bonus": 10, "duration_days": 3, "desc": "A spontaneous gathering"},
	"Feast": {"participants_min": 4, "duration_hours": 4, "mood_bonus": 15, "duration_days": 5, "desc": "A lavish communal meal"},
	"Coronation": {"participants_min": 5, "duration_hours": 3, "mood_bonus": 20, "duration_days": 8, "desc": "A leader is crowned"},
	"SpeechCeremony": {"participants_min": 3, "duration_hours": 2, "mood_bonus": 8, "duration_days": 3, "desc": "An inspiring speech"},
	"TrialOfCombat": {"participants_min": 2, "duration_hours": 1, "mood_bonus": 12, "duration_days": 5, "desc": "Ritual combat for honor"},
	"HarvestFestival": {"participants_min": 4, "duration_hours": 5, "mood_bonus": 18, "duration_days": 7, "desc": "Celebrating the harvest"},
}


func start_ritual(ritual_id: String, participant_count: int) -> Dictionary:
	if not RITUALS.has(ritual_id):
		return {"success": false, "reason": "Unknown ritual"}
	var data: Dictionary = RITUALS[ritual_id]
	if participant_count < int(data.get("participants_min", 1)):
		return {"success": false, "reason": "Not enough participants"}
	var entry: Dictionary = {
		"ritual": ritual_id,
		"participants": participant_count,
		"mood_bonus": data.mood_bonus,
		"tick": TickManager.current_tick if TickManager else 0,
	}
	_ritual_log.append(entry)
	if EventLetter and EventLetter.has_method("send_letter"):
		EventLetter.send_letter(ritual_id, String(data.get("desc", "")), 0)
	return {"success": true, "mood_bonus": data.mood_bonus, "duration_days": data.duration_days}


func get_ritual_counts() -> Dictionary:
	var counts: Dictionary = {}
	for entry: Dictionary in _ritual_log:
		var r: String = String(entry.get("ritual", ""))
		counts[r] = counts.get(r, 0) + 1
	return counts


func get_most_performed_ritual() -> String:
	var counts: Dictionary = get_ritual_counts()
	var best: String = ""
	var best_count: int = 0
	for r: String in counts:
		if counts[r] > best_count:
			best_count = counts[r]
			best = r
	return best


func get_total_mood_bonus_earned() -> int:
	var total: int = 0
	for entry: Dictionary in _ritual_log:
		total += int(entry.get("mood_bonus", 0))
	return total


func get_avg_mood_per_ritual() -> float:
	if _ritual_log.is_empty():
		return 0.0
	return snappedf(float(get_total_mood_bonus_earned()) / float(_ritual_log.size()), 0.1)


func get_unique_rituals_performed() -> int:
	var unique: Dictionary = {}
	for entry in _ritual_log:
		var ed: Dictionary = entry if entry is Dictionary else {}
		unique[str(ed.get("id", ""))] = true
	return unique.size()


func get_never_performed_count() -> int:
	var performed: Dictionary = {}
	for entry in _ritual_log:
		var ed: Dictionary = entry if entry is Dictionary else {}
		performed[str(ed.get("id", ""))] = true
	return maxi(RITUALS.size() - performed.size(), 0)


func get_highest_mood_ritual() -> String:
	var best: String = ""
	var best_mood: int = 0
	for rid: String in RITUALS:
		var m: int = int(RITUALS[rid].get("mood_bonus", 0))
		if m > best_mood:
			best_mood = m
			best = rid
	return best


func get_total_participants() -> int:
	var total: int = 0
	for entry: Dictionary in _ritual_log:
		total += int(entry.get("participants", 0))
	return total


func get_avg_participants_per_ritual() -> float:
	if _ritual_log.is_empty():
		return 0.0
	return snappedf(float(get_total_participants()) / float(_ritual_log.size()), 0.1)


func get_cultural_vitality() -> String:
	if RITUALS.is_empty():
		return "None"
	var performed: int = get_unique_rituals_performed()
	var total: int = RITUALS.size()
	var pct: float = float(performed) / float(total) * 100.0
	if pct >= 80.0:
		return "Vibrant"
	elif pct >= 50.0:
		return "Active"
	elif pct >= 20.0:
		return "Dormant"
	return "Neglected"

func get_community_engagement() -> float:
	if _ritual_log.is_empty():
		return 0.0
	return snappedf(float(get_total_participants()) / float(_ritual_log.size()), 0.1)

func get_spiritual_health() -> String:
	var avg_mood: float = get_avg_mood_per_ritual()
	if avg_mood >= 10.0:
		return "Thriving"
	elif avg_mood >= 5.0:
		return "Healthy"
	elif avg_mood > 0.0:
		return "Tepid"
	return "Low"

func get_summary() -> Dictionary:
	return {
		"ritual_types": RITUALS.size(),
		"completed_rituals": _ritual_log.size(),
		"most_performed": get_most_performed_ritual(),
		"total_mood_earned": get_total_mood_bonus_earned(),
		"avg_mood_per_ritual": get_avg_mood_per_ritual(),
		"unique_performed": get_unique_rituals_performed(),
		"never_performed": get_never_performed_count(),
		"highest_mood_ritual": get_highest_mood_ritual(),
		"total_participants": get_total_participants(),
		"avg_participants": get_avg_participants_per_ritual(),
		"cultural_vitality": get_cultural_vitality(),
		"community_engagement": get_community_engagement(),
		"spiritual_health": get_spiritual_health(),
		"ceremony_richness": get_ceremony_richness(),
		"collective_morale_boost": get_collective_morale_boost(),
		"tradition_depth": get_tradition_depth(),
		"spiritual_ecosystem_health": get_spiritual_ecosystem_health(),
		"ceremonial_governance": get_ceremonial_governance(),
		"cultural_maturity_index": get_cultural_maturity_index(),
	}

func get_ceremony_richness() -> float:
	var unique := get_unique_rituals_performed()
	var total := RITUALS.size()
	if total <= 0:
		return 0.0
	return snapped(float(unique) / float(total) * 100.0, 0.1)

func get_collective_morale_boost() -> String:
	var avg_mood := get_avg_mood_per_ritual()
	if avg_mood >= 10.0:
		return "Uplifting"
	elif avg_mood >= 5.0:
		return "Positive"
	elif avg_mood > 0.0:
		return "Mild"
	return "None"

func get_tradition_depth() -> String:
	var logs := _ritual_log.size()
	var unique := get_unique_rituals_performed()
	if logs >= 10 and unique >= 3:
		return "Deep"
	elif logs >= 3:
		return "Developing"
	return "Nascent"

func get_spiritual_ecosystem_health() -> float:
	var richness := get_ceremony_richness()
	var vitality := get_cultural_vitality()
	var v_val: float = 90.0 if vitality in ["Vibrant"] else (60.0 if vitality in ["Active", "Moderate"] else 30.0)
	var morale := get_collective_morale_boost()
	var m_val: float = 90.0 if morale == "Uplifting" else (60.0 if morale == "Positive" else 30.0)
	return snapped((richness + v_val + m_val) / 3.0, 0.1)

func get_ceremonial_governance() -> String:
	var health := get_spiritual_ecosystem_health()
	var depth := get_tradition_depth()
	if health >= 65.0 and depth in ["Deep", "Developing"]:
		return "Established"
	elif health >= 35.0:
		return "Emerging"
	return "Absent"

func get_cultural_maturity_index() -> float:
	var engagement := get_community_engagement()
	var e_val: float = minf(engagement * 10.0, 100.0)
	var spiritual := get_spiritual_health()
	var s_val: float = 90.0 if spiritual in ["Thriving", "Healthy"] else (60.0 if spiritual == "Moderate" else 30.0)
	return snapped((e_val + s_val) / 2.0, 0.1)
