extends Node

var _clusters: Dictionary = {}
var _next_id: int = 0

const MECH_TYPES: Dictionary = {
	"Centipede": {"hp": 400, "armor": 0.6, "damage": 25, "range": 30, "speed": 2.0},
	"Lancer": {"hp": 180, "armor": 0.3, "damage": 35, "range": 40, "speed": 4.5},
	"Scyther": {"hp": 200, "armor": 0.35, "damage": 20, "range": 1, "speed": 5.5},
	"Pikeman": {"hp": 100, "armor": 0.2, "damage": 30, "range": 35, "speed": 4.0},
	"Termite": {"hp": 350, "armor": 0.55, "damage": 40, "range": 8, "speed": 2.5},
	"Tunneler": {"hp": 300, "armor": 0.45, "damage": 18, "range": 1, "speed": 3.0}
}

const CLUSTER_BUILDINGS: Dictionary = {
	"AutoMortar": {"hp": 200, "damage": 40, "range": 50, "fire_rate": 0.1},
	"ShieldGenerator": {"hp": 150, "radius": 10, "block_projectile": true},
	"Assembler": {"hp": 120, "spawn_interval": 300, "spawn_type": "Scyther"},
	"ProximityActivator": {"hp": 80, "radius": 15, "wakes_on_approach": true},
	"PsychicDroner": {"hp": 100, "mood_penalty": -12, "radius": 999}
}

func spawn_cluster(threat_points: float) -> Dictionary:
	var cid: int = _next_id
	_next_id += 1
	var mechs: Array = []
	var remaining: float = threat_points
	var mech_names: Array = MECH_TYPES.keys()
	while remaining > 50:
		var chosen: String = mech_names[randi() % mech_names.size()]
		var cost: float = MECH_TYPES[chosen]["hp"] * 0.5
		if cost <= remaining:
			mechs.append(chosen)
			remaining -= cost
	var buildings: Array = []
	var bld_names: Array = CLUSTER_BUILDINGS.keys()
	if threat_points > 300:
		buildings.append(bld_names[randi() % bld_names.size()])
	_clusters[cid] = {"mechs": mechs, "buildings": buildings, "active": true}
	return {"cluster_id": cid, "mechs": mechs.size(), "buildings": buildings.size()}

func destroy_cluster(cluster_id: int) -> bool:
	if _clusters.has(cluster_id):
		_clusters[cluster_id]["active"] = false
		return true
	return false

func get_total_mech_count() -> int:
	var total: int = 0
	for cid: int in _clusters:
		if bool(_clusters[cid].get("active", false)):
			total += _clusters[cid].get("mechs", []).size()
	return total


func get_strongest_mech() -> String:
	var best: String = ""
	var best_hp: int = 0
	for m: String in MECH_TYPES:
		var hp: int = int(MECH_TYPES[m].get("hp", 0))
		if hp > best_hp:
			best_hp = hp
			best = m
	return best


func get_destroyed_count() -> int:
	var count: int = 0
	for cid: int in _clusters:
		if not bool(_clusters[cid].get("active", true)):
			count += 1
	return count


func get_avg_mechs_per_cluster() -> float:
	var active_count: int = 0
	var total_mechs: int = 0
	for cid: int in _clusters:
		if bool(_clusters[cid].get("active", false)):
			active_count += 1
			total_mechs += _clusters[cid].get("mechs", []).size()
	if active_count == 0:
		return 0.0
	return float(total_mechs) / active_count


func get_total_building_count() -> int:
	var total: int = 0
	for cid: int in _clusters:
		if bool(_clusters[cid].get("active", false)):
			total += _clusters[cid].get("buildings", []).size()
	return total


func get_weakest_mech() -> String:
	var worst: String = ""
	var worst_hp: int = 99999
	for m: String in MECH_TYPES:
		var hp: int = int(MECH_TYPES[m].get("hp", 0))
		if hp < worst_hp:
			worst_hp = hp
			worst = m
	return worst


func get_ranged_mech_count() -> int:
	var count: int = 0
	for m: String in MECH_TYPES:
		if int(MECH_TYPES[m].get("range", 0)) > 1:
			count += 1
	return count


func get_avg_mech_hp() -> float:
	if MECH_TYPES.is_empty():
		return 0.0
	var total: float = 0.0
	for m: String in MECH_TYPES:
		total += float(MECH_TYPES[m].get("hp", 0))
	return snappedf(total / float(MECH_TYPES.size()), 0.1)


func get_shield_building_count() -> int:
	var count: int = 0
	for b: String in CLUSTER_BUILDINGS:
		if CLUSTER_BUILDINGS[b].has("block_projectile"):
			count += 1
	return count


