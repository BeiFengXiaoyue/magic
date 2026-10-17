class_name ContentDatabase
extends RefCounted

## 内容载入与查询（契约 02 §1.1）。
## 校验全部委托给 ContentValidator；本类只负责读文件、建索引、提供查询。

var errors: Array[String] = []

var _elements: Dictionary = {}
var _materials: Dictionary = {}
var _recipes: Dictionary = {}
var _items: Dictionary = {}
var _nodes: Dictionary = {}
var _constants: Dictionary = {}
var _element_order: Dictionary = {}


func load_all(path: String = "res://content") -> void:
	_reset()
	var elements_doc: Variant = _read_json(path.path_join("elements.json"), "elements.json")
	var materials_doc: Variant = _read_json(path.path_join("materials.json"), "materials.json")
	var recipes_doc: Variant = _read_json(path.path_join("recipes.json"), "recipes.json")
	var items_doc: Variant = _read_json(path.path_join("items.json"), "items.json")
	var nodes_doc: Variant = _read_json(path.path_join("nodes.json"), "nodes.json")
	var constants_doc: Variant = _read_json(path.path_join("constants.json"), "constants.json")

	var validator := ContentValidator.new()
	errors = validator.validate(elements_doc, materials_doc, recipes_doc, items_doc, nodes_doc, constants_doc)
	_elements = validator.elements
	_materials = validator.materials
	_recipes = validator.recipes
	_items = validator.items
	_nodes = validator.nodes
	_constants = validator.constants
	_element_order = validator.element_order

	for message in errors:
		push_error(message)


func element(id: String) -> Dictionary:
	if not _elements.has(id):
		push_error("ContentDatabase: 未知元素 %s" % id)
		return {}
	return _elements[id]


func material(id: String) -> Dictionary:
	if not _materials.has(id):
		push_error("ContentDatabase: 未知材料 %s" % id)
		return {}
	return _materials[id]


func recipe(id: String) -> Dictionary:
	if not _recipes.has(id):
		push_error("ContentDatabase: 未知配方 %s" % id)
		return {}
	return _recipes[id]


func item(id: String) -> Dictionary:
	if not _items.has(id):
		push_error("ContentDatabase: 未知物品 %s" % id)
		return {}
	return _items[id]


func node(id: String) -> Dictionary:
	if not _nodes.has(id):
		push_error("ContentDatabase: 未知采集点 %s" % id)
		return {}
	return _nodes[id]


func constant(path: String) -> Variant:
	if _constants.is_empty():
		push_error("ContentDatabase: constants 尚未载入")
		return null
	var current: Variant = _constants
	for part in path.split("."):
		if typeof(current) != TYPE_DICTIONARY:
			push_error("ContentDatabase: 常量路径无效 %s" % path)
			return null
		var dict: Dictionary = current
		if not dict.has(part):
			push_error("ContentDatabase: 常量路径不存在 %s" % path)
			return null
		current = dict[part]
	return current


func element_order(id: String) -> int:
	return int(_element_order.get(id, -1))


func element_ids() -> Array[String]:
	return _sorted_ids(_elements)


func material_ids() -> Array[String]:
	return _sorted_ids(_materials)


func recipe_ids() -> Array[String]:
	return _sorted_ids(_recipes)


func item_ids() -> Array[String]:
	return _sorted_ids(_items)


func node_ids() -> Array[String]:
	return _sorted_ids(_nodes)


func _sorted_ids(source: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for id in source:
		out.append(str(id))
	return out


func _reset() -> void:
	errors.clear()
	_elements.clear()
	_materials.clear()
	_recipes.clear()
	_items.clear()
	_nodes.clear()
	_constants.clear()
	_element_order.clear()


func _read_json(full_path: String, label: String) -> Variant:
	if not FileAccess.file_exists(full_path):
		errors.append("%s: 文件不存在（%s）" % [label, full_path])
		return null
	var text := FileAccess.get_file_as_string(full_path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	errors.append("%s: 无法解析为 JSON 对象" % label)
	return null
