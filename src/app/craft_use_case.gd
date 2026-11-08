class_name CraftUseCase
extends RefCounted

## O1 · 炼一炉（契约 02 §3）。
## 扣材料、推时钟、产出入 Inventory、按契约广播状态。

var _db: ContentDatabase
var _clock: GameClock
var _inventory: Inventory
var _process: CraftProcess
var _publisher: CraftEventPublisher
var _journal: Journal = null
var _spirituality: Spirituality = null
var _devices: DeviceState = null
var _session: CraftSession = null
var _session_counter: int = 0


func _init(
	db: ContentDatabase,
	clock: GameClock,
	inventory: Inventory,
	process: CraftProcess,
	publisher: CraftEventPublisher = null,
	journal: Journal = null,
	spirituality: Spirituality = null,
	devices: DeviceState = null
) -> void:
	_db = db
	_clock = clock
	_inventory = inventory
	_process = process
	_publisher = publisher
	_journal = journal
	_spirituality = spirituality
	_devices = devices
	_sync_device()


func _sync_device() -> void:
	if _devices != null and _devices.current_id() != "":
		_process.set_device(_devices.current_id())


func begin(inputs: Dictionary, tier_id: String) -> String:
	if _session != null:
		return ""
	if inputs.is_empty():
		return ""
	for mat_id in inputs:
		var count := int(inputs[mat_id])
		if count <= 0:
			return ""
		if _inventory.count_material(str(mat_id)) < count:
			return ""
	for mat_id in inputs:
		_inventory.take_material(str(mat_id), int(inputs[mat_id]))

	var session := _process.start(inputs, { "temperature_tier": tier_id })
	if session == null:
		for mat_id in inputs:
			_inventory.add_material(str(mat_id), int(inputs[mat_id]))
		return ""

	_session_counter += 1
	session.id = "craft_%d" % _session_counter
	_session = session
	_publish_inventory()
	_publish_crucible()
	_publish_bubbles()
	return session.id


func tick(game_minutes: int) -> void:
	if game_minutes <= 0:
		return
	_clock.advance(game_minutes)
	if _session != null and not _session.finished:
		_process.tick(_session, game_minutes)
		_publish_crucible()


func set_tier(tier_id: String) -> void:
	if _session == null or _session.finished:
		return
	_process.set_tier(_session, tier_id)
	_publish_crucible()
	_publish_bubbles()


func take_out() -> CraftResult:
	if _session == null:
		return null
	var session := _session
	var result := _process.take_out(session)
	if result == null:
		return null
	var product := ProductInstance.new()
	product.itm_id = "itm_potion"
	product.recipe_id = session.recipe_id
	product.result = result
	product.created_day = _clock.today()
	var item := _db.item(product.itm_id)
	product.itm_name = str(item.get("name", product.itm_id))
	_inventory.add_product(product)
	_session = null
	if _journal != null:
		_journal.add_craft_entry(result, {
			"inputs": session.inputs.duplicate(),
			"tier_id": session.tier_id,
			"duration_minutes": session.duration_minutes,
			"device_id": session.device_id,
			"pressure_atm": session.pressure_atm,
			"spirit_total": _spirituality.total() if _spirituality != null else 0,
			"day": _clock.today(),
			"minute_of_day": _clock.minute_of_day,
		})
	_publish_inventory()
	_publish_crucible()
	return result


func debug_snapshot() -> Dictionary:
	if _session == null:
		return { "active": false }
	var result := _session.result
	return {
		"active": true,
		"temperature_c": _session.temperature_c,
		"tier_id": _session.tier_id,
		"progress": _session.progress,
		"dominant": result.dominant if result != null else "",
		"yield_ratio": result.yield_ratio if result != null else 0.0,
		"composition": result.composition if result != null else {},
		"reading": result.reading if result != null else {},
		"reaction_log": result.reaction_log if result != null else [],
	}


func _publish_inventory() -> void:
	if _publisher != null:
		_publisher.publish_inventory(_inventory)


func _publish_crucible() -> void:
	if _publisher != null:
		_publisher.publish_crucible(_session)


func _publish_bubbles() -> void:
	if _publisher != null:
		_publisher.publish_bubbles(_session)
