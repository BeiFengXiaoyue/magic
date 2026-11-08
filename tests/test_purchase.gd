extends RefCounted

## 商队器材：非到访日不卖、金币不足、买下即装备、重复购买、换装。


func run(ctx: TestContext) -> void:
	var db := ContentDatabase.new()
	db.load_all()
	if not db.errors.is_empty():
		ctx.check(false, "内容数据不干净：" + str(db.errors))
		return
	var clock := GameClock.new(db)
	var wallet := Wallet.new()
	var devices := DeviceState.new(db)
	var buy := BuyUseCase.new(db, clock, wallet, devices)

	ctx.check(not buy.is_caravan_day(), "第 1 天没有商队")
	ctx.check_eq(buy.offers().size(), 0, "非到访日没有器材")
	ctx.check_eq(str(buy.buy("dev_pressure_vessel").get("reason", "")), "no_caravan", "非到访日不能买")

	clock.day = 3
	ctx.check(buy.is_caravan_day(), "第 3 天商队到访")
	var offers := buy.offers()
	ctx.check_eq(offers.size(), 1, "商队带来一件器材")
	ctx.check_eq(str(offers[0].get("id", "")), "dev_pressure_vessel", "器材是加压器")
	ctx.check(not bool(offers[0].get("owned", true)), "初始未拥有")

	ctx.check_eq(str(buy.buy("dev_pressure_vessel").get("reason", "")), "poor", "没有金币买不了")
	wallet.add_gold(100)
	var bought := buy.buy("dev_pressure_vessel")
	ctx.check(bool(bought.get("bought", false)), "金币够即可买下")
	ctx.check_eq(int(bought.get("price", 0)), 60, "扣 60 金币")
	ctx.check_eq(wallet.gold, 40, "余额正确")
	ctx.check(devices.has_device("dev_pressure_vessel"), "记入已拥有")
	ctx.check_eq(devices.current_id(), "dev_pressure_vessel", "买下即装备")

	var again := buy.buy("dev_pressure_vessel")
	ctx.check_eq(str(again.get("reason", "")), "owned", "重复购买被拒绝")

	var refreshed := buy.offers()
	ctx.check(bool(refreshed[0].get("owned", false)), "货架标记已拥有")
	ctx.check(bool(refreshed[0].get("current", false)), "货架标记装备中")

	ctx.check(bool(buy.equip("dev_clay_crucible").get("ok", false)), "可换回陶土坩埚")
	ctx.check_eq(devices.current_id(), "dev_clay_crucible", "当前装备已切换")
	ctx.check_eq(str(buy.equip("dev_missing").get("reason", "")), "not_owned", "未拥有不能装备")
	ctx.check(buy.is_caravan_day(), "第 3 天仍是到访日")

	clock.day = 4
	ctx.check(not buy.is_caravan_day(), "第 4 天商队离开")
	clock.day = 10
	ctx.check(buy.is_caravan_day(), "第 10 天再来")

	var snapshot := devices.snapshot()
	var restored := DeviceState.new(db)
	restored.restore(snapshot)
	ctx.check(restored.has_device("dev_pressure_vessel"), "快照恢复已拥有")
	ctx.check_eq(restored.current_id(), "dev_clay_crucible", "快照恢复当前装备")
