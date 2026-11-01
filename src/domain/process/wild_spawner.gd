class_name WildSpawner
extends RefCounted

## 森林野生资源刷新（M2）。
## 按 forest.json 的 spawn_zones / wild_spawners 在匹配 habitat 的区域内布点；
## 使用确定性 wild 流，开局与跨天各刷新一次，同一天重复进出不重掷。

const MAX_PLACEMENT_ATTEMPTS := 48  # no-magic-ok: 布点重试上限，非策划数值
const MIN_POLYGON_POINTS := 3  # no-magic-ok: 多边形至少三个点

var _db: ContentDatabase
var _rng: DeterministicRng
var _map: Dictionary
var _active: Array[Dictionary] = []
var _last_day: int = -1


func _init(db: ContentDatabase, rng: DeterministicRng) -> void:
	_db = db
	_rng = rng
	_map = db.forest()


func scene_id() -> String:
	return str(_map.get("scene", "scene_forest"))


func ensure_day(day: int) -> void:
	if _last_day == day:
		return
	_last_day = day
	_active.clear()
	_generate(day)


func nodes(scene_id_value: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for node in _active:
		if str(node.get("scene", "")) == scene_id_value:
			out.append(node)
	return out


func node(node_id: String) -> Dictionary:
	for entry in _active:
		if str(entry.get("id", "")) == node_id:
			return entry
	return {}


func consume(node_id: String) -> void:
	for index in range(_active.size() - 1, -1, -1):
		if str(_active[index].get("id", "")) == node_id:
			_active.remove_at(index)
			return


func _generate(day: int) -> void:
	var spawners: Variant = _map.get("wild_spawners", [])
	var zones: Variant = _map.get("spawn_zones", [])
	if not spawners is Array or not zones is Array:
		return
	var rng := _rng.stream("wild")
	for entry in spawners:
		if not entry is Dictionary:
			continue
		var spawner: Dictionary = entry
		var habitats: Variant = spawner.get("habitats", [])
		var zones_for := _zones_for(zones, habitats)
		if zones_for.is_empty():
			continue
		var count := int(spawner.get("count", 0))
		var rule_id := str(spawner.get("id", ""))
		var placed := 0
		var attempts := 0
		var attempt_limit := MAX_PLACEMENT_ATTEMPTS * maxi(count, 1)
		while placed < count and attempts < attempt_limit:
			attempts += 1
			var zone: Dictionary = zones_for[rng.randi_range(0, zones_for.size() - 1)]
			var point := _random_point_in_zone(zone, rng)
			if point.x < 0.0:
				continue
			if not _valid_point(point, spawner):
				continue
			placed += 1
			_active.append({
				"id": "node_wild_%s_%d_%d" % [rule_id, day, placed],
				"material_id": str(spawner.get("material_id", "")),
				"tier": int(spawner.get("tier", 1)),
				"scene": scene_id(),
				"position": { "x": point.x, "y": point.y },
				"action": str(spawner.get("action", "gather")),
				"amount": int(spawner.get("amount", 1)),
				"source": "wild",
				"rule_id": rule_id,
			})


func _zones_for(zones: Array, habitats: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not habitats is Array:
		return out
	for zone_entry in zones:
		if not zone_entry is Dictionary:
			continue
		var zone: Dictionary = zone_entry
		if habitats.has(str(zone.get("habitat", ""))):
			out.append(zone)
	return out


func _random_point_in_zone(zone: Dictionary, rng: RandomNumberGenerator) -> Vector2:
	var shape: Variant = zone.get("shape", null)
	if not shape is Dictionary:
		return Vector2(-1.0, -1.0)
	var shape_type: Variant = shape.get("type", null)
	if shape_type == "rect":
		var x := float(shape.get("x", 0.0))
		var y := float(shape.get("y", 0.0))
		var width := float(shape.get("w", 0.0))
		var height := float(shape.get("h", 0.0))
		if width <= 0.0 or height <= 0.0:
			return Vector2(-1.0, -1.0)
		return Vector2(
			rng.randf_range(x, x + width),
			rng.randf_range(y, y + height)
		)
	if shape_type == "polygon":
		var points := _zone_points(shape)
		if points.size() < MIN_POLYGON_POINTS:
			return Vector2(-1.0, -1.0)
		var bounds := _points_bounds(points)
		var point := Vector2(
			rng.randf_range(bounds.position.x, bounds.end.x),
			rng.randf_range(bounds.position.y, bounds.end.y)
		)
		if _point_in_polygon(point, points):
			return point
	return Vector2(-1.0, -1.0)


func _valid_point(point: Vector2, spawner: Dictionary) -> bool:
	var size := _map_size()
	var margin := _walk_margin()
	if size.x <= 0.0 or size.y <= 0.0:
		return false
	if point.x < margin or point.y < margin or point.x > size.x - margin or point.y > size.y - margin:
		return false
	var min_distance := float(spawner.get("min_distance", 0.0))
	var min_sq := min_distance * min_distance
	if point.distance_squared_to(_map_position("spawn")) < min_sq:
		return false
	if point.distance_squared_to(_map_position("door")) < min_sq:
		return false
	for node_id in _db.node_ids():
		var node := _db.node(node_id)
		if str(node.get("scene", "")) != scene_id():
			continue
		if point.distance_squared_to(_position_from(node.get("position", {}))) < min_sq:
			return false
	var scenery: Variant = _map.get("scenery", [])
	if scenery is Array:
		for scenery_entry in scenery:
			if scenery_entry is Dictionary:
				if point.distance_squared_to(_position_from(scenery_entry.get("position", {}))) < min_sq:
					return false
	for active in _active:
		if point.distance_squared_to(_position_from(active.get("position", {}))) < min_sq:
			return false
	return true


func _map_size() -> Vector2:
	var size_data: Variant = _map.get("size", null)
	if not size_data is Dictionary:
		return Vector2.ZERO
	return Vector2(
		float(size_data.get("x", 0.0)),
		float(size_data.get("y", 0.0))
	)


func _walk_margin() -> float:
	return float(_map.get("walk_margin", 0.0))


func _map_position(key: String) -> Vector2:
	return _position_from(_map.get(key, {}))


func _position_from(value: Variant) -> Vector2:
	if value is Dictionary:
		return Vector2(
			float(value.get("x", 0.0)),
			float(value.get("y", 0.0))
		)
	return Vector2.ZERO


func _zone_points(shape: Dictionary) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var points: Variant = shape.get("points", [])
	if points is Array:
		for point in points:
			out.append(_position_from(point))
	return out


func _points_bounds(points: Array[Vector2]) -> Rect2:
	var min_point := points[0]
	var max_point := points[0]
	for point in points:
		min_point.x = minf(min_point.x, point.x)
		min_point.y = minf(min_point.y, point.y)
		max_point.x = maxf(max_point.x, point.x)
		max_point.y = maxf(max_point.y, point.y)
	return Rect2(min_point, max_point - min_point)


func _point_in_polygon(point: Vector2, polygon: Array[Vector2]) -> bool:
	var inside := false
	var previous := polygon.size() - 1
	for index in polygon.size():
		var current_point := polygon[index]
		var previous_point := polygon[previous]
		if (current_point.y > point.y) != (previous_point.y > point.y):
			var cross_x := (previous_point.x - current_point.x) * (point.y - current_point.y) / (previous_point.y - current_point.y) + current_point.x
			if point.x < cross_x:
				inside = not inside
		previous = index
	return inside
