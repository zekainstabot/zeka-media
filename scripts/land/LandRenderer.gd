
extends Reference

# ZekaCity - LandRenderer
# Godot 3.6
# All tile geometry is handled by IsometricGrid.

const GRID_SCRIPT = preload(
	"res://scripts/rendering/IsometricGrid.gd"
)

var isometric_grid = GRID_SCRIPT.new(64.0, 32.0)

var owned_color = Color(0.36, 0.56, 0.34)
var available_color = Color(0.68, 0.65, 0.43)

var owned_outline = Color(0.20, 0.35, 0.20)
var available_outline = Color(0.83, 0.75, 0.35)
var selected_outline = Color(1.0, 0.85, 0.1)


func set_grid(grid):
	if grid != null:
		isometric_grid = grid


func get_tile_width():
	return isometric_grid.tile_width


func get_tile_height():
	return isometric_grid.tile_height


func grid_to_screen(grid_pos, center):
	return isometric_grid.grid_to_screen(
		grid_pos,
		center
	)


func get_tile_polygon(pos):
	return isometric_grid.get_tile_polygon(pos)


func draw_tiles(
	canvas,
	land_system,
	grid_size,
	center,
	selected_x,
	selected_y
):
	for x in range(grid_size):
		for y in range(grid_size):

			var grid_pos = Vector2(x, y)

			var tile_center = isometric_grid.grid_to_screen(
				grid_pos,
				center
			)

			var polygon = isometric_grid.get_tile_polygon(
				tile_center
			)

			var fill_color = available_color
			var outline_color = available_outline

			if land_system.is_owned(grid_pos):
				fill_color = owned_color
				outline_color = owned_outline

			if x == selected_x and y == selected_y:
				outline_color = selected_outline

			canvas.draw_colored_polygon(
				polygon,
				fill_color
			)

			var outline = PoolVector2Array([
				polygon[0],
				polygon[1],
				polygon[2],
				polygon[3],
				polygon[0]
			])

			canvas.draw_polyline(
				outline,
				outline_color,
				1.0,
				true
			)
