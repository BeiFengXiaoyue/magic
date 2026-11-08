class_name BoxUseCase
extends RefCounted

## 容器分层读取与开层。引擎只消费 view / open_layer 的返回值。

var _containers: BoxBook


func _init(containers: BoxBook) -> void:
	_containers = containers


func view(container_id: String) -> Dictionary:
	var entry := _containers.entry(container_id)
	return {
		"id": container_id,
		"name": str(entry.get("name", container_id)),
		"layers": _containers.layers(container_id),
	}


func open_layer(container_id: String, index: int) -> Dictionary:
	if container_id == "":
		return { "ok": false, "reason": "unknown", "letter_id": "", "hint": "" }
	return _containers.open_layer(container_id, index)
