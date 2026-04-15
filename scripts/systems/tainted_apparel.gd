extends Node

var _tainted_items: Dictionary = {}

const TAINT_MOOD_PENALTY: float = -3.0
const TAINT_VALUE_FACTOR: float = 0.5

const TAINT_SOURCES: Dictionary = {
	"CorpseLoot": {"mood_penalty": -3.0, "can_clean": false},
	"FallenColonist": {"mood_penalty": -5.0, "can_clean": false},
	"PirateStrip": {"mood_penalty": -3.0, "can_clean": false},
	"ToxicExposure": {"mood_penalty": -2.0, "can_clean": true, "clean_work": 200},
	"BloodStained": {"mood_penalty": -1.0, "can_clean": true, "clean_work": 100}
}

func mark_tainted(item_id: int, source: String) -> Dictionary:
	if not TAINT_SOURCES.has(source):
		return {"error": "unknown_source"}
	_tainted_items[item_id] = {"source": source, "tainted": true}
	return {"item_id": item_id, "source": source, "mood_penalty": TAINT_SOURCES[source]["mood_penalty"]}

func is_tainted(item_id: int) -> bool:
	return _tainted_items.get(item_id, {}).get("tainted", false)

func get_mood_penalty(item_id: int) -> float:
	if not is_tainted(item_id):
		return 0.0
	var source: String = _tainted_items[item_id]["source"]
	return TAINT_SOURCES.get(source, {}).get("mood_penalty", TAINT_MOOD_PENALTY)

func clean_item(item_id: int) -> Dictionary:
	if not is_tainted(item_id):
		return {"error": "not_tainted"}
	var source: String = _tainted_items[item_id]["source"]
	var info: Dictionary = TAINT_SOURCES.get(source, {})
	if not info.get("can_clean", false):
		return {"error": "cannot_clean"}
	_tainted_items.erase(item_id)
	return {"cleaned": true, "work": info.get("clean_work", 100)}

func get_cleanable_count() -> int:
	var count: int = 0
	for iid: int in _tainted_items:
		var src: String = String(_tainted_items[iid].get("source", ""))
		if bool(TAINT_SOURCES.get(src, {}).get("can_clean", false)):
			count += 1
	return count


func get_taint_source_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for iid: int in _tainted_items:
		var src: String = String(_tainted_items[iid].get("source", ""))
		dist[src] = int(dist.get(src, 0)) + 1
	return dist


func get_worst_source() -> String:
	var worst: String = ""
	var worst_pen: float = 0.0
	for src: String in TAINT_SOURCES:
		var pen: float = absf(float(TAINT_SOURCES[src].get("mood_penalty", 0.0)))
		if pen > worst_pen:
			worst_pen = pen
			worst = src
	return worst


func get_unclearable_count() -> int:
	return _tainted_items.size() - get_cleanable_count()


func get_source_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for iid: int in _tainted_items:
		var s: String = String(_tainted_items[iid].get("source", ""))
		dist[s] = dist.get(s, 0) + 1
	return dist


func get_most_common_source() -> String:
	var dist: Dictionary = get_source_distribution()
	var best: String = ""
	var best_count: int = 0
	for s: String in dist:
		if int(dist[s]) > best_count:
			best_count = int(dist[s])
			best = s
	return best


func get_avg_mood_penalty() -> float:
	if TAINT_SOURCES.is_empty():
		return 0.0
	var total: float = 0.0
	for src: String in TAINT_SOURCES:
		total += float(TAINT_SOURCES[src].get("mood_penalty", 0.0))
	return snappedf(total / float(TAINT_SOURCES.size()), 0.1)


func get_total_clean_work() -> int:
	var total: int = 0
	for iid: int in _tainted_items:
		var src: String = String(_tainted_items[iid].get("source", ""))
		var info: Dictionary = TAINT_SOURCES.get(src, {})
		if bool(info.get("can_clean", false)):
			total += int(info.get("clean_work", 0))
	return total


