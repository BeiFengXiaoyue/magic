class_name InteractUseCase
extends RefCounted

## 场景交互分发（契约 02 §4.1）。
## 引擎只发 interact / scene_change；这里决定开面板、采集还是切场景。

const SCENES: Array[String] = ["scene_workshop", "scene_shop", "scene_forest"]
const DOOR_TARGETS := {
	"door_shop": "scene_shop",
	"door_forest": "scene_forest",
	"door_workshop": "scene_workshop",
}

var _publisher: CraftEventPublisher
var _gather: GatherUseCase


func _init(publisher: CraftEventPublisher = null, gather: GatherUseCase = null) -> void:
	_publisher = publisher
	_gather = gather


func handle(target_id: String) -> Dictionary:
	if target_id.begins_with("node_") and _gather != null:
		return _gather.gather(target_id)
	match target_id:
		"dev_clay_crucible":
			_publish_panel("crucible")
			return { "handled": true, "kind": "panel", "message": "" }
		"shop_counter":
			_publish_panel("shop")
			return { "handled": true, "kind": "panel", "message": "" }
		"bed":
			return { "handled": true, "kind": "message", "message": "M2 还不能睡觉。" }
	if DOOR_TARGETS.has(target_id):
		handle_scene_change(str(DOOR_TARGETS[target_id]))
		return { "handled": true, "kind": "scene", "message": "" }
	return { "handled": false, "kind": "unknown", "message": "这里什么也没有。" }


func handle_scene_change(scene_id: String) -> bool:
	if not SCENES.has(scene_id):
		return false
	if _publisher != null:
		_publisher.publish_scene(scene_id)
	return true


func _publish_panel(panel: String) -> void:
	if _publisher != null:
		_publisher.publish_panel(panel, {})
