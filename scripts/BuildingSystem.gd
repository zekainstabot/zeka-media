extends Node2D

# ZekaCity - BuildingSystem
# Godot 3.6
# Central building data and shared isometric positioning.

const ISOMETRIC_GRID_SCRIPT = preload(
	"res://scripts/rendering/IsometricGrid.gd"
)

const BUILDING_FOOTPRINTS_SCRIPT = preload(
	"res://scripts/buildings/BuildingFootprints.gd"
)

const TILE_WIDTH = 64.0
const TILE_HEIGHT = 32.0

var isometric_grid = null
var building_footprints = null

var tile_width = TILE_WIDTH
var tile_height = TILE_HEIGHT

var map_center = Vector2(600, 130)

var placed_buildings = []


func _ready():
	_initialize_systems()


func _initialize_systems():
	if isometric_grid == null:
		isometric_grid = ISOMETRIC_GRID_SCRIPT.new(
			tile_width,
			tile_height
		)

	if building_footprints == null:
		building_footprints = BUILDING_FOOTPRINTS_SCRIPT.new()


# Connect the shared coordinate system.
func set_grid(grid):
	if grid == null:
		return

	isometric_grid = grid

	tile_width = isometric_grid.tile_width
	tile_height = isometric_grid.tile_height

	update()


# Connect the shared footprint configuration.
func set_footprints(footprints):
	if footprints == null:
		return

	building_footprints = footprints
	update()


# Set the common map origin.
func set_map_origin(origin):
	map_center = origin
	update()


func get_map_origin():
	return map_center


# Receive building data from World.
func set_buildings(buildings):
	placed_buildings = buildings.duplicate(true)
	update()


# Return a copy of the current building data.
func get_buildings():
	return placed_buildings.duplicate(true)


# Convert grid coordinates to screen coordinates.
func grid_to_screen(grid_pos):
	_initialize_systems()

	return isometric_grid.grid_to_screen(
		grid_pos,
		map_center
	)


# Get the screen position of a building's ground footprint center.
func get_building_ground_position(building):
	if typeof(building) != TYPE_DICTIONARY:
		return Vector2.ZERO

	if not building.has("id") or not building.has("grid"):
		return Vector2.ZERO

	_initialize_systems()

	var footprint = building_footprints.get_footprint(
		str(building["id"])
	)

	return isometric_grid.get_footprint_ground_position(
		building["grid"],
		footprint,
		map_center
	)


# Check whether a grid tile is occupied by any building.
func is_tile_occupied(grid_pos):
	_initialize_systems()

	for building in placed_buildings:
		if typeof(building) != TYPE_DICTIONARY:
			continue

		if not building.has("id") or not building.has("grid"):
			continue

		var occupied_tiles = building_footprints.get_occupied_tiles(
			str(building["id"]),
			building["grid"]
		)

		if occupied_tiles.has(grid_pos):
			return true

	return false


# Check whether a small park exists at the given origin tile.
func has_park_at(grid_pos):
	for building in placed_buildings:
		if typeof(building) != TYPE_DICTIONARY:
			continue

		if not building.has("id") or not building.has("grid"):
			continue

		if str(building["id"]) == "small_park":
			if building["grid"] == grid_pos:
				return true

	return false


# Check whether a building with a specific ID exists at an origin tile.
func has_building_at(building_id, grid_pos):
	for building in placed_buildings:
		if typeof(building) != TYPE_DICTIONARY:
			continue

		if not building.has("id") or not building.has("grid"):
			continue

		if str(building["id"]) == str(building_id):
			if building["grid"] == grid_pos:
				return true

	return false


# Return the building occupying a tile, or an empty dictionary.
func get_building_at(grid_pos):
	_initialize_systems()

	for building in placed_buildings:
		if typeof(building) != TYPE_DICTIONARY:
			continue

		if not building.has("id") or not building.has("grid"):
			continue

		var occupied_tiles = building_footprints.get_occupied_tiles(
			str(building["id"]),
			building["grid"]
		)

		if occupied_tiles.has(grid_pos):
			return building.duplicate(true)

	return {}
