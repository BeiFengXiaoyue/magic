extends RefCounted

## K6 知识 + Flags：解锁顺序、重复 no-op、非法类别、快照往返。


func run(ctx: TestContext) -> void:
	var knowledge := Knowledge.new()
	knowledge.unlock("recipe", "rcp_wenrun_tangji")
	knowledge.unlock("concept", "cpt_huohou")
	knowledge.unlock("recipe", "rcp_wenrun_tangji")
	ctx.check_eq(knowledge.list("recipe").size(), 1, "重复解锁应为 no-op")
	ctx.check_eq(knowledge.list("recipe")[0], "rcp_wenrun_tangji", "配方顺序")
	ctx.check(knowledge.has("concept", "cpt_huohou"), "概念应已解锁")
	knowledge.unlock("bad", "x")
	ctx.check(not knowledge.has("bad", "x"), "非法类别应被忽略")

	var snapshot := knowledge.snapshot()
	knowledge.restore({})
	ctx.check_eq(knowledge.list("recipe").size(), 0, "restore 空快照")
	knowledge.restore(snapshot)
	ctx.check_eq(knowledge.list("concept").size(), 1, "知识快照往返")

	var flags := Flags.new()
	flags.set_flag("flg_crucible_unlocked")
	ctx.check(flags.has("flg_crucible_unlocked"), "旗标应存在")
	ctx.check_eq(flags.value("flg_crucible_unlocked"), true, "旗标值为 true")
	var flags_snapshot := flags.snapshot()
	flags.restore({})
	ctx.check(not flags.has("flg_crucible_unlocked"), "旗标快照清空")
	flags.restore(flags_snapshot)
	ctx.check(flags.has("flg_crucible_unlocked"), "旗标快照往返")
