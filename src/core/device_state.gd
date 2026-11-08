class_name DeviceState
extends RefCounted

## 已拥有的器材与当前装备。M3 只记 id，不做法术式属性。

var _owned: Dictionary = {}
var _current_id: String = ""


func _init(db: ContentDatabase) -> void:
	_current_id = str(db.constant("device.default_id"))
	if _current_id != "":
		_owned[_current_id] = true


func current_id() -> String:
	return _current_id


func has_device(device_id: String) -> bool:
	return _owned.has(device_id)


func add_device(device_id: String) -> void:
	if device_id != "":
		_owned[device_id] = true


func equip(device_id: String) -> bool:
	if not _owned.has(device_id):
		return false
	_current_id = device_id
	return true


func owned_ids() -> Array[String]:
	var out: Array[String] = []
	for id in _owned:
		out.append(str(id))
	return out


func snapshot() -> Dictionary:
	return { "owned": owned_ids(), "current_id": _current_id }


func restore(data: Dictionary) -> void:
	_owned.clear()
	var raw: Variant = data.get("owned", [])
	if raw is Array:
		for id in raw:
			_owned[str(id)] = true
	_current_id = str(data.get("current_id", _current_id))
	if _current_id != "":
		_owned[_current_id] = true
