extends Node

var _inbox: Array = []
var _outbox: Array = []

const LETTER_TYPES: Dictionary = {
	"ThreatLetter": {"urgency": 3, "response_days": 3, "faction_impact": -10},
	"TradeOffer": {"urgency": 1, "response_days": 7, "faction_impact": 5},
	"AllianceProposal": {"urgency": 2, "response_days": 5, "faction_impact": 15},
	"TributeRequest": {"urgency": 2, "response_days": 5, "faction_impact": -5},
	"PeaceOffer": {"urgency": 2, "response_days": 3, "faction_impact": 10},
	"WarDeclaration": {"urgency": 3, "response_days": 0, "faction_impact": -30},
	"RansomDemand": {"urgency": 3, "response_days": 2, "faction_impact": -15},
	"GiftAnnouncement": {"urgency": 1, "response_days": 0, "faction_impact": 8}
}

func receive_letter(letter_type: String, from_faction: String) -> Dictionary:
	if not LETTER_TYPES.has(letter_type):
		return {"error": "unknown_type"}
	var letter: Dictionary = {"type": letter_type, "from": from_faction, "day_received": 0, "responded": false}
	_inbox.append(letter)
	return {"received": letter_type, "urgency": LETTER_TYPES[letter_type]["urgency"]}

func respond_to_letter(index: int, accept: bool) -> Dictionary:
	if index < 0 or index >= _inbox.size():
		return {"error": "invalid_index"}
	_inbox[index]["responded"] = true
	var ltype: String = _inbox[index]["type"]
	var impact: float = LETTER_TYPES[ltype]["faction_impact"]
	if not accept:
		impact *= -0.5
	return {"responded": true, "accepted": accept, "faction_impact": impact}

func get_urgent_letters() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for l: Dictionary in _inbox:
		if not l["responded"] and LETTER_TYPES.get(l["type"], {}).get("urgency", 0) >= 3:
			result.append(l)
	return result

func get_faction_impact_total(faction: String) -> float:
	var total: float = 0.0
	for l: Dictionary in _inbox:
		if l["from"] == faction and l["responded"]:
			total += LETTER_TYPES.get(l["type"], {}).get("faction_impact", 0.0)
	return total

func get_most_active_faction() -> String:
	var counts: Dictionary = {}
	for l: Dictionary in _inbox:
		var f: String = l["from"]
		counts[f] = counts.get(f, 0) + 1
	var best: String = ""
	var best_c: int = 0
	for f: String in counts:
		if counts[f] > best_c:
			best_c = counts[f]
			best = f
	return best

func get_avg_faction_impact() -> float:
	if LETTER_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for lt: String in LETTER_TYPES:
		total += float(LETTER_TYPES[lt].get("faction_impact", 0))
	return total / LETTER_TYPES.size()


func get_positive_letter_count() -> int:
	var count: int = 0
	for lt: String in LETTER_TYPES:
		if float(LETTER_TYPES[lt].get("faction_impact", 0)) > 0:
			count += 1
	return count


func get_outbox_count() -> int:
	return _outbox.size()


func get_negative_letter_count() -> int:
	var count: int = 0
	for lt: String in LETTER_TYPES:
		if float(LETTER_TYPES[lt].get("faction_impact", 0)) < 0:
			count += 1
	return count


func get_response_rate() -> float:
	if _inbox.is_empty():
		return 0.0
	var responded: int = 0
	for l: Dictionary in _inbox:
		if bool(l.get("responded", false)):
			responded += 1
	return (float(responded) / _inbox.size()) * 100.0


func get_worst_impact_type() -> String:
	var worst: String = ""
	var worst_v: float = 0.0
	for lt: String in LETTER_TYPES:
		var v: float = float(LETTER_TYPES[lt].get("faction_impact", 0))
		if v < worst_v:
			worst_v = v
			worst = lt
	return worst


func get_inbox_health() -> String:
	var urgent: int = get_urgent_letters().size()
	if urgent == 0:
		return "Clear"
	elif urgent <= 2:
		return "Manageable"
	return "Overloaded"

