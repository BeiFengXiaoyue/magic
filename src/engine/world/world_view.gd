class_name WorldView
extends Node2D

## 占位世界：室内房间（边界限制，只能从门离开）与森林大地图（相机跟随）。
## 森林地形/道路来自地图底图；代码只放固定景物、固定节点与随机野生点。
## 只发 interact 请求，不决定打开哪个面板或切哪个场景。

signal interact_requested(target_id: String)
signal hint_changed(text: String)

const INTERACT_PAD_PX := 44.0
const RESOURCE_ART_SIZE := 140.0
const SCENERY_ART_SIZE := 180.0
const GRID_STEP := 64.0
const GRID_COLOR := Color(1.0, 1.0, 1.0, 0.04)
const ROOM_FLOOR_COLOR := Color("#33281e")
const WALL_COLOR := Color("#6b5138")
const WALL_WIDTH := 12.0

const TREE_COLORS: Array[Color] = [
	Color("#2f4a2e"),
	Color("#355336"),
	Color("#294328"),
]
const TRUNK_COLOR := Color("#4a3826")
const ROCK_COLOR := Color("#5b5b55")
const BUSH_COLOR := Color("#3f5a3a")
const TREE_RADIUS := 26.0
const TRUNK_WIDTH := 10.0
const TRUNK_HEIGHT := 30.0
const ROCK_RADIUS := 20.0
const BUSH_RADIUS := 14.0

const DEBUG_GRID_STEP := 128.0
const DEBUG_GRID_COLOR := Color(1.0, 1.0, 1.0, 0.10)
const DEBUG_ZONE_COLOR := Color(1.0, 0.75, 0.35, 0.9)
const DEBUG_LINE_WIDTH := 3.0
const DEBUG_FONT_SIZE := 16
const DEBUG_TEXT_COLOR := Color("#f0d9a0")

var _db: ContentDatabase
var _forest_map: Dictionary = {}
var _player: Player
var _interactables: Array[InteractableNode] = []
var _wild_interactables: Array[InteractableNode] = []
var _wild_nodes: Array[Dictionary] = []
var _scene_id: String = ""
var _scene_size: Vector2 = Vector2(1280.0, 720.0)
var _input_enabled: bool = true
var _debug_zones: bool = false
var _last_hint: String = ""


func setup(db: ContentDatabase) -> void:
	_db = db
	_forest_map = db.forest()
	_player = Player.new()
	add_child(_player)


func change_scene(scene_id: String) -> void:
	_scene_id = scene_id
	_clear_interactables()
	_wild_nodes.clear()
	if scene_id == SceneLayout.FOREST and not _forest_map.is_empty():
		_apply_forest_geometry()
	else:
		_apply_indoor_geometry(scene_id)
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


func set_wild_nodes(nodes: Array[Dictionary]) -> void:
	for node in _wild_interactables:
		node.queue_free()
	_wild_interactables.clear()
	_wild_nodes = nodes
	for entry in _wild_nodes:
		var node_id := str(entry.get("id", ""))
		if node_id == "":
			continue
		var material := _db.material(str(entry.get("material_id", "")))
		var label := "%s（野生）" % str(material.get("name", node_id))
		_add_interactable(
			node_id,
			_position_from(entry.get("position", {})),
			label,
			"node",
			true,
			str(material.get("art_id", "")),
			RESOURCE_ART_SIZE,
			true,
			Vector2(RESOURCE_ART_SIZE, RESOURCE_ART_SIZE)
		)


func toggle_debug_zones() -> bool:
	_debug_zones = not _debug_zones
	queue_redraw()
	return _debug_zones


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
	var best_distance := INTERACT_PAD_PX
	for node in _interactables:
		var distance := node.interact_distance(_player.position)
		if distance <= best_distance:
			best_distance = distance
			best = node
	for node in _wild_interactables:
		var distance := node.interact_distance(_player.position)
		if distance <= best_distance:
			best_distance = distance
			best = node
	return best


func _apply_forest_geometry() -> void:
	_scene_size = _forest_size()
	if _scene_size.x <= 0.0 or _scene_size.y <= 0.0:
		_scene_size = Vector2(1280.0, 720.0)
	var margin := float(_forest_map.get("walk_margin", 0.0))
	_player.position = _position_from(_forest_map.get("spawn", {}))
	_player.set_bounds(Rect2(
		margin,
		margin,
		_scene_size.x - margin * 2.0,
		_scene_size.y - margin * 2.0
	))
	_player.set_camera_limits(Rect2(Vector2.ZERO, _scene_size))
	_player.set_obstacles(_forest_obstacles())


