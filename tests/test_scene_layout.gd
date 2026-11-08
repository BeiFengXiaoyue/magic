extends RefCounted

## 室内布局一致性：贴图显示尺寸 / 地面碰撞箱 / 交互矩形三者不能漂移。
## 几何数据在 src/engine/world/scene_layout.gd，这里只验收结果。

const MAX_PROP_ART_SIZE := 260.0  # no-magic-ok: 物件贴图显示尺寸上限（美术预算），非策划数值


func run(ctx: TestContext) -> void:
	_check_scene_counts(ctx)
	_check_furniture(ctx)
	_check_doors(ctx)
	_check_no_overlap(ctx, SceneLayout.WORKSHOP)
	_check_no_overlap(ctx, SceneLayout.SHOP)
	_check_no_overlap(ctx, SceneLayout.ATTIC)
	_check_spawn_clear(ctx)
	_check_collision_stops_player(ctx)
	_check_interact_reachable(ctx)
	_check_edge_distance(ctx)


func _check_scene_counts(ctx: TestContext) -> void:
	ctx.check_eq(
		SceneLayout.interactables(SceneLayout.WORKSHOP).size(), 6,
		"工坊应有坩埚、床、两扇门、上阁楼梯子与信盘"
	)
	ctx.check_eq(
		SceneLayout.interactables(SceneLayout.SHOP).size(), 2,
		"小店应有柜台与一扇门"
	)
	ctx.check_eq(
		SceneLayout.interactables(SceneLayout.ATTIC).size(), 2,
		"阁楼应有旧木箱与下楼梯子"
	)
	for scene_id in [SceneLayout.WORKSHOP, SceneLayout.SHOP, SceneLayout.ATTIC]:
		for item in SceneLayout.interactables(scene_id):
			var size: Vector2 = item.get("interact_size", Vector2.ZERO)
			ctx.check(
				size.x > 0.0 and size.y > 0.0,
				"%s 的 %s 缺少交互矩形" % [scene_id, str(item.get("target_id", ""))]
			)


func _check_furniture(ctx: TestContext) -> void:
	for scene_id in [SceneLayout.WORKSHOP, SceneLayout.SHOP, SceneLayout.ATTIC]:
		for item in SceneLayout.interactables(scene_id):
			var kind := str(item.get("kind", ""))
			if kind != "crucible" and kind != "bed" and kind != "counter":
				continue
			var target := str(item.get("target_id", ""))
			var position: Vector2 = item["position"]
			var art_size := float(item.get("art_size", 0.0))
			var interact: Vector2 = item["interact_size"]
			var collider: Rect2 = item["collider"]
			ctx.check(
				art_size > 0.0 and art_size <= MAX_PROP_ART_SIZE,
				"%s 的贴图尺寸 %.0f 超出上限 %.0f" % [target, art_size, MAX_PROP_ART_SIZE]
			)
			ctx.check(
				collider.size.x > 0.0 and collider.size.y > 0.0,
				"%s 缺少碰撞箱" % target
			)
			ctx.check(
				collider.size.x <= art_size and collider.size.y <= art_size,
				"%s 的碰撞箱 %s 超过贴图尺寸 %.0f" % [target, str(collider.size), art_size]
			)
			var art_rect := Rect2(position - Vector2(art_size, art_size) * 0.5, Vector2(art_size, art_size))
			ctx.check(
				art_rect.has_point(collider.get_center()),
				"%s 的碰撞箱中心不在贴图范围内" % target
			)
			var interact_rect := Rect2(position - interact * 0.5, interact)
			ctx.check(
				interact_rect.encloses(collider),
				"%s 的交互矩形没有包住碰撞箱" % target
			)


func _check_doors(ctx: TestContext) -> void:
	for scene_id in [SceneLayout.WORKSHOP, SceneLayout.SHOP, SceneLayout.ATTIC]:
		var area := SceneLayout.walkable_rect(scene_id).grow(-Player.MARGIN)
		for item in SceneLayout.interactables(scene_id):
			var kind := str(item.get("kind", ""))
			if kind != "door" and kind != "ladder":
				continue
			var target := str(item.get("target_id", ""))
			var position: Vector2 = item["position"]
			var interact: Vector2 = item["interact_size"]
			var door_rect := Rect2(position - interact * 0.5, interact)
			ctx.check(
				(item["collider"] as Rect2).size.x <= 0.0,
				"%s 的门不应有碰撞箱" % target
			)
			ctx.check(
				_rect_gap(door_rect, area) <= WorldView.INTERACT_PAD_PX,
				"%s 从地面走不到" % target
			)
			for other in SceneLayout.interactables(scene_id):
				var collider: Rect2 = other["collider"]
				if collider.size.x <= 0.0:
					continue
				ctx.check(
					not door_rect.intersects(collider),
					"%s 的门被 %s 挡住" % [target, str(other.get("target_id", ""))]
				)


