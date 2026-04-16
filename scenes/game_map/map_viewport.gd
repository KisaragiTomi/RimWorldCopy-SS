extends Node2D

## Renders the MapData using TileMapLayer for GPU-accelerated terrain
## plus Sprite2D overlays for pawns, animals, and things.
## Supports pan (middle-drag / WASD / arrow keys) and zoom (scroll wheel).

signal pawn_selected(pawn_data: Dictionary)
signal multi_pawns_selected(pawn_ids: Array)
signal draft_move_issued(pawn_id: int, target: Vector2i)
signal context_menu_requested(cell_pos: Vector2i, screen_pos: Vector2, options: Array)

const CELL_SIZE := 16

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
var _building_sprites: Dictionary = {}  # thing_id -> Sprite2D
var _building_textures: Dictionary = {}  # texture_key -> Texture2D
var _wall_atlas_textures: Array[Texture2D] = []  # 16 connection tiles
var _plant_sprites: Dictionary = {}  # thing_id -> Sprite2D
var _plant_textures: Dictionary = {}  # tex_name -> Texture2D
var _item_sprites: Dictionary = {}  # thing_id -> Sprite2D
var _item_textures: Dictionary = {}  # tex_name -> Texture2D
var _pawn_body_textures: Array[Texture2D] = []
var _pawn_hair_textures: Array[Texture2D] = []
var _animal_textures: Dictionary = {}  # species -> Texture2D
var _roof_sprite: Sprite2D
var _roof_image: Image
var _roof_texture: ImageTexture
var _blood_sprites: Array[Sprite2D] = []
var _blood_tex: ImageTexture

const MOVE_LERP_SPEED := 8.0

var _dragging := false
var _drag_start := Vector2.ZERO

var _placement_mode := ""
var _placement_ghost: Sprite2D
var _selected_pawn_id: int = -1

var _day_night_mod: CanvasModulate
var _weather_particles: CPUParticles2D
var _rain_splash_particles: CPUParticles2D
var _rain_streak_tex: ImageTexture
var _lightning_timer: float = 0.0
var _lightning_flash: float = 0.0
var _fog_overlay: ColorRect
var _wet_ground_sprite: Sprite2D
var _wet_ground_alpha: float = 0.0
var _wet_ground_target: float = 0.0
var _snow_ground_sprite: Sprite2D
var _snow_ground_alpha: float = 0.0
var _snow_ground_target: float = 0.0
var _zone_sprite: Sprite2D
var _zone_image: Image
var _zone_texture: ImageTexture

var _terrain_rng := RandomNumberGenerator.new()
var _floor_to_tile: Dictionary = {}
var _terrain_blend_sprite: Sprite2D
var _grid_overlay_sprite: Sprite2D
var _hover_cell_sprite: Sprite2D
var _last_hover_cell := Vector2i(-1, -1)
var _ground_clutter: Array[Sprite2D] = []
var _water_highlights: Array[Sprite2D] = []
var _water_time: float = 0.0
var _leaf_particles: CPUParticles2D
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

const ITEM_COLORS: Dictionary = {
	"Steel": Color(0.55, 0.60, 0.68),
	"Wood": Color(0.62, 0.45, 0.25),
	"Stone": Color(0.58, 0.53, 0.48),
	"Silver": Color(0.78, 0.78, 0.82),
	"Gold": Color(0.88, 0.78, 0.22),
	"Components": Color(0.45, 0.55, 0.58),
	"AdvancedComponents": Color(0.50, 0.60, 0.65),
	"Medicine": Color(0.85, 0.25, 0.25),
	"HerbalMedicine": Color(0.35, 0.72, 0.35),
	"MealSimple": Color(0.78, 0.62, 0.38),
	"MealFine": Color(0.88, 0.68, 0.32),
	"RawFood": Color(0.72, 0.52, 0.32),
	"Cloth": Color(0.72, 0.68, 0.58),
	"Leather": Color(0.58, 0.42, 0.28),
	"Meat": Color(0.72, 0.32, 0.32),
	"Corpse": Color(0.5, 0.4, 0.35),
	"AnimalCorpse": Color(0.5, 0.4, 0.35),
	"NutrientPaste": Color(0.65, 0.60, 0.45),
	"Plasteel": Color(0.72, 0.82, 0.88),
	"Uranium": Color(0.50, 0.72, 0.50),
	"Jade": Color(0.42, 0.70, 0.52),
}

const PLANT_COLORS: Dictionary = {
	"Potato": Color(0.30, 0.50, 0.18),
	"Rice": Color(0.42, 0.62, 0.22),
	"Corn": Color(0.28, 0.48, 0.12),
	"Cotton": Color(0.65, 0.68, 0.55),
	"Healroot": Color(0.22, 0.58, 0.32),
	"Tree": Color(0.12, 0.38, 0.08),
}

const PAWN_BODY_COLORS: Array[Color] = [
	Color(0.22, 0.55, 0.22),
	Color(0.25, 0.45, 0.60),
	Color(0.60, 0.35, 0.25),
	Color(0.50, 0.40, 0.55),
	Color(0.55, 0.50, 0.30),
	Color(0.35, 0.50, 0.45),
]
const PAWN_HAIR_COLORS: Array[Color] = [
	Color(0.35, 0.22, 0.10),
	Color(0.15, 0.12, 0.08),
	Color(0.55, 0.35, 0.15),
	Color(0.72, 0.55, 0.25),
	Color(0.40, 0.18, 0.12),
	Color(0.25, 0.25, 0.28),
]
const PAWN_SKIN_COLORS: Array[Color] = [
	Color(0.85, 0.72, 0.58),
	Color(0.92, 0.78, 0.62),
	Color(0.72, 0.58, 0.42),
	Color(0.58, 0.45, 0.35),
	Color(0.78, 0.65, 0.52),
	Color(0.95, 0.82, 0.68),
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

	_terrain_blend_sprite = Sprite2D.new()
	_terrain_blend_sprite.z_index = 0
	_terrain_blend_sprite.centered = false
	add_child(_terrain_blend_sprite)

	_grid_overlay_sprite = Sprite2D.new()
	_grid_overlay_sprite.z_index = 0
	_grid_overlay_sprite.centered = false
	_grid_overlay_sprite.modulate = Color(1, 1, 1, 0.35)
	add_child(_grid_overlay_sprite)

	var hover_img := Image.create(CELL_SIZE, CELL_SIZE, false, Image.FORMAT_RGBA8)
	hover_img.fill(Color(0, 0, 0, 0))
	var hover_edge := Color(1.0, 1.0, 1.0, 0.35)
	var hover_fill := Color(1.0, 1.0, 1.0, 0.06)
	for px: int in CELL_SIZE:
		hover_img.set_pixel(px, 0, hover_edge)
		hover_img.set_pixel(px, CELL_SIZE - 1, hover_edge)
	for py: int in CELL_SIZE:
		hover_img.set_pixel(0, py, hover_edge)
		hover_img.set_pixel(CELL_SIZE - 1, py, hover_edge)
	for py: int in range(1, CELL_SIZE - 1):
		for px: int in range(1, CELL_SIZE - 1):
			hover_img.set_pixel(px, py, hover_fill)
	_hover_cell_sprite = Sprite2D.new()
	_hover_cell_sprite.texture = ImageTexture.create_from_image(hover_img)
	_hover_cell_sprite.centered = false
	_hover_cell_sprite.z_index = 8
	_hover_cell_sprite.visible = false
	add_child(_hover_cell_sprite)

	_wet_ground_sprite = Sprite2D.new()
	_wet_ground_sprite.z_index = 1
	_wet_ground_sprite.centered = false
	_wet_ground_sprite.modulate = Color(1, 1, 1, 0)
	_wet_ground_sprite.visible = false
	add_child(_wet_ground_sprite)

	_snow_ground_sprite = Sprite2D.new()
	_snow_ground_sprite.z_index = 1
	_snow_ground_sprite.centered = false
	_snow_ground_sprite.modulate = Color(1, 1, 1, 0)
	_snow_ground_sprite.visible = false
	add_child(_snow_ground_sprite)

	_thing_layer = TileMapLayer.new()
	_thing_layer.tile_set = _tileset
	_thing_layer.z_index = 1
	add_child(_thing_layer)

	_roof_sprite = Sprite2D.new()
	_roof_sprite.z_index = 4
	_roof_sprite.centered = false
	add_child(_roof_sprite)

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

	var rain_img := Image.create(2, 8, false, Image.FORMAT_RGBA8)
	rain_img.fill(Color(0, 0, 0, 0))
	for y: int in range(8):
		var a: float = 0.9 - float(y) * 0.08
		rain_img.set_pixel(0, y, Color(0.75, 0.8, 0.95, a))
		rain_img.set_pixel(1, y, Color(0.7, 0.78, 0.92, a * 0.6))
	_rain_streak_tex = ImageTexture.create_from_image(rain_img)

	_weather_particles = CPUParticles2D.new()
	_weather_particles.emitting = false
	_weather_particles.z_index = 10
	_weather_particles.amount = 200
	_weather_particles.lifetime = 2.5
	_weather_particles.one_shot = false
	_weather_particles.texture = _rain_streak_tex
	_weather_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_weather_particles.emission_rect_extents = Vector2(1200, 10)
	_weather_particles.direction = Vector2(0.2, 1.0)
	_weather_particles.spread = 10.0
	_weather_particles.gravity = Vector2(0, 200)
	_weather_particles.initial_velocity_min = 80.0
	_weather_particles.initial_velocity_max = 150.0
	_weather_particles.scale_amount_min = 0.8
	_weather_particles.scale_amount_max = 1.5
	_weather_particles.color = Color(0.7, 0.75, 0.85, 0.5)
	add_child(_weather_particles)

	_rain_splash_particles = CPUParticles2D.new()
	_rain_splash_particles.emitting = false
	_rain_splash_particles.z_index = 5
	_rain_splash_particles.amount = 60
	_rain_splash_particles.lifetime = 0.4
	_rain_splash_particles.one_shot = false
	_rain_splash_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rain_splash_particles.emission_rect_extents = Vector2(1200, 800)
	_rain_splash_particles.direction = Vector2(0.0, -1.0)
	_rain_splash_particles.spread = 60.0
	_rain_splash_particles.gravity = Vector2(0, 40)
	_rain_splash_particles.initial_velocity_min = 8.0
	_rain_splash_particles.initial_velocity_max = 18.0
	_rain_splash_particles.scale_amount_min = 0.3
	_rain_splash_particles.scale_amount_max = 0.8
	_rain_splash_particles.color = Color(0.7, 0.75, 0.88, 0.3)
	add_child(_rain_splash_particles)

	_fog_overlay = ColorRect.new()
	_fog_overlay.color = Color(0.75, 0.78, 0.82, 0.0)
	_fog_overlay.size = Vector2(2600, 1600)
	_fog_overlay.z_index = 9
	_fog_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fog_overlay)

	_leaf_particles = CPUParticles2D.new()
	_leaf_particles.emitting = true
	_leaf_particles.amount = 15
	_leaf_particles.lifetime = 8.0
	_leaf_particles.one_shot = false
	_leaf_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_leaf_particles.emission_rect_extents = Vector2(800, 10)
	_leaf_particles.direction = Vector2(0.5, 1.0)
	_leaf_particles.spread = 30.0
	_leaf_particles.gravity = Vector2(5, 8)
	_leaf_particles.initial_velocity_min = 3.0
	_leaf_particles.initial_velocity_max = 10.0
	_leaf_particles.angular_velocity_min = -30.0
	_leaf_particles.angular_velocity_max = 30.0
	_leaf_particles.scale_amount_min = 1.0
	_leaf_particles.scale_amount_max = 2.0
	_leaf_particles.color = Color(0.45, 0.55, 0.25, 0.3)
	_leaf_particles.z_index = 7
	add_child(_leaf_particles)

	generate_new_map(120, 120, randi())
	_spawn_natural_vegetation()
	_spawn_ground_clutter()
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


func _spawn_natural_vegetation() -> void:
	if map_data == null or not ThingManager:
		return
	var center := Vector2i(map_data.width / 2, map_data.height / 2)
	var veg_rng := RandomNumberGenerator.new()
	veg_rng.seed = map_data.seed + 5000
	var spawned := 0
	for y: int in map_data.height:
		for x: int in map_data.width:
			var cell: Cell = map_data.cells[y * map_data.width + x]
			if cell.is_mountain or not cell.is_passable():
				continue
			var dist: float = Vector2(x, y).distance_to(Vector2(center.x, center.y))
			if dist < 15.0:
				continue
			var fert: float = cell.fertility
			var tree_chance: float = 0.0
			match cell.terrain_def:
				"SoilRich":
					tree_chance = 0.10 + fert * 0.06
				"Soil":
					tree_chance = 0.06 + fert * 0.04
				"MarshyTerrain":
					tree_chance = 0.04
				"Gravel":
					tree_chance = 0.015
			if veg_rng.randf() < tree_chance:
				var tree := Plant.new("Tree")
				tree.growth = veg_rng.randf_range(0.3, 1.0)
				tree.growth_stage = Plant.GrowthStage.GROWING if tree.growth < 0.8 else Plant.GrowthStage.HARVESTABLE
				ThingManager.spawn_thing(tree, Vector2i(x, y))
				spawned += 1


