class_name Spirituality
extends RefCounted

## 灵性 K5（契约 05 §4.2）——唯一写入点。
## P 永久只增；S 粘性；T 临时（每日衰减）。
## 任何领域/编排改灵性都只经 apply_source / add。

var p: int = 0
var s: int = 0
var t: int = 0

var _db: ContentDatabase


func _init(db: ContentDatabase) -> void:
	_db = db


func total() -> int:
	return p + s + t


func apply_source(source_id: String) -> void:
	var sources: Variant = _db.constant("spirituality.sources")
	if not sources is Dictionary or not sources.has(source_id):
		push_error("Spirituality: 未知来源 %s" % source_id)
		return
	var source: Dictionary = sources[source_id]
	add(str(source.get("layer", "")), int(source.get("amount", 0)), source_id)


func add(layer: String, amount: int, _source: String) -> void:
	match layer:
		"P":
			if amount < 0:
				push_error("Spirituality: P 只增不减")
				return
			p += amount
		"S":
			s = maxi(0, s + amount)
		"T":
			t = maxi(0, t + amount)
		_:
			push_error("Spirituality: 非法层 %s" % layer)


func on_day_passed() -> void:
	t = maxi(0, t - int(_db.constant("spirituality.daily_t_decay")))


func perception_tier() -> String:
	var tiers: Variant = _db.constant("perception.spirit_tiers")
	var mid := 0
	var high := 0
	if tiers is Dictionary:
		mid = int(tiers.get("mid", 0))
		high = int(tiers.get("high", 0))
	var value := total()
	if value < mid:
		return "low"
	if value < high:
		return "mid"
	return "high"


func snapshot() -> Dictionary:
	return {"p": p, "s": s, "t": t}


func restore(snapshot: Dictionary) -> void:
	p = int(snapshot.get("p", 0))
	s = int(snapshot.get("s", 0))
	t = int(snapshot.get("t", 0))
