extends Node

## Generates and tracks random quests with rewards and expiry timers.
## Registered as autoload "QuestManager".

const QUEST_DEFS: Dictionary = {
	"RescueSurvivor": {
		"label": "Rescue a Survivor",
		"description": "A survivor needs help! Rescue them to gain a new colonist.",
		"reward_type": "colonist",
		"reward_amount": 1,
		"timeout_ticks": 15000,
		"difficulty": 1,
	},
	"DestroyOutpost": {
		"label": "Destroy Pirate Outpost",
		"description": "A nearby pirate outpost threatens the region. Destroy it for a reward.",
		"reward_type": "silver",
		"reward_amount": 300,
		"timeout_ticks": 25000,
		"difficulty": 3,
	},
	"DeliverGoods": {
		"label": "Deliver Trade Goods",
		"description": "A faction requests specific goods. Deliver for goodwill and payment.",
		"reward_type": "silver",
		"reward_amount": 200,
		"timeout_ticks": 20000,
		"difficulty": 2,
	},
	"HuntPredator": {
		"label": "Hunt the Maneater",
		"description": "A dangerous predator has been spotted. Hunt it to protect the colony.",
		"reward_type": "silver",
		"reward_amount": 150,
		"timeout_ticks": 12000,
		"difficulty": 2,
	},
	"ResearchRequest": {
		"label": "Research Breakthrough",
		"description": "Complete a research project for a faction in exchange for materials.",
		"reward_type": "materials",
		"reward_amount": 50,
		"timeout_ticks": 30000,
		"difficulty": 1,
	},
	"HostRefugees": {
		"label": "Host Refugees",
		"description": "Refugees request temporary shelter. Host them for goodwill.",
		"reward_type": "goodwill",
		"reward_amount": 25,
		"timeout_ticks": 18000,
		"difficulty": 1,
	},
}

var active_quests: Array[Dictionary] = []
var completed_quests: int = 0
var failed_quests: int = 0
var _next_id: int = 1
var _rng := RandomNumberGenerator.new()
var _quest_history: Array[Dictionary] = []
var total_silver_rewarded: int = 0


func _ready() -> void:
	_rng.seed = 88
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func _on_rare_tick(_tick: int) -> void:
	_tick_timeouts()
	_try_generate_quest()


func _try_generate_quest() -> void:
	if active_quests.size() >= 3:
		return
	if _rng.randf() > 0.005:
		return

	var keys: Array = QUEST_DEFS.keys()
	var chosen: String = keys[_rng.randi_range(0, keys.size() - 1)]

	for q: Dictionary in active_quests:
		if q.get("def_name", "") == chosen:
			return

	var def: Dictionary = QUEST_DEFS[chosen]
	var quest := {
		"id": _next_id,
		"def_name": chosen,
		"label": def.label,
		"description": def.description,
		"reward_type": def.reward_type,
		"reward_amount": def.reward_amount,
		"ticks_left": def.timeout_ticks,
		"state": "active",
	}
	_next_id += 1
	active_quests.append(quest)

	if ColonyLog:
		ColonyLog.add_entry("Quest", "New quest: " + def.label, "info")


func _tick_timeouts() -> void:
	var expired: Array[int] = []
	for i: int in range(active_quests.size()):
		active_quests[i].ticks_left -= 1
		if active_quests[i].ticks_left <= 0:
			expired.append(i)

	for idx: int in range(expired.size() - 1, -1, -1):
		var q: Dictionary = active_quests[expired[idx]]
		q.state = "failed"
		failed_quests += 1
		_quest_history.append({"id": q.get("id", 0), "def": q.get("def_name", ""), "state": "failed"})
		if _quest_history.size() > 50:
			_quest_history = _quest_history.slice(_quest_history.size() - 50)
		if ColonyLog:
			ColonyLog.add_entry("Quest", "Quest expired: " + q.get("label", ""), "warning")
		active_quests.remove_at(expired[idx])


func complete_quest(quest_id: int) -> Dictionary:
	for i: int in range(active_quests.size()):
		if active_quests[i].get("id", -1) == quest_id:
			var q: Dictionary = active_quests[i]
			q.state = "completed"
			completed_quests += 1
			active_quests.remove_at(i)
			_grant_reward(q)
			_quest_history.append({"id": q.get("id", 0), "def": q.get("def_name", ""), "state": "completed"})
			if _quest_history.size() > 50:
				_quest_history = _quest_history.slice(_quest_history.size() - 50)
			if ColonyLog:
				ColonyLog.add_entry("Quest", "Quest completed: %s! Reward: %d %s" % [q.get("label", ""), q.get("reward_amount", 0), q.get("reward_type", "")], "positive")
			return q
	return {}


func _grant_reward(quest: Dictionary) -> void:
	var rtype: String = quest.get("reward_type", "")
	var amount: int = quest.get("reward_amount", 0)
	match rtype:
		"silver":
			if TradeManager:
				TradeManager.colony_silver += amount
			total_silver_rewarded += amount
		"goodwill":
			pass
		"materials":
			if TradeManager:
				TradeManager.colony_silver += amount * 2
			total_silver_rewarded += amount * 2


