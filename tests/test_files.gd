class_name TestFiles
extends RefCounted

## 测试用的文件工具：递归收集 .gd。


static func collect_gd_files(root: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(root)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not name.begins_with("."):
			var path := root.path_join(name)
			if dir.current_is_dir():
				out.append_array(collect_gd_files(path))
			elif name.ends_with(".gd"):
				out.append(path)
		name = dir.get_next()
	dir.list_dir_end()
	return out
