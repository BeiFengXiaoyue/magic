extends RefCounted

## 信件生命周期：压缩链到达、阅读幂等、首次卖出、L01 门禁旗标。


func run(ctx: TestContext) -> void:
	var db := ContentDatabase.new()
	db.load_all()
	if not db.errors.is_empty():
		ctx.check(false, "内容数据不干净：" + str(db.errors))
		return
	var clock := GameClock.new(db)
	var flags := Flags.new()
	var knowledge := Knowledge.new()
	var spirit := Spirituality.new(db)
	var journal := Journal.new(db, knowledge, Perception.new(db))
	var letters := LetterBook.new(db, clock, flags, knowledge, spirit, journal)

	var delivered := letters.refresh_arrivals()
	ctx.check_eq(delivered.size(), 1, "开局只投递 L01")
	ctx.check_eq(delivered[0], "ltr_L01", "开局投递的是 L01")
	ctx.check_eq(str(letters.open("ltr_L02").get("reason", "")), "not_delivered", "未投递不能读")
	ctx.check_eq(str(letters.open("ltr_L99").get("reason", "")), "unknown", "未知信")

	ctx.check_eq(str(letters.open("ltr_L01").get("reason", "")), "ok", "L01 可读")
	ctx.check(flags.has("flg_crucible_unlocked"), "L01 解锁坩埚")
	ctx.check_eq(spirit.t, 2, "L01 发灵性 T+2")
	letters.open("ltr_L01")
	ctx.check_eq(spirit.t, 2, "重复读不重复发灵性")

	delivered = letters.refresh_arrivals()
	ctx.check_eq(delivered.size(), 1, "L01 读后投递 L02")
	ctx.check_eq(delivered[0], "ltr_L02", "下一封是 L02")
	letters.open("ltr_L02")
	ctx.check(knowledge.has("recipe", "rcp_wenrun_tangji"), "L02 解锁温润汤剂")
	ctx.check(knowledge.has("concept", "cpt_huohou"), "L02 解锁火候")
	ctx.check_eq(spirit.t, 4, "L02 发灵性")

	letters.refresh_arrivals()
	letters.open("ltr_L03")
	ctx.check(knowledge.has("location", "node_qinglucao_rare_01"), "L03 标注稀有采集点")
	ctx.check_eq(journal.notes_view().size(), 2, "L03 写入两条线索")

	delivered = letters.refresh_arrivals()
	ctx.check_eq(delivered.size(), 0, "L04 需要首次卖出")
	flags.set_flag("flg_first_sale")
	delivered = letters.refresh_arrivals()
	ctx.check_eq(delivered.size(), 1, "首次卖出后投递 L04")
	ctx.check_eq(delivered[0], "ltr_L04", "下一封是 L04")
	letters.open("ltr_L04")
	ctx.check_eq(spirit.t, 6, "L04 机械线不发灵性")
	ctx.check(knowledge.has("concept", "cpt_jilu_biaozhun"), "L04 解锁标准记录")

	letters.refresh_arrivals()
	letters.open("ltr_L05")
	ctx.check(not flags.has("flg_pressure_clue"), "L05 未答谜语前无加压线索")
	letters.answer("ltr_L05", "cpt_yali")
	ctx.check(flags.has("flg_pressure_clue"), "答对后设置加压线索")
	ctx.check_eq(spirit.t, 8, "四封神秘信共 T+8")
	ctx.check_eq(spirit.perception_tier(), "high", "T=8 达到高档")

	var snapshot := letters.snapshot()
	var restored := LetterBook.new(db, clock, flags, knowledge, spirit, journal)
	restored.restore(snapshot)
	ctx.check_eq(restored.delivered_ids().size(), 5, "快照恢复后五封都在")
	ctx.check_eq(restored.unread_ids().size(), 0, "快照恢复后全部已读")
