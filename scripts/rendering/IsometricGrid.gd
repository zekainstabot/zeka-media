
extends Reference

# ZekaCity - IsometricGrid
# Godot 3.6
# Single source of truth for isometric coordinates.

const DEFAULT_TILE_WIDTH = 64.0
const DEFAULT_TILE_HEIGHT = 32.0

var tile_width = DEFAULT_TILE_WIDTH
var tile_height = DEFAULT_TILE_HEIGHT


func _init(p_tile_width = DEFAULT_TILE_WIDTH, p_tile_height = DEFAULT_TILE_HEIGHT):
	tile_width = float(p_tile_width)
	tile_height = float(p_tile_height)


# Grid coordinates -> local screen coordinates.
func grid_to_screen(grid_pos, map_origin):
	return map_origin + Vector2(
		(grid_pos.x - grid_pos.y) * tile_width * 0.5,
		(grid_pos.x + grid_pos.y) * tile_height * 0.5
	)


# Local screen coordinates -> fractional grid coordinates.
func screen_to_grid(screen_pos, map_origin):
	var local_pos = screen_pos - map_origin

	return Vector2(
		local_pos.x / tile_width + local_pos.y / tile_height,
		-local_pos.x / tile_width + local_pos.y / tile_height
	)


# Center of a single ground tile.
func get_tile_center(grid_pos, map_origin):
	return grid_to_screen(grid_pos, map_origin)


# Four corners of a ground diamond.
func get_tile_polygon(tile_center):
	return PoolVector2Array([
		tile_center + Vector2(0, -tile_height * 0.5),
		tile_center + Vector2(tile_width * 0.5, 0),
		tile_center + Vector2(0, tile_height * 0.5),
		tile_center + Vector2(-tile_width * 0.5, 0)
	])


# Check whether a point belongs to a diamond.
func is_point_inside_tile(point, tile_center):
	var local_pos = point - tile_center

	var distance = (
		abs(local_pos.x) / (tile_width * 0.5)
		+ abs(local_pos.y) / (tile_height * 0.5)
	)

	return distance <= 1.0


# Center of all tile centers occupied by a rectangular footprint.
func get_footprint_center(origin, footprint):
	return origin + Vector2(
		(footprint.x - 1.0) * 0.5,
		(footprint.y - 1.0) * 0.5
	)


# Ground anchor for a multi-tile building.
# No extra vertical offset is applied.
func get_footprint_ground_position(origin, footprint, map_origin):
	var center_grid = get_footprint_center(
		origin,
		footprint
	)

	return grid_to_screen(center_grid, map_origin)


# Find the exact tile under a screen position.
func get_tile_at_screen(screen_pos, map_origin, grid_size):
	var approximate = screen_to_grid(
		screen_pos,
		map_origin
	)

	var base_x = int(round(approximate.x))
	var base_y = int(round(approximate.y))

	var best_tile = Vector2(-1, -1)
	var best_distance = INF

	for x in range(base_x - 1, base_x + 2):
		for y in range(base_y - 1, base_y + 2):

			if x < 0 or y < 0:
				continue

			if x >= grid_size or y >= grid_size:
				continue

			var grid_pos = Vector2(x, y)

			var center = grid_to_screen(
				grid_pos,
				map_origin
			)

			if is_point_inside_tile(screen_pos, center):
				var distance = screen_pos.distance_squared_to(
					center
				)

				if distance < best_distance:
					best_distance = distance
					best_tile = grid_pos

	return best_tile
