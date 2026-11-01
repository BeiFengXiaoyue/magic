extends RefCounted

## 求解器：温润汤剂、退热酊同 K 表序、多反应竞争、无可成对、火候差异。


func run(ctx: TestContext) -> void:
	var db := ContentDatabase.new()
	db.load_all()
	ctx.check(db.errors.is_empty(), "求解器测试需要干净的内容数据")
	var solver := ReactionSolver.new(db)

	var warm := solver.solve(
		{ "el_liuzhuan": 7.35, "el_ningding": 4.65 },
		{ "temperature_c": 90.0 }
	)
	ctx.check_eq(warm.dominant, "el_shengming", "温润汤剂主产物")
	ctx.check_approx(_effect(warm, "eff_xiufu"), 0.45, 0.06, "温润汤剂修复读数")
	ctx.check(warm.yield_ratio > 0.9, "温润汤剂产率应接近满")

	var fever := solver.solve(
		{ "el_liuzhuan": 4.2, "el_ningding": 1.8, "el_zhixu": 3.0 },
		{ "temperature_c": 200.0 }
	)
	ctx.check_eq(fever.dominant, "el_chengqing", "退热酊主产物")
	ctx.check_eq(str(fever.reaction_log[0]["compound"]), "el_shengming", "同 K 按表序生命先结合")
	ctx.check_approx(_effect(fever, "eff_zhonghe"), 0.26, 0.03, "退热酊中和读数")
	ctx.check_approx(_effect(fever, "eff_xiufu"), 0.24, 0.03, "退热酊修复读数")

	var competitive := solver.solve(
		{ "el_chiran": 3.0, "el_ningding": 1.0, "el_misan": 2.1, "el_zhixu": 0.9 },
		{ "temperature_c": 625.0 }
	)
	ctx.check_eq(str(competitive.reaction_log[0]["compound"]), "el_fenlie", "多反应先结合 K 最大的焚烈")

	var inert := solver.solve({ "el_ningding": 3.0 }, { "temperature_c": 200.0 })
	ctx.check_eq(inert.dominant, "", "无可成对时 dominant 为空")
	ctx.check_approx(float(inert.composition.get("el_ningding", 0.0)), 1.0, 1e-9, "无可成对时全部游离")
	ctx.check_approx(inert.yield_ratio, 0.0, 1e-9, "无化合物时产率为 0")

	var cold := solver.solve(
		{ "el_liuzhuan": 7.35, "el_ningding": 4.65 },
		{ "temperature_c": 90.0 }
	)
	var hot := solver.solve(
		{ "el_liuzhuan": 7.35, "el_ningding": 4.65 },
		{ "temperature_c": 625.0 }
	)
	var cold_ratio := float(cold.composition.get("el_shengming", 0.0))
	var hot_ratio := float(hot.composition.get("el_shengming", 0.0))
	ctx.check(abs(cold_ratio - hot_ratio) > 0.01, "同投料换火候应改变组成")


func _effect(result: CraftResult, effect_id: String) -> float:
	var effects: Dictionary = result.reading.get("effects", {})
	return float(effects.get(effect_id, 0.0))
