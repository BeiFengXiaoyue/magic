class_name InteractableNode
extends Node2D

## 场景里可交互的占位物：坩埚、柜台、床、门、采集点。

const RADIUS := 18.0
const COLOR_DEFAULT := Color("#d98c3f")
const COLOR_DOOR := Color("#8a6a4a")
const COLOR_DOOR_FRAME := Color("#2a1f16")
const COLOR_NODE := Color("#6f9a5a")
const COLOR_UNAVAILABLE := Color("#4a4a4a")

var target_id: String = ""
var label: String = ""
var kind: String = ""

var _available: bool = true
var _base_color: Color = COLOR_DEFAULT


func setup(id: String, display_label: String, interact_kind: String) -> void:
	target_id = id
	label = display_label
	kind = interact_kind
	if kind == "node":
		_base_color = COLOR_NODE
	elif kind == "door":
		_base_color = COLOR_DOOR
	queue_redraw()


func set_available(value: bool) -> void:
	_available = value
	queue_redraw()


func _draw() -> void:
	var color := _base_color if _available else COLOR_UNAVAILABLE
	if kind == "door":
		draw_rect(Rect2(-18.0, -32.0, 36.0, 64.0), color)
		draw_rect(Rect2(-18.0, -32.0, 36.0, 64.0), COLOR_DOOR_FRAME, false, 3.0)
	elif kind == "counter":
		draw_rect(Rect2(-40.0, -20.0, 80.0, 40.0), color)
	elif kind == "bed":
		draw_rect(Rect2(-32.0, -20.0, 64.0, 40.0), color)
	else:
		draw_circle(Vector2.ZERO, RADIUS, color)
