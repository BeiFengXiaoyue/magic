extends RefCounted

## M2 闭环：采集（固定 + 野生）→ 炼制 → 卖出；需求错配卖不掉。


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
	var wild := WildSpawner.new(db, rng)
	var gather := GatherUseCase.new(
		db, gather_process, inventory, character, clock, rng, wild, null
	)
	var craft := CraftUseCase.new(db, clock, inventory, craft_process, null)
	var sell := SellUseCase.new(db, economy, inventory, wallet, clock, null)

	var sanity_before := character.sanity
	var minute_before := clock.minute_of_day
	_gather_wild(ctx, gather, inventory, "mat_qinglucao", 6, "清露草")
	_gather_wild(ctx, gather, inventory, "mat_fengshisha", 1, "风蚀砂")
	_gather_fixed(ctx, gather, inventory, "node_taiyi_01", "mat_taiyi", 1, "苔衣")

	ctx.check(character.sanity < sanity_before, "采集应扣理智")
	ctx.check(clock.minute_of_day > minute_before, "采集应推进时间")
	ctx.check_eq(str(gather.gather("node_taiyi_01")["reason"]), "regrowing", "固定点采集后应再生")

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

	var mismatch_session := craft.begin({ "mat_qinglucao": 3, "mat_fengshisha": 1 }, "t_low_flame")
	ctx.check(mismatch_session != "", "应能开始炼制杂配酊")
	craft.tick(60)
	craft.take_out()
	var mismatch_quote := sell.quote(0)
	ctx.check(float(mismatch_quote["coverage"]) < 0.5, "杂配酊覆盖率应低于门槛")
	var mismatch_sold := sell.sell(0)
	ctx.check(not bool(mismatch_sold["sold"]), "杂配酊应卖不掉")
	ctx.check_eq(str(mismatch_sold["reason"]), "no_demand", "卖不掉原因")


func _gather_wild(
	ctx: TestContext,
	gather: GatherUseCase,
	inventory: Inventory,
	material_id: String,
	required: int,
	label: String
) -> void:
	var attempts := 0
	while inventory.count_material(material_id) < required and attempts < 60:
		attempts += 1
		var target: Dictionary = {}
		for entry in gather.wild_nodes("scene_forest"):
			if str(entry.get("material_id", "")) == material_id:
				target = entry
				break
		if target.is_empty():
			break
		gather.gather(str(target["id"]))
	ctx.check(
		inventory.count_material(material_id) >= required,
		"应采到足够的%s（实际 %d）" % [label, inventory.count_material(material_id)]
	)


func _gather_fixed(
	ctx: TestContext,
	gather: GatherUseCase,
	inventory: Inventory,
	node_id: String,
	material_id: String,
	required: int,
	label: String
) -> void:
	var attempts := 0
	while inventory.count_material(material_id) < required and attempts < 20:
		attempts += 1
		var result := gather.gather(node_id)
		if str(result.get("reason", "")) == "regrowing":
			break
	ctx.check(
		inventory.count_material(material_id) >= required,
		"应采到足够的%s（实际 %d）" % [label, inventory.count_material(material_id)]
	)
