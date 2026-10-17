class_name GameTimeDriver
extends RefCounted

## 现实时间 → 游戏分钟，并调用 O1 的 tick（契约 02 §3 的时间入口）。
## 时间倍速只影响驱动速度，不进入内核。

const TIME_SCALES: Array[float] = [1.0, 4.0, 12.0]
const MINUTES_PER_HOUR := 60

var _use_case: CraftUseCase
var _seconds_per_game_minute: float
var _accumulator: float = 0.0
var _scale_index: int = 0


func _init(db: ContentDatabase, use_case: CraftUseCase) -> void:
	_use_case = use_case
	_seconds_per_game_minute = float(db.constant("time.real_seconds_per_game_hour")) / float(MINUTES_PER_HOUR)


func advance_real(delta: float) -> void:
	if _seconds_per_game_minute <= 0.0:
		return
	_accumulator += delta * TIME_SCALES[_scale_index]
	var minutes := int(_accumulator / _seconds_per_game_minute)
	if minutes > 0:
		_accumulator -= float(minutes) * _seconds_per_game_minute
		_use_case.tick(minutes)


func cycle_scale() -> void:
	_scale_index = (_scale_index + 1) % TIME_SCALES.size()


func scale_label() -> String:
	return "%.0fx" % TIME_SCALES[_scale_index]


func current_scale() -> float:
	return TIME_SCALES[_scale_index]