func get_quest_by_id(quest_id: int) -> Dictionary:
	for q: Dictionary in active_quests:
		if q.get("id", -1) == quest_id:
			return q
	return {}


func get_quests_by_difficulty(min_diff: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for q: Dictionary in active_quests:
		var def: Dictionary = QUEST_DEFS.get(q.get("def_name", ""), {})
		if def.get("difficulty", 0) >= min_diff:
			result.append(q)
	return result


func get_completion_rate() -> float:
	var total := completed_quests + failed_quests
	if total == 0:
		return 0.0
	return float(completed_quests) / float(total)


func get_quest_history(count: int = 10) -> Array[Dictionary]:
	var start: int = maxi(0, _quest_history.size() - count)
	return _quest_history.slice(start) as Array[Dictionary]


func get_most_rewarding_quest() -> Dictionary:
	var best: Dictionary = {}
	var best_val: int = 0
	for q: Dictionary in active_quests:
		var val: int = q.get("reward_amount", 0)
		if val > best_val:
			best_val = val
			best = q
	return best


func get_expiring_soon(threshold_ticks: int = 3000) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for q: Dictionary in active_quests:
		if q.get("ticks_left", 0) <= threshold_ticks:
			result.append(q)
	return result


func get_avg_reward() -> float:
	if completed_quests == 0:
		return 0.0
	return snappedf(float(total_silver_rewarded) / float(completed_quests), 0.1)


func get_quest_health() -> String:
	var rate: float = get_completion_rate()
	if rate >= 0.8:
		return "Excellent"
	elif rate >= 0.5:
		return "Good"
	elif rate > 0.0:
		return "Struggling"
	return "None"

func get_urgency_count() -> int:
	return get_expiring_soon(1500).size()

func get_reward_tier() -> String:
	var avg: float = get_avg_reward()
	if avg >= 100.0:
		return "High"
	elif avg >= 40.0:
		return "Medium"
	elif avg > 0.0:
		return "Low"
	return "None"

func get_quest_pipeline_health() -> String:
	var active := active_quests.size()
	var rate := get_completion_rate()
	if active >= 3 and rate >= 0.5:
		return "Thriving"
	elif active >= 1:
		return "Active"
	return "Stagnant"

func get_opportunity_cost() -> float:
	if failed_quests <= 0:
		return 0.0
	return snapped(float(failed_quests) * get_avg_reward(), 0.1)

func get_strategic_value() -> String:
	var tier := get_reward_tier()
	var health := get_quest_health()
	if tier == "High" and health == "Good":
		return "Excellent"
	elif tier != "None" and health != "None":
		return "Moderate"
	return "Low"

func get_summary() -> Dictionary:
	var quests_info: Array[Dictionary] = []
	for q: Dictionary in active_quests:
		quests_info.append({
			"id": q.get("id", 0),
			"label": q.get("label", ""),
			"ticks_left": q.get("ticks_left", 0),
			"reward": q.get("reward_type", "") + " x" + str(q.get("reward_amount", 0)),
		})
	return {
		"active": active_quests.size(),
		"completed": completed_quests,
		"failed": failed_quests,
		"completion_rate": snappedf(get_completion_rate(), 0.01),
		"total_silver_rewarded": total_silver_rewarded,
		"quests": quests_info,
		"expiring_soon": get_expiring_soon().size(),
		"avg_reward": get_avg_reward(),
		"fail_rate": snappedf(float(failed_quests) / maxf(float(completed_quests + failed_quests), 1.0), 0.01),
		"silver_per_quest": snappedf(float(total_silver_rewarded) / maxf(float(completed_quests), 1.0), 0.1),
		"quest_health": get_quest_health(),
		"urgency_count": get_urgency_count(),
		"reward_tier": get_reward_tier(),
		"pipeline_health": get_quest_pipeline_health(),
		"opportunity_cost": get_opportunity_cost(),
		"strategic_value": get_strategic_value(),
		"quest_mastery_index": get_quest_mastery_index(),
		"reward_optimization_score": get_reward_optimization_score(),
		"mission_readiness": get_mission_readiness(),
	}

func get_quest_mastery_index() -> float:
	var rate: float = get_completion_rate()
	var value: String = get_strategic_value()
	var bonus: float = 20.0 if value == "High" else (10.0 if value == "Medium" else 0.0)
	return snappedf(clampf(rate * 100.0 * 0.7 + bonus, 0.0, 100.0), 0.1)

func get_reward_optimization_score() -> float:
	var avg: float = get_avg_reward()
	var per_quest: float = float(total_silver_rewarded) / maxf(float(completed_quests), 1.0)
	var score: float = minf(per_quest / 10.0, 50.0) + minf(avg / 5.0, 50.0)
	return snappedf(clampf(score, 0.0, 100.0), 0.1)

func get_mission_readiness() -> String:
	var active: int = active_quests.size()
	var expiring: int = get_expiring_soon().size()
	if active >= 3 and expiring <= 1:
		return "Ready"
	if active >= 1:
		return "Engaged"
	return "Idle"
