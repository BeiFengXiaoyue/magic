class_name UiTheme
extends RefCounted

## 引擎层的表现常量与字体/主题工厂（契约 00 §8：表现参数写成具名常量）。

const FONT_SIZE := 16
const TITLE_SIZE := 22
const COLOR_TEXT := Color("#e6dcc8")
const COLOR_ACCENT := Color("#d98c3f")
const COLOR_BG := Color("#14110f")
const COLOR_PANEL := Color("#1f1a16")


static func create() -> Theme:
	var font := SystemFont.new()
	font.font_names = PackedStringArray([
		"Microsoft YaHei",
		"SimHei",
		"Noto Sans CJK SC",
		"sans-serif",
	])
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = FONT_SIZE
	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_color("font_color", "Button", COLOR_TEXT)
	theme.set_color("font_color", "ProgressBar", COLOR_TEXT)
	return theme


static func title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", TITLE_SIZE)
	label.add_theme_color_override("font_color", COLOR_ACCENT)
	return label


static func label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
