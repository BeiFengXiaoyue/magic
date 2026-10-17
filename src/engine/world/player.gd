class_name Player
extends Node2D

## 占位角色：WASD / 方向键移动；位置限制在当前场景的可行走矩形内；
## Camera2D 跟随玩家，室内由 limits 固定视角，森林则滚动大地图。

const RADIUS := 14.0
const SPEED := 220.0
const MARGIN := 24.0
const CAMERA_SMOOTH_SPEED := 8.0
const COLOR := Color("#e6dcc8")

var _input_enabled: bool = true
var _bounds: Rect2 = Rect2(0.0, 0.0, 1280.0, 720.0)
var _camera: Camera2D


func _ready() -> void:
	z_index = 10
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = CAMERA_SMOOTH_SPEED
	add_child(_camera)
	_camera.make_current()


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled


func set_bounds(bounds: Rect2) -> void:
	_bounds = bounds


func set_camera_limits(camera_rect: Rect2) -> void:
	if _camera == null:
		return
	_camera.limit_left = int(camera_rect.position.x)
	_camera.limit_top = int(camera_rect.position.y)
	_camera.limit_right = int(camera_rect.end.x)
	_camera.limit_bottom = int(camera_rect.end.y)
	_camera.reset_smoothing()


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
	position.x = clampf(position.x, _bounds.position.x + MARGIN, _bounds.end.x - MARGIN)
	position.y = clampf(position.y, _bounds.position.y + MARGIN, _bounds.end.y - MARGIN)


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)
