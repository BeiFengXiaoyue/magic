class_name Player
extends Node2D

## 主角：WASD / 方向键移动；位置限制在当前场景的可行走矩形内；
## Camera2D 跟随玩家，室内由 limits 固定视角，森林则滚动大地图。
##
## 行走贴图只有左 / 右两行（背面图暂不生成）：
## - 有水平分量时按 A/D 选左 / 右；
## - 纯上下移动时沿用上一次的左右朝向（去掉向上分量后没有方向可判）。

const RADIUS := 14.0
const SPEED := 220.0
const MARGIN := 24.0
const CAMERA_SMOOTH_SPEED := 8.0
const COLOR := Color("#e6dcc8")

const HERO_ART_ID := "art_char_hero_walk"
const HERO_FRAME_SIZE := 192.0
const HERO_DISPLAY_SIZE := 160.0
const HERO_FOOT_OFFSET := 18.0
const HERO_FRAMES := 4
const HERO_WALK_FPS := 8.0
const HERO_ROW_LEFT := 0
const HERO_ROW_RIGHT := 1

var _input_enabled: bool = true
var _bounds: Rect2 = Rect2(0.0, 0.0, 1280.0, 720.0)
var _obstacles: Array[Rect2] = []
var _camera: Camera2D
var _hero: Texture2D = null
var _facing_right: bool = true
var _moving: bool = false
var _walk_time: float = 0.0


func _ready() -> void:
	_hero = ArtAssets.texture(HERO_ART_ID)
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = CAMERA_SMOOTH_SPEED
	add_child(_camera)
	_camera.make_current()


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if not enabled and _moving:
		_moving = false
		_walk_time = 0.0
		queue_redraw()


func set_bounds(bounds: Rect2) -> void:
	_bounds = bounds


func set_obstacles(obstacles: Array[Rect2]) -> void:
	_obstacles = obstacles


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
		if _moving:
			_moving = false
			_walk_time = 0.0
			queue_redraw()
		return

	_moving = true
	_facing_right = resolve_facing(direction, _facing_right)
	_walk_time += delta
	queue_redraw()

	var step := direction.normalized() * SPEED * delta
	var min_x := _bounds.position.x + MARGIN
	var max_x := _bounds.end.x - MARGIN
	var min_y := _bounds.position.y + MARGIN
	var max_y := _bounds.end.y - MARGIN

	var target_x := clampf(position.x + step.x, min_x, max_x)
	var candidate := Vector2(target_x, position.y)
	if not _blocked(candidate):
		position.x = target_x

	var target_y := clampf(position.y + step.y, min_y, max_y)
	candidate = Vector2(position.x, target_y)
	if not _blocked(candidate):
		position.y = target_y


func _blocked(point: Vector2) -> bool:
	for obstacle in _obstacles:
		if obstacle.grow(RADIUS).has_point(point):
			return true
	return false


## 只有左右两套行走图：有水平分量时按 A/D 定朝向；
## 纯上下移动时去掉纵向分量后没有方向可判，沿用上一次的左右朝向。
static func resolve_facing(direction: Vector2, previous_right: bool) -> bool:
	if direction.x < 0.0:
		return false
	if direction.x > 0.0:
		return true
	return previous_right


func _draw() -> void:
	if _hero == null:
		draw_circle(Vector2.ZERO, RADIUS, COLOR)
		return
	var row := HERO_ROW_RIGHT if _facing_right else HERO_ROW_LEFT
	var frame := 0
	if _moving:
		frame = int(_walk_time * HERO_WALK_FPS) % HERO_FRAMES
	var region := Rect2(
		float(frame) * HERO_FRAME_SIZE,
		float(row) * HERO_FRAME_SIZE,
		HERO_FRAME_SIZE,
		HERO_FRAME_SIZE
	)
	var dest := Rect2(
		Vector2(-HERO_DISPLAY_SIZE * 0.5, -HERO_DISPLAY_SIZE + HERO_FOOT_OFFSET),
		Vector2(HERO_DISPLAY_SIZE, HERO_DISPLAY_SIZE)
	)
	draw_texture_rect_region(_hero, dest, region)
