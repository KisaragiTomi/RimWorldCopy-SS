class_name RoomManager
extends RefCounted

## Detects enclosed rooms and calculates beauty/impressiveness.

var rooms: Array[Dictionary] = []


func detect_rooms(map: MapData) -> void:
	rooms.clear()
	var visited: Dictionary = {}

	for y: int in map.height:
		for x: int in map.width:
			if visited.has(Vector2i(x, y)):
				continue
			var cell := map.get_cell(x, y)
			if cell == null or not cell.is_passable():
				visited[Vector2i(x, y)] = true
				continue

			var room_cells: Array[Vector2i] = []
			var enclosed := _flood_fill(map, Vector2i(x, y), visited, room_cells)

			if enclosed and room_cells.size() > 0 and room_cells.size() < 400:
				var room := _build_room(map, room_cells)
				rooms.append(room)


func _flood_fill(map: MapData, start: Vector2i, visited: Dictionary, out_cells: Array[Vector2i]) -> bool:
	var queue: Array[Vector2i] = [start]
	var enclosed := true

	while queue.size() > 0:
		var pos: Vector2i = queue.pop_front() as Vector2i
		if visited.has(pos):
			continue
		visited[pos] = true

		if not map.in_bounds(pos.x, pos.y):
			enclosed = false
			continue

		var cell := map.get_cell(pos.x, pos.y)
		if cell == null:
			continue

		if not cell.is_passable():
			continue

		out_cells.append(pos)

		if pos.x == 0 or pos.x == map.width - 1 or pos.y == 0 or pos.y == map.height - 1:
			enclosed = false

		for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nb: Vector2i = pos + dir
			if not visited.has(nb):
				queue.append(nb)

	return enclosed


func _build_room(map: MapData, cells: Array[Vector2i]) -> Dictionary:
	var beauty: float = 0.0
	var wealth: float = 0.0
	var cleanliness: float = 0.0
	var thing_names: Array[String] = []

	if ThingManager:
		for pos: Vector2i in cells:
			var things := ThingManager.get_things_at(pos)
			for t: Thing in things:
				beauty += _thing_beauty(t)
				wealth += _thing_wealth(t)
				thing_names.append(t.def_name)
			if FloorManager and FloorManager.has_floor(pos):
				beauty += FloorManager.get_beauty(pos)
				cleanliness += 0.1

	var filth_count: int = 0
	if ThingManager:
		for pos: Vector2i in cells:
			for t: Thing in ThingManager.get_things_at(pos):
				if t.def_name in ["Filth", "BloodFilth", "Dirt"]:
					filth_count += 1
					cleanliness -= 0.5

	var cell_count: float = maxf(1.0, float(cells.size()))
	var avg_beauty: float = beauty / cell_count
	var avg_clean: float = cleanliness / cell_count
	var size: int = cells.size()

	var impressiveness: float = 0.0
	impressiveness += clampf(avg_beauty * 10.0, -20.0, 40.0)
	impressiveness += clampf(float(size) * 0.5, 0.0, 30.0)
	impressiveness += clampf(wealth * 0.01, 0.0, 30.0)
	impressiveness += clampf(avg_clean * 10.0, -10.0, 10.0)
	impressiveness = clampf(impressiveness, 0.0, 100.0)

	var room_type: String = _detect_room_type(thing_names, size)

	return {
		"cells": cells,
		"size": size,
		"beauty": snappedf(avg_beauty, 0.01),
		"wealth": snappedf(wealth, 0.01),
		"impressiveness": snappedf(impressiveness, 0.01),
		"cleanliness": snappedf(avg_clean, 0.01),
		"type": room_type,
		"filth": filth_count,
	}


