class_name BoxPanel
extends VBoxContainer

## 旧木箱：三层列表 + 选中层的内容。锁定的层显示 hint，不打开。
## 有信的层由引擎在右侧给“读这封信”按钮，点后交回信件面板。

signal layer_selected(index: int)
signal letter_requested(letter_id: String)
signal close_requested

const WIDTH := 760.0
const HEIGHT := 460.0
const LIST_WIDTH := 240.0

var _title: Label
var _list: ItemList
var _text: RichTextLabel
var _read_button: Button
var _status: Label
var _layers: Array[Dictionary] = []


func setup() -> void:
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	_title = UiTheme.title("旧木箱")
	add_child(_title)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	add_child(row)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(LIST_WIDTH, 0.0)
	var list_title := UiTheme.label("分层")
	list_title.add_theme_color_override("font_color", Color("#5c4b3a"))
	left.add_child(list_title)
	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_item_selected)
	_list.add_theme_color_override("font_color", Color("#2a211a"))
	_list.add_theme_color_override("font_selected_color", Color("#8c3a34"))
	_list.add_theme_stylebox_override("panel", _list_style())
	_list.add_theme_stylebox_override("selected", _selected_style())
	_list.add_theme_stylebox_override("selected_focus", _selected_style())
	left.add_child(_list)
	row.add_child(left)

	var paper := PanelContainer.new()
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paper.add_theme_stylebox_override("panel", _paper_style())
	var paper_box := VBoxContainer.new()
	paper_box.add_theme_constant_override("separation", 8)
	paper.add_child(paper_box)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_color_override("default_color", Color("#2a211a"))
	paper_box.add_child(_text)
	_read_button = Button.new()
	_read_button.text = "读这封信"
	_read_button.visible = false
	_read_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_read_button.pressed.connect(_on_read_pressed)
	paper_box.add_child(_read_button)
	row.add_child(paper)

	_status = UiTheme.label("")
	_status.add_theme_color_override("font_color", Color("#5c4b3a"))
	add_child(_status)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(_on_close_pressed)
	add_child(close_button)


func show_layers(view: Dictionary) -> void:
	_title.text = str(view.get("name", "旧木箱"))
	_layers.clear()
	_list.clear()
	_read_button.visible = false
	_text.text = "[i]选一层看看。[/i]"
	var raw: Variant = view.get("layers", [])
	if not raw is Array:
		return
	for layer in raw:
		if not layer is Dictionary:
			continue
		_layers.append(layer)
		_list.add_item(_layer_text(layer))
	_status.text = ""


func show_result(index: int, result: Dictionary, letter_title: String) -> void:
	var layer := _find_layer(index)
	if layer.is_empty():
		return
	var opened := bool(result.get("ok", false)) or bool(layer.get("opened", false))
	if opened:
		for i in _layers.size():
			if int(_layers[i].get("index", 0)) == index:
				_layers[i]["opened"] = true
				_list.set_item_text(i, _layer_text(_layers[i]))
				break
	if not bool(result.get("ok", false)):
		_text.text = "[i]%s[/i]" % str(result.get("hint", "推不开。"))
		_read_button.visible = false
		return
	var letter_id := str(result.get("letter_id", ""))
	if letter_id == "":
		_text.text = "[i]空的。[/i]"
		_read_button.visible = false
		return
	_text.text = "这层有一封信：\n[b]%s[/b]" % letter_title
	_read_button.visible = true
	_read_button.set_meta("letter_id", letter_id)


func set_status(text: String) -> void:
	_status.text = text


func _layer_text(layer: Dictionary) -> String:
	var label := str(layer.get("label", ""))
	if not bool(layer.get("unlocked", false)):
		return "%s · 锁" % label
	if bool(layer.get("opened", false)):
		return "%s · 已打开" % label
	return "%s · 未打开" % label


func _find_layer(index: int) -> Dictionary:
	for layer in _layers:
		if int(layer.get("index", 0)) == index:
			return layer
	return {}


func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _layers.size():
		return
	layer_selected.emit(int(_layers[index].get("index", 0)))


func _on_read_pressed() -> void:
	var letter_id := str(_read_button.get_meta("letter_id", ""))
	if letter_id != "":
		letter_requested.emit(letter_id)


func _on_close_pressed() -> void:
	close_requested.emit()


func _paper_style() -> StyleBoxFlat:
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


func _selected_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#b9aa8d")
	return style
