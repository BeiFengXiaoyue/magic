class_name JournalPanel
extends VBoxContainer

## E3：手记（契约 05 §7.2）。
## 配方页 / 记录页；记录按条目自己的 format 渲染，压力列恒为灰色「—」。

signal close_requested

const WIDTH := 900.0
const HEIGHT := 600.0

var _tabs: TabContainer
var _recipes: RichTextLabel
var _records: RichTextLabel


func setup() -> void:
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	add_child(UiTheme.title("手记"))
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_tabs)
	_recipes = _make_page("配方")
	_records = _make_page("记录")
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(_on_close_pressed)
	add_child(close_button)


func show_page(page: String) -> void:
	_tabs.current_tab = 0 if page == "recipes" else 1


func refresh_recipes(recipes: Array[Dictionary]) -> void:
	var lines: Array[String] = []
	if recipes.is_empty():
		lines.append("[i]还没有记下任何配方。读信会打开配方页。[/i]")
	for recipe in recipes:
		lines.append("[b]%s[/b]" % str(recipe.get("name", "")))
		lines.append("投料：%s" % str(recipe.get("inputs_text", "")))
		lines.append("火候：%s · %d 分钟 · 来源：%s" % [
			str(recipe.get("tier_name", "")),
			int(recipe.get("duration_minutes", 0)),
			str(recipe.get("source_letter", "")),
		])
		lines.append("")
	_recipes.text = "\n".join(lines)


func refresh_records(view: Dictionary) -> void:
	var lines: Array[String] = []
	lines.append("记录法：%s" % ("标准表（L04）" if str(view.get("format", "prose")) == "table" else "散记"))
	lines.append("")
	var records: Array = view.get("records", [])
	if records.is_empty():
		lines.append("[i]还没有炼制记录。[/i]")
	for record in records:
		lines.append("[b]第 %d 天[/b]" % int(record.get("day", 0)))
		if str(record.get("format", "")) == "table":
			var columns: Dictionary = record.get("columns", {})
			lines.append("改了什么：%s" % str(columns.get("changed", "")))
			lines.append("其他条件：%s" % str(columns.get("conditions", "")))
			lines.append("结果：%s" % str(columns.get("result", "")))
			lines.append("压力：[color=#6E6A63]—[/color]")
		else:
			lines.append(str(record.get("text", "")))
		lines.append("")
	var locations: Array = view.get("locations", [])
	if not locations.is_empty():
		lines.append("[b]已知采集点[/b]")
		for location in locations:
			lines.append("· %s（%s）— %s" % [
				str(location.get("name", "")),
				str(location.get("material_name", "")),
				str(location.get("journal_hint", "")),
			])
		lines.append("")
	var notes: Array = view.get("notes", [])
	if not notes.is_empty():
		lines.append("[b]线索[/b]")
		for note in notes:
			lines.append("· " + str(note.get("text", "")))
	_records.text = "\n".join(lines)


func _make_page(title: String) -> RichTextLabel:
	var scroll := ScrollContainer.new()
	scroll.name = title
	_tabs.add_child(scroll)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.scroll_active = true
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.add_theme_color_override("default_color", Color("#2a211a"))
	scroll.add_child(text)
	return text


func _on_close_pressed() -> void:
	close_requested.emit()