func _spawn_water_highlights() -> void:
	for spr: Sprite2D in _water_highlights:
		spr.queue_free()
	_water_highlights.clear()
	if map_data == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = map_data.seed + 4444
	var highlight_img := Image.create(6, 2, false, Image.FORMAT_RGBA8)
	highlight_img.fill(Color(0, 0, 0, 0))
	for px: int in 6:
		highlight_img.set_pixel(px, 0, Color(0.8, 0.9, 1.0, 0.25))
		if px > 0 and px < 5:
			highlight_img.set_pixel(px, 1, Color(0.7, 0.85, 1.0, 0.12))
	var highlight_tex := ImageTexture.create_from_image(highlight_img)
	var ripple_img := Image.create(8, 3, false, Image.FORMAT_RGBA8)
	ripple_img.fill(Color(0, 0, 0, 0))
	for px: int in 8:
		var fade: float = 1.0 - absf(px - 3.5) / 4.0
		ripple_img.set_pixel(px, 0, Color(0.6, 0.75, 0.95, 0.08 * fade))
		ripple_img.set_pixel(px, 1, Color(0.85, 0.92, 1.0, 0.18 * fade))
		ripple_img.set_pixel(px, 2, Color(0.6, 0.75, 0.95, 0.06 * fade))
	var ripple_tex := ImageTexture.create_from_image(ripple_img)
	for y: int in map_data.height:
		for x: int in map_data.width:
			var cell: Cell = map_data.cells[y * map_data.width + x]
			if not cell.terrain_def in ["WaterShallow", "WaterDeep"]:
				continue
			var is_deep: bool = cell.terrain_def == "WaterDeep"
			var density: float = 0.35 if is_deep else 0.25
			if rng.randf() < density:
				var use_ripple: bool = rng.randf() < 0.4
				var spr := Sprite2D.new()
				spr.texture = ripple_tex if use_ripple else highlight_tex
				spr.position = Vector2(x * CELL_SIZE + rng.randf_range(1, 15), y * CELL_SIZE + rng.randf_range(2, 14))
				spr.scale = Vector2(rng.randf_range(0.8, 1.8), rng.randf_range(0.8, 1.2))
				spr.z_index = 0
				spr.modulate.a = rng.randf_range(0.25, 0.6)
				spr.set_meta("base_x", spr.position.x)
				spr.set_meta("base_y", spr.position.y)
				spr.set_meta("phase", rng.randf() * TAU)
				spr.set_meta("speed", rng.randf_range(0.5, 1.4))
				add_child(spr)
				_water_highlights.append(spr)


func _spawn_ground_clutter() -> void:
	for spr: Sprite2D in _ground_clutter:
		spr.queue_free()
	_ground_clutter.clear()
	if map_data == null:
		return
	var grass_textures: Array[String] = ["GrassA", "BushA", "BushB"]
	var flower_textures: Array[String] = ["Dandelion", "DandelionB", "DandelionC"]
	var grass_tex: Array[Texture2D] = []
	var flower_tex: Array[Texture2D] = []
	for tname: String in grass_textures:
		if _plant_textures.has(tname):
			grass_tex.append(_plant_textures[tname])
	for tname: String in flower_textures:
		if _plant_textures.has(tname):
			flower_tex.append(_plant_textures[tname])
	if grass_tex.is_empty() and flower_tex.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = map_data.seed + 7777
	var density_map: Dictionary = {
		"SoilRich": 0.35, "Soil": 0.28, "MarshyTerrain": 0.20, "Gravel": 0.10,
		"Sand": 0.05, "Mud": 0.12,
	}
	var pebble_img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	pebble_img.fill(Color(0, 0, 0, 0))
	pebble_img.set_pixel(1, 1, Color(0.5, 0.48, 0.43, 0.35))
	pebble_img.set_pixel(2, 1, Color(0.55, 0.5, 0.45, 0.3))
	pebble_img.set_pixel(1, 2, Color(0.45, 0.42, 0.38, 0.3))
	var pebble_tex := ImageTexture.create_from_image(pebble_img)
	var rock_img := Image.create(8, 6, false, Image.FORMAT_RGBA8)
	rock_img.fill(Color(0, 0, 0, 0))
	for ry: int in range(1, 5):
		for rx: int in range(1, 7):
			var dist: float = absf(float(rx) - 3.5) / 3.5 + absf(float(ry) - 2.5) / 2.5
			if dist < 0.85:
				var shade: float = 0.48 + rng.randf_range(-0.05, 0.05)
				rock_img.set_pixel(rx, ry, Color(shade, shade * 0.95, shade * 0.9, 0.6))
	var rock_tex := ImageTexture.create_from_image(rock_img)
	var rocky_defs: PackedStringArray = ["Gravel", "RoughStone"]
	for y2: int in map_data.height:
		for x2: int in map_data.width:
			var c2: Cell = map_data.cells[y2 * map_data.width + x2]
			if not c2.terrain_def in rocky_defs:
				continue
			if rng.randf() < 0.18:
				var ps := Sprite2D.new()
				ps.texture = pebble_tex
				ps.position = Vector2(x2 * CELL_SIZE + rng.randf_range(2, 14), y2 * CELL_SIZE + rng.randf_range(2, 14))
				ps.z_index = 0
				ps.scale = Vector2(rng.randf_range(1.0, 2.5), rng.randf_range(1.0, 2.5))
				add_child(ps)
				_ground_clutter.append(ps)
			if rng.randf() < 0.10:
				var rs := Sprite2D.new()
				rs.texture = rock_tex
				rs.position = Vector2(x2 * CELL_SIZE + rng.randf_range(1, 12), y2 * CELL_SIZE + rng.randf_range(1, 12))
				rs.z_index = 0
				rs.scale = Vector2(rng.randf_range(1.0, 2.0), rng.randf_range(1.0, 2.0))
				rs.rotation = rng.randf_range(-0.3, 0.3)
				rs.modulate.a = rng.randf_range(0.5, 0.8)
				add_child(rs)
				_ground_clutter.append(rs)
	for y: int in map_data.height:
		for x: int in map_data.width:
			var cell: Cell = map_data.cells[y * map_data.width + x]
			if cell.is_mountain or not cell.is_passable():
				continue
			var chance: float = density_map.get(cell.terrain_def, 0.0)
			if chance <= 0.0:
				continue
			if rng.randf() > chance:
				continue
			var is_flower: bool = rng.randf() < 0.15 and not flower_tex.is_empty()
			var tex: Texture2D
			if is_flower:
				tex = flower_tex[rng.randi() % flower_tex.size()]
			elif not grass_tex.is_empty():
				tex = grass_tex[rng.randi() % grass_tex.size()]
			else:
				continue
			var spr := Sprite2D.new()
			spr.texture = tex
			var base_sc: float = CELL_SIZE * rng.randf_range(0.5, 0.9) / float(tex.get_width())
			spr.scale = Vector2(base_sc, base_sc)
			var ox: float = rng.randf_range(1.0, CELL_SIZE - 1.0)
			var oy: float = rng.randf_range(1.0, CELL_SIZE - 1.0)
			spr.position = Vector2(x * CELL_SIZE + ox, y * CELL_SIZE + oy)
			spr.z_index = 0
			spr.modulate.a = rng.randf_range(0.45, 0.8)
			spr.modulate = spr.modulate.lerp(Color(0.85, 0.95, 0.75, spr.modulate.a), 0.15)
			add_child(spr)
			_ground_clutter.append(spr)
	var tuft_img := Image.create(6, 4, false, Image.FORMAT_RGBA8)
	tuft_img.fill(Color(0, 0, 0, 0))
	tuft_img.set_pixel(2, 3, Color(0.35, 0.55, 0.2, 0.5))
	tuft_img.set_pixel(3, 3, Color(0.3, 0.5, 0.18, 0.45))
	tuft_img.set_pixel(2, 2, Color(0.4, 0.6, 0.25, 0.55))
	tuft_img.set_pixel(3, 2, Color(0.38, 0.58, 0.22, 0.5))
	tuft_img.set_pixel(1, 1, Color(0.32, 0.52, 0.2, 0.35))
	tuft_img.set_pixel(4, 1, Color(0.33, 0.53, 0.2, 0.3))
	tuft_img.set_pixel(2, 0, Color(0.35, 0.55, 0.22, 0.2))
	var tuft_tex := ImageTexture.create_from_image(tuft_img)
	var soil_defs: PackedStringArray = ["Soil", "SoilRich", "MarshyTerrain"]
	for y3: int in map_data.height:
		for x3: int in map_data.width:
			var c3: Cell = map_data.cells[y3 * map_data.width + x3]
			if c3.is_mountain or not c3.terrain_def in soil_defs:
				continue
			if rng.randf() > 0.15:
				continue
			var ts := Sprite2D.new()
			ts.texture = tuft_tex
			ts.position = Vector2(x3 * CELL_SIZE + rng.randf_range(2, 14), y3 * CELL_SIZE + rng.randf_range(2, 14))
			ts.z_index = 0
			ts.scale = Vector2(rng.randf_range(1.2, 2.5), rng.randf_range(1.2, 2.5))
			ts.flip_h = rng.randf() < 0.5
			add_child(ts)
			_ground_clutter.append(ts)
	var yflower_img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	yflower_img.fill(Color(0, 0, 0, 0))
	yflower_img.set_pixel(1, 0, Color(0.85, 0.8, 0.2, 0.7))
	yflower_img.set_pixel(0, 1, Color(0.9, 0.85, 0.3, 0.6))
	yflower_img.set_pixel(1, 1, Color(0.95, 0.9, 0.35, 0.9))
	yflower_img.set_pixel(2, 1, Color(0.88, 0.82, 0.25, 0.6))
	yflower_img.set_pixel(1, 2, Color(0.4, 0.55, 0.2, 0.5))
	var yflower_tex := ImageTexture.create_from_image(yflower_img)
	var fertile_defs: PackedStringArray = ["Soil", "SoilRich"]
	for y4: int in map_data.height:
		for x4: int in map_data.width:
			var c4: Cell = map_data.cells[y4 * map_data.width + x4]
			if c4.is_mountain or not c4.terrain_def in fertile_defs:
				continue
			var flower_chance: float = 0.25 if c4.terrain_def == "SoilRich" else 0.15
			for fi: int in range(rng.randi_range(0, 2)):
				if rng.randf() > flower_chance:
					continue
				var fs := Sprite2D.new()
				fs.texture = yflower_tex
				fs.position = Vector2(x4 * CELL_SIZE + rng.randf_range(1, 15), y4 * CELL_SIZE + rng.randf_range(1, 15))
				fs.z_index = 0
				fs.scale = Vector2(rng.randf_range(1.0, 2.0), rng.randf_range(1.0, 2.0))
				fs.modulate.a = rng.randf_range(0.5, 0.9)
				add_child(fs)
				_ground_clutter.append(fs)


func generate_new_map(w: int, h: int, seed_val: int) -> void:
	map_data = MapData.new(w, h)
	map_data.seed = seed_val
	var gen := MapGenerator.new(map_data, seed_val)
	gen.generate()
	if GameState:
		GameState.active_map = map_data
	_load_building_textures()
	_load_plant_textures()
	_load_item_textures()
	_load_pawn_textures()
	_load_animal_textures()
	_render_map()
	_render_terrain_blend()
	_render_grid_overlay()
	_render_wet_ground()
	_render_snow_ground()
	_render_roof_overlay()
	_render_zones()
	_spawn_water_highlights()
	_camera.position = Vector2(w * CELL_SIZE / 2.0, h * CELL_SIZE / 2.0)


