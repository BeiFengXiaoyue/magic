class_name SceneLayout
extends RefCounted

## M2 场景几何：室内房间边界、门、家具与固定贴图映射。
## 森林几何由 content/forest.json 提供；这里只保留室内。

const WORKSHOP := "scene_workshop"
const SHOP := "scene_shop"
const FOREST := "scene_forest"

const INDOOR_SIZE := Vector2(1280.0, 720.0)
const FOREST_SIZE := Vector2(3200.0, 2400.0)
const ROOM_MARGIN := 48.0
const FOREST_MARGIN := 64.0

const WORKSHOP_DOOR_SHOP := Vector2(375.0, 672.0)
const WORKSHOP_DOOR_FOREST := Vector2(937.0, 672.0)
const SHOP_DOOR_WORKSHOP := Vector2(48.0, 560.0)
const FOREST_DOOR_POS := Vector2(640.0, 600.0)


static func background_art_id(scene_id: String) -> String:
	if scene_id == WORKSHOP:
		return "art_scene_workshop"
	if scene_id == SHOP:
		return "art_scene_shop"
	return ""


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
		return Vector2(760.0, 720.0)
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
		out.append(_item("dev_clay_crucible", Vector2(640.0, 360.0), "坩埚", "crucible", "art_prop_crucible_clay", 220.0))
		out.append(_item("bed", Vector2(220.0, 480.0), "床", "bed", "art_prop_bed", 240.0))
		out.append(_item("door_shop", WORKSHOP_DOOR_SHOP, "去小店", "door"))
		out.append(_item("door_forest", WORKSHOP_DOOR_FOREST, "去晨暮森林", "door"))
	elif scene_id == SHOP:
		out.append(_item("shop_counter", Vector2(875.0, 310.0), "柜台", "counter", "art_prop_counter", 320.0))
		out.append(_item("door_workshop", SHOP_DOOR_WORKSHOP, "回工坊", "door"))
	elif scene_id == FOREST:
		out.append(_item("door_workshop", FOREST_DOOR_POS, "回工坊", "door"))
	return out


static func obstacles(scene_id: String) -> Array[Rect2]:
	var out: Array[Rect2] = []
	if scene_id == WORKSHOP:
		out.append(Rect2(600.0, 320.0, 80.0, 80.0))
		out.append(Rect2(160.0, 440.0, 120.0, 80.0))
	elif scene_id == SHOP:
		out.append(Rect2(735.0, 270.0, 280.0, 80.0))
	return out


static func _item(
	target_id: String,
	position: Vector2,
	label: String,
	kind: String,
	art_id: String = "",
	art_size: float = 0.0
) -> Dictionary:
	return {
		"target_id": target_id,
		"position": position,
		"label": label,
		"kind": kind,
		"art_id": art_id,
		"art_size": art_size,
	}
