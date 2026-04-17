class_name JobGiverCraft
extends ThinkNode

## Issues a Craft job when queue has items, materials available, and bench exists.

const BENCH_DEFS: PackedStringArray = [
	"CraftingSpot", "TailoringBench", "Smithy", "MachiningTable", "FabricationBench",
	"StonecuttersTable", "DrugLab", "BreweryVat", "AdvancedComponentAssembly",
]

func try_issue_job(pawn: Pawn) -> Dictionary:
	if pawn.drafted or pawn.dead or pawn.downed:
		return {}
	if not pawn.is_capable_of("Crafting"):
		return {}
	if not CraftingManager:
		return {}

	for entry: Dictionary in CraftingManager.craft_queue:
		if entry.get("assigned", false):
			continue
		var recipe_name: String = entry.get("recipe", "")
		if not CraftingManager.can_craft(recipe_name, pawn):
			continue
		if not CraftingManager.has_ingredients(recipe_name):
			continue

		var bench: Building = _find_bench(pawn)
		var target_pos: Vector2i = bench.grid_pos if bench else pawn.grid_pos

		entry["assigned"] = true

		var j := Job.new("Craft", target_pos)
		j.meta_data["recipe"] = recipe_name
		if bench:
			j.target_thing_id = bench.id
		return {"job": j, "source": self}
	return {}


func get_available_bench_count() -> int:
	if not ThingManager:
		return 0
	var cnt: int = 0
	for t: Thing in ThingManager.things:
		if t is Building:
			var b := t as Building
			if b.build_state == Building.BuildState.COMPLETE and b.def_name in BENCH_DEFS:
				cnt += 1
	return cnt


func get_queue_size() -> int:
	if not CraftingManager:
		return 0
	return CraftingManager.craft_queue.size()


func can_any_pawn_craft() -> bool:
	if not PawnManager or not CraftingManager:
		return false
	var entry: Dictionary = CraftingManager.get_next_unassigned()
	if entry.is_empty():
		return false
	var recipe_name: String = entry.get("recipe", "")
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed or p.drafted:
			continue
		if p.is_capable_of("Crafting") and CraftingManager.can_craft(recipe_name, p):
			return true
	return false


func _find_bench(p: Pawn) -> Building:
	if not ThingManager:
		return null
	var best: Building = null
	var best_dist: int = 999
	for t: Thing in ThingManager.things:
		if not (t is Building):
			continue
		var b := t as Building
		if b.build_state != Building.BuildState.COMPLETE:
			continue
		if not (b.def_name in BENCH_DEFS):
			continue
		var dist: int = absi(b.grid_pos.x - p.grid_pos.x) + absi(b.grid_pos.y - p.grid_pos.y)
		if dist < best_dist:
			best_dist = dist
			best = b
	return best


func get_craftable_recipe_count() -> int:
	if not CraftingManager:
		return 0
	return CraftingManager.RECIPES.size()


func get_bench_to_recipe_ratio() -> float:
	var benches: int = get_available_bench_count()
	var recipes: int = get_craftable_recipe_count()
	if recipes <= 0:
		return 0.0
	return snappedf(float(benches) / float(recipes), 0.01)


func get_queue_per_bench() -> float:
	var benches: int = get_available_bench_count()
	if benches <= 0:
		return 0.0
	return snappedf(float(get_queue_size()) / float(benches), 0.01)


func is_idle() -> bool:
	return get_queue_size() == 0


func get_throughput_potential() -> float:
	var benches := get_available_bench_count()
	var recipes := get_craftable_recipe_count()
	if benches <= 0:
		return 0.0
	return snapped(float(benches) * minf(float(recipes), float(benches)) / maxf(float(recipes), 1.0) * 100.0, 0.1)

func get_resource_utilization() -> String:
	var queue := get_queue_size()
	var benches := get_available_bench_count()
	if benches <= 0:
		return "No Benches"
	var ratio := float(queue) / float(benches)
	if ratio >= 3.0:
		return "Overloaded"
	elif ratio >= 1.0:
		return "Optimal"
	elif ratio > 0.0:
		return "Underutilized"
	return "Idle"

func get_bottleneck_assessment() -> String:
	var benches := get_available_bench_count()
	var recipes := get_craftable_recipe_count()
	var queue := get_queue_size()
	if benches <= 0:
		return "No Infrastructure"
	if recipes <= 0:
		return "No Recipes"
	if queue <= 0:
		return "No Orders"
	if float(queue) / float(benches) > 3.0:
		return "Bench Shortage"
	if not can_any_pawn_craft():
		return "No Workers"
	return "Balanced"

func get_craft_summary() -> Dictionary:
	return {
		"benches": get_available_bench_count(),
		"recipes_available": get_craftable_recipe_count(),
		"queue_size": get_queue_size(),
		"has_work": can_any_pawn_craft(),
		"bench_recipe_ratio": get_bench_to_recipe_ratio(),
		"queue_per_bench": get_queue_per_bench(),
		"is_idle": is_idle(),
		"throughput_potential": get_throughput_potential(),
		"resource_utilization": get_resource_utilization(),
		"bottleneck": get_bottleneck_assessment(),
		"craft_ecosystem_health": get_craft_ecosystem_health(),
		"production_governance": get_production_governance(),
		"manufacturing_maturity_index": get_manufacturing_maturity_index(),
	}

func get_craft_ecosystem_health() -> float:
	var throughput := get_throughput_potential()
	var util := get_resource_utilization()
	var u_val: float = 90.0 if util == "Optimal" else (70.0 if util == "Busy" else (40.0 if util == "Underused" else (20.0 if util == "Overloaded" else 10.0)))
	var bottle := get_bottleneck_assessment()
	var b_val: float = 90.0 if bottle == "Smooth" else (60.0 if bottle == "Queue Pressure" else 25.0)
	return snapped((minf(throughput, 100.0) + u_val + b_val) / 3.0, 0.1)

func get_production_governance() -> String:
	var eco := get_craft_ecosystem_health()
	var mat := get_manufacturing_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif get_available_bench_count() > 0:
		return "Nascent"
	return "Dormant"

func get_manufacturing_maturity_index() -> float:
	var ratio := get_bench_to_recipe_ratio()
	var qpb := get_queue_per_bench()
	var throughput := get_throughput_potential()
	return snapped((minf(ratio * 50.0, 100.0) + minf(qpb * 20.0, 100.0) + minf(throughput, 100.0)) / 3.0, 0.1)
