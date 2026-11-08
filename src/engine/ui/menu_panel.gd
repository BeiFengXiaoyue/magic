class_name MenuPanel
extends VBoxContainer

## 星露谷式页签菜单：物品 / 信息 / 需求 / 信件 / 委托。
## 物品页：10×4 物品格 + 装备栏 + 金币/日期；打开时隐藏 HUD。

signal close_requested
signal letter_selected(letter_id: String)

const WIDTH := 920.0
const HEIGHT := 640.0
const COLUMNS := 10
const SLOT_COUNT := 40
const SLOT_SIZE := 52.0
const ICON_SIZE := 34.0

var _tabs: TabContainer
var _grid: GridContainer
var _slots: Array[PanelContainer] = []
var _equipment_slots: Array[PanelContainer] = []
var _gold_label: Label
var _date_label: Label
var _demand_short: Label
var _info_label: Label
var _messages_label: Label
var _demand_detail: RichTextLabel
var _letters_list: ItemList
var _letter_ids: Array[String] = []
var _letter_body: RichTextLabel


func setup() -> void:
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	var header := HBoxContainer.new()
	header.add_child(UiTheme.title("手记与背包"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	add_child(header)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_tabs)
	_build_items_page()
	_build_info_page()
	_build_demand_page()
	_build_letters_page()
	_build_commissions_page()
	_style_tabs()

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_button.pressed.connect(_on_close_pressed)
	add_child(close_button)


func show_page(page: String) -> void:
	var index := 0
	match page:
		"info":
			index = 1
		"demand":
			index = 2
		"letters":
			index = 3
		"commissions":
			index = 4
	_tabs.current_tab = index


func refresh(view: Dictionary) -> void:
	var info: Dictionary = view.get("info", {})
	_gold_label.text = "金币 %d" % int(info.get("gold", 0))
	_date_label.text = "%s · %s" % [str(info.get("date", "")), str(info.get("time", ""))]
	_demand_short.text = str(view.get("demand_short", ""))
	_info_label.text = "\n".join([
		"地点：%s" % str(info.get("location", "")),
		"日期：%s" % str(info.get("date", "")),
		"时间：%s" % str(info.get("time", "")),
		"生命：%d    理智：%d" % [int(info.get("hp", 0)), int(info.get("sanity", 0))],
		"金币：%d" % int(info.get("gold", 0)),
		"未读信：%d" % int(info.get("unread", 0)),
	])
	_demand_detail.text = str(view.get("demand_detail", ""))
	var messages: Array = view.get("messages", [])
	var lines: Array[String] = []
	var start := maxi(0, messages.size() - 5)
	for index in range(start, messages.size()):
		lines.append("· " + str(messages[index]))
	_messages_label.text = "最近提示\n" + ("\n".join(lines) if not lines.is_empty() else "—")
	_fill_slots(view.get("items", []))
	_fill_letters(view.get("letters", []))


func show_letter(view: Dictionary) -> void:
	if view.is_empty():
		_letter_body.text = "[i]选择左侧的一封信。[/i]"
		return
	var text := "[b]%s[/b]\n\n作者：%s\n\n%s" % [
		str(view.get("title", "")),
		str(view.get("author_name", "")),
		str(view.get("body", "")),
	]
	_letter_body.text = text


func _build_items_page() -> void:
	var page := VBoxContainer.new()
	page.name = "物品"
	_tabs.add_child(page)

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	page.add_child(_grid)
	for _index in SLOT_COUNT:
		_slots.append(_make_slot(_grid))

	var equip_title := UiTheme.label("装备")
	equip_title.add_theme_color_override("font_color", Color("#5c4b3a"))
	page.add_child(equip_title)
	var equip_row := HBoxContainer.new()
	equip_row.add_theme_constant_override("separation", 10)
	page.add_child(equip_row)
	for title in ["护甲", "饰品", "饰品"]:
		var column := VBoxContainer.new()
		var caption := UiTheme.label(title)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 12)
		caption.add_theme_color_override("font_color", Color("#5c4b3a"))
		column.add_child(caption)
		var slot := _make_slot(column)
		_equipment_slots.append(slot)
		equip_row.add_child(column)

	var footer := HBoxContainer.new()
	page.add_child(footer)
	_demand_short = UiTheme.label("")
	_demand_short.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_demand_short.add_theme_color_override("font_color", Color("#5c4b3a"))
	footer.add_child(_demand_short)
	_gold_label = UiTheme.label("")
	_gold_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_gold_label.add_theme_color_override("font_color", Color("#2a211a"))
	footer.add_child(_gold_label)
	var date_spacer := Control.new()
	date_spacer.custom_minimum_size = Vector2(16.0, 0.0)
	footer.add_child(date_spacer)
	_date_label = UiTheme.label("")
	_date_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_date_label.add_theme_color_override("font_color", Color("#2a211a"))
	footer.add_child(_date_label)


