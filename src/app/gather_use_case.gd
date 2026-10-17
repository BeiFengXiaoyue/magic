class_name GatherUseCase
extends RefCounted

## O2 · 采一次集（契约 02 §3）。
## D1 判定 → 成功入库 → D4 扣理智（成功/空手同耗）→ 推时间 → 节点再生。

var _db: ContentDatabase
var _process: GatherProcess
var _inventory: Inventory
var _character: CharacterState
var _clock: GameClock
var _rng: DeterministicRng
var _publisher: CraftEventPublisher
var _regrow_at: Dictionary = {}


func _init(
	db: ContentDatabase,
	process: GatherProcess,
	inventory: Inventory,
	character: CharacterState,
	clock: GameClock,
	rng: DeterministicRng,
	publisher: CraftEventPublisher = null
) -> void:
	_db = db
	_process = process
	_inventory = inventory
	_character = character
	_clock = clock
	_rng = rng
	_publisher = publisher
	_clock.day_passed.connect(_on_day_passed)


func gather(node_id: String) -> Dictionary:
	var node := _db.node(node_id)
	if node.is_empty():
		return _failure("unknown_node")
	if not is_available(node_id):
		return _failure("regrowing")

	var today := _clock.today()
	var tool_id := str(_db.constant("gathering.default_tool"))
	var outcome := _process.attempt(node, tool_id, _rng)
	var sanity_cost := int(outcome["sanity_cost"])
	_character.adjust_sanity(-sanity_cost)
	var minutes := int(outcome["minutes"])
	_clock.advance(minutes)

	var success := bool(outcome["success"])
	var material_id := str(outcome["material_id"])
	var count := int(outcome["count"])
	if success:
		_inventory.add_material(material_id, count)
		var tier := int(node.get("tier", 1))
		var regrow_table: Dictionary = _db.constant("gathering.regrow_days_by_tier")
		var days := int(regrow_table.get(str(tier), 0))
		_regrow_at[node_id] = today + days
		_publish_inventory()
		_publish_nodes()
	_publish_player()

	return {
		"success": success,
		"material_id": material_id,
		"count": count,
		"sanity_cost": sanity_cost,
		"minutes": minutes,
		"reason": "ok" if success else "miss",
	}


func is_available(node_id: String) -> bool:
	if not _regrow_at.has(node_id):
		return true
	return _clock.today() >= int(_regrow_at[node_id])


func unavailable_ids() -> Array[String]:
	var out: Array[String] = []
	for node_id in _db.node_ids():
		if not is_available(node_id):
			out.append(node_id)
	return out


func _failure(reason: String) -> Dictionary:
	return {
		"success": false,
		"material_id": "",
		"count": 0,
		"sanity_cost": 0,
		"minutes": 0,
		"reason": reason,
	}


func _publish_inventory() -> void:
	if _publisher != null:
		_publisher.publish_inventory(_inventory)


func _publish_player() -> void:
	if _publisher != null:
		_publisher.publish_player(_character)


func _publish_nodes() -> void:
	if _publisher != null:
		_publisher.publish_nodes(unavailable_ids())


func _on_day_passed(_day: int, _season: int, _year: int) -> void:
	_publish_nodes()
