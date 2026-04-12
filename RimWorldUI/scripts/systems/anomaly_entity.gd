extends Node

var _entities: Dictionary = {}
var _next_id: int = 0

const ENTITY_TYPES: Dictionary = {
	"Revenant": {"threat_level": 3, "hp": 300, "speed": 6.0, "attack": 25, "special": "phase_through_walls"},
	"Noctol": {"threat_level": 2, "hp": 150, "speed": 5.5, "attack": 18, "special": "invisible_in_dark"},
	"Devourer": {"threat_level": 4, "hp": 500, "speed": 3.0, "attack": 40, "special": "consume_corpse"},
	"Metalhorror": {"threat_level": 3, "hp": 250, "speed": 4.5, "attack": 30, "special": "hide_in_pawn"},
	"FleshBeast": {"threat_level": 2, "hp": 200, "speed": 4.0, "attack": 20, "special": "split_on_death"},
	"GoldenCube": {"threat_level": 1, "hp": 9999, "speed": 0.0, "attack": 0, "special": "psychic_influence"},
	"Sightstealers": {"threat_level": 3, "hp": 180, "speed": 5.0, "attack": 22, "special": "blind_on_hit"},
	"PitGate": {"threat_level": 5, "hp": 9999, "speed": 0.0, "attack": 0, "special": "spawn_horrors"},
	"FleshmassNucleus": {"threat_level": 4, "hp": 400, "speed": 1.0, "attack": 0, "special": "grow_fleshmass"},
	"Duplicator": {"threat_level": 3, "hp": 200, "speed": 4.0, "attack": 15, "special": "copy_pawn_appearance"}
}

func spawn_entity(entity_type: String) -> Dictionary:
	if not ENTITY_TYPES.has(entity_type):
		return {"error": "unknown_entity"}
	var eid: int = _next_id
	_next_id += 1
	_entities[eid] = {"type": entity_type, "alive": true, "contained": false}
	return {"entity_id": eid, "type": entity_type, "threat": ENTITY_TYPES[entity_type]["threat_level"]}

func kill_entity(entity_id: int) -> bool:
	if _entities.has(entity_id):
		_entities[entity_id]["alive"] = false
		return true
	return false

func get_highest_threat_entity() -> String:
	var best: String = ""
	var best_t: int = 0
	for e: String in ENTITY_TYPES:
		var t: int = int(ENTITY_TYPES[e].get("threat_level", 0))
		if t > best_t:
			best_t = t
			best = e
	return best


func get_alive_by_type() -> Dictionary:
	var dist: Dictionary = {}
	for eid: int in _entities:
		if bool(_entities[eid].get("alive", false)):
			var t: String = String(_entities[eid].get("type", ""))
			dist[t] = int(dist.get(t, 0)) + 1
	return dist


func get_contained_count() -> int:
	var count: int = 0
	for eid: int in _entities:
		if bool(_entities[eid].get("contained", false)):
			count += 1
	return count


func get_avg_threat_level() -> float:
	if ENTITY_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for et: String in ENTITY_TYPES:
		total += float(ENTITY_TYPES[et].get("threat_level", 0))
	return total / ENTITY_TYPES.size()


func get_dead_count() -> int:
	var count: int = 0
	for eid: int in _entities:
		if not bool(_entities[eid].get("alive", true)):
			count += 1
	return count


func get_lowest_threat_entity() -> String:
	var best: String = ""
	var best_threat: int = 999
	for et: String in ENTITY_TYPES:
		var t: int = int(ENTITY_TYPES[et].get("threat_level", 999))
		if t < best_threat:
			best_threat = t
			best = et
	return best


func get_immobile_entity_count() -> int:
	var count: int = 0
	for et: String in ENTITY_TYPES:
		if float(ENTITY_TYPES[et].get("speed", 1.0)) <= 0.0:
			count += 1
	return count


func get_total_hp_pool() -> int:
	var total: int = 0
	for et: String in ENTITY_TYPES:
		total += int(ENTITY_TYPES[et].get("hp", 0))
	return total


func get_unique_special_count() -> int:
	var specials: Dictionary = {}
	for et: String in ENTITY_TYPES:
		var s: String = String(ENTITY_TYPES[et].get("special", ""))
		if s != "":
			specials[s] = true
	return specials.size()


