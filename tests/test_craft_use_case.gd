extends RefCounted

## O1 全流程：投料 → tick → 取出；扣料、入库、拒绝条件。


func run(ctx: TestContext) -> void:
	var db := ContentDatabase.new()
	db.load_all()
	ctx.check(db.errors.is_empty(), "用例测试需要干净的内容数据")

	var rng := DeterministicRng.new()
	rng.init_world(9173271)
	var clock := GameClock.new(db)
	var inventory := Inventory.new()
	inventory.add_material("mat_qinglucao", 3)
	inventory.add_material("mat_taiyi", 1)
	var solver := ReactionSolver.new(db)
	var process := CraftProcess.new(db, rng, solver)
	var use_case := CraftUseCase.new(db, clock, inventory, process, null)

	var session_id := use_case.begin({ "mat_qinglucao": 3, "mat_taiyi": 1 }, "t_low_flame")
	ctx.check(session_id != "", "开始炼制应返回 session_id")
	ctx.check_eq(inventory.count_material("mat_qinglucao"), 0, "投料应扣清露草")
	ctx.check_eq(inventory.count_material("mat_taiyi"), 0, "投料应扣苔衣")
	ctx.check(use_case.take_out() == null, "未完成时不能取出")
	ctx.check_eq(use_case.begin({}, "t_low_flame"), "", "炼制中不能重复开始")

	use_case.tick(60)
	var result := use_case.take_out()
	ctx.check(result != null, "完成后应能取出")
	if result != null:
		ctx.check_eq(result.dominant, "el_shengming", "取出产物应以生命为主")
	ctx.check_eq(inventory.products.size(), 1, "产物应写入库存")
	var product := inventory.product_at(0)
	ctx.check(product != null, "产物应为 ProductInstance")
	if product != null:
		ctx.check_eq(product.itm_id, "itm_potion", "成品物品大类")
		ctx.check_eq(product.recipe_id, "rcp_wenrun_tangji", "应记录匹配到的配方")
	ctx.check_eq(use_case.begin({ "mat_qinglucao": 3 }, "t_low_flame"), "", "库存不足应拒绝")
