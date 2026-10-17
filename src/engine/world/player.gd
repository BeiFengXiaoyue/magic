class_name Player
extends Node2D

## 占位角色：WASD / 方向键移动，边界限制在 1280×720 内。

const RADIUS := 14.0
const SPEED := 220.0
const MARGIN := 24.0
const SCENE_WIDTH := 1280.0
const SCENE_HEIGHT := 720.0
const COLOR := Color("#e6dcc8")

var _input_enabled: bool = true


func _ready() -> void:
	z_index = 10


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled


func _process(delta: float) -> void:
	if not _input_enabled:
		return
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if direction == Vector2.ZERO:
		return
	position += direction.normalized() * SPEED * delta
	position.x = clampf(position.x, MARGIN, SCENE_WIDTH - MARGIN)
	position.y = clampf(position.y, MARGIN, SCENE_HEIGHT - MARGIN)


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)
