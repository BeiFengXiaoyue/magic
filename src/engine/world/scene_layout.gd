class_name SceneLayout
extends RefCounted

## M2 场景几何：室内房间边界、森林大地图、相机范围与占位布局。

const WORKSHOP := "scene_workshop"
const SHOP := "scene_shop"
const FOREST := "scene_forest"

const INDOOR_SIZE := Vector2(1280.0, 720.0)
const FOREST_SIZE := Vector2(3200.0, 2400.0)
const ROOM_MARGIN := 48.0
const FOREST_MARGIN := 64.0


static func map_size(scene_id: String) -> Vector2:
	if scene_id == FOREST:
		return FOREST_SIZE
	return INDOOR_SIZE


static func walkable_rect(scene_id: String) -> Rect2:
	if scene_id == FOREST:
		return Rect2(
			FOREST_MARGIN,
			FOREST_MARGIN,
			FOREST_SIZE.x - FOREST_MARGIN * 2.0,
			FOREST_SIZE.y - FOREST_MARGIN * 2.0
		)
	return Rect2(
		ROOM_MARGIN,
		ROOM_MARGIN,
		INDOOR_SIZE.x - ROOM_MARGIN * 2.0,
		INDOOR_SIZE.y - ROOM_MARGIN * 2.0
	)


static func camera_rect(scene_id: String) -> Rect2:
	return Rect2(Vector2.ZERO, map_size(scene_id))


static func spawn(scene_id: String) -> Vector2:
	if scene_id == WORKSHOP:
		return Vector2(640.0, 520.0)
	if scene_id == SHOP:
		return Vector2(320.0, 520.0)
	if scene_id == FOREST:
		return Vector2(420.0, 1200.0)
	return Vector2(640.0, 520.0)


static func color(scene_id: String) -> Color:
	if scene_id == WORKSHOP:
		return Color("#2a211a")
	if scene_id == SHOP:
		return Color("#241f1c")
	if scene_id == FOREST:
		return Color("#1b2a1d")
	return Color("#1a1714")


static func interactables(scene_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if scene_id == WORKSHOP:
		out.append(_item("dev_clay_crucible", Vector2(560.0, 360.0), "坩埚", "crucible"))
		out.append(_item("bed", Vector2(220.0, 560.0), "床", "bed"))
		out.append(_item("door_shop", Vector2(1120.0, 340.0), "去小店", "door"))
		out.append(_item("door_forest", Vector2(1120.0, 580.0), "去晨暮森林", "door"))
	elif scene_id == SHOP:
		out.append(_item("shop_counter", Vector2(720.0, 360.0), "柜台", "counter"))
		out.append(_item("door_workshop", Vector2(180.0, 560.0), "回工坊", "door"))
	elif scene_id == FOREST:
		out.append(_item("door_workshop", Vector2(300.0, 1200.0), "回工坊", "door"))
	return out


static func _item(target_id: String, position: Vector2, label: String, kind: String) -> Dictionary:
	return {
		"target_id": target_id,
		"position": position,
		"label": label,
		"kind": kind,
	}
