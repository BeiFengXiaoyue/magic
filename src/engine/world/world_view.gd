class_name WorldView
extends Node2D

## M2 占位世界：三个场景、玩家移动、最近交互物、节点再生灰化。
## 只发 interact 请求，不决定打开哪个面板或切哪个场景。

signal interact_requested(target_id: String)
signal hint_changed(text: String)

const INTERACT_RADIUS_PX := 80.0
const SCENE_WIDTH := 1280.0
const SCENE_HEIGHT := 720.0
const GRID_STEP := 64.0
const GRID_COLOR := Color(1.0, 1.0, 1.0, 0.04)

var _db: ContentDatabase
var _player: Player
var _interactables: Array[InteractableNode] = []
var _scene_id: String = ""
var _input_enabled: bool = true
var _last_hint: String = ""


func setup(db: ContentDatabase) -> void:
	_db = db
	_player = Player.new()
	add_child(_player)


func change_scene(scene_id: String) -> void:
	_scene_id = scene_id
	for node in _interactables:
		node.queue_free()
	_interactables.clear()
	_player.position = SceneLayout.spawn(scene_id)
	_build_interactables(scene_id)
	queue_redraw()
	_last_hint = ""
	hint_changed.emit("")


func current_scene() -> String:
	return _scene_id


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if _player != null:
		_player.set_input_enabled(enabled)
	if not enabled:
		_last_hint = ""
		hint_changed.emit("")


func set_node_availability(unavailable: Array[String]) -> void:
	for node in _interactables:
		if node.kind == "node":
			node.set_available(not unavailable.has(node.target_id))


func _process(_delta: float) -> void:
	if not _input_enabled or _player == null:
		return
	var nearest := _nearest()
	var hint := ("E · %s" % nearest.label) if nearest != null else ""
	if hint != _last_hint:
		_last_hint = hint
		hint_changed.emit(hint)


func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled or _player == null:
		return
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode != KEY_E:
		return
	var nearest := _nearest()
	if nearest != null:
		interact_requested.emit(nearest.target_id)


func _nearest() -> InteractableNode:
	var best: InteractableNode = null
	var best_distance := INTERACT_RADIUS_PX
	for node in _interactables:
		var distance := node.position.distance_to(_player.position)
		if distance <= best_distance:
			best_distance = distance
			best = node
	return best


func _build_interactables(scene_id: String) -> void:
	for item in SceneLayout.interactables(scene_id):
		var item_position: Vector2 = item["position"]
		_add_interactable(
			str(item["target_id"]),
			item_position,
			str(item["label"]),
			str(item["kind"])
		)
	if scene_id != SceneLayout.FOREST:
		return
	for node_id in _db.node_ids():
		var node := _db.node(node_id)
		if str(node.get("scene", "")) != scene_id:
			continue
		var position_data: Dictionary = node.get("position", {})
		var position := Vector2(
			float(position_data.get("x", 0.0)),
			float(position_data.get("y", 0.0))
		)
		var material := _db.material(str(node.get("material_id", "")))
		var label := "%s（采集点）" % str(material.get("name", node_id))
		_add_interactable(node_id, position, label, "node")


func _add_interactable(target_id: String, position: Vector2, label: String, kind: String) -> void:
	var node := InteractableNode.new()
	node.setup(target_id, label, kind)
	node.position = position
	add_child(node)
	_interactables.append(node)


func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, SCENE_WIDTH, SCENE_HEIGHT), SceneLayout.color(_scene_id))
	for x in range(0, int(SCENE_WIDTH), int(GRID_STEP)):
		draw_line(Vector2(float(x), 0.0), Vector2(float(x), SCENE_HEIGHT), GRID_COLOR)
	for y in range(0, int(SCENE_HEIGHT), int(GRID_STEP)):
		draw_line(Vector2(0.0, float(y)), Vector2(SCENE_WIDTH, float(y)), GRID_COLOR)
