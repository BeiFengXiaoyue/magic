class_name GameHud
extends Control

## 场景 HUD：右上时间/金币/信件，左下状态与需求，底部中央交互提示。
## 只显示信息；数值与状态由 main 推送。

const HUD_MARGIN := 16.0
const TOP_WIDTH := 440.0
const STATUS_WIDTH := 330.0

var _time_label: Label
var _scene_label: Label
var _player_label: Label
var _money_label: Label
var _mail_label: Label
var _demand_label: Label
var _hint_label: Label
var _message_label: Label
var _hint_panel: PanelContainer


func setup() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_top_right()
	_build_status()
	_build_hint()
	_hint_label.add_theme_color_override("font_color", UiTheme.COLOR_ACCENT)
	_message_label.add_theme_color_override("font_color", UiTheme.COLOR_TEXT)


func set_time(text: String) -> void:
	_time_label.text = "时间  " + text


func set_scene(text: String) -> void:
	_scene_label.text = text


func set_player(hp: int, sanity: int) -> void:
	_player_label.text = "生命 %d    理智 %d" % [hp, sanity]


func set_money(gold: int) -> void:
	_money_label.text = "金币  %d" % gold


func set_mail(unread: int) -> void:
	_mail_label.text = ("信件  %d" % unread) if unread > 0 else "信件  —"
	_mail_label.add_theme_color_override(
		"font_color",
		UiTheme.COLOR_ACCENT if unread > 0 else UiTheme.COLOR_MUTED
	)


func set_demand(text: String) -> void:
	_demand_label.text = text


func set_hint(text: String) -> void:
	_hint_label.text = text
	_hint_panel.visible = text != ""


func set_message(text: String) -> void:
	_message_label.text = text


func _build_top_right() -> void:
	var panel := _panel(TOP_WIDTH)
	add_child(panel)
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -TOP_WIDTH - HUD_MARGIN
	panel.offset_right = -HUD_MARGIN
	panel.offset_top = HUD_MARGIN
	panel.offset_bottom = HUD_MARGIN + 72.0
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_time_label = _value_label()
	row.add_child(_icon_row("art_ui_icon_clock", "时", _time_label))
	_money_label = _value_label()
	row.add_child(_icon_row("art_ui_icon_coin", "金", _money_label))
	_mail_label = _value_label()
	row.add_child(_icon_row("art_ui_icon_letter", "信", _mail_label))
	box.add_child(row)
	_scene_label = UiTheme.label("")
	_scene_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_scene_label.add_theme_color_override("font_color", UiTheme.COLOR_MUTED)
	box.add_child(_scene_label)


func _build_status() -> void:
	var panel := _panel(STATUS_WIDTH)
	add_child(panel)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = HUD_MARGIN
	panel.offset_right = HUD_MARGIN + STATUS_WIDTH
	panel.offset_top = -HUD_MARGIN - 116.0
	panel.offset_bottom = -HUD_MARGIN
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	_player_label = UiTheme.label("")
	box.add_child(_player_label)
	_demand_label = UiTheme.label("")
	_demand_label.add_theme_color_override("font_color", UiTheme.COLOR_MUTED)
	box.add_child(_demand_label)
	_message_label = UiTheme.label("")
	box.add_child(_message_label)


func _build_hint() -> void:
	_hint_panel = _panel(0.0)
	_hint_panel.visible = false
	add_child(_hint_panel)
	_hint_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint_panel.offset_left = -160.0
	_hint_panel.offset_right = 160.0
	_hint_panel.offset_top = -HUD_MARGIN - 44.0
	_hint_panel.offset_bottom = -HUD_MARGIN
	_hint_label = UiTheme.label("")
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_panel.add_child(_hint_label)


func _panel(min_width: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_style())
	panel.custom_minimum_size = Vector2(min_width, 0.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _value_label() -> Label:
	var label := UiTheme.label("")
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	return label


func _icon_row(art_id: String, fallback: String, value_label: Label) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var texture := ArtAssets.texture(art_id)
	if texture != null:
		var icon := TextureRect.new()
		icon.texture = texture
		icon.custom_minimum_size = Vector2(22.0, 22.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
	else:
		var label := UiTheme.label(fallback)
		label.add_theme_color_override("font_color", UiTheme.COLOR_ACCENT)
		row.add_child(label)
	row.add_child(value_label)
	return row
