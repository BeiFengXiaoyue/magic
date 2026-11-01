class_name BubbleView
extends Control

## 坩埚的气泡与蒸气（契约 02 §1.8：气泡是唯一的温度反馈）。
## 等级由 Perception.visual 给出；这里只负责让气泡动起来，不读任何内核数值。

const BUBBLES_PER_LEVEL := 6.0
const BASE_BUBBLES := 4.0
const BUBBLE_RADIUS := 6.0
const BUBBLE_SPEED := 0.18
const BUBBLE_PHASE_STEP := 0.137
const BUBBLE_X_STEP := 0.381
const BUBBLE_X_OFFSET := 0.13
const BUBBLE_X_MIN := 0.15
const BUBBLE_X_SPAN := 0.7
const BUBBLE_SHRINK := 0.35
const BUBBLE_ALPHA := 0.8
const BUBBLE_ALPHA_FADE := 0.4
const LIQUID_HEIGHT_RATIO := 0.55
const STEAM_PER_LEVEL := 3
const STEAM_SPEED := 0.07
const STEAM_PHASE_STEP := 0.211
const STEAM_X_STEP := 0.53
const STEAM_X_MIN := 0.2
const STEAM_X_SPAN := 0.6
const STEAM_HEIGHT_RATIO := 0.35
const STEAM_RADIUS_SCALE := 2.5
const STEAM_ALPHA := 0.18
const COLOR_PANEL := Color("#241d17")
const COLOR_LIQUID := Color("#2a1f16")
const COLOR_BUBBLE := Color("#d98c3f")
const COLOR_STEAM := Color(0.85, 0.8, 0.7)

var _bubble_level: int = 0
var _steam_level: int = 0
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func set_levels(bubble_level: int, steam_level: int) -> void:
	_bubble_level = bubble_level
	_steam_level = steam_level
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var rect_size := size
	draw_rect(Rect2(Vector2.ZERO, rect_size), COLOR_PANEL)
	var liquid_height := rect_size.y * LIQUID_HEIGHT_RATIO
	var liquid_top := rect_size.y - liquid_height
	draw_rect(Rect2(0.0, liquid_top, rect_size.x, liquid_height), COLOR_LIQUID)

	var bubble_count := int(BASE_BUBBLES + BUBBLES_PER_LEVEL * float(_bubble_level))
	for index in bubble_count:
		var phase := fmod(_time * BUBBLE_SPEED + float(index) * BUBBLE_PHASE_STEP, 1.0)
		var x := rect_size.x * (BUBBLE_X_MIN + BUBBLE_X_SPAN * fmod(float(index) * BUBBLE_X_STEP + BUBBLE_X_OFFSET, 1.0))
		var y := liquid_top + liquid_height * (1.0 - phase)
		var radius := BUBBLE_RADIUS * (1.0 - phase * BUBBLE_SHRINK)
		var alpha := BUBBLE_ALPHA - phase * BUBBLE_ALPHA_FADE
		draw_circle(Vector2(x, y), radius, Color(COLOR_BUBBLE, alpha))

	var steam_count := _steam_level * STEAM_PER_LEVEL
	for index in steam_count:
		var phase := fmod(_time * STEAM_SPEED + float(index) * STEAM_PHASE_STEP, 1.0)
		var x := rect_size.x * (STEAM_X_MIN + STEAM_X_SPAN * fmod(float(index) * STEAM_X_STEP, 1.0))
		var y := liquid_top - rect_size.y * STEAM_HEIGHT_RATIO * phase
		var alpha := STEAM_ALPHA * (1.0 - phase)
		draw_circle(Vector2(x, y), BUBBLE_RADIUS * STEAM_RADIUS_SCALE, Color(COLOR_STEAM, alpha))
