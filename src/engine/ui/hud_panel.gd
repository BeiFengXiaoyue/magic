class_name HudPanel
extends Control

## HUD 面板：NinePatchRect 手绘木框背景 + 独立内容区。
## 不用 PanelContainer + StyleBoxTexture，避免小面板九宫格被内容挤压。

const PATCH_MARGIN := 24

var content: VBoxContainer
var _bg: NinePatchRect = null


func setup(min_width: float, padding: int = 26) -> void:
	custom_minimum_size = Vector2(min_width, 0.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texture := ArtAssets.texture("art_ui_panel_frame")
	if texture != null:
		_bg = NinePatchRect.new()
		_bg.texture = texture
		_bg.patch_margin_left = PATCH_MARGIN
		_bg.patch_margin_right = PATCH_MARGIN
		_bg.patch_margin_top = PATCH_MARGIN
		_bg.patch_margin_bottom = PATCH_MARGIN
		_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_bg)
		_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", padding)
	pad.add_theme_constant_override("margin_right", padding)
	pad.add_theme_constant_override("margin_top", padding)
	pad.add_theme_constant_override("margin_bottom", padding)
	add_child(pad)
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 4)
	pad.add_child(content)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if _bg != null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.16, 0.13, 0.10, 0.92))
	draw_rect(Rect2(Vector2.ZERO, size), Color("#8a6a4a"), false, 2.0)
