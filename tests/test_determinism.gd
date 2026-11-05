extends RefCounted

## 确定性：同种子逐字段一致；快照恢复后序列一致；换种子必变。


func run(ctx: TestContext) -> void:
	var db := ContentDatabase.new()
	db.load_all()
	if not db.errors.is_empty():
		ctx.check(false, "内容数据不干净：" + str(db.errors))
		return

	var first := _run_script(db, 9173271)
	var second := _run_script(db, 9173271)
	ctx.check(_same(first, second), "同种子重放应逐字段一致")

	var other := _run_script(db, 9173272)
	ctx.check(not _same(first, other), "换种子应改变结果")

	_test_snapshot(ctx)


func _run_script(db: ContentDatabase, seed_value: int) -> Dictionary:
	var rng := DeterministicRng.new()
	rng.init_world(seed_value)
	var clock := GameClock.new(db)
	var inventory := Inventory.new()
	inventory.add_material("mat_qinglucao", 3)
	inventory.add_material("mat_taiyi", 1)
	var solver := ReactionSolver.new(db)
	var process := CraftProcess.new(db, rng, solver)
	var use_case := CraftUseCase.new(db, clock, inventory, process, null)
	use_case.begin({ "mat_qinglucao": 3, "mat_taiyi": 1 }, "t_low_flame")
	use_case.tick(60)
	var result := use_case.take_out()
	return {
		"dominant": result.dominant,
		"composition": result.composition,
		"reading": result.reading,
		"yield": result.yield_ratio,
	}


func _same(a: Dictionary, b: Dictionary) -> bool:
	return (
		a.get("dominant") == b.get("dominant")
		and a.get("composition") == b.get("composition")
		and a.get("reading") == b.get("reading")
		and a.get("yield") == b.get("yield")
	)


func _test_snapshot(ctx: TestContext) -> void:
	for stream_name in DeterministicRng.STREAM_NAMES:
		var rng := DeterministicRng.new()
		rng.init_world(9173271)
		var stream := rng.stream(stream_name)
		for _i in 5:
			stream.randf()
		var snapshot := rng.snapshot()
		var first: Array[float] = []
		for _i in 5:
			first.append(stream.randf())
		rng.restore(snapshot)
		var second: Array[float] = []
		for _i in 5:
			second.append(stream.randf())
		ctx.check_eq(second, first, "快照恢复后随机序列应一致（%s）" % stream_name)
