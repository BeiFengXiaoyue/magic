class_name SceneLayout
extends RefCounted

## M2 场景几何：室内房间边界、门、家具与固定贴图映射。
## 森林几何由 content/forest.json 提供；这里只保留室内。
##
## 家具的三件套来自同一份数据，避免贴图 / 碰撞 / 交互三处漂移：
## - art_size：贴图显示边长（像素，美术图按此缩放）
## - collider：地面占地（世界坐标），玩家不可穿越
## - interact_size：以 position 为中心的交互矩形，玩家靠近它的边缘即可按 E

const WORKSHOP := "scene_workshop"
const SHOP := "scene_shop"
const FOREST := "scene_forest"

const INDOOR_SIZE := Vector2(1280.0, 720.0)
const FOREST_SIZE := Vector2(3200.0, 2400.0)
const FOREST_MARGIN := 64.0

## 可行走地面按烘焙背景图的墙内沿量出来（原图 1024×576，游戏内 ×1.25）：
## 工坊地板 x≈155~890、y≈100~445；小店地板 x≈145~895、y≈80~490。
## 上边界再留出角色身高：贴图从脚底向上画，否则头顶会压到上墙。
const HERO_CLEARANCE := 120.0
const WORKSHOP_FLOOR := Rect2(200.0, 245.0, 870.0, 311.0)
const SHOP_FLOOR := Rect2(190.0, 220.0, 910.0, 392.0)

## 门都嵌在墙上，各占一面：工坊底墙门洞去森林，右墙门/梯位去小店；
## 小店左墙门回工坊。坐标对齐烘焙背景里的门洞 / 门框。
const WORKSHOP_DOOR_SHOP := Vector2(1115.0, 420.0)
const WORKSHOP_DOOR_FOREST := Vector2(651.0, 600.0)
const SHOP_DOOR_WORKSHOP := Vector2(170.0, 450.0)
const FOREST_DOOR_POS := Vector2(640.0, 600.0)
const DOOR_INTERACT_SIZE := Vector2(110.0, 100.0)
const DOOR_ART_SIZE := 96.0

## 家具按背景图里的实际占位定：坩埚在房间正中，床在左上，柜台在小店中上。
const CRUCIBLE_ART_SIZE := 96.0
const BED_ART_SIZE := 170.0
const COUNTER_ART_SIZE := 230.0

## 碰撞箱覆盖贴图的整个视觉占地：45° 俯视下也不让角色站进桌面 / 锅口 / 床面。
const CRUCIBLE_COLLIDER := Rect2(592.0, 312.0, 96.0, 96.0)
const BED_COLLIDER := Rect2(215.0, 364.0, 170.0, 152.0)
const COUNTER_COLLIDER := Rect2(732.0, 235.0, 230.0, 160.0)

const CRUCIBLE_INTERACT := Vector2(112.0, 112.0)
const BED_INTERACT := Vector2(190.0, 170.0)
const COUNTER_INTERACT := Vector2(250.0, 180.0)


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
	if scene_id == SHOP:
		return SHOP_FLOOR
	return WORKSHOP_FLOOR


static func camera_rect(scene_id: String) -> Rect2:
	return Rect2(Vector2.ZERO, map_size(scene_id))


static func spawn(scene_id: String) -> Vector2:
	if scene_id == WORKSHOP:
		return Vector2(520.0, 500.0)
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
		out.append(_item(
			"dev_clay_crucible", Vector2(640.0, 360.0), "坩埚", "crucible",
			"art_prop_crucible_clay", CRUCIBLE_ART_SIZE,
			CRUCIBLE_INTERACT, CRUCIBLE_COLLIDER
		))
		out.append(_item(
			"bed", Vector2(300.0, 440.0), "床", "bed",
			"art_prop_bed", BED_ART_SIZE,
			BED_INTERACT, BED_COLLIDER
		))
		out.append(_item(
			"door_shop", WORKSHOP_DOOR_SHOP, "去小店", "door",
			"art_prop_door_wood", DOOR_ART_SIZE, DOOR_INTERACT_SIZE
		))
		out.append(_item(
			"door_forest", WORKSHOP_DOOR_FOREST, "去晨暮森林", "door",
			"art_prop_door_wood", DOOR_ART_SIZE, DOOR_INTERACT_SIZE
		))
	elif scene_id == SHOP:
		out.append(_item(
			"shop_counter", Vector2(847.0, 315.0), "柜台", "counter",
			"art_prop_counter", COUNTER_ART_SIZE,
			COUNTER_INTERACT, COUNTER_COLLIDER
		))
		out.append(_item(
			"door_workshop", SHOP_DOOR_WORKSHOP, "回工坊", "door",
			"art_prop_door_wood", DOOR_ART_SIZE, DOOR_INTERACT_SIZE
		))
	elif scene_id == FOREST:
		out.append(_item(
			"door_workshop", FOREST_DOOR_POS, "回工坊", "door",
			"", 0.0, DOOR_INTERACT_SIZE
		))
	return out


## 碰撞箱从同一份布局数据推导，不再单独维护一组矩形。
static func obstacles(scene_id: String) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for item in interactables(scene_id):
		var collider: Variant = item.get("collider", Rect2())
		if collider is Rect2 and (collider as Rect2).size.x > 0.0:
			out.append(collider)
	return out


static func _item(
	target_id: String,
	position: Vector2,
	label: String,
	kind: String,
	art_id: String = "",
	art_size: float = 0.0,
	interact_size: Vector2 = Vector2.ZERO,
	collider: Rect2 = Rect2()
) -> Dictionary:
	return {
		"target_id": target_id,
		"position": position,
		"label": label,
		"kind": kind,
		"art_id": art_id,
		"art_size": art_size,
		"interact_size": interact_size,
		"collider": collider,
	}
