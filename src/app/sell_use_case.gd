class_name SellUseCase
extends RefCounted

## O3 · 卖一瓶药（契约 02 §3）。
## 覆盖率 < normal_threshold → 价格为 0、拒卖；成交后扣成品、加金币、当日 Q +1。

var _db: ContentDatabase
var _economy: Economy
var _inventory: Inventory
var _wallet: Wallet
var _clock: GameClock
var _publisher: CraftEventPublisher
var _rolling_q: int = 0
var _last_day: int = -1


func _init(
	db: ContentDatabase,
	economy: Economy,
	inventory: Inventory,
	wallet: Wallet,
	clock: GameClock,
	publisher: CraftEventPublisher = null
) -> void:
	_db = db
	_economy = economy
	_inventory = inventory
	_wallet = wallet
	_clock = clock
	_publisher = publisher
	_last_day = clock.today()


func quote(product_index: int) -> Dictionary:
	_roll_day()
	var product := _inventory.product_at(product_index)
	if product == null:
		return {
			"coverage": 0.0,
			"price": 0,
			"demand_name": "",
			"can_sell": false,
			"reason": "invalid_index",
		}
	var demand := _demand()
	var match_ratio := Economy.coverage(product.result.reading, demand)
	var price := _economy.list_price(product, demand, _ctx())
	return {
		"coverage": match_ratio,
		"price": price,
		"demand_name": str(demand.get("name", "")),
		"can_sell": price > 0,
		"reason": "ok" if price > 0 else "no_demand",
	}


func sell(product_index: int) -> Dictionary:
	var quote_result := quote(product_index)
	var match_ratio := float(quote_result["coverage"])
	if int(quote_result["price"]) <= 0:
		return {
			"sold": false,
			"price": 0,
			"coverage": match_ratio,
			"reason": str(quote_result["reason"]),
		}
	var product := _inventory.remove_product(product_index)
	if product == null:
		return {
			"sold": false,
			"price": 0,
			"coverage": match_ratio,
			"reason": "invalid_index",
		}
	var price := int(quote_result["price"])
	_wallet.add_gold(price)
	_rolling_q += 1
	_publish_state()
	return {
		"sold": true,
		"price": price,
		"coverage": match_ratio,
		"reason": "ok",
	}


func _roll_day() -> void:
	var today := _clock.today()
	if today != _last_day:
		_rolling_q = 0
		_last_day = today


func _demand() -> Dictionary:
	return _db.constant("demand.spring_early")


func _ctx() -> Dictionary:
	return {
		"season": _clock.season,
		"reputation": "mid",
		"rolling_q": _rolling_q,
		"q_th": int(_db.constant("pricing.q_th_base")),
	}


func _publish_state() -> void:
	if _publisher == null:
		return
	_publisher.publish_inventory(_inventory)
	_publisher.publish_money(_wallet)
