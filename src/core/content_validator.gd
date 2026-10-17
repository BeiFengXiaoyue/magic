class_name ContentValidator
extends RefCounted

## 内容校验（契约 00 §7.2 的 11 条）。
## 只吃原始文档，不依赖 ContentDatabase，便于单独测试与修改。

const SCHEMA_VERSION := 1
const TOLERANCE := 1e-6  # no-magic-ok: 契约 00 §7.2 的浮点比较容差
const MIN_ELEMENT_TOTAL := 0.5  # no-magic-ok: 契约 00 §7.2 数值域下限
const MAX_ELEMENT_TOTAL := 10.0  # no-magic-ok: 契约 00 §7.2 数值域上限
const MAX_FLUCTUATION := 0.5  # no-magic-ok: 契约 00 §7.2 fluctuation 上限
const MAX_TIER := 4  # no-magic-ok: 契约 tier 1~4
const MAX_GATHER_TIER := 3  # no-magic-ok: 采集阶只有 1~3（数值表 §5.4）
const SCENES: Array[String] = ["scene_workshop", "scene_shop", "scene_forest"]

var errors: Array[String] = []
var elements: Dictionary = {}
var materials: Dictionary = {}
var recipes: Dictionary = {}
var items: Dictionary = {}
var nodes: Dictionary = {}
var constants: Dictionary = {}
var element_order: Dictionary = {}

var _seen_ids: Dictionary = {}
var _temperature_tier_ids: Dictionary = {}
var _effects: Dictionary = {}
var _costs: Dictionary = {}
var _special_effects: Dictionary = {}
var _axes: Dictionary = {}


func validate(
	elements_doc: Variant,
	materials_doc: Variant,
	recipes_doc: Variant,
	items_doc: Variant,
	nodes_doc: Variant,
	constants_doc: Variant
) -> Array[String]:
	_reset()
	_index(elements_doc, "elements.json", elements, element_order)
	_index(materials_doc, "materials.json", materials, {})
	_index(recipes_doc, "recipes.json", recipes, {})
	_index(items_doc, "items.json", items, {})
	_index(nodes_doc, "nodes.json", nodes, {})
	if constants_doc is Dictionary:
		constants = constants_doc
	_validate_constants()
	_validate_elements()
	_validate_materials()
	_validate_recipes()
	_validate_items()
	_validate_nodes()
	return errors


func _reset() -> void:
	errors.clear()
	elements.clear()
	materials.clear()
	recipes.clear()
	items.clear()
	nodes.clear()
	constants.clear()
	element_order.clear()
	_seen_ids.clear()
	_temperature_tier_ids.clear()
	_effects.clear()
	_costs.clear()
	_special_effects.clear()
	_axes.clear()


func _index(doc: Variant, label: String, target: Dictionary, order: Dictionary) -> void:
	if not doc is Dictionary:
		return
	var version: Variant = doc.get("schema_version", null)
	if version == null or int(version) != SCHEMA_VERSION:
		error("%s: schema_version 应为 %d，实际 %s" % [label, SCHEMA_VERSION, str(version)])
	var entries: Variant = doc.get("entries", null)
	if not entries is Array:
		error("%s: 缺少 entries 数组" % label)
		return
	var index := 0
	for entry in entries:
		if not entry is Dictionary:
			error("%s: entries[%d] 不是对象" % [label, index])
			index += 1
			continue
		var id_value: Variant = entry.get("id", null)
		if not id_value is String:
			error("%s: entries[%d] 缺少字符串 id" % [label, index])
			index += 1
			continue
		var id: String = id_value
		if _seen_ids.has(id):
			error("%s: 全库 ID 重复: %s" % [label, id])
		else:
			_seen_ids[id] = true
		if not target.has(id):
			target[id] = entry
			order[id] = index
		index += 1