func _spawn_initial_pawns() -> void:
	if map_data == null or not PawnManager:
		return
	if not PawnManager.pawns.is_empty():
		return
	var center := Vector2i(map_data.width / 2, map_data.height / 2)
	var colonist_defs: Array[Dictionary] = [
		{"name": "Engie", "age": 32, "skills": {"Construction": 12, "Shooting": 5, "Mining": 6}, "gear": {"Weapon": "Revolver", "BodyArmor": "FlakVest"}},
		{"name": "Doc", "age": 45, "skills": {"Medicine": 14, "Shooting": 3, "Intellectual": 8}, "gear": {"Weapon": "Revolver", "BodyArmor": "FlakVest"}},
		{"name": "Hawk", "age": 28, "skills": {"Shooting": 14, "Melee": 10, "Animals": 4}, "gear": {"Weapon": "Rifle", "BodyArmor": "FlakVest", "HeadArmor": "SimpleHelmet"}},
		{"name": "Cook", "age": 38, "skills": {"Cooking": 12, "Plants": 8, "Medicine": 4}, "gear": {"Weapon": "Knife"}},
		{"name": "Miner", "age": 35, "skills": {"Mining": 13, "Construction": 7, "Crafting": 5}, "gear": {"Weapon": "Revolver"}},
		{"name": "Crafter", "age": 41, "skills": {"Crafting": 14, "Construction": 6, "Intellectual": 6}, "gear": {"Weapon": "Knife", "BodyArmor": "FlakVest"}},
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
		if def.has("gear") and p.equipment:
			var gear: Dictionary = def["gear"]
			for slot: String in gear:
				p.equipment.equip(slot, gear[slot])
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
	var pawn_hash: int = absi(hash(p.pawn_name))
	var container := Node2D.new()
	container.z_index = 5
	add_child(container)

	if not _pawn_body_textures.is_empty():
		var body_idx: int = pawn_hash % _pawn_body_textures.size()
		var body_spr := Sprite2D.new()
		body_spr.texture = _pawn_body_textures[body_idx]
		var scale_f: float = CELL_SIZE * 1.8 / float(body_spr.texture.get_width())
		body_spr.scale = Vector2(scale_f, scale_f)
		var skin_col: Color = PAWN_SKIN_COLORS[pawn_hash % PAWN_SKIN_COLORS.size()]
		body_spr.modulate = skin_col.lerp(Color.WHITE, 0.6)
		container.add_child(body_spr)

		if not _pawn_hair_textures.is_empty():
			var hair_idx: int = (pawn_hash / 7) % _pawn_hair_textures.size()
			var hair_spr := Sprite2D.new()
			hair_spr.texture = _pawn_hair_textures[hair_idx]
			var hsc: float = CELL_SIZE * 1.2 / float(hair_spr.texture.get_width())
			hair_spr.scale = Vector2(hsc, hsc)
			hair_spr.position.y = -CELL_SIZE * 0.3
			var hair_col: Color = PAWN_HAIR_COLORS[(pawn_hash / 3) % PAWN_HAIR_COLORS.size()]
			hair_spr.modulate = hair_col
			container.add_child(hair_spr)

		var clothing_col: Color = PAWN_BODY_COLORS[pawn_hash % PAWN_BODY_COLORS.size()]
		var cloth_spr := Sprite2D.new()
		cloth_spr.texture = _pawn_body_textures[body_idx]
		cloth_spr.scale = Vector2(scale_f * 1.05, scale_f * 0.55)
		cloth_spr.position.y = CELL_SIZE * 0.15
		cloth_spr.modulate = clothing_col
		cloth_spr.modulate.a = 0.7
		container.add_child(cloth_spr)

		var weapon_name: String = ""
		if p.equipment and p.equipment.slots.has("Weapon"):
			weapon_name = p.equipment.slots["Weapon"]
		if not weapon_name.is_empty():
			var wpn_img := Image.create(8, 3, false, Image.FORMAT_RGBA8)
			wpn_img.fill(Color(0, 0, 0, 0))
			var wpn_col := Color(0.6, 0.6, 0.65, 0.85)
			if "Rifle" in weapon_name or "Sniper" in weapon_name:
				wpn_col = Color(0.5, 0.5, 0.55, 0.9)
				for wx: int in range(8):
					wpn_img.set_pixel(wx, 1, wpn_col)
				wpn_img.set_pixel(7, 0, wpn_col.darkened(0.2))
			elif "Knife" in weapon_name or "Sword" in weapon_name or "Mace" in weapon_name:
				wpn_col = Color(0.7, 0.7, 0.72, 0.85)
				for wx: int in range(5):
					wpn_img.set_pixel(wx, 1, wpn_col)
				wpn_img.set_pixel(5, 0, wpn_col.lightened(0.2))
			else:
				for wx: int in range(6):
					wpn_img.set_pixel(wx, 1, wpn_col)
			var wpn_spr := Sprite2D.new()
			wpn_spr.texture = ImageTexture.create_from_image(wpn_img)
			wpn_spr.position = Vector2(CELL_SIZE * 0.4, CELL_SIZE * 0.1)
			wpn_spr.rotation_degrees = -25.0
			wpn_spr.name = "Weapon"
			container.add_child(wpn_spr)
	else:
		var spr := Sprite2D.new()
		var frame_w: int = 12
		var frame_h: int = 14
		var img := Image.create(frame_w, frame_h, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var body_col: Color = PAWN_BODY_COLORS[pawn_hash % PAWN_BODY_COLORS.size()]
		var head_col: Color = PAWN_SKIN_COLORS[pawn_hash % PAWN_SKIN_COLORS.size()]
		for y: int in range(5, 12):
			for x: int in range(2, 10):
				img.set_pixel(x, y, body_col)
		for y: int in range(0, 5):
			for x: int in range(3, 9):
				img.set_pixel(x, y, head_col)
		spr.texture = ImageTexture.create_from_image(img)
		spr.centered = true
		container.add_child(spr)

	var ring_img := Image.create(CELL_SIZE * 2, CELL_SIZE * 2, false, Image.FORMAT_RGBA8)
	ring_img.fill(Color(0, 0, 0, 0))
	var ring_center := Vector2(CELL_SIZE, CELL_SIZE)
	var outer_r := float(CELL_SIZE) * 0.95
	var inner_r := outer_r - 2.5
	for py: int in range(CELL_SIZE * 2):
		for px: int in range(CELL_SIZE * 2):
			var dist: float = Vector2(px, py).distance_to(ring_center)
			if dist >= inner_r and dist <= outer_r:
				var edge_fade: float = 1.0 - absf(dist - (inner_r + outer_r) * 0.5) / ((outer_r - inner_r) * 0.5)
				ring_img.set_pixel(px, py, Color(0.4, 1.0, 0.4, 0.9 * edge_fade))
	var ring_spr := Sprite2D.new()
	ring_spr.texture = ImageTexture.create_from_image(ring_img)
	ring_spr.position.y = CELL_SIZE * 0.2
	ring_spr.visible = false
	ring_spr.name = "SelectRing"
	container.add_child(ring_spr)

	var bar_w: int = CELL_SIZE + 4
	var bar_h: int = 2
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.1, 0.1, 0.1, 0.6)
	bar_bg.size = Vector2(bar_w, bar_h)
	bar_bg.position = Vector2(-bar_w / 2.0, -CELL_SIZE * 0.9)
	bar_bg.name = "HealthBG"
	container.add_child(bar_bg)
	var bar_fill := ColorRect.new()
	bar_fill.color = Color(0.2, 0.9, 0.2, 0.8)
	bar_fill.size = Vector2(bar_w, bar_h)
	bar_fill.position = bar_bg.position
	bar_fill.name = "HealthFill"
	container.add_child(bar_fill)

	var name_bg := ColorRect.new()
	name_bg.color = Color(0.05, 0.05, 0.05, 0.45)
	name_bg.size = Vector2(CELL_SIZE * 2.6, 11)
	name_bg.position = Vector2(-CELL_SIZE * 1.3, -CELL_SIZE * 1.35)
	name_bg.name = "NameBG"
	name_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(name_bg)

	var name_label := Label.new()
	name_label.text = p.pawn_name
	name_label.add_theme_font_size_override("font_size", 7)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9, 0.95))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-CELL_SIZE * 1.3, -CELL_SIZE * 1.35)
	name_label.size = Vector2(CELL_SIZE * 2.6, 11)
	name_label.name = "NameLabel"
	container.add_child(name_label)

	var job_label := Label.new()
	job_label.text = ""
	job_label.add_theme_font_size_override("font_size", 6)
	job_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6, 0.85))
	job_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	job_label.add_theme_constant_override("shadow_offset_x", 1)
	job_label.add_theme_constant_override("shadow_offset_y", 1)
	job_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	job_label.position = Vector2(-CELL_SIZE * 1.2, CELL_SIZE * 0.6)
	job_label.size = Vector2(CELL_SIZE * 2.4, 10)
	job_label.name = "JobLabel"
	container.add_child(job_label)

	_pawn_sprites[p.id] = container
	var initial_pos := Vector2(p.grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
		p.grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0)
	container.position = initial_pos
	_pawn_target_pos[p.id] = initial_pos


func _update_pawn_sprite_pos(p: Pawn) -> void:
	if _pawn_sprites.has(p.id):
		var target := Vector2(p.grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
			p.grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0)
		_pawn_target_pos[p.id] = target


func _place_initial_blueprints() -> void:
	if map_data == null or not ThingManager:
		return
	var center := Vector2i(map_data.width / 2, map_data.height / 2)
	var wall_offsets: Array[Vector2i] = [
		Vector2i(-3, -3), Vector2i(-2, -3), Vector2i(-1, -3), Vector2i(0, -3), Vector2i(1, -3), Vector2i(2, -3), Vector2i(3, -3),
		Vector2i(-3, -2), Vector2i(3, -2),
		Vector2i(-3, -1), Vector2i(3, -1),
		Vector2i(-3, 0), Vector2i(3, 0),
		Vector2i(-3, 1), Vector2i(3, 1),
		Vector2i(-3, 2), Vector2i(3, 2),
		Vector2i(-3, 3), Vector2i(-2, 3), Vector2i(-1, 3), Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3),
	]
	var door_pos := center + Vector2i(0, 3)
	for off: Vector2i in wall_offsets:
		var pos := center + off
		if map_data.in_bounds(pos.x, pos.y):
			var cell := map_data.get_cell_v(pos)
			if cell and cell.is_passable():
				if pos == door_pos:
					ThingManager.place_blueprint("DoorSimple", pos)
				else:
					ThingManager.place_blueprint("Wall", pos)
	ThingManager.place_blueprint("Campfire", center)
	var furniture: Array[Dictionary] = [
		{"def": "Bed", "offset": Vector2i(-2, -2)},
		{"def": "Bed", "offset": Vector2i(-2, -1)},
		{"def": "Bed", "offset": Vector2i(-2, 0)},
		{"def": "Table", "offset": Vector2i(1, -1)},
		{"def": "DiningChair", "offset": Vector2i(0, -1)},
		{"def": "DiningChair", "offset": Vector2i(2, -1)},
		{"def": "CookingStove", "offset": Vector2i(2, 1)},
		{"def": "TorchLamp", "offset": Vector2i(-1, 2)},
	]
	for f: Dictionary in furniture:
		var pos: Vector2i = center + f["offset"]
		if map_data.in_bounds(pos.x, pos.y):
			ThingManager.place_blueprint(f["def"], pos)
	_place_initial_zones(center)


