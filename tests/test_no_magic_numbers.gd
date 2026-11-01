extends RefCounted

## 魔法数启发式扫描（契约 00 §8）：白名单 0 / 1 / -1 / 2。
## 必要豁免在同行写 "# no-magic-ok: 理由"。

const ALLOWED := [-1.0, 0.0, 1.0, 2.0]


func run(ctx: TestContext) -> void:
	var files: Array[String] = []
	files.append_array(TestFiles.collect_gd_files("res://src/core"))
	files.append_array(TestFiles.collect_gd_files("res://src/domain"))
	files.append_array(TestFiles.collect_gd_files("res://src/app"))
	ctx.check(not files.is_empty(), "应扫描到源文件")
	for path in files:
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for index in lines.size():
			var line: String = lines[index]
			if line.contains("# no-magic-ok:"):
				continue
			var code := _strip_comments_and_strings(line)
			for token in _number_tokens(code):
				var value := float(token)
				if not ALLOWED.has(value):
					ctx.check(false, "%s:%d 魔法数 %s" % [path, index + 1, token])


func _strip_comments_and_strings(line: String) -> String:
	var result := ""
	var index := 0
	var in_string := false
	var quote := ""
	while index < line.length():
		var character := line.substr(index, 1)
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
		result += character
		index += 1
	return result


func _number_tokens(code: String) -> Array[String]:
	var regex := RegEx.new()
	regex.compile("-?\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?")
	var out: Array[String] = []
	for found in regex.search_all(code):
		out.append(found.get_string())
	return out
