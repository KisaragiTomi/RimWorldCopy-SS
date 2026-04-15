extends Node

## Top-level world management: world grid, factions, caravans.
## Registered as autoload "WorldManager".

signal world_generated()
signal caravan_arrived(caravan_id: int, tile: Dictionary)

var world: WorldGrid = null
var faction_mgr: FactionManager = null
var caravans: Array[Caravan] = []
var player_home: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func generate_world(width: int = 100, height: int = 60, seed_val: int = 0) -> void:
	world = WorldGrid.new()
	world.generate(width, height, seed_val)

	faction_mgr = FactionManager.new()
	faction_mgr.load_factions()
	faction_mgr.place_settlements(world)

	var land := world.get_land_tiles()
	if land.size() > 0:
		var mid: Dictionary = land[land.size() / 2]
		player_home = Vector2i(mid.x, mid.y)
		mid["faction"] = "PlayerColony"
		mid["settlement"] = "PlayerColony"

	world_generated.emit()


func send_caravan(member_ids: Array[int], destination: Vector2i) -> Caravan:
	if world == null:
		return null
	var c := Caravan.new()
	c.members = member_ids
	c.position = player_home
	c.set_destination(destination, world)
	c.arrived.connect(_on_caravan_arrived.bind(c))
	c.returned_home.connect(_on_caravan_home.bind(c))
	caravans.append(c)
	return c


func _on_rare_tick(_tick: int) -> void:
	for c: Caravan in caravans:
		if c.state == "Traveling":
			c.tick_movement()
		elif c.state == "Returning":
			c.tick_return()


func _on_caravan_arrived(dest: Vector2i, c: Caravan) -> void:
	var tile := world.get_tile(dest.x, dest.y) if world else {}
	caravan_arrived.emit(c.id, tile)


func _on_caravan_home(c: Caravan) -> void:
	caravans.erase(c)


func get_active_caravan_count() -> int:
	return caravans.size()

func get_world_tile_count() -> int:
	if world == null:
		return 0
	return world.width * world.height

func get_faction_count() -> int:
	if faction_mgr == null:
		return 0
	return faction_mgr.factions.size()

func get_exploration_coverage() -> float:
	var tiles := get_world_tile_count()
	var active := get_active_caravan_count()
	return snapped(float(active) / maxf(tiles, 1.0) * 10000.0, 0.01)

func get_world_density() -> float:
	var tiles := get_world_tile_count()
	var factions := get_faction_count()
	return snapped(float(factions) / maxf(tiles, 1.0) * 1000.0, 0.01)

func get_colonization_index() -> float:
	var factions := get_faction_count()
	var active := get_active_caravan_count()
	return snapped(float(active + 1) / maxf(factions, 1.0) * 10.0, 0.01)

func get_world_summary() -> Dictionary:
	if world == null:
		return {"generated": false}
	return {
		"generated": true,
		"size": [world.width, world.height],
		"biomes": world.count_biomes(),
		"factions": faction_mgr.get_faction_summary() if faction_mgr else [],
		"player_home": [player_home.x, player_home.y],
		"caravans": caravans.map(func(c: Caravan) -> Dictionary: return c.get_summary()),
		"active_caravans": get_active_caravan_count(),
		"total_tiles": get_world_tile_count(),
		"faction_count": get_faction_count(),
		"exploration_coverage": get_exploration_coverage(),
		"world_density": get_world_density(),
		"colonization_index": get_colonization_index(),
		"world_ecosystem_health": get_world_ecosystem_health(),
		"geopolitical_governance": get_geopolitical_governance(),
		"civilization_spread_index": get_civilization_spread_index(),
	}

func get_world_ecosystem_health() -> float:
	var coverage := minf(get_exploration_coverage() * 10.0, 100.0)
	var density := minf(get_world_density() * 10.0, 100.0)
	var colonize := minf(get_colonization_index() * 10.0, 100.0)
	return snapped((coverage + density + colonize) / 3.0, 0.1)

func get_geopolitical_governance() -> String:
	var eco := get_world_ecosystem_health()
	var mat := get_civilization_spread_index()
	if eco >= 70.0 and mat >= 60.0:
		return "Exemplary"
	elif eco >= 40.0 or mat >= 30.0:
		return "Developing"
	elif world != null:
		return "Nascent"
	return "Dormant"

func get_civilization_spread_index() -> float:
	var factions := minf(float(get_faction_count()) * 10.0, 100.0)
	var tiles := minf(float(get_world_tile_count()) / 10.0, 100.0)
	var caravans := minf(float(get_active_caravan_count()) * 20.0, 100.0)
	return snapped((factions + tiles + caravans) / 3.0, 0.1)