func _place_initial_zones(center: Vector2i) -> void:
	if not ZoneManager:
		return
	for dx: int in range(-2, 3):
		for dy: int in range(-2, 3):
			var pos := center + Vector2i(dx, dy)
			if map_data.in_bounds(pos.x, pos.y):
				var cell := map_data.get_cell_v(pos)
				if cell and cell.is_passable():
					ZoneManager.place_zone("Stockpile", pos)
					if FloorManager:
						FloorManager.set_floor(pos, "WoodPlank")
	for dx: int in range(-6, -2):
		for dy: int in range(-6, -2):
			var pos := center + Vector2i(dx, dy)
			if map_data.in_bounds(pos.x, pos.y):
				var cell := map_data.get_cell_v(pos)
				if cell and cell.is_passable() and cell.fertility > 0.5:
					ZoneManager.place_zone("GrowingZone", pos)
	for dx: int in range(-2, 5):
		for dy: int in range(5, 9):
			var pos := center + Vector2i(dx, dy)
			if map_data.in_bounds(pos.x, pos.y):
				var cell := map_data.get_cell_v(pos)
				if cell and cell.is_passable() and cell.fertility > 0.3:
					ZoneManager.place_zone("GrowingZone", pos)


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
	var container := Node2D.new()
	container.z_index = 4
	var spr := Sprite2D.new()
	var species := a.species if a.has_method("get") else ""
	if species.is_empty() and "species" in a:
		species = a.species
	var size_mult := _animal_size_mult(species)
	if _animal_textures.has(species):
		spr.texture = _animal_textures[species]
		var target_px: float = CELL_SIZE * 2.0 * size_mult
		var scale_f: float = target_px / float(spr.texture.get_width())
		spr.scale = Vector2(scale_f, scale_f)
	else:
		var img := Image.create(12, 10, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var c := a.get_color()
		var body := Color(c[0], c[1], c[2], 1.0)
		var belly := body.lightened(0.18)
		for y: int in range(2, 7):
			for x: int in range(2, 10):
				img.set_pixel(x, y, body)
		for x: int in range(4, 8):
			img.set_pixel(x, 5, belly)
			img.set_pixel(x, 6, belly)
		for x: int in range(3, 7):
			img.set_pixel(x, 1, body.lightened(0.1))
		img.set_pixel(3, 1, body.darkened(0.3))
		var leg_col := body.darkened(0.2)
		for y: int in range(7, 9):
			img.set_pixel(3, y, leg_col)
			img.set_pixel(4, y, leg_col)
			img.set_pixel(8, y, leg_col)
			img.set_pixel(9, y, leg_col)
		img.set_pixel(10, 3, body.darkened(0.1))
		img.set_pixel(11, 3, body.darkened(0.1))
		spr.texture = ImageTexture.create_from_image(img)
		var fb_scale: float = size_mult * 1.5
		spr.scale = Vector2(fb_scale, fb_scale)
	spr.centered = true
	spr.name = "Body"
	container.add_child(spr)
	var shadow := Sprite2D.new()
	shadow.texture = spr.texture
	shadow.centered = true
	shadow.scale = Vector2(spr.scale.x * 0.9, spr.scale.y * 0.35)
	shadow.position = Vector2(1, CELL_SIZE * 0.3 * size_mult)
	shadow.modulate = Color(0, 0, 0, 0.18)
	shadow.z_index = -1
	container.add_child(shadow)
	add_child(container)
	_animal_sprites[a.id] = container
	var apos := Vector2(a.grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
		a.grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0)
	container.position = apos
	_animal_target_pos[a.id] = apos


func _animal_size_mult(species: String) -> float:
	match species:
		"Muffalo", "Cow", "Caribou":
			return 1.4
		"Deer", "Boomalope":
			return 1.2
		"Boomrat", "Rat", "Squirrel", "Hare":
			return 0.7
		"Cat", "Chicken":
			return 0.8
		"Cobra":
			return 0.9
		_:
			return 1.0


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
				var node: Node2D = _animal_sprites[a.id] as Node2D
				if not node.has_meta("corpse"):
					node.rotation_degrees = 90.0
					node.modulate = Color(0.6, 0.5, 0.5, 0.7)
					node.set_meta("corpse", true)
			continue
		if not _animal_sprites.has(a.id):
			_create_animal_sprite(a)
			a.position_changed.connect(_on_animal_moved.bind(a))


func _render_things() -> void:
	if map_data == null or not ThingManager:
		return
	_thing_layer.clear()
	for node: Node in _building_sprites.values():
		node.queue_free()
	_building_sprites.clear()
	for node: Node in _plant_sprites.values():
		node.queue_free()
	_plant_sprites.clear()
	for node: Node in _item_sprites.values():
		node.queue_free()
	_item_sprites.clear()

	var tb: String = _get_tile_tex_base()
	for thing: Thing in ThingManager.things:
		if thing.state != Thing.ThingState.SPAWNED:
			continue
		var tx: int = thing.grid_pos.x
		var ty: int = thing.grid_pos.y
		if tx < 0 or tx >= map_data.width or ty < 0 or ty >= map_data.height:
			continue

		if thing is Building:
			var bld := thing as Building
			if bld.build_state == Building.BuildState.COMPLETE and _try_render_building_sprite(bld):
				continue
			if bld.build_state != Building.BuildState.COMPLETE and _try_render_blueprint_sprite(bld):
				continue

		if thing is Plant:
			if _try_render_plant_sprite(thing as Plant, tx, ty):
				continue

		if thing is Item:
			if _try_render_item_sprite(thing as Item, tx, ty):
				continue

		var col: Color
		var state_suffix := ""
		var shape := "full"
		var tex_file := ""
		if thing is Plant:
			var plant := thing as Plant
			var base_plant_col: Color = PLANT_COLORS.get(plant.def_name, Color(0.2, 0.45, 0.15))
			var g: float = clampf(plant.growth, 0.0, 1.0)
			col = base_plant_col.darkened(0.3 * (1.0 - g))
			var gstage := int(g * 4)
			state_suffix = "_g%d" % gstage
			if plant.def_name == "Tree":
				col = col.darkened(0.1)
				shape = "canopy" if g > 0.4 else "stalk"
			elif gstage <= 0:
				shape = "dot"
			elif gstage <= 1:
				shape = "diamond"
			else:
				shape = "bush"
		elif thing is Item:
			col = ITEM_COLORS.get(thing.def_name, Color(0.8, 0.75, 0.3))
			shape = ITEM_SHAPES.get(thing.def_name, "diamond")
		elif thing is Building:
			col = thing.get_color()
			state_suffix = "_%d" % (thing as Building).build_state
		else:
			col = thing.get_color()
		var key := "t_%s_%s%s" % [thing.def_name, shape, state_suffix]
		if not _terrain_id_map.has(key):
			_add_shaped_tile(col, key, shape)
		_thing_layer.set_cell(Vector2i(tx, ty), 0, _terrain_id_map[key])


func _try_render_plant_sprite(plant: Plant, tx: int, ty: int) -> bool:
	var g: float = clampf(plant.growth, 0.0, 1.0)
	var tree_hash: int = absi(hash(str(tx) + "_" + str(ty)))
	var tex_name := ""
	if plant.def_name == "Tree":
		if g > 0.4:
			var idx: int = tree_hash % TREE_TEX_FILES.size()
			tex_name = TREE_TEX_FILES[idx].get_basename()
		else:
			var idx: int = tree_hash % TREE_IMMATURE_TEX_FILES.size()
			tex_name = TREE_IMMATURE_TEX_FILES[idx].get_basename()
	elif PLANT_TEX_MAP.has(plant.def_name):
		tex_name = PLANT_TEX_MAP[plant.def_name].get_basename()
	else:
		return false
	if not _plant_textures.has(tex_name):
		return false
	var tex: Texture2D = _plant_textures[tex_name]
	var target_px: float
	if plant.def_name == "Tree":
		if g > 0.4:
			target_px = CELL_SIZE * 3.0
		else:
			target_px = CELL_SIZE * (1.0 + g * 2.5)
	else:
		target_px = CELL_SIZE * (0.8 + g * 1.2)
	var scale_f: float = target_px / float(tex.get_width())
	var world_pos := Vector2(tx * CELL_SIZE + CELL_SIZE * 0.5, ty * CELL_SIZE + CELL_SIZE * 0.5)
	if plant.def_name == "Tree" and g > 0.3:
		var shadow := Sprite2D.new()
		shadow.texture = tex
		var shadow_sc: float = scale_f * (0.6 + g * 0.3)
		shadow.scale = Vector2(shadow_sc * 1.2, shadow_sc * 0.4)
		shadow.position = world_pos + Vector2(CELL_SIZE * 0.3, CELL_SIZE * 0.6)
		shadow.z_index = 0
		shadow.modulate = Color(0, 0, 0, 0.22)
		add_child(shadow)
		_plant_sprites[plant.get_instance_id() + 100000] = shadow
	elif g > 0.5 and plant.def_name != "Tree":
		var shadow := Sprite2D.new()
		shadow.texture = tex
		var shadow_sc: float = scale_f * 0.5
		shadow.scale = Vector2(shadow_sc * 1.0, shadow_sc * 0.3)
		shadow.position = world_pos + Vector2(CELL_SIZE * 0.15, CELL_SIZE * 0.3)
		shadow.z_index = 0
		shadow.modulate = Color(0, 0, 0, 0.12)
		add_child(shadow)
		_plant_sprites[plant.get_instance_id() + 100000] = shadow
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.scale = Vector2(scale_f, scale_f)
	spr.position = world_pos
	spr.z_index = 1
	if g > 0.9:
		spr.modulate = Color(1.0, 0.95, 0.85, 1.0)
	else:
		spr.modulate.a = clampf(0.5 + g * 0.5, 0.5, 1.0)
	add_child(spr)
	_plant_sprites[plant.get_instance_id()] = spr
	return true


func _try_render_item_sprite(item: Item, tx: int, ty: int) -> bool:
	var tex_name := ""
	if item.def_name == "Wood":
		tex_name = "WoodLog"
	elif _item_textures.has(item.def_name):
		tex_name = item.def_name
	elif item.def_name == "Components":
		tex_name = "ComponentIndustrial"
	elif item.def_name == "Medicine":
		tex_name = "MedicineIndustrial"
	elif item.def_name == "HerbalMedicine":
		tex_name = "MedicineHerbal"
	elif item.def_name == "Stone":
		tex_name = "StoneChunks"
	elif item.def_name == "MealFine" and _item_textures.has("MealFine"):
		tex_name = "MealFine"
	elif item.def_name == "MealLavish" and _item_textures.has("MealLavish"):
		tex_name = "MealLavish"
	elif item.def_name == "NutrientPaste" and _item_textures.has("NutrientPaste"):
		tex_name = "NutrientPaste"
	elif item.def_name == "Uranium" and _item_textures.has("Uranium"):
		tex_name = "Uranium"
	elif item.def_name == "Kibble" and _item_textures.has("Kibble"):
		tex_name = "Kibble"
	elif item.def_name == "StoneBlocks" and _item_textures.has("StoneBlocks"):
		tex_name = "StoneBlocks"
	else:
		return false
	if not _item_textures.has(tex_name):
		return false
	var tex: Texture2D = _item_textures[tex_name]
	var size_mult: float = 1.4
	if tex_name == "StoneChunks":
		size_mult = 2.0
	elif tex_name == "WoodLog":
		size_mult = 1.6
	var scale_f: float = float(CELL_SIZE) * size_mult / float(tex.get_width())
	var world_pos := Vector2(tx * CELL_SIZE + CELL_SIZE * 0.5, ty * CELL_SIZE + CELL_SIZE * 0.5)
	var shadow := Sprite2D.new()
	shadow.texture = tex
	shadow.scale = Vector2(scale_f, scale_f * 0.5)
	shadow.position = world_pos + Vector2(1, 3)
	shadow.modulate = Color(0, 0, 0, 0.2)
	shadow.z_index = 1
	add_child(shadow)
	_item_sprites[item.get_instance_id() + 300000] = shadow
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.scale = Vector2(scale_f, scale_f)
	spr.position = world_pos
	spr.z_index = 2
	add_child(spr)
	_item_sprites[item.get_instance_id()] = spr
	if item.stack_count > 1:
		var label := Label.new()
		label.text = str(item.stack_count)
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.position = world_pos + Vector2(-CELL_SIZE * 0.4, CELL_SIZE * 0.1)
		label.z_index = 2
		add_child(label)
		_item_sprites[item.get_instance_id() + 200000] = label
	return true


func _try_render_building_sprite(bld: Building) -> bool:
	var tex: Texture2D = null
	if bld.def_name == "Wall" and not _wall_atlas_textures.is_empty():
		var mask := _get_wall_bitmask(bld.grid_pos)
		tex = _wall_atlas_textures[mask]
	elif _building_textures.has(bld.def_name):
		tex = _building_textures[bld.def_name]
	else:
		return false

	var world_pos := Vector2(bld.grid_pos.x * CELL_SIZE + CELL_SIZE / 2, bld.grid_pos.y * CELL_SIZE + CELL_SIZE / 2)
	if bld.def_name in ["Campfire", "TorchLamp"]:
		var glow_range: int = 10 if bld.def_name == "Campfire" else 6
		var glow_alpha: float = 0.22 if bld.def_name == "Campfire" else 0.15
		var glow := Sprite2D.new()
		var glow_size: int = CELL_SIZE * glow_range
		var glow_img := Image.create(glow_size, glow_size, false, Image.FORMAT_RGBA8)
		glow_img.fill(Color(0, 0, 0, 0))
		var center_px := Vector2(glow_size / 2.0, glow_size / 2.0)
		var radius := float(glow_size / 2.0)
		for py: int in glow_size:
			for px: int in glow_size:
				var dist: float = Vector2(px, py).distance_to(center_px)
				if dist < radius:
					var t: float = 1.0 - dist / radius
					var alpha: float = t * t * glow_alpha
					glow_img.set_pixel(px, py, Color(1.0, 0.85, 0.4, alpha))
		glow.texture = ImageTexture.create_from_image(glow_img)
		glow.position = world_pos
		glow.z_index = 0
		add_child(glow)
		_building_sprites[bld.get_instance_id() + 100000] = glow
		if bld.def_name == "Campfire":
			var smoke := CPUParticles2D.new()
			smoke.emitting = true
			smoke.amount = 8
			smoke.lifetime = 2.5
			smoke.one_shot = false
			smoke.direction = Vector2(0, -1)
			smoke.spread = 20.0
			smoke.gravity = Vector2(0, -15)
			smoke.initial_velocity_min = 5.0
			smoke.initial_velocity_max = 12.0
			smoke.scale_amount_min = 1.0
			smoke.scale_amount_max = 3.0
			smoke.color = Color(0.4, 0.4, 0.4, 0.2)
			smoke.position = world_pos + Vector2(0, -CELL_SIZE * 0.3)
			smoke.z_index = 6
			add_child(smoke)
			_building_sprites[bld.get_instance_id() + 200000] = smoke
	var bld_sizes: Dictionary = {
		"Bed": Vector2(1, 2), "BedDouble": Vector2(2, 2), "HospitalBed": Vector2(1, 2),
		"Bedroll": Vector2(1, 2), "Table": Vector2(2, 2), "Table2x4": Vector2(2, 4),
		"Table3x3": Vector2(3, 3), "Table1x2": Vector2(1, 2),
		"ResearchBench": Vector2(2, 1), "HiTechResearchBench": Vector2(2, 1),
		"CookingStove": Vector2(1, 1), "FueledStove": Vector2(1, 1),
		"Shelf": Vector2(2, 1), "ShelfSmall": Vector2(1, 1),
	}
	var bld_size: Vector2 = bld_sizes.get(bld.def_name, Vector2(1, 1))
	var spr := Sprite2D.new()
	spr.texture = tex
	var scale_x: float = float(CELL_SIZE) * bld_size.x / float(tex.get_width())
	var scale_y: float = float(CELL_SIZE) * bld_size.y / float(tex.get_height())
	spr.scale = Vector2(scale_x, scale_y)
	spr.position = world_pos
	spr.z_index = 1
	add_child(spr)
	_building_sprites[bld.get_instance_id()] = spr
	if bld.def_name == "Wall":
		var shadow_img := Image.create(CELL_SIZE, 3, false, Image.FORMAT_RGBA8)
		shadow_img.fill(Color(0, 0, 0, 0))
		for px: int in CELL_SIZE:
			shadow_img.set_pixel(px, 0, Color(0, 0, 0, 0.15))
			shadow_img.set_pixel(px, 1, Color(0, 0, 0, 0.08))
			shadow_img.set_pixel(px, 2, Color(0, 0, 0, 0.03))
		var shadow_spr := Sprite2D.new()
		shadow_spr.texture = ImageTexture.create_from_image(shadow_img)
		shadow_spr.position = world_pos + Vector2(0, CELL_SIZE * 0.5 + 1)
		shadow_spr.z_index = 0
		add_child(shadow_spr)
		_building_sprites[bld.get_instance_id() + 500000] = shadow_spr
	return true


func _try_render_blueprint_sprite(bld: Building) -> bool:
	var tex: Texture2D = null
	if bld.def_name == "Wall":
		if not _wall_atlas_textures.is_empty():
			var mask := _get_wall_bitmask(bld.grid_pos)
			if mask >= 0 and mask < _wall_atlas_textures.size():
				tex = _wall_atlas_textures[mask]
			else:
				tex = _wall_atlas_textures[0]
	elif _building_textures.has(bld.def_name):
		tex = _building_textures[bld.def_name]
	if tex == null:
		return false
	var spr := Sprite2D.new()
	spr.texture = tex
	var scale_f: float = float(CELL_SIZE) / float(tex.get_width())
	spr.scale = Vector2(scale_f, scale_f)
	var world_pos := Vector2(bld.grid_pos.x * CELL_SIZE + CELL_SIZE / 2, bld.grid_pos.y * CELL_SIZE + CELL_SIZE / 2)
	spr.position = world_pos
	spr.z_index = 1
	spr.modulate = Color(0.6, 0.8, 1.0, 0.4)
	add_child(spr)
	_building_sprites[bld.get_instance_id()] = spr
	if bld.build_work_total > 0:
		var progress: float = 1.0 - (bld.build_work_left / bld.build_work_total)
		var bar_w: int = CELL_SIZE
		var bar_bg := ColorRect.new()
		bar_bg.color = Color(0.1, 0.1, 0.1, 0.5)
		bar_bg.size = Vector2(bar_w, 2)
		bar_bg.position = world_pos + Vector2(-bar_w / 2.0, CELL_SIZE * 0.4)
		bar_bg.z_index = 2
		add_child(bar_bg)
		_building_sprites[bld.get_instance_id() + 300000] = bar_bg
		var bar_fill := ColorRect.new()
		bar_fill.color = Color(0.3, 0.7, 1.0, 0.8)
		bar_fill.size = Vector2(bar_w * progress, 2)
		bar_fill.position = bar_bg.position
		bar_fill.z_index = 2
		add_child(bar_fill)
		_building_sprites[bld.get_instance_id() + 400000] = bar_fill
	return true


func ensure_pawn_sprites() -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if not _pawn_sprites.has(p.id):
			_create_pawn_sprite(p)
			p.position_changed.connect(_on_pawn_moved.bind(p))


const TERRAIN_VARIANTS := 4

func _build_tileset() -> void:
	_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(CELL_SIZE, CELL_SIZE)

	var terrain_colors: Dictionary = {
		"Soil": Color(0.58, 0.52, 0.32),
		"SoilRich": Color(0.48, 0.44, 0.24),
		"Sand": Color(0.82, 0.78, 0.58),
		"Gravel": Color(0.62, 0.58, 0.50),
		"MarshyTerrain": Color(0.42, 0.50, 0.30),
		"Mud": Color(0.50, 0.42, 0.28),
		"Ice": Color(0.88, 0.92, 0.97),
		"WaterShallow": Color(0.35, 0.52, 0.70),
		"WaterDeep": Color(0.22, 0.35, 0.55),
		"RoughStone": Color(0.62, 0.60, 0.56),
		"Mountain": Color(0.48, 0.45, 0.42),
		"Cave": Color(0.32, 0.30, 0.28),
		"OreGold": Color(0.85, 0.78, 0.30),
		"OreUranium": Color(0.50, 0.72, 0.50),
		"OreJade": Color(0.42, 0.70, 0.52),
		"OrePlasteel": Color(0.72, 0.82, 0.88),
		"OreSteel": Color(0.65, 0.70, 0.72),
		"OreCompacted": Color(0.60, 0.60, 0.58),
		"WoodFloor": Color(0.55, 0.42, 0.28),
		"Concrete": Color(0.62, 0.62, 0.60),
		"Carpet": Color(0.60, 0.30, 0.30),
	}
	_floor_to_tile = {
		"WoodPlank": "WoodFloor",
		"Concrete": "Concrete",
		"Carpet": "Carpet",
		"StoneTile": "Concrete",
		"SterileTile": "Concrete",
	}

	var tile_base: String = ProjectSettings.globalize_path("res://assets/textures/tiles/")
	var total_tiles := terrain_colors.size() * TERRAIN_VARIANTS
	var atlas_w: int = total_tiles * CELL_SIZE
	var atlas_img := Image.create(atlas_w, CELL_SIZE, false, Image.FORMAT_RGBA8)

	var soil_types: PackedStringArray = ["Soil", "SoilRich", "MarshyTerrain", "Mud"]
	var rock_types: PackedStringArray = ["RoughStone", "Mountain", "Gravel", "Cave"]
	var idx: int = 0
	for tname: String in terrain_colors:
		var base_col: Color = terrain_colors[tname]
		for v: int in TERRAIN_VARIANTS:
			var tile_path: String = tile_base + "terrain/" + tname + "_v" + str(v) + ".png"
			var used_file := false
			if FileAccess.file_exists(tile_path):
				var tile_img := Image.new()
				if tile_img.load(tile_path) == OK and tile_img.get_width() == CELL_SIZE:
					tile_img.convert(Image.FORMAT_RGBA8)
					var x_off: int = idx * CELL_SIZE
					for py: int in CELL_SIZE:
						for px: int in CELL_SIZE:
							atlas_img.set_pixel(x_off + px, py, tile_img.get_pixel(px, py))
					used_file = true
			if not used_file:
				_terrain_rng.seed = 12345 + v * 997 + idx * 31
				var x_off: int = idx * CELL_SIZE
				var is_ore := tname.begins_with("Ore")
				for py: int in CELL_SIZE:
					for px: int in CELL_SIZE:
						var noise_range: float = 0.12 if tname in soil_types else (0.10 if tname in rock_types else 0.07)
						var noise_val: float = _terrain_rng.randf_range(-noise_range, noise_range)
						var c := Color(
							clampf(base_col.r + noise_val, 0.0, 1.0),
							clampf(base_col.g + noise_val * 0.9, 0.0, 1.0),
							clampf(base_col.b + noise_val * 0.7, 0.0, 1.0),
							1.0)
						if tname == "WoodFloor":
							if py % 5 == 0:
								c = c.darkened(0.12)
							elif px == 0 or (px == 8 and py % 10 < 5) or (px == 8 and py % 10 >= 5):
								c = c.darkened(0.06)
						elif tname == "Concrete":
							if px % 8 == 0 or py % 8 == 0:
								c = c.darkened(0.08)
						elif tname == "Carpet":
							if (px + py) % 2 == 0:
								c = c.lightened(0.03)
						elif is_ore:
							var vein_val: float = sin(float(px) * 2.3 + float(py) * 1.7 + float(v) * 5.0) * 0.5 + 0.5
							if vein_val > 0.65:
								c = c.lightened(0.2 + vein_val * 0.15)
							if _terrain_rng.randf() < 0.08:
								c = c.lightened(0.3)
						elif tname in soil_types:
							if _terrain_rng.randf() < 0.18:
								c = c.lerp(Color(0.25, 0.45, 0.15), 0.3)
							elif _terrain_rng.randf() < 0.06:
								c = c.darkened(0.15)
						elif tname in rock_types:
							if _terrain_rng.randf() < 0.08:
								c = c.darkened(0.16)
							elif _terrain_rng.randf() < 0.04:
								c = c.lightened(0.12)
						elif tname == "Sand":
							if _terrain_rng.randf() < 0.08:
								c = c.lightened(0.1)
							elif _terrain_rng.randf() < 0.03:
								c = c.lerp(Color(0.7, 0.65, 0.4), 0.2)
						atlas_img.set_pixel(x_off + px, py, c)
			_terrain_id_map[tname + "_v" + str(v)] = Vector2i(idx, 0)
			idx += 1

	var atlas_tex := ImageTexture.create_from_image(atlas_img)
	var source := TileSetAtlasSource.new()
	source.texture = atlas_tex
	source.texture_region_size = Vector2i(CELL_SIZE, CELL_SIZE)
	for i: int in total_tiles:
		source.create_tile(Vector2i(i, 0))

	_tileset.add_source(source, 0)


var _tile_tex_base: String = ""

func _get_tile_tex_base() -> String:
	if _tile_tex_base.is_empty():
		_tile_tex_base = ProjectSettings.globalize_path("res://assets/textures/tiles/")
	return _tile_tex_base


func _add_file_tile(key: String, file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		return false
	var tile_img := Image.new()
	if tile_img.load(file_path) != OK:
		return false
	tile_img.convert(Image.FORMAT_RGBA8)
	if tile_img.get_width() != CELL_SIZE or tile_img.get_height() != CELL_SIZE:
		tile_img.resize(CELL_SIZE, CELL_SIZE, Image.INTERPOLATE_LANCZOS)
	var source: TileSetAtlasSource = _tileset.get_source(0) as TileSetAtlasSource
	var atlas_img: Image = source.texture.get_image()
	var cur_w := atlas_img.get_width()
	var new_w := cur_w + CELL_SIZE
	atlas_img.crop(new_w, CELL_SIZE)
	for py: int in CELL_SIZE:
		for px: int in CELL_SIZE:
			atlas_img.set_pixel(cur_w + px, py, tile_img.get_pixel(px, py))
	var new_coord := Vector2i(cur_w / CELL_SIZE, 0)
	source.texture = ImageTexture.create_from_image(atlas_img)
	source.create_tile(new_coord)
	_terrain_id_map[key] = new_coord
	return true


func _add_color_tile(col: Color, key: String) -> void:
	_add_shaped_tile(col, key, "full")


func _add_shaped_tile(col: Color, key: String, shape: String) -> void:
	var source: TileSetAtlasSource = _tileset.get_source(0) as TileSetAtlasSource
	var atlas_img: Image = source.texture.get_image()
	var cur_w := atlas_img.get_width()
	var new_w := cur_w + CELL_SIZE
	atlas_img.crop(new_w, CELL_SIZE)
	_terrain_rng.seed = hash(key)
	var half := CELL_SIZE / 2
	for py: int in CELL_SIZE:
		for px: int in CELL_SIZE:
			var draw := false
			match shape:
				"full":
					draw = true
				"ingot":
					draw = px >= 3 and px < 13 and py >= 5 and py < 11
				"log":
					draw = px >= 2 and px < 14 and py >= 4 and py < 12
				"circle":
					var dx: float = float(px) - float(half) + 0.5
					var dy: float = float(py) - float(half) + 0.5
					draw = dx * dx + dy * dy < 25.0
				"cross":
					draw = (px >= 5 and px < 11) or (py >= 5 and py < 11)
				"diamond":
					var dx: int = absi(px - half)
					var dy: int = absi(py - half)
					draw = dx + dy < 7
				"dot":
					draw = px >= 5 and px < 11 and py >= 5 and py < 11
				"stalk":
					draw = (px >= 6 and px < 10 and py >= 2 and py < 14) or \
						   (px >= 4 and px < 12 and py >= 2 and py < 6)
				"bush":
					var dx: float = float(px) - float(half) + 0.5
					var dy: float = float(py) - float(half) + 0.5
					draw = dx * dx + dy * dy < 36.0
				"canopy":
					var dx: float = float(px) - float(half) + 0.5
					var dy: float = float(py - 2) - float(half) + 2.5
					draw = (dx * dx + dy * dy < 42.0) or \
						   (px >= 7 and px < 9 and py >= 10 and py < 16)
				_:
					draw = true
			if not draw:
				continue
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


const ITEM_SHAPES: Dictionary = {
	"Steel": "ingot", "Plasteel": "ingot", "Silver": "ingot",
	"Gold": "ingot", "Uranium": "ingot",
	"Wood": "log", "Stone": "log",
	"MealSimple": "circle", "MealFine": "circle", "NutrientPaste": "circle",
	"RawFood": "circle", "Meat": "circle",
	"Medicine": "cross", "HerbalMedicine": "cross",
	"Cloth": "diamond", "Leather": "diamond",
	"Components": "dot", "AdvancedComponents": "dot",
	"Jade": "diamond",
}

const ITEM_TEX_FILES: Dictionary = {
	"Steel": "Steel.png", "Plasteel": "Plasteel.png", "Silver": "Silver.png",
	"Gold": "Gold.png", "Jade": "Jade.png",
	"Components": "ComponentIndustrial.png", "AdvancedComponents": "ComponentSpacer.png",
	"Cloth": "Cloth.png", "Leather": "Leather.png", "Hyperweave": "Hyperweave.png",
	"Meat": "Meat.png", "MealSimple": "MealSimple.png", "MealFine": "MealFine.png",
	"HerbalMedicine": "MedicineHerbal.png", "Medicine": "MedicineIndustrial.png",
	"Chemfuel": "Chemfuel.png", "Wood": "Wood.png",
}

const TREE_TEX_FILES: PackedStringArray = [
	"TreeOakA.png", "TreePineA.png", "TreeBirchA.png", "TreePoplarA.png",
	"TreeMapleA.png", "TreeCypressA.png", "TreeWillowA.png",
]
const TREE_IMMATURE_TEX_FILES: PackedStringArray = [
	"TreeOakImmature.png", "TreePineImmature.png",
]

const PLANT_TEX_MAP: Dictionary = {
	"BerryBush": "BerryBushA.png",
	"Potato": "AgaveA.png",
	"Rice": "GrassA.png",
	"Corn": "CornPlantA.png",
	"Cotton": "CottonPlantA.png",
	"Healroot": "DevilstrandA.png",
}

const PLANT_SHAPES: Dictionary = {
	"seedling": "dot",
	"leafy": "diamond",
	"growing": "bush",
	"mature": "bush",
	"tree_young": "canopy",
	"tree_mature": "canopy",
}


func _load_tex_from_file(abs_path: String) -> Texture2D:
	var img := Image.new()
	if img.load(abs_path) != OK:
		return null
	return ImageTexture.create_from_image(img)


func _load_building_textures() -> void:
	var base: String = ProjectSettings.globalize_path("res://assets/textures/buildings/")
	var tex_map: Dictionary[String, String] = {
		"DoorSimple": "DoorSimple_Mover.png",
		"Bed": "Bed_south.png",
		"BedDouble": "DoubleBed_south.png",
		"Stove": "Stove_south.png",
		"ElectricStove": "TableStoveElectric_south.png",
		"CookingStove": "TableStoveFueled_south.png",
		"FueledStove": "TableStoveFueled_south.png",
		"Cooler": "Cooler_south.png",
		"Battery": "Battery.png",
		"LampStanding": "LampStanding.png",
		"LampSun": "LampSun.png",
		"TorchLamp": "TorchLamp.png",
		"Table": "Table2x2_north.png",
		"Table1x2": "Table1x2_north.png",
		"Table2x4": "Table2x4_north.png",
		"Table3x3": "Table3x3_north.png",
		"DiningChair": "DiningChair_south.png",
		"Armchair": "Armchair_south.png",
		"Campfire": "Campfire.png",
		"Column": "Column.png",
		"Shelf": "Shelf_south.png",
		"ShelfSmall": "ShelfSmall_south.png",
		"ResearchBench": "ResearchBenchSimple_south.png",
		"HiTechResearchBench": "ResearchBenchHiTech_south.png",
		"ButcherSpot": "ButcherSpot.png",
		"CraftingSpot": "CraftingSpot.png",
		"TableButcher": "TableButcher_south.png",
		"TableMachining": "TableMachining_south.png",
		"TableStonecutter": "TableStonecutter_south.png",
		"ElectricSmelter": "ElectricSmelter_south.png",
		"FabricationBench": "FabricationBench_south.png",
		"TableTailorHand": "TableTailorHand_south.png",
		"TableTailorElectric": "TableTailorElectric_south.png",
		"TableSmithingFueled": "TableSmithingFueled_south.png",
		"TableSmithingElectric": "TableSmithingElectric_south.png",
		"Grave": "GraveEmpty_south.png",
		"Sarcophagus": "Sarcophagus_north.png",
		"Vent": "Vent.png",
		"PassiveCooler": "PassiveCooler.png",
		"ChemfuelPoweredGenerator": "ChemfuelPoweredGenerator.png",
		"WoodFiredGenerator": "WoodFiredGenerator.png",
		"EndTable": "EndTable_south.png",
		"TurretMini": "TurretMini_Base.png",
		"HospitalBed": "HospitalBed_south.png",
		"Bedroll": "Bedroll_south.png",
		"AnimalBed": "AnimalBed.png",
	}
	for def_key: String in tex_map:
		var abs_path: String = base + tex_map[def_key]
		if FileAccess.file_exists(abs_path):
			var tex := _load_tex_from_file(abs_path)
			if tex:
				_building_textures[def_key] = tex

	var wall_abs := base + "Wall_Atlas_Planks.png"
	if FileAccess.file_exists(wall_abs):
		var atlas_img := Image.new()
		if atlas_img.load(wall_abs) == OK:
			var tile_w: int = atlas_img.get_width() / 4
			var tile_h: int = atlas_img.get_height() / 4
			for row: int in 4:
				for col: int in 4:
					var sub := atlas_img.get_region(Rect2i(col * tile_w, row * tile_h, tile_w, tile_h))
					_wall_atlas_textures.append(ImageTexture.create_from_image(sub))


func _load_plant_textures() -> void:
	var base: String = ProjectSettings.globalize_path("res://assets/textures/sprites/plants/")
	var dir := DirAccess.open(base)
	if dir == null:
		return
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if file.ends_with(".png"):
			var tex := _load_tex_from_file(base + file)
			if tex:
				_plant_textures[file.get_basename()] = tex
		file = dir.get_next()


func _load_item_textures() -> void:
	var base: String = ProjectSettings.globalize_path("res://assets/textures/sprites/items/")
	var dir := DirAccess.open(base)
	if dir == null:
		return
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if file.ends_with(".png"):
			var tex := _load_tex_from_file(base + file)
			if tex:
				_item_textures[file.get_basename()] = tex
		file = dir.get_next()


func _load_pawn_textures() -> void:
	var base: String = ProjectSettings.globalize_path("res://assets/textures/sprites/pawns/")
	var body_files: PackedStringArray = [
		"Naked_Male_south.png", "Naked_Female_south.png",
		"Naked_Thin_south.png", "Naked_Fat_south.png", "Naked_Hulk_south.png",
	]
	for f: String in body_files:
		var tex := _load_tex_from_file(base + f)
		if tex:
			_pawn_body_textures.append(tex)
	var hair_files: PackedStringArray = ["HairA.png", "HairB.png", "HairC.png"]
	for f: String in hair_files:
		var tex := _load_tex_from_file(base + f)
		if tex:
			_pawn_hair_textures.append(tex)


func _load_animal_textures() -> void:
	var base: String = ProjectSettings.globalize_path("res://assets/textures/sprites/animals/")
	var dir := DirAccess.open(base)
	if dir == null:
		return
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if file.ends_with(".png"):
			var tex := _load_tex_from_file(base + file)
			if tex:
				_animal_textures[file.get_basename()] = tex
		file = dir.get_next()


func _get_wall_bitmask(pos: Vector2i) -> int:
	var mask: int = 0
	if _has_wall_at(pos + Vector2i(0, -1)):
		mask |= 1
	if _has_wall_at(pos + Vector2i(1, 0)):
		mask |= 2
	if _has_wall_at(pos + Vector2i(0, 1)):
		mask |= 4
	if _has_wall_at(pos + Vector2i(-1, 0)):
		mask |= 8
	return mask


func _has_wall_at(pos: Vector2i) -> bool:
	if map_data == null or not map_data.in_bounds(pos.x, pos.y):
		return false
	var cell := map_data.get_cell_v(pos)
	if cell == null:
		return false
	if cell.is_mountain:
		return true
	if not ThingManager:
		return false
	for t: Thing in cell.things:
		if t is Building and (t as Building).def_name == "Wall":
			return true
	return false


func _render_map() -> void:
	if map_data == null:
		return
	_terrain_layer.clear()
	var w := map_data.width
	var h := map_data.height
	for y: int in h:
		for x: int in w:
			var cell: Cell = map_data.cells[y * w + x]
			var base_key := _terrain_key(cell)
			if FloorManager and FloorManager.has_floor(Vector2i(x, y)):
				var floor_def: String = FloorManager.get_floor(Vector2i(x, y))
				var tile_key: String = _floor_to_tile.get(floor_def, "")
				if not tile_key.is_empty() and _terrain_id_map.has(tile_key + "_v0"):
					base_key = tile_key
			var variant := (x * 7 + y * 13) % TERRAIN_VARIANTS
			var vkey := base_key + "_v" + str(variant)
			if _terrain_id_map.has(vkey):
				_terrain_layer.set_cell(Vector2i(x, y), 0, _terrain_id_map[vkey])


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
		var node: Node2D = _pawn_sprites[pid]
		if node.visible:
			cnt += 1
	return cnt


func get_visible_animal_count() -> int:
	var cnt: int = 0
	for aid: int in _animal_sprites:
		var node: Node2D = _animal_sprites[aid]
		if node.visible:
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


func _update_pawn_indicators() -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if not _pawn_sprites.has(p.id):
			continue
		var container: Node2D = _pawn_sprites[p.id]
		var ring: Sprite2D = container.get_node_or_null("SelectRing")
		if ring:
			ring.visible = (p.id == _selected_pawn_id)
			if ring.visible:
				var pulse: float = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.004)
				ring.modulate.a = pulse
		var bar_bg: ColorRect = container.get_node_or_null("HealthBG")
		var bar_fill: ColorRect = container.get_node_or_null("HealthFill")
		if bar_bg and bar_fill:
			var hp_ratio: float = 1.0
			if p.health:
				hp_ratio = clampf(p.health.get_overall_health(), 0.0, 1.0)
			var bar_w: float = bar_bg.size.x
			bar_fill.size.x = bar_w * hp_ratio
			if hp_ratio > 0.6:
				bar_fill.color = Color(0.2, 0.9, 0.2, 0.8)
			elif hp_ratio > 0.3:
				bar_fill.color = Color(0.9, 0.9, 0.2, 0.8)
			else:
				bar_fill.color = Color(0.9, 0.2, 0.2, 0.8)
			var show_bar: bool = hp_ratio < 0.99 or p.id == _selected_pawn_id
			bar_bg.visible = show_bar
			bar_fill.visible = show_bar
			if hp_ratio < 0.9 and not p.dead:
				_spawn_blood_at(p.grid_pos)
		var job_lbl: Label = container.get_node_or_null("JobLabel")
		if job_lbl:
			var job_name: String = p.current_job_name if p.current_job_name else ""
			var is_sleeping: bool = job_name == "Sleep" or job_name == "Rest"
			if p.drafted:
				job_lbl.text = "Drafted"
				job_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 0.9))
			elif p.dead:
				job_lbl.text = ""
			elif is_sleeping:
				var z_phase: float = Time.get_ticks_msec() * 0.002 + float(p.id) * 1.5
				var z_count: int = 1 + int(fmod(z_phase, 3.0))
				job_lbl.text = "Z".repeat(z_count)
				job_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 0.7))
				job_lbl.position.y = -CELL_SIZE * 0.8 - sin(z_phase) * 3.0
			elif job_name.is_empty() or job_name == "Idle":
				job_lbl.text = "Idle"
				job_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.6))
				job_lbl.position.y = CELL_SIZE * 0.6
			else:
				job_lbl.text = job_name
				job_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6, 0.85))
				job_lbl.position.y = CELL_SIZE * 0.6


