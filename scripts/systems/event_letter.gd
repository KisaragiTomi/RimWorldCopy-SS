extends Node

enum LetterType { POSITIVE, NEUTRAL, NEGATIVE, THREAT, DEATH }

var _letters: Array[Dictionary] = []
var _count_by_type: Dictionary = {}
const MAX_LETTERS: int = 50

const TYPE_COLORS: Dictionary = {
	0: "green",
	1: "white",
	2: "yellow",
	3: "red",
	4: "darkred",
}


func send_letter(title: String, body: String, letter_type: int, tick: int = 0) -> void:
	var actual_tick: int = tick
	if actual_tick == 0 and TickManager:
		actual_tick = TickManager.current_tick
	var letter: Dictionary = {
		"title": title,
		"body": body,
		"type": letter_type,
		"type_label": _type_label(letter_type),
		"color": TYPE_COLORS.get(letter_type, "white"),
		"tick": actual_tick,
		"read": false,
	}
	_letters.push_front(letter)
	if _letters.size() > MAX_LETTERS:
		_letters.resize(MAX_LETTERS)
	_count_by_type[letter_type] = _count_by_type.get(letter_type, 0) + 1
	if ColonyLog and ColonyLog.has_method("add_entry"):
		ColonyLog.add_entry("Letter", title, _severity_from_type(letter_type))


func _type_label(letter_type: int) -> String:
	var labels: Array[String] = ["Positive", "Neutral", "Negative", "Threat", "Death"]
	if letter_type >= 0 and letter_type < labels.size():
		return labels[letter_type]
	return "Unknown"


func _severity_from_type(letter_type: int) -> String:
	match letter_type:
		LetterType.POSITIVE:
			return "info"
		LetterType.NEUTRAL:
			return "info"
		LetterType.NEGATIVE:
			return "warning"
		LetterType.THREAT:
			return "danger"
		LetterType.DEATH:
			return "danger"
	return "info"


func mark_read(index: int) -> void:
	if index >= 0 and index < _letters.size():
		_letters[index].read = true


func get_unread_count() -> int:
	var count: int = 0
	for l: Dictionary in _letters:
		if not l.read:
			count += 1
	return count


func get_letters(limit: int = 10) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var max_count: int = mini(limit, _letters.size())
	for i: int in range(max_count):
		result.append(_letters[i])
	return result


func mark_all_read() -> int:
	var marked: int = 0
	for l: Dictionary in _letters:
		if not l.read:
			l.read = true
			marked += 1
	return marked


func get_letters_by_type(letter_type: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for l: Dictionary in _letters:
		if l.type == letter_type:
			result.append(l)
	return result


func get_threat_count() -> int:
	return _count_by_type.get(LetterType.THREAT, 0) + _count_by_type.get(LetterType.DEATH, 0)


func get_read_percentage() -> float:
	if _letters.is_empty():
		return 0.0
	var read_count: int = 0
	for l: Dictionary in _letters:
		if l.read:
			read_count += 1
	return snappedf(float(read_count) / float(_letters.size()) * 100.0, 0.1)


func get_most_common_type() -> String:
	var best_type: int = -1
	var best_count: int = 0
	for t: int in _count_by_type:
		if _count_by_type[t] > best_count:
			best_count = _count_by_type[t]
			best_type = t
	if best_type < 0:
		return ""
	return _type_label(best_type)


func get_latest_letter() -> Dictionary:
	if _letters.is_empty():
		return {}
	return _letters[-1]


func get_summary() -> Dictionary:
	var by_type: Dictionary = {}
	for t: int in _count_by_type:
		by_type[_type_label(t)] = _count_by_type[t]
	return {
		"total": _letters.size(),
		"unread": get_unread_count(),
		"by_type": by_type,
		"threat_count": get_threat_count(),
		"read_pct": get_read_percentage(),
		"most_common_type": get_most_common_type(),
		"latest": get_latest_letter(),
		"unique_types": by_type.size(),
		"threat_pct": snappedf(float(get_threat_count()) / maxf(float(_letters.size()), 1.0) * 100.0, 0.1),
		"inbox_health": get_inbox_health(),
		"diplomatic_tone": get_diplomatic_tone(),
		"information_processing": get_information_processing(),
		"communication_governance": get_communication_governance(),
		"intelligence_bandwidth": get_intelligence_bandwidth(),
		"diplomatic_awareness_index": get_diplomatic_awareness_index(),
	}

func get_communication_governance() -> float:
	var read := get_read_percentage()
	var threat_ratio := float(get_threat_count()) / maxf(float(_letters.size()), 1.0) * 100.0
	return snapped(read - threat_ratio * 0.3, 0.1)

func get_intelligence_bandwidth() -> float:
	var total := float(_letters.size())
	var types := float(_count_by_type.size())
	if total <= 0.0:
		return 0.0
	return snapped(types / total * 100.0, 0.1)

func get_diplomatic_awareness_index() -> String:
	var tone := get_diplomatic_tone()
	var inbox := get_inbox_health()
	if inbox == "Well Managed" and tone == "Peaceful":
		return "Perceptive"
	elif inbox == "Neglected":
		return "Oblivious"
	return "Aware"

func get_inbox_health() -> String:
	var read := get_read_percentage()
	if read >= 90.0:
		return "Well Managed"
	elif read >= 60.0:
		return "Active"
	return "Neglected"

func get_diplomatic_tone() -> String:
	var threat := get_threat_count()
	var total := _letters.size()
	if total <= 0:
		return "Neutral"
	var threat_ratio := float(threat) / float(total)
	if threat_ratio < 0.2:
		return "Peaceful"
	elif threat_ratio < 0.5:
		return "Tense"
	return "Hostile"

func get_information_processing() -> float:
	var read := get_read_percentage()
	var unread := get_unread_count()
	if unread == 0:
		return 100.0
	return snapped(read, 0.1)
