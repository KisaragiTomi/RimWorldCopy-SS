extends Node

enum Relation { PARENT, CHILD, SIBLING, LOVER, SPOUSE, EX_SPOUSE, EX_LOVER }

var _relations: Dictionary = {}


func add_relation(pawn_a: int, pawn_b: int, rel: Relation) -> void:
	if not _relations.has(pawn_a):
		_relations[pawn_a] = []
	if not _relations.has(pawn_b):
		_relations[pawn_b] = []
	_relations[pawn_a].append({"target": pawn_b, "type": rel})
	var inverse: Relation = _get_inverse(rel)
	_relations[pawn_b].append({"target": pawn_a, "type": inverse})


func _get_inverse(rel: Relation) -> Relation:
	match rel:
		Relation.PARENT:
			return Relation.CHILD
		Relation.CHILD:
			return Relation.PARENT
		Relation.LOVER:
			return Relation.LOVER
		Relation.SPOUSE:
			return Relation.SPOUSE
		Relation.EX_SPOUSE:
			return Relation.EX_SPOUSE
		Relation.EX_LOVER:
			return Relation.EX_LOVER
		_:
			return rel


func get_relations(pawn_id: int) -> Array:
	return _relations.get(pawn_id, [])


func has_relation(pawn_a: int, pawn_b: int, rel: Relation) -> bool:
	var rels: Array = get_relations(pawn_a)
	for r in rels:
		var rd: Dictionary = r if r is Dictionary else {}
		if int(rd.get("target", -1)) == pawn_b and int(rd.get("type", -1)) == rel:
			return true
	return false


func get_family_members(pawn_id: int) -> Array:
	var rels: Array = get_relations(pawn_id)
	var family: Array = []
	for r in rels:
		var rd: Dictionary = r if r is Dictionary else {}
		var t: int = int(rd.get("type", -1))
		if t in [Relation.PARENT, Relation.CHILD, Relation.SIBLING, Relation.SPOUSE]:
			family.append(rd)
	return family


func get_opinion_modifier(pawn_a: int, pawn_b: int) -> float:
	var rels: Array = get_relations(pawn_a)
	var total: float = 0.0
	for r in rels:
		var rd: Dictionary = r if r is Dictionary else {}
		if int(rd.get("target", -1)) != pawn_b:
			continue
		match int(rd.get("type", -1)):
			Relation.PARENT: total += 15.0
			Relation.CHILD: total += 20.0
			Relation.SIBLING: total += 10.0
			Relation.SPOUSE: total += 30.0
			Relation.LOVER: total += 25.0
			Relation.EX_SPOUSE: total -= 15.0
			Relation.EX_LOVER: total -= 10.0
	return total


func get_total_relations() -> int:
	var total: int = 0
	for pid: int in _relations:
		total += _relations[pid].size()
	return total / 2


func get_relation_counts() -> Dictionary:
	var counts: Dictionary = {}
	var labels: Array[String] = ["Parent", "Child", "Sibling", "Lover", "Spouse", "ExSpouse", "ExLover"]
	for pid: int in _relations:
		for r in _relations[pid]:
			var rd: Dictionary = r if r is Dictionary else {}
			var t: int = int(rd.get("type", 0))
			if t >= 0 and t < labels.size():
				var lbl: String = labels[t]
				counts[lbl] = counts.get(lbl, 0) + 1
	for key: String in counts:
		counts[key] = counts[key] / 2
	return counts


func get_most_connected_pawn() -> Dictionary:
	var best_id: int = -1
	var best_count: int = 0
	for pid: int in _relations:
		if _relations[pid].size() > best_count:
			best_count = _relations[pid].size()
			best_id = pid
	if best_id < 0:
		return {}
	return {"pawn_id": best_id, "relation_count": best_count}


func get_avg_relations_per_pawn() -> float:
	if _relations.is_empty():
		return 0.0
	return snappedf(float(get_total_relations()) / float(_relations.size()), 0.1)


func get_isolated_pawn_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var pid: int = p.pawn_id if "pawn_id" in p else 0
		if not _relations.has(pid):
			count += 1
	return count


func get_most_common_relation_type() -> String:
	var counts := get_relation_counts()
	var best: String = ""
	var best_n: int = 0
	for t: String in counts:
		if counts[t] > best_n:
			best_n = counts[t]
			best = t
	return best


func get_summary() -> Dictionary:
	return {
		"pawns_with_relations": _relations.size(),
		"relation_types": 7,
		"total_relations": get_total_relations(),
		"relation_counts": get_relation_counts(),
		"most_connected": get_most_connected_pawn(),
		"avg_relations": get_avg_relations_per_pawn(),
		"isolated_pawns": get_isolated_pawn_count(),
		"most_common_type": get_most_common_relation_type(),
		"isolation_pct": snappedf(float(get_isolated_pawn_count()) / maxf(float(_relations.size() + get_isolated_pawn_count()), 1.0) * 100.0, 0.1),
		"active_relation_types": get_relation_counts().size(),
		"kinship_network_strength": get_kinship_network_strength(),
		"social_cohesion": get_social_cohesion(),
		"family_depth": get_family_depth(),
		"kinship_ecosystem_depth": get_kinship_ecosystem_depth(),
		"social_network_resilience": get_social_network_resilience(),
		"intergenerational_strength": get_intergenerational_strength(),
	}

func get_kinship_ecosystem_depth() -> float:
	var types := float(get_relation_counts().size())
	var avg := get_avg_relations_per_pawn()
	return snapped(types * avg * 10.0, 0.1)

func get_social_network_resilience() -> float:
	var isolated := float(get_isolated_pawn_count())
	var total := float(_relations.size() + get_isolated_pawn_count())
	if total <= 0.0:
		return 0.0
	return snapped((1.0 - isolated / total) * 100.0, 0.1)

func get_intergenerational_strength() -> String:
	var depth := get_family_depth()
	var cohesion := get_social_cohesion()
	if depth in ["Deep", "Rich"] and cohesion in ["Strong", "Tight-knit"]:
		return "Enduring"
	elif depth in ["None", "Shallow"]:
		return "Fragile"
	return "Growing"

func get_kinship_network_strength() -> String:
	var avg := get_avg_relations_per_pawn()
	if avg >= 3.0:
		return "Strong"
	elif avg >= 1.5:
		return "Moderate"
	elif avg > 0.0:
		return "Weak"
	return "None"

func get_social_cohesion() -> float:
	var isolated := get_isolated_pawn_count()
	var total := _relations.size() + isolated
	if total <= 0:
		return 0.0
	return snapped((1.0 - float(isolated) / float(total)) * 100.0, 0.1)

func get_family_depth() -> String:
	var types := get_relation_counts()
	var has_parent: bool = types.has("parent") and int(types.get("parent", 0)) > 0
	var has_sibling: bool = types.has("sibling") and int(types.get("sibling", 0)) > 0
	if has_parent and has_sibling:
		return "Multi-Generational"
	elif has_parent or has_sibling:
		return "Single Generation"
	return "Sparse"