func _validate_constants() -> void:
	if constants.is_empty():
		error("constants.json: 未载入")
		return
	var version: Variant = constants.get("schema_version", null)
	if version == null or int(version) != SCHEMA_VERSION:
		error("constants.json: schema_version 应为 %d" % SCHEMA_VERSION)
	_validate_vocabulary()
	_validate_reaction_constants()
	_validate_time_constants()
	_validate_device_constants()
	_validate_demo_constants()
	_validate_demand_constants()


func _validate_vocabulary() -> void:
	var vocabulary: Variant = constants.get("vocabulary", null)
	if not vocabulary is Dictionary:
		error("constants.json: 缺少 vocabulary 组")
		return
	_effects = _as_dictionary(vocabulary.get("effects", null), "vocabulary.effects")
	_costs = _as_dictionary(vocabulary.get("costs", null), "vocabulary.costs")
	_special_effects = _as_dictionary(vocabulary.get("special_effects", null), "vocabulary.special_effects")
	var axes: Variant = vocabulary.get("axes", null)
	if not axes is Dictionary:
		error("constants.json: 缺少 vocabulary.axes")
		return
	for axis_id in axes:
		var ends: Variant = axes[axis_id]
		if not ends is Array or ends.size() != 2:
			error("constants.json: 轴 %s 必须有两个端点" % str(axis_id))
			continue
		_axes[str(axis_id)] = ends


func _validate_reaction_constants() -> void:
	var reaction: Variant = constants.get("reaction", null)
	if not reaction is Dictionary:
		error("constants.json: 缺少 reaction 组")
		return
	for key in ["t_ref_c", "alpha", "axis_multiplier"]:
		if not _has_number(reaction, key):
			error("constants.json: reaction.%s 缺失" % key)
	var k_refs: Variant = reaction.get("k_ref_by_tier", null)
	if not k_refs is Dictionary:
		error("constants.json: reaction.k_ref_by_tier 缺失")
	else:
		for tier in range(1, MAX_TIER + 1):
			if not k_refs.has(str(tier)):
				error("constants.json: k_ref_by_tier 缺少阶 %d" % tier)
	var range_c: Variant = reaction.get("temperature_range_c", null)
	if not range_c is Array or range_c.size() != 2:
		error("constants.json: reaction.temperature_range_c 应为两个值")
	var tiers: Variant = reaction.get("temperature_tiers", null)
	if not tiers is Array or tiers.is_empty():
		error("constants.json: reaction.temperature_tiers 缺失")
		return
	for tier_entry in tiers:
		if not tier_entry is Dictionary:
			error("constants.json: temperature_tiers 含有非对象项")
			continue
		var tier_id: Variant = tier_entry.get("id", null)
		if not tier_id is String:
			error("constants.json: 温度档缺少 id")
			continue
		if _temperature_tier_ids.has(tier_id):
			error("constants.json: 温度档 ID 重复: %s" % str(tier_id))
		_temperature_tier_ids[str(tier_id)] = true
		var tier_range: Variant = tier_entry.get("range_c", null)
		if not tier_range is Array or tier_range.size() != 2:
			error("constants.json: 温度档 %s 的 range_c 无效" % str(tier_id))
		if not tier_entry.has("nominal_c") or not _is_number(tier_entry["nominal_c"]):
			error("constants.json: 温度档 %s 缺少 nominal_c" % str(tier_id))


func _validate_time_constants() -> void:
	var time_group: Variant = constants.get("time", null)
	if not time_group is Dictionary:
		error("constants.json: 缺少 time 组")
		return
	for key in ["real_seconds_per_game_hour", "day_start_hour", "day_end_hour", "season_days", "seasons_per_year"]:
		if not _has_number(time_group, key):
			error("constants.json: time.%s 缺失" % key)
	var minutes: Variant = time_group.get("craft_minutes_by_tier", null)
	if not minutes is Dictionary or not minutes.has("1"):
		error("constants.json: time.craft_minutes_by_tier 缺少阶 1")


