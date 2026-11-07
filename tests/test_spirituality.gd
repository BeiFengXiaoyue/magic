extends RefCounted

## K5 灵性：来源、P 只增、S/T 下限、每日衰减、层级、快照。


func run(ctx: TestContext) -> void:
	var db := ContentDatabase.new()
	db.load_all()
	if not db.errors.is_empty():
		ctx.check(false, "内容数据不干净：" + str(db.errors))
		return
	var spirit := Spirituality.new(db)
	ctx.check_eq(spirit.total(), 0, "初始灵性为 0")

	spirit.apply_source("read_mystic_letter")
	ctx.check_eq(spirit.t, 2, "读神秘信 T+2")
	spirit.add("P", 3, "test")
	ctx.check_eq(spirit.p, 3, "P 可增加")
	spirit.add("P", -1, "test")
	ctx.check_eq(spirit.p, 3, "P 不应减少")
	spirit.add("S", -10, "test")
	ctx.check_eq(spirit.s, 0, "S 下限 0")
	ctx.check_eq(spirit.total(), 5, "总值为 p+s+t")
	ctx.check_eq(spirit.perception_tier(), "mid", "total 5 应为 mid")

	spirit.on_day_passed()
	ctx.check_eq(spirit.t, 0, "每日 T-2 且不低于 0")
	ctx.check_eq(spirit.perception_tier(), "low", "total 3 应为 low")

	var snapshot := spirit.snapshot()
	spirit.restore({"p": 0, "s": 0, "t": 0})
	ctx.check_eq(spirit.total(), 0, "restore 后归零")
	spirit.restore(snapshot)
	ctx.check_eq(spirit.total(), 3, "快照往返一致")
