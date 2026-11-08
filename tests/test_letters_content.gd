extends RefCounted

## C5 数据检查：L01~L05 的字段、条件、解锁引用与 M3 禁字段。


func run(ctx: TestContext) -> void:
	var db := ContentDatabase.new()
	db.load_all()
	if not db.errors.is_empty():
		ctx.check(false, "内容数据不干净：" + str(db.errors))
		return
	ctx.check_eq(db.letter_ids().size(), 5, "Demo 应有 5 封信")
	var expected: Array[String] = ["ltr_L01", "ltr_L02", "ltr_L03", "ltr_L04", "ltr_L05"]
	for id in expected:
		ctx.check(db.has_letter(id), "缺少 %s" % id)

	var l01 := db.letter("ltr_L01")
	var l02 := db.letter("ltr_L02")
	var l03 := db.letter("ltr_L03")
	var l04 := db.letter("ltr_L04")
	var l05 := db.letter("ltr_L05")
	ctx.check(str(l01.get("body", "")).contains("致后来者"), "L01 正文")
	ctx.check(str(l02.get("body", "")).contains("凝定主修复"), "L02 正文")
	var puzzle: Dictionary = l05.get("puzzle", {})
	ctx.check_eq(str(puzzle.get("answer", "")), "cpt_yali", "L05 谜底是压力")
	ctx.check(not l05.has("unlocks"), "L05 的奖励挂在谜语上")
	ctx.check(l02.has("reply"), "L02 可回信")
	ctx.check(l03.has("reply"), "L03 可回信")
	ctx.check(l04.has("reply"), "L04 可回信")

	for entry in [l01, l02, l03, l04, l05]:
		ctx.check(not str(entry.get("title", "")).is_empty(), "标题非空")
		ctx.check(not str(entry.get("body", "")).is_empty(), "正文非空")
		ctx.check(not entry.has("deep"), "M3 不出现 deep")

	var l02_conditions: Array = l02["arrival"]["conditions"]["all"]
	ctx.check_eq(str(l02_conditions[0]["type"]), "after_letter", "L02 由 L01 触发")
	ctx.check_eq(str(l02_conditions[0]["id"]), "ltr_L01", "L02 after_letter 指向 L01")
	var l04_conditions: Array = l04["arrival"]["conditions"]["all"]
	ctx.check_eq(str(l04_conditions[0]["id"]), "ltr_L03", "L04 先要求 L03")
	ctx.check_eq(str(l04_conditions[1]["type"]), "flag", "L04 还要求首次卖出")
	ctx.check_eq(str(l04_conditions[1]["id"]), "flg_first_sale", "L04 旗标")

	ctx.check_eq(str(l02["unlocks"]["recipes"][0]), "rcp_wenrun_tangji", "L02 解锁温润汤剂")
	ctx.check_eq(str(l04["unlocks"]["recipes"][0]), "rcp_tuire_ding", "L04 解锁退热酊")
	ctx.check_eq(str(l03["unlocks"]["locations"][0]), "node_qinglucao_rare_01", "L03 标注稀有采集点")
	ctx.check(l04["spirituality"]["on_read"] == null, "L04 机械线不发灵性")
	ctx.check_eq(str(l02["spirituality"]["on_read"]), "read_mystic_letter", "L02 神秘线发灵性")

	var rare := db.node("node_qinglucao_rare_01")
	ctx.check_eq(int(rare.get("amount", 0)), 3, "稀有清露草份数")
	ctx.check_eq(str(rare.get("name", "")), "露根密丛", "稀有采集点显示名")
