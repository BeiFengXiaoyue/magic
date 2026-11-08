class_name BackpackPanel
extends VBoxContainer

## 背包（I 键）：10×4 物品格，图标 + 数量；底部金币、需求与最近提示。

signal close_requested

const WIDTH := 780.0
const HEIGHT := 600.0
const COLUMNS := 10
const SLOT_COUNT := 40
const SLOT_SIZE := 52.0
const ICON_SIZE := 34.0

var _gold_label: Label
var _demand_label: Label
var _messages_label: Label
var _grid: GridContainer
var _slots: Array[PanelContainer] = []


func setup() -> void:
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	var header := HBoxContainer.new()
	header.add_child(UiTheme.title("背包"))
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)
	_gold_label = UiTheme.label("")
	_gold_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_gold_label.add_theme_color_override("font_color", Color("#2a211a"))
	header.add_child(_gold_label)
	add_child(header)

	var subtitle := UiTheme.label("材料 / 成品")
	subtitle.add_theme_color_override("font_color", Color("#5c4b3a"))
	add_child(subtitle)

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	var grid_center := CenterContainer.new()
	add_child(grid_center)
	grid_center.add_child(_grid)
	for _index in SLOT_COUNT:
		_slots.append(_make_slot())

	var footer := HBoxContainer.new()
	footer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(footer)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(info)
	_demand_label = UiTheme.label("")
	_demand_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_demand_label.add_theme_color_override("font_color", Color("#5c4b3a"))
	info.add_child(_demand_label)
	_messages_label = UiTheme.label("")
	_messages_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_messages_label.add_theme_color_override("font_color", Color("#2a211a"))
	info.add_child(_messages_label)
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.size_flags_vertical = Control.SIZE_SHRINK_END
	close_button.pressed.connect(_on_close_pressed)
	footer.add_child(close_button)


func refresh(view: Dictionary) -> void:
	_gold_label.text = "金币 %d" % int(view.get("gold", 0))
	_demand_label.text = str(view.get("demand", ""))
	var messages: Array = view.get("messages", [])
	var lines: Array[String] = []
	var start := maxi(0, messages.size() - 3)
	for index in range(start, messages.size()):
		lines.append("· " + str(messages[index]))
	_messages_label.text = "最近提示\n" + ("\n".join(lines) if not lines.is_empty() else "—")

	var items: Array = view.get("items", [])
	for index in _slots.size():
		var item: Dictionary = items[index] if index < items.size() else {}
		_fill_slot(_slots[index], item)


func _make_slot() -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#d6c8aa")
	style.border_color = Color("#6b4a2f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	style.content_margin_left = 2.0
	style.content_margin_right = 2.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	slot.add_theme_stylebox_override("panel", style)
	_grid.add_child(slot)
	return slot


func _fill_slot(slot: PanelContainer, item: Dictionary) -> void:
	for child in slot.get_children():
		slot.remove_child(child)
		child.queue_free()
	slot.tooltip_text = ""
	if item.is_empty():
		var empty := UiTheme.label("×")
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 18)
		empty.add_theme_color_override("font_color", Color("#b9a888"))
		empty.set_anchors_preset(Control.PRESET_CENTER)
		empty.offset_left = -10.0
		empty.offset_right = 10.0
		empty.offset_top = -12.0
		empty.offset_bottom = 12.0
		slot.add_child(empty)
		return
	var item_name := str(item.get("name", ""))
	var count := int(item.get("count", 1))
	var texture := ArtAssets.texture(str(item.get("art_id", "")))
	if texture != null:
		var icon := TextureRect.new()
		icon.texture = texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.set_anchors_preset(Control.PRESET_CENTER)
		icon.offset_left = -ICON_SIZE * 0.5
		icon.offset_right = ICON_SIZE * 0.5
		icon.offset_top = -ICON_SIZE * 0.5
		icon.offset_bottom = ICON_SIZE * 0.5
		slot.add_child(icon)
	else:
		var fallback := UiTheme.label(item_name.substr(0, 2))
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 14)
		fallback.add_theme_color_override("font_color", Color("#2a211a"))
		fallback.set_anchors_preset(Control.PRESET_CENTER)
		fallback.offset_left = -24.0
		fallback.offset_right = 24.0
		fallback.offset_top = -10.0
		fallback.offset_bottom = 10.0
		slot.add_child(fallback)
	if count > 1:
		var count_label := UiTheme.label("×%d" % count)
		count_label.add_theme_font_size_override("font_size", 12)
		count_label.add_theme_color_override("font_color", Color("#2a211a"))
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		count_label.offset_left = -30.0
		count_label.offset_right = -3.0
		count_label.offset_top = -18.0
		count_label.offset_bottom = -2.0
		slot.add_child(count_label)
	slot.tooltip_text = "%s ×%d" % [item_name, count]


func _on_close_pressed() -> void:
	close_requested.emit()
