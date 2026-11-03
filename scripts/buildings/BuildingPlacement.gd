extends Reference

# ZekaCity - BuildingPlacement
# Godot 3.6
# Validates building placement using ground footprints.
# Road access is not required for placement.
# Roads occupying the footprint block construction.


func can_place_building(
	building_id,
	origin,
	grid_size,
	placed_buildings,
	footprints,
	land_system,
	road_system
):
	return get_placement_error(
		building_id,
		origin,
		grid_size,
		placed_buildings,
		footprints,
		land_system,
		road_system
	) == "OK"


func get_placement_error(
	building_id,
	origin,
	grid_size,
	placed_buildings,
	footprints,
	land_system,
	road_system
):
	if footprints == null:
		return "FOOTPRINT_SYSTEM_MISSING"

	if land_system == null:
		return "LAND_SYSTEM_MISSING"

	if not footprints.fits_inside_map(
		building_id,
		origin,
		grid_size
	):
		return "OUTSIDE_MAP"

	var new_tiles = footprints.get_occupied_tiles(
		building_id,
		origin
	)

	if new_tiles.empty():
		return "INVALID_FOOTPRINT"

	# Check every tile occupied by the new building.
	for tile in new_tiles:

		# Every occupied tile must belong to the player.
		if not land_system.is_owned(tile):
			return "LAND_NOT_OWNED"

		# A road cannot occupy a building's ground footprint.
		if road_system != null:
			if road_system.has_road(tile):
				return "ROAD_OCCUPIED"

		# Check overlap with existing buildings.
		for building in placed_buildings:

			if typeof(building) != TYPE_DICTIONARY:
				continue

			if not building.has("id"):
				continue

			if not building.has("grid"):
				continue

			var existing_tiles = footprints.get_occupied_tiles(
				str(building["id"]),
				building["grid"]
			)

			if existing_tiles.has(tile):
				return "BUILDING_OCCUPIED"

	return "OK"
