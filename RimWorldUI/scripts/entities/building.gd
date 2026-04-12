class_name Building
extends Thing

## A placed building (wall, door, furniture, workbench, etc.)
## Reads stats from DefDB; tracks material delivery and construction progress.

enum BuildState { BLUEPRINT, FRAME, COMPLETE }

var build_state: BuildState = BuildState.COMPLETE
var build_work_left: float = 0.0
var build_work_total: float = 0.0
var power_draw: float = 0.0
var power_gen: float = 0.0
var passable: bool = true
var size: Vector2i = Vector2i(1, 1)
var beauty: float = 0.0
var comfort: float = 0.0
var category: String = "Building"

var cost_list: Dictionary = {}
var materials_delivered: Dictionary = {}
var _complete_color: Color = Color(0.5, 0.5, 0.5)


func _init(def: String = "") -> void:
	super._init(def)
	_apply_def_from_db()


func _apply_def_from_db() -> void:
	if def_name.is_empty():
		return
	var data: Dictionary = {}
	if DefDB:
		data = DefDB.get_def("ThingDef", def_name)
	if data.is_empty():
		_apply_fallback()
		return

	label = data.get("label", def_name) as String
	max_hit_points = int(data.get("maxHitPoints", 100))
	hit_points = max_hit_points
	passable = bool(data.get("passable", true))
	build_work_total = float(data.get("buildWork", 100))
	build_work_left = build_work_total
	power_draw = float(data.get("powerDraw", 0))
	power_gen = float(data.get("powerGen", 0))
	beauty = float(data.get("beauty", 0))
	comfort = float(data.get("comfort", 0))
	category = data.get("category", "Building") as String

	var sz: Variant = data.get("size", [1, 1])
	if sz is Array and sz.size() >= 2:
		size = Vector2i(int(sz[0]), int(sz[1]))

	var clr: Variant = data.get("color", [])
	if clr is Array and clr.size() >= 3:
		_complete_color = Color(float(clr[0]), float(clr[1]), float(clr[2]))

	_parse_costs(data)


func _parse_costs(data: Dictionary) -> void:
	cost_list.clear()
	materials_delivered.clear()
	for key: String in data.keys():
		if not key.begins_with("cost"):
			continue
		var amount: int = int(data[key])
		if amount <= 0:
			continue
		var mat_name: String = key.substr(4)
		match mat_name:
			"Wood": cost_list["Wood"] = amount
			"Steel": cost_list["Steel"] = amount
			"Components": cost_list["Component"] = amount
			"Plasteel": cost_list["Plasteel"] = amount
			"Gold": cost_list["Gold"] = amount
			_: cost_list[mat_name] = amount
	for mat: String in cost_list:
		materials_delivered[mat] = 0


func _apply_fallback() -> void:
	build_work_total = 100.0
	build_work_left = 100.0


func place_blueprint() -> void:
	build_state = BuildState.BLUEPRINT
	build_work_left = build_work_total


func needs_materials() -> bool:
	for mat: String in cost_list:
		if materials_delivered.get(mat, 0) < cost_list[mat]:
			return true
	return false


func get_missing_materials() -> Dictionary:
	var missing: Dictionary = {}
	for mat: String in cost_list:
		var need: int = cost_list[mat] - materials_delivered.get(mat, 0)
		if need > 0:
			missing[mat] = need
	return missing


func deliver_material(mat_name: String, amount: int) -> int:
	if not cost_list.has(mat_name):
		return 0
	var need: int = cost_list[mat_name] - materials_delivered.get(mat_name, 0)
	var used: int = mini(amount, need)
	materials_delivered[mat_name] = materials_delivered.get(mat_name, 0) + used
	if not needs_materials() and build_state == BuildState.BLUEPRINT:
		build_state = BuildState.FRAME
	return used


func start_frame() -> void:
	build_state = BuildState.FRAME


