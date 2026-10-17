extends RefCounted

## M2 闭环：采集 → 炼制 → 卖出；需求错配卖不掉。


func run(ctx: TestContext) -> void:
	var db := ContentDatabase.new()
	db.load_all()
	ctx.check(db.errors.is_empty(), "M2 测试需要干净的内容数据")

	var rng := DeterministicRng.new()
	rng.init_world(9173271)
	var clock := GameClock.new(db)
	var inventory := Inventory.new()
	var character := CharacterState.new(db)
	var wallet := Wallet.new()
	var solver := ReactionSolver.new(db)
	var gather_process := GatherProcess.new(db)
	var craft_process := CraftProcess.new(db, rng, solver)
	var economy := Economy.new(db)
	var gather := GatherUseCase.new(db, gather_process, inventory, character, clock, rng, null)
	var craft := CraftUseCase.new(db, clock, inventory, craft_process, null)
	var sell := SellUseCase.new(db, economy, inventory, wallet, clock, null)

	var sanity_before := character.sanity
	var minute_before := clock.minute_of_day
	var regrown_node := ""
	for node_id in ["node_qinglucao_01", "node_qinglucao_02", "node_taiyi_01"]:
		for _attempt in 10:
			var outcome := gather.gather(node_id)
			if bool(outcome["success"]):
				regrown_node = node_id
				break

	ctx.check(inventory.count_material("mat_qinglucao") >= 3, "应采到至少 3 份清露草")
	ctx.check(inventory.count_material("mat_taiyi") >= 1, "应采到至少 1 份苔衣")
	ctx.check(character.sanity < sanity_before, "采集应扣理智")
	ctx.check(clock.minute_of_day > minute_before, "采集应推进时间")
	if regrown_node != "":
		ctx.check_eq(str(gather.gather(regrown_node)["reason"]), "regrowing", "采集后节点应进入再生")

	var session_id := craft.begin({ "mat_qinglucao": 3, "mat_taiyi": 1 }, "t_low_flame")
	ctx.check(session_id != "", "应能开始炼制温润汤剂")
	craft.tick(60)
	var result := craft.take_out()
	ctx.check(result != null, "应能取出温润汤剂")
	ctx.check_eq(inventory.products.size(), 1, "产物应以 ProductInstance 入库存")
	var product := inventory.product_at(0)
	ctx.check(product != null, "库存里应有成品实例")
	if product != null:
		ctx.check_eq(product.itm_id, "itm_potion", "成品物品大类")
		ctx.check_eq(product.recipe_id, "rcp_wenrun_tangji", "应记录匹配到的配方")

	var quote := sell.quote(0)
	ctx.check(float(quote["coverage"]) > 0.5, "温润汤剂应满足需求")
	ctx.check(float(quote["price"]) > 0.0, "温润汤剂应有报价")
	var sold := sell.sell(0)
	ctx.check(bool(sold["sold"]), "温润汤剂应能卖出")
	ctx.check(wallet.gold > 0, "卖出应增加金币")
	ctx.check_eq(inventory.products.size(), 0, "卖出应移除成品")

	inventory.add_material("mat_qinglucao", 3)
	inventory.add_material("mat_fengshisha", 1)
	var mismatch_session := craft.begin({ "mat_qinglucao": 3, "mat_fengshisha": 1 }, "t_low_flame")
	ctx.check(mismatch_session != "", "应能开始炼制杂配酊")
	craft.tick(60)
	craft.take_out()
	var mismatch_quote := sell.quote(0)
	ctx.check(float(mismatch_quote["coverage"]) < 0.5, "杂配酊覆盖率应低于门槛")
	var mismatch_sold := sell.sell(0)
	ctx.check(not bool(mismatch_sold["sold"]), "杂配酊应卖不掉")
	ctx.check_eq(str(mismatch_sold["reason"]), "no_demand", "卖不掉原因")