func _detect_room_type(thing_names: Array[String], size: int) -> String:
	var has_bed: bool = "Bed" in thing_names or "DoubleBed" in thing_names or "RoyalBed" in thing_names
	var has_table: bool = "Table" in thing_names or "DiningTable" in thing_names
	var has_research: bool = "ResearchBench" in thing_names or "HiTechResearchBench" in thing_names
	var has_stove: bool = "CookingStove" in thing_names or "ElectricStove" in thing_names
	var has_hospital: bool = "HospitalBed" in thing_names or "MedicalBed" in thing_names or "VitalsMonitor" in thing_names

	if has_hospital:
		return "Hospital"
	if has_research:
		return "Laboratory"
	if has_stove:
		return "Kitchen"
	if has_bed and has_table:
		return "Barracks"
	if has_bed:
		return "Bedroom"
	if has_table:
		return "DiningRoom"
	if size > 100:
		return "Warehouse"
	return "Room"


func _thing_beauty(t: Thing) -> float:
	var beauty_map: Dictionary = {
		"Campfire": 1.0, "Wall": 0.0, "Bed": 0.5, "DoubleBed": 0.8, "RoyalBed": 3.0,
		"Table": 0.3, "DiningTable": 0.5, "Chair": 0.2, "ArmChair": 0.8,
		"Armchair": 0.8, "DiningChair": 0.3,
		"Sculpture": 5.0, "GrandSculpture": 10.0,
		"Flower": 2.0, "FlowerPot": 1.5, "PlantPot": 1.5,
		"Lamp": 0.3, "StandingLamp": 0.5,
		"Carpet": 0.5, "Rug": 1.0,
		"Dresser": 1.0, "EndTable": 0.3, "Shelf": 0.0,
		"Filth": -3.0, "BloodFilth": -5.0, "Dirt": -1.0,
	}
	if beauty_map.has(t.def_name):
		return beauty_map[t.def_name]
	if t is Building:
		return (t as Building).beauty
	return 0.0


func _thing_wealth(t: Thing) -> float:
	var wealth_map: Dictionary = {
		"Wall": 5.0, "Bed": 30.0, "DoubleBed": 50.0, "RoyalBed": 200.0,
		"MedicalBed": 80.0,
		"Table": 20.0, "DiningTable": 30.0, "Chair": 15.0, "ArmChair": 40.0,
		"Armchair": 40.0, "DiningChair": 20.0,
		"Sculpture": 100.0, "GrandSculpture": 300.0,
		"Campfire": 10.0, "Lamp": 15.0, "StandingLamp": 25.0,
		"Dresser": 35.0, "EndTable": 15.0, "Shelf": 20.0, "PlantPot": 10.0,
		"ResearchBench": 80.0, "HiTechResearchBench": 200.0,
		"CookingStove": 50.0, "ElectricStove": 80.0,
		"HospitalBed": 100.0, "VitalsMonitor": 150.0,
	}
	return wealth_map.get(t.def_name, 2.0)


func get_room_at(pos: Vector2i) -> Dictionary:
	for r: Dictionary in rooms:
		if pos in r.cells:
			return r
	return {}


func get_room_type_at(pos: Vector2i) -> String:
	var room := get_room_at(pos)
	return room.get("type", "Outdoors")


func get_impressiveness_label(impressiveness: float) -> String:
	if impressiveness >= 80.0:
		return "Wondrously Impressive"
	elif impressiveness >= 60.0:
		return "Very Impressive"
	elif impressiveness >= 40.0:
		return "Somewhat Impressive"
	elif impressiveness >= 20.0:
		return "Decent"
	elif impressiveness >= 5.0:
		return "Dull"
	return "Awful"


func get_room_mood_thought(pos: Vector2i) -> String:
	var room := get_room_at(pos)
	if room.is_empty():
		return ""
	var imp: float = room.get("impressiveness", 0.0)
	if imp >= 80.0:
		return "WondrouslyImpressiveRoom"
	elif imp >= 60.0:
		return "VeryImpressiveRoom"
	elif imp >= 40.0:
		return "SomewhatImpressiveRoom"
	elif imp >= 20.0:
		return ""
	elif imp >= 5.0:
		return "DullRoom"
	return "AwfulRoom"


func get_best_room() -> Dictionary:
	var best: Dictionary = {}
	var best_imp: float = -1.0
	for r: Dictionary in rooms:
		if r.get("impressiveness", 0.0) > best_imp:
			best_imp = r["impressiveness"]
			best = r
	return best


