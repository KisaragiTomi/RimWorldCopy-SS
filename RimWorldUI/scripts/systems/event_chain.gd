extends Node

var _active_chains: Dictionary = {}

const CHAINS: Dictionary = {
	"RefugeeChased": {
		"steps": [
			{"id": "arrive", "text": "Refugees arrive seeking shelter", "choices": ["accept", "reject"]},
			{"id": "ambush", "text": "Raiders follow the refugees", "delay_days": 2, "condition": "accepted"},
			{"id": "betray", "text": "Refugees may betray you", "chance": 0.3, "delay_days": 5, "condition": "accepted"}
		]
	},
	"PrisonerRansom": {
		"steps": [
			{"id": "demand", "text": "Faction demands ransom for prisoner", "choices": ["pay", "refuse", "counter"]},
			{"id": "escalate", "text": "Faction sends raid as retaliation", "delay_days": 3, "condition": "refused"},
			{"id": "negotiate", "text": "Counter-offer considered", "chance": 0.5, "condition": "countered"}
		]
	},
	"MysteriousCargo": {
		"steps": [
			{"id": "drop", "text": "Mysterious cargo pod crashes nearby", "choices": ["open", "ignore"]},
			{"id": "contents", "text": "Cargo contains rare items or threat", "delay_days": 0, "condition": "opened"},
			{"id": "owner", "text": "Original owner comes to reclaim", "delay_days": 4, "condition": "opened"}
		]
	},
	"AncientThreat": {
		"steps": [
			{"id": "discover", "text": "Ancient structure discovered during mining", "choices": ["open_door", "seal"]},
			{"id": "unleash", "text": "Mechanoids or insects awaken", "delay_days": 0, "condition": "opened_door"},
			{"id": "loot", "text": "Ancient treasure accessible after clearing", "condition": "cleared"}
		]
	},
	"TradeDisaster": {
		"steps": [
			{"id": "offer", "text": "Lucrative trade offer from distant faction", "choices": ["send_caravan", "decline"]},
			{"id": "ambush_en_route", "text": "Caravan ambushed mid-journey", "chance": 0.4, "delay_days": 3, "condition": "sent"},
			{"id": "complete", "text": "Trade completed successfully", "condition": "survived"}
		]
	},
	"PsychicShip": {
		"steps": [
			{"id": "crash", "text": "Psychic ship chunk crashes", "choices": ["attack_now", "prepare"]},
			{"id": "drone", "text": "Psychic drone intensifies daily", "delay_days": 1, "condition": "preparing"},
			{"id": "emerge", "text": "Mechanoids emerge from wreckage", "delay_days": 4, "condition": "preparing"}
		]
	}
}

func start_chain(chain_id: String) -> Dictionary:
	if not CHAINS.has(chain_id):
		return {"error": "unknown_chain"}
	var chain: Dictionary = CHAINS[chain_id]
	_active_chains[chain_id] = {"current_step": 0, "day_started": 0, "choices_made": []}
	return {"started": chain_id, "first_step": chain["steps"][0]}

func make_choice(chain_id: String, choice: String) -> Dictionary:
	if not _active_chains.has(chain_id):
		return {"error": "chain_not_active"}
	_active_chains[chain_id]["choices_made"].append(choice)
	_active_chains[chain_id]["current_step"] += 1
	var chain: Dictionary = CHAINS[chain_id]
	var step_idx: int = _active_chains[chain_id]["current_step"]
	if step_idx >= chain["steps"].size():
		_active_chains.erase(chain_id)
		return {"chain_complete": chain_id}
	return {"next_step": chain["steps"][step_idx], "choice_made": choice}

func get_longest_chain() -> String:
	var best: String = ""
	var best_len: int = 0
	for cid: String in CHAINS:
		var cnt: int = CHAINS[cid]["steps"].size()
		if cnt > best_len:
			best_len = cnt
			best = cid
	return best

func get_chains_with_combat() -> Array[String]:
	var result: Array[String] = []
	for cid: String in CHAINS:
		for step: Dictionary in CHAINS[cid]["steps"]:
			var txt: String = step.get("text", "").to_lower()
			if "raid" in txt or "ambush" in txt or "mechanoid" in txt or "attack" in txt:
				result.append(cid)
				break
	return result

func get_active_chain_progress() -> Dictionary:
	var result: Dictionary = {}
	for cid: String in _active_chains:
		var total: int = CHAINS[cid]["steps"].size()
		var current: int = _active_chains[cid]["current_step"]
		result[cid] = {"current": current, "total": total}
	return result

func get_avg_chain_length() -> float:
	if CHAINS.is_empty():
		return 0.0
	var total: int = 0
	for c: String in CHAINS:
		total += CHAINS[c].get("events", []).size()
	return float(total) / CHAINS.size()


