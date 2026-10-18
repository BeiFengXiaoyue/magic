class_name GatherUseCase
extends RefCounted

## O2 · 采一次集（契约 02 §3）。
## 固定节点走再生；野生节点由 WildSpawner 生成，采集后移除，跨天重刷。

var _db: ContentDatabase
var _process: GatherProcess
var _inventory: Inventory
var _character: CharacterState
var _clock: GameClock
var _rng: DeterministicRng
var _wild: WildSpawner
var _publisher: CraftEventPublisher
var _regrow_at: Dictionary = {}


func _init(
	db: ContentDatabase,
	process: GatherProcess,
	inventory: Inventory,
	character: CharacterState,
	clock: GameClock,
	rng: DeterministicRng,
	wild: WildSpawner = null,
	publisher: CraftEventPublisher = null
) -> void:
	_db = db
	_process = process
	_inventory = inventory
	_character = character
	_clock = clock
	_rng = rng
	_wild = wild
	_publisher = publisher
	_clock.day_passed.connect(_on_day_passed)
	if _wild != null:
		_wild.ensure_day(_clock.today())


func gather(node_id: String) -> Dictionary:
	var today := _clock.today()
	if _wild != null:
		_wild.ensure_day(today)

	var node := _db.node(node_id) if _db.has_node(node_id) else {}
	var is_wild := false
	if node.is_empty() and _wild != null:
		node = _wild.node(node_id)
		is_wild = not node.is_empty()
	if node.is_empty():
		return _failure("unknown_node")
	if not is_wild and not is_available(node_id):
		return _failure("regrowing")

	var tool_id := str(_db.constant("gathering.default_tool"))
	var outcome := _process.attempt(node, tool_id, _rng)
	var sanity_cost := int(outcome["sanity_cost"])
	_character.adjust_sanity(-sanity_cost)
	var minutes := int(outcome["minutes"])

	var success := bool(outcome["success"])
	var material_id := str(outcome["material_id"])
	var count := int(outcome["count"])
	if success:
		_inventory.add_material(material_id, count)
		if is_wild:
			_wild.consume(node_id)
		else:
			var tier := int(node.get("tier", 1))
			var regrow_table: Dictionary = _db.constant("gathering.regrow_days_by_tier")
			var days := int(regrow_table.get(str(tier), 0))
			_regrow_at[node_id] = today + days

	_clock.advance(minutes)

	if success:
		_publish_inventory()
		if not is_wild:
			_publish_nodes()
	_publish_player()
	_publish_wild()

	return {
		"success": success,
		"material_id": material_id,
		"count": count,
		"sanity_cost": sanity_cost,
		"minutes": minutes,
		"reason": "ok" if success else "miss",
	}


func wild_nodes(scene_id: String) -> Array[Dictionary]:
	if _wild == null:
		return []
	_wild.ensure_day(_clock.today())
	return _wild.nodes(scene_id)


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


func _publish_wild() -> void:
	if _publisher == null or _wild == null:
		return
	_publisher.publish_wild(_wild.scene_id(), _wild.nodes(_wild.scene_id()))


func _on_day_passed(_day: int, _season: int, _year: int) -> void:
	if _wild != null:
		_wild.ensure_day(_clock.today())
		_publish_wild()
	_publish_nodes()
