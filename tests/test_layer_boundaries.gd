extends RefCounted

## 依赖方向静态检查（契约 00 §2.2）：
## 禁词 + preload/load 路径图；domain 子域互不 import；events.gd 单独豁免 Node。

const RANK := {
	"core": 0,
	"domain": 1,
	"app": 2,
	"engine": 3,
}
const UI_WORDS: Array[String] = ["Button", "Label", "Control", "Container", "Panel"]


func run(ctx: TestContext) -> void:
	var files := TestFiles.collect_gd_files("res://src")
	ctx.check(not files.is_empty(), "应扫描到源文件")
	for path in files:
		var text := FileAccess.get_file_as_string(path)
		var layer := _layer_of(path)
		if layer == "":
			continue
		if layer != "engine" and path != "res://src/app/events.gd":
			ctx.check(not text.contains("extends Node"), "%s 不应 extends Node" % path)
		if layer != "engine":
			ctx.check(not text.contains("get_tree("), "%s 不应调用 get_tree()" % path)
			ctx.check(not text.contains(".tscn"), "%s 不应引用场景文件" % path)
		if layer == "app" and path != "res://src/app/events.gd":
			for word in UI_WORDS:
				ctx.check(not text.contains(word), "%s 不应包含界面控件 %s" % [path, word])
		for reference in _src_references(text):
			var target_layer := _layer_of(reference)
			if target_layer == "":
				continue
			ctx.check(
				RANK[target_layer] <= RANK[layer],
				"%s 向上依赖 %s" % [path, reference]
			)
			if layer == "domain" and target_layer == "domain":
				ctx.check(
					_domain_of(path) == _domain_of(reference),
					"%s 跨领域引用 %s" % [path, reference]
				)


func _layer_of(path: String) -> String:
	if path.begins_with("res://src/core/"):
		return "core"
	if path.begins_with("res://src/domain/"):
		return "domain"
	if path.begins_with("res://src/app/"):
		return "app"
	if path.begins_with("res://src/engine/"):
		return "engine"
	return ""


func _domain_of(path: String) -> String:
	var prefix := "res://src/domain/"
	if not path.begins_with(prefix):
		return ""
	var rest := path.trim_prefix(prefix)
	var slash := rest.find("/")
	if slash < 0:
		return ""
	return rest.substr(0, slash)


func _src_references(text: String) -> Array[String]:
	var regex := RegEx.new()
	regex.compile("\"res://src/[^\"]+\"")
	var out: Array[String] = []
	for found in regex.search_all(text):
		out.append(found.get_string().trim_prefix("\"").trim_suffix("\""))
	return out
