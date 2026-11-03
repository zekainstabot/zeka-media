extends Reference

# ZekaCity - BuildingSpriteCatalog
# Godot 3.6
# Central catalog for building sprite resources and rendering settings.

const DEFAULT_SCALE_MULTIPLIER = 1.2
const DEFAULT_ANCHOR = Vector2(0.5, 1.0)

var building_sprites = {
	# Residential
	"small_house": "res://BuildingImages/small_house.png",
	"normal_house": "res://BuildingImages/normal_house.png",
	"low_apartment": "res://BuildingImages/low_apartment.png",
	"high_apartment": "res://BuildingImages/high_apartment.png",
	"residential_tower": "res://BuildingImages/residential_tower.png",

	# Commercial
	"grocery_store": "res://BuildingImages/grocery_store.png",
	"bakery": "res://BuildingImages/bakery.png",
	"restaurant": "res://BuildingImages/restaurant.png",
	"office": "res://BuildingImages/office.png",
	"shopping_mall": "res://BuildingImages/shopping_mall.png",
	"factory": "res://BuildingImages/factory.png",
	"mineral_market": "res://BuildingImages/mineral_market.png",

	# Municipal
	"water_tower": "res://BuildingImages/water_tower.png",
	"power_station": "res://BuildingImages/power_station.png",
	"sewage_plant": "res://BuildingImages/sewage_plant.png",
	"waste_facility": "res://BuildingImages/waste_facility.png",

	# Services
	"school": "res://BuildingImages/school.png",
	"university": "res://BuildingImages/university.png",
	"clinic": "res://BuildingImages/clinic.png",
	"hospital": "res://BuildingImages/hospital.png",
	"police_station": "res://BuildingImages/police_station.png",
	"fire_station": "res://BuildingImages/fire_station.png",
	"city_hall": "res://BuildingImages/city_hall.png",

	# Storage
	"small_warehouse": "res://BuildingImages/small_warehouse.png",
	"medium_warehouse": "res://BuildingImages/medium_warehouse.png",
	"large_warehouse": "res://BuildingImages/large_warehouse.png",
	"huge_warehouse": "res://BuildingImages/huge_warehouse.png",

	# Recreation
	"small_park": "res://BuildingImages/small_park.png",
	"playground": "res://BuildingImages/playground.png",
	"sports_center": "res://BuildingImages/sports_center.png",
	"cultural_center": "res://BuildingImages/cultural_center.png"
}

# Optional per-building visual scale adjustments.
# Buildings not listed here use the default multiplier.
var scale_multipliers = {}

# Optional normalized anchor positions.
# (0.5, 1.0) means bottom-center of the image.
var anchor_points = {}


func has_building(building_id):
	return building_sprites.has(str(building_id))


func get_texture_path(building_id):
	return building_sprites.get(
		str(building_id),
		""
	)


func get_scale_multiplier(building_id):
	return float(
		scale_multipliers.get(
			str(building_id),
			DEFAULT_SCALE_MULTIPLIER
		)
	)


func get_anchor(building_id):
	return anchor_points.get(
		str(building_id),
		DEFAULT_ANCHOR
	)


func set_texture_path(building_id, path):
	building_id = str(building_id)

	if building_id == "" or path == "":
		return false

	building_sprites[building_id] = path
	return true


func set_scale_multiplier(building_id, multiplier):
	building_id = str(building_id)

	if building_id == "" or multiplier <= 0.0:
		return false

	scale_multipliers[building_id] = float(multiplier)
	return true


func set_anchor(building_id, anchor):
	building_id = str(building_id)

	if building_id == "":
		return false

	if anchor.x < 0.0 or anchor.x > 1.0:
		return false

	if anchor.y < 0.0 or anchor.y > 1.0:
		return false

	anchor_points[building_id] = anchor
	return true


func remove_building(building_id):
	building_id = str(building_id)

	building_sprites.erase(building_id)
	scale_multipliers.erase(building_id)
	anchor_points.erase(building_id)
