class_name DayUseCase
extends RefCounted

## O5-min（契约 05 §6.3）：跨天只做 T 衰减 + 信件到达检查。
## M4 的完整 O5 在这里扩展生存/睡眠/市场/周期事件。

var _spirituality: Spirituality
var _letters: LetterUseCase


func _init(spirituality: Spirituality, letters: LetterUseCase) -> void:
	_spirituality = spirituality
	_letters = letters


func on_day_passed(_day: int, _season: int, _year: int) -> void:
	_spirituality.on_day_passed()
	_letters.refresh()