func get_threat_ratio_pct() -> float:
	if _inbox.is_empty():
		return 0.0
	var neg: int = get_negative_letter_count()
	return snappedf(float(neg) / float(_inbox.size()) * 100.0, 0.1)

func get_diplomacy_tone() -> String:
	var pos: int = get_positive_letter_count()
	var neg: int = get_negative_letter_count()
	if pos > neg * 2:
		return "Friendly"
	elif pos > neg:
		return "Cordial"
	elif pos == neg:
		return "Neutral"
	return "Hostile"

func get_diplomatic_momentum() -> String:
	var pos: int = get_positive_letter_count()
	var neg: int = get_negative_letter_count()
	var total: int = pos + neg
	if total == 0:
		return "silent"
	var ratio: float = pos * 1.0 / total
	if ratio >= 0.7:
		return "warming"
	if ratio >= 0.4:
		return "stable"
	return "deteriorating"

func get_communication_density_pct() -> float:
	var inbox_sz: int = _inbox.size()
	if inbox_sz == 0:
		return 0.0
	var urgent: int = get_urgent_letters().size()
	return snapped(urgent * 100.0 / inbox_sz, 0.1)

func get_risk_weighted_backlog() -> String:
	var unread: int = 0
	var urgent_unread: int = 0
	for l: Dictionary in _inbox:
		if not l["responded"]:
			unread += 1
			if l.get("urgent", false):
				urgent_unread += 1
	if unread == 0:
		return "clear"
	if urgent_unread >= 3:
		return "critical"
	if unread >= 5:
		return "heavy"
	return "manageable"

func get_summary() -> Dictionary:
	var unread: int = 0
	for l: Dictionary in _inbox:
		if not l["responded"]:
			unread += 1
	return {
		"letter_types": LETTER_TYPES.size(),
		"inbox": _inbox.size(),
		"unread": unread,
		"urgent_count": get_urgent_letters().size(),
		"most_active_faction": get_most_active_faction(),
		"avg_impact": snapped(get_avg_faction_impact(), 0.1),
		"positive_types": get_positive_letter_count(),
		"outbox": get_outbox_count(),
		"negative_types": get_negative_letter_count(),
		"response_rate": snapped(get_response_rate(), 0.1),
		"worst_impact_type": get_worst_impact_type(),
		"inbox_health": get_inbox_health(),
		"threat_ratio_pct": get_threat_ratio_pct(),
		"diplomacy_tone": get_diplomacy_tone(),
		"diplomatic_momentum": get_diplomatic_momentum(),
		"communication_density_pct": get_communication_density_pct(),
		"risk_weighted_backlog": get_risk_weighted_backlog(),
		"diplomatic_letter_ecosystem_health": get_diplomatic_letter_ecosystem_health(),
		"correspondence_governance": get_correspondence_governance(),
		"communication_maturity_index": get_communication_maturity_index(),
	}

func get_diplomatic_letter_ecosystem_health() -> float:
	var health := get_inbox_health()
	var h_val: float = 90.0 if health in ["Healthy", "Clean"] else (60.0 if health in ["Manageable", "Moderate"] else 30.0)
	var tone := get_diplomacy_tone()
	var t_val: float = 90.0 if tone in ["Friendly", "Positive"] else (60.0 if tone in ["Neutral", "Mixed"] else 30.0)
	var momentum := get_diplomatic_momentum()
	var m_val: float = 90.0 if momentum in ["Surging", "Strong"] else (60.0 if momentum in ["Steady", "Building"] else 30.0)
	return snapped((h_val + t_val + m_val) / 3.0, 0.1)

func get_communication_maturity_index() -> float:
	var response := get_response_rate()
	var density := get_communication_density_pct()
	var threat := get_threat_ratio_pct()
	var t_val: float = maxf(100.0 - threat, 0.0)
	return snapped((response + density + t_val) / 3.0, 0.1)

func get_correspondence_governance() -> String:
	var ecosystem := get_diplomatic_letter_ecosystem_health()
	var maturity := get_communication_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _inbox.size() > 0:
		return "Nascent"
	return "Dormant"
