extends Node2D

# ZekaCity - BuildingVisual
# Godot 3.6
# Shared isometric positioning and bottom-center sprite anchoring.

const ISOMETRIC_GRID_SCRIPT = preload(
	"res://scripts/rendering/IsometricGrid.gd"
)

const BUILDING_SCALE_MULTIPLIER = 1.2

var world = null
var building_id = ""
var grid_pos = Vector2.ZERO

var building_index = -1
var visual_alpha = 1.0

var building_texture = null
var drawer = null

var isometric_grid = null

var has_visible_bounds = false
var visible_bounds = Rect2()


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

	_initialize_grid()
	_load_building_texture()
	_calculate_visible_bounds()
	_update_building_position()

	modulate = Color(1, 1, 1, visual_alpha)

	update()


func _initialize_grid():
	if world != null and world.isometric_grid != null:
		isometric_grid = world.isometric_grid
	else:
		isometric_grid = ISOMETRIC_GRID_SCRIPT.new(
			64.0,
			32.0
		)


func _load_building_texture():
	building_texture = null
	has_visible_bounds = false
	visible_bounds = Rect2()

	var texture_path = _get_texture_path()

	if texture_path == "":
		push_warning(
			"No texture path configured for building: "
			+ building_id
		)
		return

	if not ResourceLoader.exists(texture_path):
		push_warning(
			"Building texture not found: "
			+ texture_path
		)
		return

	building_texture = load(texture_path)

	if building_texture == null:
		push_warning(
			"Could not load building texture: "
			+ texture_path
		)


func _get_texture_path():
	var texture_paths = {
		"small_house": "res://BuildingImages/small_house.png",
		"normal_house": "res://BuildingImages/normal_house.png",
		"low_apartment": "res://BuildingImages/low_apartment.png",
		"high_apartment": "res://BuildingImages/high_apartment.png",
		"residential_tower": "res://BuildingImages/residential_tower.png",

		"grocery_store": "res://BuildingImages/grocery_store.png",
		"bakery": "res://BuildingImages/bakery.png",
		"restaurant": "res://BuildingImages/restaurant.png",
		"office": "res://BuildingImages/office.png",
		"shopping_mall": "res://BuildingImages/shopping_mall.png",
		"factory": "res://BuildingImages/factory.png",
		"mineral_market": "res://BuildingImages/mineral_market.png",

		"water_tower": "res://BuildingImages/water_tower.png",
		"power_station": "res://BuildingImages/power_station.png",
		"sewage_plant": "res://BuildingImages/sewage_plant.png",
		"waste_facility": "res://BuildingImages/waste_facility.png",

		"school": "res://BuildingImages/school.png",
		"university": "res://BuildingImages/university.png",
		"clinic": "res://BuildingImages/clinic.png",
		"hospital": "res://BuildingImages/hospital.png",

		"police_station": "res://BuildingImages/police_station.png",
		"fire_station": "res://BuildingImages/fire_station.png",
		"city_hall": "res://BuildingImages/city_hall.png",

		"small_warehouse": "res://BuildingImages/small_warehouse.png",
		"medium_warehouse": "res://BuildingImages/medium_warehouse.png",
		"large_warehouse": "res://BuildingImages/large_warehouse.png",
		"huge_warehouse": "res://BuildingImages/huge_warehouse.png",

		"small_park": "res://BuildingImages/small_park.png",
		"playground": "res://BuildingImages/playground.png",
		"sports_center": "res://BuildingImages/sports_center.png",
		"cultural_center": "res://BuildingImages/cultural_center.png"
	}

	return texture_paths.get(building_id, "")


func _calculate_visible_bounds():
	has_visible_bounds = false
	visible_bounds = Rect2()

	if building_texture == null:
		return

	var image = building_texture.get_data()

	if image == null:
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


func _update_building_position():
	if world == null:
		return

	var footprint = _get_footprint()

	var map_origin = Vector2(600, 130)

	if world.has_method("get_map_origin"):
		map_origin = world.get_map_origin()

	var ground_position = isometric_grid.get_footprint_ground_position(
		grid_pos,
		footprint,
		map_origin
	)

	position = ground_position

	var depth_grid = grid_pos + Vector2(
		footprint.x - 1.0,
		footprint.y - 1.0
	)

	z_index = int(round(
		depth_grid.x + depth_grid.y
	))


func _get_footprint():
	if world != null and world.building_footprints != null:
		return world.building_footprints.get_footprint(
			building_id
		)

	return Vector2.ONE


func _get_target_size():
	var footprint = _get_footprint()

	var tile_w = 64.0
	var tile_h = 32.0

	if isometric_grid != null:
		tile_w = isometric_grid.tile_width
		tile_h = isometric_grid.tile_height

	return Vector2(
		max(
			tile_w,
			(footprint.x + footprint.y) * tile_w * 0.5
		),
		max(
			tile_h * 2.0,
			(footprint.x + footprint.y) * tile_h * 1.5
		)
	)


func _draw():
	if building_texture == null:
		if drawer != null:
			drawer.draw_building(
				self,
				building_id,
				Vector2.ZERO
			)
		return

	var texture_size = building_texture.get_size()

	if texture_size.x <= 0 or texture_size.y <= 0:
		return

	var target_size = _get_target_size()

	var scale_factor = min(
		target_size.x / texture_size.x,
		target_size.y / texture_size.y
	)

	scale_factor *= BUILDING_SCALE_MULTIPLIER

	var anchor_x = texture_size.x * 0.5
	var anchor_y = texture_size.y

	if has_visible_bounds:
		anchor_x = (
			visible_bounds.position.x
			+ visible_bounds.size.x * 0.5
		)

		anchor_y = visible_bounds.end.y

	var draw_position = Vector2(
		-anchor_x * scale_factor,
		-anchor_y * scale_factor
	)

	draw_set_transform(
		draw_position,
		0.0,
		Vector2(scale_factor, scale_factor)
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

	if not world._building_has_road_access(
		building_id,
		grid_pos
	):
		_draw_road_warning(target_size)


func _draw_road_warning(target_size):
	var marker_position = Vector2(
		0,
		-target_size.y * 0.75
	)

	draw_circle(
		marker_position,
		11.0,
		Color(0.9, 0.12, 0.12, 1)
	)

	draw_line(
		marker_position + Vector2(0, -5),
		marker_position + Vector2(0, 2),
		Color(1, 1, 1, 1),
		2.5,
		true
	)

	draw_circle(
		marker_position + Vector2(0, 6),
		1.5,
		Color(1, 1, 1, 1)
	)


func refresh_road_warning():
	update()
