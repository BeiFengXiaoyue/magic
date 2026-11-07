extends RefCounted

## 感知阈值迁入 constants：同一产物在 total 0 / 4 / 6 下描述不同。


func run(ctx: TestContext) -> void:
	var db := ContentDatabase.new()
	db.load_all()
	if not db.errors.is_empty():
		ctx.check(false, "内容数据不干净：" + str(db.errors))
		return
	var perception := Perception.new(db)
	var result := CraftResult.new()
	result.dominant = "el_shengming"
	result.yield_ratio = 0.8

	var low := perception.describe(result, {"spirit_total": 0})
	var mid := perception.describe(result, {"spirit_total": 4})
	var high := perception.describe(result, {"spirit_total": 6})
	ctx.check(low != mid, "total 0 与 4 的描述应不同")
	ctx.check(mid != high, "total 4 与 6 的描述应不同")
	ctx.check(low.contains("隐约"), "低档应保留模糊描述")
	ctx.check(high.contains("清晰"), "高档应给出清晰描述")

	var tiers: Dictionary = db.constant("perception.spirit_tiers")
	ctx.check_eq(int(tiers.get("mid", 0)), 4, "感知中档阈值来自 constants")
	ctx.check_eq(int(tiers.get("high", 0)), 6, "感知高档阈值来自 constants")
