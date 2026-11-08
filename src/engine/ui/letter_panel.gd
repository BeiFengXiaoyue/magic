class_name LetterPanel
extends VBoxContainer

## E7-lite：信纸阅读（契约 05 §7.1）。
## M3 没有任何火烤/蘸水/折叠/字谜/翻面按钮。

signal letter_selected(letter_id: String)
signal close_requested

const WIDTH := 980.0
const HEIGHT := 600.0
const LIST_WIDTH := 260.0

var _list: ItemList
var _ids: Array[String] = []
var _text: RichTextLabel
var _status_label: Label


func setup() -> void:
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	add_child(UiTheme.title("信件"))
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	add_child(row)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(LIST_WIDTH, 0.0)
	var list_title := UiTheme.label("已送达")
	list_title.add_theme_color_override("font_color", Color("#5c4b3a"))
	left.add_child(list_title)
	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_item_selected)
	_list.add_theme_color_override("font_color", Color("#2a211a"))
	_list.add_theme_color_override("font_selected_color", Color("#8c3a34"))
	left.add_child(_list)
	row.add_child(left)

	var paper := PanelContainer.new()
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var paper_box := VBoxContainer.new()
	paper.add_child(paper_box)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_color_override("default_color", Color("#2a211a"))
	paper_box.add_child(_text)
	row.add_child(paper)

	_status_label = UiTheme.label("")
	_status_label.add_theme_color_override("font_color", Color("#5c4b3a"))
	add_child(_status_label)
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(_on_close_pressed)
	add_child(close_button)


func show_list(entries: Array[Dictionary]) -> void:
	_ids.clear()
	_list.clear()
	for entry in entries:
		var status := str(entry.get("status", ""))
		var suffix := "  [新]" if status == "delivered" else ""
		_list.add_item("%s · %s%s" % [
			str(entry.get("title", "")),
			str(entry.get("author_name", "")),
			suffix,
		])
		_ids.append(str(entry.get("id", "")))
	if entries.is_empty():
		_text.text = "[i]这里还没有信。[/i]"
	else:
		_text.text = "[i]选择左侧的一封信。[/i]"


func show_letter(view: Dictionary) -> void:
	if view.is_empty():
		_text.text = "[i]没有可读的信。[/i]"
		return
	var lines: Array[String] = []
	lines.append("[b]%s[/b]" % str(view.get("title", "")))
	lines.append("作者：%s · 送达：%s" % [
		str(view.get("author_name", "")),
		str(view.get("delivery", "")),
	])
	lines.append("")
	lines.append(str(view.get("body", "")))
	var unlocks := _unlock_lines(view)
	if not unlocks.is_empty():
		lines.append("")
		lines.append("[b]你记下了[/b]")
		for line in unlocks:
			lines.append("· " + line)
	_text.text = "\n".join(lines)


func set_status(text: String) -> void:
	_status_label.text = text


func _unlock_lines(view: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for entry in view.get("unlocked_recipes", []):
		out.append("%s（配方）" % str(entry.get("name", "")))
	for entry in view.get("unlocked_concepts", []):
		out.append("%s（概念）" % str(entry.get("name", "")))
	for entry in view.get("unlocked_locations", []):
		out.append("%s（地点）" % str(entry.get("name", "")))
	for note in view.get("notes", []):
		out.append(str(note))
	return out


func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _ids.size():
		return
	letter_selected.emit(_ids[index])


func _on_close_pressed() -> void:
	close_requested.emit()
