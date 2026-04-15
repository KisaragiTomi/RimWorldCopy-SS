extends Node

const CATEGORIES: Dictionary = {
	"Root": {"parent_cat": "", "children_cats": ["Resources", "Weapons", "Apparel", "Buildings", "Food", "Medicine", "Misc"]},
	"Resources": {"parent_cat": "Root", "children_cats": ["Metal", "Fabric", "Stone", "Wood"]},
	"Metal": {"parent_cat": "Resources", "children_cats": ["Steel", "Plasteel", "Gold", "Silver", "Uranium"]},
	"Fabric": {"parent_cat": "Resources", "children_cats": ["Cloth", "Devilstrand", "Hyperweave", "Synthread"]},
	"Stone": {"parent_cat": "Resources", "children_cats": ["Granite", "Marble", "Sandstone", "Slate", "Limestone"]},
	"Wood": {"parent_cat": "Resources", "children_cats": []},
	"Weapons": {"parent_cat": "Root", "children_cats": ["Ranged", "MeleeWeapons"]},
	"Ranged": {"parent_cat": "Weapons", "children_cats": ["Pistol", "Rifle", "Shotgun", "Sniper", "MiniGun"]},
	"MeleeWeapons": {"parent_cat": "Weapons", "children_cats": ["Knife", "Mace", "Sword", "Spear"]},
	"Apparel": {"parent_cat": "Root", "children_cats": ["Headgear", "Torso", "Legs"]},
	"Headgear": {"parent_cat": "Apparel", "children_cats": []},
	"Torso": {"parent_cat": "Apparel", "children_cats": []},
	"Legs": {"parent_cat": "Apparel", "children_cats": []},
	"Buildings": {"parent_cat": "Root", "children_cats": ["Production", "Furniture", "Power", "Security"]},
	"Production": {"parent_cat": "Buildings", "children_cats": []},
	"Furniture": {"parent_cat": "Buildings", "children_cats": []},
	"Power": {"parent_cat": "Buildings", "children_cats": []},
	"Security": {"parent_cat": "Buildings", "children_cats": []},
	"Food": {"parent_cat": "Root", "children_cats": ["RawFood", "Meals"]},
	"RawFood": {"parent_cat": "Food", "children_cats": []},
	"Meals": {"parent_cat": "Food", "children_cats": []},
	"Medicine": {"parent_cat": "Root", "children_cats": []},
	"Misc": {"parent_cat": "Root", "children_cats": []},
}


func get_category(cat_id: String) -> Dictionary:
	return CATEGORIES.get(cat_id, {})


func get_parent_category(cat_id: String) -> String:
	return String(CATEGORIES.get(cat_id, {}).get("parent_cat", ""))


func get_child_categories(cat_id: String) -> Array:
	return CATEGORIES.get(cat_id, {}).get("children_cats", [])


func is_descendant_of(cat_id: String, ancestor: String) -> bool:
	var current: String = cat_id
	for _i in range(10):
		if current == ancestor:
			return true
		var p: String = get_parent_category(current)
		if p.is_empty():
			return false
		current = p
	return false


func get_leaf_categories() -> Array[String]:
	var leaves: Array[String] = []
	for cid: String in CATEGORIES:
		var children: Array = CATEGORIES[cid].get("children_cats", [])
		if children.is_empty() and cid != "Root":
			leaves.append(cid)
	return leaves


func get_depth(cat_id: String) -> int:
	var depth: int = 0
	var current: String = cat_id
	for _i in range(10):
		var p: String = get_parent_category(current)
		if p.is_empty():
			break
		depth += 1
		current = p
	return depth


func get_all_descendants(cat_id: String) -> Array[String]:
	var result: Array[String] = []
	var queue: Array = [cat_id]
	for _i in range(50):
		if queue.is_empty():
			break
		var current: String = String(queue.pop_front())
		var children: Array = get_child_categories(current)
		for c in children:
			result.append(String(c))
			queue.append(String(c))
	return result


func get_max_depth() -> int:
	var max_d: int = 0
	for cid: String in CATEGORIES:
		var d: int = get_depth(cid)
		if d > max_d:
			max_d = d
	return max_d


func get_avg_children() -> float:
	if CATEGORIES.is_empty():
		return 0.0
	var total: int = 0
	for cid: String in CATEGORIES:
		total += get_child_categories(cid).size()
	return snappedf(float(total) / float(CATEGORIES.size()), 0.1)


func get_branch_count() -> int:
	return CATEGORIES.size() - get_leaf_categories().size()


