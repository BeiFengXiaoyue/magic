class_name ArtAssets
extends RefCounted

## art_id → 成品贴图。路径按 04 契约推导：
## res://assets/textures/<category>/<art_id>.png
## 缺图返回 null，调用方回退占位绘制。

static var _cache: Dictionary = {}
static var _missing: Dictionary = {}


static func category_of(art_id: String) -> String:
	var parts := art_id.split("_")
	if parts.size() < 3:
		return ""
	if parts[0] != "art":
		return ""
	return parts[1]


static func path_for(art_id: String) -> String:
	var category := category_of(art_id)
	if category == "":
		return ""
	return "res://assets/textures/%s/%s.png" % [category, art_id]


static func texture(art_id: String) -> Texture2D:
	if art_id == "":
		return null
	if _cache.has(art_id):
		return _cache[art_id]
	if _missing.has(art_id):
		return null
	var path := path_for(art_id)
	if path == "" or not ResourceLoader.exists(path):
		_missing[art_id] = true
		return null
	var loaded: Texture2D = load(path)
	if loaded == null:
		_missing[art_id] = true
		return null
	_cache[art_id] = loaded
	return loaded


static func clear_cache() -> void:
	_cache.clear()
	_missing.clear()
