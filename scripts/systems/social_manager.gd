class_name SocialManager
extends RefCounted

## Manages pawn-to-pawn social relationships, opinions, and interactions.

signal interaction_happened(actor_id: int, target_id: int, interaction: String, opinion_change: int)

var _relations: Dictionary = {}
var _rng := RandomNumberGenerator.new()

const INTERACTION_TYPES: Array[Dictionary] = [
	{"name": "Chat", "opinion_min": 2, "opinion_max": 8, "weight": 40},
	{"name": "DeepTalk", "opinion_min": 5, "opinion_max": 15, "weight": 15},
	{"name": "Insult", "opinion_min": -15, "opinion_max": -5, "weight": 10},
	{"name": "Slight", "opinion_min": -8, "opinion_max": -2, "weight": 15},
	{"name": "KindWords", "opinion_min": 3, "opinion_max": 12, "weight": 20},
]


func _init() -> void:
	_rng.seed = randi()


func get_opinion(from_id: int, to_id: int) -> int:
	var key := _key(from_id, to_id)
	if not _relations.has(key):
		return 0
	var rel: Dictionary = _relations[key]
	var total: int = 0
	for mem: Dictionary in rel.get("memories", []):
		total += mem.get("opinion", 0)
	return clampi(total + rel.get("base_opinion", 0), -100, 100)


func set_base_opinion(from_id: int, to_id: int, value: int) -> void:
	var key := _key(from_id, to_id)
	if not _relations.has(key):
		_relations[key] = {"base_opinion": 0, "memories": []}
	_relations[key]["base_opinion"] = value


func add_memory(from_id: int, to_id: int, memory_name: String, opinion_value: int, duration_ticks: int = 60000) -> void:
	var key := _key(from_id, to_id)
	if not _relations.has(key):
		_relations[key] = {"base_opinion": 0, "memories": []}
	var memories: Array = _relations[key]["memories"]
	memories.append({
		"name": memory_name,
		"opinion": opinion_value,
		"ticks_left": duration_ticks,
	})


func do_random_interaction(actor: Pawn, target: Pawn) -> Dictionary:
	if actor.dead or target.dead or actor.downed or target.downed:
		return {}

	var dist := actor.grid_pos.distance_to(target.grid_pos)
	if dist > 5.0:
		return {}

	var social_skill: int = actor.get_skill_level("Social")
	var interaction := _pick_interaction(social_skill)
	var base_change: int = _rng.randi_range(interaction.opinion_min, interaction.opinion_max)

	var skill_mod: float = 1.0 + social_skill * 0.05
	var change: int = roundi(base_change * skill_mod)

	add_memory(target.id, actor.id, interaction.name, change)
	total_interactions += 1
	interaction_happened.emit(actor.id, target.id, interaction.name, change)

	if change > 8 and actor.thought_tracker:
		actor.thought_tracker.add_thought("HadGoodConversation")
	elif change < -8 and target.thought_tracker:
		target.thought_tracker.add_thought("WasInsulted")

	actor.gain_xp("Social", 10.0)

	return {"interaction": interaction.name, "opinion_change": change}


func _pick_interaction(social_skill: int) -> Dictionary:
	var total_weight: int = 0
	for it: Dictionary in INTERACTION_TYPES:
		var w: int = it.weight
		if it.name == "Insult" and social_skill > 8:
			w = maxi(1, w - social_skill)
		elif it.name == "DeepTalk" and social_skill > 5:
			w += social_skill
		total_weight += w

	var roll: int = _rng.randi_range(0, total_weight - 1)
	var acc: int = 0
	for it: Dictionary in INTERACTION_TYPES:
		var w: int = it.weight
		if it.name == "Insult" and social_skill > 8:
			w = maxi(1, w - social_skill)
		elif it.name == "DeepTalk" and social_skill > 5:
			w += social_skill
		acc += w
		if roll < acc:
			return it
	return INTERACTION_TYPES[0]


func tick_memories() -> void:
	for key: String in _relations.keys():
		var rel: Dictionary = _relations[key]
		var memories: Array = rel.get("memories", [])
		var i := memories.size() - 1
		while i >= 0:
			memories[i]["ticks_left"] = memories[i].ticks_left - 250
			if memories[i].ticks_left <= 0:
				memories.remove_at(i)
			i -= 1


var total_interactions: int = 0


func is_rival(a_id: int, b_id: int) -> bool:
	return get_opinion(a_id, b_id) < -40


func is_friend(a_id: int, b_id: int) -> bool:
	return get_opinion(a_id, b_id) > 40


