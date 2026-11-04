class_name InteractableNode
extends Node2D

## 场景里可交互的占位物：有 art_id 贴图就画贴图，没有就回退形状。
## props_baked / 场景背景已经画入物件时，可用 show_visual=false 只保留交互热区。

const RADIUS := 18.0
const WILD_RADIUS := 14.0
const COLOR_DEFAULT := Color("#d98c3f")
const COLOR_DOOR := Color("#8a6a4a")
const COLOR_DOOR_FRAME := Color("#2a1f16")
const COLOR_NODE := Color("#6f9a5a")
const COLOR_WILD := Color("#b7d27a")
const COLOR_UNAVAILABLE := Color("#4a4a4a")

var target_id: String = ""
var label: String = ""
var kind: String = ""
var wild: bool = false
var show_visual: bool = true

var _available: bool = true
var _base_color: Color = COLOR_DEFAULT
var _texture: Texture2D = null
var _art_size: float = 0.0
var _interact_size: Vector2 = Vector2.ZERO


func setup(
	id: String,
	display_label: String,
	interact_kind: String,
	art_id: String = "",
	art_size: float = 0.0,
	visual: bool = true,
	interact_size: Vector2 = Vector2.ZERO
) -> void:
	target_id = id
	label = display_label
	kind = interact_kind
	_art_size = art_size
	show_visual = visual
	_interact_size = interact_size
	_texture = ArtAssets.texture(art_id)
	if kind == "node":
		_base_color = COLOR_NODE
	elif kind == "door":
		_base_color = COLOR_DOOR
	queue_redraw()


func set_available(value: bool) -> void:
	_available = value
	queue_redraw()


func set_wild(value: bool) -> void:
	wild = value
	if wild:
		_base_color = COLOR_WILD
	queue_redraw()


func set_show_visual(value: bool) -> void:
	show_visual = value
	queue_redraw()


## 玩家点到交互矩形的距离；没有配交互矩形时退回圆形半径。
## 用矩形边缘判定，玩家站在贴图旁边就能按 E，而不是必须踩进贴图。
func interact_distance(point: Vector2) -> float:
	if _interact_size == Vector2.ZERO:
		return position.distance_to(point)
	var delta := (point - position).abs() - _interact_size * 0.5
	var outside := Vector2(maxf(delta.x, 0.0), maxf(delta.y, 0.0))
	return outside.length()


func _draw() -> void:
	if not show_visual:
		return
	var color := _base_color if _available else COLOR_UNAVAILABLE
	if _texture != null:
		var side := _art_size if _art_size > 0.0 else float(_texture.get_width())
		draw_texture_rect(
			_texture,
			Rect2(-side / 2.0, -side / 2.0, side, side),
			false
		)
		if wild:
			draw_arc(
				Vector2.ZERO,
				side / 2.0 + 2.0,
				0.0,
				TAU,
				24,
				Color(COLOR_WILD, 0.55),
				2.0
			)
		return

	if kind == "door":
		draw_rect(Rect2(-18.0, -32.0, 36.0, 64.0), color)
		draw_rect(Rect2(-18.0, -32.0, 36.0, 64.0), COLOR_DOOR_FRAME, false, 3.0)
	elif kind == "counter":
		draw_rect(Rect2(-40.0, -20.0, 80.0, 40.0), color)
	elif kind == "bed":
		draw_rect(Rect2(-32.0, -20.0, 64.0, 40.0), color)
	else:
		var radius := WILD_RADIUS if wild else RADIUS
		draw_circle(Vector2.ZERO, radius, color)
		if wild:
			draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 20, Color(color, 0.45), 2.0)
