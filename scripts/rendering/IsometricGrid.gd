
extends Reference

# ZekaCity - IsometricGrid
# Godot 3.6
# واحد مشترک مختصات برای تمام اجزای نقشه

var tile_width = 64.0
var tile_height = 32.0


func _init(p_tile_width = 64.0, p_tile_height = 32.0):
	tile_width = float(p_tile_width)
	tile_height = float(p_tile_height)


# تبدیل مختصات خانه به مختصات صفحه
func grid_to_screen(grid_pos, map_center):
	return map_center + Vector2(
		(grid_pos.x - grid_pos.y) * tile_width / 2.0,
		(grid_pos.x + grid_pos.y) * tile_height / 2.0
	)


# تبدیل مختصات صفحه به مختصات اعشاری شبکه
func screen_to_grid(screen_pos, map_center):
	var local_pos = screen_pos - map_center

	return Vector2(
		local_pos.x / tile_width + local_pos.y / tile_height,
		-local_pos.x / tile_width + local_pos.y / tile_height
	)


# ساخت لوزی زمین
func get_tile_polygon(tile_center):
	return PoolVector2Array([
		tile_center + Vector2(0, -tile_height / 2.0),
		tile_center + Vector2(tile_width / 2.0, 0),
		tile_center + Vector2(0, tile_height / 2.0),
		tile_center + Vector2(-tile_width / 2.0, 0)
	])


# بررسی قرار داشتن نقطه داخل لوزی
func is_point_inside_tile(point, tile_center):
	var local_pos = point - tile_center

	var distance = (
		abs(local_pos.x) / (tile_width / 2.0)
		+ abs(local_pos.y) / (tile_height / 2.0)
	)

	return distance <= 1.0


# پیدا کردن خانه‌ای که نقطه روی آن قرار گرفته است
func get_tile_at_screen(screen_pos, map_center, grid_size):
	var approximate = screen_to_grid(
		screen_pos,
		map_center
	)

	var base_x = int(round(approximate.x))
	var base_y = int(round(approximate.y))

	var best_tile = Vector2(-1, -1)
	var best_distance = INF

	# بررسی خانه‌های اطراف برای تشخیص دقیق مرز لوزی‌ها
	for x in range(base_x - 1, base_x + 2):
		for y in range(base_y - 1, base_y + 2):

			if x < 0 or y < 0:
				continue

			if x >= grid_size or y >= grid_size:
				continue

			var grid_pos = Vector2(x, y)

			var tile_center = grid_to_screen(
				grid_pos,
				map_center
			)

			if is_point_inside_tile(screen_pos, tile_center):
				var distance = screen_pos.distance_squared_to(
					tile_center
				)

				if distance < best_distance:
					best_distance = distance
					best_tile = grid_pos

	return best_tile


# مرکز هندسی یک محدوده چندخانه‌ای
func get_footprint_center(origin, footprint):
	return origin + Vector2(
		(footprint.x - 1.0) / 2.0,
		(footprint.y - 1.0) / 2.0
	)


# موقعیت نقطه اتصال ساختمان به زمین
func get_footprint_ground_position(origin, footprint, map_center):
	var center_grid = get_footprint_center(
		origin,
		footprint
	)

	return grid_to_screen(
		center_grid,
		map_center
	) + Vector2(
		0,
		(footprint.x + footprint.y) * tile_height / 4.0
	)