func _validate_device_constants() -> void:
	var device: Variant = constants.get("device", null)
	if not device is Dictionary:
		error("constants.json: 缺少 device 组")
		return
	var default_id: Variant = device.get("default_id", null)
	if not default_id is String or not device.has(default_id):
		error("constants.json: device.default_id 不存在")
		return
	var info: Variant = device[default_id]
	if not info is Dictionary:
		error("constants.json: 默认设备条目不是对象")
		return
	if not info.has("temp_jitter_c") or not _is_number(info["temp_jitter_c"]):
		error("constants.json: 默认设备缺少 temp_jitter_c")
	elif float(info["temp_jitter_c"]) < 0.0:
		error("constants.json: temp_jitter_c 不能为负")


func _validate_demo_constants() -> void:
	var demo: Variant = constants.get("demo", null)
	if not demo is Dictionary:
		error("constants.json: 缺少 demo 组")
		return
	if not demo.has("world_seed") or not _is_number(demo["world_seed"]):
		error("constants.json: demo.world_seed 缺失")
	var starting: Variant = demo.get("starting_inventory", null)
	if not starting is Dictionary:
		error("constants.json: demo.starting_inventory 缺失")
		return
	for mat_id in starting:
		if not materials.has(mat_id):
			error("constants.json: demo.starting_inventory 引用了未知材料 %s" % str(mat_id))


func _validate_demand_constants() -> void:
	var demand: Variant = constants.get("demand", null)
	if not demand is Dictionary:
		error("constants.json: 缺少 demand 组")
		return
	for key in demand:
		var item: Variant = demand[key]
		if not item is Dictionary:
			error("constants.json: demand.%s 不是对象" % str(key))
			continue
		if not item.has("needs") or not item["needs"] is Dictionary:
			error("constants.json: demand.%s 缺少 needs" % str(key))


func _validate_elements() -> void:
	for id in elements:
		var entry: Dictionary = elements[id]
		var kind_value: Variant = entry.get("kind", null)
		if not kind_value is String or not (kind_value == "base" or kind_value == "compound"):
			error("elements.json: %s 的 kind 无效" % str(id))
			continue
		var tier_value: Variant = entry.get("tier", null)
		if not _is_number(tier_value) or int(tier_value) < 1 or int(tier_value) > MAX_TIER:
			error("elements.json: %s 的 tier 无效" % str(id))
		if not _has_number(entry, "delta_h"):
			error("elements.json: %s 缺少 delta_h" % str(id))
		if kind_value == "base":
			_validate_base_element(str(id), entry)
		else:
			_validate_compound_element(str(id), entry)
		_validate_effects(str(id), entry)
		_validate_costs(str(id), entry)
		_validate_special_effects(str(id), entry)


func _validate_base_element(id: String, entry: Dictionary) -> void:
	if not entry.has("h") or not _is_number(entry["h"]):
		error("elements.json: 基础元素 %s 缺少 h" % id)
		return
	if _has_number(entry, "delta_h"):
		if abs(float(entry["delta_h"]) - float(entry["h"])) > TOLERANCE:
			error("elements.json: %s 的 delta_h 与 h 不一致" % id)


func _validate_compound_element(id: String, entry: Dictionary) -> void:
	var composition: Variant = entry.get("composition", null)
	if not composition is Dictionary or composition.is_empty():
		error("elements.json: 化合物 %s 的 composition 为空" % id)
		return
	var total := 0.0
	for component_id in composition:
		var coefficient: Variant = composition[component_id]
		if not _is_number(coefficient) or float(coefficient) <= 0.0:
			error("elements.json: %s 的成分系数无效: %s" % [id, str(component_id)])
			continue
		if not elements.has(component_id):
			error("elements.json: %s 引用了未知成分 %s" % [id, str(component_id)])
			continue
		var component: Dictionary = elements[component_id]
		if not component.has("h") or not _is_number(component["h"]):
			error("elements.json: %s 的成分 %s 不是基础元素" % [id, str(component_id)])
			continue
		total += float(coefficient) * float(component["h"])
	if _has_number(entry, "delta_h"):
		if abs(float(entry["delta_h"]) - total) > TOLERANCE:
			error("elements.json: %s 的 delta_h = %.6f，应为 %.6f" % [id, float(entry["delta_h"]), total])
	var axis: Variant = entry.get("axis", null)
	if axis == null:
		return
	if not axis is String or not _axes.has(axis):
		error("elements.json: %s 的 axis 不在词表" % id)
		return
	var ends: Array = _axes[axis]
	var matches: bool = composition.size() == ends.size()
	if matches:
		for end_id in ends:
			if not composition.has(end_id):
				matches = false
				break
	if not matches:
		error("elements.json: %s 的成分与轴 %s 的两端不符" % [id, str(axis)])


