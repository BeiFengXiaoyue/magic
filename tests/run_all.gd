extends SceneTree

## headless 测试入口：
##   godot --headless --path . --script res://tests/run_all.gd

const TESTS: Array[String] = [
	"res://tests/test_content_load.gd",
	"res://tests/test_art_assets.gd",
	"res://tests/test_reaction_solver.gd",
	"res://tests/test_economy.gd",
	"res://tests/test_craft_use_case.gd",
	"res://tests/test_wild_spawner.gd",
	"res://tests/test_gather_sell.gd",
	"res://tests/test_determinism.gd",
	"res://tests/test_scene_layout.gd",
	"res://tests/test_player_facing.gd",
	"res://tests/test_layer_boundaries.gd",
	"res://tests/test_no_magic_numbers.gd",
]


func _initialize() -> void:
	var ctx := TestContext.new()
	for path in TESTS:
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			ctx.check(false, "无法加载测试脚本 %s" % path)
			continue
		var instance = script.new()
		instance.run(ctx)
		print("[测试] %s" % path)

	if ctx.failures.is_empty():
		print("全部通过：%d 项检查" % ctx.checks)
		quit(0)
	else:
		for failure in ctx.failures:
			printerr("FAIL: " + failure)
		printerr("失败 %d / %d 项检查" % [ctx.failures.size(), ctx.checks])
		quit(1)
