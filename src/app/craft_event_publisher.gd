class_name CraftEventPublisher
extends RefCounted

## 把编排层的状态翻译成契约 payload 并发到事件总线。
## 单独成文件，让 payload 键名只有一处出处（契约 02 §4.2）。

var _event_bus: Object
var _perception: Perception


func _init(event_bus: Object, perception: Perception) -> void:
	_event_bus = event_bus
	_perception = perception


func publish_inventory(inventory: Inventory) -> void:
	_emit("state_changed", "inventory", inventory.snapshot())


func publish_crucible(session: CraftSession) -> void:
	var payload: Dictionary
	if session == null:
		payload = {
			"active": false,
			"progress": 0.0,
			"tier_id": "",
			"inputs": {},
		}
	else:
		payload = {
			"active": true,
			"progress": session.progress,
			"tier_id": session.tier_id,
			"inputs": session.inputs.duplicate(),
		}
	_emit("state_changed", "crucible", payload)


func publish_bubbles(session: CraftSession) -> void:
	if session == null or _perception == null:
		return
	var visual := _perception.visual({}, { "temperature_c": session.temperature_c })
	_emit("cue_requested", "bubbles", visual)


func publish_player(character: CharacterState) -> void:
	_emit("state_changed", "player", character.snapshot())


func publish_money(wallet: Wallet) -> void:
	_emit("state_changed", "money", wallet.snapshot())


func publish_nodes(unavailable: Array[String]) -> void:
	_emit("state_changed", "nodes", { "unavailable": unavailable })


func publish_wild(scene_id: String, nodes: Array) -> void:
	_emit("state_changed", "wild", { "scene_id": scene_id, "nodes": nodes })


func publish_panel(panel: String, params: Dictionary) -> void:
	if _event_bus == null:
		return
	_event_bus.emit_signal("panel_requested", panel, params)


func publish_scene(scene_id: String) -> void:
	_emit("cue_requested", "scene", { "scene_id": scene_id })


func _emit(signal_name: String, first: Variant, second: Variant) -> void:
	if _event_bus == null:
		return
	_event_bus.emit_signal(signal_name, first, second)
