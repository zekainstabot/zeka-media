extends Reference

# ZekaCity - BuildingFootprints
# Godot 3.6
# Controls occupied ground tiles independently from sprite dimensions.

var footprints = {
	# Residential
	"small_house": Vector2(1, 1),
	"normal_house": Vector2(2, 2),
	"low_apartment": Vector2(2, 2),
	"high_apartment": Vector2(3, 2),
	"residential_tower": Vector2(3, 3),

	# Commercial
	"grocery_store": Vector2(2, 2),
	"bakery": Vector2(2, 2),
	"restaurant": Vector2(2, 2),
	"office": Vector2(2, 2),
	"shopping_mall": Vector2(4, 3),
	"factory": Vector2(3, 3),
	"mineral_market": Vector2(2, 2),

	# Municipal
	"water_tower": Vector2(2, 2),
	"power_station": Vector2(3, 3),
	"sewage_plant": Vector2(3, 3),
	"waste_facility": Vector2(3, 3),

	# Services
	"school": Vector2(3, 2),
	"university": Vector2(4, 3),
	"clinic": Vector2(2, 2),
	"hospital": Vector2(3, 3),
	"police_station": Vector2(2, 2),
	"fire_station": Vector2(2, 2),
	"city_hall": Vector2(3, 3),

	# Storage
	"small_warehouse": Vector2(2, 2),
	"medium_warehouse": Vector2(3, 2),
	"large_warehouse": Vector2(3, 3),
	"huge_warehouse": Vector2(4, 3),

	# Recreation
	"small_park": Vector2(2, 2),
	"playground": Vector2(2, 2),
	"sports_center": Vector2(3, 3),
	"cultural_center": Vector2(3, 2)
}


# Return the ground footprint of a building.
func get_footprint(building_id):
	return footprints.get(
		str(building_id),
		Vector2(1, 1)
	)


# Change a footprint when necessary.
func set_footprint(building_id, size):
	if str(building_id) == "":
		return false

	if size.x < 1 or size.y < 1:
		return false

	if size.x != int(size.x) or size.y != int(size.y):
		return false

	footprints[str(building_id)] = Vector2(
		int(size.x),
		int(size.y)
	)

	return true


# Return every grid tile occupied by a building.
func get_occupied_tiles(building_id, origin):
	var size = get_footprint(building_id)
	var tiles = []

	for x in range(int(size.x)):
		for y in range(int(size.y)):
			tiles.append(
				origin + Vector2(x, y)
			)

	return tiles


# Return the number of occupied tiles.
func get_tile_count(building_id):
	var size = get_footprint(building_id)

	return int(size.x) * int(size.y)


# Return the center of the footprint in grid coordinates.
func get_footprint_center(building_id, origin):
	var size = get_footprint(building_id)

	return origin + Vector2(
		(size.x - 1.0) * 0.5,
		(size.y - 1.0) * 0.5
	)


# Check whether a building footprint fits inside the map.
func fits_inside_map(building_id, origin, grid_size):
	var size = get_footprint(building_id)

	if origin.x < 0 or origin.y < 0:
		return false

	if origin.x != int(origin.x):
		return false

	if origin.y != int(origin.y):
		return false

	if size.x < 1 or size.y < 1:
		return false

	if origin.x + size.x > grid_size:
		return false

	if origin.y + size.y > grid_size:
		return false

	return true


# Check whether every occupied tile belongs to the player.
func is_fully_owned(building_id, origin, land_system):
	if land_system == null:
		return false

	for tile in get_occupied_tiles(building_id, origin):
		if not land_system.is_owned(tile):
			return false

	return true


# Check whether any occupied tile is already used.
func overlaps_buildings(building_id, origin, placed_buildings):
	var occupied = get_occupied_tiles(
		building_id,
		origin
	)

	for building in placed_buildings:
		if not building.has("id"):
			continue

		if not building.has("grid"):
			continue

		var other_tiles = get_occupied_tiles(
			building["id"],
			building["grid"]
		)

		for tile in occupied:
			if other_tiles.has(tile):
				return true

	return false
