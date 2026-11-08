extends RefCounted

## L05 谜语：未读不能答、答错累计、五次给提示、十次直接给答案、答对发奖励。


func run(ctx: TestContext) -> void:
	var db := ContentDatabase.new()
	db.load_all()
	if not db.errors.is_empty():
		ctx.check(false, "内容数据不干净：" + str(db.errors))
		return
	var flags := Flags.new()
	var knowledge := Knowledge.new()
	var letters := _read_up_to_l05(db, flags, knowledge)

	var unread := LetterBook.new(
		db, GameClock.new(db), Flags.new(), Knowledge.new(),
		Spirituality.new(db), Journal.new(db, Knowledge.new(), Perception.new(db))
	)
	unread.refresh_arrivals()
	var not_read: Dictionary = unread.answer("ltr_L01", "cpt_yali")
	ctx.check_eq(str(not_read.get("reason", "")), "not_read", "未读不能答")

	var wrong := letters.answer("ltr_L05", "cpt_huohou")
	ctx.check_eq(str(wrong.get("reason", "")), "wrong", "答错")
	ctx.check(not bool(wrong.get("solved", true)), "答错未解")
	ctx.check_eq(str(wrong.get("hint", "")), "", "第一次答错不给提示")
	ctx.check_eq(letters.state("ltr_L05").puzzle_attempts, 1, "答错次数 +1")

	for _i in 3:
		letters.answer("ltr_L05", "cpt_pingheng")
	var fourth := letters.answer("ltr_L05", "cpt_nongdu")
	ctx.check(bool(fourth.get("hint", "") != ""), "第五次答错给提示")
	ctx.check(not bool(fourth.get("solved", true)), "给提示仍未解")

	ctx.check(not flags.has("flg_pressure_clue"), "答对前没有线索")
	ctx.check(not knowledge.has("concept", "cpt_kongzhi_li"), "答对前没有控制力")

	var right := letters.answer("ltr_L05", "cpt_yali")
	ctx.check(bool(right.get("solved", false)), "答对解谜")
	ctx.check(flags.has("flg_pressure_clue"), "答对解锁加压线索")
	ctx.check(knowledge.has("concept", "cpt_kongzhi_li"), "答对解锁控制力")
	ctx.check(letters.state("ltr_L05").puzzle_solved, "状态记为已解")

	var again := letters.answer("ltr_L05", "cpt_yali")
	ctx.check(bool(again.get("solved", false)), "重复作答返回已解")
	ctx.check_eq(letters.state("ltr_L05").puzzle_attempts, 5, "答对不再累计答错")

	var snapshot := letters.snapshot()
	var restored := LetterBook.new(
		db, GameClock.new(db), Flags.new(), Knowledge.new(),
		Spirituality.new(db), Journal.new(db, Knowledge.new(), Perception.new(db))
	)
	restored.restore(snapshot)
	ctx.check(restored.state("ltr_L05").puzzle_solved, "快照恢复谜语已解")
	ctx.check_eq(restored.state("ltr_L05").puzzle_attempts, 5, "快照恢复答错次数")

	_test_fallback(ctx, db)


func _test_fallback(ctx: TestContext, db: ContentDatabase) -> void:
	var letters := _read_up_to_l05(db, Flags.new(), Knowledge.new())
	var last: Dictionary = {}
	for _i in 10:
		last = letters.answer("ltr_L05", "cpt_huohou")
	ctx.check(bool(last.get("solved", false)), "十次答错直接给答案")
	ctx.check(bool(last.get("revealed", false)), "十次答错标记为揭示")
	ctx.check(letters.state("ltr_L05").puzzle_solved, "十次后状态为已解")


func _read_up_to_l05(db: ContentDatabase, flags: Flags, knowledge: Knowledge) -> LetterBook:
	var clock := GameClock.new(db)
	var spirit := Spirituality.new(db)
	var journal := Journal.new(db, knowledge, Perception.new(db))
	var letters := LetterBook.new(db, clock, flags, knowledge, spirit, journal)
	letters.refresh_arrivals()
	letters.open("ltr_L01")
	letters.refresh_arrivals()
	letters.open("ltr_L02")
	letters.refresh_arrivals()
	letters.open("ltr_L03")
	flags.set_flag("flg_first_sale")
	letters.refresh_arrivals()
	letters.open("ltr_L04")
	letters.refresh_arrivals()
	letters.open("ltr_L05")
	return letters