func get_depth_distribution() -> Dictionary:
	var dist: Dictionary = {}
	for cid: String in CATEGORIES:
		var d: int = get_depth(cid)
		var key: String = str(d)
		dist[key] = dist.get(key, 0) + 1
	return dist


func get_widest_level() -> int:
	var dist := get_depth_distribution()
	var best_depth: int = 0
	var best_count: int = 0
	for d: String in dist:
		if dist[d] > best_count:
			best_count = dist[d]
			best_depth = int(d)
	return best_depth


func get_leaf_pct() -> float:
	if CATEGORIES.is_empty():
		return 0.0
	return snappedf(float(get_leaf_categories().size()) / float(CATEGORIES.size()) * 100.0, 0.1)


func get_taxonomy_complexity() -> String:
	var depth: int = get_max_depth()
	if depth >= 5:
		return "Deep"
	elif depth >= 3:
		return "Moderate"
	elif depth >= 1:
		return "Shallow"
	return "Flat"

func get_balance_score() -> float:
	if get_branch_count() == 0:
		return 0.0
	var avg: float = get_avg_children()
	var max_children: int = 0
	for cid: String in CATEGORIES:
		var children: Array = get_child_categories(cid)
		if children.size() > max_children:
			max_children = children.size()
	if max_children == 0:
		return 100.0
	return snappedf((1.0 - absf(avg - float(max_children)) / float(max_children)) * 100.0, 0.1)

func get_pruning_potential_pct() -> float:
	var leaves: int = get_leaf_categories().size()
	var total: int = CATEGORIES.size()
	if total == 0:
		return 0.0
	var single_child: int = 0
	for cid: String in CATEGORIES:
		var children: Array = get_child_categories(cid)
		if children.size() == 1:
			single_child += 1
	return snappedf(float(single_child) / float(total) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"total_categories": CATEGORIES.size(),
		"root_children": get_child_categories("Root").size(),
		"leaf_count": get_leaf_categories().size(),
		"max_depth": get_max_depth(),
		"avg_children": get_avg_children(),
		"branch_count": get_branch_count(),
		"depth_distribution": get_depth_distribution(),
		"widest_level": get_widest_level(),
		"leaf_pct": get_leaf_pct(),
		"taxonomy_complexity": get_taxonomy_complexity(),
		"balance_score": get_balance_score(),
		"pruning_potential_pct": get_pruning_potential_pct(),
		"hierarchy_depth_rating": get_hierarchy_depth_rating(),
		"organizational_efficiency": get_organizational_efficiency(),
		"taxonomy_maturity": get_taxonomy_maturity(),
		"classification_ecosystem_health": get_classification_ecosystem_health(),
		"structural_coherence_index": get_structural_coherence_index(),
		"ontological_governance": get_ontological_governance(),
	}

func get_hierarchy_depth_rating() -> String:
	var depth := get_max_depth()
	if depth >= 5:
		return "Deep"
	elif depth >= 3:
		return "Moderate"
	elif depth > 0:
		return "Shallow"
	return "Flat"

func get_organizational_efficiency() -> float:
	var balance := get_balance_score()
	var pruning := get_pruning_potential_pct()
	return snapped(maxf(balance - pruning, 0.0), 0.1)

func get_taxonomy_maturity() -> String:
	var leaves := get_leaf_categories().size()
	var branches := get_branch_count()
	if branches >= 5 and leaves >= 10:
		return "Mature"
	elif branches >= 2:
		return "Growing"
	return "Nascent"

func get_classification_ecosystem_health() -> float:
	var efficiency := get_organizational_efficiency()
	var balance := get_balance_score()
	var maturity := get_taxonomy_maturity()
	var m_val: float = 90.0 if maturity == "Mature" else (60.0 if maturity == "Growing" else 30.0)
	return snapped((efficiency + balance + m_val) / 3.0, 0.1)

func get_structural_coherence_index() -> float:
	var depth := get_max_depth()
	var pruning := get_pruning_potential_pct()
	var leaf_pct := get_leaf_pct()
	return snapped((minf(float(depth) * 20.0, 100.0) + maxf(100.0 - pruning, 0.0) + leaf_pct) / 3.0, 0.1)

func get_ontological_governance() -> String:
	var health := get_classification_ecosystem_health()
	var coherence := get_structural_coherence_index()
	if health >= 65.0 and coherence >= 60.0:
		return "Well Governed"
	elif health >= 35.0 or coherence >= 35.0:
		return "Developing"
	return "Chaotic"