func _validate_effects(id: String, entry: Dictionary) -> void:
	var effects: Variant = entry.get("effects", null)
	if not effects is Dictionary:
		error("elements.json: %s 缺少 effects" % id)
		return
	for effect_id in effects:
		if not _effects.has(effect_id):
			error("elements.json: %s 的 effects 键 %s 不在词表" % [id, str(effect_id)])
			continue
		var value: Variant = effects[effect_id]
		if not _is_number(value) or float(value) < 0.0 or float(value) > 1.0:
			error("elements.json: %s 的 %s 读数越界" % [id, str(effect_id)])


func _validate_costs(id: String, entry: Dictionary) -> void:
	var costs: Variant = entry.get("costs", null)
	if not costs is Dictionary:
		error("elements.json: %s 缺少 costs" % id)
		return
	for cost_id in costs:
		if not _costs.has(cost_id):
			error("elements.json: %s 的 costs 键 %s 不在词表" % [id, str(cost_id)])
			continue
		var value: Variant = costs[cost_id]
		if not _is_number(value) or float(value) < 0.0 or float(value) > 1.0:
			error("elements.json: %s 的 %s 读数越界" % [id, str(cost_id)])


func _validate_special_effects(id: String, entry: Dictionary) -> void:
	var special: Variant = entry.get("special_effects", null)
	if not special is Array:
		error("elements.json: %s 缺少 special_effects" % id)
		return
	for effect_id in special:
		if not effect_id is String or not _special_effects.has(effect_id):
			error("elements.json: %s 的 special_effects 含未知 ID %s" % [id, str(effect_id)])


func _validate_materials() -> void:
	for id in materials:
		var entry: Dictionary = materials[id]
		var total: Variant = entry.get("element_total", null)
		if not _is_number(total) or float(total) < MIN_ELEMENT_TOTAL or float(total) > MAX_ELEMENT_TOTAL:
			error("materials.json: %s 的 element_total 越界" % str(id))
		var spectrum: Variant = entry.get("spectrum", null)
		if not spectrum is Dictionary or spectrum.is_empty():
			error("materials.json: %s 缺少 spectrum" % str(id))
		else:
			var sum := 0.0
			for element_id in spectrum:
				var ratio: Variant = spectrum[element_id]
				if not elements.has(element_id):
					error("materials.json: %s 引用了未知元素 %s" % [str(id), str(element_id)])
				if not _is_number(ratio) or float(ratio) < 0.0 or float(ratio) > 1.0:
					error("materials.json: %s 的谱项 %s 越界" % [str(id), str(element_id)])
					continue
				sum += float(ratio)
			if abs(sum - 1.0) > TOLERANCE:
				error("materials.json: %s 的 spectrum 比例之和 = %.6f，应为 1" % [str(id), sum])
		var fluctuation: Variant = entry.get("fluctuation", null)
		if not _is_number(fluctuation) or float(fluctuation) <= 0.0 or float(fluctuation) > MAX_FLUCTUATION:
			error("materials.json: %s 的 fluctuation 越界" % str(id))
		var price: Variant = entry.get("price", null)
		if not _is_number(price) or float(price) < 0.0 or float(price) != floor(float(price)):
			error("materials.json: %s 的 price 应为非负整数" % str(id))