func get_avg_beauty() -> float:
	if rooms.is_empty():
		return 0.0
	var total: float = 0.0
	for r: Dictionary in rooms:
		total += r.get("beauty", 0.0)
	return total / float(rooms.size())


func get_avg_impressiveness() -> float:
	if rooms.is_empty():
		return 0.0
	var total: float = 0.0
	for r: Dictionary in rooms:
		total += r.get("impressiveness", 0.0)
	return total / float(rooms.size())


func count_rooms_of_type(room_type: String) -> int:
	var count: int = 0
	for r: Dictionary in rooms:
		if r.get("type", "") == room_type:
			count += 1
	return count


func get_total_filth_count() -> int:
	var total: int = 0
	for r: Dictionary in rooms:
		total += r.get("filth", 0)
	return total

func get_cleanest_room_type() -> String:
	var type_clean: Dictionary = {}
	var type_count: Dictionary = {}
	for r: Dictionary in rooms:
		var t: String = r.get("type", "Room")
		type_clean[t] = type_clean.get(t, 0.0) + r.get("cleanliness", 0.0)
		type_count[t] = type_count.get(t, 0) + 1
	var best: String = ""
	var best_avg: float = -999.0
	for t: String in type_clean:
		var avg: float = type_clean[t] / maxf(1.0, float(type_count[t]))
		if avg > best_avg:
			best_avg = avg
			best = t
	return best

func get_avg_room_size() -> float:
	if rooms.is_empty():
		return 0.0
	var total: float = 0.0
	for r: Dictionary in rooms:
		total += float(r.get("size", 0))
	return snappedf(total / float(rooms.size()), 0.01)

func get_impressive_room_count() -> int:
	var count: int = 0
	for r: Dictionary in rooms:
		if r.get("impressiveness", 0.0) >= 40.0:
			count += 1
	return count

func get_worst_room_beauty() -> float:
	if rooms.is_empty():
		return 0.0
	var worst: float = 999.0
	for r: Dictionary in rooms:
		var b: float = r.get("beauty", 0.0)
		if b < worst:
			worst = b
	return snappedf(worst, 0.01)

func get_unique_room_types() -> int:
	var types: Dictionary = {}
	for r: Dictionary in rooms:
		types[r.get("type", "Room")] = true
	return types.size()

func get_living_standard() -> float:
	if rooms.is_empty():
		return 0.0
	var weighted := 0.0
	var total_size := 0.0
	for r in rooms:
		var size: float = r.get("size", 1.0)
		weighted += r.get("impressiveness", 0.0) * size
		total_size += size
	return snapped(weighted / maxf(total_size, 1.0), 0.01)

func get_cleanliness_index_pct() -> float:
	if rooms.is_empty():
		return 100.0
	var total_filth := get_total_filth_count()
	var max_filth := rooms.size() * 10
	return snapped((1.0 - float(total_filth) / maxf(max_filth, 1.0)) * 100.0, 0.1)

func get_spatial_efficiency() -> float:
	if rooms.is_empty():
		return 0.0
	var functional := 0
	for r in rooms:
		if r.get("type", "Room") != "Room":
			functional += 1
	return snapped(float(functional) / float(rooms.size()) * 100.0, 0.1)

func get_stats() -> Dictionary:
	var types: Dictionary = {}
	for r: Dictionary in rooms:
		var t: String = r.get("type", "Room")
		types[t] = types.get(t, 0) + 1
	return {
		"total_rooms": rooms.size(),
		"types": types,
		"avg_beauty": snappedf(get_avg_beauty(), 0.01),
		"avg_impressiveness": snappedf(get_avg_impressiveness(), 0.01),
		"total_filth": get_total_filth_count(),
		"cleanest_type": get_cleanest_room_type(),
		"avg_room_size": get_avg_room_size(),
		"impressive_rooms": get_impressive_room_count(),
		"worst_beauty": get_worst_room_beauty(),
		"unique_room_types": get_unique_room_types(),
		"living_standard": get_living_standard(),
		"cleanliness_index_pct": get_cleanliness_index_pct(),
		"spatial_efficiency": get_spatial_efficiency(),
	}
