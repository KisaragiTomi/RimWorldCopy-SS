extends Node2D

## Renders the MapData using TileMapLayer for GPU-accelerated terrain
## plus Sprite2D overlays for pawns, animals, and things.
## Supports pan (middle-drag / WASD / arrow keys) and zoom (scroll wheel).

signal pawn_selected(pawn_data: Dictionary)
signal multi_pawns_selected(pawn_ids: Array)
signal draft_move_issued(pawn_id: int, target: Vector2i)
signal context_menu_requested(cell_pos: Vector2i, screen_pos: Vector2, options: Array)

const CELL_SIZE := 16
const EDGE_SCROLL_MARGIN := 4

var map_data: MapData
var _camera: Camera2D
var _terrain_layer: TileMapLayer
var _thing_layer: TileMapLayer
var _tileset: TileSet
var _terrain_id_map: Dictionary = {}  # terrain_def_name -> atlas coords

var _pawn_sprites: Dictionary = {}  # pawn_id -> Sprite2D
var _pawn_target_pos: Dictionary = {}  # pawn_id -> Vector2 (world target)
var _animal_sprites: Dictionary = {}  # animal_id -> Sprite2D
var _animal_target_pos: Dictionary = {}

const MOVE_LERP_SPEED := 8.0

var _dragging := false
var _drag_start := Vector2.ZERO

var _placement_mode := ""
var _placement_ghost: Sprite2D
var _selected_pawn_id: int = -1

var _day_night_mod: CanvasModulate
var _weather_particles: CPUParticles2D
var _zone_sprite: Sprite2D
var _zone_image: Image
var _zone_texture: ImageTexture

var _terrain_rng := RandomNumberGenerator.new()
var _power_overlay_sprite: Sprite2D
var _power_overlay_visible := false
var _beauty_overlay_sprite: Sprite2D
var _beauty_overlay_visible := false
var _temp_overlay_sprite: Sprite2D
var _temp_overlay_visible := false
var _zone_dragging := false
var _zone_drag_start := Vector2i.ZERO
var _select_dragging := false
var _select_start_screen := Vector2.ZERO
var _select_rect: ColorRect

const BENCH_DEFS: PackedStringArray = [
	"CraftingSpot", "TailoringBench", "Smithy", "MachiningTable", "FabricationBench",
]

var _placement_rotation: int = 0

const ZONE_DESIGNATOR_MAP: Dictionary = {
	"Stockpile": "Stockpile",
	"Dumping": "Dumping",
	"Growing": "GrowingZone",
	"Home Area": "HomeArea",
	"Animal Area": "AnimalArea",
}


func _ready() -> void:
	_camera = Camera2D.new()
	_camera.enabled = true
	_camera.zoom = Vector2(1.5, 1.5)
	add_child(_camera)

	_build_tileset()

	_terrain_layer = TileMapLayer.new()
	_terrain_layer.tile_set = _tileset
	_terrain_layer.z_index = 0
	add_child(_terrain_layer)

	_thing_layer = TileMapLayer.new()
	_thing_layer.tile_set = _tileset
	_thing_layer.z_index = 1
	add_child(_thing_layer)

	_zone_sprite = Sprite2D.new()
	_zone_sprite.z_index = 2
	_zone_sprite.centered = false
	add_child(_zone_sprite)

	_power_overlay_sprite = Sprite2D.new()
	_power_overlay_sprite.z_index = 3
	_power_overlay_sprite.centered = false
	_power_overlay_sprite.visible = false
	add_child(_power_overlay_sprite)

	_beauty_overlay_sprite = Sprite2D.new()
	_beauty_overlay_sprite.z_index = 3
	_beauty_overlay_sprite.centered = false
	_beauty_overlay_sprite.visible = false
	add_child(_beauty_overlay_sprite)

	_temp_overlay_sprite = Sprite2D.new()
	_temp_overlay_sprite.z_index = 3
	_temp_overlay_sprite.centered = false
	_temp_overlay_sprite.visible = false
	add_child(_temp_overlay_sprite)

	_day_night_mod = CanvasModulate.new()
	_day_night_mod.color = Color.WHITE
	add_child(_day_night_mod)

	_weather_particles = CPUParticles2D.new()
	_weather_particles.emitting = false
	_weather_particles.z_index = 10
	_weather_particles.amount = 200
	_weather_particles.lifetime = 3.0
	_weather_particles.one_shot = false
	_weather_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_weather_particles.emission_rect_extents = Vector2(1200, 10)
	_weather_particles.direction = Vector2(0.2, 1.0)
	_weather_particles.spread = 15.0
	_weather_particles.gravity = Vector2(0, 200)
	_weather_particles.initial_velocity_min = 80.0
	_weather_particles.initial_velocity_max = 150.0
	_weather_particles.scale_amount_min = 0.8
	_weather_particles.scale_amount_max = 1.5
	_weather_particles.color = Color(0.7, 0.75, 0.85, 0.4)
	add_child(_weather_particles)

	generate_new_map(120, 120, randi())
	_spawn_initial_pawns()
	_spawn_starting_items()
	_place_initial_blueprints()
	_spawn_wildlife()
	if ThingManager:
		ThingManager.thing_spawned.connect(_on_thing_changed)
		ThingManager.thing_destroyed.connect(_on_thing_changed)
	if ZoneManager:
		ZoneManager.zone_placed.connect(_on_zone_changed)
		ZoneManager.zone_removed.connect(_on_zone_removed)
	if TickManager:
		TickManager.date_changed.connect(_on_date_changed)
		_update_day_night(TickManager.hour)
	if WeatherManager:
		WeatherManager.weather_changed.connect(_on_weather_changed)
		_update_weather_vfx(WeatherManager.current_weather)


func generate_new_map(w: int, h: int, seed_val: int) -> void:
	map_data = MapData.new(w, h)
	map_data.seed = seed_val
	var gen := MapGenerator.new(map_data, seed_val)
	gen.generate()
	if GameState:
		GameState.active_map = map_data
	_render_map()
	_render_zones()
	_camera.position = Vector2(w * CELL_SIZE / 2.0, h * CELL_SIZE / 2.0)