func get_cluster_threat_level() -> String:
	var total: int = get_total_mech_count()
	if total >= 30:
		return "Apocalyptic"
	elif total >= 15:
		return "Severe"
	elif total >= 5:
		return "Moderate"
	elif total >= 1:
		return "Minor"
	return "None"

func get_firepower_ratio_pct() -> float:
	var total: int = get_total_mech_count()
	if total == 0:
		return 0.0
	return snappedf(float(get_ranged_mech_count()) / float(total) * 100.0, 0.1)

func get_fortification_score() -> String:
	var shields: int = get_shield_building_count()
	var buildings: int = get_total_building_count()
	if buildings == 0:
		return "None"
	var pct: float = float(shields) / float(buildings)
	if pct >= 0.4:
		return "Fortress"
	elif pct >= 0.2:
		return "Fortified"
	elif pct >= 0.05:
		return "Light"
	return "Exposed"

func get_summary() -> Dictionary:
	var active: int = 0
	for cid: int in _clusters:
		if _clusters[cid]["active"]:
			active += 1
	return {
		"mech_types": MECH_TYPES.size(),
		"building_types": CLUSTER_BUILDINGS.size(),
		"active_clusters": active,
		"total_mechs": get_total_mech_count(),
		"strongest": get_strongest_mech(),
		"avg_mechs": snapped(get_avg_mechs_per_cluster(), 0.1),
		"total_buildings": get_total_building_count(),
		"weakest": get_weakest_mech(),
		"ranged_mechs": get_ranged_mech_count(),
		"avg_mech_hp": get_avg_mech_hp(),
		"shield_buildings": get_shield_building_count(),
		"threat_level": get_cluster_threat_level(),
		"firepower_ratio_pct": get_firepower_ratio_pct(),
		"fortification_score": get_fortification_score(),
		"mechanoid_swarm_density": get_mechanoid_swarm_density(),
		"armor_penetration_need": get_armor_penetration_need(),
		"cluster_elimination_difficulty": get_cluster_elimination_difficulty(),
		"mech_threat_ecosystem_health": get_mech_threat_ecosystem_health(),
		"mechanoid_governance": get_mechanoid_governance(),
		"combat_preparedness_index": get_combat_preparedness_index(),
	}

func get_mechanoid_swarm_density() -> float:
	var total := get_total_mech_count()
	var clusters := _clusters.size()
	if clusters <= 0:
		return 0.0
	return snapped(float(total) / float(clusters), 0.1)

func get_armor_penetration_need() -> String:
	var avg_hp := get_avg_mech_hp()
	if avg_hp >= 200.0:
		return "Anti-Armor Required"
	elif avg_hp >= 100.0:
		return "Standard"
	return "Light Arms Sufficient"

func get_cluster_elimination_difficulty() -> String:
	var threat := get_cluster_threat_level()
	var shields := get_shield_building_count()
	if threat in ["Extreme", "Critical"] and shields >= 2:
		return "Nightmare"
	elif threat in ["High", "Extreme"]:
		return "Hard"
	return "Manageable"

func get_mech_threat_ecosystem_health() -> float:
	var density := get_mechanoid_swarm_density()
	var firepower := get_firepower_ratio_pct()
	var fortification := get_fortification_score()
	var f_val: float = 90.0 if fortification == "Fortress" else (60.0 if fortification == "Fortified" else 25.0)
	return snapped((minf(density * 10.0, 100.0) + firepower + f_val) / 3.0, 0.1)

func get_mechanoid_governance() -> String:
	var ecosystem := get_mech_threat_ecosystem_health()
	var difficulty := get_cluster_elimination_difficulty()
	var d_val: float = 90.0 if difficulty == "Nightmare" else (60.0 if difficulty == "Hard" else 30.0)
	var combined := (ecosystem + d_val) / 2.0
	if combined >= 70.0:
		return "Existential Threat"
	elif combined >= 40.0:
		return "Significant Threat"
	elif _clusters.size() > 0:
		return "Minor Threat"
	return "Clear"

func get_combat_preparedness_index() -> float:
	var armor := get_armor_penetration_need()
	var a_val: float = 90.0 if armor == "Anti-Armor Required" else (60.0 if armor == "Standard" else 30.0)
	var threat := get_cluster_threat_level()
	var t_val: float = 90.0 if threat in ["Extreme", "Apocalyptic", "Critical"] else (60.0 if threat == "High" else 30.0)
	return snapped((a_val + t_val) / 2.0, 0.1)
