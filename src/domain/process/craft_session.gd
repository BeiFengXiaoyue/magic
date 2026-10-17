class_name CraftSession
extends RefCounted

## 一次炼制会话（契约 02 §2.1）。
## element_pool 是 M1 的内部字段：换火候重解时复用材料池，不重新消费 craft 流。

signal progress_changed(progress: float)

var id: String = ""
var inputs: Dictionary = {}
var recipe_id: String = ""
var tier_id: String = ""
var temperature_c: float = 0.0
var duration_minutes: int = 0
var elapsed_minutes: int = 0
var progress: float = 0.0
var result: CraftResult = null
var finished: bool = false

var element_pool: Dictionary = {}


func advance(game_minutes: int) -> void:
	if finished or duration_minutes <= 0:
		return
	elapsed_minutes = mini(elapsed_minutes + game_minutes, duration_minutes)
	progress = float(elapsed_minutes) / float(duration_minutes)
	if progress >= 1.0:
		progress = 1.0
		finished = true
	progress_changed.emit(progress)
