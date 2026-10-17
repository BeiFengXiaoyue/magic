class_name ObservationPanel
extends VBoxContainer

## 右侧观察面板：正常视图只显示感知通道给的文字；F1 才显示调试数据。

const WIDTH := 340.0
const SEPARATION := 8

var _observation: Label
var _debug: Label
var _time_label: Label
var _debug_visible: bool = false


func setup() -> void:
	custom_minimum_size = Vector2(WIDTH, 0.0)
	add_theme_constant_override("separation", SEPARATION)
	add_child(UiTheme.title("观察"))
	_observation = UiTheme.label("还没有开炉。")
	_observation.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_observation)
	_debug = UiTheme.label("")
	_debug.visible = false
	_debug.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_debug)
	_time_label = UiTheme.label("")
	add_child(_time_label)
	add_child(UiTheme.label("T 切倍速 · H 调试面板"))


func set_observation(text: String) -> void:
	_observation.text = text


func set_debug(text: String) -> void:
	_debug.text = text


func set_time(text: String) -> void:
	_time_label.text = text


func toggle_debug() -> void:
	_debug_visible = not _debug_visible
	_debug.visible = _debug_visible


func is_debug_visible() -> bool:
	return _debug_visible