func get_best_friend(pawn_id: int) -> int:
	var best_id: int = -1
	var best_op: int = 0
	for key: String in _relations.keys():
		var parts := key.split("_")
		if parts.size() != 2:
			continue
		if int(parts[0]) == pawn_id:
			var target_id: int = int(parts[1])
			var op: int = get_opinion(pawn_id, target_id)
			if op > best_op:
				best_op = op
				best_id = target_id
	return best_id


func get_worst_enemy(pawn_id: int) -> int:
	var worst_id: int = -1
	var worst_op: int = 0
	for key: String in _relations.keys():
		var parts := key.split("_")
		if parts.size() != 2:
			continue
		if int(parts[0]) == pawn_id:
			var target_id: int = int(parts[1])
			var op: int = get_opinion(pawn_id, target_id)
			if op < worst_op:
				worst_op = op
				worst_id = target_id
	return worst_id


func get_relation_summary(from_id: int, to_id: int) -> Dictionary:
	var key := _key(from_id, to_id)
	if not _relations.has(key):
		return {"opinion": 0, "memories": []}
	var rel: Dictionary = _relations[key]
	var op: int = get_opinion(from_id, to_id)
	var label: String = _opinion_label(op)
	return {
		"opinion": op,
		"label": label,
		"base_opinion": rel.get("base_opinion", 0),
		"memories": rel.get("memories", []).map(func(m: Dictionary) -> Dictionary:
			return {"name": m.name, "opinion": m.opinion}),
	}


func _opinion_label(op: int) -> String:
	if op >= 80:
		return "Adored"
	elif op >= 40:
		return "Friend"
	elif op >= 10:
		return "Likes"
	elif op > -10:
		return "Neutral"
	elif op > -40:
		return "Dislikes"
	elif op > -80:
		return "Rival"
	return "Hated"


func get_avg_interaction_weight() -> float:
	var total: float = 0.0
	for it: Dictionary in INTERACTION_TYPES:
		total += float(it.get("weight", 0))
	if INTERACTION_TYPES.is_empty():
		return 0.0
	return snappedf(total / float(INTERACTION_TYPES.size()), 0.01)

func get_negative_interaction_type_count() -> int:
	var count: int = 0
	for it: Dictionary in INTERACTION_TYPES:
		if it.get("opinion_max", 0) < 0:
			count += 1
	return count

func get_total_memory_count() -> int:
	var count: int = 0
	for key: String in _relations.keys():
		count += (_relations[key] as Dictionary).get("memories", []).size()
	return count

func get_positive_interaction_type_count() -> int:
	var count: int = 0
	for it: Dictionary in INTERACTION_TYPES:
		if it.get("opinion_min", 0) > 0:
			count += 1
	return count

func get_max_opinion_swing() -> int:
	var max_swing: int = 0
	for it: Dictionary in INTERACTION_TYPES:
		var swing: int = absi(it.get("opinion_max", 0) - it.get("opinion_min", 0))
		if swing > max_swing:
			max_swing = swing
	return max_swing

func get_unique_relation_pairs() -> int:
	return _relations.size()

func get_network_density() -> float:
	var n := _relations.size()
	return snapped(float(n) / maxf(total_interactions, 1.0) * 100.0, 0.1)

func get_hostility_ratio_pct() -> float:
	var neg_weight := 0.0
	var total_weight := 0.0
	for it in INTERACTION_TYPES:
		total_weight += it["weight"]
		if it["opinion_min"] < 0:
			neg_weight += it["weight"]
	return snapped(neg_weight / maxf(total_weight, 1.0) * 100.0, 0.1)

func get_relationship_depth() -> float:
	if _relations.is_empty():
		return 0.0
	var total_mem := 0
	for rel in _relations.values():
		total_mem += rel.get("memories", []).size()
	return snapped(float(total_mem) / float(_relations.size()), 0.01)

func get_stats() -> Dictionary:
	return {
		"total_relations": _relations.size(),
		"total_interactions": total_interactions,
		"avg_interaction_weight": get_avg_interaction_weight(),
		"negative_interaction_types": get_negative_interaction_type_count(),
		"total_memories": get_total_memory_count(),
		"positive_interaction_types": get_positive_interaction_type_count(),
		"max_opinion_swing": get_max_opinion_swing(),
		"unique_relation_pairs": get_unique_relation_pairs(),
		"network_density": get_network_density(),
		"hostility_ratio_pct": get_hostility_ratio_pct(),
		"relationship_depth": get_relationship_depth(),
	}


func _key(a: int, b: int) -> String:
	return str(a) + "_" + str(b)