func do_build_work(amount: float) -> bool:
	if build_state == BuildState.BLUEPRINT and needs_materials():
		return false
	if build_state == BuildState.BLUEPRINT:
		build_state = BuildState.FRAME
	build_work_left = maxf(0.0, build_work_left - amount)
	if build_work_left <= 0.0:
		build_state = BuildState.COMPLETE
		if not passable:
			_update_pathfinding()
		return true
	return false


func get_build_progress() -> float:
	if build_work_total <= 0.0:
		return 1.0
	return 1.0 - (build_work_left / build_work_total)


var is_powered: bool = true
var flammability: float = 0.0


func cancel_blueprint() -> void:
	if build_state == BuildState.COMPLETE:
		return
	state = ThingState.DESTROYED


func get_refund_materials() -> Dictionary:
	var refund: Dictionary = {}
	for mat: String in cost_list:
		var delivered: int = materials_delivered.get(mat, 0)
		if delivered > 0:
			refund[mat] = delivered
	return refund


func deconstruct() -> Dictionary:
	var recovered: Dictionary = {}
	if build_state == BuildState.COMPLETE:
		for mat: String in cost_list:
			recovered[mat] = int(cost_list[mat] * 0.75)
	state = ThingState.DESTROYED
	_clear_pathfinding()
	return recovered


func repair(amount: float) -> void:
	if build_state != BuildState.COMPLETE:
		return
	hit_points = mini(hit_points + roundi(amount), max_hit_points)


func is_damaged() -> bool:
	return build_state == BuildState.COMPLETE and hit_points < max_hit_points


func get_health_pct() -> float:
	if max_hit_points <= 0:
		return 1.0
	return float(hit_points) / float(max_hit_points)


func needs_power() -> bool:
	return power_draw > 0.0


func _update_pathfinding() -> void:
	if not GameState:
		return
	var map: MapData = GameState.get_map()
	if map == null:
		return
	var cell := map.get_cell_v(grid_pos)
	if cell:
		cell.building = true


func _clear_pathfinding() -> void:
	if not GameState:
		return
	var map: MapData = GameState.get_map()
	if map == null:
		return
	var cell := map.get_cell_v(grid_pos)
	if cell:
		cell.building = false


func get_color() -> Color:
	match build_state:
		BuildState.BLUEPRINT:
			return Color(0.3, 0.5, 0.9, 0.5)
		BuildState.FRAME:
			var progress := get_build_progress()
			return Color(0.6, 0.5, 0.3, 0.5 + 0.4 * progress)
		_:
			if is_damaged():
				var hp_pct := get_health_pct()
				return _complete_color.lerp(Color(0.8, 0.2, 0.2), 1.0 - hp_pct)
			return _complete_color


func get_efficiency() -> float:
	var hp_factor: float = get_health_pct()
	var power_factor: float = 1.0 if (not needs_power() or is_powered) else 0.5
	return hp_factor * power_factor


func get_total_cost_value() -> float:
	var values: Dictionary = {"Wood": 1.2, "Steel": 1.9, "Component": 32.0, "Plasteel": 9.0, "Gold": 10.0}
	var total: float = 0.0
	for mat: String in cost_list:
		total += cost_list[mat] * values.get(mat, 1.0)
	return total


func get_build_time_estimate(construction_speed: float) -> float:
	if construction_speed <= 0.0:
		return 999.0
	return build_work_left / construction_speed


func get_material_types_needed() -> int:
	return cost_list.size()

func get_delivery_completion_pct() -> float:
	if cost_list.is_empty():
		return 100.0
	var delivered: int = 0
	var needed: int = 0
	for mat: String in cost_list:
		needed += cost_list[mat]
		delivered += materials_delivered.get(mat, 0)
	if needed <= 0:
		return 100.0
	return snappedf(float(delivered) / float(needed) * 100.0, 0.1)

func is_power_producer() -> bool:
	return power_gen > 0.0

func get_net_power() -> float:
	return power_gen - power_draw

