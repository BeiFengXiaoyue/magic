class_name GameHud
extends VBoxContainer

## 场景 HUD：时间、场景、HP/理智、金币、当前需求、交互提示与消息。

const WIDTH := 430.0
const HUD_MARGIN := 16.0

var _time_label: Label
var _scene_label: Label
var _player_label: Label
var _money_label: Label
var _demand_label: Label
var _hint_label: Label
var _message_label: Label


func setup() -> void:
	custom_minimum_size = Vector2(WIDTH, 0.0)
	position = Vector2(HUD_MARGIN, HUD_MARGIN)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UiTheme.title("炼金术士手记"))
	_time_label = UiTheme.label("")
	_scene_label = UiTheme.label("")
	_player_label = UiTheme.label("")
	_money_label = UiTheme.label("")
	_demand_label = UiTheme.label("")
	_hint_label = UiTheme.label("")
	_message_label = UiTheme.label("")
	add_child(_time_label)
	add_child(_scene_label)
	add_child(_player_label)
	add_child(_money_label)
	add_child(_demand_label)
	add_child(_hint_label)
	add_child(_message_label)
	add_child(UiTheme.label("WASD 移动 · E 交互 · T 倍速 · B 布点 · H 调试 · Esc 关闭面板"))
	_hint_label.add_theme_color_override("font_color", UiTheme.COLOR_ACCENT)
	_message_label.add_theme_color_override("font_color", UiTheme.COLOR_TEXT)


func set_time(text: String) -> void:
	_time_label.text = text


func set_scene(text: String) -> void:
	_scene_label.text = "地点：%s" % text


func set_player(hp: int, sanity: int) -> void:
	_player_label.text = "HP %d · 理智 %d" % [hp, sanity]


func set_money(gold: int) -> void:
	_money_label.text = "金币 %d" % gold


func set_demand(text: String) -> void:
	_demand_label.text = text


func set_hint(text: String) -> void:
	_hint_label.text = text


func set_message(text: String) -> void:
	_message_label.text = text
