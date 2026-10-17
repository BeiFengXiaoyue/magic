class_name WorldView
extends Node2D

## 占位世界：室内房间（边界限制，只能从门离开）与森林大地图（相机跟随）。
## 只发 interact 请求，不决定打开哪个面板或切哪个场景。

signal interact_requested(target_id: String)
signal hint_changed(text: String)

const INTERACT_RADIUS_PX := 80.0
const GRID_STEP := 64.0
const GRID_COLOR := Color(1.0, 1.0, 1.0, 0.04)
const ROOM_FLOOR_COLOR := Color("#33281e")
const WALL_COLOR := Color("#6b5138")
const WALL_WIDTH := 12.0
const PATH_COLOR := Color("#4a3a28")
const PATH_WIDTH := 28.0
const TREE_COLOR := Color("#2f4a2e")
const TRUNK_COLOR := Color("#4a3826")
const TREE_COUNT := 48
const TREE_X_MIN := 160.0
const TREE_Y_MIN := 160.0
const TREE_X_STEP := 397
const TREE_Y_STEP := 613
const TREE_X_SPAN := 2880
const TREE_Y_SPAN := 2080
const TREE_RADIUS := 26.0
const TRUNK_WIDTH := 10.0
const TRUNK_HEIGHT := 30.0

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
	_player.set_bounds(SceneLayout.walkable_rect(scene_id))
	_player.set_camera_limits(SceneLayout.camera_rect(scene_id))
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
	var map_size := SceneLayout.map_size(_scene_id)
	draw_rect(Rect2(Vector2.ZERO, map_size), SceneLayout.color(_scene_id))
	for x in range(0, int(map_size.x), int(GRID_STEP)):
		draw_line(Vector2(float(x), 0.0), Vector2(float(x), map_size.y), GRID_COLOR)
	for y in range(0, int(map_size.y), int(GRID_STEP)):
		draw_line(Vector2(0.0, float(y)), Vector2(map_size.x, float(y)), GRID_COLOR)
	if _scene_id == SceneLayout.FOREST:
		_draw_forest()
	else:
		_draw_room()


func _draw_room() -> void:
	var room := SceneLayout.walkable_rect(_scene_id)
	draw_rect(room, ROOM_FLOOR_COLOR)
	draw_rect(room, WALL_COLOR, false, WALL_WIDTH)


func _draw_forest() -> void:
	var door := Vector2(300.0, 1200.0)
	if _db != null:
		for node_id in _db.node_ids():
			var node := _db.node(node_id)
			if str(node.get("scene", "")) != _scene_id:
				continue
			var position_data: Dictionary = node.get("position", {})
			var target := Vector2(
				float(position_data.get("x", 0.0)),
				float(position_data.get("y", 0.0))
			)
			draw_line(door, target, PATH_COLOR, PATH_WIDTH)

	for i in TREE_COUNT:
		var x := TREE_X_MIN + float((i * TREE_X_STEP) % TREE_X_SPAN)
		var y := TREE_Y_MIN + float((i * TREE_Y_STEP) % TREE_Y_SPAN)
		draw_circle(Vector2(x, y), TREE_RADIUS, TREE_COLOR)
		draw_rect(
			Rect2(x - TRUNK_WIDTH / 2.0, y, TRUNK_WIDTH, TRUNK_HEIGHT),
			TRUNK_COLOR
		)
