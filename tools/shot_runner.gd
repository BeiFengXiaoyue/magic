extends SceneTree

## 截图脚本：依次截工坊 / 小店 / 森林到 tools/_preview/。
##   godot --path . --script res://tools/shot_runner.gd --resolution 1280x720

const SHOT_DIR := "res://tools/_preview"


func _initialize() -> void:
	var main: Node = load("res://src/engine/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred(main)


func _run(main: Node) -> void:
	await _settle()
	await _capture("_shot_workshop.png")
	main.call("_change_scene", "scene_shop")
	await _settle()
	await _capture("_shot_shop.png")
	main.call("_change_scene", "scene_forest")
	await _settle()
	await _capture("_shot_forest.png")
	quit(0)


func _settle() -> void:
	for _frame in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	await process_frame


func _capture(name: String) -> void:
	var image := root.get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, name])
	print("saved ", name)
