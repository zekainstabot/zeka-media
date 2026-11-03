extends Reference

# ZekaCity - LandPurchaseController.gd
# Godot 3.6
# مدیریت درخواست، تأیید و اجرای خرید زمین

const AREA_SIZE = 2

var world = null
var pending_grid = Vector2(-1, -1)


func initialize(world_node):
	world = world_node
	pending_grid = Vector2(-1, -1)


func _get_road_system():
	if world == null:
		return null

	return world.get_node_or_null("../RoadSystem")


func _get_city_center():
	# مبدأ محاسبهٔ قیمت زمین در نسخهٔ فعلی.
	return Vector2.ZERO


func request_area_purchase(grid_pos):
	if world == null:
		return

	if world.land_system == null:
		return

	var origin = world.land_system.get_area_origin(grid_pos)

	if not world.land_system.is_area_adjacent_to_owned(origin):
		return

	var road_system = _get_road_system()

	if road_system == null:
		push_error("LandPurchaseController: RoadSystem not found")
		return

	var total_price = world.land_system.get_area_price(
		origin,
		_get_city_center(),
		road_system
	)

	if total_price <= 0:
		return

	var tiles_to_buy = _count_unowned_tiles(origin)

	if tiles_to_buy <= 0:
		return

	if not world.city_treasury.can_afford(total_price):
		print(
			"NOT ENOUGH MONEY. Price: $",
			total_price,
			" | Balance: $",
			world.city_treasury.get_balance()
		)
		return

	pending_grid = origin

	if world.world_ui_controller != null:
		world.world_ui_controller.show_land_purchase_dialog(
			tiles_to_buy,
			total_price,
			world.city_treasury.get_balance()
		)


func request_selected_land():
	if world == null:
		return

	request_area_purchase(
		Vector2(world.selected_x, world.selected_y)
	)


func confirm_land_purchase():
	if world == null:
		return

	if pending_grid.x < 0 or pending_grid.y < 0:
		return

	var road_system = _get_road_system()

	if road_system == null:
		push_error("LandPurchaseController: RoadSystem not found")
		return

	var origin = world.land_system.get_area_origin(pending_grid)

	# بررسی مجدد شرایط؛ ممکن است وضعیت زمین تغییر کرده باشد.
	if not world.land_system.is_area_adjacent_to_owned(origin):
		print("LAND PURCHASE FAILED: AREA_NOT_ADJACENT")
		pending_grid = Vector2(-1, -1)
		return

	var total_price = world.land_system.get_area_price(
		origin,
		_get_city_center(),
		road_system
	)

	if total_price <= 0:
		pending_grid = Vector2(-1, -1)
		return

	if not world.city_treasury.can_afford(total_price):
		print("LAND PURCHASE FAILED: NOT_ENOUGH_MONEY")
		pending_grid = Vector2(-1, -1)
		return

	var result = world.land_purchase.purchase_area(
		origin,
		_get_city_center(),
		world.land_system,
		world.city_treasury,
		road_system
	)

	pending_grid = Vector2(-1, -1)

	if not result.get("success", false):
		print(
			"LAND PURCHASE FAILED: ",
			result.get("error", "UNKNOWN_ERROR")
		)
		return

	print(
		"LAND PURCHASED. Tiles: ",
		result["tiles_bought"],
		" | Price: $",
		result["price"],
		" | Remaining: $",
		result["balance"]
	)

	_refresh_world()


func cancel_land_purchase():
	pending_grid = Vector2(-1, -1)


func _count_unowned_tiles(origin):
	var count = 0

	for x in range(int(origin.x), int(origin.x) + AREA_SIZE):
		for y in range(int(origin.y), int(origin.y) + AREA_SIZE):
			var tile = Vector2(x, y)

			if not world.land_system.is_inside_map(tile):
				continue

			if not world.land_system.is_owned(tile):
				count += 1

	return count


func _refresh_world():
	if world == null:
		return

	if world.world_ui_controller != null:
		world.world_ui_controller.update_treasury_label()
		world.world_ui_controller.update_land_purchase_areas()

	world.update()

	if world.save_system != null:
		world.save_system.save_world(world)
