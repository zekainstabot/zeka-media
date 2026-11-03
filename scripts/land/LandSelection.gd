extends Reference

# ZekaCity - LandSelection
# Godot 3.6
# Selects isometric land tiles using the shared IsometricGrid.

const ISOMETRIC_GRID_SCRIPT = preload(
	"res://scripts/rendering/IsometricGrid.gd"
)

var isometric_grid = ISOMETRIC_GRID_SCRIPT.new(64.0, 32.0)


func set_grid(grid):
	if grid != null:
		isometric_grid = grid


func get_selected_tile(
	mouse_pos,
	center,
	grid_size,
	tile_width = 64,
	tile_height = 32
):
	isometric_grid.tile_width = float(tile_width)
	isometric_grid.tile_height = float(tile_height)

	return isometric_grid.get_tile_at_screen(
		mouse_pos,
		center,
		grid_size
	)


func get_tile_center(grid_pos, center):
	return isometric_grid.grid_to_screen(
		grid_pos,
		center
	)


func is_inside_tile(mouse_pos, grid_pos, center):
	var tile_center = get_tile_center(
		grid_pos,
		center
	)

	return isometric_grid.is_point_inside_tile(
		mouse_pos,
		tile_center
	)
