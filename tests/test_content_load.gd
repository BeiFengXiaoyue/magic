extends RefCounted

## 内容载入：正例数量/表序/常量路径；负例验证错误被完整列出。


func run(ctx: TestContext) -> void:
	var db := ContentDatabase.new()
	db.load_all()
	ctx.check(db.errors.is_empty(), "内容载入应无错误：%s" % str(db.errors))
	ctx.check_eq(db.element_ids().size(), 21, "元素数量")
	ctx.check_eq(db.material_ids().size(), 12, "材料数量")
	ctx.check_eq(db.recipe_ids().size(), 2, "配方数量")
	ctx.check_eq(db.item_ids().size(), 2, "物品数量")
	ctx.check_eq(db.node_ids().size(), 3, "固定采集点数量")
	ctx.check_eq(str(db.item("itm_potion")["name"]), "药剂", "药剂显示名")
	ctx.check_eq(str(db.node("node_taiyi_01")["material_id"]), "mat_taiyi", "固定采集点材料")
	var forest := db.forest()
	ctx.check(not forest.is_empty(), "森林地图应载入")
	ctx.check_eq(int(forest["size"]["x"]), 3200, "森林宽度")
	ctx.check_eq(int(forest["size"]["y"]), 2400, "森林高度")
	var scenery: Array = forest.get("scenery", [])
	var zones: Array = forest.get("spawn_zones", [])
	var spawners: Array = forest.get("wild_spawners", [])
	ctx.check_eq(scenery.size(), 32, "定点景物数量")
	ctx.check_eq(zones.size(), 5, "刷新区域数量")
	ctx.check_eq(spawners.size(), 2, "野生刷新规则数量")
	ctx.check_eq(db.element_order("el_chiran"), 0, "炽燃表序")
	ctx.check_eq(db.element_order("el_zhengteng"), 6, "蒸腾表序")
	ctx.check_eq(db.element_order("el_beilun"), 20, "悖论表序")
	ctx.check_approx(float(db.constant("reaction.t_ref_c")), 200.0, 1e-9, "T_ref")
	ctx.check_eq(str(db.constant("device.default_id")), "dev_clay_crucible", "默认设备")
	_test_bad_content(ctx)


func _test_bad_content(ctx: TestContext) -> void:
	var dir := "user://test_bad_content"
	_clean_dir(dir)
	DirAccess.make_dir_recursive_absolute(dir)

	var elements := _load_json("res://content/elements.json")
	var entries: Array = elements["entries"]
	entries[0]["delta_h"] = 999.0
	entries.append(entries[0].duplicate(true))
	_write_json(dir.path_join("elements.json"), elements)

	var materials := _load_json("res://content/materials.json")
	var material_entries: Array = materials["entries"]
	material_entries[0]["spectrum"] = { "el_liuzhuan": 0.5 }
	_write_json(dir.path_join("materials.json"), materials)

	_write_json(dir.path_join("recipes.json"), _load_json("res://content/recipes.json"))
	var items := _load_json("res://content/items.json")
	items["entries"][0]["category"] = "bad"
	_write_json(dir.path_join("items.json"), items)
	var nodes := _load_json("res://content/nodes.json")
	nodes["entries"][0]["material_id"] = "mat_unknown"
	_write_json(dir.path_join("nodes.json"), nodes)
	var forest := _load_json("res://content/forest.json")
	forest["wild_spawners"][0]["material_id"] = "mat_unknown"
	forest["wild_spawners"][0]["habitats"] = ["no_zone"]
	_write_json(dir.path_join("forest.json"), forest)
	_write_json(dir.path_join("constants.json"), _load_json("res://content/constants.json"))

	var db := ContentDatabase.new()
	db.load_all(dir)
	ctx.check(not db.errors.is_empty(), "坏数据应被报告")
	ctx.check(_contains(db.errors, "ID 重复"), "应报告重复 ID")
	ctx.check(_contains(db.errors, "spectrum"), "应报告 spectrum 比例之和")
	ctx.check(_contains(db.errors, "delta_h"), "应报告 delta_h 不一致")
	ctx.check(_contains(db.errors, "category"), "应报告物品类别无效")
	ctx.check(_contains(db.errors, "material_id"), "应报告采集点材料不存在")
	ctx.check(_contains(db.errors, "habitat"), "应报告刷新区域缺失")
	_clean_dir(dir)


func _load_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}


func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "  "))
	file.close()


func _contains(messages: Array[String], needle: String) -> bool:
	for message in messages:
		if message.contains(needle):
			return true
	return false


func _clean_dir(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not name.begins_with("."):
			DirAccess.remove_absolute(dir_path.path_join(name))
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(dir_path)