func _spawn_blood_at(pos: Vector2i) -> void:
	if _blood_sprites.size() >= 80:
		var old: Sprite2D = _blood_sprites[0]
		_blood_sprites.remove_at(0)
		if is_instance_valid(old):
			old.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = randi()
	var size: int = rng.randi_range(6, 10)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark_blood := Color(0.4, 0.02, 0.02, 0.7)
	var bright_blood := Color(0.65, 0.08, 0.08, 0.85)
	var edge_blood := Color(0.5, 0.04, 0.04, 0.4)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var r: float = size * 0.4
	for y: int in size:
		for x: int in size:
			var dist: float = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy))
			if dist < r * 0.5:
				img.set_pixel(x, y, bright_blood)
			elif dist < r:
				img.set_pixel(x, y, dark_blood)
			elif dist < r + 1.0 and rng.randf() < 0.4:
				img.set_pixel(x, y, edge_blood)
	for i: int in range(rng.randi_range(3, 6)):
		var sx: int = rng.randi_range(0, size - 1)
		var sy: int = rng.randi_range(0, size - 1)
		if img.get_pixel(sx, sy).a > 0:
			var dir_x: int = rng.randi_range(-1, 1)
			var dir_y: int = rng.randi_range(-1, 1)
			for step: int in range(rng.randi_range(1, 3)):
				var nx: int = sx + dir_x * step
				var ny: int = sy + dir_y * step
				if nx >= 0 and nx < size and ny >= 0 and ny < size:
					img.set_pixel(nx, ny, edge_blood)
	var tex := ImageTexture.create_from_image(img)
	var spr := Sprite2D.new()
	spr.texture = tex
	var offset_x: float = randf_range(-CELL_SIZE * 0.3, CELL_SIZE * 0.3)
	var offset_y: float = randf_range(-CELL_SIZE * 0.3, CELL_SIZE * 0.3)
	spr.position = Vector2(pos.x * CELL_SIZE + CELL_SIZE * 0.5 + offset_x,
		pos.y * CELL_SIZE + CELL_SIZE * 0.5 + offset_y)
	spr.z_index = 1
	spr.rotation = randf_range(0, TAU)
	var s: float = randf_range(1.2, 2.0)
	spr.scale = Vector2(s, s)
	add_child(spr)
	_blood_sprites.append(spr)


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

