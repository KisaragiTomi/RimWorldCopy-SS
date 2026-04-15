extends Node

var _achieved: Dictionary = {}

const MILESTONES: Dictionary = {
	"FirstBlood": {"desc": "Win first combat", "check": "combat_won", "threshold": 1, "reward_silver": 50},
	"Population5": {"desc": "Reach 5 colonists", "check": "population", "threshold": 5, "reward_silver": 100},
	"Population10": {"desc": "Reach 10 colonists", "check": "population", "threshold": 10, "reward_silver": 200},
	"Wealth1000": {"desc": "Colony wealth reaches 1000", "check": "wealth", "threshold": 1000, "reward_silver": 150},
	"Wealth5000": {"desc": "Colony wealth reaches 5000", "check": "wealth", "threshold": 5000, "reward_silver": 300},
	"Research5": {"desc": "Complete 5 research projects", "check": "research_count", "threshold": 5, "reward_silver": 200},
	"Survive30Days": {"desc": "Survive 30 days", "check": "days_survived", "threshold": 30, "reward_silver": 250},
	"Survive100Days": {"desc": "Survive 100 days", "check": "days_survived", "threshold": 100, "reward_silver": 500},
	"BuildRoom10": {"desc": "Build 10 rooms", "check": "rooms", "threshold": 10, "reward_silver": 100},
	"TameAnimal": {"desc": "Tame first animal", "check": "tamed_animals", "threshold": 1, "reward_silver": 50},
}


func check_milestone(milestone_id: String, current_value: int) -> Dictionary:
	if _achieved.has(milestone_id):
		return {"already_achieved": true}
	if not MILESTONES.has(milestone_id):
		return {"unknown": true}
	var m: Dictionary = MILESTONES[milestone_id]
	if current_value >= int(m.threshold):
		_achieved[milestone_id] = TickManager.current_tick if TickManager else 0
		if ColonyLog and ColonyLog.has_method("add_entry"):
			ColonyLog.add_entry("Milestone", "Achieved: " + m.desc, "info")
		if EventLetter and EventLetter.has_method("send_letter"):
			EventLetter.send_letter("Milestone!", m.desc + " - Reward: " + str(m.reward_silver) + " silver", 0)
		return {"achieved": true, "reward": m.reward_silver}
	return {"not_yet": true, "progress": current_value, "target": m.threshold}


func get_achieved_count() -> int:
	return _achieved.size()


func get_remaining() -> Array[String]:
	var result: Array[String] = []
	for m_id: String in MILESTONES:
		if not _achieved.has(m_id):
			result.append(m_id)
	return result


func get_total_rewards_earned() -> int:
	var total: int = 0
	for m_id: String in _achieved:
		var m: Dictionary = MILESTONES.get(m_id, {})
		total += int(m.get("reward_silver", 0))
	return total


func get_next_milestone(check_type: String, current_value: int) -> Dictionary:
	var best: Dictionary = {}
	var best_gap: int = 999999
	for m_id: String in MILESTONES:
		if _achieved.has(m_id):
			continue
		var m: Dictionary = MILESTONES[m_id]
		if m.check == check_type:
			var gap: int = int(m.threshold) - current_value
			if gap > 0 and gap < best_gap:
				best_gap = gap
				best = {"id": m_id, "desc": m.desc, "remaining": gap}
	return best


func get_completion_percentage() -> float:
	if MILESTONES.is_empty():
		return 0.0
	return snappedf(float(_achieved.size()) / float(MILESTONES.size()) * 100.0, 0.1)


func get_avg_reward() -> float:
	if _achieved.is_empty():
		return 0.0
	return snappedf(float(get_total_rewards_earned()) / float(_achieved.size()), 0.1)


func get_most_recent_milestone() -> String:
	if _achieved.is_empty():
		return ""
	var keys := _achieved.keys()
	return str(keys[-1])


func get_progress_rating() -> String:
	var pct: float = get_completion_percentage()
	if pct >= 80.0:
		return "Near Complete"
	elif pct >= 50.0:
		return "Progressing"
	elif pct > 0.0:
		return "Early"
	return "None"

func get_reward_tier() -> String:
	var avg: float = get_avg_reward()
	if avg >= 500.0:
		return "Legendary"
	elif avg >= 200.0:
		return "High"
	elif avg >= 50.0:
		return "Standard"
	return "Low"

func get_momentum() -> float:
	if MILESTONES.is_empty():
		return 0.0
	return snappedf(float(_achieved.size()) / float(MILESTONES.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"total_milestones": MILESTONES.size(),
		"achieved": _achieved.size(),
		"achieved_list": _achieved.keys(),
		"remaining": get_remaining().size(),
		"total_rewards_earned": get_total_rewards_earned(),
		"completion_pct": get_completion_percentage(),
		"avg_reward": get_avg_reward(),
		"most_recent": get_most_recent_milestone(),
		"remaining_count": get_remaining().size(),
		"reward_per_milestone": snappedf(float(get_total_rewards_earned()) / maxf(float(_achieved.size()), 1.0), 0.1),
		"progress_rating": get_progress_rating(),
		"reward_tier": get_reward_tier(),
		"momentum_pct": get_momentum(),
		"achievement_depth": get_achievement_depth(),
		"progression_health": get_progression_health(),
		"development_trajectory": get_development_trajectory(),
		"civilizational_depth": get_civilizational_depth(),
		"achievement_momentum": get_achievement_momentum(),
		"legacy_building_score": get_legacy_building_score(),
	}

func get_civilizational_depth() -> float:
	var pct := get_completion_percentage()
	var rewards := float(get_total_rewards_earned())
	return snapped(pct * rewards / maxf(float(MILESTONES.size()), 1.0), 0.1)

func get_achievement_momentum() -> String:
	var trajectory := get_development_trajectory()
	var health := get_progression_health()
	if trajectory == "Ascending" and health in ["Healthy", "Thriving"]:
		return "Surging"
	elif trajectory == "Stagnant":
		return "Stalled"
	return "Steady"

func get_legacy_building_score() -> float:
	var depth := get_achievement_depth()
	var momentum := get_momentum()
	var bonus: float = 1.5 if depth == "Deep" else (1.0 if depth == "Moderate" else 0.5)
	return snapped(momentum * bonus, 0.1)

func get_achievement_depth() -> String:
	var pct := get_completion_percentage()
	if pct >= 80.0:
		return "Veteran"
	elif pct >= 50.0:
		return "Experienced"
	elif pct >= 20.0:
		return "Progressing"
	return "Starting"

func get_progression_health() -> String:
	var momentum := get_momentum()
	var rating := get_progress_rating()
	if momentum >= 70.0 and rating in ["Excellent", "Good"]:
		return "Thriving"
	elif momentum >= 30.0:
		return "Active"
	return "Stalling"

func get_development_trajectory() -> String:
	var remaining := get_remaining().size()
	var achieved := _achieved.size()
	if achieved > remaining * 2:
		return "Near Completion"
	elif achieved >= remaining:
		return "On Track"
	return "Early Stage"
