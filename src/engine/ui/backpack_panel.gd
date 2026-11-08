class_name BackpackPanel
extends VBoxContainer

## 背包（I 键）：材料、成品、当前需求与最近提示。
## 常驻 HUD 不再显示需求/消息，统一在这里查看。

signal close_requested

const WIDTH := 760.0
const HEIGHT := 560.0

var _gold_label: Label
var _demand_label: Label
var _materials: VBoxContainer
var _products: VBoxContainer
var _messages: VBoxContainer


func setup() -> void:
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	add_child(UiTheme.title("背包"))
	_gold_label = UiTheme.label("")
	_gold_label.add_theme_color_override("font_color", Color("#2a211a"))
	add_child(_gold_label)
	_demand_label = UiTheme.label("")
	_demand_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_demand_label.add_theme_color_override("font_color", Color("#5c4b3a"))
	add_child(_demand_label)

	_materials = _section("材料")
	_products = _section("成品")
	_messages = _section("最近提示")

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(spacer)
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(_on_close_pressed)
	add_child(close_button)


func refresh(view: Dictionary) -> void:
	_gold_label.text = "金币 %d" % int(view.get("gold", 0))
	_demand_label.text = str(view.get("demand", ""))
	_fill_list(_materials, view.get("materials", []), "还没有材料。")
	_fill_list(_products, view.get("products", []), "还没有成品。")
	_fill_list(_messages, view.get("messages", []), "还没有提示。")


func _section(title: String) -> VBoxContainer:
	var label := UiTheme.label(title)
	label.add_theme_color_override("font_color", Color("#8c3a34"))
	add_child(label)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	add_child(box)
	return box


func _fill_list(box: VBoxContainer, entries: Array, empty_text: String) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
	if entries.is_empty():
		var empty := UiTheme.label(empty_text)
		empty.add_theme_color_override("font_color", Color("#5c4b3a"))
		box.add_child(empty)
		return
	for entry in entries:
		var line := UiTheme.label("· " + str(entry))
		line.add_theme_color_override("font_color", Color("#2a211a"))
		box.add_child(line)


func _on_close_pressed() -> void:
	close_requested.emit()
