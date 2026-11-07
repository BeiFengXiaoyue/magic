class_name LetterState
extends RefCounted

## 单封信的运行时状态（契约 05 §5.1）。
## status 只前进：pending → delivered → read。

var id: String = ""
var status: String = "pending"
var delivered_day: int = 0
var read_day: int = 0
var awards: Dictionary = {"read": false}


func _init(letter_id: String = "") -> void:
	id = letter_id


func is_unread() -> bool:
	return status == "delivered"


func snapshot() -> Dictionary:
	return {
		"status": status,
		"delivered_day": delivered_day,
		"read_day": read_day,
		"awards": awards.duplicate(true),
	}


func restore(data: Dictionary) -> void:
	status = str(data.get("status", "pending"))
	delivered_day = int(data.get("delivered_day", 0))
	read_day = int(data.get("read_day", 0))
	var raw_awards: Variant = data.get("awards", null)
	if raw_awards is Dictionary:
		awards = raw_awards.duplicate(true)
