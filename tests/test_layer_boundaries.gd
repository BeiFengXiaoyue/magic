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
	_check_class_name_dependencies(ctx)


## 本项目 99% 的依赖通过 class_name 全局类完成，源码里没有 res:// 路径字符串。
## 这一段补上 class_name → 文件路径的映射，再按层检查引用方向。
func _check_class_name_dependencies(ctx: TestContext) -> void:
	var files := TestFiles.collect_gd_files("res://src")
	var class_to_path: Dictionary = {}
	for path in files:
		var class_name_value := _class_name_of(FileAccess.get_file_as_string(path))
		if class_name_value != "":
			class_to_path[class_name_value] = path
	ctx.check(not class_to_path.is_empty(), "应扫描到 class_name 声明")

	for path in files:
		var layer := _layer_of(path)
		if layer == "":
			continue
		var code := _strip_comments_and_strings(FileAccess.get_file_as_string(path))
		for class_name_value in class_to_path:
			var target: String = class_to_path[class_name_value]
			if target == path:
				continue
			var target_layer := _layer_of(target)
			if target_layer == "":
				continue
			if not code.contains(class_name_value):
				continue
			ctx.check(
				RANK[target_layer] <= RANK[layer],
				"%s 通过 class_name 向上依赖 %s" % [path, class_name_value]
			)
			if layer == "domain" and target_layer == "domain":
				ctx.check(
					_domain_of(path) == _domain_of(target),
					"%s 跨领域引用 %s" % [path, class_name_value]
				)


func _class_name_of(text: String) -> String:
	for line in text.split("\n"):
		var trimmed := line.strip_edges()
		if not trimmed.begins_with("class_name "):
			continue
		var rest := trimmed.trim_prefix("class_name ").strip_edges()
		var space := rest.find(" ")
		if space >= 0:
			rest = rest.substr(0, space)
		return rest
	return ""


func _strip_comments_and_strings(text: String) -> String:
	var out := ""
	for raw_line in text.split("\n"):
		var line := ""
		var index := 0
		var in_string := false
		var quote := ""
		while index < raw_line.length():
			var character := raw_line.substr(index, 1)
			if in_string:
				if character == "\\":
					index += 2
					continue
				if character == quote:
					in_string = false
				index += 1
				continue
			if character == "#":
				break
			if character == "\"" or character == "'":
				in_string = true
				quote = character
				index += 1
				continue
			line += character
			index += 1
		out += line + "\n"
	return out


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