func _apply_indoor_geometry(scene_id: String) -> void:
	_scene_size = SceneLayout.map_size(scene_id)
	_player.position = SceneLayout.spawn(scene_id)
	_player.set_bounds(SceneLayout.walkable_rect(scene_id))
	_player.set_obstacles(SceneLayout.obstacles(scene_id))
	_player.set_camera_limits(SceneLayout.camera_rect(scene_id))


func _build_interactables(scene_id: String) -> void:
	if scene_id == SceneLayout.FOREST and not _forest_map.is_empty():
		_add_interactable(
			"door_workshop",
			_position_from(_forest_map.get("door", {})),
			"回工坊",
			"door",
			false,
			"",
			0.0,
			false,
			Vector2(240.0, 240.0)
		)
		for node_id in _db.node_ids():
			var node := _db.node(node_id)
			if str(node.get("scene", "")) != scene_id:
				continue
			var material := _db.material(str(node.get("material_id", "")))
			_add_interactable(
				node_id,
				_position_from(node.get("position", {})),
				"%s（采集点）" % str(material.get("name", node_id)),
				"node",
				false,
				str(material.get("art_id", "")),
				RESOURCE_ART_SIZE,
				true,
				Vector2(RESOURCE_ART_SIZE, RESOURCE_ART_SIZE)
			)
		return
	for item in SceneLayout.interactables(scene_id):
		var item_position: Vector2 = item["position"]
		var item_kind := str(item["kind"])
		var art_id := str(item.get("art_id", ""))
		var interact_size: Vector2 = item.get("interact_size", Vector2.ZERO)
		var visual := bool(item.get("visual", true))
		_add_interactable(
			str(item["target_id"]),
			item_position,
			str(item["label"]),
			item_kind,
			false,
			art_id,
			float(item.get("art_size", 0.0)),
			visual,
			interact_size
		)


func _add_interactable(
	target_id: String,
	position: Vector2,
	label: String,
	kind: String,
	wild: bool = false,
	art_id: String = "",
	art_size: float = 0.0,
	show_visual: bool = true,
	interact_size: Vector2 = Vector2.ZERO
) -> void:
	var node := InteractableNode.new()
	node.setup(target_id, label, kind, art_id, art_size, show_visual, interact_size)
	node.set_wild(wild)
	node.position = position
	add_child(node)
	if wild:
		_wild_interactables.append(node)
	else:
		_interactables.append(node)


func _clear_interactables() -> void:
	for node in _interactables:
		node.queue_free()
	for node in _wild_interactables:
		node.queue_free()
	_interactables.clear()
	_wild_interactables.clear()


func _draw() -> void:
	if _scene_id == SceneLayout.FOREST:
		_draw_forest_background()
		if _debug_zones:
			_draw_debug_zones()
		_draw_scenery()
		return
	_draw_indoor()


func _draw_indoor() -> void:
	var background := _scene_background_texture(_scene_id)
	if background != null:
		draw_texture_rect(background, Rect2(Vector2.ZERO, _scene_size), false)
		return
	draw_rect(Rect2(Vector2.ZERO, _scene_size), SceneLayout.color(_scene_id))
	for x in range(0, int(_scene_size.x), int(GRID_STEP)):
		draw_line(Vector2(float(x), 0.0), Vector2(float(x), _scene_size.y), GRID_COLOR)
	for y in range(0, int(_scene_size.y), int(GRID_STEP)):
		draw_line(Vector2(0.0, float(y)), Vector2(_scene_size.x, float(y)), GRID_COLOR)
	var room := SceneLayout.walkable_rect(_scene_id)
	draw_rect(room, ROOM_FLOOR_COLOR)
	draw_rect(room, WALL_COLOR, false, WALL_WIDTH)


func _draw_forest_background() -> void:
	var texture := _forest_background_texture()
	if texture != null:
		draw_texture_rect(texture, Rect2(Vector2.ZERO, _scene_size), false)
		return
	var background: Variant = _forest_map.get("background", {})
	var fallback := "#1b2a1d"
	if background is Dictionary:
		fallback = str(background.get("fallback_color", fallback))
	draw_rect(Rect2(Vector2.ZERO, _scene_size), Color(fallback))


