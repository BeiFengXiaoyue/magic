extends RefCounted

## 信件确定性：相同动作序列快照逐字段一致；letters 流不被消费。


func run(ctx: TestContext) -> void:
	var db := ContentDatabase.new()
	db.load_all()
	if not db.errors.is_empty():
		ctx.check(false, "内容数据不干净：" + str(db.errors))
		return

	ctx.check_eq(_snapshots(db), _snapshots(db), "相同动作序列的快照应一致")

	var rng := DeterministicRng.new()
	rng.init_world(20261107)
	var before: Variant = rng.snapshot().get("letters", null)
	_snapshots(db)
	var after: Variant = rng.snapshot().get("letters", null)
	ctx.check_eq(after, before, "信件流程不应消费 letters 流")


func _snapshots(db: ContentDatabase) -> String:
	var clock := GameClock.new(db)
	var flags := Flags.new()
	var knowledge := Knowledge.new()
	var spirit := Spirituality.new(db)
	var journal := Journal.new(db, knowledge, Perception.new(db))
	var letters := LetterBook.new(db, clock, flags, knowledge, spirit, journal)
	var use_case := LetterUseCase.new(db, letters, journal, spirit, knowledge)

	use_case.refresh()
	use_case.open("ltr_L01")
	use_case.refresh()
	use_case.open("ltr_L02")
	use_case.refresh()
	use_case.open("ltr_L03")
	flags.set_flag("flg_first_sale")
	use_case.refresh()
	use_case.open("ltr_L04")
	use_case.refresh()
	use_case.open("ltr_L05")

	return JSON.stringify({
		"letters": letters.snapshot(),
		"journal": journal.snapshot(),
		"flags": flags.snapshot(),
		"spirit": spirit.snapshot(),
		"knowledge": knowledge.snapshot(),
	})
