class_name BoxBook
extends RefCounted

## 场景容器的分层状态。层条件复用 LetterBook 的到达条件求值器；
## 本类只负责“哪一层能开、开过没有”，不打开信、不碰 UI。

var _db: ContentDatabase
var _letters: LetterBook
var _opened: Dictionary = {}


func _init(db: ContentDatabase, letters: LetterBook) -> void:
	_db = db
	_letters = letters


func entry(container_id: String) -> Dictionary:
	return _db.container(container_id)


func layers(container_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var entry := _db.container(container_id)
	if entry.is_empty():
		return out
	var opened := _opened_layers(container_id)
	var raw_layers: Variant = entry.get("layers", [])
	if not raw_layers is Array:
		return out
	for layer in raw_layers:
		if not layer is Dictionary:
			continue
		var index := int(layer.get("index", 0))
		var conditions: Variant = layer.get("conditions", null)
		var unlocked := true
		if conditions is Dictionary:
			unlocked = _letters.conditions_met(conditions)
		out.append({
			"index": index,
			"label": str(layer.get("label", "")),
			"unlocked": unlocked,
			"opened": opened.has(index),
			"letter_id": str(layer.get("letter", "")),
			"hint": str(layer.get("hint", "")),
		})
	return out


func open_layer(container_id: String, index: int) -> Dictionary:
	var entry := _db.container(container_id)
	if entry.is_empty():
		return { "ok": false, "reason": "unknown", "letter_id": "", "hint": "" }
	var raw_layers: Variant = entry.get("layers", [])
	if not raw_layers is Array:
		return { "ok": false, "reason": "no_layer", "letter_id": "", "hint": "" }
	for layer in raw_layers:
		if not layer is Dictionary or int(layer.get("index", 0)) != index:
			continue
		var conditions: Variant = layer.get("conditions", null)
		if conditions is Dictionary and not _letters.conditions_met(conditions):
			return {
				"ok": false,
				"reason": "locked",
				"letter_id": "",
				"hint": str(layer.get("hint", "")),
			}
		var opened := _opened_layers(container_id)
		var first_open := not opened.has(index)
		if first_open:
			opened.append(index)
			_opened[container_id] = opened
		var letter_id := str(layer.get("letter", ""))
		return {
			"ok": true,
			"reason": "ok",
			"first_open": first_open,
			"letter_id": letter_id,
			"hint": "" if letter_id != "" else "空的。",
		}
	return { "ok": false, "reason": "no_layer", "letter_id": "", "hint": "" }


func snapshot() -> Dictionary:
	var out: Dictionary = {}
	for id in _opened:
		out[str(id)] = (_opened[id] as Array).duplicate()
	return out


func restore(snapshot: Dictionary) -> void:
	_opened.clear()
	for id in snapshot:
		var raw: Variant = snapshot[id]
		if not raw is Array:
			continue
		var layers: Array[int] = []
		for value in raw:
			layers.append(int(value))
		_opened[str(id)] = layers


func _opened_layers(container_id: String) -> Array[int]:
	var out: Array[int] = []
	if not _opened.has(container_id):
		return out
	var raw: Variant = _opened[container_id]
	if raw is Array:
		for value in raw:
			out.append(int(value))
	return out