func get_containment_status() -> String:
	var contained: int = get_contained_count()
	var alive: int = 0
	for eid: int in _entities:
		if _entities[eid]["alive"]:
			alive += 1
	if alive == 0:
		return "AllClear"
	var ratio: float = float(contained) / float(alive)
	if ratio >= 0.9:
		return "Secured"
	if ratio >= 0.5:
		return "PartialControl"
	return "Loose"


func get_lethality_index_pct() -> float:
	var dead: int = get_dead_count()
	var total: int = _entities.size()
	if total == 0:
		return 0.0
	return snappedf(float(dead) / float(total) * 100.0, 0.1)


func get_research_potential() -> String:
	var specials: int = get_unique_special_count()
	if specials >= 5:
		return "Rich"
	if specials >= 2:
		return "Moderate"
	return "Limited"


func get_summary() -> Dictionary:
	var alive: int = 0
	for eid: int in _entities:
		if _entities[eid]["alive"]:
			alive += 1
	return {
		"entity_types": ENTITY_TYPES.size(),
		"spawned_total": _entities.size(),
		"alive": alive,
		"contained": get_contained_count(),
		"highest_threat": get_highest_threat_entity(),
		"avg_threat": snapped(get_avg_threat_level(), 0.1),
		"dead": get_dead_count(),
		"lowest_threat": get_lowest_threat_entity(),
		"immobile_entities": get_immobile_entity_count(),
		"total_hp_pool": get_total_hp_pool(),
		"unique_specials": get_unique_special_count(),
		"containment_status": get_containment_status(),
		"lethality_index_pct": get_lethality_index_pct(),
		"research_potential": get_research_potential(),
		"anomaly_severity_tier": get_anomaly_severity_tier(),
		"containment_breach_risk": get_containment_breach_risk(),
		"specimen_diversity": get_specimen_diversity(),
		"anomaly_ecosystem_health": get_anomaly_ecosystem_health(),
		"entity_governance": get_entity_governance(),
		"eldritch_maturity_index": get_eldritch_maturity_index(),
	}

func get_anomaly_severity_tier() -> String:
	var avg := get_avg_threat_level()
	if avg >= 80.0:
		return "Apocalyptic"
	elif avg >= 50.0:
		return "Severe"
	elif avg > 0.0:
		return "Moderate"
	return "None"

func get_containment_breach_risk() -> String:
	var contained := get_contained_count()
	var alive := 0
	for eid: int in _entities:
		if _entities[eid]["alive"]:
			alive += 1
	if alive > 0 and contained < alive:
		return "Critical"
	elif alive > 0:
		return "Monitored"
	return "Clear"

func get_specimen_diversity() -> float:
	var specials := get_unique_special_count()
	var total := ENTITY_TYPES.size()
	if total <= 0:
		return 0.0
	return snapped(float(specials) / float(total) * 100.0, 0.1)

func get_anomaly_ecosystem_health() -> float:
	var severity := get_anomaly_severity_tier()
	var s_val: float = 90.0 if severity in ["Apocalyptic", "Extreme"] else (60.0 if severity in ["Severe", "Moderate"] else 30.0)
	var breach := get_containment_breach_risk()
	var b_val: float = 20.0 if breach == "Critical" else (60.0 if breach == "Monitored" else 90.0)
	var diversity := get_specimen_diversity()
	return snapped((s_val + b_val + diversity) / 3.0, 0.1)

func get_eldritch_maturity_index() -> float:
	var lethality := get_lethality_index_pct()
	var research := get_research_potential()
	var r_val: float = 90.0 if research in ["Rich", "Immense"] else (60.0 if research in ["Moderate", "Some"] else 30.0)
	var status := get_containment_status()
	var st_val: float = 90.0 if status in ["Fully Contained", "Secure"] else (60.0 if status in ["Partial", "Monitored"] else 30.0)
	return snapped((lethality + r_val + st_val) / 3.0, 0.1)

func get_entity_governance() -> String:
	var ecosystem := get_anomaly_ecosystem_health()
	var maturity := get_eldritch_maturity_index()
	if ecosystem >= 70.0 and maturity >= 60.0:
		return "Exemplary"
	elif ecosystem >= 40.0 or maturity >= 30.0:
		return "Developing"
	elif _entities.size() > 0:
		return "Nascent"
	return "Dormant"