func get_unique_sources_present() -> int:
	var sources: Dictionary = {}
	for iid: int in _tainted_items:
		sources[String(_tainted_items[iid].get("source", ""))] = true
	return sources.size()


func get_contamination_severity() -> String:
	var avg: float = get_avg_mood_penalty()
	if avg <= -10.0:
		return "Severe"
	elif avg <= -5.0:
		return "Moderate"
	elif avg <= -2.0:
		return "Mild"
	return "Negligible"

func get_decontamination_feasibility() -> String:
	if _tainted_items.is_empty():
		return "N/A"
	var pct: float = float(get_cleanable_count()) / float(_tainted_items.size())
	if pct >= 0.8:
		return "Easy"
	elif pct >= 0.5:
		return "Manageable"
	elif pct >= 0.2:
		return "Difficult"
	return "Impossible"

func get_morale_impact_pct() -> float:
	if _tainted_items.is_empty():
		return 0.0
	var unclearable: int = get_unclearable_count()
	return snappedf(float(unclearable) / float(_tainted_items.size()) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"taint_sources": TAINT_SOURCES.size(),
		"tainted_items": _tainted_items.size(),
		"cleanable": get_cleanable_count(),
		"worst_source": get_worst_source(),
		"unclearable": get_unclearable_count(),
		"most_common_src": get_most_common_source(),
		"avg_mood_penalty": get_avg_mood_penalty(),
		"total_clean_work": get_total_clean_work(),
		"unique_sources": get_unique_sources_present(),
		"contamination_severity": get_contamination_severity(),
		"decontamination_feasibility": get_decontamination_feasibility(),
		"morale_impact_pct": get_morale_impact_pct(),
		"wardrobe_contamination_rate": get_wardrobe_contamination_rate(),
		"cleaning_priority": get_cleaning_priority(),
		"colony_hygiene_score": get_colony_hygiene_score(),
		"sanitation_ecosystem_health": get_sanitation_ecosystem_health(),
		"hygiene_governance": get_hygiene_governance(),
		"contamination_maturity_index": get_contamination_maturity_index(),
	}

func get_wardrobe_contamination_rate() -> float:
	var tainted := _tainted_items.size()
	var cleanable := get_cleanable_count()
	if tainted <= 0:
		return 0.0
	return snapped(float(tainted - cleanable) / float(tainted) * 100.0, 0.1)

func get_cleaning_priority() -> String:
	var penalty := get_avg_mood_penalty()
	if penalty >= 10.0:
		return "Urgent"
	elif penalty >= 5.0:
		return "Moderate"
	elif penalty > 0.0:
		return "Low"
	return "None"

func get_colony_hygiene_score() -> float:
	var total := _tainted_items.size()
	var unclearable := get_unclearable_count()
	if total <= 0:
		return 100.0
	return snapped((1.0 - float(unclearable) / float(total)) * 100.0, 0.1)

func get_sanitation_ecosystem_health() -> float:
	var hygiene := get_colony_hygiene_score()
	var feasibility := get_decontamination_feasibility()
	var f_val: float = 90.0 if feasibility == "Easy" else (60.0 if feasibility == "Moderate" else 25.0)
	var severity := get_contamination_severity()
	var s_val: float = 90.0 if severity == "Mild" else (50.0 if severity == "Moderate" else 15.0)
	return snapped((hygiene + f_val + s_val) / 3.0, 0.1)

func get_hygiene_governance() -> String:
	var ecosystem := get_sanitation_ecosystem_health()
	var priority := get_cleaning_priority()
	var p_val: float = 90.0 if priority == "None" else (60.0 if priority == "Low" else 25.0)
	var combined := (ecosystem + p_val) / 2.0
	if combined >= 70.0:
		return "Pristine"
	elif combined >= 40.0:
		return "Acceptable"
	elif _tainted_items.size() > 0:
		return "Contaminated"
	return "Clean"

func get_contamination_maturity_index() -> float:
	var contamination := get_wardrobe_contamination_rate()
	var morale := get_morale_impact_pct()
	return snapped((100.0 - contamination + 100.0 - morale) / 2.0, 0.1)
