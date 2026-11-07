class_name Journal
extends RefCounted

## 手记（契约 05 §5.3）：炼制记录 + 线索 + 已知地点。
## 记录格式在「创建时」固化：L04 解锁标准表后，旧条目仍保持散记。

var _db: ContentDatabase
var _knowledge: Knowledge
var _perception: Perception
var _entries: Array[Dictionary] = []
var _notes: Array[Dictionary] = []
var _next_id: int = 1


func _init(db: ContentDatabase, knowledge: Knowledge, perception: Perception) -> void:
	_db = db
	_knowledge = knowledge
	_perception = perception


func add_craft_entry(result: CraftResult, ctx: Dictionary) -> Dictionary:
	var format := record_format()
	var inputs: Dictionary = ctx.get("inputs", {})
	var spirit_total := int(ctx.get("spirit_total", 0))
	var observation := _perception.describe(result, {"spirit_total": spirit_total})
	var dominant := ""
	var yield_ratio := 0.0
	if result != null:
		dominant = result.dominant
		yield_ratio = result.yield_ratio
	var entry := {
		"id": "jrn_%04d" % _next_id,
		"day": int(ctx.get("day", 0)),
		"minute_of_day": int(ctx.get("minute_of_day", 0)),
		"format": format,
		"inputs": inputs.duplicate(true),
		"tier_id": str(ctx.get("tier_id", "")),
		"duration_minutes": int(ctx.get("duration_minutes", 0)),
		"device_id": str(ctx.get("device_id", "")),
		"observation": observation,
		"dominant": dominant,
		"yield_ratio": yield_ratio,
		"spirit_total": spirit_total,
		"columns": {},
		"text": "",
	}
	if format == "table":
		entry["columns"] = {
			"changed": _inputs_text(inputs),
			"conditions": "%s · %d 分钟 · %s" % [
				_tier_name(str(entry["tier_id"])),
				int(entry["duration_minutes"]),
				_device_name(str(entry["device_id"])),
			],
			"result": observation,
			"pressure": null,
		}
	else:
		entry["text"] = "第 %d 天，%s，%s。%s" % [
			int(entry["day"]),
			_tier_name(str(entry["tier_id"])),
			_inputs_text(inputs),
			observation,
		]
	_next_id += 1
	_entries.append(entry)
	return entry


func add_note(text: String, source_letter: String = "") -> void:
	if text.strip_edges() == "":
		return
	_notes.append({"text": text, "source": source_letter})


func record_format() -> String:
	return "table" if _knowledge.has("concept", "cpt_jilu_biaozhun") else "prose"


func records_view() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in _entries:
		out.append(entry.duplicate(true))
	return out


func recipes_view() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for recipe_id in _knowledge.list("recipe"):
		var recipe := _db.recipe(recipe_id)
		if recipe.is_empty():
			continue
		var inputs: Dictionary = recipe.get("inputs", {})
		out.append({
			"id": recipe_id,
			"name": str(recipe.get("name", recipe_id)),
			"inputs": inputs.duplicate(true),
			"inputs_text": _inputs_text(inputs),
			"tier_name": _tier_name(str(recipe.get("temperature_tier", ""))),
			"duration_minutes": int(recipe.get("duration_minutes", 0)),
			"source_letter": str(recipe.get("source_letter", "")),
		})
	return out


func locations_view() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for location_id in _knowledge.list("location"):
		var node := _db.node(location_id)
		if node.is_empty():
			continue
		var material := _db.material(str(node.get("material_id", "")))
		out.append({
			"id": location_id,
			"name": str(node.get("name", material.get("name", location_id))),
			"journal_hint": str(node.get("journal_hint", "")),
			"scene": str(node.get("scene", "")),
			"material_name": str(material.get("name", "")),
		})
	return out


func notes_view() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for note in _notes:
		out.append(note.duplicate(true))
	return out


func snapshot() -> Dictionary:
	var entries: Array[Dictionary] = []
	for entry in _entries:
		entries.append(entry.duplicate(true))
	var notes: Array[Dictionary] = []
	for note in _notes:
		notes.append(note.duplicate(true))
	return {"next_id": _next_id, "entries": entries, "notes": notes}


func restore(snapshot: Dictionary) -> void:
	_entries.clear()
	_notes.clear()
	_next_id = int(snapshot.get("next_id", 1))
	var raw_entries: Variant = snapshot.get("entries", [])
	if raw_entries is Array:
		for entry in raw_entries:
			if entry is Dictionary:
				_entries.append(entry.duplicate(true))
	var raw_notes: Variant = snapshot.get("notes", [])
	if raw_notes is Array:
		for note in raw_notes:
			if note is Dictionary:
				_notes.append(note.duplicate(true))


func _inputs_text(inputs: Dictionary) -> String:
	var parts: Array[String] = []
	for material_id in inputs:
		var material := _db.material(str(material_id))
		parts.append("%s×%d" % [str(material.get("name", material_id)), int(inputs[material_id])])
	return "、".join(parts)


func _tier_name(tier_id: String) -> String:
	var tiers: Variant = _db.constant("reaction.temperature_tiers")
	if tiers is Array:
		for tier in tiers:
			if tier is Dictionary and str(tier.get("id", "")) == tier_id:
				return str(tier.get("name", tier_id))
	return tier_id


func _device_name(device_id: String) -> String:
	var device: Variant = _db.constant("device")
	if device is Dictionary and device.has(device_id):
		var info: Variant = device[device_id]
		if info is Dictionary:
			return str(info.get("name", device_id))
	return device_id
