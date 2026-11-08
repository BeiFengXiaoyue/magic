class_name LetterPanel
extends VBoxContainer

## E7-lite：信纸阅读（契约 05 §7.1）。
## M3 没有火烤/蘸水/折叠/翻面；读后可以选一句固定回信。

signal letter_selected(letter_id: String)
signal reply_selected(letter_id: String, option_id: String)
signal answer_selected(letter_id: String, concept_id: String)
signal close_requested

const WIDTH := 980.0
const HEIGHT := 600.0
const LIST_WIDTH := 260.0

var _list: ItemList
var _ids: Array[String] = []
var _text: RichTextLabel
var _status_label: Label
var _reply_box: VBoxContainer
var _puzzle_box: VBoxContainer
var _current_id: String = ""


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
	_list.add_theme_stylebox_override("panel", _list_style())
	_list.add_theme_stylebox_override("selected", _list_selected_style())
	_list.add_theme_stylebox_override("selected_focus", _list_selected_style())
	left.add_child(_list)
	row.add_child(left)

	var paper := PanelContainer.new()
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paper.add_theme_stylebox_override("panel", _reading_style())
	var paper_box := VBoxContainer.new()
	paper.add_child(paper_box)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_color_override("default_color", Color("#2a211a"))
	paper_box.add_child(_text)
	row.add_child(paper)

	_reply_box = VBoxContainer.new()
	_reply_box.add_theme_constant_override("separation", 6)
	add_child(_reply_box)

	_puzzle_box = VBoxContainer.new()
	_puzzle_box.add_theme_constant_override("separation", 6)
	add_child(_puzzle_box)

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
	_current_id = str(view.get("id", ""))
	var carrier := str(view.get("carrier", ""))
	var delivery_text := _delivery_name(str(view.get("delivery", "")))
	if carrier != "" and carrier != "box" and carrier != "door":
		delivery_text = "%s（信盘取件）" % _delivery_name(carrier)
	var lines: Array[String] = []
	lines.append("作者：%s · 送达：%s" % [
		str(view.get("author_name", "")),
		delivery_text,
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
	_refresh_reply(view)
	_refresh_puzzle(view)


func _refresh_puzzle(view: Dictionary) -> void:
	for child in _puzzle_box.get_children():
		_puzzle_box.remove_child(child)
		child.queue_free()
	var puzzle: Variant = view.get("puzzle", null)
	if not puzzle is Dictionary or puzzle.is_empty():
		return
	if bool(puzzle.get("solved", false)):
		var solved := UiTheme.label("谜底：%s" % str(puzzle.get("answer_label", "")))
		solved.add_theme_color_override("font_color", Color("#35632f"))
		_puzzle_box.add_child(solved)
		return
	var prompt := UiTheme.label("谜面：%s" % str(puzzle.get("prompt", "")))
	prompt.add_theme_color_override("font_color", Color("#5c4b3a"))
	_puzzle_box.add_child(prompt)
	var wordbank: Variant = puzzle.get("wordbank", [])
	if wordbank is Array and not wordbank.is_empty():
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 6)
		row.add_theme_constant_override("v_separation", 6)
		for item in wordbank:
			if not item is Dictionary:
				continue
			var button := Button.new()
			button.text = str(item.get("name", ""))
			button.pressed.connect(_on_answer_pressed.bind(str(item.get("id", ""))))
			row.add_child(button)
		_puzzle_box.add_child(row)
	var hint := str(puzzle.get("hint", ""))
	if hint != "":
		var hint_label := UiTheme.label("提示：%s" % hint)
		hint_label.add_theme_color_override("font_color", Color("#8c3a34"))
		_puzzle_box.add_child(hint_label)
	elif int(puzzle.get("attempts", 0)) > 0:
		var wrong := UiTheme.label("不对。再想想。")
		wrong.add_theme_color_override("font_color", Color("#8c3a34"))
		_puzzle_box.add_child(wrong)


func _on_answer_pressed(concept_id: String) -> void:
	if _current_id == "" or concept_id == "":
		return
	answer_selected.emit(_current_id, concept_id)


func _refresh_reply(view: Dictionary) -> void:
	for child in _reply_box.get_children():
		_reply_box.remove_child(child)
		child.queue_free()
	var reply: Variant = view.get("reply", null)
	if not reply is Dictionary or reply.is_empty():
		return
	var prompt := UiTheme.label(str(reply.get("prompt", "回信")))
	prompt.add_theme_color_override("font_color", Color("#5c4b3a"))
	_reply_box.add_child(prompt)
	if bool(reply.get("replied", false)):
		var sent := UiTheme.label("已回信：%s" % str(reply.get("reply_text", "")))
		sent.add_theme_color_override("font_color", Color("#35632f"))
		_reply_box.add_child(sent)
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var options: Variant = reply.get("options", [])
	if options is Array:
		for option in options:
			if not option is Dictionary:
				continue
			var button := Button.new()
			button.text = str(option.get("text", ""))
			button.pressed.connect(_on_reply_pressed.bind(str(option.get("id", ""))))
			row.add_child(button)
	_reply_box.add_child(row)


func _on_reply_pressed(option_id: String) -> void:
	if _current_id == "" or option_id == "":
		return
	reply_selected.emit(_current_id, option_id)


func _delivery_name(delivery: String) -> String:
	match delivery:
		"attic_box":
			return "旧木箱"
		"mail_tray":
			return "门口信盘"
		"caravan":
			return "商队"
		"door":
			return "门上"
		_:
			return delivery


func _reading_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#d3c8b0")
	style.border_color = Color("#9a8b70")
	style.set_border_width_all(2)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	return style


func _list_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#cfc4ad")
	style.border_color = Color("#9a8b70")
	style.set_border_width_all(2)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func _list_selected_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#b9aa8d")
	return style


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
