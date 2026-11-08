class_name UiTheme
extends RefCounted

## 引擎层的表现常量与字体/主题工厂（契约 00 §8：表现参数写成具名常量）。

const FONT_SIZE := 16
const TITLE_SIZE := 22
const COLOR_TEXT := Color("#e6dcc8")
const COLOR_MUTED := Color("#9a8d78")
const COLOR_ACCENT := Color("#d98c3f")
const COLOR_BG := Color("#14110f")
const COLOR_PANEL := Color("#1f1a16")
const COLOR_OUTLINE := Color("#0d0b09")
const OUTLINE_SIZE := 4


static func create() -> Theme:
	var font := SystemFont.new()
	font.font_names = PackedStringArray([
		"KaiTi",
		"STKaiti",
		"SimSun",
		"Microsoft YaHei",
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
	label.add_theme_color_override("font_outline_color", COLOR_OUTLINE)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	return label


static func label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_outline_color", COLOR_OUTLINE)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	return label


static func menu_style() -> StyleBox:
	var texture := ArtAssets.texture("art_ui_panel_frame")
	if texture != null:
		var frame := StyleBoxTexture.new()
		frame.texture = texture
		frame.texture_margin_left = 24.0
		frame.texture_margin_right = 24.0
		frame.texture_margin_top = 24.0
		frame.texture_margin_bottom = 24.0
		frame.content_margin_left = 24.0
		frame.content_margin_right = 24.0
		frame.content_margin_top = 24.0
		frame.content_margin_bottom = 24.0
		return frame
	return paper_style()


static func crucible_style() -> StyleBox:
	var texture := ArtAssets.texture("art_ui_crucible_frame")
	if texture != null:
		var frame := StyleBoxTexture.new()
		frame.texture = texture
		frame.texture_margin_left = 48.0
		frame.texture_margin_right = 48.0
		frame.texture_margin_top = 48.0
		frame.texture_margin_bottom = 48.0
		frame.content_margin_left = 32.0
		frame.content_margin_right = 32.0
		frame.content_margin_top = 28.0
		frame.content_margin_bottom = 28.0
		return frame
	return menu_style()


static func style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _button_box(Color("#c9bfa8"), Color("#6b5a44")))
	button.add_theme_stylebox_override("hover", _button_box(Color("#d8cfb9"), Color("#8c3a34")))
	button.add_theme_stylebox_override("pressed", _button_box(Color("#b9aa8d"), Color("#8c3a34")))
	button.add_theme_stylebox_override(
		"disabled",
		_button_box(Color("#9a9284"), Color("#6b5a44"))
	)
	button.add_theme_color_override("font_color", Color("#2a211a"))
	button.add_theme_color_override("font_hover_color", Color("#2a211a"))
	button.add_theme_color_override("font_pressed_color", Color("#8c3a34"))
	button.add_theme_color_override("font_disabled_color", Color("#6b665e"))


static func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style


static func paper_style() -> StyleBoxFlat:
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("#c9bfa8")
	paper.border_color = Color("#2a211a")
	paper.set_border_width_all(3)
	paper.set_corner_radius_all(0)
	paper.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	paper.shadow_size = 6
	paper.content_margin_left = 24.0
	paper.content_margin_right = 24.0
	paper.content_margin_top = 20.0
	paper.content_margin_bottom = 20.0
	return paper


static func panel_style() -> StyleBox:
	var texture := ArtAssets.texture("art_ui_panel_frame")
	if texture != null:
		var textured := StyleBoxTexture.new()
		textured.texture = texture
		textured.texture_margin_left = 24.0
		textured.texture_margin_right = 24.0
		textured.texture_margin_top = 24.0
		textured.texture_margin_bottom = 24.0
		textured.content_margin_left = 12.0
		textured.content_margin_right = 12.0
		textured.content_margin_top = 10.0
		textured.content_margin_bottom = 10.0
		return textured
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#42301f")
	style.border_color = Color("#c08a45")
	style.set_border_width_all(4)
	style.set_corner_radius_all(0)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 5
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style
