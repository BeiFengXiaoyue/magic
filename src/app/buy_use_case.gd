class_name BuyUseCase
extends RefCounted

## 商队器材（契约 05 §12 的最小实现）：到访日出售、扣金币、记入 DeviceState。
## 商队本体/场景不做；到访日由 caravan 常量决定。

var _db: ContentDatabase
var _clock: GameClock
var _wallet: Wallet
var _devices: DeviceState
var _publisher: CraftEventPublisher


func _init(
	db: ContentDatabase,
	clock: GameClock,
	wallet: Wallet,
	devices: DeviceState,
	publisher: CraftEventPublisher = null
) -> void:
	_db = db
	_clock = clock
	_wallet = wallet
	_devices = devices
	_publisher = publisher


func is_caravan_day() -> bool:
	var caravan: Variant = _db.constant("caravan")
	if not caravan is Dictionary:
		return false
	var every := int(caravan.get("visit_every_days", 1))
	var first := int(caravan.get("first_visit_day", 1))
	if every <= 0:
		return false
	var today := _clock.today()
	if today < first:
		return false
	return (today - first) % every == 0


func offers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not is_caravan_day():
		return out
	var device_table: Variant = _db.constant("device")
	if not device_table is Dictionary:
		return out
	for device_id in device_table:
		if str(device_id) == "default_id":
			continue
		var entry: Variant = device_table[device_id]
		if not entry is Dictionary or not entry.has("price"):
			continue
		out.append({
			"id": str(device_id),
			"name": str(entry.get("name", device_id)),
			"price": int(entry.get("price", 0)),
			"pressure_atm": float(entry.get("pressure_atm", 0.0)),
			"owned": _devices.has_device(str(device_id)),
			"current": _devices.current_id() == str(device_id),
		})
	return out


func buy(device_id: String) -> Dictionary:
	var device_table: Variant = _db.constant("device")
	if not device_table is Dictionary or not device_table.has(device_id):
		return { "bought": false, "reason": "unknown", "price": 0 }
	if device_id == "default_id":
		return { "bought": false, "reason": "unknown", "price": 0 }
	var entry: Variant = device_table[device_id]
	if not entry is Dictionary or not entry.has("price"):
		return { "bought": false, "reason": "not_for_sale", "price": 0 }
	if _devices.has_device(device_id):
		return { "bought": false, "reason": "owned", "price": 0 }
	if not is_caravan_day():
		return { "bought": false, "reason": "no_caravan", "price": 0 }
	var price := int(entry.get("price", 0))
	if not _wallet.spend_gold(price):
		return { "bought": false, "reason": "poor", "price": price }
	_devices.add_device(device_id)
	_devices.equip(device_id)
	if _publisher != null:
		_publisher.publish_money(_wallet)
		_publisher.publish_device(_devices)
	return { "bought": true, "reason": "ok", "price": price, "device_id": device_id }


func equip(device_id: String) -> Dictionary:
	if not _devices.equip(device_id):
		return { "ok": false, "reason": "not_owned" }
	if _publisher != null:
		_publisher.publish_device(_devices)
	return { "ok": true, "reason": "ok", "device_id": device_id }