func _rect_gap(a: Rect2, b: Rect2) -> float:
	if a.intersects(b):
		return 0.0
	var dx := maxf(maxf(b.position.x - a.end.x, a.position.x - b.end.x), 0.0)
	var dy := maxf(maxf(b.position.y - a.end.y, a.position.y - b.end.y), 0.0)
	return Vector2(dx, dy).length()


func _check_no_overlap(ctx: TestContext, scene_id: String) -> void:
	var rects: Array[Rect2] = []
	for item in SceneLayout.interactables(scene_id):
		var position: Vector2 = item["position"]
		var interact: Vector2 = item["interact_size"]
		rects.append(Rect2(position - interact * 0.5, interact))
	for left in rects.size():
		for right in range(left + 1, rects.size()):
			ctx.check(
				not rects[left].intersects(rects[right]),
				"%s 的交互矩形重叠，E 会选错目标" % scene_id
			)


func _check_spawn_clear(ctx: TestContext) -> void:
	for scene_id in [SceneLayout.WORKSHOP, SceneLayout.SHOP, SceneLayout.ATTIC]:
		var spawn := SceneLayout.spawn(scene_id)
		for collider in SceneLayout.obstacles(scene_id):
			ctx.check(
				not collider.has_point(spawn),
				"%s 的出生点落在碰撞箱里" % scene_id
			)


## 从碰撞箱正下方往上走，最近可站位置应是“碰撞箱底边 + 玩家半径”。
func _check_collision_stops_player(ctx: TestContext) -> void:
	var player := Player.new()
	player.set_obstacles(SceneLayout.obstacles(SceneLayout.WORKSHOP))
	for collider in SceneLayout.obstacles(SceneLayout.WORKSHOP):
		var x := collider.get_center().x
		var probe_y := collider.end.y + Player.RADIUS + 4.0
		ctx.check(not player._blocked(Vector2(x, probe_y)), "碰撞箱下方应可站立")
		ctx.check(player._blocked(Vector2(x, collider.end.y)), "碰撞箱底边应阻挡玩家")
	player.free()


## 站在碰撞箱正下方（玩家半径之外）必须落在交互距离内。
func _check_interact_reachable(ctx: TestContext) -> void:
	for scene_id in [SceneLayout.WORKSHOP, SceneLayout.SHOP, SceneLayout.ATTIC]:
		for item in SceneLayout.interactables(scene_id):
			var collider: Rect2 = item["collider"]
			if collider.size.x <= 0.0:
				continue
			var probe := InteractableNode.new()
			var interact_size: Vector2 = item["interact_size"]
			probe.setup("probe", "探针", "node", "", 0.0, true, interact_size)
			probe.position = item["position"]
			var stand := Vector2(collider.get_center().x, collider.end.y + Player.RADIUS)
			ctx.check(
				probe.interact_distance(stand) <= WorldView.INTERACT_PAD_PX,
				"%s 的 %s 贴着碰撞箱也按不到 E" % [scene_id, str(item.get("target_id", ""))]
			)
			probe.free()


## 交互判定按矩形边缘而不是中心：站在贴图旁边就能按 E。
func _check_edge_distance(ctx: TestContext) -> void:
	var node := InteractableNode.new()
	node.setup("probe", "探针", "node", "", 0.0, true, Vector2(100.0, 100.0))
	node.position = Vector2(200.0, 200.0)
	ctx.check_approx(node.interact_distance(Vector2(200.0, 150.0)), 0.0, 0.001, "矩形内部距离应为 0")
	ctx.check_approx(node.interact_distance(Vector2(260.0, 200.0)), 10.0, 0.001, "边缘外 10px 应为 10")
	ctx.check_approx(node.interact_distance(Vector2(320.0, 200.0)), 70.0, 0.001, "边缘外 70px 应为 70")
	node.free()