var _last_quadrum: String = ""

func _on_date_changed(date: Dictionary) -> void:
	_update_day_night(date.get("hour", 12))
	var q: String = date.get("quadrum", "")
	if q != _last_quadrum and not q.is_empty():
		_last_quadrum = q
		_update_seasonal_colors(q)


func _update_seasonal_colors(quadrum: String) -> void:
	var tint: Color = Color.WHITE
	var leaf_col: Color = Color(0.45, 0.55, 0.25, 0.3)
	match quadrum:
		"Aprimay":
			tint = Color(0.9, 1.0, 0.85)
			leaf_col = Color(0.4, 0.6, 0.3, 0.3)
		"Jugust":
			tint = Color.WHITE
			leaf_col = Color(0.35, 0.55, 0.2, 0.25)
		"Septober":
			tint = Color(1.0, 0.85, 0.6)
			leaf_col = Color(0.7, 0.5, 0.2, 0.4)
		"Decembary":
			tint = Color(0.8, 0.85, 0.9)
			leaf_col = Color(0.5, 0.45, 0.3, 0.2)
	for spr_id: int in _plant_sprites:
		var spr: Sprite2D = _plant_sprites[spr_id]
		if spr and is_instance_valid(spr) and spr_id < 100000:
			spr.modulate = spr.modulate.lerp(tint, 0.3)
	if _leaf_particles:
		_leaf_particles.color = leaf_col
		if quadrum == "Septober":
			_leaf_particles.amount = 30
		elif quadrum == "Decembary":
			_leaf_particles.amount = 5
		else:
			_leaf_particles.amount = 15


