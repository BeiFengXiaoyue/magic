class_name Knowledge
extends RefCounted

## 知识 K6（契约 05 §4.3）：配方 / 地点 / 概念 / 图纸。
## 只影响手记与指引，不影响配方匹配、求解或定价。

const KINDS: Array[String] = ["recipe", "location", "concept", "blueprint"]

var _data: Dictionary = {
	"recipe": [],
	"location": [],
	"concept": [],
	"blueprint": [],
}
var _seen: Dictionary = {}


func unlock(kind: String, id: String) -> void:
	if not KINDS.has(kind):
		push_error("Knowledge: 非法知识类别 %s" % kind)
		return
	if id.strip_edges() == "":
		push_error("Knowledge: 空知识 ID")
		return
	if has(kind, id):
		return
	var target: Array = _data[kind]
	target.append(id)
	_seen[kind + ":" + id] = true


func has(kind: String, id: String) -> bool:
	return _seen.has(kind + ":" + id)


func list(kind: String) -> Array[String]:
	var out: Array[String] = []
	if not _data.has(kind):
		return out
	for entry in _data[kind]:
		out.append(str(entry))
	return out


func snapshot() -> Dictionary:
	return _data.duplicate(true)


func restore(snapshot: Dictionary) -> void:
	_data = {
		"recipe": [],
		"location": [],
		"concept": [],
		"blueprint": [],
	}
	_seen.clear()
	for kind in KINDS:
		var values: Variant = snapshot.get(kind, [])
		if not values is Array:
			continue
		for entry in values:
			unlock(kind, str(entry))
