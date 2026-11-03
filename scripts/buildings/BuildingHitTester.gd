extends Reference

# ZekaCity - BuildingHitTester
# Godot 3.6
# Uses the shared isometric coordinate system.

const ISOMETRIC_GRID_SCRIPT = preload(
	"res://scripts/rendering/IsometricGrid.gd"
)

var isometric_grid = null


func _init():
	isometric_grid = ISOMETRIC_GRID_SCRIPT.new(64.0, 32.0)


func set_grid(grid):
	if grid != null:
		isometric_grid = grid


func find_building_at_position(
	mouse_pos,
	placed_buildings,
	building_footprints,
	tile_width,
	tile_height,
	center
):
	if building_footprints == null:
		return -1

	if isometric_grid == null:
		isometric_grid = ISOMETRIC_GRID_SCRIPT.new(
			tile_width,
			tile_height
		)

	isometric_grid.tile_width = float(tile_width)
	isometric_grid.tile_height = float(tile_height)

	var found_index = -1
	var found_depth = -INF

	for i in range(placed_buildings.size()):
		var building = placed_buildings[i]

		if typeof(building) != TYPE_DICTIONARY:
			continue

		if not building.has("id"):
			continue

		if not building.has("grid"):
			continue

		var building_id = str(building["id"])
		var grid_pos = building["grid"]

		var footprint = building_footprints.get_footprint(
			building_id
		)

		var visual_grid_pos = isometric_grid.get_footprint_center(
			grid_pos,
			footprint
		)

		# Center of the building's ground footprint.
		var building_pos = isometric_grid.grid_to_screen(
			visual_grid_pos,
			center
		)

		var ground_width = (
			footprint.x + footprint.y
		) * isometric_grid.tile_width * 0.5

		var ground_height = (
			footprint.x + footprint.y
		) * isometric_grid.tile_height * 0.5

		var building_height = max(
			90.0,
			ground_height + 70.0
		)

		var half_width = max(
			ground_width * 0.5,
			isometric_grid.tile_width * 0.5
		)

		var hit_polygon = PoolVector2Array([
			building_pos + Vector2(
				0,
				-building_height
			),

			building_pos + Vector2(
				half_width * 0.65,
				-building_height * 0.75
			),

			building_pos + Vector2(
				half_width,
				-ground_height * 0.5
			),

			building_pos + Vector2(
				half_width,
				ground_height * 0.5
			),

			building_pos + Vector2(
				0,
				ground_height
			),

			building_pos + Vector2(
				-half_width,
				ground_height * 0.5
			),

			building_pos + Vector2(
				-half_width,
				-ground_height * 0.5
			),

			building_pos + Vector2(
				-half_width * 0.65,
				-building_height * 0.75
			)
		])

		if Geometry.is_point_in_polygon(
			mouse_pos,
			hit_polygon
		):
			var depth = (
				visual_grid_pos.x + visual_grid_pos.y
			)

			# Select the visually frontmost building.
			if depth >= found_depth:
				found_depth = depth
				found_index = i

	return found_index