func _validate_recipes() -> void:
	for id in recipes:
		var entry: Dictionary = recipes[id]
		var inputs: Variant = entry.get("inputs", null)
		if not inputs is Dictionary or inputs.is_empty():
			error("recipes.json: %s 缺少 inputs" % str(id))
		else:
			for mat_id in inputs:
				if not materials.has(mat_id):
					error("recipes.json: %s 引用了未知材料 %s" % [str(id), str(mat_id)])
				var count: Variant = inputs[mat_id]
				if not _is_number(count) or int(count) < 1 or float(count) != floor(float(count)):
					error("recipes.json: %s 的 %s 份数无效" % [str(id), str(mat_id)])
		var tier: Variant = entry.get("temperature_tier", null)
		if not tier is String or not _temperature_tier_ids.has(tier):
			error("recipes.json: %s 的 temperature_tier 不在温度档表" % str(id))
		var duration: Variant = entry.get("duration_minutes", null)
		if not _is_number(duration) or int(duration) < 1 or float(duration) != floor(float(duration)):
			error("recipes.json: %s 的 duration_minutes 应为正整数" % str(id))
		var base_price: Variant = entry.get("base_price", null)
		if not _is_number(base_price) or float(base_price) < 0.0 or float(base_price) != floor(float(base_price)):
			error("recipes.json: %s 的 base_price 应为非负整数" % str(id))
		var target: Variant = entry.get("target", null)
		if target != null and (not target is String or not elements.has(target)):
			error("recipes.json: %s 的 target 不是已知元素" % str(id))


func _validate_items() -> void:
	for id in items:
		var entry: Dictionary = items[id]
		if not str(id).begins_with("itm_"):
			error("items.json: %s 缺少 itm_ 前缀" % str(id))
		if not entry.has("name") or not entry["name"] is String:
			error("items.json: %s 缺少字符串 name" % str(id))
		var category: Variant = entry.get("category", null)
		if not category is String or not (category == "potion" or category == "residue"):
			error("items.json: %s 的 category 无效" % str(id))
		if not entry.has("stackable") or not entry["stackable"] is bool:
			error("items.json: %s 的 stackable 应为布尔" % str(id))


func _validate_nodes() -> void:
	for id in nodes:
		var entry: Dictionary = nodes[id]
		if not str(id).begins_with("node_"):
			error("nodes.json: %s 缺少 node_ 前缀" % str(id))
		var material_id: Variant = entry.get("material_id", null)
		if not material_id is String or not materials.has(material_id):
			error("nodes.json: %s 的 material_id 不存在" % str(id))
		var tier: Variant = entry.get("tier", null)
		if not _is_number(tier) or int(tier) < 1 or int(tier) > MAX_GATHER_TIER:
			error("nodes.json: %s 的 tier 无效" % str(id))
		var scene: Variant = entry.get("scene", null)
		if not scene is String or not SCENES.has(scene):
			error("nodes.json: %s 的 scene 无效" % str(id))
		var position: Variant = entry.get("position", null)
		if not position is Dictionary:
			error("nodes.json: %s 缺少 position" % str(id))
		elif not _is_number(position.get("x")) or not _is_number(position.get("y")):
			error("nodes.json: %s 的 position 需要 x/y 数字" % str(id))
		var action: Variant = entry.get("action", null)
		if not action is String or not (action == "gather" or action == "chop_or_mine"):
			error("nodes.json: %s 的 action 无效" % str(id))
		var amount: Variant = entry.get("amount", null)
		if not _is_number(amount) or int(amount) < 1 or float(amount) != floor(float(amount)):
			error("nodes.json: %s 的 amount 应为正整数" % str(id))


func error(message: String) -> void:
	errors.append(message)


func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _has_number(dict: Dictionary, key: String) -> bool:
	return dict.has(key) and _is_number(dict[key])


func _as_dictionary(value: Variant, label: String) -> Dictionary:
	if value is Dictionary:
		return value
	error("constants.json: %s 应为对象" % label)
	return {}
