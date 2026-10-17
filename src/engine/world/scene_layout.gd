class_name SceneLayout
extends RefCounted

## M2 三个场景的占位布局（引擎表现参数，不是内容数据）。

const WORKSHOP := "scene_workshop"
const SHOP := "scene_shop"
const FOREST := "scene_forest"


static func spawn(scene_id: String) -> Vector2:
	if scene_id == WORKSHOP:
		return Vector2(640.0, 520.0)
	if scene_id == SHOP:
		return Vector2(320.0, 520.0)
	if scene_id == FOREST:
		return Vector2(220.0, 620.0)
	return Vector2(640.0, 520.0)


static func color(scene_id: String) -> Color:
	if scene_id == WORKSHOP:
		return Color("#2a211a")
	if scene_id == SHOP:
		return Color("#241f1c")
	if scene_id == FOREST:
		return Color("#17211a")
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
		out.append(_item("door_workshop", Vector2(140.0, 640.0), "回工坊", "door"))
	return out


static func _item(target_id: String, position: Vector2, label: String, kind: String) -> Dictionary:
	return {
		"target_id": target_id,
		"position": position,
		"label": label,
		"kind": kind,
	}
