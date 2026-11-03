extends Reference

# ZekaCity - LandPurchase.gd
# Godot 3.6
# خرید زمین در محدوده‌های 2x2

const AREA_SIZE = 2


func purchase_land(
	grid_pos,
	city_center,
	land_system,
	city_treasury,
	road_system
):
	return purchase_area(
		grid_pos,
		city_center,
		land_system,
		city_treasury,
		road_system
	)


func purchase_area(
	grid_pos,
	city_center,
	land_system,
	city_treasury,
	road_system
):
	if land_system == null or city_treasury == null:
		return _failure("INVALID_SYSTEM")

	var origin = land_system.get_area_origin(grid_pos)

	# محدوده باید مجاور زمین‌های خریداری‌شده باشد.
	if not land_system.is_area_adjacent_to_owned(origin):
		return _failure("AREA_NOT_ADJACENT")

	var area_tiles = []
	var total_price = 0

	# محاسبهٔ تمام زمین‌های خریداری‌نشده در محدوده.
	for x in range(int(origin.x), int(origin.x) + AREA_SIZE):
		for y in range(int(origin.y), int(origin.y) + AREA_SIZE):
			var tile = Vector2(x, y)

			if not land_system.is_inside_map(tile):
				continue

			if land_system.is_owned(tile):
				continue

			if not land_system.can_buy(tile):
				continue

			var tile_price = land_system.get_land_price(
				tile,
				city_center,
				road_system
			)

			area_tiles.append({
				"grid": tile,
				"price": tile_price
			})

			total_price += tile_price

	if area_tiles.empty():
		return _failure("AREA_ALREADY_OWNED")

	# بررسی موجودی.
	if not city_treasury.can_afford(total_price):
		return {
			"success": false,
			"error": "NOT_ENOUGH_MONEY",
			"price": total_price,
			"balance": city_treasury.get_balance()
		}

	# پرداخت فقط پس از تکمیل اعتبارسنجی.
	if not city_treasury.spend(total_price):
		return {
			"success": false,
			"error": "PAYMENT_FAILED",
			"price": total_price,
			"balance": city_treasury.get_balance()
		}

	var bought_tiles = []

	for item in area_tiles:
		var tile = item["grid"]

		if land_system.buy_land(tile):
			bought_tiles.append(tile)
		else:
			# بازگرداندن زمین‌های خریداری‌شده در صورت بروز خطا.
			for bought_tile in bought_tiles:
				land_system.owned_tiles.erase(bought_tile)

			city_treasury.add_money(total_price)

			return {
				"success": false,
				"error": "LAND_PURCHASE_FAILED",
				"price": total_price,
				"balance": city_treasury.get_balance()
			}

	return {
		"success": true,
		"price": total_price,
		"tiles_bought": bought_tiles.size(),
		"tiles": bought_tiles,
		"balance": city_treasury.get_balance(),
		"area_origin": origin
	}


func _failure(error_code):
	return {
		"success": false,
		"error": error_code,
		"price": 0
	}