func get_completed_chains() -> int:
	var count: int = 0
	for cid: int in _active_chains:
		if bool(_active_chains[cid].get("completed", false)):
			count += 1
	return count


func get_pending_chains() -> int:
	var count: int = 0
	for cid: int in _active_chains:
		if not bool(_active_chains[cid].get("completed", false)):
			count += 1
	return count


func get_risky_chain_count() -> int:
	var count: int = 0
	for cid: String in CHAINS:
		for step: Dictionary in CHAINS[cid]["steps"]:
			if step.has("chance"):
				count += 1
				break
	return count


func get_total_steps() -> int:
	var total: int = 0
	for cid: String in CHAINS:
		total += CHAINS[cid]["steps"].size()
	return total


func get_choice_chain_count() -> int:
	var count: int = 0
	for cid: String in CHAINS:
		for step: Dictionary in CHAINS[cid]["steps"]:
			if step.has("choices"):
				count += 1
				break
	return count


func get_narrative_complexity() -> String:
	var choice: int = get_choice_chain_count()
	var total: int = CHAINS.size()
	if total == 0:
		return "none"
	var ratio: float = choice * 1.0 / total
	if ratio >= 0.6:
		return "branching"
	if ratio >= 0.3:
		return "moderate"
	return "linear"

func get_completion_rate_pct() -> float:
	var completed: int = get_completed_chains()
	var total: int = completed + get_pending_chains()
	if total == 0:
		return 0.0
	return snapped(completed * 100.0 / total, 0.1)

func get_threat_escalation() -> String:
	var risky: int = get_risky_chain_count()
	var combat: int = get_chains_with_combat().size()
	var active: int = _active_chains.size()
	if active == 0:
		return "dormant"
	var danger: float = (risky + combat) * 1.0 / active
	if danger >= 0.6:
		return "volatile"
	if danger >= 0.3:
		return "tense"
	return "calm"

func get_summary() -> Dictionary:
	return {
		"chain_types": CHAINS.size(),
		"active_chains": _active_chains.size(),
		"longest_chain": get_longest_chain(),
		"combat_chains": get_chains_with_combat().size(),
		"avg_length": snapped(get_avg_chain_length(), 0.1),
		"completed": get_completed_chains(),
		"pending": get_pending_chains(),
		"risky_chains": get_risky_chain_count(),
		"total_steps": get_total_steps(),
		"choice_chains": get_choice_chain_count(),
		"narrative_complexity": get_narrative_complexity(),
		"completion_rate_pct": get_completion_rate_pct(),
		"threat_escalation": get_threat_escalation(),
		"story_depth_index": get_story_depth_index(),
		"decision_pressure": get_decision_pressure(),
		"chain_momentum": get_chain_momentum(),
		"narrative_ecosystem_health": get_narrative_ecosystem_health(),
		"story_governance": get_story_governance(),
		"quest_maturity_index": get_quest_maturity_index(),
	}

func get_story_depth_index() -> float:
	var total_steps := get_total_steps()
	var chains := CHAINS.size()
	if chains <= 0:
		return 0.0
	return snapped(float(total_steps) / float(chains), 0.1)

func get_decision_pressure() -> String:
	var choice := get_choice_chain_count()
	var risky := get_risky_chain_count()
	if choice >= 3 and risky >= 2:
		return "Intense"
	elif choice >= 1:
		return "Moderate"
	return "Low"

func get_chain_momentum() -> String:
	var pending := get_pending_chains()
	var completed := get_completed_chains()
	if pending > completed:
		return "Building"
	elif pending > 0:
		return "Steady"
	return "Resolved"

func get_narrative_ecosystem_health() -> float:
	var complexity := get_narrative_complexity()
	var cx_val: float = 90.0 if complexity in ["rich", "intricate"] else (60.0 if complexity in ["moderate", "mixed"] else 30.0)
	var momentum := get_chain_momentum()
	var m_val: float = 90.0 if momentum == "Building" else (60.0 if momentum == "Steady" else 30.0)
	var depth := get_story_depth_index()
	return snapped((cx_val + m_val + minf(depth * 10.0, 100.0)) / 3.0, 0.1)

func get_quest_maturity_index() -> float:
	var completion := get_completion_rate_pct()
	var escalation := get_threat_escalation()
	var e_val: float = 90.0 if escalation in ["critical", "rising"] else (60.0 if escalation in ["moderate", "steady"] else 30.0)
	var pressure := get_decision_pressure()
	var p_val: float = 90.0 if pressure == "Intense" else (60.0 if pressure == "Moderate" else 30.0)
	return snapped((completion + e_val + p_val) / 3.0, 0.1)

func get_story_governance() -> String:
	var ecosystem := get_narrative_ecosystem_health()
	var maturity := get_quest_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _active_chains.size() > 0:
		return "Nascent"
	return "Dormant"
