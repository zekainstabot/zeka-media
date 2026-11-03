extends Node2D

# ZekaCity V1 - BuildingVisual
# Godot 3.6
# تمام ساختمان‌ها از یک سیستم مختصات ایزومتریک مشترک استفاده می‌کنند.
# نقطه اتصال تصویر به زمین از پیکسل‌های واقعی PNG محاسبه می‌شود.

const ISOMETRIC_GRID_SCRIPT = preload(
	"res://scripts/rendering/IsometricGrid.gd"
)

const SPRITE_CATALOG_SCRIPT = preload(
	"res://scripts/buildings/BuildingSpriteCatalog.gd"
)

const DEFAULT_TILE_WIDTH = 64.0
const DEFAULT_TILE_HEIGHT = 32.0

var world = null
var building_id = ""
var grid_pos = Vector2.ZERO

var building_index = -1
var visual_alpha = 1.0

var building_texture = null
var sprite_catalog = null
var isometric_grid = null
var drawer = null

var visible_bounds = Rect2()
var has_visible_bounds = false

var sprite_anchor = Vector2(0.5, 1.0)
var sprite_scale = 1.2


func setup(
	p_world,
	p_building_id,
	p_grid_pos,
	p_building_index = -1,
	p_visual_alpha = 1.0
):
	world = p_world
	building_id = str(p_building_id)
	grid_pos = p_grid_pos
	building_index = p_building_index
	visual_alpha = p_visual_alpha

	_initialize_systems()
	_load_sprite_settings()
	_load_building_texture()
	_calculate_visible_bounds()
	_update_building_position()

	modulate = Color(
		1.0,
		1.0,
		1.0,
		clamp(visual_alpha, 0.0, 1.0)
	)

	update()


func _initialize_systems():
	if world != null:
		if "isometric_grid" in world and world.isometric_grid != null:
			isometric_grid = world.isometric_grid

	if isometric_grid == null:
		isometric_grid = ISOMETRIC_GRID_SCRIPT.new(
			DEFAULT_TILE_WIDTH,
			DEFAULT_TILE_HEIGHT
		)

	if sprite_catalog == null:
		sprite_catalog = SPRITE_CATALOG_SCRIPT.new()


func _load_sprite_settings():
	if sprite_catalog == null:
		return

	sprite_anchor = sprite_catalog.get_anchor(building_id)
	sprite_scale = sprite_catalog.get_scale_multiplier(building_id)

	if sprite_scale <= 0.0:
		sprite_scale = 1.0

	if sprite_anchor.x < 0.0 or sprite_anchor.x > 1.0:
		sprite_anchor.x = 0.5

	if sprite_anchor.y < 0.0 or sprite_anchor.y > 1.0:
		sprite_anchor.y = 1.0


func _load_building_texture():
	building_texture = null
	has_visible_bounds = false
	visible_bounds = Rect2()

	if sprite_catalog == null:
		return

	var texture_path = sprite_catalog.get_texture_path(building_id)

	if texture_path == "":
		push_warning("Building sprite is not registered: " + building_id)
		return

	if not ResourceLoader.exists(texture_path):
		push_warning("Building image not found: " + texture_path)
		return

	building_texture = load(texture_path)

	if building_texture == null:
		push_warning("Could not load building image: " + texture_path)


func _calculate_visible_bounds():
	has_visible_bounds = false
	visible_bounds = Rect2()

	if building_texture == null:
		return

	var image = building_texture.get_data()

	if image == null:
		push_warning("Could not read image data: " + building_id)
		return

	var image_width = image.get_width()
	var image_height = image.get_height()

	if image_width <= 0 or image_height <= 0:
		return

	image.lock()

	var min_x = image_width
	var min_y = image_height
	var max_x = -1
	var max_y = -1

	for y in range(image_height):
		for x in range(image_width):
			if image.get_pixel(x, y).a > 0.05:
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)

	image.unlock()

	if max_x < min_x or max_y < min_y:
		return

	visible_bounds = Rect2(
		min_x,
		min_y,
		max_x - min_x + 1,
		max_y - min_y + 1
	)

	has_visible_bounds = true


func _get_map_origin():
	if world != null and world.has_method("get_map_origin"):
		return world.get_map_origin()

	return Vector2(600.0, 130.0)


func _get_footprint():
	if world != null:
		if "building_footprints" in world:
			if world.building_footprints != null:
				return world.building_footprints.get_footprint(
					building_id
				)

	return Vector2.ONE


func _update_building_position():
	if isometric_grid == null:
		_initialize_systems()

	var footprint = _get_footprint()
	var map_origin = _get_map_origin()

	# مرکز سطح اشغال‌شده ساختمان؛ بدون جابه‌جایی عمودی دستی.
	position = isometric_grid.get_footprint_ground_position(
		grid_pos,
		footprint,
		map_origin
	)

	# ترتیب رسم بر اساس انتهای سطح اشغال‌شده.
	var depth_grid = grid_pos + Vector2(
		footprint.x - 1.0,
		footprint.y - 1.0
	)

	z_index = int(round(depth_grid.x + depth_grid.y))


func _get_visible_anchor_pixel():
	if not has_visible_bounds:
		if building_texture == null:
			return Vector2.ZERO

		var texture_size = building_texture.get_size()

		return Vector2(
			texture_size.x * sprite_anchor.x,
			texture_size.y * sprite_anchor.y
		)

	return Vector2(
		visible_bounds.position.x
			+ visible_bounds.size.x * sprite_anchor.x,
		visible_bounds.position.y
			+ visible_bounds.size.y * sprite_anchor.y
	)


func _draw():
	if building_texture == null:
		if drawer != null and drawer.has_method("draw_building"):
			drawer.draw_building(
				self,
				building_id,
				Vector2.ZERO
			)
		return

	var anchor_pixel = _get_visible_anchor_pixel()

	# نقطه اتصال PNG دقیقاً روی مبدأ Node قرار می‌گیرد.
	var draw_position = -anchor_pixel * sprite_scale

	draw_set_transform(
		draw_position,
		0.0,
		Vector2(sprite_scale, sprite_scale)
	)

	draw_texture(
		building_texture,
		Vector2.ZERO
	)

	draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2.ONE
	)

	_draw_road_warning()


func _draw_road_warning():
	if world == null:
		return

	if not world.has_method("_building_has_road_access"):
		return

	if world._building_has_road_access(
		building_id,
		grid_pos
	):
		return

	var marker_position = Vector2(0.0, -48.0)

	draw_circle(
		marker_position,
		11.0,
		Color(0.9, 0.12, 0.12, 1.0)
	)

	draw_line(
		marker_position + Vector2(0.0, -5.0),
		marker_position + Vector2(0.0, 2.0),
		Color(1.0, 1.0, 1.0, 1.0),
		2.5,
		true
	)

	draw_circle(
		marker_position + Vector2(0.0, 6.0),
		1.5,
		Color(1.0, 1.0, 1.0, 1.0)
	)


func refresh_road_warning():
	update()


func refresh_visual():
	_initialize_systems()
	_load_sprite_settings()
	_load_building_texture()
	_calculate_visible_bounds()
	_update_building_position()

	modulate = Color(
		1.0,
		1.0,
		1.0,
		clamp(visual_alpha, 0.0, 1.0)
	)

	update()
