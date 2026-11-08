class_name GameHud
extends Control

## 星露谷式 HUD：右上木框（日期/时间/金币/信件/地点），
## 左侧生命/理智竖条，底部交互提示与消息。

const HUD_MARGIN := 16.0
const TOP_WIDTH := 400.0
const TOP_HEIGHT := 180.0
const BAR_WIDTH := 20.0
const BAR_HEIGHT := 130.0

var _date_label: Label
var _time_label: Label
var _scene_label: Label
var _money_label: Label
var _mail_label: Label
var _hint_label: Label
var _hint_panel: HudPanel
var _hp_bar: ProgressBar
var _sanity_bar: ProgressBar
var _hp_max: int = 100
var _sanity_max: int = 100


func setup(db: ContentDatabase = null) -> void:
	if db != null:
		_hp_max = int(db.constant("survival.hp_start"))
		_sanity_max = int(db.constant("survival.sanity_start"))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_top_right()
	_build_bars()
	_build_bottom()
	_hint_label.add_theme_color_override("font_color", Color("#8c3a34"))


func configure(db: ContentDatabase) -> void:
	_hp_max = int(db.constant("survival.hp_start"))
	_sanity_max = int(db.constant("survival.sanity_start"))
	if _hp_bar != null:
		_hp_bar.max_value = float(_hp_max)
		_hp_bar.value = float(_hp_max)
	if _sanity_bar != null:
		_sanity_bar.max_value = float(_sanity_max)
		_sanity_bar.value = float(_sanity_max)


func set_date(text: String) -> void:
	_date_label.text = text


func set_time(text: String) -> void:
	_time_label.text = text


func set_scene(text: String) -> void:
	_scene_label.text = text


func set_player(hp: int, sanity: int) -> void:
	_hp_bar.max_value = float(_hp_max)
	_hp_bar.value = float(clampi(hp, 0, _hp_max))
	_sanity_bar.max_value = float(_sanity_max)
	_sanity_bar.value = float(clampi(sanity, 0, _sanity_max))


func set_money(gold: int) -> void:
	_money_label.text = "%d" % gold


func set_mail(unread: int) -> void:
	_mail_label.text = ("%d" % unread) if unread > 0 else "—"
	_mail_label.add_theme_color_override(
		"font_color",
		Color("#8c3a34") if unread > 0 else Color("#6e6a63")
	)


func set_hint(text: String) -> void:
	_hint_label.text = text
	_hint_panel.visible = text != ""


func _build_top_right() -> void:
	var panel := _panel(TOP_WIDTH)
	add_child(panel)
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -TOP_WIDTH - HUD_MARGIN
	panel.offset_right = -HUD_MARGIN
	panel.offset_top = HUD_MARGIN
	panel.offset_bottom = HUD_MARGIN + TOP_HEIGHT

	panel.content.add_theme_constant_override("separation", 6)
	_date_label = UiTheme.label("")
	_date_label.add_theme_font_size_override("font_size", 20)
	_date_label.add_theme_color_override("font_color", Color("#2a211a"))
	_date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.content.add_child(_date_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	_time_label = _value_label()
	row.add_child(_icon_row("art_ui_icon_clock", "时", _time_label))
	_money_label = _value_label()
	row.add_child(_icon_row("art_ui_icon_coin", "金", _money_label))
	_mail_label = _value_label()
	row.add_child(_icon_row("art_ui_icon_letter", "信", _mail_label))
	panel.content.add_child(row)

	_scene_label = UiTheme.label("")
	_scene_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_scene_label.add_theme_font_size_override("font_size", 14)
	_scene_label.add_theme_color_override("font_color", Color("#5c4b3a"))
	_scene_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.content.add_child(_scene_label)


func _build_bars() -> void:
	var panel := _panel(0.0, 28)
	add_child(panel)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left = -HUD_MARGIN - 180.0
	panel.offset_right = -HUD_MARGIN
	panel.offset_top = -HUD_MARGIN - 280.0
	panel.offset_bottom = -HUD_MARGIN

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 10)
	panel.content.add_child(row)

	row.add_child(_bar_column("生命", Color("#8c3a34"), true))
	_hp_bar = _last_bar
	row.add_child(_bar_column("理智", Color("#6b5a8e"), false))
	_sanity_bar = _last_bar


var _last_bar: ProgressBar


func _bar_column(title: String, color: Color, is_hp: bool) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(44.0, 0.0)
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.add_theme_constant_override("separation", 4)
	var label := UiTheme.label(title)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("#2a211a"))
	column.add_child(label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	bar.show_percentage = false
	bar.max_value = float(_hp_max if is_hp else _sanity_max)
	bar.value = bar.max_value
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#1a1714")
	background.border_color = Color("#b8863f")
	background.set_border_width_all(3)
	bar.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	column.add_child(bar)
	_last_bar = bar
	return column


func _build_bottom() -> void:
	_hint_panel = _panel(0.0, 26)
	_hint_panel.visible = false
	add_child(_hint_panel)
	_hint_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint_panel.offset_left = -160.0
	_hint_panel.offset_right = 160.0
	_hint_panel.offset_top = -HUD_MARGIN - 70.0
	_hint_panel.offset_bottom = -HUD_MARGIN
	_hint_label = UiTheme.label("")
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_panel.content.add_child(_hint_label)


func _panel(min_width: float, padding: int = 26) -> HudPanel:
	var panel := HudPanel.new()
	panel.setup(min_width, padding)
	return panel


func _value_label() -> Label:
	var label := UiTheme.label("")
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_color_override("font_color", Color("#2a211a"))
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