func get_beauty_per_tile() -> float:
	var area: int = size.x * size.y
	if area <= 0:
		return beauty
	return snappedf(beauty / float(area), 0.01)


func get_damage_severity() -> String:
	var pct: float = get_health_pct()
	if pct >= 1.0:
		return "Pristine"
	elif pct >= 0.7:
		return "Minor"
	elif pct >= 0.4:
		return "Moderate"
	elif pct > 0.0:
		return "Severe"
	return "Destroyed"


func get_maintenance_priority() -> float:
	var hp_urgency := (1.0 - get_health_pct()) * 50.0
	var power_factor := 20.0 if (needs_power() and not is_powered) else 0.0
	var beauty_loss := maxf(0.0, -beauty) * 2.0
	return snapped(hp_urgency + power_factor + beauty_loss, 0.1)

func get_roi_score() -> float:
	var cost := get_total_cost_value()
	if cost <= 0.0:
		return 0.0
	var eff := get_efficiency()
	var beauty_val := maxf(0.0, beauty) * 5.0
	var power_val := maxf(0.0, power_gen) * 0.5
	return snapped((eff * 100.0 + beauty_val + power_val) / cost, 0.01)

func get_structural_risk() -> String:
	var score := 0.0
	score += (1.0 - get_health_pct()) * 40.0
	score += flammability * 20.0
	if needs_power() and not is_powered:
		score += 15.0
	if build_state != BuildState.COMPLETE:
		score += 10.0
	if score >= 50.0:
		return "Critical"
	elif score >= 30.0:
		return "High"
	elif score >= 15.0:
		return "Moderate"
	return "Low"

func get_build_summary() -> Dictionary:
	return {
		"def_name": def_name,
		"state": BuildState.keys()[build_state],
		"health_pct": snappedf(get_health_pct() * 100.0, 0.1),
		"damage_severity": get_damage_severity(),
		"efficiency": snappedf(get_efficiency() * 100.0, 0.1),
		"beauty_per_tile": get_beauty_per_tile(),
		"net_power": get_net_power(),
		"total_cost_value": snappedf(get_total_cost_value(), 0.1),
		"delivery_pct": get_delivery_completion_pct(),
		"maintenance_priority": get_maintenance_priority(),
		"roi_score": get_roi_score(),
		"structural_risk": get_structural_risk(),
		"building_ecosystem_health": get_building_ecosystem_health(),
		"construction_governance": get_construction_governance(),
		"structural_maturity_index": get_structural_maturity_index(),
	}


func get_building_ecosystem_health() -> float:
	var maint_inv := maxf(100.0 - get_maintenance_priority(), 0.0)
	var roi := minf(get_roi_score() * 10.0, 100.0)
	var risk := get_structural_risk()
	var r_val: float = 90.0 if risk == "Minimal" else (65.0 if risk == "Low" else (35.0 if risk == "Moderate" else 15.0))
	return snapped((maint_inv + roi + r_val) / 3.0, 0.1)

func get_construction_governance() -> String:
	var eco := get_building_ecosystem_health()
	var mat := get_structural_maturity_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif build_state == BuildState.COMPLETE:
		return "Nascent"
	return "Dormant"

func get_structural_maturity_index() -> float:
	var health := get_health_pct() * 100.0
	var eff := get_efficiency() * 100.0
	var delivery := get_delivery_completion_pct()
	return snapped((health + eff + delivery) / 3.0, 0.1)

func to_dict() -> Dictionary:
	return {
		"def_name": def_name,
		"label": label,
		"grid_pos": [grid_pos.x, grid_pos.y],
		"build_state": build_state,
		"hit_points": hit_points,
		"max_hit_points": max_hit_points,
		"power_draw": power_draw,
		"power_gen": power_gen,
		"is_powered": is_powered,
		"cost_list": cost_list.duplicate(),
		"materials_delivered": materials_delivered.duplicate(),
	}
