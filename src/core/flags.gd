class_name Flags
extends RefCounted

## 布尔/简单标量世界状态（契约 05 §4.1）。
## 只存旗标；信件、库存等复杂状态不进这里。

var data: Dictionary = {}


func set_flag(id: String, value: Variant = true) -> void:
	if id.strip_edges() == "":
		push_error("Flags: 空旗标 ID")
		return
	data[id] = value


func has(id: String) -> bool:
	return data.has(id)


func value(id: String) -> Variant:
	return data.get(id, null)


func snapshot() -> Dictionary:
	return data.duplicate(true)


func restore(snapshot: Dictionary) -> void:
	data = snapshot.duplicate(true)
