extends RefCounted

## 野生刷新：区域匹配、确定性、同天稳定、跨天重刷、消费移除。


func run(ctx: TestContext) -> void:
	var db := ContentDatabase.new()
	db.load_all()
	ctx.check(db.errors.is_empty(), "野生刷新测试需要干净的内容数据")
	var forest := db.forest()

	var rng_a := DeterministicRng.new()
	rng_a.init_world(9173271)
	var wild_a := WildSpawner.new(db, rng_a)
	wild_a.ensure_day(1)
	var nodes_a := wild_a.nodes("scene_forest")
	ctx.check_eq(nodes_a.size(), 6, "首日野生点数量")
	ctx.check_eq(_count_material(nodes_a, "mat_qinglucao"), 4, "清露草野生点数量")
	ctx.check_eq(_count_material(nodes_a, "mat_fengshisha"), 2, "风蚀砂野生点数量")

	for node in nodes_a:
		ctx.check(
			_in_allowed_zone(forest, node),
			"%s 应落在匹配 habitat 的区域内" % str(node.get("id", ""))
		)

	for i in nodes_a.size():
		for j in range(i + 1, nodes_a.size()):
			var distance := _point(nodes_a[i]).distance_to(_point(nodes_a[j]))
			ctx.check(distance >= 90.0, "野生点之间应保持最小间距")

	var snapshot_a := _snapshot(nodes_a)
	wild_a.ensure_day(1)
	ctx.check_eq(_snapshot(wild_a.nodes("scene_forest")), snapshot_a, "同一天不应重掷")

	var first_id := str(nodes_a[0]["id"])
	wild_a.consume(first_id)
	ctx.check(wild_a.node(first_id).is_empty(), "采集后野生点应移除")
	wild_a.ensure_day(1)
	ctx.check_eq(wild_a.nodes("scene_forest").size(), 5, "同一天消费后不应补刷")

	wild_a.ensure_day(2)
	var nodes_day2 := wild_a.nodes("scene_forest")
	ctx.check_eq(nodes_day2.size(), 6, "跨天应重新补满")
	for node in nodes_day2:
		ctx.check(
			str(node.get("id", "")).contains("_2_"),
			"第二天的野生点应使用新日期的 ID"
		)

	var rng_b := DeterministicRng.new()
	rng_b.init_world(9173272)
	var wild_b := WildSpawner.new(db, rng_b)
	wild_b.ensure_day(1)
	ctx.check(
		_snapshot(wild_b.nodes("scene_forest")) != snapshot_a,
		"换种子应改变野生点位置"
	)


func _count_material(nodes: Array[Dictionary], material_id: String) -> int:
	var count := 0
	for node in nodes:
		if str(node.get("material_id", "")) == material_id:
			count += 1
	return count


func _snapshot(nodes: Array[Dictionary]) -> Dictionary:
	var out: Dictionary = {}
	for node in nodes:
		out[str(node.get("id", ""))] = node.get("position", {})
	return out


func _point(node: Dictionary) -> Vector2:
	var position: Dictionary = node.get("position", {})
	return Vector2(float(position.get("x", 0.0)), float(position.get("y", 0.0)))


func _in_allowed_zone(forest: Dictionary, node: Dictionary) -> bool:
	var material_id := str(node.get("material_id", ""))
	var habitats: Array = []
	var spawners: Array = forest.get("wild_spawners", [])
	for spawner in spawners:
		if str(spawner.get("material_id", "")) == material_id:
			habitats = spawner.get("habitats", [])
			break
	var zones: Array = forest.get("spawn_zones", [])
	var point := _point(node)
	for zone in zones:
		if not habitats.has(str(zone.get("habitat", ""))):
			continue
		if _zone_contains(zone, point):
			return true
	return false


func _zone_contains(zone: Dictionary, point: Vector2) -> bool:
	var shape: Dictionary = zone.get("shape", {})
	var shape_type := str(shape.get("type", ""))
	if shape_type == "rect":
		var x := float(shape.get("x", 0.0))
		var y := float(shape.get("y", 0.0))
		var width := float(shape.get("w", 0.0))
		var height := float(shape.get("h", 0.0))
		return point.x >= x and point.y >= y and point.x <= x + width and point.y <= y + height
	if shape_type == "polygon":
		var points: Array[Vector2] = []
		var raw_points: Array = shape.get("points", [])
		for raw in raw_points:
			points.append(Vector2(float(raw.get("x", 0.0)), float(raw.get("y", 0.0))))
		return Geometry2D.is_point_in_polygon(point, PackedVector2Array(points))
	return false