func _spawn_initial_pawns() -> void:
	if map_data == null or not PawnManager:
		return
	var center := Vector2i(map_data.width / 2, map_data.height / 2)
	var colonist_defs: Array[Dictionary] = [
		{"name": "Engie", "age": 32, "skills": {"Construction": 12, "Shooting": 5, "Mining": 6}},
		{"name": "Doc", "age": 45, "skills": {"Medicine": 14, "Shooting": 3, "Intellectual": 8}},
		{"name": "Hawk", "age": 28, "skills": {"Shooting": 14, "Melee": 10, "Animals": 4}},
		{"name": "Cook", "age": 38, "skills": {"Cooking": 12, "Plants": 8, "Medicine": 4}},
		{"name": "Miner", "age": 35, "skills": {"Mining": 13, "Construction": 7, "Crafting": 5}},
		{"name": "Crafter", "age": 41, "skills": {"Crafting": 14, "Construction": 6, "Intellectual": 6}},
	]
	for def: Dictionary in colonist_defs:
		var p := Pawn.new()
		p.pawn_name = def["name"]
		p.age = def["age"]
		var spawn := _find_passable_near(center, 10)
		p.set_grid_pos(spawn)
		var skills: Dictionary = def["skills"]
		for skill_name: String in skills:
			p.set_skill_level(skill_name, skills[skill_name])
		PawnManager.add_pawn(p)
		_create_pawn_sprite(p)
		p.position_changed.connect(_on_pawn_moved.bind(p))


func _find_passable_near(center: Vector2i, radius: int) -> Vector2i:
	for r: int in range(0, radius):
		for dy: int in range(-r, r + 1):
			for dx: int in range(-r, r + 1):
				var pos := Vector2i(center.x + dx, center.y + dy)
				if map_data.in_bounds(pos.x, pos.y):
					var cell := map_data.get_cell_v(pos)
					if cell and cell.is_passable():
						return pos
	return center


func _spawn_starting_items() -> void:
	if map_data == null or not ThingManager:
		return
	var center := Vector2i(map_data.width / 2, map_data.height / 2)
	var starting_items: Array[Dictionary] = [
		{"def": "Steel", "count": 450},
		{"def": "Wood", "count": 300},
		{"def": "Silver", "count": 500},
		{"def": "Components", "count": 20},
		{"def": "Medicine", "count": 24},
		{"def": "MealSimple", "count": 30},
		{"def": "Cloth", "count": 60},
	]
	var offset := 0
	for item_def: Dictionary in starting_items:
		var pos := _find_passable_near(center + Vector2i(offset % 5 - 2, offset / 5 - 1), 5)
		var item := Item.new(item_def["def"], item_def["count"])
		ThingManager.spawn_thing(item, pos)
		offset += 1
	_render_things()


func _create_pawn_sprite(p: Pawn) -> void:
	var spr := Sprite2D.new()
	var frame_w: int = 12
	var frame_h: int = 14
	var img := Image.create(frame_w * 4, frame_h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var body_col := Color(0.22, 0.55, 0.22)
	var head_col := Color(0.85, 0.72, 0.58)
	var hair_col := Color(0.35, 0.22, 0.10)
	for dir: int in 4:
		var ox: int = dir * frame_w
		for y: int in range(5, 14):
			for x: int in range(2, 10):
				img.set_pixel(ox + x, y, body_col)
		match dir:
			0:  # North - show back of head
				for y: int in range(0, 5):
					for x: int in range(3, 9):
						img.set_pixel(ox + x, y, hair_col)
			1:  # East - head shifted right
				for y: int in range(0, 5):
					for x: int in range(4, 10):
						img.set_pixel(ox + x, y, head_col)
				for y: int in range(0, 3):
					img.set_pixel(ox + 9, y, hair_col)
			2:  # South - face visible
				for y: int in range(0, 5):
					for x: int in range(3, 9):
						img.set_pixel(ox + x, y, head_col)
				img.set_pixel(ox + 4, 2, Color(0.15, 0.15, 0.15))
				img.set_pixel(ox + 7, 2, Color(0.15, 0.15, 0.15))
				img.set_pixel(ox + 5, 3, Color(0.7, 0.5, 0.4))
				img.set_pixel(ox + 6, 3, Color(0.7, 0.5, 0.4))
			3:  # West - head shifted left
				for y: int in range(0, 5):
					for x: int in range(2, 8):
						img.set_pixel(ox + x, y, head_col)
				for y: int in range(0, 3):
					img.set_pixel(ox + 2, y, hair_col)
	var tex := ImageTexture.create_from_image(img)
	spr.texture = tex
	spr.hframes = 4
	spr.frame = p.facing
	spr.centered = true
	spr.z_index = 5
	add_child(spr)
	_pawn_sprites[p.id] = spr
	var initial_pos := Vector2(p.grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
		p.grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0)
	spr.position = initial_pos
	_pawn_target_pos[p.id] = initial_pos
	spr.frame = p.facing


func _update_pawn_sprite_pos(p: Pawn) -> void:
	if _pawn_sprites.has(p.id):
		var spr: Sprite2D = _pawn_sprites[p.id]
		var target := Vector2(p.grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
			p.grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0)
		_pawn_target_pos[p.id] = target
		spr.frame = p.facing


func _place_initial_blueprints() -> void:
	if map_data == null or not ThingManager:
		return
	var center := Vector2i(map_data.width / 2, map_data.height / 2)
	var offsets: Array[Vector2i] = [
		Vector2i(-3, -3), Vector2i(-2, -3), Vector2i(-1, -3), Vector2i(0, -3), Vector2i(1, -3), Vector2i(2, -3), Vector2i(3, -3),
		Vector2i(-3, -2), Vector2i(3, -2),
		Vector2i(-3, -1), Vector2i(3, -1),
		Vector2i(-3, 0), Vector2i(3, 0),
		Vector2i(-3, 1), Vector2i(3, 1),
		Vector2i(-3, 2), Vector2i(3, 2),
		Vector2i(-3, 3), Vector2i(-2, 3), Vector2i(-1, 3), Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3),
	]
	for off: Vector2i in offsets:
		var pos := center + off
		if map_data.in_bounds(pos.x, pos.y):
			var cell := map_data.get_cell_v(pos)
			if cell and cell.is_passable():
				ThingManager.place_blueprint("Wall", pos)
	ThingManager.place_blueprint("Campfire", center)


func _on_thing_changed(_thing: Thing) -> void:
	_render_things()


func _on_pawn_moved(_old: Vector2i, _new: Vector2i, p: Pawn) -> void:
	_update_pawn_sprite_pos(p)


