extends Node

## Loads and indexes all game definitions from JSON files under res://defs/.
## Registered as autoload "DefDB".

signal defs_loaded

var _defs: Dictionary = {}  # { "TerrainDef": { "Soil": {...}, "Sand": {...} }, ... }

func _ready() -> void:
	_load_all_defs("res://defs")
	defs_loaded.emit()


func get_def(def_type: String, def_name: String) -> Dictionary:
	if _defs.has(def_type) and _defs[def_type].has(def_name):
		return _defs[def_type][def_name]
	push_warning("DefDB: %s/%s not found" % [def_type, def_name])
	return {}


func get_all(def_type: String) -> Array[Dictionary]:
	if not _defs.has(def_type):
		return []
	var arr: Array[Dictionary] = []
	for d: Dictionary in _defs[def_type].values():
		arr.append(d)
	return arr


func get_names(def_type: String) -> PackedStringArray:
	if not _defs.has(def_type):
		return PackedStringArray()
	return PackedStringArray(_defs[def_type].keys())


func get_all_sorted(def_type: String, sort_key: String = "order") -> Array[Dictionary]:
	var arr := get_all(def_type)
	if arr.is_empty():
		return arr
	arr.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get(sort_key, 9999) < b.get(sort_key, 9999)
	)
	return arr


func has_def(def_type: String, def_name: String) -> bool:
	return _defs.has(def_type) and _defs[def_type].has(def_name)


func register_def(def_type: String, def_name: String, data: Dictionary) -> void:
	if not _defs.has(def_type):
		_defs[def_type] = {}
	_defs[def_type][def_name] = data


func def_count(def_type: String) -> int:
	if not _defs.has(def_type):
		return 0
	return _defs[def_type].size()


func all_types() -> PackedStringArray:
	return PackedStringArray(_defs.keys())


func get_total_def_count() -> int:
	var total: int = 0
	for dtype: String in _defs:
		total += _defs[dtype].size()
	return total

func get_largest_def_type() -> String:
	var best: String = ""
	var best_cnt: int = 0
	for dtype: String in _defs:
		var cnt: int = _defs[dtype].size()
		if cnt > best_cnt:
			best_cnt = cnt
			best = dtype
	return best

func get_type_count() -> int:
	return _defs.size()

func get_data_density() -> float:
	var types := get_type_count()
	var total := get_total_def_count()
	return snapped(float(total) / maxf(types, 1.0), 0.01)

func get_coverage_balance_pct() -> float:
	var types := all_types()
	if types.is_empty():
		return 0.0
	var counts: Array[int] = []
	for t in types:
		counts.append(def_count(t))
	var avg := float(get_total_def_count()) / float(types.size())
	var variance := 0.0
	for c in counts:
		variance += (float(c) - avg) * (float(c) - avg)
	var std_dev := sqrt(variance / float(counts.size()))
	return snapped((1.0 - std_dev / maxf(avg, 1.0)) * 100.0, 0.1)

func get_smallest_def_type() -> String:
	var types := all_types()
	if types.is_empty():
		return ""
	var best: String = types[0]
	var best_c: int = def_count(best)
	for i in range(1, types.size()):
		var c: int = def_count(types[i])
		if c < best_c:
			best_c = c
			best = types[i]
	return best

func get_summary() -> Dictionary:
	return {
		"def_types": get_type_count(),
		"total_defs": get_total_def_count(),
		"largest_type": get_largest_def_type(),
		"all_types": Array(all_types()),
		"data_density": get_data_density(),
		"coverage_balance_pct": get_coverage_balance_pct(),
		"smallest_type": get_smallest_def_type(),
	}


# --- Loading ---

func _load_all_defs(root_path: String) -> void:
	var dir := DirAccess.open(root_path)
	if dir == null:
		push_warning("DefDB: cannot open %s" % root_path)
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := root_path.path_join(entry)
		if dir.current_is_dir():
			_load_all_defs(full)
		elif entry.ends_with(".json"):
			_load_json_file(full)
		entry = dir.get_next()


func _load_json_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("DefDB: cannot read %s" % path)
		return
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_warning("DefDB: JSON parse error in %s: %s" % [path, json.get_error_message()])
		return

	var data: Variant = json.data
	if data is Array:
		for item: Variant in data:
			if item is Dictionary:
				_register_from_dict(item as Dictionary)
	elif data is Dictionary:
		_register_from_dict(data as Dictionary)


func _register_from_dict(d: Dictionary) -> void:
	var def_type: String = d.get("defType", "")
	var def_name: String = d.get("defName", "")
	if def_type.is_empty() or def_name.is_empty():
		push_warning("DefDB: entry missing defType/defName: %s" % str(d).left(120))
		return
	register_def(def_type, def_name, d)
