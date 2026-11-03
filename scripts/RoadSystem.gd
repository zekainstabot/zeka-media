extends Node2D

# ZekaCity - RoadSystem
# Godot 3.6
# Uses the shared IsometricGrid for all road positioning.

const ISOMETRIC_GRID_SCRIPT = preload(
	"res://scripts/rendering/IsometricGrid.gd"
)

const ROAD_TEXTURE_PATH = "res://BuildingImages/road_straight.png"

const TILE_WIDTH = 64.0
const TILE_HEIGHT = 32.0

var isometric_grid = null

var map_center = Vector2(600, 130)

var roads = []
var road_texture = null

var road_texture_size = Vector2(64, 32)
var road_offset = Vector2.ZERO

var removal_highlight_enabled = false
var selected_road_for_removal = null


func _ready():
	_initialize_grid()
	_load_road_texture()
	_normalize_roads()
	update()


func _initialize_grid():
	if isometric_grid == null:
		isometric_grid = ISOMETRIC_GRID_SCRIPT.new(
			TILE_WIDTH,
			TILE_HEIGHT
		)


func set_grid(grid):
	if grid == null:
		return

	isometric_grid = grid
	update()


func set_map_origin(origin):
	map_center = origin
	update()


func get_map_origin():
	return map_center


func _load_road_texture():
	road_texture = null

	if not ResourceLoader.exists(ROAD_TEXTURE_PATH):
		push_error(
			"Road texture not found: "
			+ ROAD_TEXTURE_PATH
		)
		return

	road_texture = load(ROAD_TEXTURE_PATH)

	if road_texture == null:
		push_error(
			"Could not load road texture: "
			+ ROAD_TEXTURE_PATH
		)


func _normalize_roads():
	var unique_roads = []

	for road in roads:
		if typeof(road) != TYPE_DICTIONARY:
			continue

		if not road.has("grid"):
			continue

		var grid_pos = road["grid"]
		var already_exists = false

		for existing in unique_roads:
			if existing["grid"] == grid_pos:
				already_exists = true
				break

		if not already_exists:
			unique_roads.append({
				"grid": grid_pos
			})

	roads = unique_roads


func _draw():
	if road_texture == null:
		return

	for road in roads:
		var grid_pos = road.get(
			"grid",
			Vector2.ZERO
		)

		var center = _grid_to_screen(grid_pos)
		center += road_offset

		var tint = Color(1, 1, 1, 1)

		if removal_highlight_enabled:
			tint = Color(
				1.0,
				0.75,
				0.25,
				1.0
			)

		if _is_selected_road(grid_pos):
			tint = Color(
				1.0,
				0.2,
				0.2,
				1.0
			)

		var destination = Rect2(
			center - road_texture_size / 2.0,
			road_texture_size
		)

		draw_texture_rect(
			road_texture,
			destination,
			false,
			tint
		)


func _grid_to_screen(grid_pos):
	_initialize_grid()

	return isometric_grid.grid_to_screen(
		grid_pos,
		map_center
	)


func add_road(grid_pos, direction = 0):
	if has_road(grid_pos):
		return false

	roads.append({
		"grid": grid_pos
	})

	update()

	print("ROAD ADDED: ", grid_pos)

	return true


func remove_road_piece(grid_pos, direction = 0):
	return remove_road(grid_pos)


func remove_road(grid_pos):
	for i in range(roads.size() - 1, -1, -1):
		if roads[i].get("grid", Vector2.ZERO) == grid_pos:
			roads.remove(i)
			update()
			return true

	return false


func has_road(grid_pos):
	for road in roads:
		if road.get("grid", Vector2.ZERO) == grid_pos:
			return true

	return false


func has_road_direction(grid_pos, direction = 0):
	return has_road(grid_pos)


func set_removal_highlight(enabled):
	removal_highlight_enabled = enabled
	update()


func set_selected_road(road_data):
	selected_road_for_removal = road_data
	update()


func _is_selected_road(grid_pos):
	if selected_road_for_removal == null:
		return false

	return selected_road_for_removal.get(
		"grid",
		Vector2.ZERO
	) == grid_pos


func get_road_at_position(local_mouse_pos):
	var best_road = null
	var best_distance = INF

	for road in roads:
		var grid_pos = road.get(
			"grid",
			Vector2.ZERO
		)

		var center = _grid_to_screen(grid_pos)
		center += road_offset

		var hit_rect = Rect2(
			center - road_texture_size / 2.0,
			road_texture_size
		)

		if hit_rect.has_point(local_mouse_pos):
			var distance = local_mouse_pos.distance_squared_to(
				center
			)

			if distance < best_distance:
				best_distance = distance

				best_road = {
					"grid": grid_pos
				}

	return best_road


func set_road_width(value):
	road_texture_size.y = max(
		1.0,
		float(value)
	)

	update()


func set_road_size(width, height):
	road_texture_size = Vector2(
		max(1.0, float(width)),
		max(1.0, float(height))
	)

	update()


func set_horizontal_offset(x, y):
	road_offset = Vector2(
		float(x),
		float(y)
	)

	update()


func set_vertical_offset(x, y):
	road_offset = Vector2(
		float(x),
		float(y)
	)

	update()


func set_left_end_shift(value):
	pass


func set_deformation_columns(value):
	pass
