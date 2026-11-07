extends RefCounted

## O4 引导链：L01 → L02 → L03 → 炼制 → 卖出 → L04 → L05，含坩埚门禁。


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
	var interact := InteractUseCase.new(null, null, flags)

	ctx.check_eq(str(interact.handle("dev_clay_crucible").get("kind", "")), "message", "未读 L01 前锅是冷的")
	use_case.refresh()
	use_case.open("ltr_L01")
	ctx.check_eq(str(interact.handle("dev_clay_crucible").get("kind", "")), "panel", "读 L01 后锅可用")

	var delivered := use_case.refresh()
	ctx.check(delivered.has("ltr_L02") or letters.is_delivered("ltr_L02"), "L02 到达")
	use_case.open("ltr_L02")
	ctx.check_eq(journal.recipes_view().size(), 1, "手记出现温润汤剂")

	use_case.refresh()
	use_case.open("ltr_L03")
	ctx.check_eq(journal.locations_view().size(), 1, "手记出现稀有采集点")

	var rng := DeterministicRng.new()
	rng.init_world(int(db.constant("demo.world_seed")))
	var inventory := Inventory.new()
	inventory.add_material("mat_qinglucao", 6)
	inventory.add_material("mat_taiyi", 2)
	var craft := CraftUseCase.new(
		db, clock, inventory, CraftProcess.new(db, rng, ReactionSolver.new(db)),
		null, journal, spirit
	)
	ctx.check(craft.begin({"mat_qinglucao": 3, "mat_taiyi": 1}, "t_low_flame") != "", "第一炉开始")
	craft.tick(60)
	ctx.check(craft.take_out() != null, "第一炉取出")
	ctx.check_eq(journal.records_view().size(), 1, "取出后写一条手记")
	ctx.check_eq(str(journal.records_view()[0].get("format", "")), "prose", "L04 前是散记")

	var wallet := Wallet.new()
	var sell := SellUseCase.new(db, Economy.new(db), inventory, wallet, clock, null, flags)
	ctx.check(int(sell.quote(0).get("price", 0)) > 0, "温润汤剂可卖")
	ctx.check(bool(sell.sell(0).get("sold", false)), "卖出成功")
	ctx.check(flags.has("flg_first_sale"), "首次卖出置旗")

	delivered = use_case.refresh()
	ctx.check(delivered.has("ltr_L04") or letters.is_delivered("ltr_L04"), "首次卖出后 L04 到达")
	use_case.open("ltr_L04")
	ctx.check(knowledge.has("concept", "cpt_jilu_biaozhun"), "L04 解锁标准记录")

	craft.begin({"mat_qinglucao": 3, "mat_taiyi": 1}, "t_low_flame")
	craft.tick(60)
	ctx.check(craft.take_out() != null, "第二炉取出")
	ctx.check_eq(str(journal.records_view()[1].get("format", "")), "table", "L04 后新记录是标准表")

	use_case.refresh()
	use_case.open("ltr_L05")
	ctx.check(flags.has("flg_pressure_clue"), "L05 给出加压线索")
	ctx.check_eq(spirit.t, 8, "四封神秘信共 T+8")