func _on_weather_changed(_old: String, new_type: String) -> void:
	_update_weather_vfx(new_type)


func _update_weather_vfx(weather: String) -> void:
	if _weather_particles == null:
		return
	_weather_particles.texture = _rain_streak_tex if weather in ["Rain", "Drizzle", "Thunderstorm"] else null
	_weather_particles.lifetime = 2.5
	_weather_particles.spread = 10.0
	var enable_splash := false
	match weather:
		"Rain":
			_weather_particles.emitting = true
			_weather_particles.amount = 500
			_weather_particles.color = Color(0.7, 0.75, 0.9, 0.55)
			_weather_particles.initial_velocity_min = 150.0
			_weather_particles.initial_velocity_max = 250.0
			_weather_particles.gravity = Vector2(40, 350)
			_weather_particles.scale_amount_min = 1.0
			_weather_particles.scale_amount_max = 2.0
			enable_splash = true
		"Drizzle":
			_weather_particles.emitting = true
			_weather_particles.amount = 180
			_weather_particles.color = Color(0.65, 0.72, 0.85, 0.35)
			_weather_particles.initial_velocity_min = 80.0
			_weather_particles.initial_velocity_max = 130.0
			_weather_particles.gravity = Vector2(15, 180)
			_weather_particles.scale_amount_min = 0.6
			_weather_particles.scale_amount_max = 1.2
			enable_splash = true
		"Snow":
			_weather_particles.emitting = true
			_weather_particles.amount = 200
			_weather_particles.color = Color(0.92, 0.94, 0.97, 0.6)
			_weather_particles.initial_velocity_min = 20.0
			_weather_particles.initial_velocity_max = 50.0
			_weather_particles.gravity = Vector2(15, 40)
			_weather_particles.spread = 45.0
			_weather_particles.scale_amount_min = 1.0
			_weather_particles.scale_amount_max = 2.5
			_weather_particles.lifetime = 5.0
		"Thunderstorm":
			_weather_particles.emitting = true
			_weather_particles.amount = 700
			_weather_particles.color = Color(0.6, 0.65, 0.8, 0.6)
			_weather_particles.initial_velocity_min = 220.0
			_weather_particles.initial_velocity_max = 380.0
			_weather_particles.gravity = Vector2(70, 450)
			_weather_particles.scale_amount_min = 1.2
			_weather_particles.scale_amount_max = 2.5
			enable_splash = true
		"Hail":
			_weather_particles.emitting = true
			_weather_particles.amount = 150
			_weather_particles.color = Color(0.88, 0.9, 0.97, 0.7)
			_weather_particles.initial_velocity_min = 180.0
			_weather_particles.initial_velocity_max = 300.0
			_weather_particles.gravity = Vector2(20, 500)
			_weather_particles.scale_amount_min = 1.5
			_weather_particles.scale_amount_max = 3.0
			enable_splash = true
		"Fog":
			_weather_particles.emitting = true
			_weather_particles.amount = 30
			_weather_particles.color = Color(0.8, 0.82, 0.85, 0.15)
			_weather_particles.initial_velocity_min = 5.0
			_weather_particles.initial_velocity_max = 15.0
			_weather_particles.gravity = Vector2(8, 5)
			_weather_particles.spread = 180.0
			_weather_particles.scale_amount_min = 4.0
			_weather_particles.scale_amount_max = 8.0
			_weather_particles.lifetime = 6.0
		_:
			_weather_particles.emitting = false
	if _rain_splash_particles:
		_rain_splash_particles.emitting = enable_splash
		if enable_splash:
			var splash_count := 40 if weather == "Drizzle" else (120 if weather == "Thunderstorm" else 80)
			_rain_splash_particles.amount = splash_count
	if _fog_overlay:
		match weather:
			"Fog":
				_fog_overlay.color = Color(0.75, 0.78, 0.82, 0.25)
			"Rain":
				_fog_overlay.color = Color(0.55, 0.58, 0.65, 0.12)
			"Thunderstorm":
				_fog_overlay.color = Color(0.4, 0.42, 0.5, 0.18)
			"Drizzle":
				_fog_overlay.color = Color(0.6, 0.63, 0.68, 0.06)
			_:
				_fog_overlay.color = Color(0.75, 0.78, 0.82, 0.0)
	match weather:
		"Rain":
			_wet_ground_target = 1.0
			_snow_ground_target = 0.0
		"Thunderstorm":
			_wet_ground_target = 1.0
			_snow_ground_target = 0.0
		"Drizzle":
			_wet_ground_target = 0.5
			_snow_ground_target = 0.0
		"Snow":
			_wet_ground_target = 0.0
			_snow_ground_target = 1.0
		_:
			_wet_ground_target = 0.0
			_snow_ground_target = maxf(_snow_ground_target - 0.3, 0.0)


func _update_lightning(delta: float) -> void:
	if _day_night_mod == null:
		return
	var is_storm: bool = WeatherManager and WeatherManager.current_weather == "Thunderstorm"
	if not is_storm:
		if _lightning_flash > 0.0:
			_lightning_flash = 0.0
		return
	_lightning_timer -= delta
	if _lightning_timer <= 0.0:
		_lightning_flash = 0.6
		_lightning_timer = randf_range(3.0, 10.0)
	if _lightning_flash > 0.0:
		_lightning_flash = maxf(0.0, _lightning_flash - delta * 3.0)
		var base_color: Color = _day_night_mod.color
		var flash_add := _lightning_flash * 0.4
		_day_night_mod.color = Color(
			minf(base_color.r + flash_add, 1.0),
			minf(base_color.g + flash_add, 1.0),
			minf(base_color.b + flash_add + 0.05, 1.0),
			1.0)


func _update_day_night(hour: int) -> void:
	if _day_night_mod == null:
		return
	var t: float = float(hour)
	var color: Color
	if t >= 5.0 and t < 6.0:
		var p: float = t - 5.0
		color = Color(0.35, 0.35, 0.5).lerp(Color(0.85, 0.55, 0.5), p)
	elif t >= 6.0 and t < 7.0:
		var p: float = t - 6.0
		color = Color(0.85, 0.55, 0.5).lerp(Color(1.0, 0.9, 0.85), p)
	elif t >= 7.0 and t < 8.0:
		var p: float = t - 7.0
		color = Color(1.0, 0.9, 0.85).lerp(Color.WHITE, p)
	elif t >= 8.0 and t < 17.0:
		color = Color.WHITE
	elif t >= 17.0 and t < 18.0:
		var p: float = t - 17.0
		color = Color.WHITE.lerp(Color(1.0, 0.92, 0.8), p)
	elif t >= 18.0 and t < 19.0:
		var p: float = t - 18.0
		color = Color(1.0, 0.92, 0.8).lerp(Color(0.95, 0.6, 0.4), p)
	elif t >= 19.0 and t < 20.0:
		var p: float = t - 19.0
		color = Color(0.95, 0.6, 0.4).lerp(Color(0.7, 0.45, 0.5), p)
	elif t >= 20.0 and t < 21.0:
		var p: float = t - 20.0
		color = Color(0.7, 0.45, 0.5).lerp(Color(0.3, 0.3, 0.42), p)
	elif t >= 21.0 or t < 4.0:
		color = Color(0.25, 0.25, 0.38)
	elif t >= 4.0 and t < 5.0:
		var p: float = t - 4.0
		color = Color(0.25, 0.25, 0.38).lerp(Color(0.30, 0.30, 0.45), p)
	else:
		color = Color.WHITE
	_day_night_mod.color = color
	var night_factor: float = 1.0 - color.get_luminance()
	var glow_scale: float = 1.0 + night_factor * 0.8
	for key: int in _building_sprites:
		if key >= 100000 and key < 200000:
			var glow_spr: Sprite2D = _building_sprites[key] as Sprite2D
			if glow_spr and is_instance_valid(glow_spr):
				glow_spr.modulate.a = 0.6 + night_factor * 0.4
				glow_spr.scale = Vector2(glow_scale, glow_scale)


var _sync_timer: float = 0.0

func _process(delta: float) -> void:
	_sync_timer += delta
	if _sync_timer > 2.0:
		_sync_timer = 0.0
		ensure_pawn_sprites()
		_ensure_animal_sprites()
		_update_pawn_indicators()
	var move := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move.y += 1

	if move != Vector2.ZERO:
		_camera.position += move.normalized() * 300.0 * delta / _camera.zoom.x
	_lerp_sprites(delta)
	if _hover_cell_sprite and map_data:
		var mouse_pos := get_viewport().get_mouse_position()
		var cell := _screen_to_cell(mouse_pos)
		if map_data.in_bounds(cell.x, cell.y):
			_hover_cell_sprite.visible = true
			_hover_cell_sprite.position = Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)
		else:
			_hover_cell_sprite.visible = false
	if _weather_particles and _weather_particles.emitting:
		_weather_particles.position = _camera.position + Vector2(0, -600)
	if _rain_splash_particles and _rain_splash_particles.emitting:
		_rain_splash_particles.position = _camera.position
	if _leaf_particles:
		_leaf_particles.position = _camera.position + Vector2(0, -400)
	if _fog_overlay and _fog_overlay.color.a > 0.0:
		_fog_overlay.position = _camera.position - _fog_overlay.size / 2.0
	_water_time += delta
	if not _water_highlights.is_empty():
		for ws: Sprite2D in _water_highlights:
			var phase: float = ws.get_meta("phase")
			var base_x: float = ws.get_meta("base_x")
			var base_y: float = ws.get_meta("base_y") if ws.has_meta("base_y") else ws.position.y
			var spd: float = ws.get_meta("speed") if ws.has_meta("speed") else 1.0
			ws.position.x = base_x + sin(_water_time * 0.6 * spd + phase) * 2.5
			ws.position.y = base_y + cos(_water_time * 0.4 * spd + phase * 1.3) * 0.8
			ws.modulate.a = 0.25 + sin(_water_time * 1.0 * spd + phase) * 0.2
	for spr_id: int in _plant_sprites:
		var spr: Sprite2D = _plant_sprites[spr_id]
		if spr and is_instance_valid(spr):
			var phase: float = float(spr_id % 100) * 0.5
			spr.rotation = sin(_water_time * 0.5 + phase) * 0.02
	for gs: Sprite2D in _ground_clutter:
		if gs and is_instance_valid(gs):
			var gphase: float = gs.position.x * 0.3
			gs.rotation = sin(_water_time * 0.7 + gphase) * 0.05
	_update_lightning(delta)
	if _wet_ground_sprite:
		_wet_ground_alpha = move_toward(_wet_ground_alpha, _wet_ground_target, delta * 0.3)
		if _wet_ground_alpha > 0.01:
			_wet_ground_sprite.visible = true
			_wet_ground_sprite.modulate.a = _wet_ground_alpha
		else:
			_wet_ground_sprite.visible = false
	if _snow_ground_sprite:
		_snow_ground_alpha = move_toward(_snow_ground_alpha, _snow_ground_target, delta * 0.15)
		if _snow_ground_alpha > 0.01:
			_snow_ground_sprite.visible = true
			_snow_ground_sprite.modulate.a = _snow_ground_alpha
		else:
			_snow_ground_sprite.visible = false


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
	var t_ms: float = Time.get_ticks_msec() * 0.012
	for pid: int in _pawn_sprites:
		if _pawn_target_pos.has(pid):
			var node: Node2D = _pawn_sprites[pid]
			var target: Vector2 = _pawn_target_pos[pid]
			if node.position.distance_squared_to(target) > 0.5:
				var dir_x: float = target.x - node.position.x
				if absf(dir_x) > 0.5:
					node.scale.x = -1.0 if dir_x < 0 else 1.0
				node.position = node.position.lerp(target, lerp_factor)
				var bob_phase: float = t_ms + pid * 2.3
				node.position.y += sin(bob_phase) * 1.2
				node.rotation = sin(bob_phase * 0.5) * 0.06
			else:
				node.position = target
				node.rotation = lerpf(node.rotation, 0.0, delta * 8.0)
	for aid: int in _animal_sprites:
		if _animal_target_pos.has(aid):
			var node: Node2D = _animal_sprites[aid]
			var target: Vector2 = _animal_target_pos[aid]
			if node.position.distance_squared_to(target) > 0.5:
				var dir_x: float = target.x - node.position.x
				if absf(dir_x) > 0.5:
					node.scale.x = -absf(node.scale.x) if dir_x < 0 else absf(node.scale.x)
				node.position = node.position.lerp(target, lerp_factor)
				var bob_phase: float = t_ms + aid * 1.7
				node.position.y += sin(bob_phase) * 0.8
			else:
				node.position = target


