extends RefCounted

## 手记：散记 → 标准表、旧条目格式固化、配方/地点/线索视图。


func run(ctx: TestContext) -> void:
	var db := ContentDatabase.new()
	db.load_all()
	if not db.errors.is_empty():
		ctx.check(false, "内容数据不干净：" + str(db.errors))
		return
	var knowledge := Knowledge.new()
	var journal := Journal.new(db, knowledge, Perception.new(db))
	var result := CraftResult.new()
	result.dominant = "el_shengming"
	result.yield_ratio = 0.8
	var craft_context := {
		"inputs": {"mat_qinglucao": 3, "mat_taiyi": 1},
		"tier_id": "t_low_flame",
		"duration_minutes": 60,
		"device_id": "dev_clay_crucible",
		"spirit_total": 0,
		"day": 1,
		"minute_of_day": 240,
	}

	var first := journal.add_craft_entry(result, craft_context)
	ctx.check_eq(str(first.get("format", "")), "prose", "L04 前为散记")
	ctx.check(str(first.get("text", "")).contains("微火"), "散记含火候名")
	ctx.check_eq(journal.record_format(), "prose", "记录法初始为散记")

	knowledge.unlock("concept", "cpt_jilu_biaozhun")
	ctx.check_eq(journal.record_format(), "table", "L04 后切标准表")
	var second := journal.add_craft_entry(result, craft_context)
	ctx.check_eq(str(second.get("format", "")), "table", "新条目用标准表")
	var columns: Dictionary = second.get("columns", {})
	ctx.check_eq(columns.get("pressure", "missing"), null, "压力列恒为 null")
	ctx.check(str(columns.get("conditions", "")).contains("陶土坩埚"), "条件列含设备")
	ctx.check_eq(str(journal.records_view()[0].get("format", "")), "prose", "旧条目格式不变")

	journal.add_note("南坡湿地：清露草（野生）", "ltr_L03")
	ctx.check_eq(journal.notes_view().size(), 1, "线索写入")

	knowledge.unlock("recipe", "rcp_wenrun_tangji")
	ctx.check_eq(journal.recipes_view().size(), 1, "配方页只列已解锁配方")
	knowledge.unlock("location", "node_qinglucao_rare_01")
	var locations := journal.locations_view()
	ctx.check_eq(locations.size(), 1, "地点页列出已知采集点")
	ctx.check_eq(str(locations[0].get("name", "")), "露根密丛", "地点显示名")

	var snapshot := journal.snapshot()
	var restored := Journal.new(db, knowledge, Perception.new(db))
	restored.restore(snapshot)
	ctx.check_eq(restored.records_view().size(), 2, "手记快照恢复条目")
	ctx.check_eq(str(restored.records_view()[0].get("format", "")), "prose", "恢复后旧格式不变")
