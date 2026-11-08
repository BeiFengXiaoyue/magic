extends RefCounted

## 旧木箱分层：层顺序、条件解锁、开层幂等、快照恢复。


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
	var boxes := BoxBook.new(db, letters)

	var layers := boxes.layers("attic_box")
	ctx.check_eq(layers.size(), 3, "旧木箱应有三层")
	ctx.check_eq(int(layers[0].get("index", 0)), 1, "第一层编号")
	ctx.check_eq(str(layers[0].get("letter_id", "")), "ltr_L01", "第一层放 L01")
	ctx.check(bool(layers[0].get("unlocked", false)), "第一层初始可开")
	ctx.check(not bool(layers[1].get("unlocked", false)), "未读 L02 时中层锁着")
	ctx.check(not bool(layers[2].get("unlocked", false)), "底层锁着")

	var first := boxes.open_layer("attic_box", 1)
	ctx.check(bool(first.get("ok", false)), "第一层可打开")
	ctx.check_eq(str(first.get("letter_id", "")), "ltr_L01", "第一层给出 L01")
	ctx.check(bool(first.get("first_open", false)), "首次打开")
	ctx.check(bool(boxes.layers("attic_box")[0].get("opened", false)), "第一层记为已开")

	var again := boxes.open_layer("attic_box", 1)
	ctx.check(not bool(again.get("first_open", true)), "重复打开不重复记首次")

	var locked := boxes.open_layer("attic_box", 2)
	ctx.check_eq(str(locked.get("reason", "")), "locked", "中层未解锁不能开")
	ctx.check(not str(locked.get("hint", "")).is_empty(), "锁定层给出提示")

	knowledge.unlock("concept", "cpt_huohou")
	layers = boxes.layers("attic_box")
	ctx.check(bool(layers[1].get("unlocked", false)), "学会火候后中层解锁")
	ctx.check(not bool(layers[1].get("opened", false)), "中层尚未打开")
	var second := boxes.open_layer("attic_box", 2)
	ctx.check(bool(second.get("ok", false)), "中层可打开")
	ctx.check_eq(str(second.get("letter_id", "")), "", "中层本轮没有内容")
	ctx.check_eq(str(second.get("hint", "")), "空的。", "中层打开后显示空")

	ctx.check(not bool(boxes.layers("attic_box")[2].get("unlocked", false)), "底层仍需控制变量")

	var snapshot := boxes.snapshot()
	var restored := BoxBook.new(db, letters)
	restored.restore(snapshot)
	ctx.check(bool(restored.layers("attic_box")[0].get("opened", false)), "快照恢复第一层已开")
	ctx.check(bool(restored.layers("attic_box")[1].get("opened", false)), "快照恢复第二层已开")

	ctx.check_eq(boxes.layers("box_unknown").size(), 0, "未知容器返回空")
	ctx.check_eq(str(boxes.open_layer("box_unknown", 1).get("reason", "")), "unknown", "未知容器不可开")
