extends Reference

# ZekaCity V1 - LandSystem
# Godot 3.6
# مدیریت مالکیت زمین و محدوده‌های خرید 2x2

const LAND_PRICING_SCRIPT = preload(
	"res://scripts/land/LandPricing.gd"
)

var grid_size = 25
var owned_tiles = []

var starting_owned_tiles = [
	Vector2(0, 0),
	Vector2(0, 1),
	Vector2(1, 0),
	Vector2(1, 1)
]

var pricing = null


func _init():
	pricing = LAND_PRICING_SCRIPT.new()


func initialize(size):
	grid_size = max(1, int(size))
	owned_tiles.clear()

	for tile in starting_owned_tiles:
		if _is_inside_map(tile):
			owned_tiles.append(tile)


func is_inside_map(grid_pos):
	return _is_inside_map(grid_pos)


func is_owned(grid_pos):
	return owned_tiles.has(grid_pos)


func can_buy(grid_pos):
	return (
		_is_inside_map(grid_pos)
		and not is_owned(grid_pos)
	)


func buy_land(grid_pos):
	if not can_buy(grid_pos):
		return false

	owned_tiles.append(grid_pos)
	return true


func get_land_price(grid_pos, city_center, road_system):
	if pricing == null:
		pricing = LAND_PRICING_SCRIPT.new()

	return pricing.get_land_price(
		grid_pos,
		city_center,
		road_system
	)


# شروع محدوده خرید 2x2
func get_area_origin(grid_pos):
	return Vector2(
		int(floor(grid_pos.x / 2.0)) * 2,
		int(floor(grid_pos.y / 2.0)) * 2
	)


# آیا محدوده 2x2 زمین خریداری‌نشده دارد؟
func area_has_unowned_tiles(grid_pos):
	var origin = get_area_origin(grid_pos)

	for x in range(int(origin.x), int(origin.x) + 2):
		for y in range(int(origin.y), int(origin.y) + 2):
			var tile = Vector2(x, y)

			if _is_inside_map(tile) and not is_owned(tile):
				return true

	return false


# آیا محدوده مستقیماً به زمین مالکیت‌شده متصل است؟
func is_area_adjacent_to_owned(grid_pos):
	var origin = get_area_origin(grid_pos)

	if not area_has_unowned_tiles(origin):
		return false

	var directions = [
		Vector2(1, 0),
		Vector2(-1, 0),
		Vector2(0, 1),
		Vector2(0, -1)
	]

	for x in range(int(origin.x), int(origin.x) + 2):
		for y in range(int(origin.y), int(origin.y) + 2):
			var tile = Vector2(x, y)

			if not _is_inside_map(tile):
				continue

			for direction in directions:
				var neighbor = tile + direction

				if not _is_inside_map(neighbor):
					continue

				if get_area_origin(neighbor) == origin:
					continue

				if is_owned(neighbor):
					return true

	return false


# محاسبه مجموع قیمت زمین‌های خریداری‌نشده در محدوده
func get_area_price(grid_pos, city_center, road_system):
	var origin = get_area_origin(grid_pos)
	var total_price = 0

	for x in range(int(origin.x), int(origin.x) + 2):
		for y in range(int(origin.y), int(origin.y) + 2):
			var tile = Vector2(x, y)

			if not _is_inside_map(tile):
				continue

			if not is_owned(tile):
				total_price += get_land_price(
					tile,
					city_center,
					road_system
				)

	return total_price


# فهرست محدوده‌های قابل خرید
func get_adjacent_purchase_areas():
	var areas = []

	for x in range(0, grid_size, 2):
		for y in range(0, grid_size, 2):
			var origin = Vector2(x, y)

			if area_has_unowned_tiles(origin):
				if is_area_adjacent_to_owned(origin):
					areas.append(origin)

	return areas


func get_all_tiles():
	var tiles = []

	for x in range(grid_size):
		for y in range(grid_size):
			tiles.append(Vector2(x, y))

	return tiles


func _is_inside_map(grid_pos):
	return (
		grid_pos.x >= 0
		and grid_pos.y >= 0
		and grid_pos.x < grid_size
		and grid_pos.y < grid_size
	)