func _build_info_page() -> void:
	var page := VBoxContainer.new()
	page.name = "信息"
	_tabs.add_child(page)
	_info_label = UiTheme.label("")
	_info_label.add_theme_color_override("font_color", Color("#2a211a"))
	page.add_child(_info_label)
	_messages_label = UiTheme.label("")
	_messages_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_messages_label.add_theme_color_override("font_color", Color("#2a211a"))
	page.add_child(_messages_label)


func _build_demand_page() -> void:
	var page := VBoxContainer.new()
	page.name = "需求"
	_tabs.add_child(page)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	_demand_detail = RichTextLabel.new()
	_demand_detail.bbcode_enabled = true
	_demand_detail.scroll_active = true
	_demand_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_demand_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_demand_detail.add_theme_color_override("default_color", Color("#2a211a"))
	scroll.add_child(_demand_detail)


func _build_letters_page() -> void:
	var page := VBoxContainer.new()
	page.name = "信件"
	_tabs.add_child(page)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(row)
	_letters_list = ItemList.new()
	_letters_list.custom_minimum_size = Vector2(260.0, 0.0)
	_letters_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_letters_list.add_theme_color_override("font_color", Color("#2a211a"))
	_letters_list.add_theme_color_override("font_selected_color", Color("#8c3a34"))
	var list_style := StyleBoxFlat.new()
	list_style.bg_color = Color("#d6c8aa")
	list_style.border_color = Color("#6b4a2f")
	list_style.set_border_width_all(2)
	_letters_list.add_theme_stylebox_override("panel", list_style)
	_letters_list.add_theme_stylebox_override("focus", list_style)
	_letters_list.item_selected.connect(_on_letter_selected)
	row.add_child(_letters_list)
	_letter_body = RichTextLabel.new()
	_letter_body.bbcode_enabled = true
	_letter_body.scroll_active = true
	_letter_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_letter_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_letter_body.add_theme_color_override("default_color", Color("#2a211a"))
	row.add_child(_letter_body)
	_letter_body.text = "[i]选择左侧的一封信。[/i]"


func _style_tabs() -> void:
	_tabs.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var bar := _tabs.get_tab_bar()
	var selected := StyleBoxFlat.new()
	selected.bg_color = Color("#d6c8aa")
	selected.border_color = Color("#8c3a34")
	selected.set_border_width_all(2)
	selected.content_margin_left = 10.0
	selected.content_margin_right = 10.0
	selected.content_margin_top = 4.0
	selected.content_margin_bottom = 4.0
	var unselected := StyleBoxFlat.new()
	unselected.bg_color = Color("#b9a888")
	unselected.border_color = Color("#6b4a2f")
	unselected.set_border_width_all(1)
	unselected.content_margin_left = 10.0
	unselected.content_margin_right = 10.0
	unselected.content_margin_top = 4.0
	unselected.content_margin_bottom = 4.0
	bar.add_theme_stylebox_override("tab_selected", selected)
	bar.add_theme_stylebox_override("tab_unselected", unselected)
	bar.add_theme_stylebox_override("tab_hovered", selected)
	bar.add_theme_color_override("font_selected_color", Color("#2a211a"))
	bar.add_theme_color_override("font_unselected_color", Color("#5c4b3a"))
	bar.add_theme_font_size_override("font_size", 16)


func _build_commissions_page() -> void:
	var page := VBoxContainer.new()
	page.name = "委托"
	_tabs.add_child(page)
	var label := UiTheme.label("还没有委托。M3 只有信件引导，委托是全量内容。")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("#5c4b3a"))
	page.add_child(label)


func _make_slot(parent: Control) -> PanelContainer:
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
	parent.add_child(slot)
	_clear_slot(slot)
	return slot


func _fill_slots(items_value: Variant) -> void:
	var items: Array = items_value if items_value is Array else []
	for index in _slots.size():
		var item: Dictionary = items[index] if index < items.size() else {}
		_fill_slot(_slots[index], item)


func _fill_slot(slot: PanelContainer, item: Dictionary) -> void:
	_clear_slot(slot)
	slot.tooltip_text = ""
	if item.is_empty():
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


func _clear_slot(slot: PanelContainer) -> void:
	for child in slot.get_children():
		slot.remove_child(child)
		child.queue_free()
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


func _fill_letters(letters_value: Variant) -> void:
	_letters_list.clear()
	_letter_ids.clear()
	var letters: Array = letters_value if letters_value is Array else []
	for entry in letters:
		if not entry is Dictionary:
			continue
		var status := str(entry.get("status", ""))
		var suffix := "  [新]" if status == "delivered" else ""
		_letters_list.add_item("%s · %s%s" % [
			str(entry.get("title", "")),
			str(entry.get("author_name", "")),
			suffix,
		])
		_letter_ids.append(str(entry.get("id", "")))


func _on_letter_selected(index: int) -> void:
	if index < 0 or index >= _letter_ids.size():
		return
	letter_selected.emit(_letter_ids[index])


func _on_close_pressed() -> void:
	close_requested.emit()