func _draw_scenery() -> void:
	var scenery: Variant = _forest_map.get("scenery", [])
	if not scenery is Array:
		return
	var background := _forest_background_texture()
	for entry in scenery:
		if not entry is Dictionary:
			continue
		var position := _position_from(entry.get("position", {}))
		var kind := str(entry.get("kind", ""))
		var scale := float(entry.get("scale", 1.0))
		var variant := int(entry.get("variant", 0))
		var art_id := str(entry.get("art_id", ""))
		if background != null and art_id == "":
			continue
		if art_id != "":
			var texture := ArtAssets.texture(art_id)
			if texture != null:
				var side := SCENERY_ART_SIZE * scale
				draw_texture_rect(
					texture,
					Rect2(position - Vector2(side / 2.0, side / 2.0), Vector2(side, side)),
					false
				)
				continue
		if kind == "tree":
			var color := TREE_COLORS[variant % TREE_COLORS.size()]
			draw_circle(position, TREE_RADIUS * scale, color)
			draw_rect(Rect2(
				position.x - TRUNK_WIDTH * scale / 2.0,
				position.y,
				TRUNK_WIDTH * scale,
				TRUNK_HEIGHT * scale
			), TRUNK_COLOR)
		elif kind == "rock":
			draw_circle(position, ROCK_RADIUS * scale, ROCK_COLOR)
		elif kind == "bush":
			draw_circle(position, BUSH_RADIUS * scale, BUSH_COLOR)


func _draw_debug_zones() -> void:
	for x in range(0, int(_scene_size.x), int(DEBUG_GRID_STEP)):
		draw_line(Vector2(float(x), 0.0), Vector2(float(x), _scene_size.y), DEBUG_GRID_COLOR)
	for y in range(0, int(_scene_size.y), int(DEBUG_GRID_STEP)):
		draw_line(Vector2(0.0, float(y)), Vector2(_scene_size.x, float(y)), DEBUG_GRID_COLOR)
	var zones: Variant = _forest_map.get("spawn_zones", [])
	if not zones is Array:
		return
	for zone_entry in zones:
		if not zone_entry is Dictionary:
			continue
		var shape: Variant = zone_entry.get("shape", null)
		if not shape is Dictionary:
			continue
		var habitat := str(zone_entry.get("habitat", ""))
		var shape_type := str(shape.get("type", ""))
		if shape_type == "rect":
			var zone_rect := _rect_from(shape)
			draw_rect(zone_rect, DEBUG_ZONE_COLOR, false, DEBUG_LINE_WIDTH)
			_draw_debug_label(zone_rect.get_center(), habitat)
		elif shape_type == "polygon":
			var points := _polygon_points(shape)
			if points.size() < 3:
				continue
			var closed: Array[Vector2] = points.duplicate()
			closed.append(points[0])
			draw_polyline(PackedVector2Array(closed), DEBUG_ZONE_COLOR, DEBUG_LINE_WIDTH, true)
			_draw_debug_label(_polygon_center(points), habitat)


func _draw_debug_label(position: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	draw_string(
		font,
		position,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		DEBUG_FONT_SIZE,
		DEBUG_TEXT_COLOR
	)


func _forest_size() -> Vector2:
	var size_data: Variant = _forest_map.get("size", null)
	if not size_data is Dictionary:
		return Vector2.ZERO
	return Vector2(
		float(size_data.get("x", 0.0)),
		float(size_data.get("y", 0.0))
	)


func _forest_obstacles() -> Array[Rect2]:
	var out: Array[Rect2] = []
	if _forest_background_texture() != null:
		return out
	var scenery: Variant = _forest_map.get("scenery", [])
	if not scenery is Array:
		return out
	for entry in scenery:
		if not entry is Dictionary:
			continue
		var radius := float(entry.get("collision_radius", 0.0))
		if radius <= 0.0:
			continue
		var position := _position_from(entry.get("position", {}))
		out.append(Rect2(
			position - Vector2(radius, radius),
			Vector2(radius * 2.0, radius * 2.0)
		))
	return out


func _forest_background_texture() -> Texture2D:
	var background: Variant = _forest_map.get("background", {})
	if not background is Dictionary:
		return null
	return ArtAssets.texture(str(background.get("art_id", "")))


func _scene_background_texture(scene_id: String) -> Texture2D:
	if scene_id == SceneLayout.FOREST:
		return _forest_background_texture()
	return ArtAssets.texture(SceneLayout.background_art_id(scene_id))


func _position_from(value: Variant) -> Vector2:
	if value is Dictionary:
		return Vector2(
			float(value.get("x", 0.0)),
			float(value.get("y", 0.0))
		)
	return Vector2.ZERO


func _rect_from(shape: Dictionary) -> Rect2:
	return Rect2(
		float(shape.get("x", 0.0)),
		float(shape.get("y", 0.0)),
		float(shape.get("w", 0.0)),
		float(shape.get("h", 0.0))
	)


func _polygon_points(shape: Dictionary) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var points: Variant = shape.get("points", [])
	if points is Array:
		for point in points:
			out.append(_position_from(point))
	return out


func _polygon_center(points: Array[Vector2]) -> Vector2:
	var sum := Vector2.ZERO
	for point in points:
		sum += point
	return sum / float(points.size())
