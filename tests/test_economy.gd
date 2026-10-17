extends RefCounted

## 经济：覆盖率算例与定价口径。基础池直接喂求解器，避开采集波动。


func run(ctx: TestContext) -> void:
	var db := ContentDatabase.new()
	db.load_all()
	ctx.check(db.errors.is_empty(), "经济测试需要干净的内容数据")
	var solver := ReactionSolver.new(db)
	var economy := Economy.new(db)

	var demand: Dictionary = db.constant("demand.spring_early")
	var ctx_data := {
		"season": 0,
		"reputation": "mid",
		"rolling_q": 0,
		"q_th": 10,
	}

	var warm := _product("rcp_wenrun_tangji", solver.solve(
		{ "el_liuzhuan": 7.35, "el_ningding": 4.65 },
		{ "temperature_c": 90.0 }
	))
	ctx.check_approx(Economy.coverage(warm.result.reading, demand), 0.58, 0.02, "温润汤剂覆盖率")
	ctx.check_eq(economy.cost_of(warm), 11, "温润汤剂材料成本")
	ctx.check(economy.list_price(warm, demand, ctx_data) > 0, "温润汤剂应有报价")

	var fever := _product("rcp_tuire_ding", solver.solve(
		{ "el_liuzhuan": 4.2, "el_ningding": 1.8, "el_zhixu": 3.0 },
		{ "temperature_c": 200.0 }
	))
	ctx.check_approx(Economy.coverage(fever.result.reading, demand), 0.62, 0.03, "退热酊覆盖率")
	ctx.check_eq(economy.cost_of(fever), 10, "退热酊材料成本")

	var mismatch := _product("", solver.solve(
		{ "el_liuzhuan": 6.3, "el_ningding": 2.7, "el_misan": 2.1, "el_zhixu": 0.9 },
		{ "temperature_c": 90.0 }
	))
	ctx.check(Economy.coverage(mismatch.result.reading, demand) < 0.5, "杂配酊覆盖率应低于门槛")
	ctx.check_eq(economy.cost_of(mismatch), 0, "乱投产物成本按 0 计")
	ctx.check_eq(economy.list_price(mismatch, demand, ctx_data), 0, "杂配酊应定价为 0")


func _product(recipe_id: String, result: CraftResult) -> ProductInstance:
	var product := ProductInstance.new()
	product.itm_id = "itm_potion"
	product.recipe_id = recipe_id
	product.result = result
	return product