func _render_terrain_blend() -> void:
	if map_data == null:
		return
	var w := map_data.width
	var h := map_data.height
	var img_w := w * CELL_SIZE
	var img_h := h * CELL_SIZE
	var blend_img := Image.create(img_w, img_h, false, Image.FORMAT_RGBA8)
	blend_img.fill(Color(0, 0, 0, 0))
	var terrain_colors: Dictionary = {
		"Soil": Color(0.58, 0.52, 0.32),
		"SoilRich": Color(0.48, 0.44, 0.24),
		"Sand": Color(0.82, 0.78, 0.58),
		"Gravel": Color(0.62, 0.58, 0.50),
		"MarshyTerrain": Color(0.42, 0.50, 0.30),
		"Mud": Color(0.50, 0.42, 0.28),
		"WaterShallow": Color(0.35, 0.52, 0.70),
		"WaterDeep": Color(0.22, 0.35, 0.55),
		"RoughStone": Color(0.62, 0.60, 0.56),
		"Mountain": Color(0.48, 0.45, 0.42),
	}
	const BLEND_PX: int = 4
	var dirs: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	for y: int in h:
		for x: int in w:
			var cell: Cell = map_data.cells[y * w + x]
			var my_terrain := _terrain_key(cell)
			for d: Vector2i in dirs:
				var nx := x + d.x
				var ny := y + d.y
				if nx < 0 or nx >= w or ny < 0 or ny >= h:
					continue
				var nc: Cell = map_data.cells[ny * w + nx]
				var nb_terrain := _terrain_key(nc)
				if nb_terrain == my_terrain:
					continue
				var nb_col: Color = terrain_colors.get(nb_terrain, Color(0.5, 0.5, 0.5))
				var ox := x * CELL_SIZE
				var oy := y * CELL_SIZE
				for step: int in BLEND_PX:
					var alpha: float = 0.25 * (1.0 - float(step) / float(BLEND_PX))
					var blend_col := Color(nb_col.r, nb_col.g, nb_col.b, alpha)
					if d == Vector2i(1, 0):
						var px := CELL_SIZE - 1 - step
						for py: int in CELL_SIZE:
							var existing := blend_img.get_pixel(ox + px, oy + py)
							if blend_col.a > existing.a:
								blend_img.set_pixel(ox + px, oy + py, blend_col)
					elif d == Vector2i(-1, 0):
						var px := step
						for py: int in CELL_SIZE:
							var existing := blend_img.get_pixel(ox + px, oy + py)
							if blend_col.a > existing.a:
								blend_img.set_pixel(ox + px, oy + py, blend_col)
					elif d == Vector2i(0, 1):
						var py := CELL_SIZE - 1 - step
						for px: int in CELL_SIZE:
							var existing := blend_img.get_pixel(ox + px, oy + py)
							if blend_col.a > existing.a:
								blend_img.set_pixel(ox + px, oy + py, blend_col)
					elif d == Vector2i(0, -1):
						var py := step
						for px: int in CELL_SIZE:
							var existing := blend_img.get_pixel(ox + px, oy + py)
							if blend_col.a > existing.a:
								blend_img.set_pixel(ox + px, oy + py, blend_col)
	const CLIFF_PX: int = 5
	for y: int in h:
		for x: int in w:
			var cell: Cell = map_data.cells[y * w + x]
			if not cell.is_mountain:
				continue
			for d: Vector2i in [Vector2i(0, 1), Vector2i(1, 0)]:
				var nx := x + d.x
				var ny := y + d.y
				if nx < 0 or nx >= w or ny < 0 or ny >= h:
					continue
				var nc: Cell = map_data.cells[ny * w + nx]
				if nc.is_mountain:
					continue
				var nox := nx * CELL_SIZE
				var noy := ny * CELL_SIZE
				for step: int in CLIFF_PX:
					var alpha: float = 0.35 * (1.0 - float(step) / float(CLIFF_PX))
					var shadow_col := Color(0.0, 0.0, 0.0, alpha)
					if d == Vector2i(0, 1):
						var py := step
						for px: int in CELL_SIZE:
							var existing := blend_img.get_pixel(nox + px, noy + py)
							var merged := Color(0, 0, 0, maxf(existing.a, shadow_col.a))
							blend_img.set_pixel(nox + px, noy + py, merged)
					elif d == Vector2i(1, 0):
						var px := step
						for py: int in CELL_SIZE:
							var existing := blend_img.get_pixel(nox + px, noy + py)
							var merged := Color(0, 0, 0, maxf(existing.a, shadow_col.a))
							blend_img.set_pixel(nox + px, noy + py, merged)
	var blend_tex := ImageTexture.create_from_image(blend_img)
	_terrain_blend_sprite.texture = blend_tex


func _render_grid_overlay() -> void:
	if map_data == null or _grid_overlay_sprite == null:
		return
	var w := map_data.width
	var h := map_data.height
	var img_w := w * CELL_SIZE
	var img_h := h * CELL_SIZE
	var grid_img := Image.create(img_w, img_h, false, Image.FORMAT_RGBA8)
	grid_img.fill(Color(0, 0, 0, 0))
	var line_col := Color(0, 0, 0, 0.08)
	for y: int in range(1, h):
		var py: int = y * CELL_SIZE
		for px: int in img_w:
			grid_img.set_pixel(px, py, line_col)
	for x: int in range(1, w):
		var px: int = x * CELL_SIZE
		for py: int in img_h:
			grid_img.set_pixel(px, py, line_col)
	_grid_overlay_sprite.texture = ImageTexture.create_from_image(grid_img)


func _render_wet_ground() -> void:
	if map_data == null or _wet_ground_sprite == null:
		return
	var w := map_data.width
	var h := map_data.height
	var img_w := w * CELL_SIZE
	var img_h := h * CELL_SIZE
	var wet_img := Image.create(img_w, img_h, false, Image.FORMAT_RGBA8)
	wet_img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 54321
	var puddle_col := Color(0.15, 0.18, 0.25, 0.18)
	var wet_col := Color(0.1, 0.12, 0.18, 0.10)
	for y: int in h:
		for x: int in w:
			var tname: String = map_data.get_terrain(x, y)
			if tname in ["Water", "WaterDeep", "Marsh", "Ice"]:
				continue
			if tname in ["Mountain", "SmoothStone"]:
				continue
			var ox := x * CELL_SIZE
			var oy := y * CELL_SIZE
			for py: int in CELL_SIZE:
				for px: int in CELL_SIZE:
					wet_img.set_pixel(ox + px, oy + py, wet_col)
			if rng.randf() < 0.08:
				var cx: int = ox + rng.randi_range(2, CELL_SIZE - 3)
				var cy: int = oy + rng.randi_range(2, CELL_SIZE - 3)
				var r: int = rng.randi_range(2, 4)
				for py: int in range(-r, r + 1):
					for px: int in range(-r, r + 1):
						if px * px + py * py <= r * r:
							var fx: int = cx + px
							var fy: int = cy + py
							if fx >= 0 and fx < img_w and fy >= 0 and fy < img_h:
								wet_img.set_pixel(fx, fy, puddle_col)
	_wet_ground_sprite.texture = ImageTexture.create_from_image(wet_img)


func _render_snow_ground() -> void:
	if map_data == null or _snow_ground_sprite == null:
		return
	var w := map_data.width
	var h := map_data.height
	var img_w := w * CELL_SIZE
	var img_h := h * CELL_SIZE
	var snow_img := Image.create(img_w, img_h, false, Image.FORMAT_RGBA8)
	snow_img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 98765
	var base_snow := Color(0.92, 0.94, 0.97, 0.22)
	var drift_snow := Color(0.95, 0.96, 0.98, 0.35)
	for y: int in h:
		for x: int in w:
			var tname: String = map_data.get_terrain(x, y)
			if tname in ["Water", "WaterDeep", "Marsh"]:
				continue
			if tname == "Mountain":
				continue
			var ox := x * CELL_SIZE
			var oy := y * CELL_SIZE
			for py: int in CELL_SIZE:
				for px: int in CELL_SIZE:
					var noise: float = rng.randf() * 0.06
					snow_img.set_pixel(ox + px, oy + py, Color(base_snow.r + noise, base_snow.g + noise, base_snow.b, base_snow.a))
			if rng.randf() < 0.12:
				var cx: int = ox + rng.randi_range(1, CELL_SIZE - 2)
				var cy: int = oy + rng.randi_range(1, CELL_SIZE - 2)
				var r: int = rng.randi_range(2, 5)
				for py: int in range(-r, r + 1):
					for px: int in range(-r, r + 1):
						if px * px + py * py <= r * r:
							var fx: int = cx + px
							var fy: int = cy + py
							if fx >= 0 and fx < img_w and fy >= 0 and fy < img_h:
								snow_img.set_pixel(fx, fy, drift_snow)
	_snow_ground_sprite.texture = ImageTexture.create_from_image(snow_img)


func _render_roof_overlay() -> void:
	if map_data == null:
		return
	var w := map_data.width
	var h := map_data.height
	var img_w := w * CELL_SIZE
	var img_h := h * CELL_SIZE
	_roof_image = Image.create(img_w, img_h, false, Image.FORMAT_RGBA8)
	_roof_image.fill(Color(0, 0, 0, 0))
	var roof_col := Color(0.15, 0.12, 0.08, 0.22)
	var edge_col := Color(0.05, 0.03, 0.02, 0.35)
	var dirs: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	for y: int in h:
		for x: int in w:
			var cell: Cell = map_data.cells[y * w + x]
			if not cell.roof or cell.is_mountain:
				continue
			var ox := x * CELL_SIZE
			var oy := y * CELL_SIZE
			var is_edge_r := false
			var is_edge_l := false
			var is_edge_b := false
			var is_edge_t := false
			for d: Vector2i in dirs:
				var nx := x + d.x
				var ny := y + d.y
				if nx < 0 or nx >= w or ny < 0 or ny >= h:
					continue
				var nc: Cell = map_data.cells[ny * w + nx]
				if not nc.roof or nc.is_mountain:
					if d == Vector2i(1, 0): is_edge_r = true
					elif d == Vector2i(-1, 0): is_edge_l = true
					elif d == Vector2i(0, 1): is_edge_b = true
					elif d == Vector2i(0, -1): is_edge_t = true
			for py: int in CELL_SIZE:
				for px: int in CELL_SIZE:
					var col := roof_col
					var edge_blend: float = 0.0
					if is_edge_r and px >= CELL_SIZE - 3:
						edge_blend = maxf(edge_blend, float(px - (CELL_SIZE - 4)) / 3.0)
					if is_edge_l and px < 3:
						edge_blend = maxf(edge_blend, float(3 - px) / 3.0)
					if is_edge_b and py >= CELL_SIZE - 3:
						edge_blend = maxf(edge_blend, float(py - (CELL_SIZE - 4)) / 3.0)
					if is_edge_t and py < 3:
						edge_blend = maxf(edge_blend, float(3 - py) / 3.0)
					if edge_blend > 0.0:
						col = roof_col.lerp(edge_col, clampf(edge_blend, 0.0, 1.0))
					_roof_image.set_pixel(ox + px, oy + py, col)
	_roof_texture = ImageTexture.create_from_image(_roof_image)
	_roof_sprite.texture = _roof_texture


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
			_fill_zone_cell(_zone_image, pos, col, zone_type)

	_zone_texture = ImageTexture.create_from_image(_zone_image)
	_zone_sprite.texture = _zone_texture


func _fill_zone_cell(img: Image, cell: Vector2i, col: Color, zone_type: String = "") -> void:
	var ox := cell.x * CELL_SIZE
	var oy := cell.y * CELL_SIZE
	var border_col := Color(col.r, col.g, col.b, minf(col.a * 2.0, 0.95))
	var inner_col := Color(col.r, col.g, col.b, col.a * 0.5)
	for py: int in CELL_SIZE:
		for px: int in CELL_SIZE:
			var x := ox + px
			var y := oy + py
			if x < img.get_width() and y < img.get_height():
				var is_border := px == 0 or py == 0 or px == CELL_SIZE - 1 or py == CELL_SIZE - 1
				if is_border:
					img.set_pixel(x, y, border_col)
				elif zone_type == "GrowingZone" and py % 4 < 2:
					img.set_pixel(x, y, Color(0.35, 0.28, 0.18, 0.3))
				else:
					img.set_pixel(x, y, inner_col)


func _on_zone_changed(_zone_type: String, pos: Vector2i) -> void:
	if _zone_image == null:
		_render_zones()
		return
	var zt: String = ZoneManager.zones.get(pos, "")
	if zt.is_empty():
		return
	var col: Color = ZoneManager.get_zone_color(zt)
	_fill_zone_cell(_zone_image, pos, col, zt)
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
