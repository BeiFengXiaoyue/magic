class_name CharacterState
extends RefCounted

## D4 角色最小集（契约 02 §2.3）。M2 只接采集扣理智；
## 归零后果（昏倒、丢材料、猎人救援）M4 前补。

var hp: int = 0
var sanity: int = 0

var _max_hp: int
var _max_sanity: int


func _init(db: ContentDatabase) -> void:
	_max_hp = int(db.constant("survival.hp_start"))
	_max_sanity = int(db.constant("survival.sanity_start"))
	hp = _max_hp
	sanity = _max_sanity


func adjust_sanity(delta: int) -> void:
	sanity = clampi(sanity + delta, 0, _max_sanity)


func adjust_hp(delta: int) -> void:
	hp = clampi(hp + delta, 0, _max_hp)


func snapshot() -> Dictionary:
	return { "hp": hp, "sanity": sanity }