func _spawn_wildlife() -> void:
	if map_data == null or not AnimalManager:
		return
	AnimalManager.spawn_wildlife(map_data, 15)
	for a: Animal in AnimalManager.animals:
		_create_animal_sprite(a)
		a.position_changed.connect(_on_animal_moved.bind(a))


func _create_animal_sprite(a: Animal) -> void:
	var spr := Sprite2D.new()
	var img := Image.create(10, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := a.get_color()
	var body := Color(c[0], c[1], c[2], 1.0)
	for y: int in range(2, 8):
		for x: int in range(1, 9):
			img.set_pixel(x, y, body)
	for x: int in range(2, 6):
		img.set_pixel(x, 1, body.lightened(0.15))
	spr.texture = ImageTexture.create_from_image(img)
	spr.centered = true
	spr.z_index = 4
	add_child(spr)
	_animal_sprites[a.id] = spr
	var apos := Vector2(a.grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
		a.grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0)
	spr.position = apos
	_animal_target_pos[a.id] = apos


func _on_animal_moved(_old: Vector2i, _new: Vector2i, a: Animal) -> void:
	var target := Vector2(a.grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
		a.grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0)
	_animal_target_pos[a.id] = target


func _ensure_animal_sprites() -> void:
	if not AnimalManager:
		return
	for a: Animal in AnimalManager.animals:
		if a.dead:
			if _animal_sprites.has(a.id):
				(_animal_sprites[a.id] as Sprite2D).queue_free()
				_animal_sprites.erase(a.id)
			continue
		if not _animal_sprites.has(a.id):
			_create_animal_sprite(a)
			a.position_changed.connect(_on_animal_moved.bind(a))


func _render_things() -> void:
	if map_data == null or not ThingManager:
		return
	_thing_layer.clear()
	for thing: Thing in ThingManager.things:
		if thing.state != Thing.ThingState.SPAWNED:
			continue
		var tx: int = thing.grid_pos.x
		var ty: int = thing.grid_pos.y
		if tx >= 0 and tx < map_data.width and ty >= 0 and ty < map_data.height:
			var col: Color
			var state_suffix := ""
			if thing is Plant:
				var plant := thing as Plant
				col = Color(0.1, 0.3 + plant.growth * 0.5, 0.1)
			elif thing is Item:
				col = Color(0.8, 0.75, 0.3)
			elif thing is Building:
				col = thing.get_color()
				state_suffix = "_%d" % (thing as Building).build_state
			else:
				col = thing.get_color()
			var key := "thing_%d_%d%s" % [tx, ty, state_suffix]
			if not _terrain_id_map.has(key):
				_add_color_tile(col, key)
			_thing_layer.set_cell(Vector2i(tx, ty), 0, _terrain_id_map[key])

func ensure_pawn_sprites() -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if not _pawn_sprites.has(p.id):
			_create_pawn_sprite(p)
			p.position_changed.connect(_on_pawn_moved.bind(p))


func _build_tileset() -> void:
	_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(CELL_SIZE, CELL_SIZE)

	var terrain_colors: Dictionary = {
		"Soil": Color(0.45, 0.35, 0.2),
		"SoilRich": Color(0.35, 0.28, 0.15),
		"Sand": Color(0.78, 0.72, 0.5),
		"Gravel": Color(0.55, 0.5, 0.42),
		"MarshyTerrain": Color(0.3, 0.38, 0.2),
		"Mud": Color(0.4, 0.32, 0.18),
		"Ice": Color(0.82, 0.88, 0.95),
		"WaterShallow": Color(0.25, 0.4, 0.6),
		"WaterDeep": Color(0.15, 0.25, 0.45),
		"RoughStone": Color(0.5, 0.48, 0.45),
		"Mountain": Color(0.32, 0.30, 0.28),
		"Cave": Color(0.20, 0.18, 0.16),
		"OreGold": Color(0.78, 0.70, 0.24),
		"OreUranium": Color(0.39, 0.66, 0.39),
		"OreJade": Color(0.31, 0.63, 0.43),
		"OrePlasteel": Color(0.63, 0.74, 0.82),
		"OreSteel": Color(0.55, 0.61, 0.65),
		"OreCompacted": Color(0.51, 0.51, 0.49),
	}

	var cols := terrain_colors.size()
	var atlas_w: int = cols * CELL_SIZE
	var atlas_img := Image.create(atlas_w, CELL_SIZE, false, Image.FORMAT_RGBA8)

	_terrain_rng.seed = 12345
	var idx: int = 0
	for tname: String in terrain_colors:
		var base_col: Color = terrain_colors[tname]
		var x_off: int = idx * CELL_SIZE
		for py: int in CELL_SIZE:
			for px: int in CELL_SIZE:
				var noise_val: float = _terrain_rng.randf_range(-0.04, 0.04)
				var c := Color(
					clampf(base_col.r + noise_val, 0.0, 1.0),
					clampf(base_col.g + noise_val, 0.0, 1.0),
					clampf(base_col.b + noise_val, 0.0, 1.0),
					1.0)
				atlas_img.set_pixel(x_off + px, py, c)
		_terrain_id_map[tname] = Vector2i(idx, 0)
		idx += 1

	var atlas_tex := ImageTexture.create_from_image(atlas_img)
	var source := TileSetAtlasSource.new()
	source.texture = atlas_tex
	source.texture_region_size = Vector2i(CELL_SIZE, CELL_SIZE)
	for i: int in cols:
		source.create_tile(Vector2i(i, 0))

	_tileset.add_source(source, 0)


func _add_color_tile(col: Color, key: String) -> void:
	var source: TileSetAtlasSource = _tileset.get_source(0) as TileSetAtlasSource
	var atlas_img: Image = source.texture.get_image()
	var cur_w := atlas_img.get_width()
	var new_w := cur_w + CELL_SIZE
	atlas_img.crop(new_w, CELL_SIZE)
	_terrain_rng.seed = hash(key)
	for py: int in CELL_SIZE:
		for px: int in CELL_SIZE:
			var nv: float = _terrain_rng.randf_range(-0.03, 0.03)
			var c := Color(
				clampf(col.r + nv, 0.0, 1.0),
				clampf(col.g + nv, 0.0, 1.0),
				clampf(col.b + nv, 0.0, 1.0),
				col.a)
			atlas_img.set_pixel(cur_w + px, py, c)
	var new_coord := Vector2i(cur_w / CELL_SIZE, 0)
	source.texture = ImageTexture.create_from_image(atlas_img)
	source.create_tile(new_coord)
	_terrain_id_map[key] = new_coord


func _render_map() -> void:
	if map_data == null:
		return
	_terrain_layer.clear()
	var w := map_data.width
	var h := map_data.height
	for y: int in h:
		for x: int in w:
			var cell: Cell = map_data.cells[y * w + x]
			var key := _terrain_key(cell)
			if _terrain_id_map.has(key):
				_terrain_layer.set_cell(Vector2i(x, y), 0, _terrain_id_map[key])


func _terrain_key(cell: Cell) -> String:
	if cell.is_mountain:
		match cell.ore:
			"Gold": return "OreGold"
			"Uranium": return "OreUranium"
			"Jade": return "OreJade"
			"Plasteel": return "OrePlasteel"
			"Steel": return "OreSteel"
			"Compacted": return "OreCompacted"
		return "Mountain"
	if cell.feature == "Cave":
		return "Cave"
	return cell.terrain_def if _terrain_id_map.has(cell.terrain_def) else "Soil"


func get_visible_pawn_count() -> int:
	var cnt: int = 0
	for pid: int in _pawn_sprites:
		var spr: Sprite2D = _pawn_sprites[pid]
		if spr.visible:
			cnt += 1
	return cnt


func get_visible_animal_count() -> int:
	var cnt: int = 0
	for aid: int in _animal_sprites:
		var spr: Sprite2D = _animal_sprites[aid]
		if spr.visible:
			cnt += 1
	return cnt


func get_camera_center_cell() -> Vector2i:
	if _camera == null:
		return Vector2i.ZERO
	return Vector2i(int(_camera.position.x / CELL_SIZE), int(_camera.position.y / CELL_SIZE))


func center_on_cell(cell_pos: Vector2i) -> void:
	if _camera == null:
		return
	_camera.position = Vector2(cell_pos.x * CELL_SIZE + CELL_SIZE * 0.5, cell_pos.y * CELL_SIZE + CELL_SIZE * 0.5)


func _is_zone_designator(designator: String) -> bool:
	return ZONE_DESIGNATOR_MAP.has(designator)


func _get_zone_type(designator: String) -> String:
	return ZONE_DESIGNATOR_MAP.get(designator, "")


func set_placement_mode(designator: String) -> void:
	_placement_mode = designator
	_zone_dragging = false
	_placement_rotation = 0
	if _placement_ghost == null:
		_placement_ghost = Sprite2D.new()
		_placement_ghost.z_index = 10
		_placement_ghost.visible = false
		_placement_ghost.centered = false
		add_child(_placement_ghost)
	if designator.is_empty():
		_placement_ghost.visible = false
		_placement_ghost.rotation = 0.0
	else:
		_placement_ghost.rotation = 0.0
		var ghost_color := Color(0.3, 0.8, 0.3, 0.45)
		if _is_zone_designator(designator) and ZoneManager:
			var zt := _get_zone_type(designator)
			ghost_color = ZoneManager.get_zone_color(zt)
			ghost_color.a = 0.55
		var img := Image.create(CELL_SIZE, CELL_SIZE, false, Image.FORMAT_RGBA8)
		img.fill(ghost_color)
		_placement_ghost.texture = ImageTexture.create_from_image(img)
		_placement_ghost.visible = false


func clear_placement_mode() -> void:
	_placement_mode = ""
	if _placement_ghost:
		_placement_ghost.visible = false


func _screen_to_cell(screen_pos: Vector2) -> Vector2i:
	var world_pos := (screen_pos - get_viewport_rect().size * 0.5) / _camera.zoom + _camera.position
	return Vector2i(int(world_pos.x / CELL_SIZE), int(world_pos.y / CELL_SIZE))


func screen_to_cell(screen_pos: Vector2) -> Vector2i:
	return _screen_to_cell(screen_pos)


func _try_place_blueprint(cell_pos: Vector2i) -> void:
	if map_data == null:
		return
	if not map_data.in_bounds(cell_pos.x, cell_pos.y):
		return
	if _is_zone_designator(_placement_mode):
		_try_place_zone(cell_pos)
		return
	if not ThingManager:
		return
	var cell := map_data.get_cell_v(cell_pos)
	if cell == null or not cell.is_passable():
		return
	ThingManager.place_blueprint(_placement_mode, cell_pos)
	if ColonyLog:
		var rot_labels: Array[String] = ["N", "E", "S", "W"]
		var rot_label: String = rot_labels[_placement_rotation]
		ColonyLog.add_entry("Build", "Blueprint placed: %s at (%d,%d) facing %s" % [_placement_mode, cell_pos.x, cell_pos.y, rot_label], "info")


func _try_place_zone(cell_pos: Vector2i) -> void:
	if not ZoneManager:
		return
	var zt := _get_zone_type(_placement_mode)
	if zt.is_empty():
		return
	if ZoneManager.place_zone(zt, cell_pos):
		if ColonyLog:
			ColonyLog.add_entry("Zone", "%s zone placed at (%d,%d)" % [zt, cell_pos.x, cell_pos.y], "info")


func _place_zone_rect(from: Vector2i, to: Vector2i) -> void:
	if not ZoneManager:
		return
	var zt := _get_zone_type(_placement_mode)
	if zt.is_empty():
		return
	var count := ZoneManager.place_zone_rect(zt, from, to)
	if count > 0 and ColonyLog:
		ColonyLog.add_entry("Zone", "%s zone: %d cells placed" % [zt, count], "info")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mb.pressed
			_drag_start = mb.position
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.zoom *= 1.15
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.zoom /= 1.15
			_camera.zoom = Vector2(maxf(_camera.zoom.x, 0.2), maxf(_camera.zoom.y, 0.2))
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if not _placement_mode.is_empty():
					var cell_pos := _screen_to_cell(mb.position)
					if _is_zone_designator(_placement_mode):
						_zone_dragging = true
						_zone_drag_start = cell_pos
					else:
						_try_place_blueprint(cell_pos)
				else:
					_select_dragging = true
					_select_start_screen = mb.position
			elif not mb.pressed:
				if _zone_dragging:
					var cell_pos := _screen_to_cell(mb.position)
					_place_zone_rect(_zone_drag_start, cell_pos)
					_zone_dragging = false
				elif _select_dragging:
					_select_dragging = false
					_hide_select_rect()
					var dist := mb.position.distance_to(_select_start_screen)
					if dist < 8.0:
						var cell_pos := _screen_to_cell(mb.position)
						_try_select_pawn(cell_pos)
					else:
						_box_select_pawns(_select_start_screen, mb.position)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if not _placement_mode.is_empty():
				clear_placement_mode()
			else:
				var cell_pos := _screen_to_cell(mb.position)
				if not _try_draft_move(cell_pos):
					_show_context_menu(cell_pos, mb.position)

	elif event is InputEventKey:
		var ek := event as InputEventKey
		if ek.pressed and not ek.echo and ek.keycode == KEY_R:
			if not _placement_mode.is_empty() and not _is_zone_designator(_placement_mode):
				_placement_rotation = (_placement_rotation + 1) % 4
				if _placement_ghost:
					_placement_ghost.rotation = _placement_rotation * PI * 0.5

	elif event is InputEventMouseMotion:
		if _dragging:
			var mm := event as InputEventMouseMotion
			_camera.position -= mm.relative / _camera.zoom
		elif not _placement_mode.is_empty() and _placement_ghost:
			var mm := event as InputEventMouseMotion
			var cell_pos := _screen_to_cell(mm.position)
			_placement_ghost.position = Vector2(cell_pos.x * CELL_SIZE, cell_pos.y * CELL_SIZE)
			_placement_ghost.visible = map_data != null and map_data.in_bounds(cell_pos.x, cell_pos.y)
		elif _select_dragging:
			var mm := event as InputEventMouseMotion
			_update_select_rect(_select_start_screen, mm.position)


func _try_select_pawn(cell_pos: Vector2i) -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.grid_pos == cell_pos and not p.dead:
			_selected_pawn_id = p.id
			pawn_selected.emit(_pawn_to_colonist_dict(p))
			return
	_selected_pawn_id = -1
	pawn_selected.emit({})


func _try_draft_move(cell_pos: Vector2i) -> bool:
	if _selected_pawn_id < 0 or not PawnManager:
		return false
	var p: Pawn = _get_pawn_by_id(_selected_pawn_id)
	if p == null or not p.drafted:
		return false
	if map_data == null or not map_data.in_bounds(cell_pos.x, cell_pos.y):
		return false
	var cell := map_data.get_cell_v(cell_pos)
	if cell == null or not cell.is_passable():
		return false

	var pf := Pathfinder.new(map_data)
	var path_result: Array[Vector2i] = pf.find_path(p.grid_pos, cell_pos)
	if path_result.is_empty():
		return false
	p.path = path_result
	p.path_index = 0
	p.current_job_name = "DraftMove"
	draft_move_issued.emit(p.id, cell_pos)
	return true


func _get_pawn_by_id(pid: int) -> Pawn:
	if not PawnManager:
		return null
	for p: Pawn in PawnManager.pawns:
		if p.id == pid:
			return p
	return null


func set_selected_pawn_id(pid: int) -> void:
	_selected_pawn_id = pid


func _pawn_to_colonist_dict(p: Pawn) -> Dictionary:
	var skill_levels: Dictionary = {}
	for sk: String in p.skills:
		skill_levels[sk] = p.skills[sk].get("level", 0)

	var health_parts: Array[Dictionary] = []
	if p.health:
		for bp: Dictionary in p.health.body_parts:
			var max_hp: float = float(bp.get("max_hp", 10))
			var cur_hp: float = float(bp.get("hp", max_hp))
			var ratio: float = cur_hp / maxf(max_hp, 1.0)
			var status := "OK" if ratio >= 0.9 else ("Hurt" if ratio >= 0.5 else "Critical")
			health_parts.append({"part": bp.get("name", "?"), "hp": ratio, "status": status})
	if health_parts.is_empty():
		for part_name in ["Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"]:
			health_parts.append({"part": part_name, "hp": 1.0, "status": "OK"})

	var overall_health: float = 1.0
	if p.health:
		overall_health = p.health.get_overall_health()

	var thoughts: Array[Dictionary] = []
	if p.thought_tracker:
		for t: Dictionary in p.thought_tracker.thoughts:
			thoughts.append({
				"text": t.get("label", t.get("id", "?")),
				"value": int(t.get("mood", 0.0) * 100),
			})

	var gear: Array[Dictionary] = []
	if p.equipment:
		for slot: String in p.equipment.slots:
			var item_name: String = p.equipment.slots[slot]
			if not item_name.is_empty():
				gear.append({"slot": slot, "name": item_name})
	var armor_sharp: float = p.equipment.get_armor_sharp() if p.equipment else 0.0
	var armor_blunt: float = p.equipment.get_armor_blunt() if p.equipment else 0.0
	var cold_insul: float = p.equipment.get_insulation_cold() if p.equipment else 0.0
	var heat_insul: float = p.equipment.get_insulation_heat() if p.equipment else 0.0

	return {
		"name": p.pawn_name,
		"age": p.age,
		"gender": p.gender,
		"main_skill": p.get_best_skill(),
		"mood": p.get_need("Mood"),
		"food": p.get_need("Food"),
		"rest": p.get_need("Rest"),
		"joy": p.get_need("Joy"),
		"health": overall_health,
		"drafted": p.drafted,
		"skills": skill_levels,
		"health_parts": health_parts,
		"traits": Array(p.traits),
		"backstory": p.backstory,
		"current_job": p.current_job_name,
		"mental_state": p.mental_state,
		"thoughts": thoughts,
		"pawn_id": p.id,
		"head_texture": "",
		"gear": gear,
		"armor_sharp": armor_sharp,
		"armor_blunt": armor_blunt,
		"insulation_cold": cold_insul,
		"insulation_heat": heat_insul,
	}


func get_map_resolution() -> Vector2i:
	if map_data == null:
		return Vector2i.ZERO
	return Vector2i(map_data.width, map_data.height)

func get_zoom_level() -> float:
	if _camera == null:
		return 1.0
	return snappedf(_camera.zoom.x, 0.01)

func get_total_entity_sprites() -> int:
	return _pawn_sprites.size() + _animal_sprites.size()

func get_pawn_density() -> float:
	var res: Vector2i = get_map_resolution()
	var area: int = res.x * res.y
	if area <= 0:
		return 0.0
	return snappedf(float(_pawn_sprites.size()) / float(area) * 1000.0, 0.01)


func get_is_zoomed_in() -> bool:
	return get_zoom_level() > 1.5


func get_visible_ratio() -> float:
	var total: int = _pawn_sprites.size() + _animal_sprites.size()
	if total <= 0:
		return 0.0
	var visible: int = get_visible_pawn_count() + get_visible_animal_count()
	return snappedf(float(visible) / float(total) * 100.0, 0.1)


func get_render_load_score() -> float:
	var sprites := get_total_entity_sprites()
	var zoom := get_zoom_level()
	var visible := get_visible_ratio()
	return snapped(float(sprites) * zoom * (visible / 100.0), 0.1)

func get_viewport_coverage_pct() -> float:
	var res := get_map_resolution()
	if res.x <= 0 or res.y <= 0:
		return 0.0
	var zoom := get_zoom_level()
	var viewport_area := (1920.0 / zoom) * (1080.0 / zoom)
	var map_area := float(res.x * res.y) * float(CELL_SIZE * CELL_SIZE)
	return snapped(minf(viewport_area / maxf(map_area, 1.0) * 100.0, 100.0), 0.1)

func get_visual_clarity() -> String:
	var density := get_pawn_density()
	var zoom := get_zoom_level()
	if zoom >= 1.5 and density < 0.1:
		return "Excellent"
	elif zoom >= 1.0 and density < 0.3:
		return "Good"
	elif density < 0.5:
		return "Fair"
	return "Cluttered"

func get_summary() -> Dictionary:
	return {
		"visible_pawns": get_visible_pawn_count(),
		"visible_animals": get_visible_animal_count(),
		"camera_center": [get_camera_center_cell().x, get_camera_center_cell().y],
		"map_resolution": [get_map_resolution().x, get_map_resolution().y],
		"zoom_level": get_zoom_level(),
		"total_sprites": get_total_entity_sprites(),
		"pawn_density": get_pawn_density(),
		"is_zoomed_in": get_is_zoomed_in(),
		"visible_ratio_pct": get_visible_ratio(),
		"render_load": get_render_load_score(),
		"viewport_coverage_pct": get_viewport_coverage_pct(),
		"visual_clarity": get_visual_clarity(),
	}

func _on_date_changed(date: Dictionary) -> void:
	_update_day_night(date.get("hour", 12))


func _on_weather_changed(_old: String, new_type: String) -> void:
	_update_weather_vfx(new_type)


func _update_weather_vfx(weather: String) -> void:
	if _weather_particles == null:
		return
	match weather:
		"Rain":
			_weather_particles.emitting = true
			_weather_particles.amount = 250
			_weather_particles.color = Color(0.6, 0.65, 0.8, 0.35)
			_weather_particles.initial_velocity_min = 120.0
			_weather_particles.initial_velocity_max = 200.0
			_weather_particles.gravity = Vector2(30, 300)
			_weather_particles.scale_amount_min = 0.5
			_weather_particles.scale_amount_max = 1.0
		"Drizzle":
			_weather_particles.emitting = true
			_weather_particles.amount = 100
			_weather_particles.color = Color(0.65, 0.7, 0.8, 0.2)
			_weather_particles.initial_velocity_min = 60.0
			_weather_particles.initial_velocity_max = 100.0
			_weather_particles.gravity = Vector2(10, 150)
			_weather_particles.scale_amount_min = 0.3
			_weather_particles.scale_amount_max = 0.6
		"Snow":
			_weather_particles.emitting = true
			_weather_particles.amount = 180
			_weather_particles.color = Color(0.9, 0.92, 0.95, 0.5)
			_weather_particles.initial_velocity_min = 20.0
			_weather_particles.initial_velocity_max = 50.0
			_weather_particles.gravity = Vector2(15, 40)
			_weather_particles.spread = 45.0
			_weather_particles.scale_amount_min = 1.0
			_weather_particles.scale_amount_max = 2.5
		"Thunderstorm":
			_weather_particles.emitting = true
			_weather_particles.amount = 400
			_weather_particles.color = Color(0.5, 0.55, 0.7, 0.45)
			_weather_particles.initial_velocity_min = 180.0
			_weather_particles.initial_velocity_max = 300.0
			_weather_particles.gravity = Vector2(60, 400)
			_weather_particles.scale_amount_min = 0.6
			_weather_particles.scale_amount_max = 1.2
		"Hail":
			_weather_particles.emitting = true
			_weather_particles.amount = 120
			_weather_particles.color = Color(0.85, 0.88, 0.95, 0.6)
			_weather_particles.initial_velocity_min = 150.0
			_weather_particles.initial_velocity_max = 250.0
			_weather_particles.gravity = Vector2(20, 500)
			_weather_particles.scale_amount_min = 1.5
			_weather_particles.scale_amount_max = 3.0
		_:
			_weather_particles.emitting = false


func _update_day_night(hour: int) -> void:
	if _day_night_mod == null:
		return
	var t: float = float(hour)
	var color: Color
	if t >= 6.0 and t < 7.0:
		color = Color(0.6, 0.55, 0.7).lerp(Color.WHITE, t - 6.0)
	elif t >= 7.0 and t < 18.0:
		color = Color.WHITE
	elif t >= 18.0 and t < 20.0:
		var sunset_progress: float = (t - 18.0) / 2.0
		color = Color.WHITE.lerp(Color(0.9, 0.6, 0.4), sunset_progress)
	elif t >= 20.0 and t < 22.0:
		var dusk_progress: float = (t - 20.0) / 2.0
		color = Color(0.9, 0.6, 0.4).lerp(Color(0.25, 0.25, 0.4), dusk_progress)
	elif t >= 22.0 or t < 4.0:
		color = Color(0.25, 0.25, 0.4)
	elif t >= 4.0 and t < 6.0:
		var dawn_progress: float = (t - 4.0) / 2.0
		color = Color(0.25, 0.25, 0.4).lerp(Color(0.6, 0.55, 0.7), dawn_progress)
	else:
		color = Color.WHITE
	_day_night_mod.color = color


var _sync_timer: float = 0.0

func _process(delta: float) -> void:
	_sync_timer += delta
	if _sync_timer > 2.0:
		_sync_timer = 0.0
		ensure_pawn_sprites()
		_ensure_animal_sprites()
	var move := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		move.x -= 1
	if Input.is_action_pressed("ui_right"):
		move.x += 1
	if Input.is_action_pressed("ui_up"):
		move.y -= 1
	if Input.is_action_pressed("ui_down"):
		move.y += 1

	var vp_size := get_viewport_rect().size
	var mouse := get_viewport().get_mouse_position()
	if mouse.x <= EDGE_SCROLL_MARGIN:
		move.x -= 1
	elif mouse.x >= vp_size.x - EDGE_SCROLL_MARGIN:
		move.x += 1
	if mouse.y <= EDGE_SCROLL_MARGIN:
		move.y -= 1
	elif mouse.y >= vp_size.y - EDGE_SCROLL_MARGIN:
		move.y += 1

	if move != Vector2.ZERO:
		_camera.position += move.normalized() * 300.0 * delta / _camera.zoom.x
	_lerp_sprites(delta)
	if _weather_particles and _weather_particles.emitting:
		_weather_particles.position = _camera.position + Vector2(0, -600)


func _update_select_rect(start: Vector2, end: Vector2) -> void:
	if _select_rect == null:
		_select_rect = ColorRect.new()
		_select_rect.color = Color(0.3, 0.7, 1.0, 0.15)
		_select_rect.z_index = 20
		_select_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		get_viewport().get_window().add_child(_select_rect)
	var min_x := minf(start.x, end.x)
	var min_y := minf(start.y, end.y)
	var w := absf(end.x - start.x)
	var h := absf(end.y - start.y)
	_select_rect.position = Vector2(min_x, min_y)
	_select_rect.size = Vector2(w, h)
	_select_rect.visible = true


func _hide_select_rect() -> void:
	if _select_rect and is_instance_valid(_select_rect):
		_select_rect.visible = false


func _box_select_pawns(start_screen: Vector2, end_screen: Vector2) -> void:
	if not PawnManager:
		return
	var start_cell := _screen_to_cell(start_screen)
	var end_cell := _screen_to_cell(end_screen)
	var min_x := mini(start_cell.x, end_cell.x)
	var max_x := maxi(start_cell.x, end_cell.x)
	var min_y := mini(start_cell.y, end_cell.y)
	var max_y := maxi(start_cell.y, end_cell.y)
	var selected_ids: Array[int] = []
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if p.grid_pos.x >= min_x and p.grid_pos.x <= max_x and \
		   p.grid_pos.y >= min_y and p.grid_pos.y <= max_y:
			selected_ids.append(p.id)
	if selected_ids.size() == 1:
		var p: Pawn = _get_pawn_by_id(selected_ids[0])
		if p:
			_selected_pawn_id = p.id
			pawn_selected.emit(_pawn_to_colonist_dict(p))
	elif selected_ids.size() > 1:
		_selected_pawn_id = selected_ids[0]
		multi_pawns_selected.emit(selected_ids)


func _lerp_sprites(delta: float) -> void:
	var lerp_factor: float = minf(MOVE_LERP_SPEED * delta, 1.0)
	for pid: int in _pawn_sprites:
		if _pawn_target_pos.has(pid):
			var spr: Sprite2D = _pawn_sprites[pid]
			var target: Vector2 = _pawn_target_pos[pid]
			if spr.position.distance_squared_to(target) > 0.5:
				spr.position = spr.position.lerp(target, lerp_factor)
			else:
				spr.position = target
	for aid: int in _animal_sprites:
		if _animal_target_pos.has(aid):
			var spr: Sprite2D = _animal_sprites[aid]
			var target: Vector2 = _animal_target_pos[aid]
			if spr.position.distance_squared_to(target) > 0.5:
				spr.position = spr.position.lerp(target, lerp_factor)
			else:
				spr.position = target


func _render_zones() -> void:
	if map_data == null:
		return
	var w := map_data.width
	var h := map_data.height
	var img_w := w * CELL_SIZE
	var img_h := h * CELL_SIZE
	_zone_image = Image.create(img_w, img_h, false, Image.FORMAT_RGBA8)
	_zone_image.fill(Color(0, 0, 0, 0))

	if ZoneManager:
		for pos: Vector2i in ZoneManager.zones:
			var zone_type: String = ZoneManager.zones[pos]
			var col: Color = ZoneManager.get_zone_color(zone_type)
			_fill_zone_cell(_zone_image, pos, col)

	_zone_texture = ImageTexture.create_from_image(_zone_image)
	_zone_sprite.texture = _zone_texture


func _fill_zone_cell(img: Image, cell: Vector2i, col: Color) -> void:
	var ox := cell.x * CELL_SIZE
	var oy := cell.y * CELL_SIZE
	for py: int in CELL_SIZE:
		for px: int in CELL_SIZE:
			var x := ox + px
			var y := oy + py
			if x < img.get_width() and y < img.get_height():
				img.set_pixel(x, y, col)


func _on_zone_changed(_zone_type: String, pos: Vector2i) -> void:
	if _zone_image == null:
		_render_zones()
		return
	var zt: String = ZoneManager.zones.get(pos, "")
	if zt.is_empty():
		return
	var col: Color = ZoneManager.get_zone_color(zt)
	_fill_zone_cell(_zone_image, pos, col)
	_zone_texture.update(_zone_image)


func _on_zone_removed(pos: Vector2i) -> void:
	if _zone_image == null:
		return
	_fill_zone_cell(_zone_image, pos, Color(0, 0, 0, 0))
	_zone_texture.update(_zone_image)


func _show_context_menu(cell_pos: Vector2i, screen_pos: Vector2) -> void:
	if map_data == null or not map_data.in_bounds(cell_pos.x, cell_pos.y):
		return
	var options: Array[Dictionary] = []

	if ThingManager:
		var things_at: Array = ThingManager.get_things_at(cell_pos)
		for thing: Thing in things_at:
			if thing is Building:
				var bld := thing as Building
				if bld.build_state == Building.BuildState.COMPLETE:
					options.append({"label": "Deconstruct " + bld.def_name, "action": "deconstruct", "target_pos": cell_pos})
					if bld.is_damaged():
						options.append({"label": "Prioritize repair", "action": "repair", "target_pos": cell_pos})
					if bld.def_name in BENCH_DEFS:
						options.append({"label": "Set bills...", "action": "workbench_bills", "target_pos": cell_pos, "bench_name": bld.def_name})
				else:
					options.append({"label": "Cancel " + bld.def_name, "action": "cancel_build", "target_pos": cell_pos})
					options.append({"label": "Prioritize build", "action": "prioritize_build", "target_pos": cell_pos})
			elif thing is Plant:
				options.append({"label": "Cut " + thing.def_name, "action": "cut_plant", "target_pos": cell_pos})
				if (thing as Plant).growth >= 0.9:
					options.append({"label": "Harvest " + thing.def_name, "action": "harvest", "target_pos": cell_pos})
			elif thing is Item:
				options.append({"label": "Haul " + thing.def_name, "action": "haul", "target_pos": cell_pos})

	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.grid_pos == cell_pos and not p.dead:
				if not p.drafted:
					options.append({"label": "Draft " + p.pawn_name, "action": "draft", "pawn_id": p.id})
				else:
					options.append({"label": "Undraft " + p.pawn_name, "action": "undraft", "pawn_id": p.id})

	var cell := map_data.get_cell_v(cell_pos)
	if cell and not cell.zone.is_empty():
		options.append({"label": "Remove zone", "action": "remove_zone", "target_pos": cell_pos})
		if cell.zone == "stockpile":
			options.append({"label": "Stockpile settings...", "action": "stockpile_config", "target_pos": cell_pos})

	if cell and cell.is_mountain:
		options.append({"label": "Mine", "action": "mine", "target_pos": cell_pos})

	if options.is_empty():
		return
	context_menu_requested.emit(cell_pos, screen_pos, options)


func toggle_power_overlay() -> void:
	_power_overlay_visible = not _power_overlay_visible
	if _power_overlay_visible:
		_render_power_overlay()
	_power_overlay_sprite.visible = _power_overlay_visible


func _render_power_overlay() -> void:
	if map_data == null:
		return
	var w := map_data.width
	var h := map_data.height
	var img_w := w * CELL_SIZE
	var img_h := h * CELL_SIZE
	var img := Image.create(img_w, img_h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	if not ThingManager:
		return

	var color_gen := Color(0.2, 0.8, 0.3, 0.4)
	var color_draw := Color(0.8, 0.3, 0.2, 0.4)
	var color_conduit := Color(0.5, 0.5, 0.1, 0.3)
	var color_battery := Color(0.3, 0.5, 0.8, 0.4)

	var power_data: Dictionary = {
		"WoodFiredGenerator": "gen", "SolarGenerator": "gen",
		"Battery": "battery",
		"PowerConduit": "conduit",
		"MiniTurret": "draw", "CookingStove": "draw",
		"MachiningTable": "draw", "HiTechResearchBench": "draw",
		"CommsConsole": "draw", "SunLamp": "draw",
		"FabricationBench": "draw",
	}

	for t: Thing in ThingManager.things:
		if not (t is Building):
			continue
		var bld := t as Building
		var ptype: String = power_data.get(bld.def_name, "")
		if ptype.is_empty():
			continue
		var col: Color
		match ptype:
			"gen":
				col = color_gen
			"draw":
				col = color_draw
			"conduit":
				col = color_conduit
			"battery":
				col = color_battery
			_:
				continue
		_fill_power_cell(img, bld.grid_pos, col)

	var tex := ImageTexture.create_from_image(img)
	_power_overlay_sprite.texture = tex


func _fill_power_cell(img: Image, cell: Vector2i, col: Color) -> void:
	var ox := cell.x * CELL_SIZE
	var oy := cell.y * CELL_SIZE
	for py: int in CELL_SIZE:
		for px: int in CELL_SIZE:
			var x := ox + px
			var y := oy + py
			if x < img.get_width() and y < img.get_height():
				img.set_pixel(x, y, col)


func toggle_beauty_overlay() -> void:
	_beauty_overlay_visible = not _beauty_overlay_visible
	if _beauty_overlay_visible:
		_render_beauty_overlay()
	_beauty_overlay_sprite.visible = _beauty_overlay_visible


func _render_beauty_overlay() -> void:
	if map_data == null:
		return
	var w: int = map_data.width
	var h: int = map_data.height
	var img := Image.create(w * CELL_SIZE, h * CELL_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for cy: int in h:
		for cx: int in w:
			var beauty: float = 0.0
			if ThingManager:
				for thing in ThingManager.things_at(Vector2i(cx, cy)):
					beauty += thing.get("beauty", 0.0) if thing is Dictionary else 0.0
			if absf(beauty) < 0.1:
				continue
			var col: Color
			if beauty > 0:
				var t: float = clampf(beauty / 10.0, 0.0, 1.0)
				col = Color(0.2, 0.8, 0.3, 0.2 + t * 0.4)
			else:
				var t: float = clampf(-beauty / 10.0, 0.0, 1.0)
				col = Color(0.8, 0.2, 0.2, 0.2 + t * 0.4)
			_fill_power_cell(img, Vector2i(cx, cy), col)
	_beauty_overlay_sprite.texture = ImageTexture.create_from_image(img)


func toggle_temp_overlay() -> void:
	_temp_overlay_visible = not _temp_overlay_visible
	if _temp_overlay_visible:
		_render_temp_overlay()
	_temp_overlay_sprite.visible = _temp_overlay_visible


func _render_temp_overlay() -> void:
	if map_data == null:
		return
	var w: int = map_data.width
	var h: int = map_data.height
	var base_temp: float = 20.0
	if WeatherManager and WeatherManager.has_method("get_outdoor_temp"):
		base_temp = WeatherManager.get_outdoor_temp()
	elif WeatherManager and "temperature" in WeatherManager:
		base_temp = float(WeatherManager.temperature)
	var img := Image.create(w * CELL_SIZE, h * CELL_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for cy: int in h:
		for cx: int in w:
			var cell_temp: float = base_temp
			var has_roof := false
			if ThingManager:
				for thing in ThingManager.things_at(Vector2i(cx, cy)):
					if thing is Dictionary:
						if thing.get("def_name", "") == "Roof":
							has_roof = true
					elif thing is Node and thing.has_method("get") and thing.get("def_name") == "Roof":
						has_roof = true
			if has_roof:
				cell_temp = clampf(base_temp, 15.0, 28.0)
			var col: Color
			if cell_temp < 0.0:
				var t: float = clampf(-cell_temp / 40.0, 0.0, 1.0)
				col = Color(0.2, 0.4, 1.0, 0.15 + t * 0.45)
			elif cell_temp > 30.0:
				var t: float = clampf((cell_temp - 30.0) / 30.0, 0.0, 1.0)
				col = Color(1.0, 0.3, 0.1, 0.15 + t * 0.45)
			else:
				var norm: float = clampf((cell_temp - 0.0) / 30.0, 0.0, 1.0)
				col = Color(0.3, 0.7, 0.3, 0.1 + norm * 0.15)
			_fill_power_cell(img, Vector2i(cx, cy), col)
	_temp_overlay_sprite.texture = ImageTexture.create_from_image(img)
