extends RefCounted

## 回信：只有已读的信能回、选项写旗标、重复回信幂等、快照恢复。


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
	var use_case := LetterUseCase.new(db, letters, journal, spirit, knowledge)

	letters.refresh_arrivals()
	ctx.check_eq(str(letters.reply("ltr_L02", "rep_L02_thanks").get("reason", "")), "not_delivered", "未送达不能回")
	letters.open("ltr_L01")
	ctx.check_eq(str(letters.reply("ltr_L01", "rep_L02_thanks").get("reason", "")), "no_reply", "L01 没有回信选项")
	letters.refresh_arrivals()
	ctx.check_eq(str(letters.reply("ltr_L02", "rep_L02_thanks").get("reason", "")), "not_read", "未读不能回")

	letters.open("ltr_L02")
	ctx.check_eq(str(letters.reply("ltr_L02", "rep_missing").get("reason", "")), "bad_option", "未知选项")
	var sent := letters.reply("ltr_L02", "rep_L02_thanks")
	ctx.check(bool(sent.get("ok", false)), "L02 可回信")
	ctx.check_eq(str(sent.get("text", "")), "记下了，先试一炉。", "回信文本")
	ctx.check(flags.has("flg_replied_pol"), "回信写旗标")

	var again := letters.reply("ltr_L02", "rep_L02_thanks")
	ctx.check(bool(again.get("ok", false)), "重复回同一句仍成功")
	ctx.check_eq(str(again.get("reason", "")), "ok", "重复回同一句 reason ok")
	var other := letters.reply("ltr_L02", "rep_L02_why")
	ctx.check(not bool(other.get("ok", false)), "不能改成另一句")
	ctx.check_eq(str(other.get("reason", "")), "already", "改回信被拒绝")

	var view := use_case.letter_view("ltr_L02")
	var reply_view: Dictionary = view.get("reply", {})
	ctx.check(bool(reply_view.get("replied", false)), "视图标记已回信")
	ctx.check_eq(str(reply_view.get("reply_text", "")), "记下了，先试一炉。", "视图回信文本")
	ctx.check_eq((reply_view.get("options", []) as Array).size(), 2, "视图带两个回信选项")

	var snapshot := letters.snapshot()
	var restored := LetterBook.new(db, clock, flags, knowledge, spirit, journal)
	restored.restore(snapshot)
	ctx.check_eq(restored.state("ltr_L02").reply_id, "rep_L02_thanks", "快照恢复回信")
